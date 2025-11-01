//
//  StatsView.swift
//  QuitERGY
//
//  Created by Codex.
//

import SwiftUI
import Charts
import SwiftData

struct StatsView: View {
    @StateObject private var viewModel: StatsViewModel

    init(service: DrinkPersistenceProviding) {
        _viewModel = StateObject(wrappedValue: StatsViewModel(service: service))
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    if viewModel.selectedProfile == nil {
                        missingProfileCard
                    }

                    metricsSection
                    chartSection
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
            }
            .background(QuitERGYTheme.background.ignoresSafeArea())
            .navigationTitle("Stats")
            .toolbarTitleDisplayMode(.inline)
#if DEBUG
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("3 Tage ohne Drinks") {
                            viewModel.simulateNoDrinks(forDays: 3)
                        }
                        Button("7 Tage ohne Drinks") {
                            viewModel.simulateNoDrinks(forDays: 7)
                        }
                        Button("14 Tage ohne Drinks") {
                            viewModel.simulateNoDrinks(forDays: 14)
                        }
                        Divider()
                        Button("Simulation zurücksetzen") {
                            viewModel.clearSimulation()
                        }
                    } label: {
                        Image(systemName: "timeline.selection")
                    }
                }
            }
#endif
            .task {
                viewModel.loadData()
            }
            .alert("Fehler", isPresented: errorBinding) {
                Button("Okay", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )
    }

    private var missingProfileCard: some View {
        VStack(spacing: 12) {
            Text("No profile selected")
                .font(.quitRounded(.semibold, size: 18))
                .foregroundStyle(QuitERGYTheme.textPrimary)
            Text("Create a drink profile in Settings to see savings and progress.")
                .font(.quitRounded(.medium, size: 14))
                .foregroundStyle(QuitERGYTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(20)
        .cardBackground()
    }

    private var metricsSection: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 16)], spacing: 16) {
            ForEach(viewModel.metrics) { metric in
                MetricBarCard(metric: metric)
            }
        }
    }

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Weekly Drinks Logged")
                .font(.quitRounded(.semibold, size: 18))
                .foregroundStyle(QuitERGYTheme.textPrimary)

            Chart(viewModel.progress) { point in
                BarMark(
                    x: .value("Day", point.label),
                    y: .value("Drinks", point.value)
                )
                .foregroundStyle(QuitERGYTheme.accent)
                .cornerRadius(8)
                .annotation(position: .top, alignment: .center) {
                    if point.value > 0 {
                        Text("\(Int(point.value))")
                            .font(.quitRounded(.medium, size: 12))
                            .foregroundStyle(QuitERGYTheme.textSecondary)
                    }
                }
            }
            .frame(height: 220)
            .chartXAxis {
                AxisMarks(values: viewModel.progress.map(\.label)) { value in
                    AxisValueLabel()
                        .foregroundStyle(QuitERGYTheme.textSecondary)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine().foregroundStyle(QuitERGYTheme.accent.opacity(0.1))
                    AxisValueLabel()
                        .foregroundStyle(QuitERGYTheme.textSecondary)
                }
            }
            .padding()
            .cardBackground()
        }
    }
}

private struct MetricBarCard: View {
    let metric: StatsMetric

    private var progressFraction: CGFloat {
        CGFloat(min(max(progressValue, 0), 1))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(metric.type.rawValue, systemImage: iconName)
                .font(.quitRounded(.medium, size: 16))
                .foregroundStyle(QuitERGYTheme.textSecondary)

            Text(metric.formattedValue)
                .font(.quitRounded(.semibold, size: 28))
                .foregroundStyle(QuitERGYTheme.textPrimary)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(QuitERGYTheme.surface.opacity(0.4))
                    Capsule()
                        .fill(QuitERGYTheme.accent)
                        .frame(width: geometry.size.width * progressFraction)
                        .shadow(color: QuitERGYTheme.accent.opacity(0.35), radius: 6, y: 2)
                }
            }
            .frame(height: 10)
        }
        .padding(QuitERGYTheme.cardPadding)
        .cardBackground()
    }

    private var iconName: String {
        switch metric.type {
        case .money: return "eurosign.circle.fill"
        case .sugar: return "cube.fill"
        case .drinks: return "bolt.fill"
        }
    }

    private var progressValue: Double {
        let goal: Double
        switch metric.type {
        case .money: goal = 100
        case .sugar: goal = 500
        case .drinks: goal = 30
        }
        guard goal > 0 else { return 0 }
        return min(metric.value / goal, 1.0)
    }
}

#Preview {
    let schema = Schema([
        DrinkProfile.self,
        DrinkLog.self,
        UserSettings.self,
        UserProfile.self
    ])
    let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [configuration])
    let service = DrinkPersistenceService(modelContext: container.mainContext)

    let profile = DrinkProfile(
        name: "Noctra Energy",
        brand: "Velocity Labs",
        variant: .classic,
        sugarGrams: 34,
        caffeineMg: 160,
        price: Decimal(string: "2.49") ?? 2.49
    )
    container.mainContext.insert(profile)
    try? service.selectProfile(profile)
    for dayOffset in 0..<5 {
        if let date = Calendar.current.date(byAdding: .day, value: -dayOffset, to: Date()) {
            try? service.logDrink(profile, date: date)
        }
    }
    try? container.mainContext.save()

    return StatsView(service: service)
        .environment(\.drinkPersistence, service)
        .modelContainer(container)
}
