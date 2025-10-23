//
//  HistoryNavigationState.swift
//  SimpleFocus
//
//  Created by Codex on 2025-10-22.
//

import Combine

@MainActor
final class HistoryNavigationState: ObservableObject {
    @Published private(set) var isShowingHistory: Bool = false

    func showHistory() {
        isShowingHistory = true
    }

    func dismissHistory() {
        isShowingHistory = false
    }
}
