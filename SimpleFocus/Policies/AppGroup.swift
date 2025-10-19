//
//  AppGroup.swift
//  SimpleFocus
//
//  Created by Codex on 2025-10-17.
//

import Foundation

enum AppGroup {
    /// Update this identifier to match the App Group configured in Xcode capabilities.
    static let identifier = "group.com.zifengguo.simple-focus"

    static func containerURL() -> URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
    }
}
