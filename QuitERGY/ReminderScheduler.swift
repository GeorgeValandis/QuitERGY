//
//  ReminderScheduler.swift
//  QuitERGY
//
//  Created by Codex.
//

import Foundation
import UserNotifications

protocol ReminderScheduling {
    func ensureAuthorization() async throws
    func scheduleDailyReminder(at time: Date, profileName: String?) async throws
    func cancelScheduledReminder()
}

enum ReminderSchedulerError: LocalizedError {
    case permissionDenied

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return L10n.text("Notifications are disabled. Enable them in Settings to receive reminders.")
        }
    }
}

final class ReminderScheduler: ReminderScheduling {
    private let center: UNUserNotificationCenter
    private let reminderIdentifier = "QuitERGY.dailyReminder"

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func ensureAuthorization() async throws {
        let settings = await withCheckedContinuation { continuation in
            center.getNotificationSettings { settings in
                continuation.resume(returning: settings)
            }
        }
        switch settings.authorizationStatus {
        case .denied:
            throw ReminderSchedulerError.permissionDenied
        case .notDetermined:
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            if !granted {
                throw ReminderSchedulerError.permissionDenied
            }
        default:
            break
        }
    }

    func scheduleDailyReminder(at time: Date, profileName: String?) async throws {
        try await ensureAuthorization()
        cancelScheduledReminder()

        var dateComponents = Calendar.current.dateComponents([.hour, .minute], from: time)
        dateComponents.second = 0

        let content = UNMutableNotificationContent()
        content.title = L10n.text("Energy Check-in")
        if let profileName, !profileName.isEmpty {
            content.body = L10n.format("Did you have your %@ today?", profileName)
        } else {
            content.body = L10n.text("Did you have an energy drink today?")
        }
        content.sound = UNNotificationSound.default

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: reminderIdentifier, content: content, trigger: trigger)

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            center.add(request) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    func cancelScheduledReminder() {
        center.removePendingNotificationRequests(withIdentifiers: [reminderIdentifier])
    }
}
