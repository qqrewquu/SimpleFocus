//
//  AppTheme.swift
//  SimpleFocus
//
//  Created by Codex on 2025-10-17.
//

import SwiftUI

struct AppThemePalette {
    let background: Color
    let surfaceElevated: Color
    let surfaceMuted: Color
    let textPrimary: Color
    let textSecondary: Color
    let primary: Color
    let primaryDisabled: Color
    let warning: Color
    let accentGradient: LinearGradient
    let tabActive: Color
    let tabInactive: Color
}

enum AppTheme {
    static let primaryDisabled = Color.white.opacity(0.15)
    static let dark = AppThemePalette(
        background: Color(red: 16 / 255, green: 25 / 255, blue: 35 / 255),
        surfaceElevated: Color.white.opacity(0.08),
        surfaceMuted: Color.white.opacity(0.04),
        textPrimary: Color.white,
        textSecondary: Color.white.opacity(0.65),
        primary: Color(red: 10 / 255, green: 132 / 255, blue: 1.0),
        primaryDisabled: Color.white.opacity(0.15),
        warning: Color(red: 1.0, green: 0.62, blue: 0.24),
        accentGradient: LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.38, green: 0.72, blue: 1.0),
                Color(red: 0.35, green: 0.56, blue: 1.0),
                Color(red: 0.49, green: 0.38, blue: 1.0)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        tabActive: Color(red: 10 / 255, green: 132 / 255, blue: 1.0),
        tabInactive: Color.white.opacity(0.45)
    )

    static let light = AppThemePalette(
        background: Color(red: 245 / 255, green: 246 / 255, blue: 248 / 255),
        surfaceElevated: Color.white,
        surfaceMuted: Color(red: 229 / 255, green: 233 / 255, blue: 240 / 255),
        textPrimary: Color(red: 23 / 255, green: 32 / 255, blue: 41 / 255),
        textSecondary: Color(red: 23 / 255, green: 32 / 255, blue: 41 / 255).opacity(0.6),
        primary: Color(red: 0 / 255, green: 122 / 255, blue: 255 / 255),
        primaryDisabled: Color(red: 0 / 255, green: 122 / 255, blue: 255 / 255).opacity(0.25),
        warning: Color(red: 0.98, green: 0.45, blue: 0.15),
        accentGradient: LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.25, green: 0.55, blue: 1.0),
                Color(red: 0.13, green: 0.45, blue: 0.93)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        tabActive: Color(red: 0 / 255, green: 122 / 255, blue: 255 / 255),
        tabInactive: Color(red: 70 / 255, green: 82 / 255, blue: 96 / 255)
    )
}
