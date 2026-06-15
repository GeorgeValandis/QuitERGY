//
//  Localization.swift
//  QuitERGY
//
//  Created by Codex.
//

import Foundation

enum L10n {
    static func text(_ key: String) -> String {
        String(localized: String.LocalizationValue(key))
    }

    static func format(_ key: String, _ arguments: CVarArg...) -> String {
        let localizedFormat = NSLocalizedString(key, comment: "")
        return String(format: localizedFormat, locale: Locale.current, arguments: arguments)
    }
}
