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
                    ForEach(section.tasks) { task in
                        HistoryTaskRow(task: task)
                            .listRowBackground(Color.clear)
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

private struct HistoryTaskRow: View {
    let task: TaskItem

    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(AppTheme.primary.opacity(0.75))
                .frame(width: 12, height: 12)

            Text(task.content)
                .font(.system(size: 17))
                .foregroundColor(AppTheme.textPrimary)

            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.surfaceElevated)
        )
    }
}

#Preview {
    let container = try! ModelContainer(for: TaskItem.self,
                                        configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let store = TaskStore(modelContext: container.mainContext)
    let viewModel = HistoryViewModel(store: store)

    return HistoryView(viewModel: viewModel)
        .modelContainer(container)
}
