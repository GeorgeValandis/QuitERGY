import SwiftUI

enum QuitERGYPaywallBrand {
    static let accent = QuitERGYTheme.accent
    static let background = QuitERGYTheme.background
    static let surface = QuitERGYTheme.surface

    static let highlightGradient = LinearGradient(
        colors: [accent.opacity(0.85), accent.opacity(0.55)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static var screenBackground: some View {
        ZStack {
            background
            LinearGradient(
                colors: [
                    accent.opacity(0.12),
                    Color.black.opacity(0.6),
                    accent.opacity(0.18)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    static func blurGlow(radius: CGFloat = 60, opacity: Double = 0.65) -> some View {
        Circle()
            .fill(accent.opacity(opacity))
            .blur(radius: radius)
    }
}
