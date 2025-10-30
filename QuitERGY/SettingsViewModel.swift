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

    @Published var errorMessage: String?

    private let persistence: DrinkPersistenceProviding

    init(service: DrinkPersistenceProviding) {
        self.persistence = service
    }

    func loadData() {
        do {
            profiles = try persistence.loadProfiles()
            selectedProfile = try persistence.loadSelectedProfile()
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
            throw ValidationError(message: "\(label) muss eine Zahl sein.")
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
}

private struct ValidationError: LocalizedError {
    let message: String

    var errorDescription: String? { message }
}
