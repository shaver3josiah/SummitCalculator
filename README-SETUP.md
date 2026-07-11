# Summit Setup Guide

This is the one time checklist to get Summit from this repo onto TestFlight. You are on Windows. All Apple specific work (building, signing, uploading) happens on GitHub's macOS runners, not on your machine. You only need a web browser and a terminal that can run git.

Follow the sections in order: A, then B, then C. Section D is a troubleshooting reference, read it only if something breaks.

## A. Apple Developer and App Store Connect setup

Do this at https://developer.apple.com and https://appstoreconnect.apple.com while signed in with your paid Apple Developer account.

1. Accept agreements.
   1. Go to https://developer.apple.com/account and sign in.
   2. If you see a banner about a Program License Agreement or Apple Developer Agreement, open it and accept. Do this before anything else, everything below silently fails if an agreement is pending.

2. Register the bundle ID.
   1. Go to https://developer.apple.com/account/resources/identifiers/list.
   2. Click the plus button next to Identifiers.
   3. Choose App IDs, click Continue.
   4. Choose App, click Continue.
   5. Description: `Summit`.
   6. Bundle ID: choose Explicit, enter `com.shaver.summitcalculator`.
   7. Leave capabilities unchecked unless you know you need one. Click Continue, then Register.

3. Create the App Store Connect app record.
   1. Go to https://appstoreconnect.apple.com and sign in.
   2. Click Apps, then click the plus button, then choose New App.
   3. Platforms: check iOS.
   4. Name: `Summit Calculator` (this is the App Store listing name, it can differ from the on device display name `Summit`).
   5. Primary language: English (U.S.) or your preference.
   6. Bundle ID: select `com.shaver.summitcalculator` from the dropdown, it should already appear since you registered it in step 2.
   7. SKU: any unique string, for example `summitcalculator001`.
   8. User Access: Full Access.
   9. Click Create.

4. Create an App Store Connect API key.
   1. In App Store Connect, click Users and Access.
   2. Click the Integrations tab, then Keys (older accounts show a top level Keys tab instead of Integrations, use whichever is present).
   3. Click the plus button to request a new key.
   4. Name: `Summit CI`.
   5. Access: App Manager.
   6. Click Generate.
   7. Click Download API Key next to the new key. This downloads a file named `AuthKey_XXXXXXXXXX.p8`.
   8. Apple lets you download this file exactly once. Save it somewhere safe on your Windows machine immediately, for example your password manager or an encrypted folder. You will paste its contents into a GitHub secret in section B, then you can delete the local copy if you want.
   9. Note the Key ID shown in the table, a 10 character code. You need this for `ASC_KEY_ID`.
   10. Note the Issuer ID shown above the keys table, a UUID. You need this for `ASC_ISSUER_ID`.

5. Find your Team ID.
   1. Go to https://developer.apple.com/account.
   2. Click Membership details (sometimes labeled Membership in the sidebar).
   3. Copy the Team ID, a 10 character alphanumeric code. This is `APPLE_TEAM_ID`.

6. Add your tester (e.g. your own Apple ID) as a user and internal tester.
   1. In App Store Connect, click Users and Access.
   2. Click the Users tab (or People, depending on account type).
   3. Click the plus button to invite a new user.
   4. Enter the tester's name and email address.
   5. Role: Developer or App Manager is enough to see builds and TestFlight, avoid Admin unless you want them managing the whole account.
   6. Under app access, grant access to the Summit Calculator app specifically.
   7. Click Invite. The tester gets an email to accept and set up two factor authentication if they do not already have an Apple Developer account association.
   8. Once they accept, go to your app, click the TestFlight tab.
   9. Click Internal Testing in the sidebar (or App Store Connect Users group under Internal Testing).
   10. Click the plus button next to Testers, select the tester from the list of users with app access, click Add.
   11. Internal testers do not need App Review, they get new builds as soon as processing finishes.

## B. GitHub setup

1. Create a private repository.
   1. Go to https://github.com/new.
   2. Owner: your account.
   3. Repository name: `summit-calculator` or similar.
   4. Visibility: Private.
   5. Do not initialize with a README, .gitignore, or license, this repo already has its own files.
   6. Click Create repository.

