#!/bin/bash

REPO_URL="https://<ACCESS-TOKEN>@dev.azure.com/devopspractice6680482/Azure-CICD-voting-app/_git/Azure-CICD-voting-app"

# Creating & switching directory
mkdir -p /tmp/azure_repo && cd /tmp/azure_repo

# Cloning the repository on the self hosted agent carrying CI
git clone $REPO_URL .

# Replacing & updating image name under deployment YAML files
sed -i "s|image: .*|image: $1/$2:$3|g" k8s-specifications/$4-deployment.yaml

# Configure Git identity to avoid CI errors
git config user.email "devopspractice668@gmail.com"
git config user.name "devopspractice668"

# Adding files in staging area
git add .

# Commiting the changes
git commit -m "Updating Azure Repo"

# Pushing the changes back to repository.
git push

# Clean up.
rm -rf /tmp/azure_repo