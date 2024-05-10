#!/bin/bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
set -e # exit on error

DIR=$(dirname "$0")
source  $DIR/_common.sh

deploymentName=$(date +"%Y-%m-%d-%H%M%S")
deploymentOutput=""
echo "$ADE_OPERATION_PARAMETERS"
# format the parameters as arm parameters
branchName=$(echo "$ADE_OPERATION_PARAMETERS" | jq '.branch')
repoUrl=$(echo "$ADE_OPERATION_PARAMETERS" | jq '.repoUrl')

# Today azd cli does not support managed identity login, so need to login with a service principal
# echo "Signing into AZD using MSI"
# while true; do
#     # managed identity isn't available immediately
#     # we need to do retry after a short nap
#     az login --identity --allow-no-subscriptions --only-show-errors --output none 2> $ADE_ERROR_LOG && {
#         echo "Successfully signed into Azure"
#         break
#     } || sleep 5
# done

# Get SP details from ADE_OPERATION_PARAMETERS
appId=$(echo "$ADE_OPERATION_PARAMETERS" | jq '.appId')
appSecret=$(echo "$ADE_OPERATION_PARAMETERS" | jq '.appsecret')
tenant=$(echo "$ADE_OPERATION_PARAMETERS" | jq '.tenantid')

login=$(az login --service-principal -u $appId -p $appSecret --tenant $tenant)

azd config set auth.useAzCliAuth true

if [ -z "$repoUrl" ]; then
  echo "No Repo Provided. Exiting."
  exit 1
else
  repoUrl=`sed -e 's/^"//' -e 's/"$//' <<<"$repoUrl"`
  echo "Cloning https://github.com/$repoUrl.git"
  git clone "https://github.com/$repoUrl.git" repo --quiet
fi

cd repo
git fetch --quiet
echo "$branchName"

if [ -v branchName ]; then
    if [ -z "$branchName" ]  ; then
      echo "No branch name provided. Using default branch"
    else
      branchName=`sed -e 's/^"//' -e 's/"$//' <<<"$branchName"`
      echo "Checking out $branchName branch"
      git checkout "$branchName" --quiet
    fi
else
    echo "No branch name provided. Using default branch"
fi

if [ -d "$ADE_STORAGE/.azure" ]; then
  echo ".azure folder already exists. Existing Environment. Copying to directory"
  mkdir -p ".azure"
  cp -a "$ADE_STORAGE/.azure" .
else
  echo ".azure folder does not exist. New environment"
  export AZURE_ENV_NAME="eShop"
  export AZURE_LOCATION=$ADE_ENVIRONMENT_LOCATION
  export AZURE_SUBSCRIPTION_ID=$ADE_SUBSCRIPTION_ID

  export AZD_INITIAL_ENVIRONMENT_CONFIG=$(cat <<-EOF
{
  "services": {
    "app": {
      "config": {
        "exposedServices": [
          "webapp"
        ]
      }
    }
  }
}
EOF
)
fi

export AZD_DEBUG_DOTNET_APPHOST_USE_RESOURCE_GROUP_DEPLOYMENTS="true"
export AZURE_RESOURCE_GROUP=$ADE_RESOURCE_GROUP_NAME
azd config set alpha.resourceGroupDeployments on

echo $AZURE_RESOURCE_GROUP
echo $AZD_DEBUG_DOTNET_APPHOST_USE_RESOURCE_GROUP_DEPLOYMENTS


azd provision --no-prompt > "azdProvision.txt"

if [ $? -eq 0 ]; then
    provisionContnet=$(cat "azdProvision.txt")
    echo "$provisionContnet"
    #azd deploy --no-prompt > "azdDeploy.txt"
    # if [ $? -eq 0 ]; then
    #   deployContent=$(cat "azdDeploy.txt")
    #   echo "Outputs successfully generated for ADE"
    #   echo "$deployContent"
    #   mkdir -p "$ADE_STORAGE/.azure"
    #   cp -a ".azure/" "$ADE_STORAGE/"
    #   echo "Copied .azure folder to persistent storage"
    # else
    #     content=$(cat "azdDeploy.txt")
    #     echo "$content"
    # fi
        echo -e "\n>>> Generating outputs for ADE...\n"

    deploymentOutput=$(az deployment group show -g "$ADE_RESOURCE_GROUP_NAME" -n "$deploymentName" --query properties.outputs)
    if [ -z "$deploymentOutput" ]; then
        deploymentOutput="{}"
    fi
    echo "{\"outputs\": $deploymentOutput}" > $ADE_OUTPUTS
    echo "Outputs successfully generated for ADE"
else
    echo "Deployment failed to create."
fi