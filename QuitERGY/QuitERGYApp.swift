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
    @StateObject private var ratingController = RatingPromptController()
    
    @Environment(\.scenePhase) private var scenePhase

    init() {
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
                    // Check if badge should be shown (but don't request permission yet)
                    BadgeManager.shared.checkAndUpdateBadge()
                }
        }
        .modelContainer(sharedModelContainer)
        .onChange(of: scenePhase) { oldPhase, newPhase in
            switch newPhase {
            case .active:
                // App became active - clear badge and update last open
                BadgeManager.shared.handleAppDidBecomeActive()
            case .background:
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
