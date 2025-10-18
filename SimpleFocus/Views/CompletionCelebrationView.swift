//
//  CompletionCelebrationView.swift
//  SimpleFocus
//
//  Created by Codex on 2025-10-17.
//

import SwiftUI

struct CompletionCelebrationView: View {
    let celebration: CompletionCelebration
    var onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Capsule()
                .fill(Color.white.opacity(0.25))
                .frame(width: 40, height: 4)
                .padding(.top, 12)

            Text(celebration.title)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(AppTheme.textPrimary)
                .multilineTextAlignment(.center)

            VStack(spacing: 12) {
                Text("“\(celebration.quote.text)”")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)

                Text("— \(celebration.quote.author)")
                    .font(.system(size: 16))
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            Button(action: onDismiss) {
                Text("继续保持专注")
                    .font(.system(size: 18, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppTheme.primary)
                    .foregroundColor(AppTheme.textPrimary)
                    .cornerRadius(18)
            }

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
        .background(AppTheme.background)
    }
}

#Preview("Completion Celebration") {
    CompletionCelebrationView(
        celebration: CompletionCelebration(
            title: "恭喜完成全部任务！",
            quote: CelebrationQuote(text: "Stay hungry, stay foolish.", author: "Steve Jobs")
        )
    ) {}
}
