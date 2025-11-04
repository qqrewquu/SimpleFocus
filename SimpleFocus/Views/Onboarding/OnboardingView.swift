//
//  OnboardingView.swift
//  SimpleFocus
//
//  Created by Codex on 2025-10-29.
//

import SwiftUI

struct OnboardingView: View {
    @StateObject private var viewModel: OnboardingViewModel
    @State private var isShowingSkipAlert = false

    init(viewModel: OnboardingViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()

            VStack(spacing: 28) {
                TabView(selection: $viewModel.currentStepIndex) {
                    WelcomeStepView()
                        .tag(OnboardingViewModel.Step.welcome.rawValue)

                    GoalSelectionStepView(
                        options: viewModel.goalOptions,
                        selected: viewModel.selectedGoal,
                        onSelect: viewModel.selectGoal
                    )
                    .tag(OnboardingViewModel.Step.goalSelection.rawValue)

                    CommitmentStepView(
                        firstGoal: $viewModel.firstGoal,
                        signature: $viewModel.signature
                    )
                    .tag(OnboardingViewModel.Step.commitment.rawValue)

                    FocusCardStepView(
                        goalTitle: viewModel.trimmedFirstGoal,
                        signature: viewModel.trimmedSignature,
                        subtitle: viewModel.selectedGoalTitle,
                        quote: viewModel.focusCardQuote
                    )
                    .tag(OnboardingViewModel.Step.focusCard.rawValue)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.2), value: viewModel.currentStepIndex)
                .padding(.top, 12)

                ProgressView(value: viewModel.progressFraction)
                    .progressViewStyle(.linear)
                    .tint(AppTheme.primary)
                    .padding(.horizontal, 32)

                HStack {
                    if !viewModel.isOnFirstStep {
                        Button("返回") {
                            viewModel.goBack()
                        }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                    }

                    Spacer()

                    Button(viewModel.primaryButtonTitle) {
                        viewModel.advance()
                    }
                    .buttonStyle(PrimaryOnboardingButtonStyle())
                    .disabled(viewModel.isPrimaryActionDisabled && !viewModel.isOnFinalStep)
                }
                .padding(.horizontal, 32)
            }
            .overlay(alignment: .topTrailing) {
                if !viewModel.isOnFinalStep {
                    Button("跳过") {
                        isShowingSkipAlert = true
                    }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(AppTheme.textSecondary)
                    .padding(.trailing, 32)
                    .alert("确认跳过引导？", isPresented: $isShowingSkipAlert) {
                        Button("随时在右下角新增", role: .cancel) {
                            isShowingSkipAlert = false
                        }
                        Button("跳过", role: .destructive) {
                            isShowingSkipAlert = false
                            viewModel.skip()
                        }
                    } message: {
                        Text("你可以随时通过右下角的 + 按钮添加第一条任务。")
                    }
                }
        }
    }
}
}

private struct PrimaryOnboardingButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        PrimaryButton(configuration: configuration)
    }

    private struct PrimaryButton: View {
        @Environment(\.isEnabled) private var isEnabled
        let configuration: Configuration

        var body: some View {
            configuration.label
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(isEnabled ? AppTheme.textPrimary : AppTheme.textPrimary.opacity(0.55))
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(backgroundColor)
                )
                .opacity(isEnabled ? 1 : 0.65)
                .animation(.easeInOut(duration: 0.15), value: isEnabled)
        }

        private var backgroundColor: Color {
            if !isEnabled {
                return AppTheme.primaryDisabled
            }
            return AppTheme.primary.opacity(configuration.isPressed ? 0.7 : 1)
        }
    }
}
