# Backend Setup

## Install Node Dependencies

```bash
npm install
cd functions
npm install
cd ..
```

## Seed Firestore

The seed script writes packages, sample active Shootrs, one sample client, one booking, chat messages, notifications, and `admin_overview/summary`.

Use a Firebase service account or Google application-default credentials:

```bash
$env:GOOGLE_APPLICATION_CREDENTIALS="C:\path\to\service-account.json"
npm run seed:firestore
```

Optional admin bootstrap while seeding:

```bash
$env:SEED_ADMIN_UID="firebase-auth-uid"
npm run seed:firestore
```

## Set A Real Admin

Create or sign in an email user in Firebase Auth, then grant admin from a trusted machine:

```bash
$env:GOOGLE_APPLICATION_CREDENTIALS="C:\path\to\service-account.json"
npm run admin:set -- --email=admin@shootr.app
```

The script sets both Firebase Auth custom claims and the Firestore `users/{uid}` admin profile. The admin must sign out and sign back in after claims change.

## Razorpay Functions

Set secrets:

```bash
firebase functions:secrets:set RAZORPAY_KEY_ID --project shootr-app
firebase functions:secrets:set RAZORPAY_KEY_SECRET --project shootr-app
firebase functions:secrets:set RAZORPAY_WEBHOOK_SECRET --project shootr-app
firebase functions:secrets:set BOOTSTRAP_ADMIN_EMAIL --project shootr-app
```

Deploy:

```bash
firebase deploy --only functions,firestore:rules,firestore:indexes --project shootr-app
```

In Razorpay Dashboard, add the webhook URL for `razorpayWebhook` and enable payment captured/failed events. Keep the webhook secret identical to `RAZORPAY_WEBHOOK_SECRET`.

## Bootstrap The First Admin From The App

Set `BOOTSTRAP_ADMIN_EMAIL` to the first admin email. Then deploy Functions and sign in from the app through **Admin sign in**. If the signed-in Firebase Auth email matches the secret, `bootstrapAdminAccount` creates the admin profile and custom claims.

Spark-plan fallback: until Functions/Secret Manager are available, Firestore rules allow the exact email in `AppConstants.bootstrapAdminEmail` to create the first admin profile from the app. Keep that email narrow and remove the fallback once custom claims are deployed.

## Rules Tests

```bash
npm run test:rules
```

These tests verify that clients cannot self-create admin profiles, cannot write packages, can read active Shootr profiles, and cannot change their own role.
