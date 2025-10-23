//
//  SimpleFocusActivityAttributes.swift
//  SimpleFocus
//
//  Created by Codex on 2025-10-22.
//

import Foundation

#if canImport(ActivityKit)
import ActivityKit

@available(iOS 17.0, *)
struct SimpleFocusActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public let tasks: [LiveActivityDisplayTask]
        public let totalTasks: Int
        public let completedTasks: Int
        public let remainingTasks: Int
        public let progress: Double
        public let statusMessage: String
    }

    public var title: String = "SimpleFocus"
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
