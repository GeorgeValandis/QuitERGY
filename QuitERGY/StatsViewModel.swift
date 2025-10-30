//
//  StatsViewModel.swift
//  QuitERGY
//
//  Created by Codex.
//

import Foundation
import Combine

struct StatsMetric: Identifiable {
    enum MetricType: String {
        case money = "Money Saved"
        case sugar = "Sugar Avoided"
        case drinks = "Drinks Skipped"
    }

    let id = UUID()
    let type: MetricType
    let value: Double
    let formattedValue: String
    let unit: String
}

struct ProgressPoint: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
}

@MainActor
final class StatsViewModel: ObservableObject {
    @Published var metrics: [StatsMetric] = [
        StatsMetric(type: .money, value: 0, formattedValue: "€0.00", unit: "€"),
        StatsMetric(type: .sugar, value: 0, formattedValue: "0g", unit: "g"),
        StatsMetric(type: .drinks, value: 0, formattedValue: "0", unit: "")
    ]
    @Published var progress: [ProgressPoint] = []
    @Published var selectedProfile: DrinkProfile?
    @Published var errorMessage: String?

    private let persistence: DrinkPersistenceProviding
    private let calendar = Calendar.current
    private let currencyFormatter: NumberFormatter
    private let numberFormatter: NumberFormatter

    init(service: DrinkPersistenceProviding) {
        self.persistence = service
        self.currencyFormatter = NumberFormatter()
        currencyFormatter.numberStyle = .currency
        currencyFormatter.locale = Locale.current

        self.numberFormatter = NumberFormatter()
        numberFormatter.maximumFractionDigits = 1
        numberFormatter.minimumFractionDigits = 0
    }

    func loadData() {
        do {
            selectedProfile = try persistence.loadSelectedProfile()
            let endDate = Date()
            let startDate = calendar.date(byAdding: .day, value: -365, to: endDate) ?? endDate.addingTimeInterval(-365 * 24 * 60 * 60)
            let logs = try persistence.fetchRecentLogs(in: DateInterval(start: startDate, end: endDate))

            computeMetrics(using: logs)
            computeProgress(using: logs)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func computeMetrics(using logs: [DrinkLog]) {
        guard let profile = selectedProfile else {
            metrics = [
                StatsMetric(type: .money, value: 0, formattedValue: "€0.00", unit: "€"),
                StatsMetric(type: .sugar, value: 0, formattedValue: "0g", unit: "g"),
                StatsMetric(type: .drinks, value: 0, formattedValue: "0", unit: "")
            ]
            return
        }

        let lastLogDate = logs.max(by: { $0.timestamp < $1.timestamp })?.timestamp
        let streakDays = calculateStreakDays(from: lastLogDate)
        let avoidedDrinks = Double(streakDays)

        let moneyValue = avoidedDrinks * priceValue(profile.price)
        let sugarValue = avoidedDrinks * profile.sugarGrams
        let drinksValue = avoidedDrinks

        metrics = [
            StatsMetric(
                type: .money,
                value: moneyValue,
                formattedValue: currencyFormatter.string(from: NSNumber(value: moneyValue)) ?? "€0.00",
                unit: "€"
            ),
            StatsMetric(
                type: .sugar,
                value: sugarValue,
                formattedValue: "\(numberFormatter.string(from: NSNumber(value: sugarValue)) ?? "0")g",
                unit: "g"
            ),
            StatsMetric(
                type: .drinks,
                value: drinksValue,
                formattedValue: "\(Int(drinksValue))",
                unit: ""
            )
        ]
    }

    private func computeProgress(using logs: [DrinkLog]) {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "EEE"

        let today = calendar.startOfDay(for: Date())
        let start = calendar.date(byAdding: .day, value: -6, to: today) ?? today

        var counts: [Date: Int] = [:]
        for log in logs {
            let day = calendar.startOfDay(for: log.timestamp)
            if day >= start && day <= today {
                counts[day, default: 0] += 1
            }
        }

        var points: [ProgressPoint] = []
        for offset in 0...6 {
            if let day = calendar.date(byAdding: .day, value: offset, to: start) {
                let label = formatter.string(from: day)
                let value = Double(counts[day, default: 0])
                points.append(ProgressPoint(label: label, value: value))
            }
        }
        progress = points
    }

    private func calculateStreakDays(from lastDrinkDate: Date?) -> Int {
        guard let lastDrinkDate else { return 0 }
        let startOfToday = calendar.startOfDay(for: Date())
        let startOfLast = calendar.startOfDay(for: lastDrinkDate)
        let components = calendar.dateComponents([.day], from: startOfLast, to: startOfToday)
        return max(0, components.day ?? 0)
    }

    private func priceValue(_ price: Decimal) -> Double {
        NSDecimalNumber(decimal: price).doubleValue
    }
}
