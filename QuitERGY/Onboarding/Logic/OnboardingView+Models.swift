//
//  OnboardingView+Models.swift
//  QuitERGY
//
//  Created by Codex.
//

import SwiftUI

extension OnboardingView {
    enum OnboardingStep: Int, CaseIterable, Identifiable {
        case baseline
        case drink
        case composition
        case goal
        case summary

        var id: Int { rawValue }
    }

    enum BaselineFrequency: String, CaseIterable, Identifiable {
        case onePerWeek
        case twoToThreePerWeek
        case onePerDay
        case twoOrMorePerDay

        var id: String { rawValue }

        var title: String {
            switch self {
            case .onePerWeek: return "1 per week"
            case .twoToThreePerWeek: return "2–3 per week"
            case .onePerDay: return "1 per day"
            case .twoOrMorePerDay: return "2 or more per day"
            }
        }

        var subtitle: String {
            switch self {
            case .onePerWeek: return "Mostly on weekends"
            case .twoToThreePerWeek: return "Every other day habit"
            case .onePerDay: return "Daily routine"
            case .twoOrMorePerDay: return "Heavy usage"
            }
        }

        var emoji: String {
            switch self {
            case .onePerWeek: return "☕️"
            case .twoToThreePerWeek: return "⚡️"
            case .onePerDay: return "🔋"
            case .twoOrMorePerDay: return "🚀"
            }
        }

        var drinksPerDay: Double {
            switch self {
            case .onePerWeek:
                return 1.0 / 7.0
            case .twoToThreePerWeek:
                return 2.5 / 7.0
            case .onePerDay:
                return 1.0
            case .twoOrMorePerDay:
                return 2.0
            }
        }
    }

    enum DrinkType: String, CaseIterable, Identifiable {
        case redBull
        case monster
        case rockstar
        case other

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .redBull: return "Red Bull"
            case .monster: return "Monster"
            case .rockstar: return "Rockstar"
            case .other: return "Something else"
            }
        }

        var defaultSugar: Double {
            switch self {
            case .redBull: return 27
            case .monster: return 54
            case .rockstar: return 55
            case .other: return 30
            }
        }

        var defaultCaffeine: Double {
            switch self {
            case .redBull: return 80
            case .monster: return 160
            case .rockstar: return 160
            case .other: return 150
            }
        }

        var defaultPrice: Double {
            switch self {
            case .redBull: return 1.99
            case .monster: return 2.39
            case .rockstar: return 2.29
            case .other: return 2.10
            }
        }
    }

    enum GoalType: String, CaseIterable, Identifiable {
        case quit
        case reduce

        var id: String { rawValue }

        var title: String {
            switch self {
            case .quit: return "Quit completely"
            case .reduce: return "Drink less"
            }
        }

        var subtitle: String {
            switch self {
            case .quit: return "Zero energy drinks going forward"
            case .reduce: return "Set a realistic target per week"
            }
        }

        var emoji: String {
            switch self {
            case .quit: return "🚫"
            case .reduce: return "⚖️"
            }
        }
    }

    struct OnboardingForm {
        var baselineFrequency: BaselineFrequency?
        var drinkType: DrinkType = .redBull
        var pricePerDrink: Double = DrinkType.redBull.defaultPrice
        var sugarPerDrink: Double = DrinkType.redBull.defaultSugar
        var caffeinePerDrink: Double = DrinkType.redBull.defaultCaffeine
        var goal: GoalType = .quit
        var targetDrinksPerWeek: Double? = 0
        var hasCustomizedPrice = false
        var hasCustomizedSugar = false
        var hasCustomizedCaffeine = false
        var startDate: Date = Date()
    }

    struct SummarySnapshot: Equatable {
        var weeklyBaseline: Double
        var weeklyTarget: Double
        var monthlyDrinkSavings: Double
        var monthlyMoneySavings: Double
        var monthlySugarSavings: Double
        var monthlyCaffeineSavings: Double
    }
}
