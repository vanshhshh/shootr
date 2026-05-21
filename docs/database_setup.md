# Database Setup Guide (Firebase + Firestore)

This project currently runs from seeded mock data in `MockMarketplaceService`.
Use this guide to move it to production-grade Firebase data.

## 1. Prerequisites

1. Install Flutter (stable) and Firebase CLI:
   - `dart pub global activate flutterfire_cli`
   - `npm i -g firebase-tools`
2. Login to Firebase:
   - `firebase login`
3. Create a Firebase project in the Firebase Console.
4. Enable products:
   - Authentication (Phone, Email if needed)
   - Cloud Firestore
   - Cloud Storage
   - Cloud Functions
   - Cloud Messaging

## 2. Configure This Flutter App

Run from repository root:

```bash
flutter pub get
flutterfire configure
```

This updates FlutterFire bindings and generates proper platform options.
Then replace placeholder keys in `lib/firebase_options.dart` if any remain.

## 3. Firestore Security + Indexes

This repository already includes:

- `firestore.rules`
- `firestore.indexes.json`

Deploy both:

```bash
firebase init firestore
firebase deploy --only firestore:rules,firestore:indexes
```

## 4. Suggested Firestore Data Model

Use these top-level collections:

1. `users/{uid}`
2. `packages/{packageId}`
3. `bookings/{bookingId}`
4. `chat_threads/{bookingId}/messages/{messageId}`
5. `notifications/{notificationId}`
6. `admin_overview/{docId}`

### users

- `role`: `"client" | "shootr" | "admin"`
- `name`, `phone`, `city`, `state`, `country`
- `accountStatus`, `rating`, `reviewCount`
- `specialisationIds`, `deviceModel`, `deviceTier`
- `walletBalance`, `creditsBalance`, `totalSpent`, `totalEarned`
- `notificationPreferences` map
- `createdAt`, `updatedAt`

### packages

- `type`: `"basic" | "pro" | "luxe" | "drone"`
- `title`, `description`, `price`
- `isAddon`, `requiresDrone`
- `inclusions` array

### bookings

- `clientId`, `shootrId`
- `clientName`, `shootrName`
- `status`
- `packageType`, `categoryId`
- `scheduledAt`, `durationHours`
- `location` map (`address`, `city`, `state`, `country`, `latitude`, `longitude`)
- `stylePreference`, `mood`, `musicPreference`, `reelsNeeded`, `aspectRatio`
- `baseAmount`, `platformFee`, `taxAmount`, `creditsUsed`, `totalAmount`
- `paymentMethod`, `paymentStatus`, `refundStatus`
- `notes`, `promoCode`, `trackEnabled`
- `createdAt`, `updatedAt`

### chat_threads/messages

- `chat_threads/{bookingId}` metadata document (optional)
- `messages/{messageId}`:
  - `bookingId`, `senderId`, `senderName`, `type`, `body`, `sentAt`, `isRead`

### notifications

- `targetUserId` (preferred) and/or `targetRole`
- `title`, `body`, `read`
- `createdAt`

## 5. App Wiring Checklist (Critical)

1. Add repository/services for Firestore reads/writes.
2. In `AppController.initialize()`, read Firestore data instead of `MockMarketplaceService.bootstrap()`.
3. Replace direct in-memory mutations with repository writes:
   - create booking
   - update booking status
   - send message
   - update profile
   - mark notification read
4. Keep `LocalCacheService` as offline cache fallback only.

## 6. Cloud Functions You Should Add

1. `createPaymentIntent` (Stripe)
2. `razorpayWebhookHandler`
3. `onBookingStatusChange` (server-side notification fanout)
4. `onNewMessage` (push notifications)
5. `adminResolveDispute` (centralized refund/audit path)

## 7. Secrets + Environment

Do not hardcode payment keys in app code.

Store secrets in:

- Firebase Functions config/secrets
- CI/CD secrets
- Runtime env for web/admin

## 8. Migration Strategy From Mock Data

1. Export sample seed from `MockMarketplaceService`.
2. Import to Firestore as initial dataset for staging.
3. Release a feature flag:
   - `useFirestore=true` in staging first.
4. Verify:
   - Auth flow
   - Booking creation
   - Chat
   - Admin moderation actions
5. Remove mock bootstrap only after parity is confirmed.

## 9. Minimum Production Validation

1. Security rules test matrix (client/shootr/admin).
2. Booking lifecycle integration tests.
3. Payment + webhook replay tests.
4. Notification delivery checks (foreground/background/terminated).
5. Load test on booking + chat write hotspots.
