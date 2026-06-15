import Foundation
#if canImport(TelemetryDeck)
import TelemetryDeck
#endif

struct AnalyticsEventRecord: Equatable {
    let name: String
    let properties: [String: String]
    let timestamp: Date
}

@MainActor
final class AppAnalytics {
    static let shared = AppAnalytics(appName: "QuitERGY")

    private let appName: String
    private let maxRecentEvents = 100
    private var isEnabledOverride: Bool?
    private var eventSink: ((AnalyticsEventRecord) -> Void)?
    private var isTelemetryDeckConfigured = false

    private(set) var recentEvents: [AnalyticsEventRecord] = []

    private init(appName: String) {
        self.appName = appName
    }

    func configureRemoteAnalytics() {
        configureRemoteAnalytics(appID: AnalyticsConfiguration.telemetryDeckAppID)
    }

    func configureRemoteAnalytics(appID: String) {
        let normalizedAppID = sanitizedValue(appID, maximumLength: 120)
        guard !normalizedAppID.isEmpty else { return }
        guard !isTelemetryDeckConfigured else { return }

        #if canImport(TelemetryDeck)
        let config = TelemetryDeck.Config(appID: normalizedAppID)
        TelemetryDeck.initialize(config: config)
        isTelemetryDeckConfigured = true
        #endif
    }

    func track(_ name: String, properties: [String: String] = [:]) {
        guard isEnabled else { return }

        let event = AnalyticsEventRecord(
            name: sanitizedEventName(name),
            properties: baseProperties().merging(sanitizedProperties(properties)) { _, new in new },
            timestamp: Date()
        )

        recentEvents.append(event)
        if recentEvents.count > maxRecentEvents {
            recentEvents.removeFirst(recentEvents.count - maxRecentEvents)
        }

        eventSink?(event)
        sendToRemoteAnalytics(event)

        #if DEBUG
        if ProcessInfo.processInfo.environment["APP_ANALYTICS_DEBUG_LOG"] == "1" {
            print("[Analytics] \(event.name) \(event.properties)")
        }
        #endif
    }

    func setEnabledForTesting(_ isEnabled: Bool?) {
        isEnabledOverride = isEnabled
    }

    func setEventSinkForTesting(_ sink: ((AnalyticsEventRecord) -> Void)?) {
        eventSink = sink
    }

    func resetForTesting() {
        recentEvents.removeAll()
        eventSink = nil
        isEnabledOverride = nil
    }

    private var isEnabled: Bool {
        if let isEnabledOverride { return isEnabledOverride }
        if ProcessInfo.processInfo.environment["APP_ANALYTICS_DISABLED"] == "1" {
            return false
        }
        if let storedPreference = UserDefaults.standard.object(forKey: "analytics_enabled") as? Bool {
            return storedPreference
        }

        #if DEBUG
        return true
        #else
        return isTelemetryDeckConfigured
        #endif
    }

    private func sendToRemoteAnalytics(_ event: AnalyticsEventRecord) {
        guard isTelemetryDeckConfigured else { return }

        #if canImport(TelemetryDeck)
        TelemetryDeck.signal(event.name, parameters: event.properties)
        #endif
    }

    private func baseProperties() -> [String: String] {
        [
            "app": appName,
            "app_version": Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown",
            "build": Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "unknown",
            "locale": Locale.current.identifier,
            "os": ProcessInfo.processInfo.operatingSystemVersionString,
            "platform": platformName
        ]
    }

    private var platformName: String {
        #if os(iOS)
        return "ios"
        #elseif os(macOS)
        return "macos"
        #else
        return "apple"
        #endif
    }

    private func sanitizedEventName(_ name: String) -> String {
        let sanitizedName = sanitizedValue(name, maximumLength: 80)
        return sanitizedName.isEmpty ? "unknown_event" : sanitizedName
    }

    private func sanitizedProperties(_ properties: [String: String]) -> [String: String] {
        var result: [String: String] = [:]

        for (key, value) in properties.sorted(by: { $0.key < $1.key }).prefix(40) {
            let sanitizedKey = sanitizedKey(key)
            guard !sanitizedKey.isEmpty else { continue }
            result[sanitizedKey] = sanitizedValue(value, maximumLength: 160)
        }

        return result
    }

    private func sanitizedKey(_ key: String) -> String {
        let characters = key.map { character in
            character.isLetter || character.isNumber || character == "_" || character == "-" || character == "."
                ? character
                : "_"
        }
        return String(String(characters).prefix(64))
    }

    private func sanitizedValue(_ value: String, maximumLength: Int) -> String {
        let normalized = value
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return String(normalized.prefix(maximumLength))
    }
}
