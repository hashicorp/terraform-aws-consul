#!/bin/bash

set -e

source "/opt/gruntwork/bash-commons/log.sh"
source "/opt/gruntwork/bash-commons/string.sh"
source "/opt/gruntwork/bash-commons/assert.sh"
source "/opt/gruntwork/bash-commons/aws-wrapper.sh"

function log {
  local -r level="$1"
  local -r message="$2"
  local -r timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  >&2 echo -e "${timestamp} [${level}] [$SCRIPT_NAME] ${message}"
}

function log_info {
  local -r message="$1"
  log "INFO" "$message"
}

function log_warn {
  local -r message="$1"
  log "WARN" "$message"
}

function log_error {
  local -r message="$1"
  log "ERROR" "$message"
}

# Based on code from: http://stackoverflow.com/a/16623897/483528
function strip_prefix {
  local -r str="$1"
  local -r prefix="$2"
  echo "${str#$prefix}"
}

function assert_not_empty {
  local -r arg_name="$1"
  local -r arg_value="$2"

  if [[ -z "$arg_value" ]]; then
    log_error "The value for '$arg_name' cannot be empty"
    print_usage
    exit 1
  fi
}

function lookup_path_in_instance_metadata {
  local -r path="$1"
  curl --silent --show-error --location "$EC2_INSTANCE_METADATA_URL/$path/"
}

function lookup_path_in_instance_dynamic_data {
  local -r path="$1"
  curl --silent --show-error --location "$EC2_INSTANCE_DYNAMIC_DATA_URL/$path/"
}

function get_instance_ip_address {
  lookup_path_in_instance_metadata "local-ipv4"
}

function get_instance_id {
  lookup_path_in_instance_metadata "instance-id"
}

function get_instance_region {
  lookup_path_in_instance_dynamic_data "instance-identity/document" | jq -r ".region"
}

function get_instance_tags {
  local -r instance_id="$1"
  local -r instance_region="$2"
  local tags=""
  local count_tags=""

  log_info "Looking up tags for Instance $instance_id in $instance_region"
  for (( i=1; i<="$MAX_RETRIES"; i++ )); do
    tags=$(aws ec2 describe-tags \
      --region "$instance_region" \
      --filters "Name=resource-type,Values=instance" "Name=resource-id,Values=${instance_id}")
    count_tags=$(echo $tags | jq -r ".Tags? | length")
    if [[ "$count_tags" -gt 0 ]]; then
      log_info "This Instance $instance_id in $instance_region has Tags."
      echo "$tags"
      return
    else
      log_warn "This Instance $instance_id in $instance_region does not have any Tags."
      log_warn "Will sleep for $SLEEP_BETWEEN_RETRIES_SEC seconds and try again."
      sleep "$SLEEP_BETWEEN_RETRIES_SEC"
    fi
  done

  log_error "Could not find Instance Tags for $instance_id in $instance_region after $MAX_RETRIES retries."
  exit 1
}

function get_asg_size {
  local -r asg_name="$1"
  local -r aws_region="$2"
  local asg_json=""

  log_info "Looking up the size of the Auto Scaling Group $asg_name in $aws_region"
  asg_json=$(aws autoscaling describe-auto-scaling-groups --region "$aws_region" --auto-scaling-group-names "$asg_name")
  echo "$asg_json" | jq -r '.AutoScalingGroups[0].DesiredCapacity'
}

function get_cluster_size {
  local -r instance_tags="$1"
  local -r aws_region="$2"

  local asg_name=""
  asg_name=$(get_tag_value "$instance_tags" "$AWS_ASG_TAG_KEY")
  if [[ -z "$asg_name" ]]; then
    log_warn "This EC2 Instance does not appear to be part of an Auto Scaling Group, so cannot determine cluster size. Setting cluster size to 1."
    echo 1
  else
    get_asg_size "$asg_name" "$aws_region"
  fi
}

