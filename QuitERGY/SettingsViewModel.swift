//
//  SettingsViewModel.swift
//  QuitERGY
//
//  Created by Codex.
//

import Foundation
import Combine

struct DrinkPreset: Identifiable, Hashable {
    let id: String
    let displayName: String
    let brand: String?
    let variant: DrinkVariant
    let sugarGrams: Double
    let caffeineMg: Double
    let price: Decimal

    init(
        displayName: String,
        brand: String? = nil,
        variant: DrinkVariant,
        sugarGrams: Double,
        caffeineMg: Double,
        price: Decimal,
        id: String? = nil
    ) {
        self.displayName = displayName
        self.brand = brand
        self.variant = variant
        self.sugarGrams = sugarGrams
        self.caffeineMg = caffeineMg
        self.price = price
        self.id = id ?? "\(displayName)-\(variant.rawValue)"
    }
}

@MainActor
final class SettingsViewModel: ObservableObject {
    static let commonDrinkPresets: [DrinkPreset] = [
        DrinkPreset(
            displayName: "Red Bull 250ml",
            brand: "Red Bull GmbH",
            variant: .classic,
            sugarGrams: 27,
            caffeineMg: 80,
            price: Decimal(string: "1.59") ?? 0
        ),
        DrinkPreset(
            displayName: "Red Bull Sugarfree 250ml",
            brand: "Red Bull GmbH",
            variant: .sugarFree,
            sugarGrams: 0,
            caffeineMg: 80,
            price: Decimal(string: "1.59") ?? 0
        ),
        DrinkPreset(
            displayName: "Monster Energy 500ml",
            brand: "Monster Beverage",
            variant: .classic,
            sugarGrams: 54,
            caffeineMg: 160,
            price: Decimal(string: "1.99") ?? 0
        ),
        DrinkPreset(
            displayName: "Monster Ultra 500ml",
            brand: "Monster Beverage",
            variant: .zero,
            sugarGrams: 0,
            caffeineMg: 150,
            price: Decimal(string: "1.99") ?? 0
        ),
        DrinkPreset(
            displayName: "Rockstar Original 500ml",
            brand: "Rockstar Energy",
            variant: .classic,
            sugarGrams: 63,
            caffeineMg: 160,
            price: Decimal(string: "1.89") ?? 0
        ),
        DrinkPreset(
            displayName: "Celsius 355ml",
            brand: "Celsius Holdings",
            variant: .zero,
            sugarGrams: 0,
            caffeineMg: 200,
            price: Decimal(string: "2.29") ?? 0
        ),
        DrinkPreset(
            displayName: "Bang 473ml",
            brand: "Vital Pharmaceuticals",
            variant: .highCaffeine,
            sugarGrams: 0,
            caffeineMg: 300,
            price: Decimal(string: "2.49") ?? 0
        )
    ]

    @Published var profiles: [DrinkProfile] = []
    @Published var selectedProfile: DrinkProfile?

    @Published var nameInput: String = ""
    @Published var brandInput: String = ""
    @Published var variant: DrinkVariant = .classic
    @Published var sugarInput: String = ""
    @Published var caffeineInput: String = ""
    @Published var priceInput: String = ""
    @Published var selectedPreset: DrinkPreset?

    @Published var reminderEnabled: Bool = false
    @Published var reminderTime: Date
    @Published var reminderStatusMessage: String?

    @Published var errorMessage: String?
    @Published var generalStatusMessage: String?

    private let persistence: DrinkPersistenceProviding
    private let reminderScheduler: ReminderScheduling
    private let calendar: Calendar
    private let defaultReminderTime: Date

    init(service: DrinkPersistenceProviding, reminderScheduler: ReminderScheduling, calendar: Calendar = .current) {
        self.persistence = service
        self.reminderScheduler = reminderScheduler
        self.calendar = calendar
        self.defaultReminderTime = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
        self.reminderTime = defaultReminderTime
        if let preset = SettingsViewModel.commonDrinkPresets.first {
            applyPreset(preset)
            selectedPreset = preset
        }
    }

