import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import { admin, initializeAdminApp } from './firebase_admin_app.mjs';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(__dirname, '..');
const seedPath =
  process.env.SEED_FILE || path.join(root, 'seed', 'firestore_seed.json');

initializeAdminApp();
const db = admin.firestore();

const seed = JSON.parse(await fs.readFile(seedPath, 'utf8'));

const writes = [];

function queueSet(documentPath, data) {
  writes.push({ documentPath, data });
}

for (const [id, data] of Object.entries(seed.packages || {})) {
  queueSet(`packages/${id}`, data);
}

for (const [id, data] of Object.entries(seed.users || {})) {
  queueSet(`users/${id}`, data);
}

for (const [id, data] of Object.entries(seed.bookings || {})) {
  queueSet(`bookings/${id}`, data);
}

for (const [id, data] of Object.entries(seed.notifications || {})) {
  queueSet(`notifications/${id}`, data);
}

for (const [id, data] of Object.entries(seed.adminOverview || {})) {
  queueSet(`admin_overview/${id}`, data);
}

for (const [threadId, threadData] of Object.entries(seed.chatThreads || {})) {
  queueSet(`chat_threads/${threadId}`, threadData.thread || { bookingId: threadId });
  for (const [messageId, message] of Object.entries(threadData.messages || {})) {
    queueSet(`chat_threads/${threadId}/messages/${messageId}`, message);
  }
}

const adminUid = process.env.SEED_ADMIN_UID;
if (adminUid) {
  const now = new Date().toISOString();
  queueSet(`users/${adminUid}`, {
    id: adminUid,
    role: 'admin',
    name: process.env.SEED_ADMIN_NAME || 'Shootr Admin',
    phone: process.env.SEED_ADMIN_PHONE || '',
    city: process.env.SEED_ADMIN_CITY || 'Mumbai',
    state: process.env.SEED_ADMIN_STATE || 'Maharashtra',
    country: 'india',
    photoUrl:
      process.env.SEED_ADMIN_PHOTO ||
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
  });
  await admin.auth().setCustomUserClaims(adminUid, {
    role: 'admin',
    admin: true,
  });
}

for (let index = 0; index < writes.length; index += 450) {
  const batch = db.batch();
  for (const write of writes.slice(index, index + 450)) {
    batch.set(db.doc(write.documentPath), write.data, { merge: true });
  }
  await batch.commit();
}

console.log(`Seeded ${writes.length} Firestore documents from ${seedPath}.`);
if (adminUid) {
  console.log(`Admin claims and user profile set for uid ${adminUid}.`);
}
