//
//  SettingsView.swift
//  QuitERGY
//
//  Created by Codex.
//

import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.openURL) private var openURL
    @StateObject private var viewModel: SettingsViewModel
    @State private var isPresentingResetAlert = false
    @State private var isPresentingOnboardingResetAlert = false
    @State private var isPresentingProfileForm = false
    @State private var isEditingReminderTime = false
    @State private var hasInitializedReminder = false
    @State private var isPresentingPaywall = false

    private let supportEmail = "support@quitergy.app"
    private let legalDocuments: [LegalDocument] = [
        LegalDocument(
            title: "Terms of Use",
            systemImage: "doc.text.fill",
            fileName: "terms of use"
        ),
        LegalDocument(
            title: "Privacy Policy",
            systemImage: "hand.raised.fill",
            fileName: "privacy policy"
        ),
        LegalDocument(
            title: "Imprint",
            systemImage: "info.circle.fill",
            fileName: "legal notice"
        ),
    ]

    private var appVersion: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        return version
    }

    init(
        service: DrinkPersistenceProviding,
        reminderScheduler: ReminderScheduling = ReminderScheduler()
    ) {
        _viewModel = StateObject(
            wrappedValue: SettingsViewModel(service: service, reminderScheduler: reminderScheduler))
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    premiumBanner
                        .listRowInsets(EdgeInsets(top: 12, leading: 0, bottom: 12, trailing: 0))
                        .listRowBackground(Color.clear)
                }
                .listRowBackground(Color.clear)

                Section {
                    heroCard
                        .listRowInsets(EdgeInsets(top: 12, leading: 0, bottom: 16, trailing: 0))
                        .listRowBackground(Color.clear)
                }
                .listRowBackground(Color.clear)

                Section("Drink Profiles") {
                    if viewModel.profiles.isEmpty {
                        Text("No profiles yet. Create one to keep track of your stats.")
                            .font(.quitRounded(.medium, size: 14))
                            .foregroundStyle(QuitERGYTheme.textSecondary)
                            .padding(.vertical, 4)
                    } else {
                        ForEach(viewModel.profiles) { profile in
                            ProfileRow(
                                profile: profile,
                                isSelected: profile.id == viewModel.selectedProfile?.id
                            ) {
                                viewModel.selectProfile(profile)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    viewModel.deleteProfile(profile)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }

                    Button {
                        // Check if user can create more profiles
                        #if DEBUG
                        viewModel.prepareNewProfile()
                        isPresentingProfileForm = true
                        #else
                        if !PurchaseManager.shared.isPremiumUnlocked && viewModel.profiles.count >= 1 {
                            isPresentingPaywall = true
                        } else {
                            viewModel.prepareNewProfile()
                            isPresentingProfileForm = true
                        }
                        #endif
                    } label: {
                        HStack {
                            Label("Save New Profile", systemImage: "plus.circle.fill")
                                .font(.quitRounded(.semibold, size: 16))
                            #if !DEBUG
                            if !PurchaseManager.shared.isPremiumUnlocked && viewModel.profiles.count >= 1 {
                                Spacer()
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .padding(4)
                                    .background(Circle().fill(.red))
                            }
                            #endif
                        }
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(QuitERGYTheme.accent)
                    .padding(.top, 8)
                }
                .listRowBackground(QuitERGYTheme.surface)

                Section("Daily Reminder") {
                    #if DEBUG
                    Toggle(isOn: $viewModel.reminderEnabled) {
                        Label("Ask me once per day", systemImage: "alarm.fill")
                    }
                    .onChange(of: viewModel.reminderEnabled, initial: false) { oldValue, newValue in
                        guard hasInitializedReminder else { return }
                        guard oldValue != newValue else { return }
                        
                        if !newValue {
                            withAnimation {
                                isEditingReminderTime = false
                            }
                        }
                        
                        // Handle permission request asynchronously without blocking UI
                        Task {
                            await viewModel.handleReminderToggle(newValue)
                        }
                    }
                    #else
                    if PurchaseManager.shared.isPremiumUnlocked {
                        Toggle(isOn: $viewModel.reminderEnabled) {
                            Label("Ask me once per day", systemImage: "alarm.fill")
                        }
                        .onChange(of: viewModel.reminderEnabled, initial: false) { oldValue, newValue in
                            guard hasInitializedReminder else { return }
                            guard oldValue != newValue else { return }
                            
                            if !newValue {
                                withAnimation {
                                    isEditingReminderTime = false
                                }
                            }
                            
                            // Handle permission request asynchronously without blocking UI
                            Task {
                                await viewModel.handleReminderToggle(newValue)
                            }
                        }
                    } else {
                        Button {
                            isPresentingPaywall = true
                        } label: {
                            HStack {
                                Label("Ask me once per day", systemImage: "alarm.fill")
                                    .foregroundStyle(QuitERGYTheme.textPrimary)
                                Spacer()
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .padding(4)
                                    .background(Circle().fill(.red))
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    #endif

                    if viewModel.reminderEnabled {
                        DisclosureGroup(isExpanded: $isEditingReminderTime) {
                            DatePicker(
                                "",
                                selection: $viewModel.reminderTime,
                                displayedComponents: .hourAndMinute
                            )
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                            .onChange(of: viewModel.reminderTime) { _, newValue in
                                viewModel.updateReminderTime(newValue)
                            }
                            .padding(.vertical, 4)

                            HStack {
                                Spacer()
                                Button {
                                    viewModel.confirmReminderSelection()
                                    withAnimation {
                                        isEditingReminderTime = false
                                    }
                                } label: {
                                    Text("OK")
                                        .font(.quitRounded(.semibold, size: 14))
                                        .foregroundStyle(QuitERGYTheme.textPrimary)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(QuitERGYTheme.accent.opacity(0.2))
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        } label: {
                            HStack {
                                Text("Reminder Time")
                                Spacer()
                                Text(reminderTimeLabel)
                                    .font(.quitRounded(.medium, size: 14))
                                    .foregroundStyle(QuitERGYTheme.textSecondary)
                            }
                        }
                    }

                    if let status = viewModel.reminderStatusMessage {
                        Text(status)
                            .font(.quitRounded(.medium, size: 12))
                            .foregroundStyle(QuitERGYTheme.textSecondary)
                            .padding(.top, 4)
                    }
                }
                .listRowBackground(QuitERGYTheme.surface)

                Section("Current Profile") {
                    if let profile = viewModel.selectedProfile {
                        CurrentProfileSummary(profile: profile)
                            .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 12, trailing: 0))
                            .listRowBackground(Color.clear)
                    } else {
                        Text("Pick a profile to let us calculate your progress.")
                            .font(.quitRounded(.medium, size: 14))
                            .foregroundStyle(QuitERGYTheme.textSecondary)
                    }
                }
                .listRowBackground(QuitERGYTheme.surface)

                Section("Support") {
                    Button(action: contactSupport) {
                        SettingRow(
                            icon: "paperplane.fill",
                            title: "Contact Support",
                            subtitle: "We usually reply within 24h",
                            iconColor: QuitERGYTheme.accent
                        )
                    }
                    .buttonStyle(.plain)

                    Button(role: .destructive) {
                        isPresentingResetAlert = true
                    } label: {
                        SettingRow(
                            icon: "arrow.counterclockwise",
                            title: "Reset Progress",
                            subtitle: "Clear streak data and start fresh",
                            iconColor: Color.red
                        )
                        .foregroundStyle(Color.red)
                    }

                    Button {
                        isPresentingOnboardingResetAlert = true
                    } label: {
                        SettingRow(
                            icon: "sparkles",
                            title: "Reset Onboarding",
                            subtitle: "Run the intro again next launch",
                            iconColor: QuitERGYTheme.accent
                        )
                    }
                    .buttonStyle(.plain)

                    if let generalStatus = viewModel.generalStatusMessage {
                        Text(generalStatus)
                            .font(.quitRounded(.medium, size: 12))
                            .foregroundStyle(QuitERGYTheme.textSecondary)
                            .padding(.top, 6)
                    }
                }
                .listRowBackground(QuitERGYTheme.surface)

                Section("Legal") {
                    ForEach(legalDocuments) { document in
                        NavigationLink(value: document) {
                            SettingRow(
                                icon: document.systemImage,
                                title: document.title,
                                subtitle: "Read the fine print"
                            )
                        }
                    }
                }
                .listRowBackground(QuitERGYTheme.surface)

                Section {
                    versionFooter
                        .listRowBackground(Color.clear)
                }
                .listRowBackground(Color.clear)
            }
            .scrollContentBackground(.hidden)
            .listStyle(.insetGrouped)
            .background(QuitERGYTheme.background)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: LegalDocument.self) { document in
                LegalDocumentView(document: document)
            }
            .alert("Reset all progress?", isPresented: $isPresentingResetAlert) {
                Button("Reset", role: .destructive) {}
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will clear your streak and statistics. This action cannot be undone.")
            }
            .alert("Reset onboarding?", isPresented: $isPresentingOnboardingResetAlert) {
                Button("Reset", role: .destructive) {
                    viewModel.resetOnboardingFlow()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("The onboarding will start again the next time you open the app.")
            }
            .alert("Hinweis", isPresented: errorAlertBinding) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .sheet(isPresented: $isPresentingProfileForm) {
                ProfileFormView(isPresented: $isPresentingProfileForm, viewModel: viewModel)
            }
            .sheet(isPresented: $isPresentingPaywall) {
                PaywallView()
                    .environmentObject(PurchaseManager.shared)
            }
            .task {
                viewModel.loadData()
                hasInitializedReminder = true
                isEditingReminderTime = false
            }
        }
        .onAppear {
            hasInitializedReminder = false
            isEditingReminderTime = false
        }
    }

    private var premiumBanner: some View {
        Button {
            isPresentingPaywall = true
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(QuitERGYTheme.accent.opacity(0.18))
                        .frame(width: 56, height: 56)
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(QuitERGYTheme.accent)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Unlock Premium")
                        .font(.quitRounded(.semibold, size: 18))
                        .foregroundStyle(QuitERGYTheme.textPrimary)
                    Text("Track unlimited streaks, insights & more")
                        .font(.quitRounded(.medium, size: 14))
                        .foregroundStyle(QuitERGYTheme.textSecondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(QuitERGYTheme.textSecondary.opacity(0.6))
            }
            .padding(18)
            .cardBackground()
        }
        .buttonStyle(.plain)
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label {
                Text("Stay ⚡️ Focused")
                    .font(.quitRounded(.semibold, size: 22))
                    .foregroundStyle(QuitERGYTheme.textPrimary)
            } icon: {
                Image(systemName: "bolt.heart.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(QuitERGYTheme.accent)
            }

            Text("Track your clean streak, celebrate milestones, and keep your energy steady.")
                .font(.quitRounded(.medium, size: 16))
                .foregroundStyle(QuitERGYTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

        }
        .padding(20)
        .cardBackground()
    }

    private var versionFooter: some View {
        VStack(spacing: 6) {
            Text("QuitERGY Version \(appVersion)")
                .font(.quitRounded(.medium, size: 14))
                .foregroundStyle(QuitERGYTheme.textSecondary)
            Text("Crafted to keep your energy clean and steady.")
                .font(.quitRounded(.medium, size: 13))
                .foregroundStyle(QuitERGYTheme.textSecondary.opacity(0.9))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 12)
    }

    private var errorAlertBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )
    }

    private func contactSupport() {
        guard let url = URL(string: "mailto:\(supportEmail)") else { return }
        openURL(url)
    }

    private var reminderTimeLabel: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: viewModel.reminderTime)
    }
}

