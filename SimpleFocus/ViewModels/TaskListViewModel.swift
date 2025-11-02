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

    var hasTasks: Bool {
        !tasks.isEmpty
    }

    private let store: TaskStore
    private let celebrationProvider: CelebrationProviding
    private let encouragementProvider: EncouragementProviding
    private let calendar: Calendar
    private var liveActivityController: LiveActivityLifecycleController?
    private var currentDayAnchor: Date?

    init(store: TaskStore,
         celebrationProvider: CelebrationProviding? = nil,
         encouragementProvider: EncouragementProviding? = nil,
         calendar: Calendar = .current,
         liveActivityController: LiveActivityLifecycleController? = nil) {
        self.store = store
        self.celebrationProvider = celebrationProvider ?? CelebrationProvider()
        self.encouragementProvider = encouragementProvider ?? EncouragementProvider()
        self.calendar = calendar
        self.liveActivityController = liveActivityController
    }

    func setLiveActivityController(_ controller: LiveActivityLifecycleController) {
        liveActivityController = controller
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
        }

        pruneCompletedAnimationFlags()
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

    func complete(task: TaskItem) async throws {
        try store.markTaskCompleted(task)
        recentlyCompletedTaskIDs.insert(task.id)
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
