//
//  SettingsView.swift
//  QuitERGY
//
//  Created by Codex.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.openURL) private var openURL
    @StateObject private var viewModel: SettingsViewModel
    @State private var isPresentingResetAlert = false
    @State private var isPresentingProfileForm = false

    private let supportEmail = "support@quitergy.app"
    private let legalDocuments: [LegalDocument] = [
        LegalDocument(
            title: "Terms of Use",
            systemImage: "doc.text.fill",
            body: "QuitERGY is designed to support your journey away from energy drinks. Review our Terms of Use to understand how we handle your data and what you can expect from the app."
        ),
        LegalDocument(
            title: "Privacy Policy",
            systemImage: "hand.raised.fill",
            body: "We respect your privacy. This placeholder policy explains which information we collect, how we process it, and how you remain in control of your data."
        ),
        LegalDocument(
            title: "Imprint",
            systemImage: "info.circle.fill",
            body: "QuitERGY ⚡️\n\nThis is placeholder content for your legal imprint. Replace it with the official business address, registration details, and contact information."
        )
    ]

    private var appVersion: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        if let build = info?["CFBundleVersion"] as? String {
            return "\(version) (\(build))"
        }
        return version
    }

    init(service: DrinkPersistenceProviding) {
        _viewModel = StateObject(wrappedValue: SettingsViewModel(service: service))
    }

    var body: some View {
        NavigationStack {
            List {
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
                            ProfileRow(profile: profile, isSelected: profile.id == viewModel.selectedProfile?.id) {
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
                        viewModel.prepareNewProfile()
                        isPresentingProfileForm = true
                    } label: {
                        Label("Save New Profile", systemImage: "plus.circle.fill")
                            .font(.quitRounded(.semibold, size: 16))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(QuitERGYTheme.accent)
                    .padding(.top, 8)
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
                Button("Reset", role: .destructive) { }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will clear your streak and statistics. This action cannot be undone.")
            }
            .alert("Hinweis", isPresented: errorAlertBinding) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .sheet(isPresented: $isPresentingProfileForm) {
                ProfileFormView(isPresented: $isPresentingProfileForm, viewModel: viewModel)
            }
            .task {
                viewModel.loadData()
            }
        }
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
        .neonGlow(color: QuitERGYTheme.accent.opacity(0.45), lineWidth: 0.8)
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
}

private struct ProfileFormView: View {
    @Binding var isPresented: Bool
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        NavigationStack {
            Form {
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
                    .foregroundStyle(isSelected ? QuitERGYTheme.accent : QuitERGYTheme.textSecondary)
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
    let body: String
}

private struct LegalDocumentView: View {
    let document: LegalDocument

    var body: some View {
        ScrollView {
            Text(document.body)
                .font(.quitRounded(.medium, size: 15))
                .foregroundStyle(QuitERGYTheme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(24)
        }
        .background(QuitERGYTheme.background.ignoresSafeArea())
        .navigationTitle(document.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    let schema = Schema([
        DrinkProfile.self,
        DrinkLog.self,
        UserSettings.self
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

    return SettingsView(service: service)
        .environment(\.drinkPersistence, service)
        .modelContainer(container)
}
