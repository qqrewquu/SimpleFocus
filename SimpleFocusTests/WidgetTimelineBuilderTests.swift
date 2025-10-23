//
//  WidgetTimelineBuilderTests.swift
//  SimpleFocusTests
//
//  Created by Codex on 2025-10-17.
//

import Foundation
import Testing
import WidgetKit
@testable import SimpleFocus

@Suite("Widget Timeline Builder")
struct WidgetTimelineBuilderTests {
    private let calendar = Calendar(identifier: .gregorian)

    @Test("Build entry filters to today's incomplete tasks and limits to three")
    func buildEntryFiltersAndLimitsTasks() {
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let encouragement = StubEncouragementProvider()
        let builder = TaskWidgetTimelineBuilder(calendar: calendar,
                                                encouragementProvider: encouragement)

        let tasks = [
            TaskItem(content: "Today A", creationDate: today),
            TaskItem(content: "Today B", creationDate: today.addingTimeInterval(30)),
            TaskItem(content: "Today C", creationDate: today.addingTimeInterval(60)),
            TaskItem(content: "Today D", creationDate: today.addingTimeInterval(90)),
            TaskItem(content: "Yesterday", creationDate: yesterday),
            TaskItem(content: "Completed", creationDate: today, isCompleted: true)
        ]

        let entry = builder.buildEntry(for: today, tasks: tasks)

        guard case let .tasks(displayedTasks) = entry.state else {
            Issue.record("Expected tasks state but received \(entry.state)")
            return
        }

        #expect(displayedTasks.count == 3)
        #expect(displayedTasks.map(\.content) == ["Today A", "Today B", "Today C"])
    }

    @Test("Empty state uses encouragement provider")
    func emptyStateUsesEncouragement() {
        let today = Date()
        let encouragement = StubEncouragementProvider()
        let builder = TaskWidgetTimelineBuilder(calendar: calendar,
                                                encouragementProvider: encouragement)

        let entry = builder.buildEntry(for: today, tasks: [])

        guard case let .empty(message) = entry.state else {
            Issue.record("Expected empty state but received \(entry.state)")
            return
        }

        #expect(message == encouragement.stubMessage)
    }
}

// MARK: - Test Doubles

private final class StubEncouragementProvider: EncouragementProviding {
    let stubMessage = EncouragementMessage(message: "All set for today",
                                           encouragement: "Rest well and come back tomorrow.")

    func nextMessage() -> EncouragementMessage {
        stubMessage
    }
}
