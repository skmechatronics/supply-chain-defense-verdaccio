# bootstrap.ps1
# Creates the Azure Storage backend for Terraform state.
# Run once before any terraform init/plan/apply.
#
# Prerequisites: Azure CLI 2.58.0+
#
# Usage:
#   .\bootstrap.ps1
#   .\bootstrap.ps1 -Location "eastus" -LocationAbbr "eus"

param(
    [string]$Location     = "australiaeast",
    [string]$LocationAbbr = "ause",
    [string]$Prefix       = "vdcd"
)

$ErrorActionPreference = "Stop"
$ResourceGroup  = "$Prefix-rg-tfstate-$LocationAbbr"
$StorageAccount = "${Prefix}tfstate${LocationAbbr}"
$Container      = "tfstate"
$LockName       = "$ResourceGroup-lock"

function Write-Step { param([string]$Message); Write-Host $Message -ForegroundColor Yellow }
function Write-Ok   { param([string]$Message); Write-Host $Message -ForegroundColor Green }
function Write-Fail { param([string]$Message); Write-Host $Message -ForegroundColor Red }

function Invoke-Login {
    Write-Step "Logging in to Azure..."
    az login
    if ($LASTEXITCODE -ne 0) { Write-Fail "Login failed."; exit 1 }
    Write-Ok "Logged in."
}

function New-StateResourceGroup {
    Write-Step "Creating resource group: $ResourceGroup"
    az group create --name $ResourceGroup --location $Location | Out-Null
    if ($LASTEXITCODE -ne 0) { Write-Fail "Failed to create resource group."; exit 1 }
    Write-Ok "Resource group ready: $ResourceGroup"
}

function New-StateStorageAccount {
    Write-Step "Creating storage account: $StorageAccount"
    az storage account create `
        --name $StorageAccount `
        --resource-group $ResourceGroup `
        --location $Location `
        --sku Standard_LRS `
        --kind StorageV2 `
        --min-tls-version TLS1_2 `
        --https-only true `
        --allow-blob-public-access false | Out-Null
    if ($LASTEXITCODE -ne 0) { Write-Fail "Failed to create storage account."; exit 1 }
    Write-Ok "Storage account ready: $StorageAccount"
}

function Enable-Versioning {
    Write-Step "Enabling blob versioning on state storage..."
    az storage account blob-service-properties update `
        --account-name $StorageAccount `
        --resource-group $ResourceGroup `
        --enable-versioning true | Out-Null
    if ($LASTEXITCODE -ne 0) { Write-Fail "Failed to enable versioning."; exit 1 }
    Write-Ok "Blob versioning enabled."
}

function New-StateContainer {
    Write-Step "Creating blob container: $Container"
    az storage container create `
        --name $Container `
        --account-name $StorageAccount `
        --auth-mode login | Out-Null
    if ($LASTEXITCODE -ne 0) { Write-Fail "Failed to create container."; exit 1 }
    Write-Ok "Container ready: $Container"
}

function Add-ResourceGroupLock {
    Write-Step "Adding delete lock on resource group: $ResourceGroup"
    az lock create `
        --name $LockName `
        --resource-group $ResourceGroup `
        --lock-type CanNotDelete `
        --notes "Protects Terraform state storage from accidental deletion." | Out-Null
    if ($LASTEXITCODE -ne 0) { Write-Fail "Failed to create lock."; exit 1 }
    Write-Ok "Delete lock applied: $LockName"
}

function Show-BackendConfig {
    Write-Host ""
    Write-Host "Terraform backend configuration:" -ForegroundColor Cyan
    Write-Host "--------------------------------" -ForegroundColor Cyan
    Write-Host "resource_group_name  = `"$ResourceGroup`""
    Write-Host "storage_account_name = `"$StorageAccount`""
    Write-Host "container_name       = `"$Container`""
    Write-Host "key                  = `"<module>.tfstate`"  # e.g. app-service.tfstate"
    Write-Host ""
    Write-Host "Add these values to infra-azure/<module>/backend.tf before running terraform init." -ForegroundColor Yellow
}

function Main {
    Invoke-Login
    New-StateResourceGroup
    New-StateStorageAccount
    Enable-Versioning
    New-StateContainer
    Add-ResourceGroupLock
    Show-BackendConfig
}

Main
