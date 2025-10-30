//
//  OnboardingView+Normalization.swift
//  QuitERGY
//
//  Created by Codex.
//

import Foundation

extension OnboardingView {
    var normalizedBaselinePerDay: Double {
        form.baselineFrequency?.drinksPerDay ?? 0
    }

    var normalizedBaselinePerWeek: Double {
        normalizedBaselinePerDay * 7
    }

    var normalizedBaselinePerMonth: Double {
        normalizedBaselinePerWeek * 4
    }

    var normalizedTargetPerWeek: Double {
        switch form.goal {
        case .quit:
            return 0
        case .reduce:
            return max(0, min(normalizedBaselinePerWeek, form.targetDrinksPerWeek ?? normalizedBaselinePerWeek))
        }
    }

    var normalizedTargetPerMonth: Double {
        normalizedTargetPerWeek * 4
    }

    var normalizedDrinkSavingsPerWeek: Double {
        max(0, normalizedBaselinePerWeek - normalizedTargetPerWeek)
    }

    var normalizedDrinkSavingsPerMonth: Double {
        normalizedDrinkSavingsPerWeek * 4
    }

    func makeSummarySnapshot() -> SummarySnapshot {
        let drinkSavings = normalizedDrinkSavingsPerMonth
        let moneySavings = drinkSavings * max(0, form.pricePerDrink)
        let sugarSavings = drinkSavings * max(0, form.sugarPerDrink)
        let caffeineSavings = drinkSavings * max(0, form.caffeinePerDrink)

        return SummarySnapshot(
            weeklyBaseline: normalizedBaselinePerWeek,
            weeklyTarget: normalizedTargetPerWeek,
            monthlyDrinkSavings: drinkSavings,
            monthlyMoneySavings: moneySavings,
            monthlySugarSavings: sugarSavings,
            monthlyCaffeineSavings: caffeineSavings
        )
    }
}
