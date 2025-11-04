//
//  OnboardingViewModel.swift
//  SimpleFocus
//
//  Created by Codex on 2025-10-29.
//

import Combine
import Foundation
import SwiftUI

@MainActor
final class OnboardingViewModel: ObservableObject {
    enum Step: Int, CaseIterable {
        case welcome
        case goalSelection
        case commitment
        case focusCard

        var title: String {
            switch self {
            case .welcome:
                return "欢迎"
            case .goalSelection:
                return "选择目标"
            case .commitment:
                return "承诺"
            case .focusCard:
                return "专注卡片"
            }
        }

        var message: String {
            switch self {
            case .welcome:
                return "了解 SimpleFocus 的专注理念。"
            case .goalSelection:
                return "挑选最符合你痛点的专注方向。"
            case .commitment:
                return "写下当下最重要的目标与签名。"
            case .focusCard:
                return "生成你的专属专注卡片并开启新一天。"
            }
        }
    }

    struct GoalOption: Identifiable, Equatable {
        let id = UUID()
        let icon: String
        let title: String
        let subtitle: String
    }

    @Published var currentStepIndex: Int = Step.welcome.rawValue {
        didSet {
            if currentStepIndex > maxUnlockedStepIndex {
                currentStepIndex = oldValue
            }
        }
    }
    @Published var selectedGoal: GoalOption?
    @Published var firstGoal: String = ""
    @Published var signature: String = ""

    private(set) var maxUnlockedStepIndex: Int
    let goalOptions: [GoalOption]

    var currentStep: Step {
        Step(rawValue: currentStepIndex) ?? .welcome
    }

    var isOnFirstStep: Bool {
        currentStepIndex == Step.welcome.rawValue
    }

    var isOnFinalStep: Bool {
        currentStepIndex == Step.focusCard.rawValue
    }

    var primaryButtonTitle: String {
        isOnFinalStep ? "开始使用 SimpleFocus" : "继续"
    }

    var progressFraction: Double {
        let total = Double(Step.allCases.count)
        return (Double(currentStepIndex) + 1.0) / total
    }

    var trimmedFirstGoal: String {
        firstGoal.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedSignature: String {
        signature.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var selectedGoalTitle: String {
        selectedGoal?.title ?? "专注你的重点事项"
    }

    var isPrimaryActionDisabled: Bool {
        switch currentStep {
        case .welcome:
            return false
        case .goalSelection:
            return selectedGoal == nil
        case .commitment:
            return trimmedFirstGoal.isEmpty || trimmedSignature.isEmpty
        case .focusCard:
            return false
        }
    }

    var focusCardSubtitle: String {
        selectedGoal?.subtitle ?? "坚持专注，让每天都有值得记录的成果。"
    }

    var focusCardQuote: (quote: String, author: String) {
        (
            "\"The key is not to prioritize what's on your schedule, but to schedule your priorities.\"",
            "—— Stephen R. Covey"
        )
    }

    private let onFinish: (String) -> Void
    private let onSkip: () -> Void

    init(onFinish: @escaping (String) -> Void,
         onSkip: @escaping () -> Void) {
        self.onFinish = onFinish
        self.onSkip = onSkip
        self.goalOptions = [
            GoalOption(icon: "target", title: "我想每天保持专注", subtitle: "减少分心，聚焦最关键的 2-3 件事"),
            GoalOption(icon: "clock.badge.checkmark", title: "我想按时完成重要任务", subtitle: "规划关键节点，避免最后一刻的压力"),
            GoalOption(icon: "heart.text.square", title: "我想兼顾工作与生活", subtitle: "留出时间照顾健康与家人"),
            GoalOption(icon: "sparkles", title: "我想建立好习惯", subtitle: "通过每天的小步骤累积长期成就")
        ]
        self.maxUnlockedStepIndex = Step.welcome.rawValue
    }

    func selectGoal(_ option: GoalOption) {
        selectedGoal = option
    }

    func advance() {
        guard let step = Step(rawValue: currentStepIndex) else {
            return
        }

        switch step {
        case .commitment:
            firstGoal = trimmedFirstGoal
            signature = trimmedSignature
        default:
            break
        }

        if step == .focusCard {
            finish()
            return
        }

        if let next = Step(rawValue: step.rawValue + 1) {
            let nextIndex = next.rawValue
            maxUnlockedStepIndex = max(maxUnlockedStepIndex, nextIndex)
            withAnimation(.easeInOut(duration: 0.25)) {
                currentStepIndex = nextIndex
            }
        }
    }

    func goBack() {
        guard let step = Step(rawValue: currentStepIndex),
              let previous = Step(rawValue: step.rawValue - 1) else {
            return
        }

        withAnimation(.easeInOut(duration: 0.25)) {
            currentStepIndex = previous.rawValue
        }
    }

    func skip() {
        maxUnlockedStepIndex = Step.focusCard.rawValue
        onSkip()
    }

    func finish() {
        maxUnlockedStepIndex = Step.focusCard.rawValue
        onFinish(trimmedFirstGoal)
    }
}
