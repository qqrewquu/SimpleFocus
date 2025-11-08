//
//  TaskListViewModel.swift
//  SimpleFocus
//
//  Created by Codex on 2025-10-17.
//

import Combine
import Foundation
import SwiftUI
#if canImport(ActivityKit)
import ActivityKit
#endif

@MainActor
final class TaskListViewModel: ObservableObject {
    @Published private(set) var tasks: [TaskItem] = []
    @Published private(set) var celebration: CompletionCelebration?
    @Published private(set) var recentlyCompletedTaskIDs: Set<UUID> = []
    @Published private(set) var canAddTask: Bool = true
    @Published private(set) var limitState: EncouragementMessage?
    @Published private(set) var pendingCompletionTaskIDs: Set<UUID> = []


    var hasTasks: Bool {
        !tasks.isEmpty
    }

    private let store: TaskStore
    private let celebrationProvider: CelebrationProviding
    private let encouragementProvider: EncouragementProviding
    private let calendar: Calendar
    private var liveActivityController: LiveActivityLifecycleController?
    private var currentDayAnchor: Date?
    private var pendingCompletionTasks: [UUID: Task<Void, Never>] = [:]
    private var pendingCompletionHandlers: [UUID: () -> Void] = [:]
    private let completionDelay: TimeInterval

    init(store: TaskStore,
         celebrationProvider: CelebrationProviding? = nil,
         encouragementProvider: EncouragementProviding? = nil,
         completionDelay: TimeInterval = 1.5,
         calendar: Calendar = .current,
         liveActivityController: LiveActivityLifecycleController? = nil) {
        self.store = store
        self.celebrationProvider = celebrationProvider ?? CelebrationProvider()
        self.encouragementProvider = encouragementProvider ?? EncouragementProvider()
        self.completionDelay = completionDelay
        self.calendar = calendar
        self.liveActivityController = liveActivityController
    }

    func setLiveActivityController(_ controller: LiveActivityLifecycleController) {
        liveActivityController = controller
    }

    func toggleCompletion(for task: TaskItem,
                          referenceDate: Date = Date(),
                          onFinalize: (() -> Void)? = nil) {
        let id = task.id
        if pendingCompletionTaskIDs.contains(id) {
            cancelPendingCompletion(for: id)
            return
        }

        pendingCompletionTaskIDs.insert(id)
        recentlyCompletedTaskIDs.insert(id)
        if let onFinalize {
            pendingCompletionHandlers[id] = onFinalize
        } else {
            pendingCompletionHandlers.removeValue(forKey: id)
        }

        let pendingTask = Task { [weak self] in
            guard let self else { return }
            do {
                try await Task.sleep(nanoseconds: UInt64(self.completionDelay * 1_000_000_000))
                try Task.checkCancellation()
                await self.finalizePendingCompletion(taskID: id, referenceDate: referenceDate)
            } catch is CancellationError {
                return
            } catch {
                await MainActor.run {
                    self.handleCompletionFailure(for: id, error: error)
                }
            }
        }

        pendingCompletionTasks[id] = pendingTask
    }

    func isPendingCompletion(_ id: UUID) -> Bool {
        pendingCompletionTaskIDs.contains(id)
    }

    private func finalizePendingCompletion(taskID: UUID,
                                           referenceDate: Date) async {
        do {
            guard let task = try store.task(withID: taskID) else {
                throw NSError(domain: "TaskListViewModel",
                              code: -1,
                              userInfo: [NSLocalizedDescriptionKey: "Task not found for completion"])
            }

            try store.markTaskCompleted(task)
            pendingCompletionTaskIDs.remove(taskID)
            pendingCompletionTasks.removeValue(forKey: taskID)
            let handler = pendingCompletionHandlers.removeValue(forKey: taskID)

            try await refresh(referenceDate: referenceDate, animate: true)

            if let handler {
                handler()
            }
        } catch {
            await MainActor.run {
                self.handleCompletionFailure(for: taskID, error: error)
            }
        }
    }

    private func cancelPendingCompletion(for id: UUID) {
        pendingCompletionTasks[id]?.cancel()
        pendingCompletionTasks.removeValue(forKey: id)
        pendingCompletionHandlers.removeValue(forKey: id)
        pendingCompletionTaskIDs.remove(id)
        recentlyCompletedTaskIDs.remove(id)
    }

