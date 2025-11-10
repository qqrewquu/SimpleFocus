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
        #if DEBUG
        print("[LiveActivity] areActivitiesEnabled=\(info.areActivitiesEnabled)")
        #endif
        guard info.areActivitiesEnabled else {
            throw LiveActivityManagerError.activitiesDisabled
        }

        do {
            let attributes = SimpleFocusActivityAttributes()
            let contentState = SimpleFocusActivityAttributes.ContentState(from: state)
            let content = ActivityContent(state: contentState, staleDate: nil)
            let requested = try Activity.request(attributes: attributes, content: content)
            activity = requested
            #if DEBUG
            print("[LiveActivity] request success, id=\(requested.id)")
            #endif
        } catch {
            #if DEBUG
            print("[LiveActivity] request failed: \(error)")
            #endif
            throw error
        }
    }

    func updateActivity(with state: LiveActivityContentState) async throws {
        guard let activity else {
            try await startActivity(with: state)
            return
        }
        let contentState = SimpleFocusActivityAttributes.ContentState(from: state)
        let content = ActivityContent(state: contentState, staleDate: nil)
        await activity.update(content)
        #if DEBUG
        print("[LiveActivity] update success, id=\(activity.id)")
        #endif
    }

    func endActivity(reason: LiveActivityEndReason) async throws {
        guard let activity else { return }
        let dismissal: ActivityUIDismissalPolicy
        switch reason {
        case .completedAllTasks, .manualReset, .dateRolledOver: 
            dismissal = .immediate
        }
        await activity.end(nil, dismissalPolicy: dismissal)
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
