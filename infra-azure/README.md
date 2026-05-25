# infra-azure

OpenTofu configuration to deploy the Verdaccio cooldown registry on Azure. Hosting options are independent — pick one and deploy it. Shared infrastructure (resource group, ACR) is provisioned by `shared/` first.

## Prerequisites

- Azure CLI 2.58.0+
- OpenTofu 1.12.0+ — install via [tenv](https://github.com/tofuutils/tenv): `winget install tofuutils.tenv`
- An active Azure subscription
- Docker (to build and push the Verdaccio image to ACR)

## Structure

```
bootstrap.ps1              # one-time setup — creates remote state storage and generates backend configs
deploy.ps1                 # runs tofu init / plan / apply / output / destroy for any module
modules/
  app-service/             # storage account, azure files share, linux app service plan + web app
shared/                    # root module — provisions resource group and ACR, deployed first
  backend.hcl.sample       # backend config template, populated by bootstrap.ps1
app-service-hosting/       # root module — deploys verdaccio on App Service
  backend.hcl.sample       # backend config template, populated by bootstrap.ps1
```

## Deployment order

```
1. bootstrap.ps1          → creates Azure state storage + generates backend.hcl files
2. shared/                → provisions resource group and ACR
3. build + push image     → push verdaccio-cooldown image to ACR
4. app-service-hosting/   → deploys storage account, Azure Files share, and App Service
```

Steps 1 and 2 are one-time. Step 3 is repeated whenever the image changes. Step 4 is re-applied to update the running service.

## 1. Bootstrap

Run once before anything else. Creates the Azure Storage account used as the OpenTofu remote state backend, then generates `backend.hcl` from the templates in each module directory.

```powershell
.\bootstrap.ps1
```

With a non-default region or prefix:

```powershell
.\bootstrap.ps1 -Location "eastus" -LocationAbbr "eus" -Prefix "vdcd"
```

The script:
- Logs in to Azure (skips if already authenticated)
- Creates a dedicated resource group for OpenTofu state (`vdcd-rg-tfstate-ause`)
- Creates a storage account with blob versioning enabled (`vdcdtfstateause`)
- Creates separate blob containers per module (`shared`, `app-service-hosting`)
- Applies a `CanNotDelete` lock on the state resource group
- Generates `backend.hcl` in `shared/` and `app-service-hosting/` from their `backend.hcl.sample` templates

> `backend.hcl` is gitignored. Re-run bootstrap on a fresh clone to regenerate it.

## 2. Deploy shared infrastructure

Use `deploy.ps1` to run OpenTofu actions against any module. If switches are omitted it will prompt for them.

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

This provisions the resource group and ACR (`vdcdacrause`). Check the outputs for the ACR login server name.

## 3. Build and push the Verdaccio image

Use `push-to-acr.ps1` — it builds from `verdaccio-image/`, pushes to ACR, and updates the App Service container config directly via Azure CLI:

```powershell
.\push-to-acr.ps1 -Tag 0.1.0
.\push-to-acr.ps1 -Tag 0.2.0 -MinAgeDays 14
```

After the first push, image config lives outside Terraform. Subsequent image updates are handled by `push-to-acr.ps1` alone — no `tofu apply` needed. Terraform manages infrastructure (App Service Plan, storage, networking); the running image is managed separately.

## 4. Deploy App Service hosting

Copy the outputs from step 2 into `app-service-hosting/terraform.tfvars`, then:

```powershell
.\deploy.ps1 -Module app-service-hosting -Action init
.\deploy.ps1 -Module app-service-hosting -Action plan
.\deploy.ps1 -Module app-service-hosting -Action apply
```

This creates the storage account, Azure Files share, App Service Plan, and Web App in the resource group provisioned by `shared/`. The App Service uses a system-assigned managed identity with AcrPull access — no credentials stored in state.

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

## Future considerations

### Network security

The current setup uses App Service IP access restrictions (`allowed_cidr_ranges` in tfvars). Set this to the client's office or VPN IP range (e.g. `["1.2.3.4/32"]`) — leaving it empty exposes the registry publicly.

The proper solution for production is **VNet integration**: deploy the App Service into a client VNet with a private endpoint, making the registry unreachable from the public internet entirely. This requires a dedicated subnet and a higher App Service SKU (P1v2+).

### Registry authentication

With network-level security in place, no application auth is needed for internal deployments. If the registry must be accessible outside a VNet:

- **`verdaccio-openid-connect`** — OIDC plugin supporting Azure AD, Okta, and Auth0. Developers authenticate with work credentials; npm uses a bearer token in `.npmrc`. Requires an Azure AD app registration in the client's tenant.
- **Azure App Service EasyAuth** — platform-level Azure AD auth, no Verdaccio plugin needed, configured in Terraform. npm CLI requires a pre-generated token in `.npmrc`.
