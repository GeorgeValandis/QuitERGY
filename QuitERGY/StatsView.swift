//
//  StatsView.swift
//  QuitERGY
//
//  Created by Codex.
//

import Charts
import SwiftData
import SwiftUI

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

                    chartSection
                    metricsSection
                }
                .padding(.horizontal, 24)
                .padding(.top, 0)
                .padding(.bottom, 32)
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
                Button("Okay", role: .cancel) {}
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
        LazyVGrid(
            columns: [
                GridItem(.flexible(minimum: 150, maximum: 200), spacing: 12),
                GridItem(.flexible(minimum: 150, maximum: 200), spacing: 12),
            ],
            spacing: 25
        ) {
            ForEach(viewModel.metrics) { metric in
                MetricBarCard(metric: metric)
                    .frame(height: 80)
            }
        }
    }

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header mit Datumsbereich und Segmented Control
            HStack {
                Text(dateRangeText)
                    .font(.quitRounded(.semibold, size: 15))
                    .foregroundStyle(QuitERGYTheme.textPrimary)

                Spacer()

                Picker("Period", selection: $viewModel.selectedPeriod) {
                    Text("Weekly").tag(TimePeriod.weekly)
                    Text("Monthly").tag(TimePeriod.monthly)
                }
                .pickerStyle(.segmented)
                .frame(width: 180)
                .onChange(of: viewModel.selectedPeriod) { _, _ in
                    viewModel.loadData()
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)

            // Statistik-Bereich
            VStack(alignment: .leading, spacing: 8) {
                Text("\(totalDrinks) \(totalDrinks == 1 ? "Drink" : "Drinks")")
                    .font(.quitRounded(.bold, size: 32))
                    .foregroundStyle(QuitERGYTheme.textPrimary)

                HStack(alignment: .center, spacing: 16) {
                    Label("\(drinksDifference) \(drinksDifference == 1 ? "drink" : "drinks") less than last month", systemImage: "clock")
                        .font(.quitRounded(.medium, size: 13))
                        .foregroundStyle(QuitERGYTheme.textSecondary)

                    Label("Under weekly target", systemImage: "info.circle")
                        .font(.quitRounded(.medium, size: 13))
                        .foregroundStyle(QuitERGYTheme.textSecondary)
                }
                .alignmentGuide(.firstTextBaseline) { d in d[.firstTextBaseline] }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)

            // Area Chart
            Chart(viewModel.progress) { point in
                AreaMark(
                    x: .value("Day", point.label),
                    y: .value("Drinks", point.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color.blue.opacity(0.4),
                            Color.blue.opacity(0.2),
                            Color.blue.opacity(0.05),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                LineMark(
                    x: .value("Day", point.label),
                    y: .value("Drinks", point.value)
                )
                .foregroundStyle(Color.blue.opacity(0.7))
                .lineStyle(StrokeStyle(lineWidth: 2.5))
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks(values: .stride(by: viewModel.selectedPeriod == .weekly ? 1 : 7)) {
                    value in
                    if let label = value.as(String.self) {
                        AxisValueLabel {
                            VStack(spacing: 4) {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 8, height: 8)
                                Text(label)
                                    .font(.quitRounded(.medium, size: 11))
                                    .foregroundStyle(QuitERGYTheme.textSecondary)
                            }
                        }
                    }
                }
            }
            .chartYAxis(.hidden)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(
            RoundedRectangle(cornerRadius: QuitERGYTheme.cardCornerRadius)
                .fill(QuitERGYTheme.surface.opacity(0.3))
        )
    }

    private var dateRangeText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let daysBack = viewModel.selectedPeriod == .weekly ? -6 : -29
        let start = Calendar.current.date(byAdding: .day, value: daysBack, to: Date()) ?? Date()
        let end = Date()
        return
            "\(formatter.string(from: start).uppercased()) - \(formatter.string(from: end).uppercased())"
    }

    private var totalDrinks: Int {
        Int(viewModel.progress.reduce(0) { $0 + $1.value })
    }

    private var drinksDifference: Int {
        6  // Placeholder - sollte aus ViewModel kommen
    }
}

private struct MetricBarCard: View {
    let metric: StatsMetric

    private var progressFraction: CGFloat {
        CGFloat(min(max(progressValue, 0), 1))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(metric.type.rawValue, systemImage: iconName)
                .font(.quitRounded(.medium, size: 12))
                .foregroundStyle(QuitERGYTheme.textSecondary)
                .lineLimit(1)

            Text(metric.formattedValue)
                .font(.quitRounded(.semibold, size: 22))
                .foregroundStyle(QuitERGYTheme.textPrimary)

            Spacer(minLength: 2)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(QuitERGYTheme.surface.opacity(0.4))
                    Capsule()
                        .fill(QuitERGYTheme.accent)
                        .frame(width: geometry.size.width * progressFraction)
                        .shadow(color: QuitERGYTheme.accent.opacity(0.35), radius: 4, y: 1)
                }
            }
            .frame(height: 6)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(12)
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
        UserProfile.self,
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
