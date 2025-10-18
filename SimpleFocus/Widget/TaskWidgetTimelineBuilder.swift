//
//  TaskWidgetTimelineBuilder.swift
//  SimpleFocus
//
//  Created by Codex on 2025-10-17.
//

import Foundation
import WidgetKit

struct SimpleFocusWidgetTask: Identifiable, Equatable {
    let id: UUID
    let content: String
}

enum SimpleFocusWidgetState: Equatable {
    case tasks([SimpleFocusWidgetTask])
    case empty(EncouragementMessage)
}

struct SimpleFocusWidgetEntry: TimelineEntry, Equatable {
    let date: Date
    let state: SimpleFocusWidgetState
}

struct TaskWidgetTimelineBuilder {
    private let calendar: Calendar
    private let encouragementProvider: EncouragementProviding

    init(calendar: Calendar = .current,
         encouragementProvider: EncouragementProviding = EncouragementProvider()) {
        self.calendar = calendar
        self.encouragementProvider = encouragementProvider
    }

    func buildEntry(for referenceDate: Date, tasks: [TaskItem]) -> SimpleFocusWidgetEntry {
        let todaysTasks = tasks
            .filter { !$0.isCompleted && calendar.isDate($0.creationDate, inSameDayAs: referenceDate) }
            .sorted { $0.creationDate < $1.creationDate }

        if todaysTasks.isEmpty {
            return SimpleFocusWidgetEntry(date: referenceDate,
                                          state: .empty(encouragementProvider.nextMessage()))
        }

        let visibleTasks = todaysTasks.prefix(TaskLimit.dailyLimit).map {
            SimpleFocusWidgetTask(id: $0.id, content: $0.content)
        }

        return SimpleFocusWidgetEntry(date: referenceDate,
                                      state: .tasks(Array(visibleTasks)))
    }
}
