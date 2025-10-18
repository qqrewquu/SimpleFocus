//
//  TaskStore.swift
//  SimpleFocus
//
//  Created by Codex on 2025-10-17.
//

import Foundation
import SwiftData

@MainActor
final class TaskStore {
    private let modelContext: ModelContext
    private let calendar: Calendar

    init(modelContext: ModelContext, calendar: Calendar = .current) {
        self.modelContext = modelContext
        self.calendar = calendar
    }

    func save(task: TaskItem) throws {
        if task.modelContext == nil {
            modelContext.insert(task)
        }
        try modelContext.save()
    }

    func createTask(with content: String) throws -> TaskItem {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        precondition(!trimmed.isEmpty, "Task content should not be empty")
        let task = TaskItem(content: trimmed)
        try save(task: task)
        return task
    }

    func markTaskCompleted(_ task: TaskItem) throws {
        task.isCompleted = true
        try save(task: task)
    }

    func clearTodayTasks(referenceDate: Date = Date()) throws {
        let startOfDay = calendar.startOfDay(for: referenceDate)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return
        }

        let predicate = #Predicate<TaskItem> {
            $0.creationDate >= startOfDay &&
            $0.creationDate < endOfDay
        }

        let descriptor = FetchDescriptor<TaskItem>(predicate: predicate)
        let tasks = try modelContext.fetch(descriptor)
        tasks.forEach { modelContext.delete($0) }
        try modelContext.save()
    }

    func countTasksForToday(referenceDate: Date = Date()) throws -> Int {
        try countTasks(for: referenceDate)
    }

    func isDailyLimitReached(referenceDate: Date = Date()) throws -> Bool {
        try countTasksForToday(referenceDate: referenceDate) >= TaskLimit.dailyLimit
    }

    func fetchIncompleteTasksForToday(referenceDate: Date = Date()) async throws -> [TaskItem] {
        let startOfDay = calendar.startOfDay(for: referenceDate)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return []
        }

        let predicate = #Predicate<TaskItem> {
            $0.creationDate >= startOfDay &&
            $0.creationDate < endOfDay &&
            $0.isCompleted == false
        }

        var descriptor = FetchDescriptor<TaskItem>(predicate: predicate,
                                                   sortBy: [SortDescriptor(\TaskItem.creationDate, order: .forward)])
        descriptor.fetchLimit = 0

        return try modelContext.fetch(descriptor)
    }

    private func countTasks(for referenceDate: Date) throws -> Int {
        let startOfDay = calendar.startOfDay(for: referenceDate)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return 0
        }

        let predicate = #Predicate<TaskItem> {
            $0.creationDate >= startOfDay &&
            $0.creationDate < endOfDay
        }

        var descriptor = FetchDescriptor<TaskItem>(predicate: predicate)
        descriptor.fetchLimit = 0

        return try modelContext.fetchCount(descriptor)
    }
}

extension TaskStore {
    static func makeSharedStore() throws -> TaskStore {
        if AppGroup.containerURL() != nil {
            let container = try ModelContainer(for: TaskItem.self,
                                               configurations: ModelConfiguration(groupContainerIdentifier: AppGroup.identifier))
            return TaskStore(modelContext: container.mainContext)
        } else {
            let container = try ModelContainer(for: TaskItem.self)
            return TaskStore(modelContext: container.mainContext)
        }
    }
}
