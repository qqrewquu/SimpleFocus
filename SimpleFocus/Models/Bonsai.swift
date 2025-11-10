//
//  Bonsai.swift
//  SimpleFocus
//
//  Created by Codex on 2025-10-29.
//

import Foundation
import SwiftData

@Model
final class Bonsai {
    var creationDate: Date = Date()
    var growthPoints: Int = 0
    var lastGrowthDate: Date?

    init(creationDate: Date = .now,
         growthPoints: Int = 0,
         lastGrowthDate: Date? = nil) {
        self.creationDate = creationDate
        self.growthPoints = growthPoints
        self.lastGrowthDate = lastGrowthDate
    }
}
