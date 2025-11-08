//
//  AppState.swift
//  SimpleFocus
//
//  Created by Codex on 2025-10-29.
//

import SwiftUI

enum AppState {
    @AppStorage("hasAttemptedReviewRequest") static var hasAttemptedReviewRequest: Bool = false

    static func attemptReviewRequest(source: String) {
        guard hasAttemptedReviewRequest == false else { return }
        ReviewService.requestReview()
        hasAttemptedReviewRequest = true
#if DEBUG
        print("[Review] Request triggered from \(source)")
#endif
    }
}
