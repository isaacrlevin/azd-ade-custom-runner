This repo contains the container definition for an ADE Custom Runner, which is made available in Private Preview. For more information, see the [docs](https://learn.microsoft.com/en-us/azure/deployment-environments/how-to-configure-extensibility-bicep-container-image)

## What this image does

- Creates a container with the following tools installed on it
  - Azure CLI with BIcep
  - AZD
  - .NET 8
  - Aspire Workload
- Provided a repo and branch via ADE parameters, executes the following steps
  - Clones the repo
  - Checks out the branch
  - Creates AZD Project
  - Enables Resource Group Based Deployment on the project
  - Runs AZD Provision on the project
  - Runs AZD Deploy on the project

After the script completes inside the container, the entire resource stack for the AZD environment will be created in Azure and the app will be deployed to those resources.

## How to use

This runner takes advantage of a "base" image that I have deployed to my personal DockerHub. If you would rather build that base image and push yourself.

```bash
docker build -t {YOUR_DOCKER_USER}/ade-custom-runner-base:latest -f .\Dockerfile.base .
```

After that you will build the image for the actual runner and publish Azure Container Registry (NOTE: you will need to update `Dockerfile` if you are using your own base). Here is how to do this from the official docs.

```bash
docker build . -t {YOUR_REGISTRY}.azurecr.io/ade-custom-runner:latest
az login
az acr login -n {YOUR_REGISTRY}
az acr update -n {YOUR_REGISTRY} --public-network-enabled true
az acr update -n {YOUR_REGISTRY} --anonymous-pull-enabled true
docker push {YOUR_REGISTRY}.azurecr.io/adecustomrunner:{YOUR_TAG}
```

At this point you have a Image Definition deployed to ACR, and you will need to update your Environment Definition `manifest.yml` file to use this new runner.

```bash
runner: "{YOUR_REGISTRY}.azurecr.io/adecustomrunner:latest"
```