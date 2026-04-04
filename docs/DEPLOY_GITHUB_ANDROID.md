# GitHub + CI/CD for Android (Sora de)

This repo includes:

- **Android CI** (`.github/workflows/android_ci.yml`) — on every push/PR to **`main` or `master`**: `flutter analyze` and `flutter test`. Rename your default branch to `main` if you use that convention (`git branch -M main`).
- **Android release** (`.github/workflows/android_release.yml`) — builds a release APK, publishes a **GitHub Release** with asset `sorade-android.apk`, and optionally updates **Firestore** `app_config/android` so the app shows **Download update** in Account & settings.

## 1. Put the project on GitHub

If this folder is not a git repo yet:

```powershell
cd C:\Users\arwin\Desktop\sora_app
git init
git add .
git commit -m "Initial commit: Sora de"
```

On GitHub: **New repository** (empty, no README). Then:

```powershell
git branch -M main
git remote add origin https://github.com/YOUR_USER/YOUR_REPO.git
git push -u origin main
```

Use a **private** repo if you prefer not to expose `android/app/google-services.json` (Firebase client config is not a secret key, but some teams still keep it private).

## 2. Enable Actions to create releases

In the GitHub repo: **Settings → Actions → General → Workflow permissions** → select **Read and write permissions** → Save.

## 3. Automatic in-app updates (Firestore)

So users see **Update available** after a release:

1. **Enable the Cloud Firestore API** on the Google Cloud project linked to Firebase (required for server/CI access, separate from using Firestore in the app).  
   - [API Library — Firestore](https://console.cloud.google.com/apis/library/firestore.googleapis.com) (pick your project, e.g. **sora-de**) → **Enable**.  
   - If CI shows `SERVICE_DISABLED`, use the `activationUrl` from the log or wait a few minutes after enabling.

2. In **Google Cloud Console** (same project as Firebase), create a **service account** with a role that can write Firestore (e.g. **Cloud Datastore User** or **Firebase Admin**-style access via a custom role with `datastore.documents.*`).
3. Create a **JSON key** for that account.
4. In the GitHub repo: **Settings → Secrets and variables → Actions → New repository secret**  
   Name: `FIREBASE_SERVICE_ACCOUNT_JSON`  
   Value: paste the **entire JSON** file contents.

The release workflow runs `tool/ci/update_firestore_app_config.cjs`, which sets:

- `latestBuildNumber` — from `pubspec.yaml` (number after `+`)
- `downloadUrl` — GitHub Release asset URL for `sorade-android.apk`
- `versionLabel`, `releaseNotes` (from last commit message)

Firestore security rules already allow **read** of `app_config` for signed-in users; the Admin SDK bypasses rules for writes.

If you **do not** add the secret, releases still work; you only need to paste `downloadUrl` and `latestBuildNumber` manually in the console the first time (or each time).

## 4. Ship a new version

1. Edit **`pubspec.yaml`**: bump **both** parts, e.g. `version: 1.0.1+2` (`1.0.1` = version name, `2` = build number the app compares).
2. Commit and push to `main`.

Then either:

**A — Tag push (good for “this commit is the release”)**

```powershell
git tag v1.0.1-2
git push origin v1.0.1-2
```

The tag **must** match the rule: for `1.0.1+2` use tag **`v1.0.1-2`** (replace `+` with `-` before the build number).

**B — Manual run**

**Actions → Android release APK → Run workflow** (uses `pubspec.yaml` on the selected branch; creates the same tag/release if it does not exist).

## 5. Users install updates

They open **Account & settings → App update → Download update** (Android), or open the Release page and download `sorade-android.apk`. They may need to allow **Install unknown apps** for the browser or Files app.

## 6. Play Store (optional)

`flutter build appbundle --release` and upload to Google Play is separate from this pipeline; Play has its own update mechanism.