    private func cancelAllPendingCompletions() {
        for task in pendingCompletionTasks.values {
            task.cancel()
        }
        pendingCompletionTasks.removeAll()
        pendingCompletionHandlers.removeAll()
        pendingCompletionTaskIDs.removeAll()
    }

    private func prunePendingCompletions(validIDs: Set<UUID>) {
        let invalid = pendingCompletionTaskIDs.subtracting(validIDs)
        for id in invalid {
            cancelPendingCompletion(for: id)
        }
    }

    @MainActor
    private func handleCompletionFailure(for id: UUID, error: Error) {
        pendingCompletionTasks.removeValue(forKey: id)
        pendingCompletionHandlers.removeValue(forKey: id)
        pendingCompletionTaskIDs.remove(id)
        recentlyCompletedTaskIDs.remove(id)
        #if DEBUG
        print("[TaskListViewModel] Failed to finalize completion for \(id): \(error)")
        #endif
    }


    func refresh(referenceDate: Date = Date(), animate: Bool = false) async throws {
        let dayAnchor = calendar.startOfDay(for: referenceDate)
        let staleCount = try store.staleIncompleteTaskCount(before: dayAnchor)
        let movedToNewDay = currentDayAnchor.map { dayAnchor > $0 } ?? false
        let needsInitialRolloverHandling = (currentDayAnchor == nil && staleCount > 0)
        let rolledOverFromPreviousDay = movedToNewDay || needsInitialRolloverHandling

        if rolledOverFromPreviousDay {
            recentlyCompletedTaskIDs.removeAll()
            celebration = nil
            limitState = nil
            cancelAllPendingCompletions()

            if let controller = liveActivityController, controller.isActivityRunning {
                try await controller.endActivity(reason: .dateRolledOver)
            }
        }

        currentDayAnchor = dayAnchor

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
            AppState.attemptReviewRequest(source: "completed_first_day_tasks")
        }

        pruneCompletedAnimationFlags()
        prunePendingCompletions(validIDs: Set(fetched.map(\.id)))
        try updateAddAvailability(referenceDate: referenceDate)

        if let controller = liveActivityController {
            do {
                let todaysTasks = try await store.fetchTasksForToday(referenceDate: referenceDate)
                #if DEBUG
                print("[LiveActivity] refreshing with tasks:", todaysTasks.map(\.content))
                #endif
                try await controller.handleTasksChanged(referenceDate: referenceDate, tasks: todaysTasks)
                #if canImport(ActivityKit)
                if #available(iOS 17.0, *) {
                    let activities = Activity<SimpleFocusActivityAttributes>.activities
                    #if DEBUG
                    print("[LiveActivity] active IDs:", activities.map(\.id))
                    #endif
                }
                #endif
            } catch {
                #if DEBUG
                if let managerError = error as? LiveActivityManagerError {
                    switch managerError {
                    case .unsupportedTarget:
                        print("[LiveActivity] 当前设备/模拟器不支持 Live Activity 展示，已忽略。")
                    case .activitiesDisabled:
                        print("[LiveActivity] Live Activity 功能未启用。");
                    }
                } else {
                    let message = String(describing: error)
                    if message.contains("unsupportedTarget") {
                        print("[LiveActivity] 系统返回 unsupportedTarget（该运行时目前无法展示 Live Activity）。")
                    } else {
                        print("[LiveActivity] Failed to update: \(message)")
                    }
                }
                #endif
            }
        }
    }

    func edit(task: TaskItem, newContent: String, referenceDate: Date = Date()) async throws {
        let normalized = try normalizeContent(from: newContent)
        try store.updateTask(task, with: normalized)
        try await refresh(referenceDate: referenceDate)
    }

    func clearCompletionAnimation(for taskID: UUID) {
        recentlyCompletedTaskIDs.remove(taskID)
    }

    func dismissCelebration() {
        celebration = nil
    }

    func resetTodayTasks(referenceDate: Date = Date()) async throws {
        try store.clearTodayTasks(referenceDate: referenceDate)
        cancelAllPendingCompletions()
        recentlyCompletedTaskIDs.removeAll()
        celebration = nil
        limitState = nil
        currentDayAnchor = calendar.startOfDay(for: referenceDate)
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

    private func normalizeContent(from raw: String) throws -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw TaskInputError.emptyContent
        }
        return String(trimmed.prefix(TaskContentPolicy.maxLength))
    }
}
