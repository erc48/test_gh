#!/bin/bash

# Define variables
SOURCE_REPO="erc48/libreria"
SOURCE_DIR="./github/shared_workflows"
DEST_DIR=".github/workflows"

# Function to clone repo and copy file
copy_file_to_repo() {
  local repo=$1
  local source_file=$2
  local dest_file="$DEST_DIR/$source_file"

  echo "Processing repository: $repo"

  # Clone the destination repository
  gh repo clone erc48/$repo
  cd $repo

  # Create the destination directory if it doesn't exist
  mkdir -p $(dirname $dest_file)

  # Copy the file from the source repository to the destination repository
  gh repo clone $SOURCE_REPO tmp_source_repo
  cp tmp_source_repo/$SOURCE_DIR/$source_file $dest_file

  # Commit and push the changes
  git add $dest_file
  git commit -m "Add reusable workflow $source_file"
  git push origin main

  # Clean up
  cd ..
  rm -rf $repo tmp_source_repo
}

# Function to set up rulesets
setup_ruleset() {
  local repo=$1
  local ruleset_name=$2
  local active=$3
  local branches=("${!4}")
  local require_status_checks=$5
  local checks=("${!6}")

  # Convert branches array to JSON array
  branches_json=$(printf '%s\n' "${branches[@]}" | jq -R . | jq -s .)

  # Convert checks array to JSON array
  checks_json=$(printf '%s\n' "${checks[@]}" | jq -R . | jq -s .)

  # Create ruleset payload
  ruleset_payload=$(jq -n \
    --arg name "$ruleset_name" \
    --argjson active "$active" \
    --argjson branches "$branches_json" \
    --argjson require_status_checks "$require_status_checks" \
    --argjson checks "$checks_json" \
    '{
      name: $name,
      active: $active,
      conditions: {
        ref_name: {
          include: $branches
        }
      },
      enforcement: {
        enabled: true,
        require_status_checks: {
          enabled: $require_status_checks,
          contexts: $checks
        }
      }
    }')

  # Create ruleset using GitHub CLI
  echo "$ruleset_payload" | gh api -X POST \
    -H "Accept: application/vnd.github+json" \
    "/repos/erc48/$repo/rulesets" \
    --input -
}

# Read configuration from JSON file
config_file="config.json"
repos=$(jq -c '.files[]' $config_file)
rulesets=$(jq -c '.rulesets[]' $config_file)

# Loop through the files and repos in the configuration
for repo_config in $repos; do
  source_file=$(echo $repo_config | jq -r '.source')
  repos=$(echo $repo_config | jq -r '.repos[]')

  for repo in $repos; do
    copy_file_to_repo $repo $source_file
  done
done

# Loop through the rulesets in the configuration
for ruleset_config in $rulesets; do
  ruleset_name=$(echo $ruleset_config | jq -r '.name')
  active=$(echo $ruleset_config | jq -r '.active')
  require_status_checks=$(echo $ruleset_config | jq -r '.require_status_checks.required')
  checks=$(echo $ruleset_config | jq -r '.require_status_checks.checks[]')

  repos=$(echo $ruleset_config | jq -r '.repos | keys[]')
  for repo in $repos; do
    branches=($(echo $ruleset_config | jq -r --arg repo "$repo" '.repos[$repo][]'))
    setup_ruleset $repo $ruleset_name $active branches[@] $require_status_checks checks[@]
  done
done
