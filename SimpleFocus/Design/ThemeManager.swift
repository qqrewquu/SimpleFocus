//
//  ThemeManager.swift
//  SimpleFocus
//
//  Created by Codex on 2025-10-29.
//

import Combine
import Foundation
import SwiftUI

enum AppThemeMode: String, CaseIterable, Identifiable {
    case dark
    case light

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .dark:
            return "夜间"
        case .light:
            return "日间"
        }
    }
}

final class ThemeManager: ObservableObject {
    private static let storageKey = "preferredThemeMode"

    @Published var mode: AppThemeMode {
        didSet {
            UserDefaults.standard.set(mode.rawValue, forKey: Self.storageKey)
        }
    }

    var palette: AppThemePalette {
        switch mode {
        case .dark:
            return AppTheme.dark
        case .light:
            return AppTheme.light
        }
    }

    init() {
        if let stored = UserDefaults.standard.string(forKey: Self.storageKey),
           let storedMode = AppThemeMode(rawValue: stored) {
            mode = storedMode
        } else {
            mode = .dark
        }
    }
}

private struct ThemePaletteKey: EnvironmentKey {
    static let defaultValue: AppThemePalette = AppTheme.dark
}

extension EnvironmentValues {
    var themePalette: AppThemePalette {
        get { self[ThemePaletteKey.self] }
        set { self[ThemePaletteKey.self] = newValue }
    }
}
