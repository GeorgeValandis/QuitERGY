import Combine
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

public struct RemoteUpdateGateConfiguration: Sendable {
    public let appStoreId: String
    public let appName: String
    public let policyURL: URL
    public let countryCode: String

    public init(
        appStoreId: String,
        appName: String,
        policyURL: URL = URL(string: "https://georgevalandis.com/app-updates/ios.json")!,
        countryCode: String = "DE"
    ) {
        self.appStoreId = appStoreId
        self.appName = appName
        self.policyURL = policyURL
        self.countryCode = countryCode
    }
}

public enum RemoteUpdateMode: String, Decodable, Sendable {
    case none
    case optional
    case required
}

public struct RemoteUpdatePrompt: Equatable, Sendable {
    public enum Kind: Sendable {
        case optional
        case required
    }

    public let kind: Kind
    public let appName: String
    public let latestVersion: String?
    public let minimumSupportedVersion: String?
    public let message: String?
    public let storeURL: URL

    public var isRequired: Bool {
        kind == .required
    }
}

public struct RemoteUpdatePolicyFeed: Decodable, Sendable {
    public let apps: [RemoteUpdatePolicy]
}

public struct RemoteUpdatePolicy: Decodable, Sendable {
    public let bundleId: String
    public let appStoreId: String?
    public let latestVersion: String?
    public let minimumSupportedVersion: String?
    public let mode: RemoteUpdateMode?
    public let message: String?
    public let storeURL: String?
}

public struct RemoteUpdateLookupResponse: Decodable, Sendable {
    public struct AppInfo: Decodable, Sendable {
        public let version: String?
        public let trackViewUrl: String?
    }

    public let results: [AppInfo]
}

@MainActor
public final class RemoteUpdateGate: ObservableObject {
    @Published public private(set) var prompt: RemoteUpdatePrompt?
    @Published public private(set) var latestVersion: String?

    private let configuration: RemoteUpdateGateConfiguration
    private let bundleID: String
    private let dismissedVersionKey: String

    public var isPromptVisible: Bool {
        prompt != nil
    }

    public init(
        configuration: RemoteUpdateGateConfiguration,
        bundleID: String = Bundle.main.bundleIdentifier ?? ""
    ) {
        self.configuration = configuration
        self.bundleID = bundleID
        dismissedVersionKey = "gv_dismissedUpdateVersion_\(configuration.appStoreId)"
    }

    public func check() async {
        guard let current = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            return
        }

        async let lookupResult = fetchAppStoreInfo()
        async let remotePolicy = fetchRemotePolicy()

        let appStoreInfo = await lookupResult
        let policy = await remotePolicy
        let latest = policy?.latestVersion?.nonEmpty ?? appStoreInfo.version?.nonEmpty
        let minimumSupported = policy?.minimumSupportedVersion?.nonEmpty
        let storeURL =
            policy?.storeURL.flatMap(URL.init(string:))
            ?? appStoreInfo.trackViewUrl.flatMap(URL.init(string:))
            ?? URL(string: "https://apps.apple.com/app/id\(configuration.appStoreId)")!

        latestVersion = latest

        if let minimumSupported, Self.isOutdated(current: current, latest: minimumSupported) {
            prompt = RemoteUpdatePrompt(
                kind: .required,
                appName: configuration.appName,
                latestVersion: latest,
                minimumSupportedVersion: minimumSupported,
                message: policy?.message,
                storeURL: storeURL
            )
            return
        }

        let policyMode = policy?.mode ?? .optional
        guard policyMode != .none, let latest, Self.isOutdated(current: current, latest: latest) else {
            prompt = nil
            return
        }

        if policyMode == .required {
            prompt = RemoteUpdatePrompt(
                kind: .required,
                appName: configuration.appName,
                latestVersion: latest,
                minimumSupportedVersion: minimumSupported ?? latest,
                message: policy?.message,
                storeURL: storeURL
            )
            return
        }

        guard UserDefaults.standard.string(forKey: dismissedVersionKey) != latest else {
            prompt = nil
            return
        }

