//
//  SimpleFocusTests.swift
//  SimpleFocusTests
//
//  Created by Zifeng Guo on 2025-10-17.
//

import Foundation
import SwiftData
import Testing
@testable import SimpleFocus

@Suite("Task Data Core Tests")
@MainActor
struct TaskDataCoreTests {

    @Test("TaskItem defaults")
    func taskItemDefaults() throws {
        let task = TaskItem(content: "Write tests")
        #expect(!task.isCompleted)
        let now = Date()
        let interval = task.creationDate.timeIntervalSince(now)
        #expect(abs(interval) < 1, "Creation date should default to now")
        #expect(!task.content.isEmpty)
    }

    @Test("TaskStore persists and fetches today's incomplete tasks")
    func taskStorePersistsAndFetchesTodayTasks() async throws {
        let container = try ModelContainer(for: TaskItem.self,
                                           configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let store = TaskStore(modelContext: container.mainContext)

        let todayTask = TaskItem(content: "Plan MVP")
        let completedTask = TaskItem(content: "Finish yesterday", isCompleted: true)
        let oldTask = TaskItem(content: "Old item", creationDate: Calendar.current.date(byAdding: .day, value: -1, to: Date())!)

        try store.save(task: todayTask)
        try store.save(task: completedTask)
        try store.save(task: oldTask)

        let results = try await store.fetchIncompleteTasksForToday()

        #expect(results.count == 1)
        #expect(results.first?.content == "Plan MVP")
    }
}

@Suite("Main Screen ViewModel Tests")
@MainActor
struct MainScreenViewModelTests {

