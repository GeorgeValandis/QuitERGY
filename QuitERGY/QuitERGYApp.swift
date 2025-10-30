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
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            StreakRecord.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(sharedModelContainer)
    }
}
