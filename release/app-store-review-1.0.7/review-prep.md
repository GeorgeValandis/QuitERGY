# QuitERGY App Review Prep 1.0.7

Date: 2026-06-18
Version: 1.0.7
Build: 24
Bundle ID: `com.GA.QuitERGY`
App Store ID: `6754967219`
Archive: `build/QuitERGY-1.0.7-24.xcarchive`
Exported IPA: `build/export-1.0.7-24/QuitERGY.ipa`

## Pricing Decision

Recommended launch prices:

- Weekly: `$1.99`
- Monthly: `$4.99`

Monthly should be the default/highlighted plan. The weekly plan gives a flexible entry point, while monthly is the better user-facing value and should reduce churn pressure versus a weekly-first paywall.

No free trial is configured for this review prep. Add one later only if the first subscription funnel needs it; it adds App Store Connect and cancellation-risk complexity before we have baseline conversion data.

## Product IDs

- Monthly subscription: `com.quitergy.premium.monthly`
- Weekly subscription: `com.quitergy.premium.weekly`
- Entitlement: `QuitERGYPremium`
- RevenueCat offering: `default`
- RevenueCat packages: `$rc_monthly`, `$rc_weekly`

Legacy Lifetime IDs remain recognized only for existing purchasers:

- `com.quitergy.premium.lifetime`
- `quitergy_lifetime`

## App Store Connect Checklist

- Create subscription group: `QuitERGY Premium`.
- Create `QuitERGY Premium Monthly` with product ID `com.quitergy.premium.monthly`, duration 1 month, price USD `$4.99`.
- Create `QuitERGY Premium Weekly` with product ID `com.quitergy.premium.weekly`, duration 1 week, price USD `$1.99`.
- Add product localization: display names and description from `subscription-product-contract.json`.
- Confirm both subscriptions reach `Ready to Submit`.
- If App Store Connect requires first-time IAP review, attach both subscriptions to app version `1.0.7`.
- Confirm Pricing/App Availability is still configured.
- Confirm export compliance remains `usesNonExemptEncryption=false`.

## RevenueCat Checklist

- In the QuitERGY RevenueCat project, keep entitlement `QuitERGYPremium`.
- In offering `default`, attach:
  - `$rc_monthly` -> `com.quitergy.premium.monthly`
  - `$rc_weekly` -> `com.quitergy.premium.weekly`
- Make monthly the primary/default package in the dashboard if RevenueCat ordering is shown.
- Keep Lifetime out of the current offering.
- Verify products load in TestFlight Sandbox, not only local StoreKit.

## App Review Notes

Suggested App Review notes:

```
QuitERGY is a local-first energy drink tracking app. Premium unlocks unlimited logging, detailed statistics, daily reminders, and multiple drink profiles.

Premium is available through auto-renewable weekly and monthly subscriptions. No account is required. To find the purchase flow, open Settings and tap "Unlock Premium", or trigger a Premium-gated action such as adding more free logs after the free allowance is used.

Purchases and restores are handled through Apple In-App Purchase and RevenueCat entitlement validation. Drink logs, notes, reminders, profiles, and progress data stay on device.
```

## Submission Gates

Local prep is not enough for final submission. Before pressing submit:

- Upload the exported build `24` to App Store Connect.
- Verify ASC subscriptions and RevenueCat offering against `subscription-product-contract.json`.
- Run a real-device TestFlight Sandbox purchase for monthly, weekly, and restore.
- Save sandbox evidence under this release folder before final review submission.

Local verification completed:

- XcodeBuildMCP simulator build/run: passed.
- Paywall screenshot check: passed; Monthly is selected by default, Weekly is visible, Lifetime is no longer offered.
- `xcodebuild test -only-testing:QuitERGYTests`: passed.
- `xcodebuild test -only-testing:QuitERGYUITests/QuitERGYUITests/testExample`: passed with `UITEST_BYPASS_PURCHASES=1`.
- `xcodebuild archive`: passed.
- `xcodebuild -exportArchive`: passed; exported IPA is distribution-signed.