    @Test("Refresh filters only today's incomplete tasks")
    func refreshFiltersIncompleteTasks() async throws {
        let container = try ModelContainer(for: TaskItem.self,
                                           configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let store = TaskStore(modelContext: container.mainContext)
        let viewModel = TaskListViewModel(store: store)

        let today = TaskItem(content: "Design layout")
        let completed = TaskItem(content: "Ship feature", isCompleted: true)
        let oldDate = Calendar.current.date(byAdding: .day, value: -2, to: Date())!
        let oldTask = TaskItem(content: "Old task", creationDate: oldDate)

        try store.save(task: today)
        try store.save(task: completed)
        try store.save(task: oldTask)

        try await viewModel.refresh()

        #expect(viewModel.tasks.count == 1)
        #expect(viewModel.tasks.first?.content == "Design layout")
        #expect(viewModel.hasTasks)
    }

    @Test("Empty state when no tasks")
    func emptyStateWhenNoTasks() async throws {
        let container = try ModelContainer(for: TaskItem.self,
                                           configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let store = TaskStore(modelContext: container.mainContext)
        let viewModel = TaskListViewModel(store: store)

        try await viewModel.refresh()

        #expect(viewModel.tasks.isEmpty)
        #expect(viewModel.hasTasks == false)
    }

    @Test("Completing task updates store and list")
    func completingTaskUpdatesStoreAndList() async throws {
        let container = try ModelContainer(for: TaskItem.self,
                                           configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let store = TaskStore(modelContext: container.mainContext)
        let viewModel = TaskListViewModel(store: store)

        let task = TaskItem(content: "Finish mock")
        try store.save(task: task)

        try await viewModel.refresh()
        #expect(viewModel.tasks.count == 1)

        try await viewModel.complete(task: task)
        try await viewModel.refresh()

        #expect(task.isCompleted)
        #expect(viewModel.tasks.isEmpty)
    }

    @Test("Completing last task triggers celebration with quote")
    func completingLastTaskTriggersCelebration() async throws {
        let container = try ModelContainer(for: TaskItem.self,
                                           configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let store = TaskStore(modelContext: container.mainContext)
        let celebration = StubCelebrationProvider()
        let viewModel = TaskListViewModel(store: store, celebrationProvider: celebration)

        let first = TaskItem(content: "Item 1")
        let second = TaskItem(content: "Item 2")
        try store.save(task: first)
        try store.save(task: second)

        try await viewModel.refresh()
        try await viewModel.complete(task: first)
        try await viewModel.refresh()
        #expect(viewModel.celebration == nil)

        try await viewModel.complete(task: second)
        try await viewModel.refresh()

        #expect(celebration.invocationCount == 1)
        #expect(viewModel.celebration?.title == "All Done!")
        #expect(viewModel.celebration?.quote.text == "Stay hungry, stay foolish.")
        #expect(viewModel.celebration?.quote.author == "Steve Jobs")
    }

    @Test("Dismissing celebration clears state")
    func dismissingCelebrationClearsState() async throws {
        let container = try ModelContainer(for: TaskItem.self,
                                           configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let store = TaskStore(modelContext: container.mainContext)
        let celebration = StubCelebrationProvider()
        let viewModel = TaskListViewModel(store: store, celebrationProvider: celebration)

        let task = TaskItem(content: "Only task")
        try store.save(task: task)

        try await viewModel.refresh()
        try await viewModel.complete(task: task)
        try await viewModel.refresh()

        #expect(viewModel.celebration != nil)
        viewModel.dismissCelebration()
        #expect(viewModel.celebration == nil)
    }

    @Test("Completing task records animation state")
    func completingTaskRecordsAnimationState() async throws {
        let container = try ModelContainer(for: TaskItem.self,
                                           configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let store = TaskStore(modelContext: container.mainContext)
        let viewModel = TaskListViewModel(store: store)

        let task = TaskItem(content: "Animate me")
        try store.save(task: task)

        try await viewModel.refresh()
        try await viewModel.complete(task: task)

        #expect(viewModel.recentlyCompletedTaskIDs.contains(task.id))

        viewModel.clearCompletionAnimation(for: task.id)
        #expect(!viewModel.recentlyCompletedTaskIDs.contains(task.id))
    }

    @Test("Add button disabled when daily limit reached")
    func addButtonDisabledWhenLimitReached() async throws {
        let container = try ModelContainer(for: TaskItem.self,
                                           configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let store = TaskStore(modelContext: container.mainContext)
        let viewModel = TaskListViewModel(store: store)

        try store.save(task: TaskItem(content: "Task 1"))
        try store.save(task: TaskItem(content: "Task 2"))
        try store.save(task: TaskItem(content: "Task 3"))

        try await viewModel.refresh()

        #expect(viewModel.canAddTask == false)
    }

    @Test("Daily limit resets on new day or manual clear")
    func dailyLimitResetsOnNewDayOrManualClear() async throws {
        let container = try ModelContainer(for: TaskItem.self,
                                           configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let store = TaskStore(modelContext: container.mainContext)
        let viewModel = TaskListViewModel(store: store)

        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!

        try store.save(task: TaskItem(content: "Old", creationDate: yesterday))

        try await viewModel.refresh()
        #expect(viewModel.canAddTask)

        _ = try AddTaskViewModel(store: store).submit(content: "Task 1")
        _ = try AddTaskViewModel(store: store).submit(content: "Task 2")
        _ = try AddTaskViewModel(store: store).submit(content: "Task 3")
        try await viewModel.refresh()
        #expect(viewModel.canAddTask == false)

        try await viewModel.resetTodayTasks()
        #expect(viewModel.canAddTask)
    }

    @Test("Limit reached state surfaces encouragement copy")
    func limitReachedStateSurfacesEncouragementCopy() async throws {
        let container = try ModelContainer(for: TaskItem.self,
                                           configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let store = TaskStore(modelContext: container.mainContext)
        let encouragement = StubEncouragementProvider()
        let viewModel = TaskListViewModel(store: store,
                                          celebrationProvider: CelebrationProvider(),
                                          encouragementProvider: encouragement)

        try store.save(task: TaskItem(content: "One"))
        try store.save(task: TaskItem(content: "Two"))
        try store.save(task: TaskItem(content: "Three"))

        try await viewModel.refresh()

        #expect(viewModel.limitState == encouragement.stubMessage)
    }
}

@Suite("Add Task ViewModel Tests")
@MainActor
struct AddTaskViewModelTests {

    @Test("Submit creates trimmed task within limit")
    func submitCreatesTrimmedTask() throws {
        let container = try ModelContainer(for: TaskItem.self,
                                           configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let store = TaskStore(modelContext: container.mainContext)
        let viewModel = AddTaskViewModel(store: store)

        viewModel.content = "  Finish draft  "
        let task = try viewModel.submit()

        #expect(task.content == "Finish draft")
        #expect(task.isCompleted == false)
        #expect(viewModel.content.isEmpty)
    }

    @Test("Content is capped at 20 characters")
    func contentIsCappedAtTwentyCharacters() throws {
        let container = try ModelContainer(for: TaskItem.self,
                                           configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let store = TaskStore(modelContext: container.mainContext)
        let viewModel = AddTaskViewModel(store: store)

        viewModel.content = "1234567890123456789012345"
        #expect(viewModel.content.count == AddTaskViewModel.maxLength)
        #expect(viewModel.content == "12345678901234567890")
    }

    @Test("Submit throws when content is empty")
    func submitThrowsWhenEmpty() throws {
        let container = try ModelContainer(for: TaskItem.self,
                                           configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let store = TaskStore(modelContext: container.mainContext)
        let viewModel = AddTaskViewModel(store: store)

        viewModel.content = "   "
        #expect(throws: TaskInputError.emptyContent) {
            _ = try viewModel.submit()
        }
    }

    @Test("Submit prevents adding more than three tasks per day")
    func submitPreventsAddingMoreThanThreeTasks() throws {
        let container = try ModelContainer(for: TaskItem.self,
                                           configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let store = TaskStore(modelContext: container.mainContext)
        let viewModel = AddTaskViewModel(store: store)

        _ = try viewModel.submit(content: "Task 1")
        _ = try viewModel.submit(content: "Task 2")
        _ = try viewModel.submit(content: "Task 3")

        #expect(throws: TaskInputError.limitReached) {
            _ = try viewModel.submit(content: "Task 4")
        }
    }

    @Test("Completing a task does not reset limit for the day")
    func completingTaskDoesNotResetLimit() async throws {
        let container = try ModelContainer(for: TaskItem.self,
                                           configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let store = TaskStore(modelContext: container.mainContext)
        let listViewModel = TaskListViewModel(store: store)
        let addViewModel = AddTaskViewModel(store: store)

        _ = try addViewModel.submit(content: "Task 1")
        _ = try addViewModel.submit(content: "Task 2")
        let third = try addViewModel.submit(content: "Task 3")

        try await listViewModel.refresh()
        try await listViewModel.complete(task: third)

        #expect(throws: TaskInputError.limitReached) {
            _ = try addViewModel.submit(content: "Task 4")
        }
    }
}

// MARK: - Test Doubles

@MainActor
private final class StubCelebrationProvider: CelebrationProviding {
    private(set) var invocationCount = 0

    func nextCelebration() -> CompletionCelebration {
        invocationCount += 1
        return CompletionCelebration(title: "All Done!",
                                     quote: CelebrationQuote(text: "Stay hungry, stay foolish.",
                                                             author: "Steve Jobs"))
    }
}

@MainActor
private final class StubEncouragementProvider: EncouragementProviding {
    let stubMessage = EncouragementMessage(message: "今日安排已满",
                                           encouragement: "好好休息，为明天充电。")

    func nextMessage() -> EncouragementMessage {
        stubMessage
    }
}
