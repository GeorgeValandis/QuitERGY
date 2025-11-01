//
//  HomeViewModel.swift
//  QuitERGY
//
//  Created by Codex.
//

import Combine
import Foundation
import SwiftUI

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var streakDays: Int = 0
    @Published var lastDrinkDate: Date?
    @Published var selectedProfile: DrinkProfile?
    @Published var recentLogs: [DrinkLog] = []
    @Published var isShowingResetAlert = false
    @Published var showMissingProfileAlert = false
    @Published var errorMessage: String?

    private let persistence: DrinkPersistenceProviding
    private let calendar = Calendar.current
    private let streakGoal: Double = 30
    #if DEBUG
        private var simulationCancellable: AnyCancellable?
    #endif

    init(service: DrinkPersistenceProviding) {
        self.persistence = service

        #if DEBUG
            simulationCancellable = DebugSimulationController.shared.$simulatedCleanDays
                .removeDuplicates()
                .sink { [weak self] _ in
                    self?.updateMetrics()
                }
        #endif
    }

    func loadData() {
        do {
            selectedProfile = try persistence.loadSelectedProfile()
            let start =
                calendar.date(byAdding: .day, value: -365, to: Date())
                ?? Date().addingTimeInterval(-365 * 24 * 60 * 60)
            let interval = DateInterval(start: start, end: Date())
            recentLogs = try persistence.fetchRecentLogs(in: interval)
            updateMetrics()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addDrink() {
        guard let profile = selectedProfile else {
            showMissingProfileAlert = true
            return
        }

        do {
            _ = try persistence.logDrink(profile, date: Date())
            isShowingResetAlert = false
            loadData()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    var streakTitle: String {
        "⚡️ \(streakDays) DAYS CLEAN"
    }

    var streakSubtitle: String {
        selectedProfile != nil ? "since your last energy drink" : "Set up a drink profile first"
    }

    var streakProgress: Double {
        guard streakGoal > 0 else { return 0 }
        return min(Double(streakDays) / streakGoal, 1.0)
    }

    var timeSinceLastDrink: String {
        guard let lastDrinkDate else {
            return "No logs yet"
        }
        let components = calendar.dateComponents([.day, .hour], from: lastDrinkDate, to: Date())
        let days = components.day ?? 0
        let hours = components.hour ?? 0
        return "\(days)d \(hours)h"
    }

    private func updateMetrics() {
        #if DEBUG
            if let simulatedDays = DebugSimulationController.shared.simulatedCleanDays {
                streakDays = simulatedDays
                lastDrinkDate = calendar.date(byAdding: .day, value: -simulatedDays, to: Date())
                return
            }
        #endif
        lastDrinkDate = recentLogs.sorted(by: { $0.timestamp > $1.timestamp }).first?.timestamp
        streakDays = calculateStreakDays(from: lastDrinkDate)
    }

    private func calculateStreakDays(from lastDrinkDate: Date?) -> Int {
        guard let lastDrinkDate else { return 0 }
        let startOfToday = calendar.startOfDay(for: Date())
        let startOfLastLog = calendar.startOfDay(for: lastDrinkDate)
        let components = calendar.dateComponents([.day], from: startOfLastLog, to: startOfToday)
        return max(0, components.day ?? 0)
    }
}
