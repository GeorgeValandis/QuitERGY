# QuitERGY App Review Prep 1.0.9

Date: 2026-06-24
Version: 1.0.9
Build: 26
Bundle ID: `com.GA.QuitERGY`
App Store ID: `6754967219`

## Reason For Submission

App Store Connect currently shows app version `1.0.8` as `READY_FOR_SALE`, while the auto-renewable subscription products remain blocked:

- `com.quitergy.premium.monthly`: `DEVELOPER_ACTION_NEEDED`
- `com.quitergy.premium.weekly.v2`: `DEVELOPER_ACTION_NEEDED`

The App Review rejection reason was Guideline 3.1.2: the reviewer could not find functional Terms of Use (EULA) and Privacy Policy links in the reviewed app binary.

## Fix In This Build

- The Premium paywall footer shows tappable `Terms of Use (EULA)` and `Privacy Policy` links next to `Restore`.
- Settings includes a `Legal` section with the same Terms and Privacy links.
- Both public legal URLs were checked on 2026-06-24 and return HTTP 200:
  - `https://georgevalandis.com/apps/quitergy/terms-and-conditions/`
  - `https://georgevalandis.com/apps/quitergy/privacy/`
- Premium copy now describes the notification difference accurately: free users can receive check-ins every 2 days, while Premium unlocks a daily check-in schedule.

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

Do not create duplicate subscription products. The existing products must be resubmitted with the new app binary and review notes.

## Current ASC State Verified 2026-06-24

- App version `1.0.8`: `READY_FOR_SALE`
- Subscription group: `Premium Access` (`21880624`)
- Monthly subscription: `6781659490`, product ID `com.quitergy.premium.monthly`, state `DEVELOPER_ACTION_NEEDED`
- Weekly v2 subscription: `6781658331`, product ID `com.quitergy.premium.weekly.v2`, state `DEVELOPER_ACTION_NEEDED`

## Submission Result 2026-06-24

- Build `26` was archived, exported, validated, and uploaded to App Store Connect.
- App Store Connect build `84a2c273-ded9-4cfd-9fa6-7528c7e193a7` is `VALID`.
- App Store version `1.0.9` (`206a4c83-c457-4454-ae15-c532650e8fcc`) is `WAITING_FOR_REVIEW`.
- en-US release notes were set for `1.0.9`.
- App Review notes were updated with the Guideline 3.1.2 legal-link fix and direct legal URLs.
- Subscription submissions were created:
  - Monthly submission `e6f2bd15-7677-40a7-9dd9-cfb94b7453e4`
  - Weekly v2 submission `2e9cb904-50e9-4d7e-b7c8-64da6795325f`
- Immediate readback still reported both subscription product states as `DEVELOPER_ACTION_NEEDED`. Apple allows `subscriptionSubmissions` creation through the API but does not allow `GET` on those submission resources, so confirm visually in App Store Connect that the subscription submissions are attached/open.

## App Review Notes

Suggested App Review notes:

```
QuitERGY is a local-first energy drink tracking app. Premium unlocks unlimited logging, detailed statistics, a daily check-in schedule, and multiple drink profiles. Free users can still use periodic check-ins; Premium upgrades the reminder cadence to daily.

Premium is available through auto-renewable weekly and monthly subscriptions. No account is required. To find the purchase flow, open Settings and tap "Unlock Premium", or trigger a Premium-gated action such as adding more free logs after the free allowance is used.

This build addresses the previous Guideline 3.1.2 feedback. The Terms of Use (EULA) and Privacy Policy links are functional in the app binary. They appear in the Premium paywall footer next to Restore and are also available in Settings > Legal.

Terms of Use (EULA): https://georgevalandis.com/apps/quitergy/terms-and-conditions/
Privacy Policy: https://georgevalandis.com/apps/quitergy/privacy/

Purchases and restores are handled through Apple In-App Purchase and RevenueCat entitlement validation. Drink logs, notes, reminders, profiles, and progress data stay on device.
```

## Submission Gates

- Done: local project bumped to version `1.0.9` build `26`.
- Done: legal links verified reachable over HTTPS.
- Done: build/test/archive/export/upload build `26`.
- Done: create App Store Connect version `1.0.9`, attach build `26`, add review notes, and submit.
- Done: resubmit Monthly and Weekly v2 subscriptions after build `26` became available for App Review.
- Follow-up: visually verify in App Store Connect that Monthly and Weekly v2 no longer require an additional manual action, because the product-state API still returned `DEVELOPER_ACTION_NEEDED` immediately after the accepted subscription submission calls.
- Recommended: complete one TestFlight sandbox purchase/restore pass on a physical device before final submission if time allows.
