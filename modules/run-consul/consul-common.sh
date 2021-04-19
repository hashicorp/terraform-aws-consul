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
  fi
  else
    log_error "ACL storage type '${storage_type}' is not supported."
    exit 1
  fi

}