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

    @Test("TaskStore fetches all tasks for today including completed")
    func taskStoreFetchesAllTasksForToday() async throws {
        let container = try ModelContainer(for: TaskItem.self,
                                           configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let store = TaskStore(modelContext: container.mainContext)

        let base = Date(timeIntervalSince1970: 2_500_000)
        let first = TaskItem(content: "Morning", creationDate: base, isCompleted: false)
        let second = TaskItem(content: "Evening", creationDate: base.addingTimeInterval(3600), isCompleted: true)
        let previous = TaskItem(content: "Yesterday", creationDate: Calendar.current.date(byAdding: .day, value: -1, to: base)!)

        try store.save(task: first)
        try store.save(task: second)
        try store.save(task: previous)

        let tasks = try await store.fetchTasksForToday(referenceDate: base)

        #expect(tasks.count == 2)
        #expect(tasks.map(\.content) == ["Morning", "Evening"])
    }

    @Test("Fetch completed tasks returns only finished items sorted by creation date descending")
    func fetchCompletedTasksReturnsSortedResults() async throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let base = Date(timeIntervalSince1970: 1_000_000) // deterministic reference
        let olderDate = calendar.date(byAdding: .day, value: -1, to: base)!
        let newerDate = calendar.date(byAdding: .hour, value: 6, to: base)!

        let container = try ModelContainer(for: TaskItem.self,
                                           configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let store = TaskStore(modelContext: container.mainContext, calendar: calendar)

        let older = TaskItem(content: "Older completed", creationDate: olderDate, isCompleted: true)
        let newer = TaskItem(content: "Newer completed", creationDate: newerDate, isCompleted: true)
        let incomplete = TaskItem(content: "Incomplete item", creationDate: newerDate, isCompleted: false)

        try store.save(task: older)
        try store.save(task: newer)
        try store.save(task: incomplete)

        let results = try await store.fetchCompletedTasks()

        let contents = results.map(\.content)
        let allCompleted = results.allSatisfy(\.isCompleted)

        #expect(results.count == 2)
        #expect(contents == ["Newer completed", "Older completed"])
        #expect(allCompleted)
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
        let liveActivity = LiveActivityManagerSpy()
        let lifecycle = LiveActivityLifecycleController(manager: liveActivity,
                                                        stateBuilder: LiveActivityStateBuilder())
        let viewModel = TaskListViewModel(store: store,
                                          celebrationProvider: CelebrationProvider(),
                                          encouragementProvider: EncouragementProvider(),
                                          liveActivityController: lifecycle)

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
        let liveActivity = LiveActivityManagerSpy()
        let lifecycle = LiveActivityLifecycleController(manager: liveActivity,
                                                        stateBuilder: LiveActivityStateBuilder())
        let viewModel = TaskListViewModel(store: store,
                                          celebrationProvider: CelebrationProvider(),
                                          encouragementProvider: EncouragementProvider(),
                                          liveActivityController: lifecycle)

        try await viewModel.refresh()

        #expect(viewModel.tasks.isEmpty)
        #expect(viewModel.hasTasks == false)
    }

    @Test("Completing task updates store and list")
    func completingTaskUpdatesStoreAndList() async throws {
        let container = try ModelContainer(for: TaskItem.self,
                                           configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let store = TaskStore(modelContext: container.mainContext)
        let liveActivity = LiveActivityManagerSpy()
        let lifecycle = LiveActivityLifecycleController(manager: liveActivity,
                                                        stateBuilder: LiveActivityStateBuilder())
        let viewModel = TaskListViewModel(store: store,
                                          celebrationProvider: CelebrationProvider(),
                                          encouragementProvider: EncouragementProvider(),
                                          liveActivityController: lifecycle)

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
        let liveActivity = LiveActivityManagerSpy()
        let lifecycle = LiveActivityLifecycleController(manager: liveActivity,
                                                        stateBuilder: LiveActivityStateBuilder())
        let viewModel = TaskListViewModel(store: store,
                                          celebrationProvider: celebration,
                                          encouragementProvider: EncouragementProvider(),
                                          liveActivityController: lifecycle)

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

        guard let limitState = viewModel.limitState else {
            Issue.record("Expected limit state message when daily limit is reached")
            return
        }

        #expect(limitState.message == encouragement.stubMessage.message)
        #expect(limitState.encouragement == encouragement.stubMessage.encouragement)
    }
}

@Suite("Live Activity Integration")
@MainActor
struct LiveActivityIntegrationTests {

    private func makeViewModel(referenceDate: Date = Date()) throws -> (TaskListViewModel, TaskStore, LiveActivityManagerSpy, Date) {
        let container = try ModelContainer(for: TaskItem.self,
                                           configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let store = TaskStore(modelContext: container.mainContext)
        let spy = LiveActivityManagerSpy()
        let lifecycle = LiveActivityLifecycleController(manager: spy,
                                                        stateBuilder: LiveActivityStateBuilder())
        let viewModel = TaskListViewModel(store: store)
        viewModel.setLiveActivityController(lifecycle)
        return (viewModel, store, spy, referenceDate)
    }

    @Test("First refresh starts Live Activity")
    func firstRefreshStartsLiveActivity() async throws {
        let referenceDate = Date(timeIntervalSince1970: 6_000_000)
        let (viewModel, store, spy, date) = try makeViewModel(referenceDate: referenceDate)

        try store.save(task: TaskItem(content: "Focus work", creationDate: date))

        try await viewModel.refresh(referenceDate: date)

        #expect(spy.startedActivities.count == 1)
        #expect(spy.updatedActivities.isEmpty)
        #expect(spy.endedActivities.isEmpty)
    }

    @Test("Subsequent refresh updates Live Activity")
    func subsequentRefreshUpdatesLiveActivity() async throws {
        let referenceDate = Date(timeIntervalSince1970: 6_000_000)
        let (viewModel, store, spy, date) = try makeViewModel(referenceDate: referenceDate)

        let first = TaskItem(content: "Focus work", creationDate: date)
        try store.save(task: first)

        try await viewModel.refresh(referenceDate: date)

        let second = TaskItem(content: "Design review", creationDate: date.addingTimeInterval(60))
        try store.save(task: second)

        try await viewModel.refresh(referenceDate: date)

        #expect(spy.startedActivities.count == 1)
        #expect(spy.updatedActivities.count == 1)
        #expect(spy.endedActivities.isEmpty)
    }

    @Test("Refresh ends Live Activity when no active tasks remain")
    func refreshEndsLiveActivityWhenNoActiveTasksRemain() async throws {
        let referenceDate = Date(timeIntervalSince1970: 6_000_000)
        let (viewModel, store, spy, date) = try makeViewModel(referenceDate: referenceDate)

        let task = TaskItem(content: "Focus work", creationDate: date)
        try store.save(task: task)

        try await viewModel.refresh(referenceDate: date)

        task.isCompleted = true
        try store.save(task: task)
        try await viewModel.refresh(referenceDate: date)

        #expect(spy.startedActivities.count == 1)
        #expect(spy.updatedActivities.count == 0)
        #expect(spy.endedActivities == [.completedAllTasks])
    }
}

@Suite("History ViewModel Tests")
@MainActor
struct HistoryViewModelTests {

    @Test("Load history groups completed tasks by day")
    func loadHistoryGroupsCompletedTasksByDay() async throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateStyle = .medium

        let container = try ModelContainer(for: TaskItem.self,
                                           configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let store = TaskStore(modelContext: container.mainContext, calendar: calendar)
        let viewModel = HistoryViewModel(store: store,
                                         calendar: calendar,
                                         dateFormatter: formatter)

        let base = Date(timeIntervalSince1970: 1_000_000)
        let todayStart = calendar.startOfDay(for: base)
        let yesterdayStart = calendar.date(byAdding: .day, value: -1, to: todayStart)!

        let todayMorning = calendar.date(byAdding: .hour, value: 9, to: todayStart)!
        let todayAfternoon = calendar.date(byAdding: .hour, value: 15, to: todayStart)!
        let yesterdayNoon = calendar.date(byAdding: .hour, value: 12, to: yesterdayStart)!

        let todayFirst = TaskItem(content: "Plan roadmap", creationDate: todayMorning, isCompleted: true)
        let todaySecond = TaskItem(content: "Write copy", creationDate: todayAfternoon, isCompleted: true)
        let yesterdayTask = TaskItem(content: "Ship beta", creationDate: yesterdayNoon, isCompleted: true)
        let incomplete = TaskItem(content: "Keep working", creationDate: todayMorning, isCompleted: false)

        try store.save(task: todayFirst)
        try store.save(task: todaySecond)
        try store.save(task: yesterdayTask)
        try store.save(task: incomplete)

        try await viewModel.loadHistory()

        #expect(viewModel.isEmpty == false)
        #expect(viewModel.sections.count == 2)

        let firstSection = viewModel.sections[0]
        let secondSection = viewModel.sections[1]

        #expect(calendar.isDate(firstSection.date, inSameDayAs: todayStart))
        let firstContents = firstSection.tasks.map(\.content)
        #expect(firstContents == ["Plan roadmap", "Write copy"])
        #expect(firstSection.title == formatter.string(from: todayStart))

        #expect(calendar.isDate(secondSection.date, inSameDayAs: yesterdayStart))
        let secondContents = secondSection.tasks.map(\.content)
        #expect(secondContents == ["Ship beta"])
        #expect(secondSection.title == formatter.string(from: yesterdayStart))
    }

    @Test("Empty history exposes empty state")
    func emptyHistoryExposesEmptyState() async throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateStyle = .medium

        let container = try ModelContainer(for: TaskItem.self,
                                           configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let store = TaskStore(modelContext: container.mainContext, calendar: calendar)
        let viewModel = HistoryViewModel(store: store,
                                         calendar: calendar,
                                         dateFormatter: formatter)

        try await viewModel.loadHistory()

        #expect(viewModel.sections.isEmpty)
        #expect(viewModel.isEmpty)
    }

    @Test("Section count description reflects localized total")
    func sectionCountDescriptionReflectsLocalizedTotal() async throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateStyle = .medium

        let container = try ModelContainer(for: TaskItem.self,
                                           configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let store = TaskStore(modelContext: container.mainContext, calendar: calendar)
        let viewModel = HistoryViewModel(store: store,
                                         calendar: calendar,
                                         dateFormatter: formatter)

        let date = Date(timeIntervalSince1970: 1_111_111)
        let first = TaskItem(content: "Read notes", creationDate: date, isCompleted: true)
        let second = TaskItem(content: "Write summary", creationDate: date.addingTimeInterval(300), isCompleted: true)

        try store.save(task: first)
        try store.save(task: second)

        try await viewModel.loadHistory()

        guard let section = viewModel.sections.first else {
            Issue.record("Expected at least one history section")
            return
        }

        #expect(viewModel.countDescription(for: section) == "2 条完成记录")
    }
}

@Suite("History Navigation State")
@MainActor
struct HistoryNavigationStateTests {

    @Test("Show history toggles presentation flag")
    func showHistoryTogglesPresentationFlag() {
        let navigation = HistoryNavigationState()

        #expect(navigation.isShowingHistory == false)

        navigation.showHistory()

        #expect(navigation.isShowingHistory)
    }

    @Test("Dismiss history resets presentation flag")
    func dismissHistoryResetsPresentationFlag() {
        let navigation = HistoryNavigationState()
        navigation.showHistory()
        navigation.dismissHistory()

        #expect(navigation.isShowingHistory == false)
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
