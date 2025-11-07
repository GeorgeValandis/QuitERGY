//
//  BadgeManager.swift
//  QuitERGY
//
//  Created by Georgios Avenidis on 07.11.25.
//

import Foundation
import UserNotifications

@MainActor
final class BadgeManager {
    static let shared = BadgeManager()
    
    private let defaults = UserDefaults.standard
    private let lastOpenKey = "badge_last_app_open"
    
    private init() {}
    
    /// Request notification permission (needed for badges)
    func requestBadgePermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.badge]) { granted, error in
            if let error = error {
                print("❌ Badge permission error: \(error)")
            } else if granted {
                print("✅ Badge permission granted")
            }
        }
    }
    
    /// Call this when the app becomes active
    func handleAppDidBecomeActive() {
        // Clear badge when app is opened
        clearBadge()
        
        // Update last open timestamp
        updateLastOpenDate()
    }
    
    /// Call this when the app goes to background
    func handleAppWillResignActive() {
        // Schedule badge check for tomorrow
        scheduleBadgeCheck()
    }
    
    /// Clear the app badge
    func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0) { error in
            if let error = error {
                print("❌ Error clearing badge: \(error)")
            }
        }
    }
    
    /// Set badge to 1
    private func setBadge() {
        UNUserNotificationCenter.current().setBadgeCount(1) { error in
            if let error = error {
                print("❌ Error setting badge: \(error)")
            } else {
                print("✅ Badge set to 1")
            }
        }
    }
    
    /// Update the last open date to now
    private func updateLastOpenDate() {
        let now = Date()
        defaults.set(now, forKey: lastOpenKey)
        print("📅 Last open date updated: \(now)")
    }
    
    /// Schedule a check to set badge if app hasn't been opened in 24 hours
    private func scheduleBadgeCheck() {
        // Remove any existing badge notifications
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["badge_reminder"])
        
        // Create a notification that just sets the badge (no alert/sound)
        let content = UNMutableNotificationContent()
        content.badge = 1
        
        // Trigger after 24 hours
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 24 * 60 * 60, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "badge_reminder",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error scheduling badge: \(error)")
            } else {
                print("✅ Badge scheduled for 24 hours from now")
            }
        }
    }
    
    /// Check if we should show badge (called on app launch)
    func checkAndUpdateBadge() {
        guard let lastOpen = defaults.object(forKey: lastOpenKey) as? Date else {
            // First launch, no badge needed
            return
        }
        
        let hoursSinceLastOpen = Date().timeIntervalSince(lastOpen) / 3600
        
        if hoursSinceLastOpen >= 24 {
            // More than 24 hours since last open, set badge
            setBadge()
        } else {
            // Less than 24 hours, clear badge
            clearBadge()
        }
    }
}
