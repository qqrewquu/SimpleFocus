//
//  SimpleFocusLiveActivityManager.swift
//  SimpleFocus
//
//  Created by Codex on 2025-10-22.
//

import Foundation

#if canImport(ActivityKit)
import ActivityKit

enum LiveActivityManagerError: Error {
    case activitiesDisabled
    case unsupportedTarget
}

@available(iOS 17.0, *)
final class SimpleFocusLiveActivityManager: LiveActivityManaging {
    private var activity: Activity<SimpleFocusActivityAttributes>?

    func startActivity(with state: LiveActivityContentState) async throws {
        let info = ActivityAuthorizationInfo()
        guard info.areActivitiesEnabled else {
            throw LiveActivityManagerError.activitiesDisabled
        }
        if info.activityAuthorizationStatus != .approved {
            throw LiveActivityManagerError.unsupportedTarget
        }

        let attributes = SimpleFocusActivityAttributes()
        let contentState = SimpleFocusActivityAttributes.ContentState(from: state)
        let content = ActivityContent(state: contentState, staleDate: nil)
        activity = try Activity.request(attributes: attributes, content: content)
    }

    func updateActivity(with state: LiveActivityContentState) async throws {
        guard let activity else {
            try await startActivity(with: state)
            return
        }
        let contentState = SimpleFocusActivityAttributes.ContentState(from: state)
        let content = ActivityContent(state: contentState, staleDate: nil)
        try await activity.update(content)
    }

    func endActivity(reason: LiveActivityEndReason) async throws {
        guard let activity else { return }
        let dismissal: ActivityUIDismissalPolicy
        switch reason {
        case .completedAllTasks, .manualReset, .dateRolledOver:
            dismissal = .immediate
        }
        await activity.end(dismissalPolicy: dismissal)
        self.activity = nil
    }
}
#else
final class SimpleFocusLiveActivityManager: LiveActivityManaging {
    func startActivity(with state: LiveActivityContentState) async throws {}
    func updateActivity(with state: LiveActivityContentState) async throws {}
    func endActivity(reason: LiveActivityEndReason) async throws {}
}
#endif
