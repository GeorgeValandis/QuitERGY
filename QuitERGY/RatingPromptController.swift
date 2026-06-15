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
        case successfulLogCount = "rating_prompt_successful_log_count"
        case lastPromptTimestamp = "rating_prompt_last_shown"
        case lastPromptMilestone = "rating_prompt_last_milestone"
    }

    private let defaults: UserDefaults
    private let appStoreURL: URL?

    private let successfulLogMilestones: Set<Int> = [3, 10, 25]
    private let streakMilestones: Set<Int> = [3, 7, 14, 30, 60, 90]
    private let cooldownInterval: TimeInterval = 90 * 24 * 60 * 60

    init(appStoreURL: URL? = nil, defaults: UserDefaults = .standard) {
        self.appStoreURL = appStoreURL
        self.defaults = defaults
    }

    func recordAppOpen() {
        // Intentionally no-op: review prompts should follow a useful action, not launch.
    }

    func recordEntryCreated() {
        recordSuccessfulLog(isNoDrink: true, streakDays: 0)
    }

    func recordSuccessfulLog(isNoDrink: Bool, streakDays: Int) {
        guard isNoDrink else { return }

        successfulLogCount += 1
        guard let milestoneKey = milestoneKey(logCount: successfulLogCount, streakDays: streakDays) else {
            return
        }

        requestReviewIfEligible(for: milestoneKey)
    }

    func resetCounters() {
        successfulLogCount = 0
    }

    func completePrompt() {
    }

    func handleRateNowAction() {
        AppAnalytics.shared.track("review_write_link_opened", properties: [
            "surface": "rating_prompt"
        ])
        openWriteReviewPage()
        completePrompt()
    }

    private func milestoneKey(logCount: Int, streakDays: Int) -> String? {
        if streakMilestones.contains(streakDays) {
            return "streak-\(streakDays)"
        }
        if successfulLogMilestones.contains(logCount) {
            return "successful-log-\(logCount)"
        }
        return nil
    }

    private var cooldownSatisfied: Bool {
        guard lastPromptTimestamp > 0 else { return true }
        return Date().timeIntervalSince1970 - lastPromptTimestamp >= cooldownInterval
    }

    private var successfulLogCount: Int {
        get { defaults.integer(forKey: StorageKey.successfulLogCount.rawValue) }
        set { defaults.set(newValue, forKey: StorageKey.successfulLogCount.rawValue) }
    }

    private var lastPromptMilestone: String {
        get { defaults.string(forKey: StorageKey.lastPromptMilestone.rawValue) ?? "" }
        set { defaults.set(newValue, forKey: StorageKey.lastPromptMilestone.rawValue) }
    }

    private var lastPromptTimestamp: TimeInterval {
        get { defaults.double(forKey: StorageKey.lastPromptTimestamp.rawValue) }
        set { defaults.set(newValue, forKey: StorageKey.lastPromptTimestamp.rawValue) }
    }

    private func requestReviewIfEligible(for milestoneKey: String) {
        guard lastPromptMilestone != milestoneKey else {
            AppAnalytics.shared.track("review_prompt_suppressed", properties: [
                "milestone": milestoneKey,
                "reason": "duplicate_milestone"
            ])
            return
        }
        guard cooldownSatisfied else {
            AppAnalytics.shared.track("review_prompt_suppressed", properties: [
                "milestone": milestoneKey,
                "reason": "cooldown"
            ])
            return
        }

#if canImport(StoreKit) && os(iOS)
        if let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }) {
            lastPromptMilestone = milestoneKey
            lastPromptTimestamp = Date().timeIntervalSince1970
            AppAnalytics.shared.track("review_prompt_eligible", properties: [
                "milestone": milestoneKey
            ])
            AppAnalytics.shared.track("review_prompt_requested", properties: [
                "milestone": milestoneKey,
                "surface": "system_review_prompt"
            ])

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                if #available(iOS 18.0, *) {
                    AppStore.requestReview(in: windowScene)
                } else {
                    SKStoreReviewController.requestReview(in: windowScene)
                }
            }
        } else {
            AppAnalytics.shared.track("review_prompt_suppressed", properties: [
                "milestone": milestoneKey,
                "reason": "no_active_scene"
            ])
        }
#endif
    }

    private func openWriteReviewPage() {
#if os(iOS)
        if let appStoreURL {
            UIApplication.shared.open(appStoreURL)
        }
#endif
    }
}
