//
//  OnboardingView+Overlays.swift
//  QuitERGY
//
//  Created by Codex.
//

import SwiftUI

extension OnboardingView {
    var onboardingBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    QuitERGYTheme.background,
                    QuitERGYTheme.background.opacity(0.95)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            RadialGradient(
                colors: [
                    QuitERGYTheme.accent.opacity(0.25),
                    .clear
                ],
                center: .topTrailing,
                startRadius: 100,
                endRadius: 520
            )
            RadialGradient(
                colors: [
                    QuitERGYTheme.accent.opacity(0.18),
                    .clear
                ],
                center: .bottomLeading,
                startRadius: 60,
                endRadius: 480
            )
        }
        .ignoresSafeArea()
    }
}
