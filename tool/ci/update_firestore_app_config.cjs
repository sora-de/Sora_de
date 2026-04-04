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

let cred;
try {
  cred = JSON.parse(json);
} catch (e) {
  console.error('FIREBASE_SERVICE_ACCOUNT_JSON is not valid JSON', e);
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

const projectId = cred.project_id;
if (!projectId) {
  console.error('Service account JSON missing project_id');
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.cert(cred),
  projectId,
});

console.log(`Firestore Admin: project_id=${projectId}, doc=app_config/android`);

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
    const code = e.code;
    const n = typeof code === 'number' ? code : parseInt(String(code), 10);
    if (n === 5 || code === 'NOT_FOUND' || String(e.message || '').includes('NOT_FOUND')) {
      console.error(`
NOT_FOUND (gRPC 5): The Firestore *database* may not exist yet for this project.
1. Open Firebase Console → Build → Firestore Database.
2. Click "Create database", choose Native mode and a region, finish the wizard.
3. Confirm the service account JSON project_id (${projectId}) matches this Firebase project.
See docs/DEPLOY_GITHUB_ANDROID.md
`);
    }
    process.exit(1);
  });
