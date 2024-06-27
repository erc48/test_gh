#!/bin/bash

# Define variables
SOURCE_REPO="erc48/libreria"
SOURCE_PATH=".github/workflows/test_reusable.yaml"
DEST_PATH=".github/workflows/test_reusable.yaml"

# List all repositories in the organization
repos=$(gh repo list erc48 --json name --jq '.[] | select(.name | test("^ci_")) | .name')

# Loop through the repositories that match the pattern
for repo in $repos; do
  echo "Processing repository: $repo"

  # Clone the destination repository
  gh repo clone erc48/$repo
  cd $repo

  # Create the destination directory if it doesn't exist
  mkdir -p $(dirname $DEST_PATH)

  # Copy the file from the source repository to the destination repository
  gh repo clone $SOURCE_REPO tmp_source_repo
  cp tmp_source_repo/$SOURCE_PATH $DEST_PATH

  # Commit and push the changes
  git add $DEST_PATH
  git commit -m "Add reusable workflow"
  git push origin main

  # Clean up
  cd ..
  rm -rf $repo tmp_source_repo
done
