//
//  HistoryView.swift
//  SimpleFocus
//
//  Created by Codex on 2025-10-22.
//

import SwiftData
import SwiftUI

@MainActor
struct HistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: HistoryViewModel

    init(viewModel: HistoryViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("历史记录")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("完成") {
                            dismiss()
                        }
                        .foregroundColor(AppTheme.textPrimary)
                    }
                }
        }
        .background(AppTheme.background.ignoresSafeArea())
        .task {
            do {
                try await viewModel.loadHistory()
            } catch {
                assertionFailure("Failed to load history: \(error)")
            }
        }
        .refreshable {
            try? await viewModel.loadHistory()
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isEmpty {
            emptyState
        } else {
            historyList
        }
    }

    private var historyList: some View {
        List {
            ForEach(viewModel.sections) { section in
                Section {
                    ForEach(taskGroups(for: section)) { group in
                        if !group.tasks.isEmpty {
                            HistoryStatusRowHeader(status: group.status,
                                                   count: group.tasks.count)
                                .listRowInsets(EdgeInsets(top: 12, leading: 8, bottom: 4, trailing: 8))
                                .listRowBackground(Color.clear)

                            ForEach(group.tasks) { task in
                                HistoryTaskRow(task: task, status: group.status)
                                    .listRowBackground(Color.clear)
                            }
                        }
                    }
                } header: {
                    HistorySectionHeader(title: section.title,
                                         subtitle: viewModel.countDescription(for: section))
                        .padding(.bottom, 4)
                }
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(AppTheme.background)
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(AppTheme.surfaceElevated)
                    .frame(width: 120, height: 120)
                Image(systemName: "archivebox")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(AppTheme.accentGradient)
            }

            Text("暂无历史记录")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(AppTheme.accentGradient)

            Text("完成任务后，你将在这里看到每天的成果列表。")
                .font(.system(size: 17))
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.background)
    }
}

private struct HistorySectionHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(AppTheme.textPrimary)
            Text(subtitle)
                .font(.system(size: 14))
                .foregroundColor(AppTheme.textSecondary)
        }
        .padding(.top, 16)
        .padding(.horizontal, 8)
    }
}

private struct HistoryStatusRowHeader: View {
    let status: HistoryTaskStatus
    let count: Int

    var body: some View {
        HStack(spacing: 8) {
            Text(status.title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(status.tintColor)
            Text("· \(count) 条")
                .font(.system(size: 14))
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct HistoryTaskRow: View {
    let task: TaskItem
    let status: HistoryTaskStatus

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: status.iconName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(status.tintColor)
                .frame(width: 24, height: 24)
                .background(
                    Circle()
                        .fill(status.iconBackground)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(task.content)
                    .font(.system(size: 17))
                    .foregroundColor(AppTheme.textPrimary)
                Text(status.detailText)
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.textSecondary)
            }

            Spacer()
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(status.cardBackground)
        )
    }
}

private struct HistoryTaskGroup: Identifiable {
    let status: HistoryTaskStatus
    let tasks: [TaskItem]

    var id: HistoryTaskStatus { status }
}

private enum HistoryTaskStatus: Hashable {
    case completed
    case incomplete

    var title: String {
        switch self {
        case .completed:
            return "已完成"
        case .incomplete:
            return "未完成"
        }
    }

    var iconName: String {
        switch self {
        case .completed:
            return "checkmark.circle.fill"
        case .incomplete:
            return "clock.fill"
        }
    }

    var tintColor: Color {
        switch self {
        case .completed:
            return AppTheme.primary
        case .incomplete:
            return AppTheme.warning
        }
    }

    var iconBackground: Color {
        switch self {
        case .completed:
            return AppTheme.primary.opacity(0.18)
        case .incomplete:
            return AppTheme.warning.opacity(0.18)
        }
    }

    var cardBackground: Color {
        switch self {
        case .completed:
            return AppTheme.surfaceElevated
        case .incomplete:
            return AppTheme.surfaceMuted
        }
    }

    var detailText: String {
        switch self {
        case .completed:
            return "状态：已完成"
        case .incomplete:
            return "状态：未完成"
        }
    }
}

private func taskGroups(for section: HistorySection) -> [HistoryTaskGroup] {
    var groups: [HistoryTaskGroup] = []
    if !section.incompleteTasks.isEmpty {
        groups.append(HistoryTaskGroup(status: .incomplete,
                                       tasks: section.incompleteTasks))
    }
    if !section.completedTasks.isEmpty {
        groups.append(HistoryTaskGroup(status: .completed,
                                       tasks: section.completedTasks))
    }
    return groups
}

#Preview {
    let container = try! ModelContainer(for: TaskItem.self,
                                        configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let store = TaskStore(modelContext: container.mainContext)
    let viewModel = HistoryViewModel(store: store)

    return HistoryView(viewModel: viewModel)
        .modelContainer(container)
}
