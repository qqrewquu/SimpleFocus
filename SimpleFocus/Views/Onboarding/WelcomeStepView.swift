//
//  WelcomeStepView.swift
//  SimpleFocus
//
//  Created by Codex on 2025-10-29.
//

import SwiftUI

struct WelcomeStepView: View {
    @Environment(\.themePalette) private var theme
    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 20) {
                Image(systemName: "sparkles")
                    .font(.system(size: 72, weight: .regular))
                    .foregroundStyle(theme.accentGradient)

                Text("欢迎使用 SimpleFocus")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(theme.textPrimary)

            Text("我们相信真正的效率源自专注。每天锁定 2-3 件最重要的任务，让你在忙碌中依旧保持节奏与成就感。")
                    .font(.system(size: 18))
                    .foregroundColor(theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .padding(.horizontal, 8)
            }

            FeatureHighlight(
                iconName: "checkmark.circle",
                title: "少而精的待办",
                description: "每天只聚焦最重要的 2-3 件事，避免被冗长列表淹没。"
            )

            FeatureHighlight(
                iconName: "sparkles",
                title: "锁屏实时提醒",
                description: "通过 Live Activity 与 Widget，将待办任务贴在眼前。"
            )

            FeatureHighlight(
                iconName: "bolt",
                title: "完成反馈与激励",
                description: "完成当天任务后获得奖励语与励志卡片，让坚持更有成就感。"
            )

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

private struct FeatureHighlight: View {
    let iconName: String
    let title: String
    let description: String
    @Environment(\.themePalette) private var theme

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: iconName)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(theme.accentGradient)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(theme.textPrimary)
                Text(description)
                    .font(.system(size: 16))
                    .foregroundColor(theme.textSecondary)
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(theme.surfaceElevated)
        )
    }
}
