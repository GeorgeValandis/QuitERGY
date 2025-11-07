//
//  AppStoreRatingView.swift
//  QuitERGY
//
//  Created by Georgios Avenidis on 07.11.25.
//

import SwiftUI

struct AppStoreRatingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    private let onRateNow: () -> Void
    private let onSendFeedback: () -> Void
    private let onMaybeLater: () -> Void

    init(
        onRateNow: @escaping () -> Void = {},
        onSendFeedback: @escaping () -> Void = {},
        onMaybeLater: @escaping () -> Void = {}
    ) {
        self.onRateNow = onRateNow
        self.onSendFeedback = onSendFeedback
        self.onMaybeLater = onMaybeLater
    }

    var body: some View {
        GeometryReader { proxy in
            let metrics = RatingLayoutMetrics(size: proxy.size)
            let safeInsets = proxy.safeAreaInsets

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: metrics.stackSpacing) {
                    Capsule()
                        .fill(Color.primary.opacity(0.08))
                        .frame(width: 42, height: 5)

                    VStack(spacing: metrics.contentSpacing) {
                        icon(isCompactHeight: metrics.isCompactHeight)

                        VStack(spacing: metrics.titleSpacing) {
                            Text("Enjoying QuitERGY?")
                                .font(.title3.weight(.bold))
                                .multilineTextAlignment(.center)
                            
                            // 5 goldene Sterne
                            HStack(spacing: 6) {
                                ForEach(0..<5, id: \.self) { _ in
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [
                                                    Color(red: 1.0, green: 0.84, blue: 0.0),
                                                    Color(red: 1.0, green: 0.75, blue: 0.0)
                                                ],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                        .shadow(color: Color.yellow.opacity(0.3), radius: 4, x: 0, y: 2)
                                }
                            }
                            .padding(.vertical, 4)

                            Text(
                                "Your App Store review helps more people break free from energy drinks."
                            )
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                        }

                        featureList(isCompactHeight: metrics.isCompactHeight)

                        VStack(spacing: metrics.buttonStackSpacing) {
                            Button(action: handleRateNow) {
                                Text("Rate QuitERGY")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, metrics.primaryButtonVerticalPadding)
                            }
                            .buttonStyle(.plain)
                            .background(primaryGradient)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .shadow(color: accentColor.opacity(0.2), radius: 14, x: 0, y: 6)

                            Button(action: handleMaybeLater) {
                                Text("Maybe later")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, metrics.secondaryButtonVerticalPadding)
                            }
                            .buttonStyle(.borderless)
                            .background(secondaryBackground)
                            .foregroundStyle(accentColor)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }

                        Button(action: handleSendFeedback) {
                            HStack(spacing: 6) {
                                Image(systemName: "heart.text.square")
                                Text("Something to improve? Send feedback")
                            }
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                        }
                        .foregroundStyle(accentColor)
                        .padding(.top, metrics.feedbackTopPadding)
                    }
                    .padding(.top, metrics.innerTopPadding)
                    .padding(.horizontal, metrics.innerHorizontalPadding)
                    .padding(.vertical, metrics.innerVerticalPadding)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, safeInsets.top + metrics.contentTopPadding)
                .padding(.horizontal, metrics.outerHorizontalPadding)
                .padding(.bottom, safeInsets.bottom + metrics.bottomPadding)
            }
            .scrollIndicators(.hidden)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .modifier(SheetBackgroundModifier(background: sheetBackground))
        .presentationDetents([.fraction(0.9), .large])
        .presentationDragIndicator(.hidden)
    }

    private func icon(isCompactHeight: Bool) -> some View {
        let circleSize: CGFloat = isCompactHeight ? 78 : 84
        let symbolSize: CGFloat = isCompactHeight ? 32 : 34

        return ZStack {
            Circle()
                .fill(primaryGradient)
                .frame(width: circleSize, height: circleSize)
                .overlay(
                    Circle()
                        .stroke(
                            Color.white.opacity(colorScheme == .dark ? 0.08 : 0.24), lineWidth: 1)
                )
                .shadow(color: accentColor.opacity(0.25), radius: 12, x: 0, y: 8)

            Image(systemName: "star.fill")
                .font(.system(size: symbolSize, weight: .semibold))
                .foregroundStyle(.white)
        }
        .padding(.bottom, 4)
    }

    private func featureList(isCompactHeight: Bool) -> some View {
        let padding: CGFloat = isCompactHeight ? 14 : 16

        return VStack(alignment: .leading, spacing: 12) {
            infoRow(icon: "sparkles", text: "Takes less than 30 seconds", isCompactHeight: isCompactHeight)
            infoRow(icon: "hands.sparkles", text: "Helps others discover QuitERGY", isCompactHeight: isCompactHeight)
            infoRow(icon: "bubble.left", text: "We read every note you share", isCompactHeight: isCompactHeight)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(padding)
        .background(secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func infoRow(icon: String, text: LocalizedStringKey, isCompactHeight: Bool) -> some View {
        let circleSize: CGFloat = isCompactHeight ? 26 : 28
        let symbolSize: CGFloat = isCompactHeight ? 13 : 14

        return HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(accentColor.opacity(colorScheme == .dark ? 0.25 : 0.18))
                    .frame(width: circleSize, height: circleSize)
                Image(systemName: icon)
                    .font(.system(size: symbolSize, weight: .semibold))
                    .foregroundStyle(accentColor)
            }
            Text(text)
                .font(.footnote.weight(.medium))
                .foregroundStyle(.secondary)
        }
    }

    private func handleRateNow() {
        dismiss()
        onRateNow()
    }

    private func handleSendFeedback() {
        dismiss()
        onSendFeedback()
    }

    private func handleMaybeLater() {
        dismiss()
        onMaybeLater()
    }

    private var accentColor: Color {
        QuitERGYTheme.accent
    }

    private var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [accentColor.opacity(0.85), accentColor.opacity(0.55)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var secondaryBackground: Color {
        if colorScheme == .dark {
            return Color.white.opacity(0.06)
        }
        return QuitERGYTheme.surface
    }

    private var sheetBackground: some View {
        ZStack {
            sheetBaseColor
            LinearGradient(
                colors: [
                    accentColor.opacity(0.18), Color.clear, accentColor.opacity(0.08),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .ignoresSafeArea()
    }

    private var sheetBaseColor: Color {
        #if os(iOS)
            if colorScheme == .dark {
                return Color(uiColor: .secondarySystemBackground)
            }
            return Color(uiColor: .systemBackground)
        #else
            if colorScheme == .dark {
                return Color(nsColor: .windowBackgroundColor)
            }
            return Color(nsColor: .windowBackgroundColor)
        #endif
    }
}

private struct RatingLayoutMetrics {
    let isCompactHeight: Bool
    let isMediumHeight: Bool
    let stackSpacing: CGFloat
    let contentSpacing: CGFloat
    let titleSpacing: CGFloat
    let buttonStackSpacing: CGFloat
    let primaryButtonVerticalPadding: CGFloat
    let secondaryButtonVerticalPadding: CGFloat
    let feedbackTopPadding: CGFloat
    let innerTopPadding: CGFloat
    let innerHorizontalPadding: CGFloat
    let innerVerticalPadding: CGFloat
    let contentTopPadding: CGFloat
    let outerHorizontalPadding: CGFloat
    let bottomPadding: CGFloat

    init(size: CGSize) {
        let height = size.height
        let width = size.width
        isCompactHeight = height < 520
        isMediumHeight = height < 620
        let isSmallPhone = height <= 610 && width <= 375

        if isCompactHeight {
            stackSpacing = 18
        } else if isSmallPhone {
            stackSpacing = 10
        } else {
            stackSpacing = 24
        }
        contentSpacing = isMediumHeight ? 14 : 16
        titleSpacing = isCompactHeight ? 8 : 10
        buttonStackSpacing = isCompactHeight ? 12 : 14
        primaryButtonVerticalPadding = isCompactHeight ? 12 : 14
        secondaryButtonVerticalPadding = isCompactHeight ? 11 : 13
        feedbackTopPadding = isCompactHeight ? 4 : 6
        innerTopPadding = isCompactHeight ? 8 : 12
        innerHorizontalPadding = isMediumHeight ? 22 : 24
        innerVerticalPadding = isMediumHeight ? 22 : 26
        contentTopPadding = isCompactHeight ? 12 : 18
        outerHorizontalPadding = 0
        bottomPadding = 24
    }
}

#Preview {
    AppStoreRatingView()
        .preferredColorScheme(.dark)
}

#Preview("Light") {
    AppStoreRatingView()
        .preferredColorScheme(.light)
}

private struct SheetBackgroundModifier<Background: View>: ViewModifier {
    let background: Background

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 17, *) {
            content
                .presentationBackground {
                    background
                }
        } else {
            content
                .background(background)
        }
    }
}
