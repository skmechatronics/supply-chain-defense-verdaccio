# infra-azure

Terraform configuration to deploy the Verdaccio cooldown registry on Azure.

## Prerequisites

- Azure CLI 2.58.0+
- Terraform 1.x
- An active Azure subscription

## Structure

```
bootstrap.ps1        # one-time setup: creates remote state storage account
modules/
  common/            # resource group, azure files share
  app-service/       # app service plan, web app, azure files mount
app-service/         # root module for App Service deployment
```

## First-time setup

Run the bootstrap script once to create the Terraform remote state backend:

```powershell
.\bootstrap.ps1
```

With a custom region:

```powershell
.\bootstrap.ps1 -Location "eastus" -LocationAbbr "eus"
```

The script will output the backend configuration values to add to your `backend.tf` before running `terraform init`.

## Deploying

```powershell
cd app-service
terraform init
terraform plan -var-file="terraform.tfvars"
terraform apply -var-file="terraform.tfvars"
```
