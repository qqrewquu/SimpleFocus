//
//  LiveActivityLifecycleControllerTests.swift
//  SimpleFocusTests
//
//  Created by Codex on 2025-10-22.
//

import Foundation
import Testing
@testable import SimpleFocus

@Suite("Live Activity Lifecycle Controller Tests")
@MainActor
struct LiveActivityLifecycleControllerTests {

    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }()

    @Test("Start activity when first task is added today")
    func startActivityOnFirstTaskAdded() async throws {
        let manager = LiveActivityManagerSpy()
        let builder = LiveActivityStateBuilder(calendar: calendar)
        let controller = LiveActivityLifecycleController(manager: manager,
                                                         stateBuilder: builder)

        let referenceDate = Date(timeIntervalSince1970: 5_000_000)
        let task = TaskItem(content: "Focus work", creationDate: referenceDate, isCompleted: false)

        try await controller.handleTasksChanged(referenceDate: referenceDate,
                                                tasks: [task])

        #expect(manager.startedActivities.count == 1)
        #expect(manager.updatedActivities.isEmpty)
        #expect(manager.endedActivities.isEmpty)
    }

    @Test("Update activity when additional tasks appear")
    func updateActivityWhenTasksChange() async throws {
        let manager = LiveActivityManagerSpy()
        let builder = LiveActivityStateBuilder(calendar: calendar)
        let controller = LiveActivityLifecycleController(manager: manager,
                                                         stateBuilder: builder)

        let referenceDate = Date(timeIntervalSince1970: 5_000_000)
        let task1 = TaskItem(content: "Focus work", creationDate: referenceDate, isCompleted: false)

        try await controller.handleTasksChanged(referenceDate: referenceDate,
                                                tasks: [task1])

        let task2 = TaskItem(content: "Design review", creationDate: referenceDate.addingTimeInterval(60), isCompleted: false)

        try await controller.handleTasksChanged(referenceDate: referenceDate,
                                                tasks: [task1, task2])

        #expect(manager.startedActivities.count == 1)
        #expect(manager.updatedActivities.count == 1)
        #expect(manager.endedActivities.isEmpty)
    }

    @Test("Keep activity running and update when tasks become completed")
    func keepActivityRunningWhenAllTasksComplete() async throws {
        let manager = LiveActivityManagerSpy()
        let builder = LiveActivityStateBuilder(calendar: calendar)
        let controller = LiveActivityLifecycleController(manager: manager,
                                                         stateBuilder: builder)

        let referenceDate = Date(timeIntervalSince1970: 5_000_000)
        let activeTask = TaskItem(content: "Focus work", creationDate: referenceDate, isCompleted: false)

        try await controller.handleTasksChanged(referenceDate: referenceDate,
                                                tasks: [activeTask])

        let completedTask = TaskItem(content: "Focus work", creationDate: referenceDate, isCompleted: true)

        try await controller.handleTasksChanged(referenceDate: referenceDate,
                                                tasks: [completedTask])

        #expect(manager.startedActivities.count == 1)
        #expect(manager.updatedActivities.count == 1)
        #expect(manager.endedActivities.isEmpty)
    }

    @Test("End activity when there are no tasks for today")
    func endActivityWhenNoTasksForToday() async throws {
        let manager = LiveActivityManagerSpy()
        let builder = LiveActivityStateBuilder(calendar: calendar)
        let controller = LiveActivityLifecycleController(manager: manager,
                                                         stateBuilder: builder)

        let referenceDate = Date(timeIntervalSince1970: 5_000_000)
        try await controller.handleTasksChanged(referenceDate: referenceDate,
                                                tasks: [])

        #expect(manager.startedActivities.isEmpty)
        #expect(manager.updatedActivities.isEmpty)
        #expect(manager.endedActivities == [.completedAllTasks])
    }
}
