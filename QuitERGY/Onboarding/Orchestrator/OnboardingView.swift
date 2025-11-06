//
//  OnboardingView.swift
//  QuitERGY
//
//  Created by Codex.
//

import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.drinkPersistence) private var persistence

    let onCompleted: () -> Void

    @State var workflow = Workflow()
    @State var form = OnboardingForm()
    @State private var showValidationHint = false
    @State private var errorMessage: String?
    @FocusState var focusedField: FocusField?

    init(onCompleted: @escaping () -> Void = {}) {
        self.onCompleted = onCompleted
    }

    var body: some View {
        ZStack {
            onboardingBackground
            VStack(spacing: 28) {
                headerSection

                StepDetailView(
                    indicator: stepIndicatorText,
                    title: stepTitle,
                    subtitle: stepSubtitle
                ) {
                    stepContent()
                }
                .animation(.easeInOut(duration: 0.3), value: workflow.currentStep)

                Spacer(minLength: 0)

                if showValidationHint, let message = validationMessage {
                    Text(message)
                        .font(.quitRounded(.medium, size: 14))
                        .foregroundStyle(Color.red.opacity(0.85))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .transition(.opacity)
                }

                footerControls
            }
            .padding(.horizontal, 24)
            .padding(.top, 36)
            .padding(.bottom, 30)
        }
        .onAppear {
            applyDefaults(for: form.drinkType)
        }
        .onChange(of: workflow.currentStep) { _, _ in
            showValidationHint = false
            focusedField = nil
        }
        .onChange(of: form.drinkType) { oldValue, newValue in
            guard oldValue != newValue else { return }
            form.hasCustomizedPrice = false
            form.hasCustomizedSugar = false
            form.hasCustomizedCaffeine = false
            applyDefaults(for: newValue)
        }
        .onChange(of: form.baselineFrequency) { _, _ in
            if form.goal == .reduce {
                handleGoalSelection(.reduce)
            }
        }
        .alert("Something went wrong", isPresented: errorBinding) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "We couldn’t save your onboarding data. Please try again.")
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Let’s personalise QuitERGY")
                    .font(.quitRounded(.semibold, size: 22))
                    .foregroundStyle(QuitERGYTheme.textPrimary)
                Text("Tell us where you’re starting so we can cheer every win.")
                    .font(.quitRounded(.medium, size: 15))
                    .foregroundStyle(QuitERGYTheme.textSecondary)
            }

            progressBar(value: progressValue)
                .frame(height: 10)
        }
    }

    private var footerControls: some View {
        HStack(spacing: 16) {
            if !workflow.isFirstStep {
                secondaryButton(title: "Back") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        workflow.goBack()
                    }
                }
            }

            primaryButton(title: primaryActionTitle, isDisabled: false) {
                handlePrimaryAction()
            }
        }
    }

    private func handlePrimaryAction() {
        guard isCurrentStepValid else {
            withAnimation(.easeInOut(duration: 0.3)) {
                showValidationHint = true
            }
            return
        }

        showValidationHint = false

        if workflow.isOnSummary {
            completeOnboarding()
        } else {
            withAnimation(.easeInOut(duration: 0.35)) {
                workflow.advance()
            }
        }
    }

    private func completeOnboarding() {
        do {
            try persistProfile()
            onCompleted()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func applyDefaults(for type: DrinkType) {
        if !form.hasCustomizedPrice {
            form.pricePerDrink = type.defaultPrice
        }
        if !form.hasCustomizedSugar {
            form.sugarPerDrink = type.defaultSugar
        }
        if !form.hasCustomizedCaffeine {
            form.caffeinePerDrink = type.defaultCaffeine
        }
        if form.goal == .reduce {
            handleGoalSelection(.reduce)
        }
    }

    func handleGoalSelection(_ goal: GoalType) {
        form.goal = goal
        switch goal {
        case .quit:
            form.targetDrinksPerWeek = 0
        case .reduce:
            let baselineInt = max(1, Int(ceil(normalizedBaselinePerWeek)))
            let defaultTarget = Double(max(0, baselineInt - 1))
            form.targetDrinksPerWeek = defaultTarget
        }
    }

    private func persistProfile() throws {
        let profile = try fetchOrCreateProfile()
        profile.baselineDrinksPerDay = normalizedBaselinePerDay
        profile.targetDrinksPerWeek = normalizedTargetPerWeek
        profile.drinkType = form.drinkType.displayName
        profile.pricePerDrink = form.pricePerDrink
        profile.sugarPerDrink = form.sugarPerDrink
        profile.caffeinePerDrink = form.caffeinePerDrink
        profile.startDate = form.startDate

        // Find or create DrinkProfile - avoid duplicates
        let input = DrinkProfileInput(
            name: form.drinkType.displayName,
            brand: form.drinkType.brandName,
            variant: form.drinkType.variant,
            sugarGrams: form.sugarPerDrink,
            caffeineMg: form.caffeinePerDrink,
            price: Decimal(form.pricePerDrink)
        )
        let drinkProfile = try persistence.findOrCreateProfile(input: input)
        try persistence.selectProfile(drinkProfile)

        let settings = try fetchOrCreateSettings()
        settings.hasCompletedOnboarding = true
        settings.userProfile = profile
        if settings.dailyTargetDrinks == nil {
            let dailyTarget = Int(ceil(normalizedTargetPerWeek / 7.0))
            settings.dailyTargetDrinks = max(0, dailyTarget)
        }

        try modelContext.save()
    }

    private func fetchOrCreateProfile() throws -> UserProfile {
        var descriptor = FetchDescriptor<UserProfile>()
        descriptor.fetchLimit = 1
        if let existing = try modelContext.fetch(descriptor).first {
            return existing
        }

        let profile = UserProfile(
            baselineDrinksPerDay: normalizedBaselinePerDay,
            targetDrinksPerWeek: normalizedTargetPerWeek,
            drinkType: form.drinkType.displayName,
            pricePerDrink: form.pricePerDrink,
            sugarPerDrink: form.sugarPerDrink,
            caffeinePerDrink: form.caffeinePerDrink,
            startDate: form.startDate
        )
        modelContext.insert(profile)
        return profile
    }

    private func fetchOrCreateSettings() throws -> UserSettings {
        var descriptor = FetchDescriptor<UserSettings>()
        descriptor.fetchLimit = 1
        if let existing = try modelContext.fetch(descriptor).first {
            return existing
        }
        let settings = UserSettings()
        modelContext.insert(settings)
        return settings
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )
    }
}

#Preview {
    let schema = Schema([
        DrinkProfile.self,
        DrinkLog.self,
        UserSettings.self,
        UserProfile.self
    ])
    let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [configuration])

    return OnboardingView()
        .modelContainer(container)
}
