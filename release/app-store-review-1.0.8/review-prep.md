# QuitERGY App Review Prep 1.0.8

Date: 2026-06-19
Version: 1.0.8
Build: 25
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

- App version `1.0.7` is already `READY_FOR_SALE`; the subscription-change build must therefore ship as version `1.0.8`.
- App version `1.0.8` is submitted and `WAITING_FOR_REVIEW` (`8cdfd3f2-71f3-4d0a-803f-338492d588b8`) with manual release.
- Build `25` is uploaded, processed as `VALID`, and attached to version `1.0.8` (`f63a7bef-558d-4faa-ae0d-9a6a1d177695`). See `asc-revenuecat-evidence-2026-06-19.json`.
- Build `24` remains uploaded and valid as the previous 1.0.8 candidate (`79695de0-89b8-4090-bccf-016ea4263c43`).
- Internal TestFlight group `QuitERGY Internal Review Test 1.0.8` is created and linked to builds `25` and `24` (`48ee200b-ef02-4576-bcb6-cb72cf06a07b`).
- en-US release notes and App Review notes are updated for weekly/monthly subscriptions.
- Subscription group: `Premium Access` (`21880624`).
- Weekly v2 subscription: `6781658331`, product ID `com.quitergy.premium.weekly.v2`, price USA `$1.99`, state `WAITING_FOR_REVIEW`, submission `54c42f54-08da-47aa-997e-cd197de7487c`.
- Monthly subscription: `6781659490`, product ID `com.quitergy.premium.monthly`, price USA `$4.99`, state `WAITING_FOR_REVIEW`, submission `bd479e4f-10b0-4594-8273-0692198ea6bb`.
- Both new subscriptions have en-US localization, global equalized price points, global availability, review notes, and App Review screenshots configured.

## RevenueCat State

- Project `QuitERGY` (`66808b7f`) uses entitlement `Premium`.
- Offering `Default` (`ofrnga8c48941a8`) is current.
- Package `$rc_monthly` points to `com.quitergy.premium.monthly`.
- Package `$rc_weekly` points to `com.quitergy.premium.weekly.v2`.
- `$rc_lifetime` is removed from the offering. Existing lifetime product IDs remain attached to `Premium` for legacy unlocks.
- Live RevenueCat verification on 2026-06-19 confirmed the current offering contains only `$rc_monthly` and `$rc_weekly` for the App Store app.

### Production Purchase Diagnostic - 2026-06-24

- App Store Connect API check on 2026-06-24 confirmed app version `1.0.8` is now `READY_FOR_SALE`.
- RevenueCat public offerings API check on 2026-06-24 confirmed current offering `Default` still maps `$rc_monthly` to `com.quitergy.premium.monthly` and `$rc_weekly` to `com.quitergy.premium.weekly.v2`.
- App Store Connect subscription-group check on 2026-06-24 found the production blocker: both purchase products are still `DEVELOPER_ACTION_NEEDED`.
- Monthly subscription `6781659490` has rejected en-US localization `73d6f2e1-3de9-4154-b555-6f4a89dfacec`.
- Weekly v2 subscription `6781658331` has rejected en-US localization `af1dca83-7abc-4b26-8766-c2e0cc01117e`.
- App Review notes show the rejection reason is Guideline 3.1.2: the reviewer could not find functional Terms of Use (EULA) and Privacy Policy links in the app binary.
- ASC rejected localization edit attempts with `Cannot edit SubscriptionLocalization when it is in REJECTED state`.
- New subscription review submissions were created through the ASC API: monthly `e4caefc5-247e-4ea6-b46c-0f1583162ff9`, weekly `34804a96-a555-4f76-ac8f-44d2e3017c7e`.
- Local app hardening now loads the explicit `Default` offering, hides unavailable packages, removes the direct product fallback, records RevenueCat cancellation separately from technical purchase failure, and shows functional EULA/Privacy links directly in the Paywall purchase area.
- Simulator evidence for the legal-link fix is saved as `paywall-legal-links-simulator-2026-06-24.jpg`.

## App Review Notes

Suggested App Review notes:

```
QuitERGY is a local-first energy drink tracking app. Premium unlocks unlimited logging, detailed statistics, daily reminders, and multiple drink profiles.

Premium is available through auto-renewable weekly and monthly subscriptions. No account is required. To find the purchase flow, open Settings and tap "Unlock Premium", or trigger a Premium-gated action such as adding more free logs after the free allowance is used.

The Terms of Use (EULA) and Privacy Policy links are functional in the app binary. They appear directly on the Premium paywall, below the auto-renewal notice and above the Continue purchase button. They are also available in Settings > Legal.

Purchases and restores are handled through Apple In-App Purchase and RevenueCat entitlement validation. Drink logs, notes, reminders, profiles, and progress data stay on device.
```

## Submission Gates

- Done: archive and export version `1.0.8` build `25`.
- Done: validate build `25` IPA with `altool`.
- Done: upload build `25` to App Store Connect.
- Done: attach build `25` to ASC version `1.0.8`.
- Done: create internal TestFlight group and link build `25`.
- Done: configure RevenueCat offering `Default`.
- Done: upload subscription App Review screenshot for both new subscriptions.
- Done: submit app version `1.0.8` with build `25` for App Review.
- Done: submit Monthly and Weekly v2 first-time subscriptions for App Review.
- Partial: build `24` was installed on a physical iPhone 17 Pro Max through the TestFlight invite/redeem flow, and the app loaded the RevenueCat `Default` offering with `$rc_monthly` and `$rc_weekly` mapped to `Premium`. See `testflight-sandbox-evidence/2026-06-18-device-test-partial.json`.
- Risk accepted for this submission: real-device TestFlight Sandbox purchase for monthly, weekly, and restore was not successfully completed for build `25` before submission.
