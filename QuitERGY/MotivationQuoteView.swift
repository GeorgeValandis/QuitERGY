//
//  MotivationQuoteView.swift
//  QuitERGY
//
//  Created by Codex.
//

import SwiftUI

struct MotivationQuoteView: View {
    var quote: String

    var body: some View {
        Text(quote)
            .font(.quitRounded(.medium, size: 16))
            .foregroundStyle(QuitERGYTheme.textSecondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .cardBackground()
    }
}

#Preview {
    MotivationQuoteView(quote: "You’re taking back your energy.")
        .padding()
        .background(QuitERGYTheme.background)
}
