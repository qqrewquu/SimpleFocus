//
//  AppTheme.swift
//  SimpleFocus
//
//  Created by Codex on 2025-10-17.
//

import SwiftUI

enum AppTheme {
    static let background = Color(red: 16 / 255, green: 25 / 255, blue: 35 / 255)
    static let primary = Color(red: 10 / 255, green: 132 / 255, blue: 1.0)
    static let primaryDisabled = Color.white.opacity(0.15)
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.65)
    static let surfaceElevated = Color.white.opacity(0.08)
    static let surfaceMuted = Color.white.opacity(0.04)
    static let warning = Color(red: 1.0, green: 0.62, blue: 0.24)
    static let accentGradient = LinearGradient(
        gradient: Gradient(colors: [
            Color(red: 0.38, green: 0.72, blue: 1.0),
            Color(red: 0.35, green: 0.56, blue: 1.0),
            Color(red: 0.49, green: 0.38, blue: 1.0)
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
