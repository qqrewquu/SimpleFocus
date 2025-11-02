//
//  LiveActivitySharedModels.swift
//  SimpleFocus
//
//  Created by Codex on 2025-10-27.
//

import Foundation

#if canImport(ActivityKit)
import ActivityKit
#endif

struct LiveActivityDisplayTask: Codable, Hashable, Identifiable {
    let id: UUID
    let content: String
    let isCompleted: Bool
}

struct LiveActivityContentState: Codable, Hashable {
    let displayedTasks: [LiveActivityDisplayTask]
    let totalTasks: Int
    let completedTasks: Int
    let remainingTasks: Int
    let progress: Double
    let statusMessage: String
}

#if canImport(ActivityKit)
@available(iOS 17.0, *)
struct SimpleFocusActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        let tasks: [LiveActivityDisplayTask]
        let totalTasks: Int
        let completedTasks: Int
        let remainingTasks: Int
        let progress: Double
        let statusMessage: String
    }

    var title: String = "SimpleFocus"
}

@available(iOS 17.0, *)
extension SimpleFocusActivityAttributes.ContentState {
    init(from state: LiveActivityContentState) {
        self.init(tasks: state.displayedTasks,
                  totalTasks: state.totalTasks,
                  completedTasks: state.completedTasks,
                  remainingTasks: state.remainingTasks,
                  progress: state.progress,
                  statusMessage: state.statusMessage)
    }
}
#endif
