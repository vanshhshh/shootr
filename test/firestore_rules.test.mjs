import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  doc,
  getDoc,
  setDoc,
  updateDoc,
} from 'firebase/firestore';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(__dirname, '..');

const testEnv = await initializeTestEnvironment({
  projectId: 'shootr-rules-test',
  firestore: {
    rules: fs.readFileSync(path.join(root, 'firestore.rules'), 'utf8'),
  },
});

function userProfile(role, accountStatus = 'active') {
  return {
    id: `${role}_uid`,
    role,
    accountStatus,
    name: 'Test User',
    phone: '+910000000000',
    city: 'Mumbai',
    photoUrl: '',
    activeSince: '2026-05-19T00:00:00.000Z',
    createdAt: '2026-05-19T00:00:00.000Z',
    updatedAt: '2026-05-19T00:00:00.000Z',
    verified: false,
    backgroundVerified: false,
    identityStatus: 'pending',
    deviceVerificationStatus: 'pending',
    totalEarned: 0,
  };
}

async function run() {
  await testEnv.clearFirestore();

  const clientDb = testEnv.authenticatedContext('client_uid', {
    role: 'client',
    admin: false,
  }).firestore();
  const adminDb = testEnv.authenticatedContext('admin_uid', {
    role: 'admin',
    admin: true,
  }).firestore();
  const shootrDb = testEnv.authenticatedContext('shootr_uid', {
    role: 'shootr',
    admin: false,
  }).firestore();
  const bootstrapAdminDb = testEnv.authenticatedContext('bootstrap_uid', {
    email: 'vansh.sharma.cse@gmail.com',
  }).firestore();

  await assertSucceeds(
    setDoc(doc(clientDb, 'users/client_uid'), userProfile('client')),
  );
  await assertFails(
    setDoc(doc(clientDb, 'users/client_admin'), userProfile('admin')),
  );

  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), 'users/admin_uid'), userProfile('admin'));
    await setDoc(
      doc(context.firestore(), 'users/shootr_uid'),
      userProfile('shootr'),
    );
  });

  await assertSucceeds(
    setDoc(doc(adminDb, 'packages/basic'), {
      type: 'basic',
      title: 'Basic',
      description: '1 reel',
      price: 1999,
    }),
  );
  await assertSucceeds(
    setDoc(doc(bootstrapAdminDb, 'users/bootstrap_uid'), userProfile('admin')),
  );
  await assertFails(
    setDoc(doc(clientDb, 'packages/pro'), {
      type: 'pro',
      title: 'Pro',
      description: '2 reels',
      price: 3499,
    }),
  );

  await assertSucceeds(getDoc(doc(clientDb, 'users/shootr_uid')));
  await assertFails(
    updateDoc(doc(clientDb, 'users/client_uid'), {
      role: 'admin',
    }),
  );

  const baseBooking = {
    id: 'booking_open',
    clientId: 'client_uid',
    clientName: 'Test Client',
    shootrId: '',
    shootrName: '',
    packageType: 'basic',
    scheduledAt: '2026-05-20T10:00:00.000Z',
    durationHours: 1,
    location: {
      address: 'Bandra West',
      city: 'Mumbai',
      latitude: 19.0596,
      longitude: 72.8295,
      country: 'india',
    },
    categoryId: 'product',
    eventType: 'Product Reel',
    stylePreference: 'Cinematic',
    musicPreference: 'Trending',
    reelsNeeded: 1,
    aspectRatio: '9:16',
    baseAmount: 1999,
    platformFee: 99,
    taxAmount: 360,
    status: 'pending',
    createdAt: '2026-05-19T00:00:00.000Z',
    updatedAt: '2026-05-19T00:00:00.000Z',
    qrPayload: 'TEST',
    paymentMethod: 'UPI',
    paymentStatus: 'pending',
  };

  await assertSucceeds(
    setDoc(doc(clientDb, 'bookings/booking_open'), baseBooking),
  );
  await assertFails(
    setDoc(doc(clientDb, 'bookings/booking_preassigned'), {
      ...baseBooking,
      id: 'booking_preassigned',
      shootrId: 'shootr_uid',
      shootrName: 'Shootr',
      status: 'confirmed',
    }),
  );
  await assertSucceeds(getDoc(doc(shootrDb, 'bookings/booking_open')));
  await assertSucceeds(
    updateDoc(doc(shootrDb, 'bookings/booking_open'), {
      status: 'confirmed',
      shootrId: 'shootr_uid',
      shootrName: 'Shootr',
      etaMinutes: 8,
      liveLatitude: 19.0596,
      liveLongitude: 72.8295,
      updatedAt: '2026-05-19T00:01:00.000Z',
    }),
  );
  await assertFails(
    updateDoc(doc(clientDb, 'bookings/booking_open'), {
      paymentStatus: 'paid',
    }),
  );
  await assertSucceeds(
    updateDoc(doc(clientDb, 'bookings/booking_open'), {
      status: 'cancelled',
      updatedAt: '2026-05-19T00:02:00.000Z',
    }),
  );

  await testEnv.cleanup();
}

run().catch(async (error) => {
  await testEnv.cleanup();
  console.error(error);
  process.exit(1);
});
