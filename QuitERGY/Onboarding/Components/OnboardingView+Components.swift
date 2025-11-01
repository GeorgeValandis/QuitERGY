//
//  OnboardingView+Components.swift
//  QuitERGY
//
//  Created by Codex.
//

import SwiftUI

extension OnboardingView {
    struct NeonCard<Content: View>: View {
        let alignment: HorizontalAlignment
        let spacing: CGFloat
        @ViewBuilder var content: () -> Content

        init(
            alignment: HorizontalAlignment = .leading,
            spacing: CGFloat = 20,
            @ViewBuilder content: @escaping () -> Content
        ) {
            self.alignment = alignment
            self.spacing = spacing
            self.content = content
        }

        var body: some View {
            VStack(alignment: alignment, spacing: spacing) {
                content()
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: QuitERGYTheme.cardCornerRadius)
                    .fill(QuitERGYTheme.surface)
                    .shadow(color: QuitERGYTheme.cardShadowColor, radius: 18, x: 0, y: 12)
            )
        }
    }

    struct OptionButton: View {
        let title: String
        let subtitle: String
        let emoji: String?
        let isSelected: Bool
        let action: () -> Void

        init(
            title: String,
            subtitle: String,
            emoji: String? = nil,
            isSelected: Bool,
            action: @escaping () -> Void
        ) {
            self.title = title
            self.subtitle = subtitle
            self.emoji = emoji
            self.isSelected = isSelected
            self.action = action
        }

        var body: some View {
            Button(action: action) {
                HStack(alignment: .center, spacing: 16) {
                    if let emoji {
                        Text(emoji)
                            .font(.system(size: 24))
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.quitRounded(.semibold, size: 18))
                            .foregroundStyle(QuitERGYTheme.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                            .allowsTightening(true)
                            .layoutPriority(1)
                        Text(subtitle)
                            .font(.quitRounded(.medium, size: 14))
                            .foregroundStyle(QuitERGYTheme.textSecondary)
                            .lineSpacing(2)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(alignment: .trailing) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(
                            isSelected
                                ? QuitERGYTheme.accent : QuitERGYTheme.textSecondary.opacity(0.5))
                }
                .padding(18)
                .contentShape(Rectangle())
            }
            .frame(maxWidth: .infinity)
            .buttonStyle(.plain)
            .background(
                RoundedRectangle(cornerRadius: QuitERGYTheme.cardCornerRadius - 6)
                    .fill(QuitERGYTheme.surface.opacity(isSelected ? 0.9 : 0.7))
            )
        }
    }

    struct MetricTile: View {
        let title: String
        let value: String
        let caption: String?

        init(title: String, value: String, caption: String? = nil) {
            self.title = title
            self.value = value
            self.caption = caption
        }

        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text(title.uppercased())
                    .font(.quitRounded(.medium, size: 12))
                    .foregroundStyle(QuitERGYTheme.textSecondary.opacity(0.8))
                Text(value)
                    .font(.quitRounded(.semibold, size: 22))
                    .foregroundStyle(QuitERGYTheme.textPrimary)
                if let caption {
                    Text(caption)
                        .font(.quitRounded(.medium, size: 13))
                        .foregroundStyle(QuitERGYTheme.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: QuitERGYTheme.cardCornerRadius - 8)
                    .fill(QuitERGYTheme.surface.opacity(0.82))
            )
        }
    }

    func primaryButton(title: String, isDisabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.quitRounded(.semibold, size: 18))
                .foregroundStyle(QuitERGYTheme.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: QuitERGYTheme.cardCornerRadius)
                        .fill(
                            isDisabled
                                ? QuitERGYTheme.accent.opacity(0.2)
                                : QuitERGYTheme.accent.opacity(0.4))
                )
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }

    func secondaryButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.quitRounded(.medium, size: 16))
                .foregroundStyle(QuitERGYTheme.textSecondary)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: QuitERGYTheme.cardCornerRadius)
                        .fill(QuitERGYTheme.surface.opacity(0.6))
                )
        }
        .buttonStyle(.plain)
    }

    func progressBar(value: Double) -> some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(QuitERGYTheme.surface.opacity(0.6))
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                QuitERGYTheme.accent.opacity(0.6),
                                QuitERGYTheme.accent,
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(18, proxy.size.width * CGFloat(min(max(value, 0), 1))))
            }
        }
        .frame(height: 10)
        .animation(.easeInOut(duration: 0.45), value: value)
    }
}
