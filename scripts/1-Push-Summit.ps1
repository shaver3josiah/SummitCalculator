$ErrorActionPreference = "Stop"
$RepoUrl = "https://github.com/shaver3josiah/SummitCalculator.git"
$ActionsUrl = "https://github.com/shaver3josiah/SummitCalculator/actions"
$RepoDir = Split-Path -Parent $PSScriptRoot

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "Git is not installed. Install it, then rerun this script:" -ForegroundColor Red
    Write-Host "  winget install --id Git.Git -e" -ForegroundColor Yellow
    exit 1
}

Set-Location $RepoDir
Write-Host "Repo folder: $RepoDir"

if (-not (Test-Path (Join-Path $RepoDir ".git"))) {
    git init | Out-Null
    Write-Host "Initialized new git repository."
}

if (-not (git config user.name)) { git config user.name "Jmarker" }
if (-not (git config user.email)) { git config user.email "shaver3josiah@gmail.com" }

git add -A
$pending = git status --porcelain
if ($pending) {
    git commit -m "Summit iOS port: SummitCore engines (290 golden vectors), SwiftUI app, no-Mac CI to TestFlight" | Out-Null
    Write-Host "Committed $((($pending | Measure-Object).Count)) changes."
} else {
    Write-Host "Nothing new to commit."
}

git branch -M main

if (git remote | Select-String -Quiet -SimpleMatch "origin") {
    git remote set-url origin $RepoUrl
} else {
    git remote add origin $RepoUrl
}

$remoteMain = git ls-remote --heads origin main 2>$null
if ($remoteMain) {
    Write-Host "Remote already has a main branch (probably a GitHub auto README). Merging it in."
    git pull origin main --no-rebase --allow-unrelated-histories --no-edit
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Merge needs a manual decision. Run 'git status', resolve, commit, then rerun this script." -ForegroundColor Red
        exit 1
    }
}

git push -u origin main
if ($LASTEXITCODE -ne 0) {
    Write-Host "Push failed. If a sign-in window appeared, complete it and rerun. Otherwise check the repo URL and your GitHub access." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Pushed. The 'test' workflow is now compiling SummitCore and running all 290 golden vectors on Linux." -ForegroundColor Green
Write-Host "If that job fails, copy the log into the Claude session for a fix pass."
Write-Host "Next: finish README-SETUP.md sections A and B (Apple + GitHub secrets), then run 2-Release-TestFlight.ps1."
Start-Process $ActionsUrl
