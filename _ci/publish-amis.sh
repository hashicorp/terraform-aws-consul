#!/bin/bash
#
# Build the example AMI, copy it to all AWS regions, and make all AMIs public. 
#
# This script is meant to be run in a CircleCI job.
#

set -e

readonly PACKER_TEMPLATE_PATH="/home/ubuntu/$CIRCLE_PROJECT_REPONAME/examples/consul-ami/consul.json"
readonly PACKER_TEMPLATE_DEFAULT_REGION="us-east-1"

# In CircleCI, every build populates the branch name in CIRCLE_BRANCH except builds triggered by a new tag, for which
# the CIRCLE_BRANCH env var is empty. We assume tags are only issued against the master branch.
readonly BRANCH_NAME="${CIRCLE_BRANCH:-master}"

readonly PACKER_BUILD_NAME="$1"

if [[ -z "$PACKER_BUILD_NAME" ]]; then
  echo "ERROR: You must pass in the Packer build name as the first argument to this function."
  exit 1
fi

echo "Checking out branch $BRANCH_NAME to make sure we do all work in a branch and not in detached HEAD state"
git checkout "$BRANCH_NAME"

regions_response=$(aws ec2 describe-regions --region "$PACKER_TEMPLATE_DEFAULT_REGION")
all_aws_regions=$(echo "$regions_response" | jq -r '.Regions | map(.RegionName) | join(",")')

packer build \
  --only="$PACKER_BUILD_NAME" \
  -var copy_ami_to_regions="$all_aws_regions" \
  -var share_ami_with_groups="all" \
  "$PACKER_TEMPLATE_PATH"
