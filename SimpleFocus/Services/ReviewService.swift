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
        DispatchQueue.main.async {
            guard let scene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else {
                return
            }
            SKStoreReviewController.requestReview(in: scene)
        }
    }
}
