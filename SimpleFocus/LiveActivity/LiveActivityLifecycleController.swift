//
//  LiveActivityLifecycleController.swift
//  SimpleFocus
//
//  Created by Codex on 2025-10-22.
//

import Foundation

@MainActor
final class LiveActivityLifecycleController {
    private let manager: LiveActivityManaging
    private let stateBuilder: LiveActivityStateBuilder
    private(set) var isActivityRunning = false

    init(manager: LiveActivityManaging,
         stateBuilder: LiveActivityStateBuilder) {
        self.manager = manager
        self.stateBuilder = stateBuilder
    }

    func handleTasksChanged(referenceDate: Date = Date(),
                            tasks: [TaskItem]) async throws {
        if let state = stateBuilder.makeContentState(referenceDate: referenceDate, tasks: tasks) {
            if isActivityRunning {
                try await manager.updateActivity(with: state)
            } else {
                try await manager.startActivity(with: state)
                isActivityRunning = true
            }
        } else {
            try await endActivity(reason: .completedAllTasks)
        }
    }

    func endActivity(reason: LiveActivityEndReason) async throws {
        try await manager.endActivity(reason: reason)
        isActivityRunning = false
    }
}
