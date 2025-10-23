//
//  LiveActivityManager.swift
//  SimpleFocus
//
//  Created by Codex on 2025-10-22.
//

import Foundation

enum LiveActivityEndReason: Equatable {
    case completedAllTasks
    case manualReset
    case dateRolledOver
}

protocol LiveActivityManaging: AnyObject {
    func startActivity(with state: LiveActivityContentState) async throws
    func updateActivity(with state: LiveActivityContentState) async throws
    func endActivity(reason: LiveActivityEndReason) async throws
}
