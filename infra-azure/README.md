# infra-azure

Terraform configuration to deploy the Verdaccio cooldown registry on Azure. Hosting options are independent — pick one and deploy it. Both use the same shared infrastructure (ACR, storage, resource group) provisioned by `shared/`.

## Prerequisites

- Azure CLI 2.58.0+
- Terraform 1.x
- An active Azure subscription
- Docker (to build and push the Verdaccio image to ACR)

## Structure

```
bootstrap.ps1              # one-time setup — creates remote state storage and generates backend configs
deploy.ps1                 # runs terraform init / plan / apply / output for any module
modules/
  common/                  # resource group, storage account, azure files share, ACR
  app-service/             # linux app service plan + web app with azure files mount
shared/                    # root module — provisions common infra, deployed first
  backend.hcl.sample       # backend config template, populated by bootstrap.ps1
app-service-hosting/       # root module — deploys verdaccio on App Service
  backend.hcl.sample       # backend config template, populated by bootstrap.ps1
```

## Deployment order

```
1. bootstrap.ps1          → creates Azure state storage + generates backend.hcl files
2. shared/                → provisions ACR, storage, resource group
3. build + push image     → push verdaccio-cooldown image to ACR
4. app-service-hosting/   → deploys App Service, pulls image from ACR
```

Steps 1 and 2 are one-time. Step 3 is repeated whenever the image changes. Step 4 is re-applied to update the running service.

## 1. Bootstrap

Run once before anything else. Creates the Azure Storage account used as the Terraform remote state backend, then generates `backend.hcl` from the templates in each module directory.

```powershell
.\bootstrap.ps1
```

With a non-default region or prefix:

```powershell
.\bootstrap.ps1 -Location "eastus" -LocationAbbr "eus" -Prefix "vdcd"
```

The script:
- Logs in to Azure (skips if already authenticated)
- Creates a dedicated resource group for Terraform state (`vdcd-rg-tfstate-ause`)
- Creates a storage account with blob versioning enabled (`vdcdtfstateause`)
- Creates a `tfstate` blob container
- Applies a `CanNotDelete` lock on the state resource group
- Generates `backend.hcl` in `shared/` and `app-service-hosting/` from their `backend.hcl.sample` templates

> `backend.hcl` is gitignored. Re-run bootstrap on a fresh clone to regenerate it.

## 2. Deploy shared infrastructure

Use `deploy.ps1` to run Terraform actions against any module. If switches are omitted it will prompt for them.

```powershell
.\deploy.ps1 -Module shared -Action init
.\deploy.ps1 -Module shared -Action plan
.\deploy.ps1 -Module shared -Action apply
.\deploy.ps1 -Module shared -Action output
```

Or just run `.\deploy.ps1` and follow the prompts.

`deploy.ps1` will:
- Error early if `backend.hcl` is missing (tells you to run bootstrap first)
- Copy `terraform.tfvars.sample` to `terraform.tfvars` automatically if it doesn't exist, then pause so you can review it before continuing

This provisions the resource group, Azure Files share, and ACR (`vdcdacrause`). Check the outputs for the ACR login server name.

## 3. Build and push the Verdaccio image

```powershell
az acr login --name vdcdacrause
docker build -t vdcdacrause.azurecr.io/verdaccio-cooldown:0.1.0 ..\local-registry
docker push vdcdacrause.azurecr.io/verdaccio-cooldown:0.1.0
```

## 4. Deploy App Service hosting

```powershell
.\deploy.ps1 -Module app-service-hosting -Action init
.\deploy.ps1 -Module app-service-hosting -Action plan
.\deploy.ps1 -Module app-service-hosting -Action apply
```

Set `verdaccio_image_tag` in `terraform.tfvars` to match the tag you pushed in step 3. The App Service reads shared infrastructure (ACR credentials, storage account, resource group) directly from the `shared/` Terraform state — no manual wiring needed.

## Naming convention

Resources follow the pattern `{prefix}-{type}-{region}` (e.g. `vdcd-rg-ause`, `vdcd-app-ause`). Storage account names drop hyphens due to Azure restrictions (e.g. `vdcdstaccause`).

| Resource | Name |
|---|---|
| State resource group | `vdcd-rg-tfstate-ause` |
| State storage account | `vdcdtfstateause` |
| App resource group | `vdcd-rg-ause` |
| Storage account | `vdcdstaccause` |
| ACR | `vdcdacrause` |
| App Service Plan | `vdcd-asp-ause` |
| Web App | `vdcd-app-ause` |
