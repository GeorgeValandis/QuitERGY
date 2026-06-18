//
//  OnboardingView.swift
//  QuitERGY
//
//  Created by Codex.
//

import SwiftData
import SwiftUI

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.drinkPersistence) private var persistence
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let onCompleted: () -> Void

    @State var workflow = Workflow()
    @State var form = OnboardingForm()
    @State var showsCompositionEditor = false
    @State private var showValidationHint = false
    @State private var errorMessage: String?
    @State private var headerHeight: CGFloat = 0
    @State private var footerHeight: CGFloat = 0
    @State private var didCompleteOnboarding = false
    @State private var didTrackFirstLogPromptView = false
    @State private var viewedOnboardingStepIDs: Set<String> = []
    @FocusState var focusedField: FocusField?

    init(onCompleted: @escaping () -> Void = {}) {
        self.onCompleted = onCompleted
    }

    var body: some View {
        ZStack {
            onboardingBackground
            if horizontalSizeClass == .regular {
                GeometryReader { proxy in
                    let isTightHeight = proxy.size.height < 900
                    let sectionSpacing: CGFloat = isTightHeight ? 20 : 28
                    let outerTopPadding: CGFloat = isTightHeight ? 20 : 36
                    let outerBottomPadding: CGFloat = isTightHeight ? 16 : 30
                    let scrollPadding: CGFloat = isTightHeight ? 16 : 24
                    let scrollInsetExtra: CGFloat = isTightHeight ? 8 : 16

                    ZStack {
                        ScrollView {
                            VStack(spacing: sectionSpacing) {
                                stepCard

                                if showValidationHint, let message = validationMessage {
                                    Text(message)
                                        .font(.quitRounded(.medium, size: 14))
                                        .foregroundStyle(Color.red.opacity(0.85))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .transition(.opacity)
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, scrollPadding)
                            .frame(maxWidth: .infinity, alignment: .top)
                        }
                        .padding(.top, headerHeight + scrollInsetExtra)
                        .padding(.bottom, footerHeight + scrollInsetExtra)

                        VStack(spacing: sectionSpacing) {
                            headerSection
                                .background(
                                    GeometryReader { overlayProxy in
                                        Color.clear.preference(
                                            key: HeaderHeightKey.self,
                                            value: overlayProxy.size.height
                                        )
                                    }
                                )
                                .onPreferenceChange(HeaderHeightKey.self) { value in
                                    headerHeight = value
                                }

                            Spacer(minLength: 0)

                            footerControls
                                .background(
                                    GeometryReader { overlayProxy in
                                        Color.clear.preference(
                                            key: FooterHeightKey.self,
                                            value: overlayProxy.size.height
                                        )
                                    }
                                )
                                .onPreferenceChange(FooterHeightKey.self) { value in
                                    footerHeight = value
                                }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, outerTopPadding)
                        .padding(.bottom, outerBottomPadding)
                    }
                    .frame(width: proxy.size.width, height: proxy.size.height, alignment: .top)
                    .overlay(alignment: .topLeading) {
                        #if DEBUG
                            if ProcessInfo.processInfo.environment["SHOW_ONBOARDING_LAYOUT_DEBUG"]
                                == "1"
                            {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("h: \(Int(proxy.size.height)) w: \(Int(proxy.size.width))")
                                    Text(
                                        "header: \(Int(headerHeight)) footer: \(Int(footerHeight))")
                                    Text(
                                        "sizeClass: \(horizontalSizeClass == .regular ? "regular" : "compact")"
                                    )
                                    Text("tight: \(isTightHeight ? "yes" : "no")")
                                }
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.white)
                                .padding(8)
                                .background(Color.black.opacity(0.65))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .padding(.top, 8)
                                .padding(.leading, 8)
                            }
                        #endif
                    }
                }
            } else {
                compactContent
            }
        }
        .onAppear {
            applyDefaults(for: form.drinkType)
        }
        .onChange(of: workflow.currentStep) { _, _ in
            showValidationHint = false
            focusedField = nil
        }
        .task(id: workflow.currentStep) {
            trackOnboardingStepViewedIfNeeded()
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
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "We couldn’t save your onboarding data. Please try again.")
        }
        .onDisappear {
            trackOnboardingAbandonedIfNeeded()
        }
    }

    private var compactContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection

                stepCard

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
            .padding(.top, 28)
            .padding(.bottom, 30)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .scrollIndicators(.hidden)
    }

    private var stepCard: some View {
        StepDetailView(
            indicator: stepIndicatorText,
            title: stepTitle,
            subtitle: stepSubtitle
        ) {
            stepContent()
        }
        .animation(.easeInOut(duration: 0.3), value: workflow.currentStep)
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
                    AppAnalytics.shared.track(
                        "onboarding_back_tapped", properties: onboardingStepProperties())
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
            AppAnalytics.shared.track(
                "onboarding_validation_failed", properties: onboardingStepProperties())
            withAnimation(.easeInOut(duration: 0.3)) {
                showValidationHint = true
            }
            return
        }

        showValidationHint = false

        if workflow.isOnSummary {
            completeOnboarding()
        } else {
            AppAnalytics.shared.track(
                "onboarding_next_tapped", properties: onboardingStepProperties())
            withAnimation(.easeInOut(duration: 0.35)) {
                workflow.advance()
            }
        }
    }

    private func completeOnboarding() {
        do {
            let drinkProfile = try persistProfile()
            try recordFirstLogIfNeeded(for: drinkProfile)
            didCompleteOnboarding = true
            AppAnalytics.shared.track(
                "onboarding_completed", properties: onboardingCompletionProperties())
            onCompleted()
        } catch {
            AppAnalytics.shared.track(
                "onboarding_save_failed", properties: onboardingStepProperties())
            errorMessage = error.localizedDescription
        }
    }

    private func recordFirstLogIfNeeded(for drinkProfile: DrinkProfile) throws {
        guard let choice = form.firstLogChoice else { return }

        switch choice {
        case .drink:
            _ = try persistence.logDrink(drinkProfile, date: Date())
        case .noDrink:
            _ = try persistence.logNoDrink(drinkProfile, date: Date())
        }

        AppAnalytics.shared.track(
            "drink_log_recorded",
            properties: [
                "kind": choice.analyticsValue,
                "streak_days": "0",
                "surface": "onboarding",
            ])
    }

    private func trackOnboardingStepViewedIfNeeded() {
        let stepID = workflow.currentStep.analyticsName
        guard !viewedOnboardingStepIDs.contains(stepID) else { return }

        viewedOnboardingStepIDs.insert(stepID)
        AppAnalytics.shared.track("onboarding_step_viewed", properties: onboardingStepProperties())

        if workflow.currentStep == .summary {
            trackFirstLogPromptViewedIfNeeded()
        }
    }

    func selectFirstLogChoice(_ choice: FirstLogChoice) {
        form.firstLogChoice = choice

        var properties = onboardingStepProperties()
        properties["choice"] = choice.analyticsValue
        properties["surface"] = "onboarding_summary"
        AppAnalytics.shared.track("first_log_choice_selected", properties: properties)
    }

    private func trackFirstLogPromptViewedIfNeeded() {
        guard !didTrackFirstLogPromptView else { return }

        didTrackFirstLogPromptView = true
        var properties = onboardingStepProperties()
        properties["surface"] = "onboarding_summary"
        AppAnalytics.shared.track("first_log_prompt_viewed", properties: properties)
    }

    private func trackOnboardingAbandonedIfNeeded() {
        guard !didCompleteOnboarding else { return }

        AppAnalytics.shared.track("onboarding_abandoned", properties: onboardingStepProperties())
    }

    private func onboardingStepProperties() -> [String: String] {
        [
            "step": workflow.currentStep.analyticsName,
            "step_count": "\(OnboardingStep.allCases.count)",
            "step_id": workflow.currentStep.analyticsName,
            "step_index": "\(workflow.currentStep.rawValue)",
        ]
    }

    private func onboardingCompletionProperties() -> [String: String] {
        var properties = onboardingStepProperties()
        properties["baseline_frequency"] = form.baselineFrequency?.rawValue ?? "unknown"
        properties["drink_type"] = form.drinkType.rawValue
        properties["goal"] = form.goal.rawValue
        if let targetDrinksPerWeek = form.targetDrinksPerWeek {
            properties["target_drinks_per_week"] = "\(targetDrinksPerWeek)"
        }
        properties["first_log_choice"] = form.firstLogChoice?.analyticsValue ?? "none"
        return properties
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

    @discardableResult
    private func persistProfile() throws -> DrinkProfile {
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
        return drinkProfile
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

private struct HeaderHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private struct FooterHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

#Preview {
    let schema = Schema([
        DrinkProfile.self,
        DrinkLog.self,
        UserSettings.self,
        UserProfile.self,
    ])
    let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [configuration])

    return OnboardingView()
        .modelContainer(container)
}