2. Add repository secrets.
   1. In your new GitHub repo, click Settings.
   2. Click Secrets and variables, then Actions.
   3. Click New repository secret for each of the following, one at a time.

   | Secret name | Value |
   |---|---|
   | `APPLE_TEAM_ID` | the 10 character Team ID from A.5 |
   | `ASC_KEY_ID` | the Key ID from A.4.9 |
   | `ASC_ISSUER_ID` | the Issuer ID from A.4.10 |
   | `ASC_KEY_P8` | the full contents of the `.p8` file from A.4.7, open it in Notepad and paste everything including the `-----BEGIN PRIVATE KEY-----` and `-----END PRIVATE KEY-----` lines |

   4. Double check `ASC_KEY_P8` has no extra blank line at the start or missing characters at the end, a truncated paste is the most common cause of signing failures.

## C. Push the code and trigger the first build

Run these from a Windows terminal (PowerShell or Git Bash) inside the `SummitCalculator` folder.

1. Connect the local folder to your new GitHub repo.
   ```
   git init
   git add .
   git commit -m "Initial Summit scaffold"
   git branch -M main
   git remote add origin https://github.com/shaver3josiah/SummitCalculator.git
   git push -u origin main
   ```

2. Tag and push to trigger the release build.
   ```
   git tag v0.1.0
   git push --tags
   ```
   Pushing a tag matching `v*` is what starts the release workflow. Pushing to `main` alone only runs the test workflow, it does not build or upload anything to Apple.

3. Watch the build.
   1. Go to your repo on GitHub, click the Actions tab.
   2. You should see a run named `release` triggered by the tag push, click it.
   3. Click the `build-and-upload` job to see live logs.
   4. Expect the whole run to take 20 to 30 minutes: XcodeGen and font download are fast, `xcodebuild archive` is the slow step, upload is a few minutes.
   5. A green check means the build reached App Store Connect. A red X means something failed, see section D.

4. Find the build in TestFlight.
   1. Go to App Store Connect, open Summit Calculator, click the TestFlight tab.
   2. New builds first show status Processing for 10 to 60 minutes after upload, this happens on Apple's side after your GitHub Action finishes, it is normal and you cannot speed it up.
   3. Once processing finishes, the build appears under Internal Testing and the TestFlight app will offer it to your testers automatically (assuming section A.6 is done).
   4. If Apple asks compliance questions (encryption export), the `ITSAppUsesNonExemptEncryption` key set to false in this project answers that automatically and you should not see the prompt, but if you do, answer that the app does not use encryption beyond what iOS provides by default.

## D. Troubleshooting

| Problem | What it means | What to do |
|---|---|---|
| Agreement not accepted | Build fails early with a message about a pending agreement or contract | Go to https://developer.apple.com/account, accept the outstanding agreement, then re-run the failed GitHub Actions job with Re-run all jobs |
| First build stuck in Processing | Apple's own post-upload processing step, unrelated to your CI | Normal for up to about an hour on a brand new app's first build. If it is stuck past 2 hours, check your email for a rejection notice from Apple, otherwise just wait |
| Signing failures (`-allowProvisioningUpdates` errors, "No profiles found", "Team not found") | Usually a wrong or expired secret, or the bundle ID was not registered before the app record was created | Recheck `APPLE_TEAM_ID` matches A.5 exactly, recheck `ASC_KEY_P8` was pasted in full with no truncation, confirm the bundle ID in Certificates Identifiers Profiles matches `com.shaver.summitcalculator` exactly |
| `pilot` or fastlane upload step fails with an authentication error | `ASC_KEY_ID` or `ASC_ISSUER_ID` do not match the key, or the key's App Manager role is insufficient | Recheck both values against the Keys page in App Store Connect, confirm the key still exists and was not revoked |
| CI minute budget | A free personal GitHub account includes 2000 Actions minutes per month for private repos, but macOS runners consume that allowance about 10 times faster per minute than Linux runners | Each release run uses roughly 15 minutes of actual macOS runner time, which draws down the equivalent of about 150 minutes from your 2000 minute monthly allowance. That is roughly 13 release runs per month before you would need to pay for more. The test workflow runs on Linux and barely dents the budget, only release tags are expensive. Tag releases deliberately rather than on every small change |

## Appendix: privacy manifest note

`App/Support/PrivacyInfo.xcprivacy` declares no collected data, no tracking, and an empty
NSPrivacyAccessedAPITypes array. It does not include the UserDefaults reason code
(CA92.1). SummitCore's persistence type is `JSONStore`, which is initialized with an
explicit `directory: URL` and writes JSON files to disk, it is not a wrapper around
`UserDefaults`. If a future change introduces direct `UserDefaults` access anywhere in
the app or package, add an NSPrivacyAccessedAPIType entry for
NSPrivacyAccessedAPICategoryUserDefaults with reason CA92.1 (or the reason that matches
the actual use) before shipping, App Store Connect validation rejects builds that touch
UserDefaults without a declared reason.

