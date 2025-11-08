//
//  GoalSelectionStepView.swift
//  SimpleFocus
//
//  Created by Codex on 2025-10-29.
//

import SwiftUI

struct GoalSelectionStepView: View {
    let options: [OnboardingViewModel.GoalOption]
    let selected: OnboardingViewModel.GoalOption?
    let onSelect: (OnboardingViewModel.GoalOption) -> Void
    @Environment(\.themePalette) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Spacer(minLength: 12)

            VStack(alignment: .leading, spacing: 12) {
                Text("选择你最想改善的方向")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(theme.textPrimary)

                Text("我们会围绕你的选择，为接下来的体验提供更聚焦的建议。")
                    .font(.system(size: 17))
                    .foregroundColor(theme.textSecondary)
            }
            .padding(.horizontal, 4)

            VStack(spacing: 14) {
                ForEach(options) { option in
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            onSelect(option)
                        }
                    } label: {
                        GoalCard(option: option, isSelected: option.id == selected?.id)
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

private struct GoalCard: View {
    let option: OnboardingViewModel.GoalOption
    let isSelected: Bool
    @Environment(\.themePalette) private var theme

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: option.icon)
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(theme.accentGradient)
                .frame(width: 34, height: 34)

            VStack(alignment: .leading, spacing: 8) {
                Text(option.title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(theme.textPrimary)

                Text(option.subtitle)
                    .font(.system(size: 15))
                    .foregroundColor(theme.textSecondary)
                    .multilineTextAlignment(.leading)
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(theme.primary)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(theme.surfaceElevated.opacity(isSelected ? 1 : 0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(isSelected ? theme.primary : Color.white.opacity(0.06), lineWidth: isSelected ? 2 : 1)
                )
                .shadow(color: isSelected ? theme.primary.opacity(0.25) : .clear,
                        radius: isSelected ? 14 : 0,
                        x: 0,
                        y: 8)
        )
        .scaleEffect(isSelected ? 1.02 : 1.0)
    }
}
