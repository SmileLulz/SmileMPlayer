param(
    [Alias("dr")]
    [switch]$DryRun,

    [Alias("cu")]
    [switch]$CheckUpdate,

    [Alias("h")]
    [switch]$Help
)

$ErrorActionPreference = "Stop"

$Repository = "SmileLulz/SmileMPlayer"
$ApiUrl = "https://api.github.com/repos/$Repository/releases/latest"

function Show-Usage {
    Write-Host @"
SmileMPlayer Windows installer

Usage:
  .\install-win.ps1
  .\install-win.ps1 -DryRun
  .\install-win.ps1 -CheckUpdate
  .\install-win.ps1 -Help

Options:
  -DryRun, -dr
      Download and verify the latest installer, but do not run it.

  -CheckUpdate, -cu
      Check and display the latest SmileMPlayer release.

  -Help, -h
      Show this help message.
"@
}

$headers = @{
    "Accept" = "application/vnd.github+json"
    "X-GitHub-Api-Version" = "2022-11-28"
}

function Get-LatestRelease {
    Write-Host "Fetching latest release information..." -ForegroundColor Yellow

    return Invoke-RestMethod `
        -Uri $ApiUrl `
        -Headers $headers `
        -Method Get
}

if ($Help) {
    Show-Usage
    exit 0
}

if ($DryRun -and $CheckUpdate) {
    Write-Error "Cannot use -DryRun and -CheckUpdate together."
    exit 1
}

if ($CheckUpdate) {
    Write-Host "SmileMPlayer update checker" -ForegroundColor Cyan
    Write-Host ""

    $release = Get-LatestRelease

    $latestTag = $release.tag_name
    $latestName = $release.name

    if ([string]::IsNullOrWhiteSpace($latestTag)) {
        Write-Error "GitHub returned a release without a tag."
        exit 1
    }

    Write-Host "Latest release: $latestName" -ForegroundColor Green
    Write-Host "Tag:            $latestTag"
    Write-Host ""

    exit 0
}

Write-Host "SmileMPlayer Windows installer" -ForegroundColor Cyan
Write-Host ""

if ($DryRun) {
    Write-Host "Mode: dry run" -ForegroundColor Yellow
    Write-Host ""
}

$release = Get-LatestRelease

$releaseTag = $release.tag_name
$releaseName = $release.name

$matches = @(
    $release.assets | Where-Object {
        $_.name -match '^SmileMPlayer-.+-windows-x64-setup\.exe$'
    }
)

if ($matches.Count -eq 0) {
    Write-Error "No Windows x64 installer was found in release $releaseTag."
    exit 1
}

if ($matches.Count -gt 1) {
    Write-Error "Multiple Windows x64 installers were found:"
    $matches | ForEach-Object {
        Write-Host "  $($_.name)"
    }
    exit 1
}

$asset = $matches[0]

if ([string]::IsNullOrWhiteSpace($asset.digest)) {
    Write-Error "GitHub did not provide a SHA-256 digest for $($asset.name)."
    exit 1
}

if (-not $asset.digest.StartsWith("sha256:")) {
    Write-Error "Unexpected asset digest format: $($asset.digest)"
    exit 1
}

$expectedHash = $asset.digest.Substring(7)

Write-Host "Release:   $releaseName"
Write-Host "Tag:       $releaseTag"
Write-Host "Installer: $($asset.name)"
Write-Host ""

$tempDirectory = Join-Path $env:TEMP "SmileMPlayerInstaller"

if (Test-Path $tempDirectory) {
    Remove-Item -Recurse -Force $tempDirectory
}

New-Item -ItemType Directory -Path $tempDirectory | Out-Null

$installerPath = Join-Path $tempDirectory $asset.name

try {
    Write-Host "Downloading installer..." -ForegroundColor Yellow

    Invoke-WebRequest `
        -Uri $asset.browser_download_url `
        -OutFile $installerPath

    Write-Host "Verifying SHA-256..." -ForegroundColor Yellow

    $actualHash = (
        Get-FileHash `
            -Path $installerPath `
            -Algorithm SHA256
    ).Hash

    if ($actualHash -ne $expectedHash) {
        Write-Error @"
SHA-256 verification failed.

Expected:
$expectedHash

Actual:
$actualHash
"@
        exit 1
    }

    Write-Host "SHA-256 verified." -ForegroundColor Green
    Write-Host ""

    if ($DryRun) {
        Write-Host "Dry run complete." -ForegroundColor Green
        Write-Host "Installer downloaded and verified, but was not executed."
        exit 0
    }

    Write-Host "Starting SmileMPlayer installer..." -ForegroundColor Yellow

    $process = Start-Process `
        -FilePath $installerPath `
        -Verb RunAs `
        -Wait `
        -PassThru

    if ($process.ExitCode -ne 0) {
        Write-Error "SmileMPlayer installer exited with code $($process.ExitCode)."
        exit $process.ExitCode
    }

    Write-Host ""
    Write-Host "SmileMPlayer $releaseTag installed successfully." -ForegroundColor Green
}
finally {
    if (Test-Path $tempDirectory) {
        Remove-Item -Recurse -Force $tempDirectory -ErrorAction SilentlyContinue
    }
}
