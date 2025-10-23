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

    @Test("Build trims to three incomplete tasks and sorts by creation date")
    func buildTrimsAndSortsIncompleteTasks() {
        let builder = LiveActivityStateBuilder(calendar: calendar)
        let base = Date(timeIntervalSince1970: 2_000_000)

        let task1 = TaskItem(content: "Old completed", creationDate: base, isCompleted: true)
        let task2 = TaskItem(content: "Focus research", creationDate: base.addingTimeInterval(60), isCompleted: false)
        let task3 = TaskItem(content: "Write outline", creationDate: base.addingTimeInterval(120), isCompleted: false)
        let task4 = TaskItem(content: "Design preview", creationDate: base.addingTimeInterval(180), isCompleted: false)
        let task5 = TaskItem(content: "Spillover item", creationDate: base.addingTimeInterval(240), isCompleted: false)

        let state = builder.makeContentState(referenceDate: base,
                                             tasks: [task1, task5, task4, task3, task2])

        guard let state else {
            Issue.record("Expected non-nil state when there are active tasks")
            return
        }

        #expect(state.displayedTasks.map(\.content) == ["Focus research", "Write outline", "Design preview"])
        #expect(state.totalTasks == 4)
        #expect(state.completedTasks == 1)
        #expect(state.remainingTasks == 3)
        #expect(abs(state.progress - 0.25) < 0.0001)
        #expect(state.statusMessage == "Daily Focus: 3/4 Tasks Left")
    }

    @Test("Build returns nil when there are no active tasks for today")
    func buildReturnsNilWhenNoActiveTasks() {
        let builder = LiveActivityStateBuilder(calendar: calendar)
        let base = Date(timeIntervalSince1970: 3_000_000)

        let yesterday = calendar.date(byAdding: .day, value: -1, to: base)!
        let yesterdayTask = TaskItem(content: "Old task", creationDate: yesterday, isCompleted: false)
        let completedToday = TaskItem(content: "Done item", creationDate: base, isCompleted: true)

        let state = builder.makeContentState(referenceDate: base, tasks: [yesterdayTask, completedToday])

        #expect(state == nil)
    }

    @Test("Build returns nil when all tasks for today are completed")
    func buildReturnsNilWhenAllCompleted() {
        let builder = LiveActivityStateBuilder(calendar: calendar)
        let base = Date(timeIntervalSince1970: 4_000_000)

        let completedA = TaskItem(content: "Morning review", creationDate: base, isCompleted: true)
        let completedB = TaskItem(content: "Ship email", creationDate: base.addingTimeInterval(120), isCompleted: true)

        let state = builder.makeContentState(referenceDate: base, tasks: [completedA, completedB])

        #expect(state == nil)
    }
}
