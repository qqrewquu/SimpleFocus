//
//  HistoryViewModel.swift
//  SimpleFocus
//
//  Created by Codex on 2025-10-21.
//

import Foundation
import Combine

@MainActor
final class HistoryViewModel: ObservableObject {
    @Published private(set) var sections: [HistorySection] = []

    var isEmpty: Bool {
        sections.isEmpty
    }

    private let store: TaskStore
    private let calendar: Calendar
    private let dateFormatter: DateFormatter

    init(store: TaskStore,
         calendar: Calendar = .current,
         dateFormatter: DateFormatter? = nil) {
        self.store = store
        self.calendar = calendar
        self.dateFormatter = dateFormatter ?? HistoryViewModel.makeDefaultFormatter()
    }

    func loadHistory() async throws {
        let tasks = try await store.fetchAllTasks()
        guard !tasks.isEmpty else {
            sections = []
            return
        }

        let grouped = Dictionary(grouping: tasks) { task in
            calendar.startOfDay(for: task.creationDate)
        }

        let orderedDates = grouped.keys.sorted(by: >)

        sections = orderedDates.map { date in
            let tasksForDate = (grouped[date] ?? [])
                .sorted { $0.creationDate < $1.creationDate }
            let title = dateFormatter.string(from: date)
            let completed = tasksForDate.filter(\.isCompleted)
            let incomplete = tasksForDate.filter { !$0.isCompleted }
            return HistorySection(id: date,
                                  date: date,
                                  title: title,
                                  completedTasks: completed,
                                  incompleteTasks: incomplete)
        }
    }

    func countDescription(for section: HistorySection) -> String {
        var components: [String] = []
        if section.completedTasks.isEmpty == false {
            components.append("已完成 · \(section.completedTasks.count) 条")
        }
        if section.incompleteTasks.isEmpty == false {
            components.append("未完成 · \(section.incompleteTasks.count) 条")
        }
        if components.isEmpty {
            return "暂无记录"
        }
        return components.joined(separator: "  |  ")
    }
}

struct HistorySection: Identifiable, Equatable {
    let id: Date
    let date: Date
    let title: String
    let completedTasks: [TaskItem]
    let incompleteTasks: [TaskItem]
}

private extension HistoryViewModel {
    static func makeDefaultFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }
}
