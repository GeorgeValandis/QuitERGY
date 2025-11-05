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
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.05, green: 0.08, blue: 0.15),
                        Color(red: 0.02, green: 0.05, blue: 0.12)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
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
                .shadow(color: Color(red: 0, green: 255 / 255, blue: 157 / 255).opacity(0.6), radius: 20)

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
                Text("You're on track to quit energy drinks by:")
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

            // Log drink button
            Button {
                if viewModel.selectedProfile == nil {
                    viewModel.showMissingProfileAlert = true
                } else {
                    viewModel.isShowingResetAlert = true
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "waterbottle.fill")
                        .font(.system(size: 20, weight: .semibold))
                    Text("Log Drink")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(
                    QuitERGYTheme.accent
                        .shadow(.inner(color: QuitERGYTheme.accent.opacity(0.5), radius: 8))
                )
                .clipShape(Capsule())
                .shadow(color: QuitERGYTheme.accent.opacity(0.6), radius: 16, y: 4)
            }
            .buttonStyle(.plain)
        }
    }
    
    private var activityGrid: some View {
        VStack(spacing: 12) {
            Text("Activity")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHGrid(rows: Array(repeating: GridItem(.fixed(18), spacing: 6), count: 7), spacing: 6) {
                    ForEach(0..<84, id: \.self) { index in
                        let daysAgo = 83 - index
                        let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
                        let hasDrink = viewModel.hasDrinkOn(date: date)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(hasDrink ? QuitERGYTheme.accent : Color.white.opacity(0.1))
                            .frame(width: 18, height: 18)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(hasDrink ? QuitERGYTheme.accent.opacity(0.5) : Color.white.opacity(0.15), lineWidth: 1)
                            )
                            .shadow(color: hasDrink ? QuitERGYTheme.accent.opacity(0.6) : Color.clear, radius: 4)
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 20)
            }
        }
        .padding(.horizontal, 20)
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
            return "You're building momentum! Your body is starting to adjust to life without energy drinks."
        } else if days < 30 {
            return "Impressive progress! You're breaking the habit and forming healthier patterns."
        } else if days < 60 {
            return "You're over \(days) days in! The cravings may still come, but your mind is stronger, and your willpower is greater. Stay the course and trust the process."
        } else {
            return "Outstanding achievement! You've proven your strength and commitment. Keep going!"
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
