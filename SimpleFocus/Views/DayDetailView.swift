//
//  DayDetailView.swift
//  SimpleFocus
//
//  Created by Codex on 2025-10-29.
//

import SwiftUI

struct DayDetailView: View {
    let date: Date
    let tasks: [TaskItem]
    let titleText: String

    private var completedTasks: [TaskItem] {
        tasks.filter(\.isCompleted)
    }

    private var incompleteTasks: [TaskItem] {
        tasks.filter { !$0.isCompleted }
    }

    private var summaryText: String {
        "已完成: \(completedTasks.count) | 未完成: \(incompleteTasks.count)"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                summary
                taskSection(title: "已完成任务", tasks: completedTasks, accent: AppTheme.primary, icon: "checkmark.circle.fill")
                taskSection(title: "未完成任务", tasks: incompleteTasks, accent: AppTheme.warning, icon: "circle")

                if tasks.isEmpty {
                    emptyState
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 32)
        }
        .background(AppTheme.background.ignoresSafeArea())
    }

    private var header: some View {
        Text(titleText)
            .font(.system(size: 20, weight: .bold))
            .foregroundColor(AppTheme.textPrimary)
    }

    private var summary: some View {
        Text(summaryText)
            .font(.system(size: 15, weight: .medium))
            .foregroundColor(AppTheme.textSecondary)
    }

    private func taskSection(title: String,
                             tasks: [TaskItem],
                             accent: Color,
                             icon: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if !tasks.isEmpty {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(accent)

                ForEach(tasks) { task in
                    DayDetailTaskRow(task: task, accent: accent, icon: icon)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("当日暂无任务记录")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(AppTheme.textPrimary)
            Text("保持专注，明天继续创造进步吧。")
                .font(.system(size: 15))
                .foregroundColor(AppTheme.textSecondary)
        }
    }
}

private struct DayDetailTaskRow: View {
    let task: TaskItem
    let accent: Color
    let icon: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(accent)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(accent.opacity(0.15))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(task.content)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppTheme.textPrimary)
                Text(task.creationDate, style: .time)
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.textSecondary)
            }

            Spacer()
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.surfaceElevated)
        )
    }
}
