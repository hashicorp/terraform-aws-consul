#!/bin/bash

set -e

function get_acl_token_parameter_name {
  local -r cluster_name="$1"
  local -r token_name="${2:-bootstrap}"
  echo "/$cluster_name/token/$token_name"
}

function read_acl_token {
  local -r cluster_name="$1"
  local -r token_name="${2:-bootstrap}"
  local -r aws_region="$3"
  local -r max_retries="${4:-60}"
  local -r sleep_between_retries="${5:-5}"
  local -r ignore_error="${6:-false}"

  local parameter_name=$(get_acl_token_parameter_name $cluster_name $token_name)
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
}

function write_acl_token {
  local -r token="$1"
  local -r cluster_name="$2"
  local -r token_name="${3:-bootstrap}"
  local -r aws_region="$4"
  local -r storage_type="$5"

  local -r parameter_name=$(get_acl_token_parameter_name $cluster_name $token_name)
  aws ssm put-parameter --name $parameter_name --value $token --type SecureString --region $aws_region

}