private struct ProfileFormView: View {
    @Binding var isPresented: Bool
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        NavigationStack {
            Form {
                if !SettingsViewModel.commonDrinkPresets.isEmpty {
                    Section("Preset") {
                        Menu {
                            ForEach(SettingsViewModel.commonDrinkPresets) { preset in
                                Button(preset.displayName) {
                                    viewModel.selectPreset(preset)
                                }
                            }
                        } label: {
                            HStack {
                                Text("Energy Drink")
                                Spacer()
                                Text(viewModel.selectedPreset?.displayName ?? "Choose")
                                    .foregroundStyle(QuitERGYTheme.textSecondary)
                            }
                        }
                    }
                }

                Section("Details") {
                    TextField("Name", text: $viewModel.nameInput)
                    TextField("Brand", text: $viewModel.brandInput)
                }

                Section("Variant") {
                    Picker("Variant", selection: $viewModel.variant) {
                        ForEach(DrinkVariant.allCases) { variant in
                            Text(variant.displayName).tag(variant)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("Nutrition") {
                    TextField("Sugar (g)", text: $viewModel.sugarInput)
                        .keyboardType(.decimalPad)
                    TextField("Caffeine (mg)", text: $viewModel.caffeineInput)
                        .keyboardType(.decimalPad)
                    TextField("Price (€)", text: $viewModel.priceInput)
                        .keyboardType(.decimalPad)
                }
            }
            .scrollContentBackground(.hidden)
            .background(QuitERGYTheme.background)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if viewModel.saveProfile() {
                            isPresented = false
                        }
                    }
                    .disabled(viewModel.nameInput.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .navigationTitle("Create Profile")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.fraction(0.75), .large])
        .presentationDragIndicator(.visible)
    }
}

private struct ProfileRow: View {
    let profile: DrinkProfile
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 14) {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(
                        isSelected ? QuitERGYTheme.accent : QuitERGYTheme.textSecondary)
                VStack(alignment: .leading, spacing: 4) {
                    Text(profile.name)
                        .font(.quitRounded(.semibold, size: 16))
                        .foregroundStyle(QuitERGYTheme.textPrimary)
                    if let brand = profile.brand, !brand.isEmpty {
                        Text(brand)
                            .font(.quitRounded(.medium, size: 13))
                            .foregroundStyle(QuitERGYTheme.textSecondary)
                    }
                    Text(profile.variant.displayName)
                        .font(.quitRounded(.medium, size: 12))
                        .foregroundStyle(QuitERGYTheme.textSecondary.opacity(0.8))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(QuitERGYTheme.textSecondary.opacity(0.7))
            }
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }
}

