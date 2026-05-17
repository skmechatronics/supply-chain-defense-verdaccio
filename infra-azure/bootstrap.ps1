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

function New-BackendConfigs {
    $modules = @("shared", "app-service-hosting")

    Write-Step "Generating backend.hcl files from templates..."
    foreach ($module in $modules) {
        $samplePath = Join-Path $PSScriptRoot $module "backend.hcl.sample"
        $outputPath = Join-Path $PSScriptRoot $module "backend.hcl"

        if (-not (Test-Path $samplePath)) {
            Write-Fail "Template not found: $samplePath"
            exit 1
        }

        $content = Get-Content $samplePath -Raw
        $content = $content -replace "\{\{RESOURCE_GROUP_NAME\}\}", $ResourceGroup
        $content = $content -replace "\{\{STORAGE_ACCOUNT_NAME\}\}", $StorageAccount
        $content = $content -replace "\{\{CONTAINER_NAME\}\}",       $Container

        Set-Content -Path $outputPath -Value $content -NoNewline
        Write-Ok "Generated: $outputPath"
    }

    Write-Host ""
    Write-Host "Run terraform init in each module with:" -ForegroundColor Cyan
    Write-Host "  terraform init -backend-config=backend.hcl" -ForegroundColor Cyan
}

function Main {
    Invoke-Login
    New-StateResourceGroup
    New-StateStorageAccount
    Enable-Versioning
    New-StateContainer
    Add-ResourceGroupLock
    New-BackendConfigs
}

Main
