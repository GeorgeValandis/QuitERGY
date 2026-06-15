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
                        subtitle: L10n.format(
                            "%d g sugar\n%d mg caffeine",
                            Int(type.defaultSugar),
                            Int(type.defaultCaffeine)
                        ),
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
                    TextField(
                        "Price", value: $form.pricePerDrink,
                        format: .number.precision(.fractionLength(0...2))
                    )
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

            compositionEditor()
        }
    }

    @ViewBuilder
    private func compositionEditor() -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    showsCompositionEditor.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    Text("Fine-tune sugar & caffeine")
                        .font(.quitRounded(.medium, size: 15))
                        .foregroundStyle(QuitERGYTheme.textSecondary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(QuitERGYTheme.textSecondary)
                        .rotationEffect(.degrees(showsCompositionEditor ? 180 : 0))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if showsCompositionEditor {
                Text("Adjust if your favourite drink differs.")
                    .font(.quitRounded(.medium, size: 14))
                    .foregroundStyle(QuitERGYTheme.textSecondary)

                HStack(spacing: 16) {
                    valueCard(
                        title: L10n.text("Sugar per can"),
                        unit: "g",
                        value: $form.sugarPerDrink,
                        focus: .sugar
                    ) {
                        form.hasCustomizedSugar = true
                    }

                    valueCard(
                        title: L10n.text("Caffeine per can"),
                        unit: "mg",
                        value: $form.caffeinePerDrink,
                        focus: .caffeine
                    ) {
                        form.hasCustomizedCaffeine = true
                    }
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
                        Text(L10n.format("%d drinks / week", Int(binding.wrappedValue)))
                            .font(.quitRounded(.semibold, size: 18))
                            .foregroundStyle(QuitERGYTheme.textPrimary)
                    }
                    .labelsHidden()
                    .padding(.vertical, 4)

                    Text(
                        L10n.format(
                            "From %@ down to %@ per week.",
                            formatDrinks(normalizedBaselinePerWeek),
                            formatDrinks(binding.wrappedValue)
                        )
                    )
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

            HStack(alignment: .top, spacing: 16) {
                MetricTile(
                    title: L10n.text("Weekly baseline"),
                    value: L10n.format("%@ drinks", formatDrinks(snapshot.weeklyBaseline)),
                    caption: L10n.text("Current routine")
                )
                .frame(height: 85)
                MetricTile(
                    title: L10n.text("Weekly goal"),
                    value: L10n.format("%@ drinks", formatDrinks(snapshot.weeklyTarget)),
                    caption: L10n.text("A new target")
                )
                .frame(height: 85)
            }

            HStack(alignment: .top, spacing: 16) {
                MetricTile(
                    title: L10n.text("Monthly savings"),
                    value: formatCurrency(snapshot.monthlyMoneySavings),
                    caption: L10n.format(
                        "%@ drinks avoided", formatDrinks(snapshot.monthlyDrinkSavings))
                )
                .frame(height: 85)
                MetricTile(
                    title: L10n.text("Less sugar"),
                    value: L10n.format("%@ g", formatNumber(snapshot.monthlySugarSavings)),
                    caption: L10n.format(
                        "%@ mg caffeine", formatNumber(snapshot.monthlyCaffeineSavings))
                )
                .frame(height: 85)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text(L10n.text("Did you have an energy drink today?"))
                    .font(.quitRounded(.semibold, size: 18))
                    .foregroundStyle(QuitERGYTheme.textPrimary)

                OptionButton(
                    title: L10n.text("Yes, I had one"),
                    subtitle: L10n.text("Log it as your first entry"),
                    emoji: "\u{1F964}",
                    isSelected: form.firstLogChoice == .drink
                ) {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        selectFirstLogChoice(.drink)
                    }
                }

                OptionButton(
                    title: L10n.text("Not today"),
                    subtitle: L10n.text("Start your clean streak right away"),
                    emoji: "\u{2705}",
                    isSelected: form.firstLogChoice == .noDrink
                ) {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        selectFirstLogChoice(.noDrink)
                    }
                }
            }
            .padding(.top, 8)
        }
    }

    private func valueCard(
        title: String,
        unit: String,
        value: Binding<Double>,
        focus: FocusField,
        onEdit: @escaping () -> Void
    ) -> some View {
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
