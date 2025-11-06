//
//  DrinkPersistenceService.swift
//  QuitERGY
//
//  Created by Codex.
//

import Foundation
import SwiftData

struct DrinkProfileInput {
    var name: String
    var brand: String?
    var variant: DrinkVariant
    var sugarGrams: Double
    var caffeineMg: Double
    var price: Decimal
}

struct ReminderConfiguration: Equatable {
    var isEnabled: Bool
    var reminderTime: Date?
}

enum DrinkPersistenceError: LocalizedError {
    case missingProfile
    case invalidDateRange
    case saveFailed
    case deleteFailed

    var errorDescription: String? {
        switch self {
        case .missingProfile:
            return "The selected drink profile could not be found."
        case .invalidDateRange:
            return "The requested date range is invalid."
        case .saveFailed:
            return "Changes could not be saved."
        case .deleteFailed:
            return "The profile could not be deleted."
        }
    }
}

@MainActor
protocol DrinkPersistenceProviding {
    func loadProfiles() throws -> [DrinkProfile]
    func createProfile(input: DrinkProfileInput) throws -> DrinkProfile
    func deleteProfile(_ profile: DrinkProfile) throws
    func selectProfile(_ profile: DrinkProfile?) throws
    func loadSelectedProfile() throws -> DrinkProfile?
    func loadUserProfile() throws -> UserProfile?
    func logDrink(_ profile: DrinkProfile, date: Date) throws -> DrinkLog
    func logNoDrink(_ profile: DrinkProfile, date: Date) throws -> DrinkLog
    func fetchRecentLogs(in interval: DateInterval) throws -> [DrinkLog]
    func loadReminderConfiguration() throws -> ReminderConfiguration
    func updateReminderConfiguration(_ configuration: ReminderConfiguration) throws
    func updateOnboardingCompletion(to value: Bool) throws
}

@MainActor
final class DrinkPersistenceService: DrinkPersistenceProviding {
    private let modelContext: ModelContext
    private let calendar = Calendar.current

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func loadProfiles() throws -> [DrinkProfile] {
        let descriptor = FetchDescriptor<DrinkProfile>(
            sortBy: [SortDescriptor(\DrinkProfile.name, order: .forward)]
        )
        return try modelContext.fetch(descriptor)
    }

    func createProfile(input: DrinkProfileInput) throws -> DrinkProfile {
        let profile = DrinkProfile(
            name: input.name,
            brand: input.brand,
            variant: input.variant,
            sugarGrams: input.sugarGrams,
            caffeineMg: input.caffeineMg,
            price: input.price
        )
        modelContext.insert(profile)
        try saveContext()
        return profile
    }

    func deleteProfile(_ profile: DrinkProfile) throws {
        if let settings = try fetchSettings(),
           settings.selectedProfile?.persistentModelID == profile.persistentModelID {
            settings.selectedProfile = nil
        }
        modelContext.delete(profile)
        try saveContext()
    }

    func selectProfile(_ profile: DrinkProfile?) throws {
        let settings = try fetchOrCreateSettings()
        settings.selectedProfile = profile
        try saveContext()
    }

    func loadSelectedProfile() throws -> DrinkProfile? {
        try fetchSettings()?.selectedProfile
    }

    func loadUserProfile() throws -> UserProfile? {
        try fetchSettings()?.userProfile
    }

    func logDrink(_ profile: DrinkProfile, date: Date) throws -> DrinkLog {
        guard let managedProfile = modelContext.model(for: profile.persistentModelID) as? DrinkProfile else {
            throw DrinkPersistenceError.missingProfile
        }

        let log = DrinkLog(timestamp: date, profile: managedProfile, isNoDrink: false)
        modelContext.insert(log)
        try saveContext()
        return log
    }
    
    func logNoDrink(_ profile: DrinkProfile, date: Date) throws -> DrinkLog {
        guard let managedProfile = modelContext.model(for: profile.persistentModelID) as? DrinkProfile else {
            throw DrinkPersistenceError.missingProfile
        }

        let log = DrinkLog(timestamp: date, profile: managedProfile, isNoDrink: true)
        modelContext.insert(log)
        try saveContext()
        return log
    }

    func fetchRecentLogs(in interval: DateInterval) throws -> [DrinkLog] {
        guard interval.duration >= 0 else { throw DrinkPersistenceError.invalidDateRange }
        let descriptor = FetchDescriptor<DrinkLog>(
            predicate: #Predicate { log in
                log.timestamp >= interval.start && log.timestamp <= interval.end
            },
            sortBy: [SortDescriptor(\DrinkLog.timestamp, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    private func fetchSettings() throws -> UserSettings? {
        var descriptor = FetchDescriptor<UserSettings>()
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    private func fetchOrCreateSettings() throws -> UserSettings {
        if let existing = try fetchSettings() {
            return existing
        }
        let settings = UserSettings()
        modelContext.insert(settings)
        try saveContext()
        return settings
    }

    func loadReminderConfiguration() throws -> ReminderConfiguration {
        let settings = try fetchOrCreateSettings()
        return ReminderConfiguration(isEnabled: settings.reminderEnabled, reminderTime: settings.reminderTime)
    }

    func updateReminderConfiguration(_ configuration: ReminderConfiguration) throws {
        let settings = try fetchOrCreateSettings()
        settings.reminderEnabled = configuration.isEnabled
        settings.reminderTime = configuration.reminderTime
        try saveContext()
    }

    func updateOnboardingCompletion(to value: Bool) throws {
        let settings = try fetchOrCreateSettings()
        settings.hasCompletedOnboarding = value
        try saveContext()
    }

    private func saveContext() throws {
        do {
            try modelContext.save()
        } catch {
            throw DrinkPersistenceError.saveFailed
        }
    }
}
