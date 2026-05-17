# deploy.ps1
# Runs Terraform actions against a root module.
#
# Usage:
#   .\deploy.ps1                                      # prompts for module and action
#   .\deploy.ps1 -Module shared -Action plan
#   .\deploy.ps1 -Module app-service-hosting -Action apply

param(
    [ValidateSet("shared", "app-service-hosting")]
    [string]$Module,

    [ValidateSet("init", "plan", "apply", "output", "destroy")]
    [string]$Action
)

$ErrorActionPreference = "Stop"

$ValidModules  = @("shared", "app-service-hosting")
$ValidActions  = @("init", "plan", "apply", "output", "destroy")

function Write-Step { param([string]$Message); Write-Host $Message -ForegroundColor Yellow }
function Write-Ok   { param([string]$Message); Write-Host $Message -ForegroundColor Green }
function Write-Fail { param([string]$Message); Write-Host $Message -ForegroundColor Red }

function Resolve-Module {
    if ($Module) { return $Module }

    Write-Host ""
    Write-Host "Available modules:" -ForegroundColor Cyan
    for ($i = 0; $i -lt $ValidModules.Count; $i++) {
        Write-Host "  [$($i + 1)] $($ValidModules[$i])"
    }

    do {
        $input = Read-Host "Select module (1-$($ValidModules.Count))"
        $index = [int]$input - 1
    } while ($index -lt 0 -or $index -ge $ValidModules.Count)

    return $ValidModules[$index]
}

function Resolve-Action {
    if ($Action) { return $Action }

    Write-Host ""
    Write-Host "Available actions:" -ForegroundColor Cyan
    for ($i = 0; $i -lt $ValidActions.Count; $i++) {
        Write-Host "  [$($i + 1)] $($ValidActions[$i])"
    }

    do {
        $input = Read-Host "Select action (1-$($ValidActions.Count))"
        $index = [int]$input - 1
    } while ($index -lt 0 -or $index -ge $ValidActions.Count)

    return $ValidActions[$index]
}

function Assert-BackendConfig {
    param([string]$ModuleDir)
    $backendHcl = Join-Path $ModuleDir "backend.hcl"
    if (-not (Test-Path $backendHcl)) {
        Write-Fail "backend.hcl not found in $ModuleDir."
        Write-Host "Run .\bootstrap.ps1 first to generate it." -ForegroundColor Yellow
        exit 1
    }
}

function Assert-TfVars {
    param([string]$ModuleDir)
    $tfvars   = Join-Path $ModuleDir "terraform.tfvars"
    $sample   = Join-Path $ModuleDir "terraform.tfvars.sample"

    if (-not (Test-Path $tfvars)) {
        if (Test-Path $sample) {
            Copy-Item $sample $tfvars
            Write-Ok "Created terraform.tfvars from sample."
            Write-Host "Review $tfvars before continuing." -ForegroundColor Yellow
            $confirm = Read-Host "Press Enter to continue or Ctrl+C to abort"
        } else {
            Write-Fail "terraform.tfvars not found and no sample to copy from: $ModuleDir"
            exit 1
        }
    }
}

function Invoke-TerraformAction {
    param([string]$ModuleDir, [string]$TfAction)

    Push-Location $ModuleDir
    try {
        switch ($TfAction) {
            "init" {
                Write-Step "Running terraform init..."
                terraform init -backend-config="backend.hcl"
            }
            "plan" {
                Write-Step "Running terraform plan..."
                terraform plan -var-file="terraform.tfvars"
            }
            "apply" {
                Write-Step "Running terraform apply..."
                terraform apply -var-file="terraform.tfvars"
            }
            "output" {
                Write-Step "Running terraform output..."
                terraform output
            }
            "destroy" {
                Write-Step "Running terraform destroy..."
                terraform destroy -var-file="terraform.tfvars"
            }
        }

        if ($LASTEXITCODE -ne 0) {
            Write-Fail "terraform $TfAction failed."
            exit 1
        }

        Write-Ok "terraform $TfAction completed."
    } finally {
        Pop-Location
    }
}

function Main {
    $resolvedModule = Resolve-Module
    $resolvedAction = Resolve-Action
    $moduleDir      = Join-Path $PSScriptRoot $resolvedModule

    Write-Host ""
    Write-Step "Module: $resolvedModule | Action: $resolvedAction"

    if ($resolvedAction -ne "output") {
        Assert-BackendConfig -ModuleDir $moduleDir
    }

    if ($resolvedAction -in @("plan", "apply", "destroy")) {
        Assert-TfVars -ModuleDir $moduleDir
    }

    Invoke-TerraformAction -ModuleDir $moduleDir -TfAction $resolvedAction
}

Main
