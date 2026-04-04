/**
 * Called from GitHub Actions when FIREBASE_SERVICE_ACCOUNT_JSON is set.
 * Merges app_config/android with latestBuildNumber, downloadUrl, versionLabel, releaseNotes.
 */
const admin = require('firebase-admin');

const json = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
if (!json) {
  console.error('FIREBASE_SERVICE_ACCOUNT_JSON is empty');
  process.exit(1);
}

const build = parseInt(process.env.LATEST_BUILD_NUMBER, 10);
if (!Number.isFinite(build)) {
  console.error('LATEST_BUILD_NUMBER invalid');
  process.exit(1);
}

const downloadUrl = process.env.APK_DOWNLOAD_URL;
if (!downloadUrl) {
  console.error('APK_DOWNLOAD_URL missing');
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.cert(JSON.parse(json)),
});

const notes = (process.env.RELEASE_NOTES || '').trim().slice(0, 2000);

admin
  .firestore()
  .doc('app_config/android')
  .set(
    {
      latestBuildNumber: build,
      downloadUrl,
      versionLabel: process.env.VERSION_LABEL || '',
      ...(notes ? { releaseNotes: notes } : {}),
    },
    { merge: true },
  )
  .then(() => {
    console.log('Firestore app_config/android updated.');
    process.exit(0);
  })
  .catch((e) => {
    console.error(e);
    process.exit(1);
  });
