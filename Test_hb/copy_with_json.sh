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

# Read configuration from JSON file
config_file="config.json"
repos=$(jq -c '.files[]' $config_file)

# Loop through the files and repos in the configuration
for repo_config in $repos; do
  source_file=$(echo $repo_config | jq -r '.source')
  repos=$(echo $repo_config | jq -r '.repos[]')

  for repo in $repos; do
    copy_file_to_repo $repo $source_file
  done
done
