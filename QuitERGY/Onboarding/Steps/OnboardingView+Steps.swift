//
//  OnboardingView+Steps.swift
//  QuitERGY
//
//  Created by Codex.
//

import SwiftUI

extension OnboardingView {
    @ViewBuilder
    func stepContent() -> some View {
        switch workflow.currentStep {
        case .baseline:
            baselineStep()
        case .drink:
            drinkStep()
        case .composition:
            compositionStep()
        case .goal:
            goalStep()
        case .summary:
            summaryStep()
        }
    }

    @ViewBuilder
    private func baselineStep() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(BaselineFrequency.allCases) { option in
                OptionButton(
                    title: option.title,
                    subtitle: option.subtitle,
                    emoji: option.emoji,
                    isSelected: form.baselineFrequency == option
                ) {
                    form.baselineFrequency = option
                }
            }
        }
    }

    @ViewBuilder
    private func drinkStep() -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("What do you usually drink?")
                .font(.quitRounded(.medium, size: 16))
                .foregroundStyle(QuitERGYTheme.textSecondary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                ForEach(DrinkType.allCases) { type in
                    OptionButton(
                        title: type.displayName,
                        subtitle: "Sugar \(Int(type.defaultSugar)) g\n\(Int(type.defaultCaffeine)) mg caffeine",
                        emoji: nil,
                        isSelected: form.drinkType == type
                    ) {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            form.drinkType = type
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Average price per can")
                    .font(.quitRounded(.medium, size: 15))
                    .foregroundStyle(QuitERGYTheme.textSecondary)

                HStack {
                    TextField("Price", value: $form.pricePerDrink, format: .number.precision(.fractionLength(0...2)))
                        .font(.quitRounded(.semibold, size: 18))
                        .foregroundStyle(QuitERGYTheme.textPrimary)
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .price)
                        .onChange(of: form.pricePerDrink) { _, newValue in
                            if newValue < 0 {
                                form.pricePerDrink = 0
                            }
                            if focusedField == .price {
                                form.hasCustomizedPrice = true
                            }
                        }
                    Text("€")
                        .font(.quitRounded(.medium, size: 18))
                        .foregroundStyle(QuitERGYTheme.textSecondary)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: QuitERGYTheme.cardCornerRadius - 8)
                        .fill(QuitERGYTheme.surface.opacity(0.88))
                )
            }
        }
    }

    @ViewBuilder
    private func compositionStep() -> some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Adjust if your favourite drink differs.")
                .font(.quitRounded(.medium, size: 15))
                .foregroundStyle(QuitERGYTheme.textSecondary)

            HStack(spacing: 16) {
                valueCard(
                    title: "Sugar per can",
                    unit: "g",
                    value: $form.sugarPerDrink,
                    focus: .sugar
                ) {
                    form.hasCustomizedSugar = true
                }

                valueCard(
                    title: "Caffeine per can",
                    unit: "mg",
                    value: $form.caffeinePerDrink,
                    focus: .caffeine
                ) {
                    form.hasCustomizedCaffeine = true
                }
            }
        }
    }

    @ViewBuilder
    private func goalStep() -> some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Choose the outcome that excites you most.")
                .font(.quitRounded(.medium, size: 15))
                .foregroundStyle(QuitERGYTheme.textSecondary)

            ForEach(GoalType.allCases) { goal in
                OptionButton(
                    title: "\(goal.emoji) \(goal.title)",
                    subtitle: goal.subtitle,
                    emoji: nil,
                    isSelected: form.goal == goal
                ) {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        handleGoalSelection(goal)
                    }
                }
            }

            if form.goal == .reduce, let target = form.targetDrinksPerWeek {
                let baselineInt = max(1, Int(ceil(normalizedBaselinePerWeek)))
                let binding = Binding<Double>(
                    get: { min(Double(baselineInt - 1), max(0, target)) },
                    set: {
                        let clamped = min(max(0, $0.rounded()), Double(max(0, baselineInt - 1)))
                        form.targetDrinksPerWeek = clamped
                    }
                )

                VStack(alignment: .leading, spacing: 12) {
                    Text("Target drinks per week")
                        .font(.quitRounded(.medium, size: 15))
                        .foregroundStyle(QuitERGYTheme.textSecondary)

                    Stepper(value: binding, in: 0...Double(max(0, baselineInt - 1)), step: 1) {
                        Text("\(Int(binding.wrappedValue)) drinks / week")
                            .font(.quitRounded(.semibold, size: 18))
                            .foregroundStyle(QuitERGYTheme.textPrimary)
                    }
                    .labelsHidden()
                    .padding(.vertical, 4)

                    Text("From \(formatDrinks(normalizedBaselinePerWeek)) down to \(formatDrinks(binding.wrappedValue)) per week.")
                        .font(.quitRounded(.medium, size: 14))
                        .foregroundStyle(QuitERGYTheme.textSecondary)
                }
                .padding(18)
                .background(
                    RoundedRectangle(cornerRadius: QuitERGYTheme.cardCornerRadius - 8)
                        .fill(QuitERGYTheme.surface.opacity(0.88))
                )
            }
        }
    }

    @ViewBuilder
    private func summaryStep() -> some View {
        let snapshot = summarySnapshot
        VStack(alignment: .leading, spacing: 20) {
            Text(summaryHeadline)
                .font(.quitRounded(.semibold, size: 20))
                .foregroundStyle(QuitERGYTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text(summaryBody)
                .font(.quitRounded(.medium, size: 15))
                .foregroundStyle(QuitERGYTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 16) {
                MetricTile(
                    title: "Weekly baseline",
                    value: "\(formatDrinks(snapshot.weeklyBaseline)) drinks",
                    caption: "Current routine"
                )
                MetricTile(
                    title: "Weekly goal",
                    value: "\(formatDrinks(snapshot.weeklyTarget)) drinks",
                    caption: "A new target"
                )
            }

            HStack(spacing: 16) {
                MetricTile(
                    title: "Monthly savings",
                    value: formatCurrency(snapshot.monthlyMoneySavings),
                    caption: "\(formatDrinks(snapshot.monthlyDrinkSavings)) drinks avoided"
                )
                MetricTile(
                    title: "Less sugar",
                    value: "\(formatNumber(snapshot.monthlySugarSavings)) g",
                    caption: "\(formatNumber(snapshot.monthlyCaffeineSavings)) mg caffeine"
                )
            }

            Text("Ready to reclaim your energy?")
                .font(.quitRounded(.semibold, size: 18))
                .foregroundStyle(QuitERGYTheme.textPrimary)
                .padding(.top, 8)
        }
    }

    private func valueCard(title: String,
                           unit: String,
                           value: Binding<Double>,
                           focus: FocusField,
                           onEdit: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.quitRounded(.medium, size: 15))
                .foregroundStyle(QuitERGYTheme.textSecondary)

            HStack {
                TextField(title, value: value, format: .number.precision(.fractionLength(0...1)))
                    .font(.quitRounded(.semibold, size: 18))
                    .foregroundStyle(QuitERGYTheme.textPrimary)
                    .keyboardType(.decimalPad)
                    .focused($focusedField, equals: focus)
                    .onChange(of: value.wrappedValue) { _, newValue in
                        if newValue < 0 {
                            value.wrappedValue = 0
                        }
                        if focusedField == focus {
                            onEdit()
                        }
                    }
                Text(unit)
                    .font(.quitRounded(.medium, size: 18))
                    .foregroundStyle(QuitERGYTheme.textSecondary)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: QuitERGYTheme.cardCornerRadius - 8)
                    .fill(QuitERGYTheme.surface.opacity(0.88))
            )
        }
    }

    private func formatDrinks(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...1)))
    }

    private func formatNumber(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...0)))
    }

    private func formatCurrency(_ value: Double) -> String {
        value.formatted(.currency(code: "EUR").precision(.fractionLength(0...1)))
    }
}
