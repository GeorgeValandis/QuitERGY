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
- Done: App Store Connect UI verification on 2026-06-29 shows Monthly, Weekly v2, and the `Premium Access` group localization are all `Waiting for Review`.
- Follow-up: wait for Apple approval of the two subscriptions, then verify a fresh non-test purchase event.
- Recommended: complete one TestFlight sandbox purchase/restore pass on a physical device before final submission if time allows.

## Subscription Resubmission Follow-up 2026-06-29

- App Store Connect API confirmed app version `1.0.9` build `26` is `READY_FOR_SALE`.
- Immediate subscription readback still showed both products as `DEVELOPER_ACTION_NEEDED` with `REJECTED` en-US localizations.
- Updated both subscription review notes to explicitly reference the live `1.0.9` legal-link fix and direct Terms/Privacy URLs.
- Created new subscription submissions after `1.0.9` was live:
  - Monthly submission `25b28708-cfa5-4955-8b8e-3d9657a7de91`
  - Weekly v2 submission `b08d5597-2228-4b6d-bde8-dc215abd0807`
- Apple still does not allow `GET` on `subscriptionSubmissions`; immediate product-state readback can still report `DEVELOPER_ACTION_NEEDED`.
- App Store Connect UI showed the `Premium Access` subscription group localization `English (U.S.)` was also `Rejected`; created subscription group submission `1b9e6a0b-29c7-43a0-b658-5a7072991f05`.
- App Store Connect UI still required manual localization saves: saved `Premium Access` group localization, then submitted it. Final group localization state: `Waiting for Review`.
- Saved both subscription en-US localizations with description `Unlock logs, detailed stats, and profiles.`, then submitted both products in ASC UI. Final states:
  - Monthly `com.quitergy.premium.monthly`: `Waiting for Review`
  - Weekly v2 `com.quitergy.premium.weekly.v2`: `Waiting for Review`
- App Store Connect API readback confirmed `WAITING_FOR_REVIEW` for Monthly, Weekly v2, and group localization after the ASC UI resubmits.
- Evidence: `release/app-store-review-1.0.9/subscription-resubmission-2026-06-29.json`