private struct CurrentProfileSummary: View {
    let profile: DrinkProfile

    private var priceString: String {
        let number = NSDecimalNumber(decimal: profile.price)
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: number) ?? "–"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(profile.name)
                .font(.quitRounded(.semibold, size: 18))
                .foregroundStyle(QuitERGYTheme.textPrimary)

            if let brand = profile.brand, !brand.isEmpty {
                Text(brand)
                    .font(.quitRounded(.medium, size: 14))
                    .foregroundStyle(QuitERGYTheme.textSecondary)
            }

            HStack(spacing: 16) {
                metricTile(title: "Sugar", value: "\(format(profile.sugarGrams))g")
                metricTile(title: "Caffeine", value: "\(format(profile.caffeineMg))mg")
                metricTile(title: "Price", value: priceString)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(18)
        .cardBackground()
        .neonGlow(color: QuitERGYTheme.accent.opacity(0.35), lineWidth: 0.7)
    }

    private func format(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }

    private func metricTile(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.quitRounded(.medium, size: 11))
                .foregroundStyle(QuitERGYTheme.textSecondary.opacity(0.8))
            Text(value)
                .font(.quitRounded(.semibold, size: 15))
                .foregroundStyle(QuitERGYTheme.textPrimary)
        }
    }
}

private struct SettingRow: View {
    var icon: String
    var title: String
    var subtitle: String?
    var trailingText: String? = nil
    var iconColor: Color = QuitERGYTheme.accent

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(iconColor)
                .frame(width: 44, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(iconColor.opacity(0.18))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.quitRounded(.semibold, size: 16))
                    .foregroundStyle(QuitERGYTheme.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(.quitRounded(.medium, size: 13))
                        .foregroundStyle(QuitERGYTheme.textSecondary)
                }
            }

            Spacer()

            if let trailingText {
                Text(trailingText)
                    .font(.quitRounded(.medium, size: 13))
                    .foregroundStyle(QuitERGYTheme.textSecondary)
            }
        }
        .padding(.vertical, 6)
    }
}

