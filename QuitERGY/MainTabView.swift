//
//  MainTabView.swift
//  QuitERGY
//
//  Created by Codex.
//

import SwiftUI
import UIKit

struct MainTabView: View {
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
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "bolt.heart.fill")
                }

            StatsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.doc.horizontal.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "slider.horizontal.3")
                }
        }
        .tint(QuitERGYTheme.accent)
        .background(QuitERGYTheme.background.ignoresSafeArea())
    }
}

#Preview {
    MainTabView()
}
