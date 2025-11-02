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

        let incompleteTasks = todaysTasks
            .filter { !$0.isCompleted }
            .sorted { $0.creationDate < $1.creationDate }

        let visibleIncomplete = Array(incompleteTasks.prefix(dailyLimit))
        let visibleRemaining = visibleIncomplete.count

        guard visibleRemaining > 0 else {
            return nil
        }

        let completedCount = todaysTasks.filter(\.isCompleted).count
        let totalCount = visibleRemaining + completedCount

        let displayedTasks = visibleIncomplete.map {
            LiveActivityDisplayTask(id: $0.id,
                                    content: $0.content,
                                    isCompleted: false)
        }

        let progress = totalCount > 0 ? Double(completedCount) / Double(totalCount) : 0
        let statusMessage = makeStatusMessage(remaining: visibleRemaining, total: totalCount)

        return LiveActivityContentState(displayedTasks: displayedTasks,
                                        totalTasks: totalCount,
                                        completedTasks: completedCount,
                                        remainingTasks: visibleRemaining,
                                        progress: progress,
                                        statusMessage: statusMessage)
    }

    private func makeStatusMessage(remaining: Int, total: Int) -> String {
        let taskWord = remaining == 1 ? "Task" : "Tasks"
        let suffix = remaining == 1 ? "Left" : "Left"
        return "Daily Focus: \(remaining)/\(total) \(taskWord) \(suffix)"
    }
}
