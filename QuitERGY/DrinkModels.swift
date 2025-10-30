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
final class UserSettings {
    @Attribute(.unique) var id: UUID
    var selectedProfile: DrinkProfile?
    var dailyTargetDrinks: Int?

    init(id: UUID = UUID(), selectedProfile: DrinkProfile? = nil, dailyTargetDrinks: Int? = nil) {
        self.id = id
        self.selectedProfile = selectedProfile
        self.dailyTargetDrinks = dailyTargetDrinks
    }
}
