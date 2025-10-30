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
    let unit: String
    let formattedValue: String
}

struct ProgressPoint: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
}

@MainActor
final class StatsViewModel: ObservableObject {
    @Published var metrics: [StatsMetric] = [
        StatsMetric(type: .money, value: 48.75, unit: "€", formattedValue: "€48.75"),
        StatsMetric(type: .sugar, value: 366, unit: "g", formattedValue: "366g"),
        StatsMetric(type: .drinks, value: 34, unit: "", formattedValue: "34")
    ]

    @Published var progress: [ProgressPoint] = [
        ProgressPoint(label: "Mon", value: 1),
        ProgressPoint(label: "Tue", value: 1),
        ProgressPoint(label: "Wed", value: 2),
        ProgressPoint(label: "Thu", value: 2),
        ProgressPoint(label: "Fri", value: 3),
        ProgressPoint(label: "Sat", value: 3),
        ProgressPoint(label: "Sun", value: 4)
    ]
}
