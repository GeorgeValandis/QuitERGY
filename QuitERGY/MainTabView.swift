//
//  MainTabView.swift
//  QuitERGY
//
//  Created by Codex.
//

import SwiftUI
import UIKit
import SwiftData

struct MainTabView: View {
    @Environment(\.drinkPersistence) private var persistence
    private let reminderScheduler: ReminderScheduling = ReminderScheduler()

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(QuitERGYTheme.background)
        let selectedColor = UIColor(QuitERGYTheme.accent)
        let normalColor = UIColor(QuitERGYTheme.textSecondary)
        appearance.stackedLayoutAppearance.selected.iconColor = selectedColor
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: selectedColor]
        appearance.stackedLayoutAppearance.normal.iconColor = normalColor
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: normalColor]
        appearance.inlineLayoutAppearance = appearance.stackedLayoutAppearance
        appearance.compactInlineLayoutAppearance = appearance.stackedLayoutAppearance
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView {
            HomeView(service: persistence)
                .tabItem {
                    Label("Home", systemImage: "bolt.heart.fill")
                }

            StatsView(service: persistence)
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.doc.horizontal.fill")
                }

            SettingsView(service: persistence, reminderScheduler: reminderScheduler)
                .tabItem {
                    Label("Settings", systemImage: "slider.horizontal.3")
                }
        }
        .tint(QuitERGYTheme.accent)
        .background(QuitERGYTheme.background.ignoresSafeArea())
    }
}

#Preview {
    let schema = Schema([
        DrinkProfile.self,
        DrinkLog.self,
        UserSettings.self
    ])
    let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [configuration])
    let service = DrinkPersistenceService(modelContext: container.mainContext)
    return MainTabView()
        .environment(\.drinkPersistence, service)
        .modelContainer(container)
}
