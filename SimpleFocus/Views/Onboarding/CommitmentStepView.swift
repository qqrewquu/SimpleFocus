//
//  CommitmentStepView.swift
//  SimpleFocus
//
//  Created by Codex on 2025-10-29.
//

import SwiftUI

struct CommitmentStepView: View {
    @Binding var firstGoal: String
    @Binding var signature: String

    @FocusState private var focusedField: Field?

    enum Field {
        case goal
        case signature
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("写下今天最重要的一件事")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)

                    Text("一旦写下，就意味着向自己做出承诺。完成它，你就离目标更近一步。")
                        .font(.system(size: 17))
                        .foregroundColor(AppTheme.textSecondary)
                        .lineSpacing(4)
                }
                .padding(.horizontal, 4)

                VStack(alignment: .leading, spacing: 12) {
                    Text("我的第一个专注目标是")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)

                    TextField("例如：完成年度汇报初稿", text: $firstGoal)
                        .textFieldStyle(OnboardingTextFieldStyle())
                        .focused($focusedField, equals: .goal)
                        .submitLabel(.next)
                        .onSubmit {
                            focusedField = .signature
                        }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("签名确认")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)

                    TextField("请输入你的名字或昵称", text: $signature)
                        .textFieldStyle(OnboardingTextFieldStyle())
                        .focused($focusedField, equals: .signature)
                        .submitLabel(.done)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Label("小贴士", systemImage: "lightbulb")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppTheme.primary)

                    Text("将目标写得具体且可完成，例如：“周三前完成市场调研 PPT 的前三页”，这样在完成时更有成就感。")
                        .font(.system(size: 15))
                        .foregroundColor(AppTheme.textSecondary)
                        .lineSpacing(4)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(AppTheme.surfaceMuted)
                )
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 32)
        }
        .scrollDismissesKeyboard(.interactively)
    }
}

private struct OnboardingTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<_Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(AppTheme.surfaceElevated)
            )
            .foregroundColor(AppTheme.textPrimary)
    }
}
