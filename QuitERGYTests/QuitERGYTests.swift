//
//  QuitERGYTests.swift
//  QuitERGYTests
//
//  Created by Georgios Avenidis on 30.10.25.
//

import Foundation
import SwiftData
import Testing
#if canImport(RevenueCat)
import RevenueCat
#endif

@testable import QuitERGY

@Suite(.serialized)
struct QuitERGYTests {

    @MainActor
    @Test func appAnalyticsCapturesSanitizedEvents() async throws {
        let analytics = AppAnalytics.shared
        analytics.resetForTesting()
        analytics.setEnabledForTesting(true)
        defer { analytics.resetForTesting() }

        var received: [AnalyticsEventRecord] = []
        analytics.setEventSinkForTesting { event in
            received.append(event)
        }

        analytics.track(
            " paywall_viewed\n",
            properties: [
                "bad key": " value\nwith line ",
                "long_value": String(repeating: "x", count: 220),
            ])

        let event = try #require(received.first)
        let longValue = try #require(event.properties["long_value"])

        #expect(event.name == "paywall_viewed")
        #expect(event.properties["app"] == "QuitERGY")
        #expect(event.properties["bad_key"] == "value with line")
        #expect(longValue.count == 160)
        #expect(analytics.recentEvents.count == 1)
    }

    #if canImport(RevenueCat)
    @MainActor
    @Test func revenueCatConfigAcceptsExpectedProductsWhenPackageAliasChanges() async throws {
        let package = makeRevenueCatPackage(
            identifier: "custom_weekly_alias",
            packageType: .custom,
            productId: QuitERGYRevenueCat.productIdWeekly,
            price: "$1.99"
        )

        #expect(QuitERGYRevenueCat.isSupportedPurchasePackage(package))
    }

