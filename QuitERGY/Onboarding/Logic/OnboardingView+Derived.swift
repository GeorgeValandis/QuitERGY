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
        "Step \(workflow.currentIndex + 1) of \(workflow.totalSteps)"
    }

    var stepTitle: String {
        switch workflow.currentStep {
        case .baseline:
            return "How often do you drink energy drinks?"
        case .drink:
            return "Pick your go-to drink"
        case .composition:
            return "What’s inside your drink?"
        case .goal:
            return "Define your goal"
        case .summary:
            return "Ready to start?"
        }
    }

    var stepSubtitle: String {
        switch workflow.currentStep {
        case .baseline:
            return "Understanding your routine builds a personalised baseline."
        case .drink:
            return "Price helps us calculate realistic savings."
        case .composition:
            return "Sugar and caffeine power your future victories."
        case .goal:
            return "Choose the path that fits your journey."
        case .summary:
            return "Here’s what changes when you start today."
        }
    }

    var primaryActionTitle: String {
        workflow.isOnSummary ? "Start My Journey ⚡️" : "Continue"
    }

    var isCurrentStepValid: Bool {
        switch workflow.currentStep {
        case .baseline:
            return form.baselineFrequency != nil
        case .drink:
            return form.pricePerDrink > 0
        case .composition:
            return form.sugarPerDrink >= 0 && form.caffeinePerDrink >= 0
        case .goal:
            switch form.goal {
            case .quit:
                return true
            case .reduce:
                guard normalizedBaselinePerWeek > 0,
                      let target = form.targetDrinksPerWeek else { return false }
                return target >= 0 && target < normalizedBaselinePerWeek
            }
        case .summary:
            return true
        }
    }

    var validationMessage: String? {
        guard !isCurrentStepValid else { return nil }
        switch workflow.currentStep {
        case .baseline:
            return "Choose the option that matches your current habit."
        case .drink:
            return "Enter a realistic average price per drink."
        case .composition:
            return "Sugar and caffeine can’t be negative."
        case .goal:
            return "Set a target that’s lower than your current baseline."
        case .summary:
            return nil
        }
    }

    var summarySnapshot: SummarySnapshot {
        makeSummarySnapshot()
    }

    var summaryHeadline: String {
        let weekly = summarySnapshot.weeklyBaseline
        let formattedWeekly = weekly.formatted(.number.precision(.fractionLength(0...1)))
        return "You currently drink about \(formattedWeekly) per week."
    }

    var summaryBody: String {
        let savings = summarySnapshot.monthlyMoneySavings.formatted(.currency(code: "EUR").precision(.fractionLength(0...1)))
        let sugar = summarySnapshot.monthlySugarSavings.formatted(.number.precision(.fractionLength(0...0)))
        return "Start today and you can save around \(savings) and \(sugar) g of sugar every month."
    }
}
