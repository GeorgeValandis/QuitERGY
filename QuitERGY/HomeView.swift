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
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    streakRing
                        .padding(.top, 20)

                    activityGrid
                        .padding(.top, -16)

                    motivationalSection

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 120)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(QuitERGYTheme.background.ignoresSafeArea())
            .navigationTitle("Overview")
            .navigationBarTitleDisplayMode(.inline)
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
        .alert("Change to No Drink?", isPresented: $viewModel.showChangeToNoDrinkAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Yes, No Drink", role: .destructive) {
                viewModel.confirmLogNoDrink()
            }
        } message: {
            Text(
                "You already logged drinks today. Do you want to change to 'No Drink'? This will delete all drink logs for today."
            )
        }
        .alert("Change to Drink?", isPresented: $viewModel.showChangeToDrinkAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Yes, Log Drink", role: .destructive) {
                viewModel.confirmAddDrink()
            }
        } message: {
            Text(
                "You already logged 'No Drink' today. Do you want to change and log a drink instead?"
            )
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
            // Background circle
            Circle()
                .stroke(
                    Color.white.opacity(0.1),
                    lineWidth: 20
                )

            // Progress circle with accent color
            Circle()
                .trim(from: 0, to: displayedProgress)
                .stroke(
                    Color(red: 0, green: 255 / 255, blue: 157 / 255),
                    style: StrokeStyle(lineWidth: 20, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(
                    color: Color(red: 0, green: 255 / 255, blue: 157 / 255).opacity(0.6), radius: 20
                )

            // Inner content
            VStack(spacing: 8) {
                Text("RECOVERY")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
                    .tracking(1.5)

                Text("\(Int(displayedProgress * 100))%")
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("\(viewModel.streakDays)D STREAK")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
                    .tracking(0.8)
            }
        }
        .frame(width: 240, height: 240)
    }

    private var motivationalSection: some View {
        VStack(spacing: 24) {
            // Target date section
            VStack(spacing: 8) {
                Text(streakMessage)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)

                Text(targetDate)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.white.opacity(0.1))
                    )
            }

            // Action buttons
            HStack(spacing: 12) {
                // Log Drink button (red)
                Button {
                    if viewModel.selectedProfile == nil {
                        viewModel.showMissingProfileAlert = true
                    } else {
                        viewModel.isShowingResetAlert = true
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "waterbottle.fill")
                            .font(.system(size: 18, weight: .semibold))
                        Text("Log Drink")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity)
                    .background(
                        Color.red
                            .shadow(.inner(color: Color.red.opacity(0.5), radius: 8))
                    )
                    .clipShape(Capsule())
                    .shadow(color: Color.red.opacity(0.6), radius: 16, y: 4)
                }
                .buttonStyle(.plain)

                // No Drink button (green)
                Button {
                    if viewModel.selectedProfile == nil {
                        viewModel.showMissingProfileAlert = true
                    } else {
                        viewModel.logNoDrink()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18, weight: .semibold))
                        Text("No Drink")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity)
                    .background(
                        Color.green
                            .shadow(.inner(color: Color.green.opacity(0.5), radius: 8))
                    )
                    .clipShape(Capsule())
                    .shadow(color: Color.green.opacity(0.6), radius: 16, y: 4)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
        }
    }

    private var activityGrid: some View {
        VStack(spacing: 12) {
            Text("Activity")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHGrid(
                    rows: Array(repeating: GridItem(.fixed(18), spacing: 6), count: 7), spacing: 6
                ) {
                    ForEach(0..<84, id: \.self) { index in
                        let daysAgo = 83 - index
                        let date =
                            Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())
                            ?? Date()
                        let dayStatus = viewModel.getDayStatus(for: date)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(fillColor(for: dayStatus))
                            .frame(width: 18, height: 18)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(strokeColor(for: dayStatus), lineWidth: 1)
                            )
                            .shadow(color: shadowColor(for: dayStatus), radius: 4)
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 20)
            }
        }
        .padding(.horizontal, 20)
    }

    private func fillColor(for status: HomeViewModel.DayStatus) -> Color {
        switch status {
        case .noDrink:
            return Color.green
        case .hadDrinks(let count):
            return redColor(for: count)
        case .noEntry:
            return Color.white.opacity(0.1)
        }
    }

    private func strokeColor(for status: HomeViewModel.DayStatus) -> Color {
        switch status {
        case .noDrink:
            return Color.green.opacity(0.5)
        case .hadDrinks(let count):
            return redColor(for: count).opacity(0.5)
        case .noEntry:
            return Color.white.opacity(0.15)
        }
    }

    private func shadowColor(for status: HomeViewModel.DayStatus) -> Color {
        switch status {
        case .noDrink:
            return Color.green.opacity(0.6)
        case .hadDrinks(let count):
            return redColor(for: count).opacity(0.6)
        case .noEntry:
            return Color.clear
        }
    }

    private func redColor(for drinkCount: Int) -> Color {
        // Gradient from light red (1 drink) to dark red (5+ drinks)
        switch drinkCount {
        case 1:
            return Color(red: 1.0, green: 0.4, blue: 0.4)  // Light red
        case 2:
            return Color(red: 0.95, green: 0.3, blue: 0.3)  // Medium-light red
        case 3:
            return Color(red: 0.9, green: 0.2, blue: 0.2)  // Medium red
        case 4:
            return Color(red: 0.8, green: 0.15, blue: 0.15)  // Medium-dark red
        default:  // 5+
            return Color(red: 0.7, green: 0.1, blue: 0.1)  // Dark red
        }
    }

    private var streakMessage: String {
        // Check if user logged a drink today
        let today = Calendar.current.startOfDay(for: Date())
        let hasDrinkToday = viewModel.recentLogs.contains { log in
            Calendar.current.startOfDay(for: log.timestamp) == today && !log.isNoDrink
        }

        if hasDrinkToday {
            return "Your 90-day goal has been adjusted to:"
        } else {
            return "You're on track to reach your 90-day goal by:"
        }
    }

    private var targetDate: String {
        let calendar = Calendar.current
        let targetDays = 90 - viewModel.streakDays
        if targetDays > 0 {
            let targetDate = calendar.date(byAdding: .day, value: targetDays, to: Date()) ?? Date()
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d, yyyy"
            return formatter.string(from: targetDate)
        }
        return "Goal achieved!"
    }

    private var motivationalMessage: String {
        let days = viewModel.streakDays
        if days == 0 {
            return "Every journey begins with a single step. You've got this!"
        } else if days < 7 {
            return "Great start! The first week is the hardest, but you're already making progress."
        } else if days < 14 {
            return
                "You're building momentum! Your body is starting to adjust to life without energy drinks."
        } else if days < 30 {
            return "Impressive progress! You're breaking the habit and forming healthier patterns."
        } else if days < 60 {
            return
                "You're over \(days) days in! The cravings may still come, but your mind is stronger, and your willpower is greater. Stay the course and trust the process."
        } else {
            return
                "Outstanding achievement! You've proven your strength and commitment. Keep going!"
        }
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
