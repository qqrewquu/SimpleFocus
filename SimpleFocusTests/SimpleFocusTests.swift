//
//  SimpleFocusTests.swift
//  SimpleFocusTests
//
//  Focused on verifying the daily rollover logic for tasks and Live Activity.
//

import Foundation
import SwiftData
import Testing
@testable import SimpleFocus

@Suite("Daily Rollover Data Tests")
@MainActor
struct DailyRolloverDataTests {

    @Test("Counts stale incomplete tasks without deleting them")
    func countsStaleIncompleteTasksWithoutDeletingThem() async throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let base = Date(timeIntervalSince1970: 3_000_000)
        let todayStart = calendar.startOfDay(for: base)
        let yesterdayStart = calendar.date(byAdding: .day, value: -1, to: todayStart)!

        let container = try ModelContainer(for: TaskItem.self,
                                           configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let store = TaskStore(modelContext: container.mainContext, calendar: calendar)

        let staleIncomplete = TaskItem(content: "Leftover",
                                       creationDate: calendar.date(byAdding: .hour, value: 9, to: yesterdayStart)!)
        let staleCompleted = TaskItem(content: "Done",
                                      creationDate: calendar.date(byAdding: .hour, value: 14, to: yesterdayStart)!,
                                      isCompleted: true)
        let todayTask = TaskItem(content: "Today",
                                 creationDate: calendar.date(byAdding: .hour, value: 10, to: todayStart)!)

        try store.save(task: staleIncomplete)
        try store.save(task: staleCompleted)
        try store.save(task: todayTask)

        let staleCount = try store.staleIncompleteTaskCount(before: todayStart)

        let yesterdayReference = calendar.date(byAdding: .hour, value: 12, to: yesterdayStart)!
        let yesterdayTasks = try await store.fetchTasksForToday(referenceDate: yesterdayReference)
        let todaysTasks = try await store.fetchTasksForToday(referenceDate: base)
        let completedTasks = try await store.fetchCompletedTasks()

        #expect(staleCount == 1)
        #expect(yesterdayTasks.count == 1)
        #expect(yesterdayTasks.first?.content == "Done")
        #expect(yesterdayTasks.first?.isCompleted == true)
        #expect(yesterdayTasks.contains { $0.isCompleted })
        #expect(todaysTasks.contains { $0.content == "Today" })
        #expect(completedTasks.contains { $0.content == "Done" })
    }

    @Test("Updating incomplete task persists new content")
    func updatingIncompleteTaskPersistsNewContent() throws {
        let container = try ModelContainer(for: TaskItem.self,
                                           configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let store = TaskStore(modelContext: container.mainContext)

        let task = TaskItem(content: "Original")
        try store.save(task: task)

        try store.updateTask(task, with: "Updated")

        let fetchDescriptor = FetchDescriptor<TaskItem>()
        let allTasks = try container.mainContext.fetch(fetchDescriptor)

        #expect(allTasks.count == 1)
        #expect(allTasks.first?.content == "Updated")
    }

    @Test("Updating completed task throws")
    func updatingCompletedTaskThrows() throws {
        let container = try ModelContainer(for: TaskItem.self,
                                           configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let store = TaskStore(modelContext: container.mainContext)

        let task = TaskItem(content: "Done", isCompleted: true)
        try store.save(task: task)

        #expect(throws: TaskUpdateError.completedTask) {
            try store.updateTask(task, with: "New")
        }
    }
}

@Suite("Daily Rollover Live Activity Tests")
@MainActor
struct DailyRolloverLiveActivityTests {

    @Test("Refresh across midnight ends Live Activity with rollover")
    func refreshAcrossMidnightEndsLiveActivityWithRollover() async throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let container = try ModelContainer(for: TaskItem.self,
                                           configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let store = TaskStore(modelContext: container.mainContext, calendar: calendar)
        let spy = LiveActivityManagerSpy()
        let lifecycle = LiveActivityLifecycleController(manager: spy,
                                                        stateBuilder: LiveActivityStateBuilder(calendar: calendar))
        let viewModel = TaskListViewModel(store: store,
                                          celebrationProvider: CelebrationProvider(),
                                          encouragementProvider: EncouragementProvider(),
                                          calendar: calendar,
                                          liveActivityController: lifecycle)

        let dayStart = calendar.startOfDay(for: Date(timeIntervalSince1970: 7_000_000))
        let evening = calendar.date(byAdding: .hour, value: 21, to: dayStart)!
        let nextDayStart = calendar.date(byAdding: .day, value: 1, to: dayStart)!
        let nextMorning = calendar.date(byAdding: .hour, value: 8, to: nextDayStart)!

        let task = TaskItem(content: "Evening prep", creationDate: evening)
        try store.save(task: task)

        try await viewModel.refresh(referenceDate: evening)

        #expect(spy.startedActivities.count == 1)
        #expect(viewModel.tasks.count == 1)

        try await viewModel.refresh(referenceDate: nextMorning)

        #expect(viewModel.tasks.isEmpty)
        #expect(spy.endedActivities.contains(.dateRolledOver))
        #expect(spy.startedActivities.count == 1)
        #expect(spy.updatedActivities.isEmpty)
        #expect(viewModel.canAddTask)
    }
}

@Suite("History ViewModel Tests")
@MainActor
struct HistoryViewModelRolloverTests {