    func loadData() {
        do {
            profiles = try persistence.loadProfiles()
            selectedProfile = try persistence.loadSelectedProfile()
            let reminder = try persistence.loadReminderConfiguration()
            reminderEnabled = reminder.isEnabled
            reminderTime = reminder.reminderTime ?? defaultReminderTime
            reminderStatusMessage = reminder.isEnabled
                ? "Daily reminder scheduled at \(formattedTime(reminderTime))."
                : nil
            generalStatusMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func selectProfile(_ profile: DrinkProfile) {
        do {
            try persistence.selectProfile(profile)
            selectedProfile = profile
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteProfile(_ profile: DrinkProfile) {
        do {
            try persistence.deleteProfile(profile)
            loadData()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteProfiles(at offsets: IndexSet) {
        for index in offsets {
            let profile = profiles[index]
            deleteProfile(profile)
        }
    }

    func prepareNewProfile() {
        if let preset = SettingsViewModel.commonDrinkPresets.first {
            applyPreset(preset)
            selectedPreset = preset
        } else {
            nameInput = ""
            brandInput = ""
            variant = .classic
            sugarInput = ""
            caffeineInput = ""
            priceInput = ""
            selectedPreset = nil
        }
        errorMessage = nil
    }

    @discardableResult
    func saveProfile() -> Bool {
        do {
            let input = try buildInput()
            let profile = try persistence.createProfile(input: input)
            try persistence.selectProfile(profile)
            loadData()
            prepareNewProfile()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func updateReminderEnabled(_ isEnabled: Bool) {
        guard reminderEnabled != isEnabled else { return }
        reminderEnabled = isEnabled
        
        if isEnabled {
            // Request notification permission immediately when toggle is enabled
            Task {
                await requestNotificationPermission()
            }
        } else {
            // Disable reminder immediately when toggle is off
            Task {
                await persistReminderConfiguration()
            }
        }
    }
    
    private func requestNotificationPermission() async {
        do {
            // Request permission first
            try await reminderScheduler.scheduleDailyReminder(at: reminderTime, profileName: selectedProfile?.name)
            reminderStatusMessage = "Daily reminder scheduled at \(formattedTime(reminderTime))."
            
            // Save configuration
            let config = ReminderConfiguration(
                isEnabled: true,
                reminderTime: reminderTime
            )
            try persistence.updateReminderConfiguration(config)
        } catch {
            // If permission denied or error, revert toggle
            reminderScheduler.cancelScheduledReminder()
            reminderEnabled = false
            reminderStatusMessage = nil
            if (try? persistence.updateReminderConfiguration(ReminderConfiguration(isEnabled: false, reminderTime: nil))) == nil {
                // ignore persistence failure
            }
            errorMessage = error.localizedDescription
        }
    }

    func selectPreset(_ preset: DrinkPreset) {
        selectedPreset = preset
        applyPreset(preset)
    }

    func updateReminderTime(_ time: Date) {
        reminderTime = time
        if reminderEnabled {
            // Update the scheduled reminder with new time
            Task {
                await updateScheduledReminder()
            }
        }
    }

    func confirmReminderSelection() {
        // Just close the time picker, reminder is already scheduled
        if reminderEnabled {
            reminderStatusMessage = "Daily reminder scheduled at \(formattedTime(reminderTime))."
        }
    }
    
    private func updateScheduledReminder() async {
        guard reminderEnabled else { return }
        
        do {
            // Update the scheduled reminder with new time
            try await reminderScheduler.scheduleDailyReminder(at: reminderTime, profileName: selectedProfile?.name)
            reminderStatusMessage = "Daily reminder scheduled at \(formattedTime(reminderTime))."
            
            // Save configuration
            let config = ReminderConfiguration(
                isEnabled: true,
                reminderTime: reminderTime
            )
            try persistence.updateReminderConfiguration(config)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func resetOnboardingFlow() {
        do {
            try persistence.updateOnboardingCompletion(to: false)
            generalStatusMessage = "Onboarding reset. The intro will run again on the next launch."
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func persistReminderConfiguration() async {
        let config = ReminderConfiguration(
            isEnabled: reminderEnabled,
            reminderTime: reminderEnabled ? reminderTime : nil
        )

        do {
            if reminderEnabled {
                try await reminderScheduler.scheduleDailyReminder(at: reminderTime, profileName: selectedProfile?.name)
                reminderStatusMessage = "Daily reminder scheduled at \(formattedTime(reminderTime))."
            } else {
                reminderScheduler.cancelScheduledReminder()
                reminderStatusMessage = "Daily reminder disabled."
            }
            try persistence.updateReminderConfiguration(config)
        } catch {
            reminderScheduler.cancelScheduledReminder()
            reminderEnabled = false
            reminderStatusMessage = nil
            if (try? persistence.updateReminderConfiguration(ReminderConfiguration(isEnabled: false, reminderTime: nil))) == nil {
                // ignore persistence failure and surface original error below
            }
            errorMessage = error.localizedDescription
        }
    }

    private func buildInput() throws -> DrinkProfileInput {
        let trimmedName = nameInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw ValidationError(message: "Please enter a name for the profile.")
        }

        let sugar = try parseDouble(from: sugarInput, label: "Sugar (g)")
        let caffeine = try parseDouble(from: caffeineInput, label: "Caffeine (mg)")
        let price = try parseDecimal(from: priceInput, label: "Price (€)")

        guard sugar >= 0, caffeine >= 0, price >= 0 else {
            throw ValidationError(message: "Negative values are not allowed.")
        }

        let brandTrimmed = brandInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let brand = brandTrimmed.isEmpty ? nil : brandTrimmed

        return DrinkProfileInput(
            name: trimmedName,
            brand: brand,
            variant: variant,
            sugarGrams: sugar,
            caffeineMg: caffeine,
            price: price
        )
    }

    private func parseDouble(from value: String, label: String) throws -> Double {
        let sanitized = value.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespaces)
        guard !sanitized.isEmpty else { return 0 }
        guard let number = Double(sanitized) else {
            throw ValidationError(message: "\(label) must be a number.")
        }
        return number
    }

    private func parseDecimal(from value: String, label: String) throws -> Decimal {
        let sanitized = value.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespaces)
        guard !sanitized.isEmpty else { return 0 }
        guard let decimal = Decimal(string: sanitized, locale: Locale.current) ??
            Decimal(string: sanitized)
        else {
            throw ValidationError(message: "\(label) must be a valid number.")
        }
        return decimal
    }

    private func applyPreset(_ preset: DrinkPreset) {
        nameInput = preset.displayName
        brandInput = preset.brand ?? ""
        variant = preset.variant
        sugarInput = formattedNumber(preset.sugarGrams)
        caffeineInput = formattedNumber(preset.caffeineMg)
        priceInput = formattedDecimal(preset.price)
    }

    private func formattedNumber(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(Int(value))
        }
        return String(format: "%.2f", value)
    }

    private func formattedDecimal(_ value: Decimal) -> String {
        NSDecimalNumber(decimal: value).stringValue
    }

    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

private struct ValidationError: LocalizedError {
    let message: String

    var errorDescription: String? { message }
}
