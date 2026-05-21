# Shootr App Flow

## Roles

1. Client
2. Shootr
3. Admin

## Client Journey

1. Role select -> phone OTP -> profile setup
2. Home -> category/search -> choose Shootr
3. Booking flow:
   - category
   - shootr
   - package
   - schedule
   - location
   - brief
   - review + pay
4. Confirmation + live tracking
5. Active shoot + chat
6. Reel delivery -> vault

## Shootr Journey

1. Role select -> phone OTP -> onboarding (identity, device, payout, availability)
2. Shootr Home (online/offline + earnings snapshot)
3. Requests -> accept/decline
4. Active bookings -> progress + upload reel
5. Earnings + profile management

## Admin Journey

1. Open admin console
2. Manage Shootrs (approve, suspend, reject, ban)
3. Manage Clients (flag, warn, ban)
4. Manage bookings (issue resolution, refunds)
5. Pricing controls
6. Notifications broadcast

## Current State

- UI and flow are end-to-end functional with mock + local cache.
- Firebase services exist as scaffolds and need production wiring.
