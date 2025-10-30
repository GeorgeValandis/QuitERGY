//
//  HomeViewModel.swift
//  QuitERGY
//
//  Created by Codex.
//

import Foundation
import Combine
import SwiftUI

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var streakDays: Int = 17
    @Published var lastDrinkDate: Date = Calendar.current.date(byAdding: .day, value: -17, to: .now) ?? .now
    @Published var isShowingResetAlert = false

    private let streakGoal: Double = 30

    var streakTitle: String {
        "⚡️ \(streakDays) DAYS CLEAN"
    }

    var streakSubtitle: String {
        "since your last energy drink"
    }

    var streakProgress: Double {
        guard streakGoal > 0 else { return 0 }
        return min(Double(streakDays) / streakGoal, 1.0)
    }

    var timeSinceLastDrink: String {
        let components = Calendar.current.dateComponents([.day, .hour], from: lastDrinkDate, to: .now)
        let days = components.day ?? 0
        let hours = components.hour ?? 0
        return "\(days)d \(hours)h"
    }

    func addDrink() {
        withAnimation(.easeInOut) {
            streakDays = 0
            lastDrinkDate = .now
        }
    }

    func simulateNewDay() {
        withAnimation(.easeInOut) {
            streakDays += 1
        }
    }
}
