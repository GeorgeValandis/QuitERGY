//
//  OnboardingView+Workflow.swift
//  QuitERGY
//
//  Created by Codex.
//

import SwiftUI

extension OnboardingView {
    struct Workflow {
        private let steps = OnboardingStep.allCases
        var currentStep: OnboardingStep = .baseline

        var currentIndex: Int {
            steps.firstIndex(of: currentStep) ?? 0
        }

        var totalSteps: Int {
            steps.count
        }

        var isOnSummary: Bool {
            currentStep == .summary
        }

        var isFirstStep: Bool {
            currentStep == steps.first
        }

        mutating func advance() {
            guard let index = steps.firstIndex(of: currentStep),
                  index < steps.count - 1 else { return }
            currentStep = steps[index + 1]
        }

        mutating func goBack() {
            guard let index = steps.firstIndex(of: currentStep),
                  index > 0 else { return }
            currentStep = steps[index - 1]
        }
    }

    enum FocusField: Hashable {
        case price
        case sugar
        case caffeine
    }
}
