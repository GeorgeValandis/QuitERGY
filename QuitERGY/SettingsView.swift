//
//  SettingsView.swift
//  QuitERGY
//
//  Created by Codex.
//

import SwiftUI

struct SettingsView: View {
    @State private var isPresentingResetAlert = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 16) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 36, weight: .semibold))
                            .foregroundStyle(QuitERGYTheme.accent)
                            .frame(width: 64, height: 64)
                            .background(
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(QuitERGYTheme.accent.opacity(0.12))
                            )

                        VStack(alignment: .leading, spacing: 6) {
                            Text("QuitERGY ⚡️")
                                .font(.quitRounded(.semibold, size: 20))
                            Text("A calmer path away from energy drinks.")
                                .font(.quitRounded(.medium, size: 15))
                                .foregroundStyle(QuitERGYTheme.textSecondary)
                        }
                    }
                    .listRowBackground(QuitERGYTheme.background)
                }

                Section("About") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("We’re building a supportive space to help you stay off energy drinks. Track your wins, keep your energy clean, and celebrate every milestone.")
                            .font(.quitRounded(.medium, size: 15))
                            .foregroundStyle(QuitERGYTheme.textSecondary)

                        Button {
                            // Placeholder for support action
                        } label: {
                            Label("Contact Support", systemImage: "paperplane.fill")
                                .font(.quitRounded(.semibold, size: 16))
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(QuitERGYTheme.accent)
                    }
                    .padding(.vertical, 8)
                    .listRowBackground(QuitERGYTheme.background)
                }

                Section {
                    Button(role: .destructive) {
                        isPresentingResetAlert = true
                    } label: {
                        Label("Reset Progress", systemImage: "arrow.counterclockwise")
                            .font(.quitRounded(.semibold, size: 16))
                    }
                    .listRowBackground(QuitERGYTheme.background)
                }
            }
            .scrollContentBackground(.hidden)
            .listStyle(.insetGrouped)
            .background(QuitERGYTheme.background)
            .navigationTitle("Settings")
            .alert("Reset all progress?", isPresented: $isPresentingResetAlert) {
                Button("Reset", role: .destructive) { }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will clear your streak and statistics. This action cannot be undone.")
            }
        }
    }
}

#Preview {
    SettingsView()
}
