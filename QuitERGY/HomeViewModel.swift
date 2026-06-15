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
    enum LogOutcome {
        case drink
        case noDrink
    }

    @Published var streakDays: Int = 0
    @Published var lastDrinkDate: Date?
    @Published var selectedProfile: DrinkProfile?
    @Published var userProfile: UserProfile?
    @Published var recentLogs: [DrinkLog] = []
    @Published var isShowingResetAlert = false
    @Published var showMissingProfileAlert = false
    @Published var showChangeToNoDrinkAlert = false
    @Published var showChangeToDrinkAlert = false
    @Published var showPremiumRequiredAlert = false
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
            userProfile = try persistence.loadUserProfile()
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

    @discardableResult
    func addDrink() -> LogOutcome? {
        guard selectedProfile != nil else {
            showMissingProfileAlert = true
            return nil
        }
        
        // Check if there's a "No Drink" log for today
        let today = calendar.startOfDay(for: Date())
        let todayNoDrinkLogs = recentLogs.filter { log in
            calendar.startOfDay(for: log.timestamp) == today && log.isNoDrink
        }
        
        if !todayNoDrinkLogs.isEmpty {
            // Show confirmation alert
            showChangeToDrinkAlert = true
            return nil
        } else {
            // No "No Drink" log today, proceed directly
            return confirmAddDrink()
        }
    }

    @discardableResult
    func confirmAddDrink() -> LogOutcome? {
        guard let profile = selectedProfile else { return nil }
        
        do {
            #if DEBUG
            // Clear debug simulation when logging a real drink
            DebugSimulationController.shared.simulatedCleanDays = nil
            #endif
            
            // Delete all "No Drink" logs for today
            let today = calendar.startOfDay(for: Date())
            let todayNoDrinkLogs = recentLogs.filter { log in
                calendar.startOfDay(for: log.timestamp) == today && log.isNoDrink
            }
            
            for log in todayNoDrinkLogs {
                try persistence.deleteLog(log)
            }
            
            // Add drink log (allows multiple drinks per day)
            _ = try persistence.logDrink(profile, date: Date())
            isShowingResetAlert = false
            loadData()
            return .drink
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    @discardableResult
    func logNoDrink() -> LogOutcome? {
        guard selectedProfile != nil else {
            showMissingProfileAlert = true
            return nil
        }
        
        // Check if there are any drink logs for today
        let today = calendar.startOfDay(for: Date())
        let todayLogs = recentLogs.filter { log in
            calendar.startOfDay(for: log.timestamp) == today && !log.isNoDrink
        }
        
        if !todayLogs.isEmpty {
            // Show confirmation alert
            showChangeToNoDrinkAlert = true
            return nil
        } else {
            // No drinks logged today, proceed directly
            return confirmLogNoDrink()
        }
    }

    @discardableResult
    func confirmLogNoDrink() -> LogOutcome? {
        guard let profile = selectedProfile else { return nil }
        
        do {
            #if DEBUG
            // Clear debug simulation when logging "no drink"
            DebugSimulationController.shared.simulatedCleanDays = nil
            #endif
            
            // Delete all drink logs for today
            let today = calendar.startOfDay(for: Date())
            let todayDrinkLogs = recentLogs.filter { log in
                calendar.startOfDay(for: log.timestamp) == today && !log.isNoDrink
            }
            
            for log in todayDrinkLogs {
                try persistence.deleteLog(log)
            }
            
            // Add "No Drink" log
            _ = try persistence.logNoDrink(profile, date: Date())
            loadData()
            return .noDrink
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    var streakTitle: String {
        L10n.format("⚡️ %d DAYS CLEAN", streakDays)
    }

    var streakSubtitle: String {
        selectedProfile != nil
            ? L10n.text("since your last energy drink")
            : L10n.text("Set up a drink profile first")
    }

    var streakProgress: Double {
        guard streakGoal > 0 else { return 0 }
        return min(Double(streakDays) / streakGoal, 1.0)
    }

    var timeSinceLastDrink: String {
        guard let lastDrinkDate else {
            return L10n.text("No logs yet")
        }
        let components = calendar.dateComponents([.day, .hour], from: lastDrinkDate, to: Date())
        let days = components.day ?? 0
        let hours = components.hour ?? 0
        return L10n.format("%dd %dh", days, hours)
    }

    private func updateMetrics() {
        #if DEBUG
            if let simulatedDays = DebugSimulationController.shared.simulatedCleanDays {
                streakDays = simulatedDays
                lastDrinkDate = calendar.date(byAdding: .day, value: -simulatedDays, to: Date())
                return
            }
        #endif
        lastDrinkDate = recentLogs
            .filter { !$0.isNoDrink }
            .max(by: { $0.timestamp < $1.timestamp })?
            .timestamp

        let streakBaselineDate = lastDrinkDate ?? userProfile?.startDate
        streakDays = calculateStreakDays(from: streakBaselineDate)
    }

    private func calculateStreakDays(from lastDrinkDate: Date?) -> Int {
        guard let lastDrinkDate else { return 0 }
        let startOfToday = calendar.startOfDay(for: Date())
        let startOfLastLog = calendar.startOfDay(for: lastDrinkDate)
        
        // If last drink was today, streak is 0
        if startOfLastLog == startOfToday {
            return 0
        }
        
        let components = calendar.dateComponents([.day], from: startOfLastLog, to: startOfToday)
        return max(0, components.day ?? 0)
    }
    
    func hasDrinkOn(date: Date) -> Bool {
        let startOfDay = calendar.startOfDay(for: date)
        return recentLogs.contains { log in
            calendar.startOfDay(for: log.timestamp) == startOfDay
        }
    }
    
    enum DayStatus {
        case noDrink           // Green - user logged "No Drink"
        case hadDrinks(Int)    // Red - user logged drinks (with count)
        case noEntry           // Gray - no entry for this day
    }
    
    func getDayStatus(for date: Date) -> DayStatus {
        let startOfDay = calendar.startOfDay(for: date)
        let logsForDay = recentLogs.filter { log in
            calendar.startOfDay(for: log.timestamp) == startOfDay
        }
        
        // Count drink logs (isNoDrink = false)
        let drinkCount = logsForDay.filter { !$0.isNoDrink }.count
        
        if drinkCount > 0 {
            return .hadDrinks(drinkCount)
        }
        
        // If there's a "no drink" log (isNoDrink = true), show green
        if logsForDay.contains(where: { $0.isNoDrink }) {
            return .noDrink
        }
        
        // No entry for this day
        return .noEntry
    }
}
