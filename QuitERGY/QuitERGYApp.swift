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

    init() {
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
                .preferredColorScheme(.dark)
        }
        .modelContainer(sharedModelContainer)
    }
}
