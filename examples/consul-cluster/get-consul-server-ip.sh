#!/bin/bash

readonly SCRIPT_NAME="$(basename "$0")"

readonly MAX_RETRIES=30
readonly SLEEP_BETWEEN_RETRIES_SEC=10

function log {
  local readonly level="$1"
  local readonly message="$2"
  local readonly timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  >&2 echo -e "${timestamp} [${level}] [$SCRIPT_NAME] ${message}"
}

function log_info {
  local readonly message="$1"
  log "INFO" "$message"
}

function log_warn {
  local readonly message="$1"
  log "WARN" "$message"
}

function log_error {
  local readonly message="$1"
  log "ERROR" "$message"
}

function assert_is_installed {
  local readonly name="$1"

  if [[ ! $(command -v ${name}) ]]; then
    log_error "The binary '$name' is required by this script but is not installed or in the system's PATH."
    exit 1
  fi
}

function get_required_terraform_output {
  local readonly output_name="$1"
  local output_value

  output_value=$(terraform output -no-color "$output_name")

  if [[ -z "$output_value" ]]; then
    log_error "Unable to find a value for Terraform output $output_name"
    exit 1
  fi

  echo "$output_value"
}

#
# Usage: join SEPARATOR ARRAY
#
# Joins the elements of ARRAY with the SEPARATOR character between them.
#
# Examples:
#
# join ", " ("A" "B" "C")
#   Returns: "A, B, C"
#
function join {
  local readonly separator="$1"
  shift
  local readonly values=("$@")

  printf "%s$separator" "${values[@]}" | sed "s/$separator$//"
}

function get_consul_server_ip {
  local ips
  local i

  for (( i=1; i<="$MAX_RETRIES"; i++ )); do
    ips=($(get_consul_cluster_ips))
    if [[ "${#ips[@]}" -gt 0 ]]; then
      echo "${ips[0]}"
      return
    else
      log_warn "Did not find any Consul servers. They may still be booting. Will sleep for $SLEEP_BETWEEN_RETRIES_SEC and try again."
      sleep "$SLEEP_BETWEEN_RETRIES_SEC"
    fi
  done

  log_error "Failed to find any Consul servers after $MAX_RETRIES retries."
  exit 1
}

function get_consul_cluster_ips {
  local aws_region
  local cluster_tag_key
  local cluster_tag_value

  aws_region=$(get_required_terraform_output "aws_region")
  cluster_tag_key=$(get_required_terraform_output "consul_servers_cluster_tag_key")
  cluster_tag_value=$(get_required_terraform_output "consul_servers_cluster_tag_value")

  log_info "Fetching public IP addresses for EC2 Instances in $aws_region with tag $cluster_tag_key=$cluster_tag_value"

  aws ec2 describe-instances \
    --region "$aws_region" \
    --filter "Name=tag:$cluster_tag_key,Values=$cluster_tag_value" "Name=instance-state-name,Values=running" | \
    jq -r '.Reservations[].Instances[].PublicIpAddress'
}

function print_instructions {
  local readonly server_ip="$1"

  local instructions=()
  instructions+=("\nFound Consul server at IP address: $server_ip\n")
  instructions+=("Some commands for you to try:\n")
  instructions+=("consul members -rpc-addr=$server_ip:8400")
  instructions+=("consul kv put -http-addr=$server_ip:8500 foo bar")
  instructions+=("consul kv get -http-addr=$server_ip:8500 foo")
  instructions+=("\nTo see the Consul UI, open the following URL in your web browser: http://$server_ip:8500/ui/\n")

  local instructions_str
  instructions_str=$(join "\n" "${instructions[@]}")

  echo -e "$instructions_str"
}

function run {
  assert_is_installed "aws"
  assert_is_installed "jq"
  assert_is_installed "terraform"

  local server_ip
  server_ip=$(get_consul_server_ip)

  print_instructions "$server_ip"
}

run