//
//  ReviewService.swift
//  SimpleFocus
//
//  Created by Codex on 2025-10-29.
//

import Foundation
import StoreKit
import UIKit

enum ReviewService {
    static func requestReview() {
        guard let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else {
            return
        }

        if #available(iOS 18.0, *) {
            Task { @MainActor in
                try? await AppStore.requestReview(in: scene)
            }
        } else {
            DispatchQueue.main.async {
                SKStoreReviewController.requestReview(in: scene)
            }
        }
    }
}
