//
//  Theme.swift
//  QuitERGY
//
//  Created by Codex.
//

import SwiftUI

enum QuitERGYTheme {
    static let background = Color(red: 14 / 255, green: 14 / 255, blue: 14 / 255)
    static let surface = Color(red: 24 / 255, green: 24 / 255, blue: 26 / 255)
    static let accent = Color(red: 0 / 255, green: 255 / 255, blue: 157 / 255)
    static let textPrimary = Color.white
    static let textSecondary = Color(red: 156 / 255, green: 163 / 255, blue: 175 / 255)

    static let cardCornerRadius: CGFloat = 20
    static let cardPadding: CGFloat = 20
    static let cardShadowColor: Color = Color.black.opacity(0.45)
}

extension Font {
    static func quitRounded(_ weight: Font.Weight = .regular, size: CGFloat) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

struct NeonGlowModifier: ViewModifier {
    var color: Color = QuitERGYTheme.accent
    var cornerRadius: CGFloat = QuitERGYTheme.cardCornerRadius
    var lineWidth: CGFloat = 1.5

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(color.opacity(0.8), lineWidth: lineWidth)
                    .shadow(color: color.opacity(0.6), radius: 12)
            )
    }
}

extension View {
    func neonGlow(color: Color = QuitERGYTheme.accent,
                  cornerRadius: CGFloat = QuitERGYTheme.cardCornerRadius,
                  lineWidth: CGFloat = 1.5) -> some View {
        modifier(NeonGlowModifier(color: color, cornerRadius: cornerRadius, lineWidth: lineWidth))
    }

    func cardBackground() -> some View {
        background(
            RoundedRectangle(cornerRadius: QuitERGYTheme.cardCornerRadius)
                .fill(QuitERGYTheme.surface)
                .shadow(color: QuitERGYTheme.cardShadowColor, radius: 18, x: 0, y: 12)
        )
    }
}
