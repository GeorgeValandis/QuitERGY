//
//  StepDetailView.swift
//  QuitERGY
//
//  Created by Codex.
//

import SwiftUI

struct StepDetailView<Content: View>: View {
    let indicator: String
    let title: String
    let subtitle: String
    @ViewBuilder let content: Content

    init(indicator: String,
         title: String,
         subtitle: String,
         @ViewBuilder content: () -> Content) {
        self.indicator = indicator
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        OnboardingView.NeonCard {
            VStack(alignment: .leading, spacing: 16) {
                Text(indicator.uppercased())
                    .font(.quitRounded(.medium, size: 12))
                    .foregroundStyle(QuitERGYTheme.textSecondary.opacity(0.7))
                Text(title)
                    .font(.quitRounded(.semibold, size: 24))
                    .foregroundStyle(QuitERGYTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(subtitle)
                    .font(.quitRounded(.medium, size: 15))
                    .foregroundStyle(QuitERGYTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                Divider()
                    .background(QuitERGYTheme.surface.opacity(0.6))
                content
            }
        }
    }
}
