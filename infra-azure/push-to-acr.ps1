# push-to-acr.ps1
# Builds the Verdaccio image, pushes it to ACR, and updates the App Service container config.
# After the first run, image config lives outside Terraform — subsequent pushes update the
# App Service directly without a tofu apply.
#
# Prerequisites: Azure CLI 2.58.0+, Docker
#
# Usage:
#   .\push-to-acr.ps1 -Tag 0.1.0
#   .\push-to-acr.ps1 -Tag 0.2.0 -MinAgeDays 14 -Prefix vdcd -LocationAbbr ause

param(
    [Parameter(Mandatory)]
    [string]$Tag,

    [int]$MinAgeDays          = 7,
    [string]$PackageBlocks    = "",
    [string]$PackageOverrides = "",
    [string]$Prefix           = "vdcd",
    [string]$LocationAbbr     = "ause"
)

$ErrorActionPreference = "Stop"

$AcrName       = "${Prefix}acr${LocationAbbr}"
$AppName       = "${Prefix}-app-${LocationAbbr}"
$ResourceGroup = "${Prefix}-rg-${LocationAbbr}"
$ImageRepo     = "verdaccio-cooldown"
$FullImage     = "${AcrName}.azurecr.io/${ImageRepo}:${Tag}"
$BuildContext  = Join-Path $PSScriptRoot "..\verdaccio-image"

function Write-Step { param([string]$Message); Write-Host $Message -ForegroundColor Yellow }
function Write-Ok   { param([string]$Message); Write-Host $Message -ForegroundColor Green }
function Write-Fail { param([string]$Message); Write-Host $Message -ForegroundColor Red }

Write-Step "Logging in to ACR: $AcrName"
az acr login --name $AcrName
if ($LASTEXITCODE -ne 0) { Write-Fail "ACR login failed."; exit 1 }

Write-Step "Building image: $FullImage (minAgeDays=$MinAgeDays)"
docker build --build-arg MIN_AGE_DAYS=$MinAgeDays -t $FullImage $BuildContext
if ($LASTEXITCODE -ne 0) { Write-Fail "Docker build failed."; exit 1 }
Write-Ok "Build complete."

Write-Step "Pushing image: $FullImage"
docker push $FullImage
if ($LASTEXITCODE -ne 0) { Write-Fail "Docker push failed."; exit 1 }
Write-Ok "Push complete."

Write-Step "Updating App Service container config: $AppName"
az webapp config container set `
    --name $AppName `
    --resource-group $ResourceGroup `
    --docker-custom-image-name $FullImage
if ($LASTEXITCODE -ne 0) { Write-Fail "Failed to update App Service container config."; exit 1 }
Write-Ok "App Service updated. Image: $FullImage"

$appSettings = @("PACKAGE_BLOCKS=$PackageBlocks", "PACKAGE_OVERRIDES=$PackageOverrides")
Write-Step "Updating app settings (PACKAGE_BLOCKS, PACKAGE_OVERRIDES)"
az webapp config appsettings set `
    --name $AppName `
    --resource-group $ResourceGroup `
    --settings @appSettings | Out-Null
if ($LASTEXITCODE -ne 0) { Write-Fail "Failed to update app settings."; exit 1 }
Write-Ok "App settings updated."