        prompt = RemoteUpdatePrompt(
            kind: .optional,
            appName: configuration.appName,
            latestVersion: latest,
            minimumSupportedVersion: minimumSupported,
            message: policy?.message,
            storeURL: storeURL
        )
    }

    public func dismiss() {
        if let latestVersion {
            UserDefaults.standard.set(latestVersion, forKey: dismissedVersionKey)
        }
        prompt = nil
    }

    public func openAppStore() {
        guard let url = prompt?.storeURL ?? URL(string: "https://apps.apple.com/app/id\(configuration.appStoreId)") else {
            return
        }

        #if os(iOS)
        UIApplication.shared.open(url)
        #endif
    }

    private func fetchAppStoreInfo() async -> RemoteUpdateLookupResponse.AppInfo {
        guard let url = URL(
            string: "https://itunes.apple.com/lookup?id=\(configuration.appStoreId)&country=\(configuration.countryCode)"
        ) else {
            return .init(version: nil, trackViewUrl: nil)
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let result = try JSONDecoder().decode(RemoteUpdateLookupResponse.self, from: data)
            return result.results.first ?? .init(version: nil, trackViewUrl: nil)
        } catch {
            return .init(version: nil, trackViewUrl: nil)
        }
    }

    private func fetchRemotePolicy() async -> RemoteUpdatePolicy? {
        do {
            let (data, _) = try await URLSession.shared.data(from: configuration.policyURL)
            let feed = try JSONDecoder().decode(RemoteUpdatePolicyFeed.self, from: data)
            return feed.apps.first {
                $0.bundleId == bundleID || $0.appStoreId == configuration.appStoreId
            }
        } catch {
            return nil
        }
    }

    private static func isOutdated(current: String, latest: String) -> Bool {
        let a = current.split(separator: ".").map { Int($0) ?? 0 }
        let b = latest.split(separator: ".").map { Int($0) ?? 0 }
        let maxCount = max(a.count, b.count)
        let pa = a + Array(repeating: 0, count: maxCount - a.count)
        let pb = b + Array(repeating: 0, count: maxCount - b.count)
        for index in 0..<maxCount {
            if pa[index] != pb[index] {
                return pa[index] < pb[index]
            }
        }
        return false
    }
}

public struct RemoteUpdateGateView: View {
    @ObservedObject private var gate: RemoteUpdateGate

    public init(gate: RemoteUpdateGate) {
        self.gate = gate
    }

    public var body: some View {
        if let prompt = gate.prompt {
            if prompt.isRequired {
                requiredView(prompt)
            } else {
                optionalBanner(prompt)
            }
        }
    }

    private func optionalBanner(_ prompt: RemoteUpdatePrompt) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.down.circle.fill")
                .font(.title2)
                .foregroundStyle(Color.accentColor)

            VStack(alignment: .leading, spacing: 3) {
                Text("Update available")
                    .font(.headline)
                Text(prompt.message ?? versionText(prompt))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            Button("Later") {
                gate.dismiss()
            }
            .buttonStyle(.bordered)

            Button("Update") {
                gate.openAppStore()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(14)
        .frame(maxWidth: 560)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: Color.black.opacity(0.18), radius: 18, y: 8)
        .padding()
    }

    private func requiredView(_ prompt: RemoteUpdatePrompt) -> some View {
        ZStack {
            Color.black.opacity(0.42)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundStyle(Color.accentColor)

                VStack(spacing: 8) {
                    Text("Update required")
                        .font(.title2.bold())
                    Text(prompt.message ?? L10n.format("Please update %@ to continue.", prompt.appName))
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                if let minimumSupportedVersion = prompt.minimumSupportedVersion {
                    Text(L10n.format("Minimum required version: %@", minimumSupportedVersion))
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                Button {
                    gate.openAppStore()
                } label: {
                    Text("Open App Store")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(24)
            .frame(maxWidth: 420)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func versionText(_ prompt: RemoteUpdatePrompt) -> String {
        if let latestVersion = prompt.latestVersion {
            return L10n.format("Version %@ is available in the App Store.", latestVersion)
        }
        return L10n.text("A newer version is available in the App Store.")
    }
}

private extension String {
    var nonEmpty: String? {
        let value = trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}