    @Test("History sections expose completed and incomplete groups")
    func historySectionsExposeCompletedAndIncompleteGroups() async throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let container = try ModelContainer(for: TaskItem.self,
                                           configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let store = TaskStore(modelContext: container.mainContext, calendar: calendar)
        let viewModel = HistoryViewModel(store: store, calendar: calendar)

        let day = Date(timeIntervalSince1970: 8_000_000)
        let startOfDay = calendar.startOfDay(for: day)
        let morning = calendar.date(byAdding: .hour, value: 9, to: startOfDay)!
        let evening = calendar.date(byAdding: .hour, value: 18, to: startOfDay)!
        let previousDay = calendar.date(byAdding: .day, value: -1, to: day)!

        let completed = TaskItem(content: "Finished", creationDate: morning, isCompleted: true)
        let missed = TaskItem(content: "Missed", creationDate: morning, isCompleted: false)
        let previousCompleted = TaskItem(content: "Yesterday Done", creationDate: previousDay, isCompleted: true)
        let previousMissed = TaskItem(content: "Yesterday Missed", creationDate: previousDay, isCompleted: false)

        try store.save(task: completed)
        try store.save(task: missed)
        try store.save(task: previousCompleted)
        try store.save(task: previousMissed)

        try await viewModel.loadHistory()

        #expect(viewModel.sections.count == 2)

        guard let todaySection = viewModel.sections.first(where: { calendar.isDate($0.date, inSameDayAs: day) }) else {
            Issue.record("Expected to find section for current day")
            return
        }

        #expect(todaySection.incompleteTasks.count == 1)
        #expect(todaySection.completedTasks.count == 1)
        #expect(todaySection.incompleteTasks.first?.content == "Missed")
        #expect(todaySection.completedTasks.first?.content == "Finished")

        guard let previousSection = viewModel.sections.first(where: { calendar.isDate($0.date, inSameDayAs: previousDay) }) else {
            Issue.record("Expected to find section for previous day")
            return
        }

        #expect(previousSection.incompleteTasks.count == 1)
        #expect(previousSection.completedTasks.count == 1)
        #expect(previousSection.incompleteTasks.first?.content == "Yesterday Missed")
        #expect(previousSection.completedTasks.first?.content == "Yesterday Done")
    }
}

@Suite("Task Editing ViewModel Tests")
@MainActor
struct TaskEditingViewModelTests {

    @Test("Editing task trims content and refreshes list")
    func editingTaskTrimsContentAndRefreshesList() async throws {
        let container = try ModelContainer(for: TaskItem.self,
                                           configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let store = TaskStore(modelContext: container.mainContext)
        let spy = LiveActivityManagerSpy()
        let lifecycle = LiveActivityLifecycleController(manager: spy,
                                                        stateBuilder: LiveActivityStateBuilder())
        let viewModel = TaskListViewModel(store: store,
                                          celebrationProvider: CelebrationProvider(),
                                          encouragementProvider: EncouragementProvider(),
                                          liveActivityController: lifecycle)

        let task = TaskItem(content: "Focus")
        try store.save(task: task)

        try await viewModel.refresh()
        #expect(viewModel.tasks.first?.content == "Focus")

        try await viewModel.edit(task: task, newContent: "  Updated title that is quite long  ")

        try await viewModel.refresh()

        guard let updated = viewModel.tasks.first else {
            Issue.record("Expected updated task to remain in list")
            return
        }

        #expect(updated.content.count <= TaskContentPolicy.maxLength)
        #expect(updated.content == "Updated title that i")
        #expect(spy.updatedActivities.isEmpty == false)
    }

    @Test("Editing to empty content throws")
    func editingToEmptyContentThrows() async throws {
        let container = try ModelContainer(for: TaskItem.self,
                                           configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let store = TaskStore(modelContext: container.mainContext)
        let viewModel = TaskListViewModel(store: store)

        let task = TaskItem(content: "Focus")
        try store.save(task: task)

        try await viewModel.refresh()

        #expect(throws: TaskInputError.emptyContent) {
            try await viewModel.edit(task: task, newContent: "   ")
        }
    }
}

@Suite("Task Completion Buffer Tests")
@MainActor
struct TaskCompletionBufferTests {

    @Test("Task remains visible during completion buffer then finishes")
    func taskCompletesAfterDelay() async throws {
        let container = try ModelContainer(for: TaskItem.self,
                                           configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let store = TaskStore(modelContext: container.mainContext)
        let task = TaskItem(content: "Focus task")
        try store.save(task: task)

        let viewModel = TaskListViewModel(store: store, completionDelay: 0.05)
        try await viewModel.refresh()

        viewModel.toggleCompletion(for: task)

        #expect(viewModel.isPendingCompletion(task.id))
        #expect(viewModel.tasks.contains { $0.id == task.id })

        try await Task.sleep(nanoseconds: 120_000_000)
        try await Task.yield()

        #expect(viewModel.tasks.isEmpty)
        #expect(viewModel.pendingCompletionTaskIDs.isEmpty)
    }

    @Test("Toggling again within buffer cancels completion")
    func togglingAgainCancelsPendingCompletion() async throws {
        let container = try ModelContainer(for: TaskItem.self,
                                           configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let store = TaskStore(modelContext: container.mainContext)
        let task = TaskItem(content: "Undo task")
        try store.save(task: task)

        let viewModel = TaskListViewModel(store: store, completionDelay: 0.1)
        try await viewModel.refresh()

        viewModel.toggleCompletion(for: task)
        #expect(viewModel.isPendingCompletion(task.id))

        viewModel.toggleCompletion(for: task)
        #expect(viewModel.isPendingCompletion(task.id) == false)

        try await Task.sleep(nanoseconds: 150_000_000)
        try await Task.yield()

        #expect(viewModel.tasks.contains { $0.id == task.id })
        #expect(viewModel.pendingCompletionTaskIDs.isEmpty)
    }
}
