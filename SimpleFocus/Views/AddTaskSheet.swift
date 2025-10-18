//
//  AddTaskSheet.swift
//  SimpleFocus
//
//  Created by Codex on 2025-10-17.
//

import SwiftData
import SwiftUI

struct AddTaskSheet: View {
    @ObservedObject var viewModel: AddTaskViewModel
    var limitState: EncouragementMessage?
    var onTaskCreated: (TaskItem) -> Void

    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Capsule()
                .fill(Color.white.opacity(0.2))
                .frame(width: 40, height: 4)
                .frame(maxWidth: .infinity)
                .padding(.top, 8)

            Text("新增专注任务")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(AppTheme.textPrimary)

            VStack(alignment: .leading, spacing: 8) {
                TextField("输入任务（最多20字）", text: $viewModel.content)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(AppTheme.background.opacity(0.6))
                    .cornerRadius(14)
                    .foregroundColor(AppTheme.textPrimary)
                    .submitLabel(.done)

                Text("建议：任务保持在20字以内，以便锁屏显示。")
                    .font(.footnote)
                    .foregroundColor(AppTheme.textSecondary)

                if let limitState {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(limitState.message)
                            .font(.footnote)
                            .foregroundColor(.red.opacity(0.85))
                        Text(limitState.encouragement)
                            .font(.footnote)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    .multilineTextAlignment(.leading)
                }

                HStack {
                    Spacer()
                    Text("\(viewModel.content.count)/\(AddTaskViewModel.maxLength)")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }
            }

            if let error = errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundColor(.red.opacity(0.8))
            }

            Button(action: submit) {
                Text("确认")
                    .font(.system(size: 18, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(submitEnabled ? AppTheme.primary : AppTheme.primary.opacity(0.4))
                    .foregroundColor(AppTheme.textPrimary)
                    .cornerRadius(18)
            }
            .disabled(!submitEnabled)

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
        .background(AppTheme.background)
    }

    private var submitEnabled: Bool {
        viewModel.canSubmit && limitState == nil
    }

    private func submit() {
        do {
            let task = try viewModel.submit()
            errorMessage = nil
            onTaskCreated(task)
        } catch TaskInputError.emptyContent {
            errorMessage = "请输入任务内容"
        } catch TaskInputError.limitReached {
            errorMessage = "今天的三项任务已满，暂无法再添加"
        } catch {
            errorMessage = "发生未知错误，请重试"
        }
    }
}

#Preview("Add Task Sheet") {
    let schema = Schema([TaskItem.self])
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: configuration)
    let store = TaskStore(modelContext: container.mainContext)
    let viewModel = AddTaskViewModel(store: store)
    return AddTaskSheet(viewModel: viewModel, limitState: nil) { _ in }
        .modelContainer(container)
}

#Preview("Add Task Sheet - Limit Reached") {
    let schema = Schema([TaskItem.self])
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: configuration)
    let store = TaskStore(modelContext: container.mainContext)
    let viewModel = AddTaskViewModel(store: store)
    let limit = EncouragementMessage(message: "今日三件大事已妥善安排。",
                                     encouragement: "好好休息，为明天充电。")
    return AddTaskSheet(viewModel: viewModel, limitState: limit) { _ in }
        .modelContainer(container)
}
