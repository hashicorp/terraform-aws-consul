#!/bin/bash
#
# Build the example AMI, copy it to all AWS regions, and make all AMIs public. 
#
# This script is meant to be run in a CircleCI job.
#

set -e

if [[ "$#" -ne 2 ]]; then
  echo "Usage: publish-amis.sh PACKER_TEMPLATE_PATH BUILDER_NAME"
  exit 1
fi

if [[ -z "$PUBLISH_AMI_AWS_ACCESS_KEY_ID" || -z "$PUBLISH_AMI_AWS_SECRET_ACCESS_KEY" ]]; then
  echo "The PUBLISH_AMI_AWS_ACCESS_KEY_ID and PUBLISH_AMI_AWS_SECRET_ACCESS_KEY environment variables must be set to the AWS credentials to use to publish the AMIs."
  exit 1
fi

readonly packer_template_path="$1"
readonly builder_name="$2"

regions_response=$(aws ec2 describe-regions --region "us-east-1")
all_aws_regions=$(echo "$regions_response" | jq -r '.Regions | map(.RegionName) | join(",")')

echo "Building Packer template $packer_template_path (builder: $builder_name) and sharing it with all AWS accounts in the following regions: $all_aws_regions"

# Copying AMIs to many regions can take longer than Packer's default wait timeouts, so we increase them here per
# https://github.com/hashicorp/packer/issues/6536
export AWS_MAX_ATTEMPTS=240
export AWS_POLL_DELAY_SECONDS=15

# We publish the AMIs to a different AWS account, so set those credentials
export AWS_ACCESS_KEY_ID="$PUBLISH_AMI_AWS_ACCESS_KEY_ID"
export AWS_SECRET_ACCESS_KEY="$PUBLISH_AMI_AWS_SECRET_ACCESS_KEY"

packer build \
  --only="$builder_name" \
  -var copy_ami_to_regions="$all_aws_regions" \
  -var share_ami_with_groups="all" \
  "$packer_template_path"
