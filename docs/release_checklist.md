# Release Checklist

## Android Identity

- Confirm package name: `com.shootr.app.shootr`
- Replace placeholder app display name/assets if needed.
- Create a Play upload key and configure `android/key.properties`.
- Add release signing config in `android/app/build.gradle.kts`.
- Build release: `flutter build appbundle --release`

## Firebase Production

- Add release SHA-1 and SHA-256 fingerprints in Firebase Android app settings.
- Re-download `google-services.json` after adding fingerprints.
- Deploy rules, indexes, and functions.

## Store Assets

- App icon: 512x512 PNG
- Feature graphic: 1024x500 PNG
- Screenshots for phone form factors
- Short description, full description, category, support email

## Legal

- Publish a privacy policy URL.
- Publish terms covering bookings, cancellations, creator payouts, and media usage rights.
- Verify Razorpay business/KYC and settlement settings before accepting live payments.

## Final Verification

- Test phone OTP with a real device.
- Test email sign-up/sign-in.
- Test admin sign-in after custom claims.
- Test Cloudinary upload from client and Shootr flows.
- Test Razorpay test-mode payment, webhook receipt, and Firestore payment order update.
- Test notifications on at least two physical Android devices.
