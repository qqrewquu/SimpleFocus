//
//  LanguageManager.swift
//  SimpleFocus
//
//  Created by Codex on 2025-11-08.
//

import Combine
import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case english
    case simplifiedChinese

    var id: String { rawValue }

    var locale: Locale {
        switch self {
        case .system:
            return .autoupdatingCurrent
        case .english:
            return Locale(identifier: "en")
        case .simplifiedChinese:
            return Locale(identifier: "zh-Hans")
        }
    }
}

final class LanguageManager: ObservableObject {
    static private(set) var shared: LanguageManager?

    @Published var selection: AppLanguage {
        didSet {
            defaults.set(selection.rawValue, forKey: SettingsStorageKeys.languageSelection)
            LanguageManager.shared = self
        }
    }

    var locale: Locale {
        selection.locale
    }

    private let defaults: UserDefaults
    private var bundleCache: [AppLanguage: Bundle] = [:]

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let stored = defaults.string(forKey: SettingsStorageKeys.languageSelection),
           let language = AppLanguage(rawValue: stored) {
            selection = language
        } else {
            selection = .system
        }
        LanguageManager.shared = self
    }

    /// Returns the bundle that matches the current app language selection.
    private var localizationBundle: Bundle {
        switch selection {
        case .system:
            return .main
        case .english:
            return bundle(for: "en")
        case .simplifiedChinese:
            return bundle(for: "zh-Hans")
        }
    }

    private func bundle(for resource: String) -> Bundle {
        if let cached = bundleCache[selection] {
            return cached
        }
        if let path = Bundle.main.path(forResource: resource, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            bundleCache[selection] = bundle
            return bundle
        }
        return .main
    }

    func localized(_ key: String) -> String {
        localizationBundle.localizedString(forKey: key, value: nil, table: nil)
    }

    func localizedFormat(_ key: String, _ args: CVarArg...) -> String {
        localizedFormat(key, arguments: args)
    }

    func localizedFormat(_ key: String, arguments: [CVarArg]) -> String {
        let format = localized(key)
        return String(format: format, locale: locale, arguments: arguments)
    }

    func displayName(for language: AppLanguage) -> String {
        switch language {
        case .system:
            return localized("跟随系统")
        case .english:
            return localized("English")
        case .simplifiedChinese:
            return localized("简体中文")
        }
    }

    static func sharedLocalized(_ key: String) -> String {
        shared?.localized(key) ?? NSLocalizedString(key, comment: "")
    }

    static func sharedLocalizedFormat(_ key: String, _ args: CVarArg...) -> String {
        shared?.localizedFormat(key, arguments: args) ?? String(format: NSLocalizedString(key, comment: ""), arguments: args)
    }
}
