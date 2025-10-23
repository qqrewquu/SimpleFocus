//
//  LiveActivityManagerSpy.swift
//  SimpleFocusTests
//
//  Created by Codex on 2025-10-22.
//

import Foundation
@testable import SimpleFocus

final class LiveActivityManagerSpy: LiveActivityManaging {
    private(set) var startedActivities: [LiveActivityContentState] = []
    private(set) var updatedActivities: [LiveActivityContentState] = []
    private(set) var endedActivities: [LiveActivityEndReason] = []
    var startResult: Result<Void, Error> = .success(())
    var updateResult: Result<Void, Error> = .success(())
    var endResult: Result<Void, Error> = .success(())

    func startActivity(with state: LiveActivityContentState) async throws {
        startedActivities.append(state)
        switch startResult {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }

    func updateActivity(with state: LiveActivityContentState) async throws {
        updatedActivities.append(state)
        switch updateResult {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }

    func endActivity(reason: LiveActivityEndReason) async throws {
        endedActivities.append(reason)
        switch endResult {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }
}
