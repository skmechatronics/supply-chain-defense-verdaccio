# build-and-check.ps1
# Orchestrator: build the image, start the container, then verify the filter.
#
# Usage:
#   .\build-and-check.ps1
#   .\build-and-check.ps1 -MinAgeDays 14
#   .\build-and-check.ps1 -MinAgeDays 14 -Packages axios,react
#   .\build-and-check.ps1 -VerdaccioUrl "http://localhost:4873"

param(
    [ValidateRange(1, 90)]
    [int]$MinAgeDays = 7,
    [string[]]$Packages = @("axios", "@types/node", "eslint", "vite", "typescript"),
    [string]$VerdaccioUrl = "http://localhost:4873"
)

$ErrorActionPreference = "Stop"

function Main {
    # Forward only the params the user explicitly set, so each child applies its own defaults
    # for anything not specified at the orchestrator level.
    & "$PSScriptRoot\build-docker-verdaccio.ps1" -MinAgeDays $MinAgeDays
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    & "$PSScriptRoot\check-package-versions.ps1" -Packages $Packages -VerdaccioUrl $VerdaccioUrl
}

Main