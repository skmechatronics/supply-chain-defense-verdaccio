# check-package-versions.ps1
# Verify the cooldown filter is active by comparing Verdaccio's responses to npm.
#
# Usage:
#   .\check-package-versions.ps1
#   .\check-package-versions.ps1 -Packages axios,react
#   .\check-package-versions.ps1 -VerdaccioUrl "http://localhost:4873" -Packages "@types/node"

param(
    [string[]]$Packages = @("axios", "@types/node", "eslint", "vite", "typescript"),
    [string]$VerdaccioUrl = "http://localhost:4873"
)

$ErrorActionPreference = "Stop"

function Write-Progress-Step { param([string]$Message); Write-Host $Message -ForegroundColor Yellow }
function Write-Success       { param([string]$Message); Write-Host $Message -ForegroundColor Green }
function Write-Error-Step    { param([string]$Message); Write-Host $Message -ForegroundColor Red }

function Get-PackageLatest {
    param(
        [string]$RegistryUrl,
        [string]$EncodedPackage
    )

    $response = Invoke-RestMethod -Uri "$RegistryUrl/$EncodedPackage"
    $latest   = $response.'dist-tags'.latest

    $publishTime = $response.time.$latest
    if ($publishTime -is [string]) {
        $publishTime = [DateTime]::Parse($publishTime, [System.Globalization.CultureInfo]::InvariantCulture)
    }
    $publishTime = $publishTime.ToUniversalTime()

    return [PSCustomObject]@{
        Version     = $latest
        PublishTime = $publishTime
    }
}

function Get-FilterStatus {
    param(
        [string]$NpmLatest,
        [string]$VerdaccioLatest
    )

    if ($NpmLatest -ne $VerdaccioLatest) {
        return [PSCustomObject]@{
            Filtered = $true
            Label    = "FILTERED"
            Color    = "Green"
        }
    }

    return [PSCustomObject]@{
        Filtered = $false
        Label    = "not filtered"
        Color    = "Yellow"
    }
}

function Write-TableHeader {
    $header = "{0,-20} {1,-15} {2,-10} {3,-15} {4,-10} {5}" `
        -f "PACKAGE", "NPM LATEST", "NPM AGE", "VERDACCIO", "VERD AGE", "STATUS"
    $rule = "-" * 90
    Write-Host ""
    Write-Host $header -ForegroundColor Cyan
    Write-Host $rule   -ForegroundColor Cyan
}

function Write-PackageRow {
    param(
        [string]$Package,
        [string]$NpmLatest,
        [double]$NpmAgeDays,
        [string]$VerdaccioLatest,
        [double]$VerdaccioAgeDays,
        [string]$StatusLabel,
        [string]$StatusColor
    )

    $line = "{0,-20} {1,-15} {2,-10} {3,-15} {4,-10} {5}" `
        -f $Package, $NpmLatest, $NpmAgeDays, $VerdaccioLatest, $VerdaccioAgeDays, $StatusLabel

    Write-Host $line -ForegroundColor $StatusColor
}

function Test-Filter {
    param([string[]]$PackageList, [string]$Url)

    Write-Progress-Step "Verifying filter against: $($PackageList -join ', ')"
    Write-Host ""
    Write-Host "Comparing $Url against https://registry.npmjs.org"

    Write-TableHeader

    $anyFiltered = $false

    foreach ($pkg in $PackageList) {
        $encoded = $pkg -replace "@", "%40" -replace "/", "%2F"

        try {
            $npm       = Get-PackageLatest -RegistryUrl "https://registry.npmjs.org" -EncodedPackage $encoded
            $verdaccio = Get-PackageLatest -RegistryUrl $Url -EncodedPackage $encoded
        } catch {
            Write-Error-Step ("{0,-20} failed to fetch: {1}" -f $pkg, $_.Exception.Message)
            continue
        }

        $now              = (Get-Date).ToUniversalTime()
        $npmAgeDays       = [math]::Round(($now - $npm.PublishTime).TotalDays, 1)
        $verdaccioAgeDays = [math]::Round(($now - $verdaccio.PublishTime).TotalDays, 1)
        $status           = Get-FilterStatus -NpmLatest $npm.Version -VerdaccioLatest $verdaccio.Version

        Write-PackageRow `
            -Package $pkg `
            -NpmLatest $npm.Version `
            -NpmAgeDays $npmAgeDays `
            -VerdaccioLatest $verdaccio.Version `
            -VerdaccioAgeDays $verdaccioAgeDays `
            -StatusLabel $status.Label `
            -StatusColor $status.Color

        if ($status.Filtered) { $anyFiltered = $true }
    }

    Write-Host ""
    if ($anyFiltered) {
        Write-Success "Filter confirmed working: at least one package was filtered."
    } else {
        Write-Error-Step "No package was filtered. Either none above published recently, or the filter is misconfigured."
        Write-Host "Try again later, or pass -Packages with a more active package." -ForegroundColor Yellow
    }
}

function Main {
    Test-Filter -PackageList $Packages -Url $VerdaccioUrl
}

Main