# One-time: set the 4 GitHub Actions secrets for SummitCalculator.
# These are the SAME values the Bloom Calculator repo uses (the ASC API key is
# team-level, not app-scoped), so you can reuse what you set up for Bloom.
#
# Where to find each value (README-SETUP.md section A has the full walkthrough):
#   APPLE_TEAM_ID  -> developer.apple.com > Membership details (10 characters)
#   ASC_KEY_ID     -> appstoreconnect.apple.com > Users and Access > Integrations > Keys
#                     (the ACTIVE key's ID; you have AuthKey_9CX2N2794M.p8 and
#                      AuthKey_M52D48GPNS.p8 in Downloads - the Keys page shows which
#                      ID is active, use that one's .p8 below)
#   ASC_ISSUER_ID  -> same Keys page, the UUID shown above the key table
#   ASC_KEY_P8     -> the matching AuthKey_XXXXXXXXXX.p8 file (raw contents, NOT base64)
#
# Run from anywhere:  powershell -File scripts\3-Set-Secrets.ps1

$Repo = "shaver3josiah/SummitCalculator"

$teamId = Read-Host "APPLE_TEAM_ID (10 chars)"
$keyId = Read-Host "ASC_KEY_ID (10 chars, the ACTIVE key)"
$issuerId = Read-Host "ASC_ISSUER_ID (UUID)"
$p8Path = Read-Host "Full path to the matching AuthKey .p8 file (e.g. C:\Users\shave\Downloads\AuthKey_$keyId.p8)"

if (-not (Test-Path $p8Path)) {
    Write-Host "ERROR: file not found: $p8Path" -ForegroundColor Red
    exit 1
}

gh secret set APPLE_TEAM_ID --repo $Repo --body $teamId
if (-not $?) { exit 1 }
gh secret set ASC_KEY_ID --repo $Repo --body $keyId
if (-not $?) { exit 1 }
gh secret set ASC_ISSUER_ID --repo $Repo --body $issuerId
if (-not $?) { exit 1 }
# Pipe the raw file so PEM newlines survive exactly.
Get-Content -Raw $p8Path | gh secret set ASC_KEY_P8 --repo $Repo
if (-not $?) { exit 1 }

Write-Host ""
Write-Host "All 4 secrets set on $Repo." -ForegroundColor Green
gh api "repos/$Repo/actions/secrets" --jq '.secrets[].name'
Write-Host ""
Write-Host "Next: register bundle id com.shaver.summitcalculator + create the" -ForegroundColor Yellow
Write-Host "'Summit Calculator' app record (README-SETUP.md A.2-A.3), then run" -ForegroundColor Yellow
Write-Host "scripts\2-Release-TestFlight.ps1 -Version v0.1.0" -ForegroundColor Yellow