# Get the value for a specific tag from the tags JSON returned by the AWS describe-tags:
# https://docs.aws.amazon.com/cli/latest/reference/ec2/describe-tags.html
function get_tag_value {
  local -r tags="$1"
  local -r tag_key="$2"

  echo "$tags" | jq -r ".Tags[] | select(.Key == \"$tag_key\") | .Value"
}

function assert_is_installed {
  local -r name="$1"

  if [[ ! $(command -v ${name}) ]]; then
    log_error "The binary '$name' is required by this script but is not installed or in the system's PATH."
    exit 1
  fi
}

function split_by_lines {
  local prefix="$1"
  shift

  for var in "$@"; do
    echo "${prefix}${var}"
  done
}

function generate_systemd_config {
  local -r systemd_config_path="$1"
  local -r consul_config_dir="$2"
  local -r consul_data_dir="$3"
  local -r consul_systemd_stdout="$4"
  local -r consul_systemd_stderr="$5"
  local -r consul_bin_dir="$6"
  local -r consul_user="$7"
  shift 7
  local -r environment=("$@")
  local -r config_path="$consul_config_dir/$CONSUL_CONFIG_FILE"

  log_info "Creating systemd config file to run Consul in $systemd_config_path"

  local -r unit_config=$(cat <<EOF
[Unit]
Description="HashiCorp Consul - A service mesh solution"
Documentation=https://www.consul.io/
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=$config_path

EOF
)

  local -r service_config=$(cat <<EOF
[Service]
Type=notify
User=$consul_user
Group=$consul_user
ExecStart=$consul_bin_dir/consul agent -config-dir $consul_config_dir -data-dir $consul_data_dir
ExecReload=$consul_bin_dir/consul reload
KillMode=process
Restart=on-failure
TimeoutSec=300s
LimitNOFILE=65536
$(split_by_lines "Environment=" "${environment[@]}")

EOF
)

  local log_config=""
  if [[ -n $consul_systemd_stdout ]]; then
    log_config+="StandardOutput=$consul_systemd_stdout\n"
  fi
  if [[ -n $consul_systemd_stderr ]]; then
    log_config+="StandardError=$consul_systemd_stderr\n"
  fi

  local -r install_config=$(cat <<EOF
[Install]
WantedBy=multi-user.target
EOF
)

  echo -e "$unit_config" > "$systemd_config_path"
  echo -e "$service_config" >> "$systemd_config_path"
  echo -e "$log_config" >> "$systemd_config_path"
  echo -e "$install_config" >> "$systemd_config_path"
}

function start_consul {
  log_info "Reloading systemd config and starting Consul"

  sudo systemctl daemon-reload
  sudo systemctl enable consul.service
  sudo systemctl restart consul.service
}

# Based on: http://unix.stackexchange.com/a/7732/215969
function get_owner_of_path {
  local -r path="$1"
  ls -ld "$path" | awk '{print $3}'
}

function get_acl_token_ssm_parameter_name {
  local -r cluster_name="$1"
  local -r token_name="${2:-bootstrap}"
  echo "/$cluster_name/token/$token_name"
}

function read_acl_token {
  local -r cluster_name="$1"
  local -r token_name="${2:-bootstrap}"
  local -r aws_region="$3"
  local -r storage_type="$4"
  local -r max_retries="${5:-60}"
  local -r sleep_between_retries="${6:-5}"
  local -r ignore_error="${7:-false}"

  if [[ $storage_type == "ssm" ]]; then
    local parameter_name=$(get_acl_token_ssm_parameter_name $cluster_name $token_name)
    local parameters
    local parameter_exists
    local token

    for (( i=0; i<"$max_retries"; i++ )); do
      parameters=$(aws ssm get-parameters --names $parameter_name --with-decryption --region $aws_region)
      parameter_exists=$(echo $parameters | jq '[.Parameters[]] | length')
      if [[ $parameter_exists -eq 1 ]]; then
        token=$(echo $parameters | jq '.Parameters[0].Value' -r)
        echo $token
        return
      else
        log_info "Parameter $parameter_name does not yet exist."
        sleep "$sleep_between_retries"
      fi
    done
    log_error "Parameter $parameter_name still does not exist after exceeding maximum number of retries."
    if [[ "$ignore_error" == "false" ]]; then
      exit 1
    fi
  else
    log_error "ACL storage type '${storage_type}' is not supported."
    exit 1
  fi
}

