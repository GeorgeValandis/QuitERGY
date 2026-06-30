# QuitERGY App Review Prep 1.0.10

Date: 2026-06-30
Version: 1.0.10
Build: 27
Bundle ID: `com.GA.QuitERGY`
App Store ID: `6754967219`

## Reason For Submission

Apple returned the first-time subscription products with Guideline 2.1(b): "the required binary was not submitted." Build `26` for app version `1.0.9` was already `READY_FOR_SALE`, so the subscriptions could not be reviewed together with an active app binary submission.

This release creates a fresh app binary submission so the existing monthly and weekly subscriptions can be submitted with the binary.

## Product IDs

- Monthly subscription: `com.quitergy.premium.monthly`
- Weekly subscription: `com.quitergy.premium.weekly.v2`
- Entitlement: `Premium`
- RevenueCat offering: `Default`
- RevenueCat packages: `$rc_monthly`, `$rc_weekly`

Do not create duplicate subscription products.

## Review Notes

Suggested App Review notes:

```
QuitERGY is a local-first energy drink tracking app. Premium unlocks unlimited logging, detailed statistics, a daily check-in schedule, and multiple drink profiles. Free users can still use periodic check-ins; Premium upgrades the reminder cadence to daily.

Premium is available through auto-renewable weekly and monthly subscriptions. No account is required. To find the purchase flow, open Settings and tap "Unlock Premium", or trigger a Premium-gated action such as adding more free logs after the free allowance is used.

This build is submitted together with the first-time In-App Purchase subscription products after the previous Guideline 2.1(b) note that the required binary was not submitted.

The build also addresses the earlier Guideline 3.1.2 feedback. The Terms of Use (EULA) and Privacy Policy links are functional in the app binary. They appear in the Premium paywall footer next to Restore and are also available in Settings > Legal.

Terms of Use (EULA): https://georgevalandis.com/apps/quitergy/terms-and-conditions/
Privacy Policy: https://georgevalandis.com/apps/quitergy/privacy/

Purchases and restores are handled through Apple In-App Purchase and RevenueCat entitlement validation. Drink logs, notes, reminders, profiles, and progress data stay on device.
```

## Submission Gates

- Done: build `27` passed local simulator build and `QuitERGYTests` on iPhone 17 Pro.
- Done: archived and exported `build/QuitERGY-1.0.10-27.xcarchive` / `build/export-1.0.10-27/QuitERGY.ipa`.
- Done: `altool --validate-app` succeeded with no errors.
- Done: uploaded build `27` to App Store Connect. ASC build id: `08d537f4-3a91-436b-a696-3ee4b50e835c`.
- Done: created App Store Connect version `1.0.10`. ASC app version id: `16bf7c6e-304b-40ad-848e-0f68fc72a581`.
- Done: attached build `27`, set review notes, and submitted app version `1.0.10`. ASC app version state after submission: `WAITING_FOR_REVIEW`.
- Done: submitted subscription group with this app binary. ASC submission id: `bd7ee9a1-0572-4e60-8c5b-eb59ba9893dd`.
- Done: updated both subscription review notes to reference app version `1.0.10` build `27`.
- Done: submitted Monthly subscription with this app binary. Latest ASC submission id: `28c6c276-091b-4109-b577-69957090f6c0`.
- Done: submitted Weekly v2 subscription with this app binary. Latest ASC submission id: `dde2522e-c3c8-4afa-9182-2da47955f0db`.

## API Readback After Submission

- App version `1.0.10`: `WAITING_FOR_REVIEW`
- Attached build `27`: `VALID`
- Monthly subscription: submission accepted; product readback still shows `DEVELOPER_ACTION_NEEDED` immediately after submission.
- Weekly v2 subscription: submission accepted; product readback still shows `DEVELOPER_ACTION_NEEDED` immediately after submission.
- Subscription group localization: submission accepted; localization readback still shows `REJECTED` immediately after submission.

The accepted `subscriptionSubmissions` and `subscriptionGroupSubmission` are the important evidence for the previous Guideline 2.1(b) issue. The old visible product states can lag behind or remain returned until App Review processes the now-attached binary submission.
