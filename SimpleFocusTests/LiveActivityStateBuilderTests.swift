//
//  LiveActivityStateBuilderTests.swift
//  SimpleFocusTests
//
//  Created by Codex on 2025-10-22.
//

import Foundation
import Testing
@testable import SimpleFocus

@Suite("Live Activity State Builder Tests")
struct LiveActivityStateBuilderTests {

    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }()

    @Test("Build sorts completed tasks to the top while preserving creation order")
    func buildOrdersCompletedTasksFirst() {
        let builder = LiveActivityStateBuilder(calendar: calendar)
        let base = Date(timeIntervalSince1970: 2_000_000)

        let completed = TaskItem(content: "Old completed", creationDate: base, isCompleted: true)
        let first = TaskItem(content: "Focus research", creationDate: base.addingTimeInterval(60), isCompleted: false)
        let second = TaskItem(content: "Write outline", creationDate: base.addingTimeInterval(120), isCompleted: false)

        let state = builder.makeContentState(referenceDate: base,
                                             tasks: [second, completed, first])

        guard let state else {
            Issue.record("Expected non-nil state when there are active tasks")
            return
        }

        #expect(state.displayedTasks.map(\.content) == ["Old completed", "Focus research", "Write outline"])
        #expect(state.displayedTasks.map(\.isCompleted) == [true, false, false])
        #expect(state.totalTasks == 3)
        #expect(state.completedTasks == 1)
        #expect(state.remainingTasks == 2)
        #expect(abs(state.progress - 0.3333) < 0.0005)
        #expect(state.statusMessage == "Daily Focus: 1/3 Task Completed")
    }

    @Test("Build ignores tasks from other days but keeps completed tasks for today")
    func buildKeepsCompletedTasksForToday() {
        let builder = LiveActivityStateBuilder(calendar: calendar)
        let base = Date(timeIntervalSince1970: 3_000_000)

        let yesterday = calendar.date(byAdding: .day, value: -1, to: base)!
        let yesterdayTask = TaskItem(content: "Old task", creationDate: yesterday, isCompleted: false)
        let completedToday = TaskItem(content: "Done item", creationDate: base, isCompleted: true)

        let state = builder.makeContentState(referenceDate: base, tasks: [yesterdayTask, completedToday])

        guard let state else {
            Issue.record("Expected state to include today's completed task")
            return
        }

        #expect(state.displayedTasks.count == 1)
        #expect(state.displayedTasks.first?.isCompleted == true)
        #expect(state.totalTasks == 1)
        #expect(state.completedTasks == 1)
        #expect(state.remainingTasks == 0)
        #expect(abs(state.progress - 1.0) < 0.0001)
        #expect(state.statusMessage == "Daily Focus: 1/1 Task Completed")
    }

    @Test("Build produces state when all tasks for today are completed")
    func buildProducesStateWhenAllCompleted() {
        let builder = LiveActivityStateBuilder(calendar: calendar)
        let base = Date(timeIntervalSince1970: 4_000_000)

        let completedA = TaskItem(content: "Morning review", creationDate: base, isCompleted: true)
        let completedB = TaskItem(content: "Ship email", creationDate: base.addingTimeInterval(120), isCompleted: true)

        let state = builder.makeContentState(referenceDate: base, tasks: [completedA, completedB])

        guard let state else {
            Issue.record("Expected state to represent all completed tasks")
            return
        }

        #expect(state.displayedTasks.map(\.content) == ["Morning review", "Ship email"])
        #expect(state.displayedTasks.allSatisfy(\.isCompleted))
        #expect(state.totalTasks == 2)
        #expect(state.completedTasks == 2)
        #expect(state.remainingTasks == 0)
        #expect(abs(state.progress - 1.0) < 0.0001)
        #expect(state.statusMessage == "Daily Focus: 2/2 Tasks Completed")
    }
}
