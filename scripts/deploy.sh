#!/bin/bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
set -e # exit on error

DIR=$(dirname "$0")
source  $DIR/_common.sh

deploymentName=$(date +"%Y-%m-%d-%H%M%S")
deploymentOutput=""

# format the parameters as arm parameters
deploymentParameters=$(echo "$ADE_OPERATION_PARAMETERS" | jq --compact-output '{ "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#", "contentVersion": "1.0.0.0", "parameters": (to_entries | if length == 0 then {} else (map( { (.key): { "value": .value } } ) | add) end) }' )

echo "Signing into AZD using MSI"
while true; do
    # managed identity isn't available immediately
    # we need to do retry after a short nap
    az login --identity --allow-no-subscriptions --only-show-errors --output none 2> $ADE_ERROR_LOG && {
        echo "Successfully signed into Azure"
        break
    } || sleep 5
done

azd config set auth.useAzCliAuth true

git clone https://github.com/isaaclevintest/eShop.git

cd eShop

export AZURE_ENV_NAME="eShop"
export AZURE_LOCATION=$ADE_ENVIRONMENT_LOCATION
export AZURE_SUBSCRIPTION_ID=$ADE_SUBSCRIPTION_ID
export AZD_DEBUG_DOTNET_APPHOST_USE_RESOURCE_GROUP_DEPLOYMENTS="true"
export AZURE_RESOURCE_GROUP=$ADE_RESOURCE_GROUP_NAME

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

echo "AZURE_ENV_NAME: $AZURE_ENV_NAME"
echo "AZURE_LOCATION: $AZURE_LOCATION"
echo "AZURE_SUBSCRIPTION_ID: $AZURE_SUBSCRIPTION_ID"
echo "AZD_INITIAL_ENVIRONMENT_CONFIG: $AZD_INITIAL_ENVIRONMENT_CONFIG"
echo "AZURE_RESOURCE_GROUP: $AZURE_RESOURCE_GROUP"
azd config set alpha.resourceGroupDeployments on

azd provision --no-prompt > "azdProvision.txt"

if [ $? -eq 0 ]; then
    provisionContnet=$(cat "azdProvision.txt")
    echo "$provisionContnet"
    azd deploy --no-prompt > "azdDeploy.txt"
    if [ $? -eq 0 ]; then
      deployContent=$(cat "azdDeploy.txt")
      echo "Outputs successfully generated for ADE"
      echo "$deployContent"
    else
        content=$(cat "azdDeploy.txt")
        echo "$content"
    fi
else
    echo "Deployment failed to create."
fi