function write_acl_token {
  local -r token="$1"
  local -r cluster_name="$2"
  local -r token_name="${3:-bootstrap}"
  local -r aws_region="$4"
  local -r storage_type="$5"

  if [[ $storage_type == "ssm" ]]; then
    local -r parameter_name=$(get_acl_token_ssm_parameter_name $cluster_name $token_name)
    aws ssm put-parameter --name $parameter_name --value $token --type SecureString --region $aws_region
  else
    log_error "ACL storage type '${storage_type}' is not supported."
    exit 1
  fi

}

function generate_consul_config {
  local -r server="${1}"
  local -r config_dir="${2}"
  local -r user="${3}"
  local -r cluster_tag_key="${4}"
  local -r cluster_tag_value="${5}"
  local -r datacenter="${6}"
  local -r enable_gossip_encryption="${7}"
  local -r gossip_encryption_key="${8}"
  local -r enable_rpc_encryption="${9}"
  local -r verify_server_hostname="${10}"
  local -r ca_path="${11}"
  local -r cert_file_path="${12}"
  local -r key_file_path="${13}"
  local -r cleanup_dead_servers="${14}"
  local -r last_contact_threshold="${15}"
  local -r max_trailing_logs="${16}"
  local -r server_stabilization_time="${17}"
  local -r redundancy_zone_tag="${18}"
  local -r disable_upgrade_migration="${19}"
  local -r upgrade_version_tag=${20}
  local -r config_path="$config_dir/$CONSUL_CONFIG_FILE"
  local -r enable_acl="${21}"

  shift 21
  local -r recursors=("$@")

  local instance_id=""
  local instance_ip_address=""
  local instance_region=""
  # https://www.consul.io/docs/agent/options#ui-1
  local ui_config_enabled="false"

  instance_id=$(get_instance_id)
  instance_ip_address=$(get_instance_ip_address)
  instance_region=$(get_instance_region)

  local retry_join_json=""
  if [[ -z "$cluster_tag_key" || -z "$cluster_tag_value" ]]; then
    log_warn "Either the cluster tag key ($cluster_tag_key) or value ($cluster_tag_value) is empty. Will not automatically try to form a cluster based on EC2 tags."
  else
    retry_join_json=$(cat <<EOF
"retry_join": ["provider=aws region=$instance_region tag_key=$cluster_tag_key tag_value=$cluster_tag_value"],
EOF
)
  fi

  local recursors_config=""
  if (( ${#recursors[@]} != 0 )); then
        recursors_config="\"recursors\" : [ "
        for recursor in "${recursors[@]}"
        do
            recursors_config="${recursors_config}\"${recursor}\", "
        done
        recursors_config=$(echo "${recursors_config}"| sed 's/, $//')" ],"
  fi

  local bootstrap_expect=""
  if [[ "$server" == "true" ]]; then
    local instance_tags=""
    local cluster_size=""

    instance_tags=$(get_instance_tags "$instance_id" "$instance_region")
    cluster_size=$(get_cluster_size "$instance_tags" "$instance_region")

    bootstrap_expect="\"bootstrap_expect\": $cluster_size,"
    ui_config_enabled="true"
  fi

  local autopilot_configuration
  autopilot_configuration=$(cat <<EOF
"autopilot": {
  "cleanup_dead_servers": $cleanup_dead_servers,
  "last_contact_threshold": "$last_contact_threshold",
  "max_trailing_logs": $max_trailing_logs,
  "server_stabilization_time": "$server_stabilization_time",
  "redundancy_zone_tag": "$redundancy_zone_tag",
  "disable_upgrade_migration": $disable_upgrade_migration,
  "upgrade_version_tag": "$upgrade_version_tag"
},
EOF
)

  local gossip_encryption_configuration=""
  if [[ "$enable_gossip_encryption" == "true" && -n "$gossip_encryption_key" ]]; then
    log_info "Creating gossip encryption configuration"
    gossip_encryption_configuration="\"encrypt\": \"$gossip_encryption_key\","
  fi

  local rpc_encryption_configuration=""
  if [[ "$enable_rpc_encryption" == "true" && -n "$ca_path" && -n "$cert_file_path" && -n "$key_file_path" ]]; then
    log_info "Creating RPC encryption configuration"
    rpc_encryption_configuration=$(cat <<EOF
"verify_outgoing": true,
"verify_incoming": true,
"verify_server_hostname": $verify_server_hostname,
"ca_path": "$ca_path",
"cert_file": "$cert_file_path",
"key_file": "$key_file_path",
EOF
)
  fi

  local acl_configuration=""
  if [[ "$enable_acl" == "true" ]]; then
    log_info "Creating ACL configuration"
    acl_configuration=$(cat <<EOF
"acl": {
  "enabled": true,
  "default_policy": "deny",
  "enable_token_persistence": true
},
EOF
)
  fi

  log_info "Creating default Consul configuration"
  local default_config_json
  default_config_json=$(cat <<EOF
{
  "advertise_addr": "$instance_ip_address",
  "bind_addr": "$instance_ip_address",
  $bootstrap_expect
  "client_addr": "0.0.0.0",
  "datacenter": "$datacenter",
  "node_name": "$instance_id",
  $recursors_config
  $retry_join_json
  $acl_configuration
  "server": $server,
  $gossip_encryption_configuration
  $rpc_encryption_configuration
  $autopilot_configuration
  "telemetry": {
    "disable_compat_1.9": true
  },
  "ui_config": {
    "enabled": $ui_config_enabled
  }
}
EOF
)
  log_info "Installing Consul config file in $config_path"
  echo "$default_config_json" | jq '.' > "$config_path"
  chown "$user:$user" "$config_path"
}

function generate_bootstrap_acl_token {
  local -r max_retries="$1"
  local -r sleep_between_retries="$2"
  
  local token

  for (( i=0; i<"$max_retries"; i++ )); do
    token=$(consul acl bootstrap -format=json | jq '.SecretID' -r)
    if [[ "$token" == "" ]]; then
      log_info "Token could not be obtained, retrying."
      sleep $sleep_between_retries
    else
      echo $token
      return
    fi
  done

  log_error "Unable to obtain ACL token. Aborting."
  exit 1
}

function generate_node_acl_policy {
  local -r node_name="$1"

  local -r policy_hcl=$(cat <<EOF
node_prefix "" {
  policy = "read"
}

node "${node_name}" {
  policy = "write"
}
EOF
)
  echo $policy_hcl
}

function write_acl_policy {
  local -r policy_name="$1"
  local -r policy_hcl="$2"
  local -r token="$3"

  local token_arg

  if [[ ! "$token" == "" ]]; then
    token_arg="-token $token"
  else
    token_arg=""
  fi

  consul acl policy create -name $policy_name -rules "$policy_hcl" $token_arg
}

function generate_token {
  local -r policy_name="$1"
  local -r description="$2"
  local -r token="$3"

  if [[ ! "$token" == "" ]]; then
    token_arg="-token $token"
  else
    token_arg=""
  fi

  local -r generated_token=$(consul acl token create -format=json -policy-name $policy_name -description "$description" $token_arg | jq '.SecretID' -r)

  echo $generated_token
}

function set_agent_token {
  local -r agent_token="$1"
  local -r token="$2"

  local token_arg
  
  if [[ ! "$token" == "" ]]; then
    token_arg="-token $token"
  else
    token_arg=""
  fi
  
  consul acl set-agent-token $token_arg agent "$token"
}