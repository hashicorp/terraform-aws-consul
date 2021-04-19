#!/bin/bash

set -e

source "/opt/gruntwork/bash-commons/log.sh"
source "/opt/gruntwork/bash-commons/string.sh"
source "/opt/gruntwork/bash-commons/assert.sh"
source "/opt/gruntwork/bash-commons/aws-wrapper.sh"

function get_acl_token_ssm_parameter_name {
  local -r cluster_name="$1"
  echo "/$cluster_name/token/bootstrap"
}

function read_acl_token {
  local -r cluster_name="$1"
  local -r storage_type="$2"
  local -r max_retries="${3:-60}"
  local -r sleep_between_retries="${4:-5}"

  if [[ $storage_type == "ssm" ]]; then
    local parameter_name=$(get_acl_token_ssm_parameter_name $cluster_name)
    local parameters
    local parameter_exists
    local token

    for (( i=0; i<"$max_retries"; i++ )); do
      parameters=$(aws ssm get-parameters --names $parameter_name --with-decryption)
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
    exit 1
  else
    log_error "ACL storage type '${storage_type}' is not supported."
    exit 1
  fi
}

function write_acl_token {
  local -r token="$1"
  local -r cluster_name="$2"
  local -r storage_type="$3"

  if [$storage_type == "ssm"]; then
    local -r parameter_name=$(get_acl_token_ssm_parameter_name $cluster_name)
    aws ssm put-parameter --name $parameter_name --value $token
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

  shift 20
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

  # INPROGRESS: Add step to add ACL section if --enable-acl is set, including token section if client == true
  local acl_configuration=""
  if [[ "$enable_acl" == "true" ]]; then
    log_info "Creating ACL configuration"
    acl_configuration=$(cat <<EOF
"acl": {
  "enabled":true
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