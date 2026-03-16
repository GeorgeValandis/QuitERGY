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
    @EnvironmentObject private var ratingController: RatingPromptController

    @Query var settings: [UserSettings]
    @State private var hasEnsuredSettings = false
    @State private var ensureError: String?
    @State private var showPaywall = false
    @State private var showRatingPrompt = false
    @State private var shouldTriggerRatingAfterPaywall = false

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
                OnboardingView {
                    showPaywall = true
                    // Mark that we should trigger rating after paywall dismisses
                    shouldTriggerRatingAfterPaywall = true
                }
            }
        }
        .background(QuitERGYTheme.background.ignoresSafeArea())
        .sheet(isPresented: $showPaywall) {
            PaywallView()
                .environmentObject(PurchaseManager.shared)
                .environmentObject(ratingController)
                .interactiveDismissDisabled()
        }
        .sheet(isPresented: $showRatingPrompt) {
            AppStoreRatingView(
                onRateNow: {
                    ratingController.handleRateNowAction()
                },
                onSendFeedback: {
                    // TODO: Feedback-Logik implementieren (z.B. E-Mail öffnen)
                    ratingController.completePrompt()
                },
                onMaybeLater: {
                    ratingController.completePrompt()
                }
            )
        }
        .task {
            await ensureSettingsRecord()
            if ProcessInfo.processInfo.environment["UITEST_SHOW_PAYWALL_ON_LAUNCH"] == "1" {
                showPaywall = true
            }
        }
        .onChange(of: ratingController.isPresentingPrompt) { _, newValue in
            showRatingPrompt = newValue
        }
        .onChange(of: showPaywall) { _, isShowing in
            // When paywall is dismissed and we should trigger rating
            print("🔍 Paywall onChange: isShowing=\(isShowing), shouldTrigger=\(shouldTriggerRatingAfterPaywall)")
            if !isShowing && shouldTriggerRatingAfterPaywall {
                print("✅ Triggering rating after paywall dismiss")
                shouldTriggerRatingAfterPaywall = false
                // Delay slightly to ensure smooth transition
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    print("⭐️ Showing rating prompt directly after onboarding")
                    ratingController.isPresentingPrompt = true
                }
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
