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
        let completedTasks = try await store.fetchCompletedTasks()
        guard !completedTasks.isEmpty else {
            sections = []
            return
        }

        let grouped = Dictionary(grouping: completedTasks) { task in
            calendar.startOfDay(for: task.creationDate)
        }

        let orderedDates = grouped.keys.sorted(by: >)

        sections = orderedDates.map { date in
            let tasks = (grouped[date] ?? [])
                .sorted { $0.creationDate < $1.creationDate }
            let title = dateFormatter.string(from: date)
            return HistorySection(id: date, date: date, title: title, tasks: tasks)
        }
    }

    func countDescription(for section: HistorySection) -> String {
        let count = section.tasks.count
        return "\(count) 条完成记录"
    }
}

struct HistorySection: Identifiable, Equatable {
    let id: Date
    let date: Date
    let title: String
    let tasks: [TaskItem]
}

private extension HistoryViewModel {
    static func makeDefaultFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }
}
