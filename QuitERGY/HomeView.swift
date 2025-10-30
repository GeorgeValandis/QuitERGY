//
//  HomeView.swift
//  QuitERGY
//
//  Created by Codex.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var displayedProgress: Double = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 36) {
                Spacer(minLength: 0)

                streakRing
                    .padding(.top, 24)

                sinceLastDrink

                addDrinkButton

                Spacer()

                MotivationQuoteView(quote: "You’re taking back your energy.")
                    .padding(.bottom, 16)
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(QuitERGYTheme.background.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("QuitERGY")
                        .font(.quitRounded(.semibold, size: 20))
                        .foregroundStyle(QuitERGYTheme.textPrimary)
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2)) {
                displayedProgress = viewModel.streakProgress
            }
        }
        .onChange(of: viewModel.streakProgress) { _, newValue in
            withAnimation(.easeInOut(duration: 0.8)) {
                displayedProgress = newValue
            }
        }
        .alert("Reset streak?", isPresented: $viewModel.isShowingResetAlert) {
            Button("Reset", role: .destructive) {
                viewModel.addDrink()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Logging a drink resets your current streak to zero.")
        }
    }

    private var streakRing: some View {
        ZStack {
            Circle()
                .stroke(QuitERGYTheme.accent.opacity(0.15), lineWidth: 18)

            Circle()
                .trim(from: 0, to: displayedProgress)
                .stroke(style: StrokeStyle(lineWidth: 18, lineCap: .round))
                .foregroundStyle(QuitERGYTheme.accent)
                .shadow(color: QuitERGYTheme.accent.opacity(0.7), radius: 18)
                .rotationEffect(.degrees(-90))

            VStack(spacing: 8) {
                Text(viewModel.streakTitle)
                    .font(.quitRounded(.semibold, size: 22))
                    .foregroundStyle(QuitERGYTheme.textPrimary)
                Text(viewModel.streakSubtitle)
                    .font(.quitRounded(.medium, size: 16))
                    .foregroundStyle(QuitERGYTheme.textSecondary)
            }
        }
        .frame(width: 260, height: 260)
    }

    private var sinceLastDrink: some View {
        VStack(spacing: 12) {
            Text("Since last drink")
                .font(.quitRounded(.medium, size: 16))
                .foregroundStyle(QuitERGYTheme.textSecondary)

            Text(viewModel.timeSinceLastDrink)
                .font(.quitRounded(.semibold, size: 32))
                .foregroundStyle(QuitERGYTheme.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(QuitERGYTheme.cardPadding)
        .cardBackground()
        .neonGlow(color: QuitERGYTheme.accent.opacity(0.4), lineWidth: 0.6)
    }

    private var addDrinkButton: some View {
        Button {
            viewModel.isShowingResetAlert = true
        } label: {
            Text("Add Drink")
                .font(.quitRounded(.semibold, size: 18))
                .foregroundStyle(QuitERGYTheme.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: QuitERGYTheme.cardCornerRadius)
                        .fill(QuitERGYTheme.accent.opacity(0.1))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: QuitERGYTheme.cardCornerRadius)
                        .stroke(QuitERGYTheme.accent, lineWidth: 1.5)
                )
        }
        .tint(QuitERGYTheme.accent)
        .buttonStyle(.plain)
    }
}

#Preview {
    HomeView()
}
