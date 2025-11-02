//
//  LiveActivityStateBuilder.swift
//  SimpleFocus
//
//  Created by Codex on 2025-10-22.
//

import Foundation

final class LiveActivityStateBuilder {
    private let calendar: Calendar
    private let dailyLimit: Int

    init(calendar: Calendar = .current, dailyLimit: Int = TaskLimit.dailyLimit) {
        self.calendar = calendar
        self.dailyLimit = dailyLimit
    }

    func makeContentState(referenceDate: Date = Date(),
                          tasks: [TaskItem]) -> LiveActivityContentState? {
        let todaysTasks = tasks.filter { calendar.isDate($0.creationDate, inSameDayAs: referenceDate) }
        guard !todaysTasks.isEmpty else {
            return nil
        }

        let sortedTasks = todaysTasks.sorted { lhs, rhs in
            switch (lhs.isCompleted, rhs.isCompleted) {
            case (true, false):
                return true
            case (false, true):
                return false
            default:
                return lhs.creationDate < rhs.creationDate
            }
        }

        let displayedTasks = Array(sortedTasks.prefix(dailyLimit)).map {
            LiveActivityDisplayTask(id: $0.id,
                                    content: $0.content,
                                    isCompleted: $0.isCompleted)
        }

        let totalCount = todaysTasks.count
        let completedCount = todaysTasks.filter(\.isCompleted).count
        let remainingCount = totalCount - completedCount

        let progress = totalCount > 0 ? Double(completedCount) / Double(totalCount) : 0
        let statusMessage = makeStatusMessage(completed: completedCount, total: totalCount)

        return LiveActivityContentState(displayedTasks: displayedTasks,
                                        totalTasks: totalCount,
                                        completedTasks: completedCount,
                                        remainingTasks: remainingCount,
                                        progress: progress,
                                        statusMessage: statusMessage)
    }

    private func makeStatusMessage(completed: Int, total: Int) -> String {
        let taskWord = completed == 1 ? "Task" : "Tasks"
        return "Daily Focus: \(completed)/\(total) \(taskWord) Completed"
    }
}
