import { admin, initializeAdminApp } from './firebase_admin_app.mjs';

initializeAdminApp();

const args = new Map();
for (const arg of process.argv.slice(2)) {
  const [key, ...valueParts] = arg.replace(/^--/, '').split('=');
  args.set(key, valueParts.join('='));
}

const uidArg = args.get('uid') || process.env.ADMIN_UID;
const emailArg = args.get('email') || process.env.ADMIN_EMAIL;

if (!uidArg && !emailArg) {
  console.error('Usage: npm run admin:set -- --uid=<firebase_uid>');
  console.error('   or: npm run admin:set -- --email=<firebase_auth_email>');
  process.exit(1);
}

const user = uidArg
  ? await admin.auth().getUser(uidArg)
  : await admin.auth().getUserByEmail(emailArg);

await admin.auth().setCustomUserClaims(user.uid, {
  role: 'admin',
  admin: true,
});

const now = new Date().toISOString();
await admin.firestore().doc(`users/${user.uid}`).set(
  {
    id: user.uid,
    role: 'admin',
    name: user.displayName || args.get('name') || 'Shootr Admin',
    phone: user.phoneNumber || '',
    city: args.get('city') || 'Mumbai',
    state: args.get('state') || 'Maharashtra',
    country: 'india',
    photoUrl:
      user.photoURL ||
      'https://images.unsplash.com/photo-1560250097-0b93528c311a',
    activeSince: now,
    createdAt: now,
    updatedAt: now,
    accountStatus: 'active',
    notificationPreferences: {
      bookingUpdates: true,
      promos: true,
      reminders: true,
      messages: true,
      safety: true,
      payouts: true,
    },
  },
  { merge: true },
);

console.log(`Admin role applied to ${user.uid}. Sign out/in to refresh claims.`);
