# Subscription setup (Google Play + RevenueCat)

Manual steps required for correct pricing in purchase emails and the Play Store.

## Google Play Console

1. App: `com.rohitrathod.physiqai` → **Monetize → Subscriptions**.
2. Open the monthly subscription product linked in RevenueCat.
3. Under **Base plans**, set billing period to **1 month (P1M)** — not **5 minutes (P5M)**. A P5M plan causes emails to show "per 5 minutes".
4. Set the production price (e.g. monthly INR amount).
5. Retire or stop offering any test P5M base plans for production.

## RevenueCat dashboard

1. **Entitlements:** identifier must be `premium`.
2. **Products:** Android product IDs must match Google Play subscription IDs.
3. **Offerings:** Mark the main offering as **Current**. Include monthly, annual, and a special package (identifier contains `special`).
4. After Play Console changes, sync products in RevenueCat.

## Verify in app

Run the app and check debug logs from `RevenueCat: Fetching offerings` for package and product IDs.
