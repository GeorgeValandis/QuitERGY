//
//  OnboardingView+Derived.swift
//  QuitERGY
//
//  Created by Codex.
//

import Foundation

extension OnboardingView {
    var progressValue: Double {
        guard workflow.totalSteps > 0 else { return 0 }
        return Double(workflow.currentIndex + 1) / Double(workflow.totalSteps)
    }

    var stepIndicatorText: String {
        L10n.format("Step %d of %d", workflow.currentIndex + 1, workflow.totalSteps)
    }

    var stepTitle: String {
        switch workflow.currentStep {
        case .baseline:
            return L10n.text("How often do you drink energy drinks?")
        case .drink:
            return L10n.text("Pick your go-to drink")
        case .goal:
            return L10n.text("Define your goal")
        case .summary:
            return L10n.text("Ready to start?")
        }
    }

    var stepSubtitle: String {
        switch workflow.currentStep {
        case .baseline:
            return L10n.text("Understanding your routine builds a personalised baseline.")
        case .drink:
            return L10n.text("Price helps us calculate realistic savings.")
        case .goal:
            return L10n.text("Choose the path that fits your journey.")
        case .summary:
            return L10n.text("Here’s what changes when you start today.")
        }
    }

    var primaryActionTitle: String {
        workflow.isOnSummary ? L10n.text("Start My Journey ⚡️") : L10n.text("Continue")
    }

    var isCurrentStepValid: Bool {
        switch workflow.currentStep {
        case .baseline:
            return form.baselineFrequency != nil
        case .drink:
            return form.pricePerDrink > 0 && form.sugarPerDrink >= 0 && form.caffeinePerDrink >= 0
        case .goal:
            switch form.goal {
            case .quit:
                return true
            case .reduce:
                guard normalizedBaselinePerWeek > 0,
                    let target = form.targetDrinksPerWeek
                else { return false }
                return target >= 0 && target < normalizedBaselinePerWeek
            }
        case .summary:
            return form.firstLogChoice != nil
        }
    }

    var validationMessage: String? {
        guard !isCurrentStepValid else { return nil }
        switch workflow.currentStep {
        case .baseline:
            return L10n.text("Choose the option that matches your current habit.")
        case .drink:
            if form.pricePerDrink <= 0 {
                return L10n.text("Enter a realistic average price per drink.")
            }
            return L10n.text("Sugar and caffeine can’t be negative.")
        case .goal:
            return L10n.text("Set a target that’s lower than your current baseline.")
        case .summary:
            return L10n.text("Answer the question above to start your tracking.")
        }
    }

    var summarySnapshot: SummarySnapshot {
        makeSummarySnapshot()
    }

    var summaryHeadline: String {
        let weekly = summarySnapshot.weeklyBaseline
        let formattedWeekly = weekly.formatted(.number.precision(.fractionLength(0...1)))
        return L10n.format("You currently drink about %@ per week.", formattedWeekly)
    }

    var summaryBody: String {
        let savings = summarySnapshot.monthlyMoneySavings.formatted(
            .currency(code: "EUR").precision(.fractionLength(0...1)))
        let sugar = summarySnapshot.monthlySugarSavings.formatted(
            .number.precision(.fractionLength(0...0)))
        return L10n.format(
            "Start today and you can save around %@ and %@ g of sugar every month.", savings, sugar)
    }
}
