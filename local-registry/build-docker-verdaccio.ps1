# build-docker-verdaccio.ps1
# Build the verdaccio-cooldown Docker image with a configurable cooldown window.
#
# Usage:
#   .\build-docker-verdaccio.ps1
#   .\build-docker-verdaccio.ps1 -MinAgeDays 14

param(
    [ValidateRange(1, 90)]
    [int]$MinAgeDays = 7
)

$ErrorActionPreference = "Stop"

$ContainerName = "verdaccio-dev"
$ImageName     = "verdaccio-cooldown:0.1.0"
$ConfigPath    = "$PSScriptRoot\conf\config.yaml"

function Write-Progress-Step { param([string]$Message); Write-Host $Message -ForegroundColor Yellow }
function Write-Success       { param([string]$Message); Write-Host $Message -ForegroundColor Green }
function Write-Error-Step    { param([string]$Message); Write-Host $Message -ForegroundColor Red }

function Update-ConfigCooldown {
    $templatePath = "$PSScriptRoot\conf\config-template.yaml"
    $configPath   = "$PSScriptRoot\conf\config.yaml"

    Write-Progress-Step "Generating config.yaml from template with minAgeDays=$MinAgeDays"

    if (-not (Test-Path $templatePath)) {
        Write-Error-Step "Template not found: $templatePath"
        exit 1
    }

    $template = Get-Content $templatePath -Raw
    $config   = $template -replace "\{\{MIN_AGE_DAYS\}\}", $MinAgeDays

    if ($config -eq $template) {
        Write-Error-Step "Placeholder {{MIN_AGE_DAYS}} not found in template."
        exit 1
    }

    Set-Content -Path $configPath -Value $config -NoNewline
    Write-Success "Generated $configPath"
}

function Remove-ExistingContainer {
    Write-Progress-Step "Checking for existing container: $ContainerName"
    $existing = docker ps -a --filter "name=^${ContainerName}$" --format "{{.Names}}"
    if ($existing) {
        Write-Progress-Step "Removing existing container: $ContainerName"
        docker rm -f $ContainerName | Out-Null
        Write-Success "Removed existing container."
    } else {
        Write-Success "No existing container to remove."
    }
}

function Build-Image {
    Write-Progress-Step "Building image: $ImageName"
    docker build -t $ImageName $PSScriptRoot
    if ($LASTEXITCODE -ne 0) {
        Write-Error-Step "Docker build failed."
        exit 1
    }
    Write-Success "Image built: $ImageName"
}

function Start-Container {
    Write-Progress-Step "Starting container: $ContainerName"
    docker run -d `
        --name $ContainerName `
        -p 4873:4873 `
        -v "${PSScriptRoot}\conf:/verdaccio/conf" `
        -v "${PSScriptRoot}\storage:/verdaccio/storage" `
        $ImageName | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Error-Step "Failed to start container."
        exit 1
    }
    Write-Success "Container started: $ContainerName"
}

function Wait-ForVerdaccio {
    Write-Progress-Step "Waiting for Verdaccio to respond..."
    for ($i = 0; $i -lt 20; $i++) {
        try {
            Invoke-RestMethod -Uri "http://localhost:4873/-/ping" -TimeoutSec 1 | Out-Null
            Write-Success "Verdaccio is up at http://localhost:4873"
            return
        } catch {
            Start-Sleep -Milliseconds 500
        }
    }
    Write-Error-Step "Verdaccio did not respond in time. Check 'docker logs $ContainerName'."
    exit 1
}

function Main {
    Update-ConfigCooldown
    Remove-ExistingContainer
    Build-Image
    Start-Container
    Wait-ForVerdaccio
}

Main