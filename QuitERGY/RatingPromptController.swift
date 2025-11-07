//
//  RatingPromptController.swift
//  QuitERGY
//
//  Created by Georgios Avenidis on 07.11.25.
//

import Foundation
import Combine
import SwiftUI
#if canImport(StoreKit)
import StoreKit
#endif
#if os(iOS)
import UIKit
#endif

@MainActor
final class RatingPromptController: ObservableObject {
    private enum StorageKey: String {
        case entryCount = "rating_prompt_entry_count"
        case launchCount = "rating_prompt_launch_count"
        case lastPromptTimestamp = "rating_prompt_last_shown"
        case stage = "rating_prompt_stage"
    }

    @Published var isPresentingPrompt: Bool = false

    private let defaults: UserDefaults
    private let appStoreURL: URL?

    private enum Stage: Int {
        case initial = 0
        case recurring = 1

        var threshold: Int {
            switch self {
            case .initial: return 3
            case .recurring: return 10
            }
        }
    }

    private var stageRaw: Int {
        get { defaults.integer(forKey: StorageKey.stage.rawValue) }
        set { defaults.set(newValue, forKey: StorageKey.stage.rawValue) }
    }

    private var stage: Stage {
        get { Stage(rawValue: stageRaw) ?? .initial }
        set { stageRaw = newValue.rawValue }
    }

    private let cooldownInterval: TimeInterval = 14 * 24 * 60 * 60

    init(appStoreURL: URL? = nil, defaults: UserDefaults = .standard) {
        self.appStoreURL = appStoreURL
        self.defaults = defaults
    }

    func recordAppOpen() {
        guard !isPresentingPrompt else { return }
        launchCount += 1
        evaluateIfNeeded()
    }

    func recordEntryCreated() {
        guard !isPresentingPrompt else { return }
        entryCount += 1
        evaluateIfNeeded()
    }

    func resetCounters() {
        entryCount = 0
        launchCount = 0
    }

    func completePrompt() {
        isPresentingPrompt = false
    }

    func handleRateNowAction() {
        requestReviewIfPossible()
        completePrompt()
    }

    private func evaluateIfNeeded() {
        guard !isPresentingPrompt else { return }
        guard cooldownSatisfied else { return }

        let threshold = stage.threshold
        if entryCount >= threshold || launchCount >= threshold {
            triggerPrompt()
        }
    }

    private var cooldownSatisfied: Bool {
        guard lastPromptTimestamp > 0 else { return true }
        return Date().timeIntervalSince1970 - lastPromptTimestamp >= cooldownInterval
    }

    private func triggerPrompt() {
        isPresentingPrompt = true
        lastPromptTimestamp = Date().timeIntervalSince1970
        entryCount = 0
        launchCount = 0
        if stage == .initial {
            stage = .recurring
        }
    }

    private var entryCount: Int {
        get { defaults.integer(forKey: StorageKey.entryCount.rawValue) }
        set { defaults.set(newValue, forKey: StorageKey.entryCount.rawValue) }
    }

    private var launchCount: Int {
        get { defaults.integer(forKey: StorageKey.launchCount.rawValue) }
        set { defaults.set(newValue, forKey: StorageKey.launchCount.rawValue) }
    }

    private var lastPromptTimestamp: TimeInterval {
        get { defaults.double(forKey: StorageKey.lastPromptTimestamp.rawValue) }
        set { defaults.set(newValue, forKey: StorageKey.lastPromptTimestamp.rawValue) }
    }

    private func requestReviewIfPossible() {
#if canImport(StoreKit) && os(iOS)
        if let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }) {
            SKStoreReviewController.requestReview(in: windowScene)
            return
        }
#endif
#if os(iOS)
        if let appStoreURL {
            UIApplication.shared.open(appStoreURL)
        }
#endif
    }
}
