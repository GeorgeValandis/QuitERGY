//
//  RootView.swift
//  QuitERGY
//
//  Created by Codex.
//

import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var modelContext

    @Query var settings: [UserSettings]
    @State private var hasEnsuredSettings = false
    @State private var ensureError: String?
    @State private var showPaywall = false

    init() {
        _settings = Query(FetchDescriptor<UserSettings>())
    }

    var body: some View {
        Group {
            if let ensureError {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 34))
                        .foregroundStyle(.yellow)
                    Text("Setup failed")
                        .font(.quitRounded(.semibold, size: 20))
                        .foregroundStyle(QuitERGYTheme.textPrimary)
                    Text(ensureError)
                        .font(.quitRounded(.medium, size: 15))
                        .foregroundStyle(QuitERGYTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(24)
                .background(QuitERGYTheme.background.ignoresSafeArea())
            } else if !hasEnsuredSettings {
                ProgressView("Loading…")
                    .font(.quitRounded(.semibold, size: 16))
                    .foregroundStyle(QuitERGYTheme.textPrimary)
                    .padding()
                    .background(QuitERGYTheme.background.ignoresSafeArea())
            } else if settings.first?.hasCompletedOnboarding == true {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .background(QuitERGYTheme.background.ignoresSafeArea())
        .sheet(isPresented: $showPaywall) {
            PaywallView()
                .environmentObject(PurchaseManager.shared)
                .interactiveDismissDisabled()
        }
        .task {
            await ensureSettingsRecord()
            if ProcessInfo.processInfo.environment["UITEST_SHOW_PAYWALL_ON_LAUNCH"] == "1" {
                AppAnalytics.shared.track("paywall_presented", properties: [
                    "surface": "uitest",
                    "trigger": "launch_argument"
                ])
                showPaywall = true
            }
        }
    }

    private func ensureSettingsRecord() async {
        guard !hasEnsuredSettings else { return }
        do {
            let shouldSkipOnboardingForUITests = ProcessInfo.processInfo.environment["UITEST_SKIP_ONBOARDING"] == "1"
            var descriptor = FetchDescriptor<UserSettings>()
            descriptor.fetchLimit = 1
            if let existing = try modelContext.fetch(descriptor).first {
                if shouldSkipOnboardingForUITests, !existing.hasCompletedOnboarding {
                    existing.hasCompletedOnboarding = true
                    try modelContext.save()
                }
            } else {
                let settings = UserSettings()
                if shouldSkipOnboardingForUITests {
                    settings.hasCompletedOnboarding = true
                }
                modelContext.insert(settings)
                try modelContext.save()
            }
            hasEnsuredSettings = true
        } catch {
            ensureError = error.localizedDescription
        }
    }
}

#Preview {
    let schema = Schema([
        DrinkProfile.self,
        DrinkLog.self,
        UserSettings.self,
        UserProfile.self
    ])
    let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [configuration])
    let service = DrinkPersistenceService(modelContext: container.mainContext)

    return RootView()
        .environment(\.drinkPersistence, service)
        .modelContainer(container)
}
