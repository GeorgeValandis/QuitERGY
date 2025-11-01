//
//  HomeView.swift
//  QuitERGY
//
//  Created by Codex.
//

import SwiftData
import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel
    @State private var displayedProgress: Double = 0

    init(service: DrinkPersistenceProviding) {
        _viewModel = StateObject(wrappedValue: HomeViewModel(service: service))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                streakRing
                    .padding(.top, 8)

                sinceLastDrink

                addDrinkButton

                Spacer(minLength: 0)
            }
            .padding(.top, 32)
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(QuitERGYTheme.background.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("QuitERGY")
                        .font(.quitRounded(.semibold, size: 20))
                        .foregroundStyle(QuitERGYTheme.textPrimary)
                }
            }
        }
        .task {
            viewModel.loadData()
            withAnimation(.easeInOut(duration: 1.2)) {
                displayedProgress = viewModel.streakProgress
            }
        }
        .onChange(of: viewModel.streakProgress) { _, newValue in
            withAnimation(.easeInOut(duration: 0.8)) {
                displayedProgress = newValue
            }
        }
        .alert("Drink logged?", isPresented: $viewModel.isShowingResetAlert) {
            Button("Confirm", role: .destructive) {
                viewModel.addDrink()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Adding an energy drink will reset your current clean streak.")
        }
        .alert("Profile needed", isPresented: $viewModel.showMissingProfileAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Please create a drink profile in Settings first.")
        }
        .alert("Error", isPresented: errorBinding) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )
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

            if let profile = viewModel.selectedProfile {
                Text("Profile: \(profile.name)")
                    .font(.quitRounded(.medium, size: 14))
                    .foregroundStyle(QuitERGYTheme.textSecondary.opacity(0.8))
            } else {
                Text("No profile selected")
                    .font(.quitRounded(.medium, size: 14))
                    .foregroundStyle(QuitERGYTheme.textSecondary.opacity(0.8))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(QuitERGYTheme.cardPadding)
        .cardBackground()
    }

    private var addDrinkButton: some View {
        Button {
            if viewModel.selectedProfile == nil {
                viewModel.showMissingProfileAlert = true
            } else {
                viewModel.isShowingResetAlert = true
            }
        } label: {
            Text("Log Drink")
                .font(.quitRounded(.semibold, size: 18))
                .foregroundStyle(QuitERGYTheme.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: QuitERGYTheme.cardCornerRadius)
                        .fill(QuitERGYTheme.accent.opacity(0.2))
                )
        }
        .tint(QuitERGYTheme.accent)
        .buttonStyle(.plain)
    }
}

#Preview {
    let schema = Schema([
        DrinkProfile.self,
        DrinkLog.self,
        UserSettings.self,
        UserProfile.self,
    ])
    let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [configuration])
    let service = DrinkPersistenceService(modelContext: container.mainContext)

    let profile = DrinkProfile(
        name: "Noctra Energy",
        brand: "Velocity Labs",
        variant: .sugarFree,
        sugarGrams: 0,
        caffeineMg: 180,
        price: Decimal(string: "2.49") ?? 2.49
    )
    container.mainContext.insert(profile)
    try? service.selectProfile(profile)
    try? service.logDrink(profile, date: Date().addingTimeInterval(-3600 * 24 * 5))
    try? container.mainContext.save()

    return HomeView(service: service)
        .environment(\.drinkPersistence, service)
        .modelContainer(container)
}
