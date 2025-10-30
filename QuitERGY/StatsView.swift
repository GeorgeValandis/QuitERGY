//
//  StatsView.swift
//  QuitERGY
//
//  Created by Codex.
//

import SwiftUI
import Charts

struct StatsView: View {
    @StateObject private var viewModel = StatsViewModel()

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    metricsSection
                    chartSection
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
            }
            .background(QuitERGYTheme.background.ignoresSafeArea())
            .navigationTitle("Stats")
            .toolbarTitleDisplayMode(.inline)
        }
    }

    private var metricsSection: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 16)], spacing: 16) {
            ForEach(viewModel.metrics) { metric in
                StatCard(metric: metric)
            }
        }
    }

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Weekly Progress")
                .font(.quitRounded(.semibold, size: 18))
                .foregroundStyle(QuitERGYTheme.textPrimary)

            Chart(viewModel.progress) { point in
                LineMark(
                    x: .value("Day", point.label),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(QuitERGYTheme.accent)
                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))

                AreaMark(
                    x: .value("Day", point.label),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(QuitERGYTheme.accent.opacity(0.25))
            }
            .frame(height: 220)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: viewModel.progress.count)) { value in
                    AxisGridLine().foregroundStyle(QuitERGYTheme.accent.opacity(0.1))
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
            .neonGlow(color: QuitERGYTheme.accent.opacity(0.45), lineWidth: 0.8)
        }
    }
}

private struct StatCard: View {
    let metric: StatsMetric

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(metric.type.rawValue, systemImage: iconName)
                .font(.quitRounded(.medium, size: 16))
                .foregroundStyle(QuitERGYTheme.textSecondary)

            Text(metric.formattedValue)
                .font(.quitRounded(.semibold, size: 28))
                .foregroundStyle(QuitERGYTheme.textPrimary)

            ProgressView(value: min(metric.value / targetValue, 1.0))
                .tint(QuitERGYTheme.accent)
                .progressViewStyle(.linear)
                .frame(height: 6)
                .clipShape(Capsule())
                .shadow(color: QuitERGYTheme.accent.opacity(0.4), radius: 8)
        }
        .padding(QuitERGYTheme.cardPadding)
        .cardBackground()
        .neonGlow()
    }

    private var iconName: String {
        switch metric.type {
        case .money: return "eurosign.circle.fill"
        case .sugar: return "cube.fill"
        case .drinks: return "bolt.fill"
        }
    }

    private var targetValue: Double {
        switch metric.type {
        case .money: return 60
        case .sugar: return 500
        case .drinks: return 40
        }
    }
}

#Preview {
    StatsView()
}
