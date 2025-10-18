//
//  TaskListViewModel.swift
//  SimpleFocus
//
//  Created by Codex on 2025-10-17.
//

import Combine
import Foundation
import SwiftUI

@MainActor
final class TaskListViewModel: ObservableObject {
    @Published private(set) var tasks: [TaskItem] = []
    @Published private(set) var celebration: CompletionCelebration?
    @Published private(set) var recentlyCompletedTaskIDs: Set<UUID> = []
    @Published private(set) var canAddTask: Bool = true
    @Published private(set) var limitState: EncouragementMessage?

    var hasTasks: Bool {
        !tasks.isEmpty
    }

    private let store: TaskStore
    private let celebrationProvider: CelebrationProviding
    private let encouragementProvider: EncouragementProviding

    init(store: TaskStore,
         celebrationProvider: CelebrationProviding = CelebrationProvider(),
         encouragementProvider: EncouragementProviding = EncouragementProvider()) {
        self.store = store
        self.celebrationProvider = celebrationProvider
        self.encouragementProvider = encouragementProvider
    }

    func refresh(referenceDate: Date = Date(), animate: Bool = false) async throws {
        let previousCount = tasks.count
        let fetched = try await store.fetchIncompleteTasksForToday(referenceDate: referenceDate)
        if animate {
            withAnimation(.easeOut(duration: 0.3)) {
                tasks = fetched
            }
        } else {
            tasks = fetched
        }

        if previousCount > 0 && fetched.isEmpty {
            celebration = celebrationProvider.nextCelebration()
        }

        pruneCompletedAnimationFlags()
        try updateAddAvailability(referenceDate: referenceDate)
    }

    func complete(task: TaskItem) async throws {
        try store.markTaskCompleted(task)
        recentlyCompletedTaskIDs.insert(task.id)
    }

    func clearCompletionAnimation(for taskID: UUID) {
        recentlyCompletedTaskIDs.remove(taskID)
    }

    func dismissCelebration() {
        celebration = nil
    }

    func resetTodayTasks(referenceDate: Date = Date()) async throws {
        try store.clearTodayTasks(referenceDate: referenceDate)
        recentlyCompletedTaskIDs.removeAll()
        celebration = nil
        limitState = nil
        try await refresh(referenceDate: referenceDate, animate: true)
    }

    private func pruneCompletedAnimationFlags() {
        let remainingIDs = Set(tasks.map(\.id))
        recentlyCompletedTaskIDs = recentlyCompletedTaskIDs.intersection(remainingIDs)
    }

    private func updateAddAvailability(referenceDate: Date) throws {
        let limitReached = try store.isDailyLimitReached(referenceDate: referenceDate)
        canAddTask = !limitReached
        limitState = limitReached ? encouragementProvider.nextMessage() : nil
    }
}
