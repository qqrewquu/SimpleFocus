//
//  FocusCardStepView.swift
//  SimpleFocus
//
//  Created by Codex on 2025-10-29.
//

import SwiftUI

struct FocusCardStepView: View {
    let goalTitle: String
    let signature: String
    let subtitle: String
    let quote: (quote: String, author: String)

    var body: some View {
        VStack(spacing: 28) {
            Spacer(minLength: 24)

            Text("太棒了！你的专注旅程即将开始")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(AppTheme.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)

            Text("这是你为自己做出的承诺卡片。今天就从这个目标开始，完成后别忘了回来打卡。")
                .font(.system(size: 17))
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 24)

            FocusCard(goalTitle: goalTitle, signature: signature, subtitle: subtitle)
                .padding(.horizontal, 16)

            QuoteBlock(quote: quote.quote, author: quote.author)
                .padding(.horizontal, 36)

            Spacer()
            Spacer()
        }
    }
}

private struct FocusCard: View {
    let goalTitle: String
    let signature: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .center, spacing: 16) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(AppTheme.accentGradient)

                VStack(alignment: .leading, spacing: 6) {
                    Text("今日专注目标")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppTheme.textSecondary)

                    Text(subtitle)
                        .font(.system(size: 15))
                        .foregroundColor(AppTheme.textSecondary.opacity(0.8))
                }
            }

            Text(goalTitle.isEmpty ? "为自己的目标写下一个清晰描述" : goalTitle)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(AppTheme.textPrimary)
                .lineSpacing(4)

            HStack {
                Spacer()
                Text(signature.isEmpty ? "署名等待填写" : "—— \(signature)")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
        .padding(28)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(AppTheme.surfaceElevated)
                .shadow(color: Color.black.opacity(0.35), radius: 18, x: 0, y: 16)
        )
        .overlay(
            AppTheme.accentGradient
                .opacity(0.25)
                .mask(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(AppTheme.primary.opacity(0.4), lineWidth: 1.2)
        )
    }
}

private struct QuoteBlock: View {
    let quote: String
    let author: String

    var body: some View {
        VStack(spacing: 8) {
            Text(quote)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
            Text(author)
                .font(.system(size: 13))
                .foregroundColor(AppTheme.textSecondary.opacity(0.7))
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppTheme.surfaceMuted)
        )
    }
}
