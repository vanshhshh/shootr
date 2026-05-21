import admin from 'firebase-admin';

export function initializeAdminApp() {
  if (admin.apps.length > 0) {
    return admin.app();
  }

  const projectId =
    process.env.FIREBASE_PROJECT_ID ||
    process.env.GCLOUD_PROJECT ||
    process.env.GOOGLE_CLOUD_PROJECT ||
    'shootr-app';

  const inlineServiceAccount = process.env.FIREBASE_SERVICE_ACCOUNT;
  if (inlineServiceAccount) {
    const credential = admin.credential.cert(JSON.parse(inlineServiceAccount));
    return admin.initializeApp({ credential, projectId });
  }

  return admin.initializeApp({
    credential: admin.credential.applicationDefault(),
    projectId,
  });
}

export { admin };
