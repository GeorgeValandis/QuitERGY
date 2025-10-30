//
//  ContentView.swift
//  QuitERGY
//
//  Created by Georgios Avenidis on 30.10.25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        MainTabView()
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

    return ContentView()
        .environment(\.drinkPersistence, service)
        .modelContainer(container)
}