private struct LegalDocument: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let systemImage: String
    let fileName: String
}

private struct LegalDocumentView: View {
    let document: LegalDocument
    @State private var content: String = ""
    @State private var isLoading: Bool = true

    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
            } else {
                Text(content)
                    .font(.quitRounded(.medium, size: 15))
                    .foregroundStyle(QuitERGYTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(24)
            }
        }
        .background(QuitERGYTheme.background.ignoresSafeArea())
        .navigationTitle(document.title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadContent()
        }
    }
    
    private func loadContent() async {
        guard let fileURL = Bundle.main.url(forResource: document.fileName, withExtension: "txt") else {
            content = "Error: File not found (\(document.fileName).txt)"
            isLoading = false
            return
        }
        
        do {
            content = try String(contentsOf: fileURL, encoding: .utf8)
        } catch {
            content = "Error loading file: \(error.localizedDescription)"
        }
        isLoading = false
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
    let service = DrinkPersistenceService(modelContext: container.mainContext)

    let sample = DrinkProfile(
        name: "Noctra Energy",
        brand: "Velocity Labs",
        variant: .sugarFree,
        sugarGrams: 0,
        caffeineMg: 180,
        price: Decimal(string: "2.49") ?? 2.49
    )
    container.mainContext.insert(sample)
    try? service.selectProfile(sample)
    try? container.mainContext.save()

    struct PreviewReminderScheduler: ReminderScheduling {
        func ensureAuthorization() async throws {}
        func scheduleDailyReminder(at time: Date, profileName: String?) async throws {}
        func cancelScheduledReminder() {}
    }

    return SettingsView(service: service, reminderScheduler: PreviewReminderScheduler())
        .environment(\.drinkPersistence, service)
        .modelContainer(container)
}
