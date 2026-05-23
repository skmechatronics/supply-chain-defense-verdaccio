# push-to-acr.ps1
# Builds the Verdaccio image, pushes it to ACR, and applies app-service-hosting.
#
# Prerequisites: Azure CLI 2.58.0+, Docker, OpenTofu (via tenv)
#
# Usage:
#   .\push-to-acr.ps1 -Tag 0.1.0
#   .\push-to-acr.ps1 -Tag 0.2.0 -MinAgeDays 14 -Prefix vdcd -LocationAbbr ause

param(
    [Parameter(Mandatory)]
    [string]$Tag,

    [int]$MinAgeDays      = 7,
    [string]$Prefix       = "vdcd",
    [string]$LocationAbbr = "ause"
)

$ErrorActionPreference = "Stop"

$AcrName      = "${Prefix}acr${LocationAbbr}"
$ImageRepo    = "verdaccio-cooldown"
$FullImage    = "${AcrName}.azurecr.io/${ImageRepo}:${Tag}"
$BuildContext = Join-Path $PSScriptRoot "..\verdaccio-image"
$TfVarsPath   = Join-Path $PSScriptRoot "app-service-hosting\terraform.tfvars"

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

Write-Step "Updating terraform.tfvars..."
$content = Get-Content $TfVarsPath
$content = $content -replace '^docker_registry_url\s*=.*', "docker_registry_url = `"https://${AcrName}.azurecr.io`""
$content = $content -replace '^docker_image_name\s*=.*',   "docker_image_name   = `"${ImageRepo}:${Tag}`""
Set-Content $TfVarsPath $content
Write-Ok "terraform.tfvars updated."

Write-Step "Applying app-service-hosting..."
& "$PSScriptRoot\deploy.ps1" -Module app-service-hosting -Action apply
