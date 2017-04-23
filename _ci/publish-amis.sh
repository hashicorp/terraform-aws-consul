#!/bin/bash
#
# Build the example AMI, copy it to all AWS regions, and make all AMIs public. 
#
# This script is meant to be run in a CircleCI job.
#

set -e

readonly PACKER_TEMPLATE_PATH="$CIRCLE_PROJECT_NAME/examples/consul-ami/consul.json"
readonly PACKER_TEMPLATE_DEFAULT_REGION="us-east-1"
readonly API_PROPERTIES_FILE="/tmp/api.properties"
readonly AMI_LIST_MARKDOWN_PATH="$CIRCLE_PROJECT_NAME/_docs/amis.md"
readonly GIT_COMMIT_MESSAGE="Add latest AMI IDs."
readonly GIT_USER_NAME="gruntwork-ci"
readonly GIT_USER_EMAIL="ci@gruntwork.io"

# Build the example AMI
build-packer-artifact \
  --packer-template-path "$PACKER_TEMPLATE_PATH" \
  --output-properties-file "$API_PROPERTIES_FILE"

# Copy the AMI to all regions and make it public in each
source "$API_PROPERTIES_FILE"
publish-ami \
  --all-regions \
  --source-ami-id "$ARTIFACT_ID" \
  --source-ami-region "$PACKER_TEMPLATE_DEFAULT_REGION" \
  --output-markdown > "$AMI_LIST_MARKDOWN_PATH"

# Git add, commit, and push the newly created AMI IDs as a markdown doc to the repo
git-add-commit-push \
  --path "$AMI_LIST_MARKDOWN_PATH" \
  --message "$GIT_COMMIT_MESSAGE" \
  --skip-ci-flag \
  --user-name "$GIT_USER_NAME" \
  --user-email "$GIT_USER_EMAIL"
