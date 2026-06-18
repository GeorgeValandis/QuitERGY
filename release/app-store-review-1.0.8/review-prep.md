# QuitERGY App Review Prep 1.0.8

Date: 2026-06-18
Version: 1.0.8
Build: 24
Bundle ID: `com.GA.QuitERGY`
App Store ID: `6754967219`

## Pricing Decision

- Weekly: `$1.99`
- Monthly: `$4.99`

Monthly remains the default/highlighted plan. No free trial is configured for this submission.

## Product IDs

- Monthly subscription: `com.quitergy.premium.monthly`
- Weekly subscription: `com.quitergy.premium.weekly.v2`
- Entitlement: `Premium`
- RevenueCat offering: `Default`
- RevenueCat packages: `$rc_monthly`, `$rc_weekly`

The original `com.quitergy.premium.weekly` ASC product is not used because its only localization is `REJECTED` and ASC does not allow editing or deleting that last rejected localization.

## ASC State

- App version `1.0.7` is already `READY_FOR_SALE`; build 24 must therefore ship as version `1.0.8`.
- App version `1.0.8` is created in ASC as `PREPARE_FOR_SUBMISSION` (`8cdfd3f2-71f3-4d0a-803f-338492d588b8`) with manual release.
- Build `24` is uploaded, processed as `VALID`, `APP_STORE_ELIGIBLE`, and attached to version `1.0.8` (`79695de0-89b8-4090-bccf-016ea4263c43`).
- Internal TestFlight group `QuitERGY Internal Review Test 1.0.8` is created and linked to build `24` (`48ee200b-ef02-4576-bcb6-cb72cf06a07b`).
- en-US release notes and App Review notes are updated for weekly/monthly subscriptions.
- Subscription group: `Premium Access` (`21880624`).
- Weekly v2 subscription: `6781658331`, product ID `com.quitergy.premium.weekly.v2`, price USA `$1.99`, state `READY_TO_SUBMIT`.
- Monthly subscription: `6781659490`, product ID `com.quitergy.premium.monthly`, price USA `$4.99`, state `READY_TO_SUBMIT`.
- Both new subscriptions have en-US localization, global equalized price points, global availability, review notes, and App Review screenshots configured.

## RevenueCat State

- Project `QuitERGY` (`66808b7f`) uses entitlement `Premium`.
- Offering `Default` (`ofrnga8c48941a8`) is current.
- Package `$rc_monthly` points to `com.quitergy.premium.monthly`.
- Package `$rc_weekly` points to `com.quitergy.premium.weekly.v2`.
- `$rc_lifetime` is removed from the offering. Existing lifetime product IDs remain attached to `Premium` for legacy unlocks.

## App Review Notes

Suggested App Review notes:

```
QuitERGY is a local-first energy drink tracking app. Premium unlocks unlimited logging, detailed statistics, daily reminders, and multiple drink profiles.

Premium is available through auto-renewable weekly and monthly subscriptions. No account is required. To find the purchase flow, open Settings and tap "Unlock Premium", or trigger a Premium-gated action such as adding more free logs after the free allowance is used.

Purchases and restores are handled through Apple In-App Purchase and RevenueCat entitlement validation. Drink logs, notes, reminders, profiles, and progress data stay on device.
```

## Submission Gates

- Done: archive and export version `1.0.8` build `24`.
- Done: validate IPA with `altool`.
- Done: upload build `24` to App Store Connect.
- Done: attach build `24` to ASC version `1.0.8`.
- Done: create internal TestFlight group for build `24`.
- Done: configure RevenueCat offering `Default`.
- Done: upload subscription App Review screenshot for both new subscriptions.
- Blocked: run real-device TestFlight Sandbox purchase for monthly, weekly, and restore, then document the result.
- Pending after real-device evidence: submit app version `1.0.8` and both first-time subscriptions for App Review.
