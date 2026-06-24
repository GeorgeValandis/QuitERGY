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
    func scheduleCheckInReminder(at time: Date, profileName: String?, cadence: ReminderCadence) async throws
    func cancelScheduledReminder()
}

enum ReminderCadence: Equatable {
    case daily
    case everyTwoDays

    var dayInterval: Int {
        switch self {
        case .daily: return 1
        case .everyTwoDays: return 2
        }
    }
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
    private let reminderIdentifierPrefix = "QuitERGY.checkInReminder"
    private let scheduledCheckInCount = 16

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

    func scheduleCheckInReminder(at time: Date, profileName: String?, cadence: ReminderCadence) async throws {
        try await ensureAuthorization()
        cancelScheduledReminder()

        let content = UNMutableNotificationContent()
        content.title = L10n.text("Energy Check-in")
        if let profileName, !profileName.isEmpty {
            content.body = L10n.format("Hey, did you have your %@ today?", profileName)
        } else {
            content.body = L10n.text("Hey, did you have an energy drink today?")
        }
        content.sound = UNNotificationSound.default

        switch cadence {
        case .daily:
            try await scheduleRepeatingDailyReminder(content: content, at: time)
        case .everyTwoDays:
            try await scheduleRollingEveryTwoDaysReminders(content: content, at: time)
        }
    }

    private func scheduleRepeatingDailyReminder(content: UNNotificationContent, at time: Date) async throws {
        var dateComponents = Calendar.current.dateComponents([.hour, .minute], from: time)
        dateComponents.second = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: reminderIdentifier(for: 0), content: content, trigger: trigger)

        try await add(request)
    }

    private func scheduleRollingEveryTwoDaysReminders(content: UNNotificationContent, at time: Date) async throws {
        let calendar = Calendar.current
        let now = Date()
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        let hour = timeComponents.hour ?? 9
        let minute = timeComponents.minute ?? 0

        var firstDate = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: now) ?? now
        if firstDate <= now {
            firstDate = calendar.date(byAdding: .day, value: ReminderCadence.everyTwoDays.dayInterval, to: firstDate) ?? now.addingTimeInterval(2 * 24 * 60 * 60)
        }

        for index in 0..<scheduledCheckInCount {
            guard let fireDate = calendar.date(
                byAdding: .day,
                value: index * ReminderCadence.everyTwoDays.dayInterval,
                to: firstDate
            ) else {
                continue
            }
            let triggerComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
            let request = UNNotificationRequest(identifier: reminderIdentifier(for: index), content: content, trigger: trigger)
            try await add(request)
        }
    }

    private func add(_ request: UNNotificationRequest) async throws {
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
        center.removePendingNotificationRequests(withIdentifiers: reminderIdentifiers)
    }

    private var reminderIdentifiers: [String] {
        (0..<scheduledCheckInCount).map { reminderIdentifier(for: $0) }
    }

    private func reminderIdentifier(for index: Int) -> String {
        "\(reminderIdentifierPrefix).\(index)"
    }
}
