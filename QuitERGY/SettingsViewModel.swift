//
//  SettingsViewModel.swift
//  QuitERGY
//
//  Created by Codex.
//

import Foundation
import Combine

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var profiles: [DrinkProfile] = []
    @Published var selectedProfile: DrinkProfile?

    @Published var nameInput: String = ""
    @Published var brandInput: String = ""
    @Published var variant: DrinkVariant = .classic
    @Published var sugarInput: String = ""
    @Published var caffeineInput: String = ""
    @Published var priceInput: String = ""

    @Published var reminderEnabled: Bool = false
    @Published var reminderTime: Date
    @Published var reminderStatusMessage: String?

    @Published var errorMessage: String?

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
        nameInput = ""
        brandInput = ""
        variant = .classic
        sugarInput = ""
        caffeineInput = ""
        priceInput = ""
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
        Task {
            await persistReminderConfiguration()
        }
    }

    func updateReminderTime(_ time: Date) {
        reminderTime = time
        if reminderEnabled {
            Task {
                await persistReminderConfiguration()
            }
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
