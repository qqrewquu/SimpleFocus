//
//  UserDefaults+AppGroup.swift
//  SimpleFocus
//
//  Created by Codex on 2025-11-09.
//

import Foundation

extension UserDefaults {
    static let appGroup: UserDefaults = {
        if let defaults = UserDefaults(suiteName: AppGroup.identifier) {
            return defaults
        }
        return .standard
    }()
}
