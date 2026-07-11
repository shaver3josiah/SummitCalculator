param([string]$Version = "v0.1.0")
$ErrorActionPreference = "Stop"
$ActionsUrl = "https://github.com/shaver3josiah/SummitCalculator/actions"
$RepoDir = Split-Path -Parent $PSScriptRoot
Set-Location $RepoDir

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "Git is not installed. Run 1-Push-Summit.ps1 first." -ForegroundColor Red
    exit 1
}

Write-Host "This tags $Version and triggers the macOS build that uploads to TestFlight."
Write-Host "It only succeeds if these are done (see README-SETUP.md):"
Write-Host "  1. Apple: bundle id com.shaver.summitcalculator registered, app record created, agreements accepted"
Write-Host "  2. Summit added as internal tester"
Write-Host "  3. GitHub repo secrets set: APPLE_TEAM_ID, ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_P8"
$ok = Read-Host "All done? (y/n)"
if ($ok -ne "y") {
    Write-Host "Finish README-SETUP.md sections A and B first, then rerun." -ForegroundColor Yellow
    Start-Process (Join-Path $RepoDir "README-SETUP.md")
    exit 0
}

if (git tag --list $Version) {
    Write-Host "Tag $Version already exists. Rerun with a bumped version, for example:" -ForegroundColor Red
    Write-Host "  .\scripts\2-Release-TestFlight.ps1 -Version v0.1.1" -ForegroundColor Yellow
    exit 1
}

git tag $Version
git push origin $Version
if ($LASTEXITCODE -ne 0) {
    git tag -d $Version | Out-Null
    Write-Host "Tag push failed, local tag rolled back. Check connectivity and rerun." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Release $Version triggered. Expect 20 to 30 minutes." -ForegroundColor Green
Write-Host "Watch the 'release' workflow, then check the TestFlight app on your iPhone."
Write-Host "If the workflow fails, copy the log into the Claude session for a fix pass."
Start-Process $ActionsUrl