    @MainActor
    @Test func revenueCatConfigPrioritizesConfiguredPackagesAndKnownProducts() async throws {
        let unrelated = makeRevenueCatPackage(
            identifier: "$rc_annual",
            packageType: .annual,
            productId: "com.quitergy.premium.annual",
            price: "$29.99"
        )
        let customWeekly = makeRevenueCatPackage(
            identifier: "custom_weekly_alias",
            packageType: .custom,
            productId: QuitERGYRevenueCat.productIdWeekly,
            price: "$1.99"
        )
        let monthly = makeRevenueCatPackage(
            identifier: QuitERGYRevenueCat.packageIdMonthly,
            packageType: .monthly,
            productId: QuitERGYRevenueCat.productIdMonthly,
            price: "$4.99"
        )
        let offering = Offering(
            identifier: "Experiment",
            serverDescription: "Test offering",
            availablePackages: [unrelated, customWeekly, monthly],
            webCheckoutUrl: nil
        )

        let prioritized = QuitERGYRevenueCat.prioritizedPackages(in: offering)
        let firstProductIds = prioritized.prefix(2).map(\.storeProduct.productIdentifier)

        #expect(firstProductIds == [
            QuitERGYRevenueCat.productIdMonthly,
            QuitERGYRevenueCat.productIdWeekly
        ])
        #expect(prioritized.last?.storeProduct.productIdentifier == "com.quitergy.premium.annual")
    }
    #endif

    @Test func freeDrinkLogAllowanceAllowsExactlyThreeLogs() async throws {
        let suiteName = "free-drink-log-allowance-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        #expect(FreeDrinkLogAllowance.hasRemainingFreeLog(defaults: defaults))

        FreeDrinkLogAllowance.recordFreeLog(defaults: defaults)
        FreeDrinkLogAllowance.recordFreeLog(defaults: defaults)

        #expect(FreeDrinkLogAllowance.hasRemainingFreeLog(defaults: defaults))

        FreeDrinkLogAllowance.recordFreeLog(defaults: defaults)

        #expect(FreeDrinkLogAllowance.usedFreeLogCount(defaults: defaults) == 3)
        #expect(!FreeDrinkLogAllowance.hasRemainingFreeLog(defaults: defaults))
    }

    @MainActor
    @Test func freeCheckInReminderUsesEveryTwoDayCadence() async throws {
        let fixture = try makeInMemoryPersistenceFixture()
        let scheduler = CapturingReminderScheduler()
        let viewModel = SettingsViewModel(service: fixture.service, reminderScheduler: scheduler)

        await viewModel.handleReminderToggle(true, isPremiumUnlocked: false)

        #expect(viewModel.reminderEnabled)
        #expect(scheduler.scheduledCadence == .everyTwoDays)
        #expect(viewModel.reminderStatusMessage?.contains("every 2 days") == true)
    }

    @MainActor
    @Test func premiumCheckInReminderUsesDailyCadence() async throws {
        let fixture = try makeInMemoryPersistenceFixture()
        let scheduler = CapturingReminderScheduler()
        let viewModel = SettingsViewModel(service: fixture.service, reminderScheduler: scheduler)

        await viewModel.handleReminderToggle(true, isPremiumUnlocked: true)

        #expect(viewModel.reminderEnabled)
        #expect(scheduler.scheduledCadence == .daily)
        #expect(viewModel.reminderStatusMessage?.contains("Daily check-in") == true)
    }

    @Test func onboardingHasFourStepsEndingInSummary() async throws {
        let steps = OnboardingView.OnboardingStep.allCases

        #expect(steps.map(\.analyticsName) == ["baseline", "drink", "goal", "summary"])

        var workflow = OnboardingView.Workflow()
        #expect(workflow.currentStep == .baseline)
        workflow.advance()
        #expect(workflow.currentStep == .drink)
        workflow.advance()
        #expect(workflow.currentStep == .goal)
        workflow.advance()
        #expect(workflow.currentStep == .summary)
        #expect(workflow.isOnSummary)
    }

    @Test func firstLogChoiceMapsToAnalyticsValues() async throws {
        #expect(OnboardingView.FirstLogChoice.drink.analyticsValue == "drink")
        #expect(OnboardingView.FirstLogChoice.noDrink.analyticsValue == "no_drink")
    }

    @MainActor
    @Test func noDrinkLogDoesNotResetCleanStreak() async throws {
        let schema = Schema([
            DrinkProfile.self,
            DrinkLog.self,
            UserSettings.self,
            UserProfile.self,
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = container.mainContext
        let service = DrinkPersistenceService(modelContext: context)
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let startDate = try #require(calendar.date(byAdding: .day, value: -5, to: today))

        let drinkProfile = DrinkProfile(
            name: "Energy",
            brand: nil,
            variant: .classic,
            sugarGrams: 27,
            caffeineMg: 80,
            price: 2.49
        )
        let userProfile = UserProfile(
            baselineDrinksPerDay: 1,
            targetDrinksPerWeek: 0,
            drinkType: "Energy",
            pricePerDrink: 2.49,
            sugarPerDrink: 27,
            caffeinePerDrink: 80,
            startDate: startDate
        )
        let settings = UserSettings(selectedProfile: drinkProfile, userProfile: userProfile)

        context.insert(drinkProfile)
        context.insert(userProfile)
        context.insert(settings)
        _ = try service.logNoDrink(drinkProfile, date: Date())

        let viewModel = HomeViewModel(service: service)
        viewModel.loadData()

        #expect(viewModel.lastDrinkDate == nil)
        #expect(viewModel.streakDays == 5)
    }

    @MainActor
    private func makeInMemoryPersistenceFixture() throws -> InMemoryPersistenceFixture {
        let schema = Schema([
            DrinkProfile.self,
            DrinkLog.self,
            UserSettings.self,
            UserProfile.self,
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        return InMemoryPersistenceFixture(
            container: container,
            service: DrinkPersistenceService(modelContext: container.mainContext)
        )
    }

    private struct InMemoryPersistenceFixture {
        let container: ModelContainer
        let service: DrinkPersistenceService
    }

    @MainActor
    private final class CapturingReminderScheduler: ReminderScheduling {
        var scheduledCadence: ReminderCadence?

        func ensureAuthorization() async throws {}

        func scheduleCheckInReminder(at time: Date, profileName: String?, cadence: ReminderCadence) async throws {
            scheduledCadence = cadence
        }

        func cancelScheduledReminder() {}
    }

}

#if canImport(RevenueCat)
private func makeRevenueCatPackage(
    identifier: String,
    packageType: PackageType,
    productId: String,
    price: String
) -> Package {
    let product = TestStoreProduct(
        localizedTitle: productId,
        price: 1.99,
        currencyCode: "USD",
        localizedPriceString: price,
        productIdentifier: productId,
        productType: .autoRenewableSubscription,
        localizedDescription: "QuitERGY Premium",
        subscriptionGroupIdentifier: "premium",
        locale: Locale(identifier: "en_US")
    )

    return Package(
        identifier: identifier,
        packageType: packageType,
        storeProduct: product.toStoreProduct(),
        offeringIdentifier: "test",
        webCheckoutUrl: nil
    )
}
#endif
