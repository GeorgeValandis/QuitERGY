# QuitERGY App Review Prep 1.0.11

Date: 2026-07-03
Version: 1.0.11
Build: 28
Bundle ID: `com.GA.QuitERGY`
App Store ID: `6754967219`

## Reason For Submission

QuitERGY's first-time Premium Access subscriptions were returned with Guideline 2.1(b): App Review said the required binary was not submitted. Version `1.0.10` / build `27` became `READY_FOR_SALE`, but the IAPs still required review action.

This release submits a fresh app binary together with the subscription submissions so App Review can evaluate the IAPs with an active app-version review.

## Build Evidence

- Local project bumped to version `1.0.11`, build `28`.
- `xcodebuild test` succeeded on iPhone 17 Pro simulator.
- Archive succeeded: `build/QuitERGY-1.0.11-28.xcarchive`.
- Export succeeded: `build/export-1.0.11-28/QuitERGY.ipa`.
- IPA SHA-256: `eaa7d9002721dd27070bbf3a08d284e6b9b1e7595735202ce6634e66ab78afda`.
- `altool --validate-app` succeeded with no errors.
- `altool --upload-app` succeeded. Delivery UUID / ASC build id: `290920a1-a02f-4225-bf88-d2ff15c9c75a`.
- ASC build `28` readback: `VALID`, `usesNonExemptEncryption=false`.

## ASC Review Submission Evidence

- App Store version `1.0.11` id: `e40ba4d3-29cd-4905-9864-c1dc54d691dd`.
- App Store version state after submission: `WAITING_FOR_REVIEW`.
- App Review submission id: `2be9f9b5-31a1-4044-8ad5-41ac216580b3`.
- Review submission submitted date: `2026-07-03T11:36:22.895Z`.
- Review submission state: `WAITING_FOR_REVIEW`.
- Review submission contains one app-version item for `1.0.11`; item readback state: `READY_FOR_REVIEW`.

## IAP Submission Evidence

Submitted alongside the fresh app-version review:

- Monthly subscription `com.quitergy.premium.monthly` / ASC id `6781659490`: subscriptionSubmission id `96c4be4d-81f4-4b96-8103-bf9280f28282`.
- Weekly v2 subscription `com.quitergy.premium.weekly.v2` / ASC id `6781658331`: subscriptionSubmission id `abc29a05-d451-4a6b-9b68-b1b3ec750a80`.
- Premium Access subscription group `21880624`: subscriptionGroupSubmission id `65b72d07-cc0e-4746-b6a0-7c6e256c43e5`.

Final API readback on 2026-07-03:

- Monthly subscription: `WAITING_FOR_REVIEW`.
- Weekly v2 subscription: `WAITING_FOR_REVIEW`.
- English (U.S.) subscription group localization: `WAITING_FOR_REVIEW`.

Current blocker state: the fresh binary and the IAP subscription artifacts have both been submitted. The remaining gate is Apple approval, then live production confirmation through RevenueCat and TelemetryDeck `purchase_succeeded`.
