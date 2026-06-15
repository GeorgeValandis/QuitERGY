//
//  QuitERGYApp.swift
//  QuitERGY
//
//  Created by Georgios Avenidis on 30.10.25.
//

import SwiftUI
import SwiftData

@main
struct QuitERGYApp: App {
    let sharedModelContainer: ModelContainer
    let persistenceService: DrinkPersistenceService
    @StateObject private var ratingController = RatingPromptController(
        appStoreURL: URL(string: "https://apps.apple.com/app/id6754967219?action=write-review")
    )
    @StateObject private var updateGate = RemoteUpdateGate(
        configuration: .init(appStoreId: "6754967219", appName: "QuitERGY")
    )
    
    @Environment(\.scenePhase) private var scenePhase

    init() {
        AppAnalytics.shared.configureRemoteAnalytics()
        PurchaseManager.configureIfNeeded()

        let schema = Schema([
            DrinkProfile.self,
            DrinkLog.self,
            UserSettings.self,
            UserProfile.self
        ])
        
        // Ensure Application Support directory exists
        let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        try? FileManager.default.createDirectory(at: appSupportURL, withIntermediateDirectories: true)
        
        let storeURL = appSupportURL.appendingPathComponent("QuitERGY.store")
        let configuration = ModelConfiguration(schema: schema, url: storeURL)

        do {
            let container = try ModelContainer(for: schema, configurations: [configuration])
            self.sharedModelContainer = container
            self.persistenceService = DrinkPersistenceService(modelContext: container.mainContext)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.drinkPersistence, persistenceService)
                .environmentObject(ratingController)
                .preferredColorScheme(.dark)
                .onAppear {
                    AppAnalytics.shared.track("app_opened")
                    // Check if badge should be shown (but don't request permission yet)
                    BadgeManager.shared.checkAndUpdateBadge()
                }
                .task {
                    await updateGate.check()
                }
                .overlay(alignment: .top) {
                    RemoteUpdateGateView(gate: updateGate)
                }
        }
        .modelContainer(sharedModelContainer)
        .onChange(of: scenePhase) { oldPhase, newPhase in
            switch newPhase {
            case .active:
                AppAnalytics.shared.track("app_became_active")
                // App became active - clear badge and update last open
                BadgeManager.shared.handleAppDidBecomeActive()
            case .background:
                AppAnalytics.shared.track("app_backgrounded")
                // App went to background - schedule badge for tomorrow
                BadgeManager.shared.handleAppWillResignActive()
            case .inactive:
                break
            @unknown default:
                break
            }
        }
    }
}
