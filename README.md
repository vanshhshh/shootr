# Shootr

Shootr is a Flutter marketplace app for booking short-form video creators and managing reel shoots across clients, Shootrs, and admins.

## What Is Included

- Riverpod app state with seeded marketplace data
- `go_router` navigation for auth, client, shootr, chat, notifications, and admin
- Reusable neon/glass design system widgets
- Client flow: onboarding, discovery, profile view, booking, confirmation, tracking, delivery, vault
- Shootr flow: onboarding, dashboard, request handling, active jobs, earnings, profile, upload
- Admin flow: dashboard, moderation, booking resolution, pricing, analytics, notifications
- Firebase, analytics, deep link, payment, notification, and location service scaffolds
- Local cache for completed bookings, selected locations, saved Shootrs, and preferences

## UI And Flow Improvements Added

- Reusable flow guidance component: `lib/shared/widgets/flow_guide_card.dart`
- Clear role-path explanation on role selection screen
- Quick booking guidance on client home
- Step-by-step "Now / Next" guidance in booking flow
- Daily operating flow guidance on Shootr home

## Deep Link Note

Firebase Dynamic Links was deprecated and shut down on **August 25, 2025**.
This app uses `app_links` as the deep-link base.

## Local Setup

1. Install latest stable Flutter SDK.
2. Run `flutter pub get`.
3. Configure Firebase for this app:
   - `flutterfire configure`
4. Replace any remaining placeholder values in `lib/firebase_options.dart`.
5. Add Google Maps API keys, Stripe key, Razorpay key, notification assets, and platform permissions.

## Cloudinary Media Setup

Shootr stores profile photos, portfolio images, and delivered reels in Cloudinary.
Create an unsigned upload preset in Cloudinary named:

```text
shootr_unsigned
```

Recommended preset settings:

- Signing mode: unsigned
- Folder: allow app-provided folders
- Allowed formats: `jpg,png,webp,mp4,mov`
- Max file size: match your Cloudinary plan limits

The app uses cloud name `dg0grjaj3` by default. Override either value at build time with:

```bash
flutter run --dart-define=CLOUDINARY_CLOUD_NAME=your_cloud --dart-define=CLOUDINARY_UPLOAD_PRESET=your_unsigned_preset
```

## Database Setup

A complete setup guide is available at:

- `docs/database_setup.md`
- `docs/backend_setup.md`

This repository now also includes deployable Firestore files:

- `firestore.rules`
- `firestore.indexes.json`

Deploy with:

```bash
firebase deploy --only firestore:rules,firestore:indexes
```

Deploy Functions with:

```bash
firebase deploy --only functions,firestore:rules,firestore:indexes --project shootr-app
```

## Flow Documentation

- `docs/app_flow.md`
- `docs/release_checklist.md`
- `docs/privacy_policy.md`

## Production Next Steps

- Seed production Firestore and promote the first real admin user.
- Add store-console assets, production signing, live Razorpay credentials, and legal URLs.
- Expand device and emulator coverage before Play Store submission.

## Validation Run In This Workspace

- `flutter analyze` passed
- `flutter test` passed
