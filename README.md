This repo contains the container definition for an ADE Custom Runner, which is made available in Private Preview. For more information, see the [docs](https://github.com/Azure/deployment-environments/blob/custom-runner-private-preview/documentation/custom-image-support/README.md)

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
