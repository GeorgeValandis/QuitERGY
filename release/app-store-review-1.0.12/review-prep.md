# QuitERGY App Review Prep 1.0.12

Date: 2026-07-05
Version: 1.0.12
Build: 30
Bundle ID: `com.GA.QuitERGY`
App Store ID: `6754967219`

## Why 1.0.12 Exists

Version `1.0.11` moved to `READY_FOR_SALE` with build `28`, but the Premium Access subscription products stayed in Apple's separate IAP review queue as `WAITING_FOR_REVIEW`.

The first attempt to replace `1.0.11` with build `29` was rejected by App Store Connect validation because the `1.0.11` pre-release train was already closed. The replacement therefore had to be submitted as a higher version: `1.0.12` build `30`.

## Why The Subscriptions Were Not Finished With 1.0.11

Apple's app-version review and first-time subscription review are separate review resources. The `1.0.11` app-version review completed and the app binary became live, while the subscription products and subscription group localization remained `WAITING_FOR_REVIEW`. They were not returned to `DEVELOPER_ACTION_NEEDED`, so there was no new product-level submit action available in App Store Connect.

For `1.0.12`, the app review notes and both subscription review notes now explicitly reference app version `1.0.12` build `30`, so App Review has the current binary context while the IAP items remain in review.

## Build Evidence

- Local project bumped to version `1.0.12`, build `30`.
- RevenueCat offering resolution fix is in commit `add659e`.
- Archive succeeded: `build/QuitERGY-1.0.12-30.xcarchive`.
- Export succeeded: `build/export-1.0.12-30/QuitERGY.ipa`.
- IPA SHA-256: `6cce15e1915be2c099973e33b808aafa921fb762ca49d98434819232ef1e0534`.
- `altool --validate-app` succeeded with no errors.
- `altool --upload-app` succeeded. Delivery UUID / ASC build id: `c1bb9c31-1198-4bdc-867b-cbc1a5db9401`.
- ASC build `30` readback: `VALID`, `usesNonExemptEncryption=false`.

## ASC Review Submission Evidence

- App Store version `1.0.12` id: `16b18a78-82a6-426c-ace5-8f846ce70c17`.
- App Store version state after submission: `WAITING_FOR_REVIEW`.
- App Review submission id: `db02f641-9f9c-4e39-a723-15386814e0b8`.
- Review submission submitted date: `2026-07-05T16:19:44.508Z`.
- Review submission state: `WAITING_FOR_REVIEW`.
- Review submission item readback state: `READY_FOR_REVIEW`.
- Release notes: `Improves Premium purchase handling and subscription offering reliability.`

## IAP Review State

Current API readback after submitting `1.0.12`:

- Monthly subscription `com.quitergy.premium.monthly` / ASC id `6781659490`: `WAITING_FOR_REVIEW`.
- Weekly v2 subscription `com.quitergy.premium.weekly.v2` / ASC id `6781658331`: `WAITING_FOR_REVIEW`.
- Monthly en-US localization `7148defd-ffe0-4554-be75-b3eb7eedbfb4`: `WAITING_FOR_REVIEW`.
- Weekly v2 en-US localization `4bcb54af-3491-47f6-9e93-29a4cfcd819b`: `WAITING_FOR_REVIEW`.
- Premium Access group localization `98dd8b21-7cd0-442a-b1b0-9e6ad9aaf3fb`: `WAITING_FOR_REVIEW`.
- Both subscription review notes were patched to reference app version `1.0.12` build `30`.
- Both IAP review screenshots are uploaded and complete.

## Remaining Gate

Apple must approve both subscriptions and the subscription group localization. The production purchase blocker is only fully cleared after App Store Connect shows the IAPs approved and live telemetry/revenue data shows a fresh `purchase_succeeded`.
