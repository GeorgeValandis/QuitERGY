//
//  DrinkModels.swift
//  QuitERGY
//
//  Created by Codex.
//

import Foundation
import SwiftData

enum DrinkVariant: String, CaseIterable, Codable, Identifiable {
    case classic = "Classic"
    case sugarFree = "Sugar Free"
    case zero = "Zero"
    case highCaffeine = "High Caffeine"
    case custom = "Custom"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .classic: return "Classic"
        case .sugarFree: return "Sugar Free"
        case .zero: return "Zero"
        case .highCaffeine: return "High Caffeine"
        case .custom: return "Custom"
        }
    }
}

@Model
final class DrinkProfile {
    @Attribute(.unique) var id: UUID
    var name: String
    var brand: String?
    var variant: DrinkVariant
    var sugarGrams: Double
    var caffeineMg: Double
    var price: Decimal

    var logs: [DrinkLog] = []

    init(
        id: UUID = UUID(),
        name: String,
        brand: String?,
        variant: DrinkVariant,
        sugarGrams: Double,
        caffeineMg: Double,
        price: Decimal
    ) {
        self.id = id
        self.name = name
        self.brand = brand
        self.variant = variant
        self.sugarGrams = sugarGrams
        self.caffeineMg = caffeineMg
        self.price = price
    }
}

@Model
final class DrinkLog {
    @Attribute(.unique) var id: UUID
    var timestamp: Date
    var profile: DrinkProfile

    init(id: UUID = UUID(), timestamp: Date, profile: DrinkProfile) {
        self.id = id
        self.timestamp = timestamp
        self.profile = profile
    }
}

@Model
final class UserProfile {
    @Attribute(.unique) var id: UUID
    var baselineDrinksPerDay: Double
    var targetDrinksPerWeek: Double
    var drinkType: String
    var pricePerDrink: Double
    var sugarPerDrink: Double
    var caffeinePerDrink: Double
    var startDate: Date

    init(
        id: UUID = UUID(),
        baselineDrinksPerDay: Double,
        targetDrinksPerWeek: Double,
        drinkType: String,
        pricePerDrink: Double,
        sugarPerDrink: Double,
        caffeinePerDrink: Double,
        startDate: Date
    ) {
        self.id = id
        self.baselineDrinksPerDay = baselineDrinksPerDay
        self.targetDrinksPerWeek = targetDrinksPerWeek
        self.drinkType = drinkType
        self.pricePerDrink = pricePerDrink
        self.sugarPerDrink = sugarPerDrink
        self.caffeinePerDrink = caffeinePerDrink
        self.startDate = startDate
    }
}

@Model
final class UserSettings {
    @Attribute(.unique) var id: UUID
    var selectedProfile: DrinkProfile?
    var dailyTargetDrinks: Int?
    var reminderEnabled: Bool
    var reminderTime: Date?
    var hasCompletedOnboarding: Bool = false
    var userProfile: UserProfile?

    init(
        id: UUID = UUID(),
        selectedProfile: DrinkProfile? = nil,
        dailyTargetDrinks: Int? = nil,
        reminderEnabled: Bool = false,
        reminderTime: Date? = nil,
        userProfile: UserProfile? = nil
    ) {
        self.id = id
        self.selectedProfile = selectedProfile
        self.dailyTargetDrinks = dailyTargetDrinks
        self.reminderEnabled = reminderEnabled
        self.reminderTime = reminderTime
        self.userProfile = userProfile
    }
}
