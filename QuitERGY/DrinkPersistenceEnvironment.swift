//
//  DrinkPersistenceEnvironment.swift
//  QuitERGY
//
//  Created by Codex.
//

import SwiftUI

private struct DrinkPersistenceKey: EnvironmentKey {
    static let defaultValue: DrinkPersistenceProviding = UnimplementedDrinkPersistenceService()
}

extension EnvironmentValues {
    var drinkPersistence: DrinkPersistenceProviding {
        get { self[DrinkPersistenceKey.self] }
        set { self[DrinkPersistenceKey.self] = newValue }
    }
}

@MainActor
struct UnimplementedDrinkPersistenceService: DrinkPersistenceProviding {
    func loadProfiles() throws -> [DrinkProfile] {
        fatalError("Drink persistence service not provided.")
    }

    func createProfile(input: DrinkProfileInput) throws -> DrinkProfile {
        fatalError("Drink persistence service not provided.")
    }

    func deleteProfile(_ profile: DrinkProfile) throws {
        fatalError("Drink persistence service not provided.")
    }

    func selectProfile(_ profile: DrinkProfile?) throws {
        fatalError("Drink persistence service not provided.")
    }

    func loadSelectedProfile() throws -> DrinkProfile? {
        fatalError("Drink persistence service not provided.")
    }

    func logDrink(_ profile: DrinkProfile, date: Date) throws -> DrinkLog {
        fatalError("Drink persistence service not provided.")
    }

    func fetchRecentLogs(in interval: DateInterval) throws -> [DrinkLog] {
        fatalError("Drink persistence service not provided.")
    }
}
