//
//  EncouragementProvider.swift
//  SimpleFocus
//
//  Created by Codex on 2025-10-17.
//

import Foundation

struct EncouragementMessage: Equatable {
    let message: String
    let encouragement: String
}

protocol EncouragementProviding {
    func nextMessage() -> EncouragementMessage
}

struct EncouragementProvider: EncouragementProviding {
    private var messages: [EncouragementMessage] {
        [
            EncouragementMessage(message: LocalizationHelper.text("今日三件大事已妥善安排。"),
                                 encouragement: LocalizationHelper.text("给自己一点掌声，明天继续保持节奏。")),
            EncouragementMessage(message: LocalizationHelper.text("今天的焦点任务已经排满。"),
                                 encouragement: LocalizationHelper.text("好好充电，明天从容再战。")),
            EncouragementMessage(message: LocalizationHelper.text("任务额度已满，保持专注！"),
                                 encouragement: LocalizationHelper.text("留些精力给明天，你正走在正确的路上。"))
        ]
    }

    func nextMessage() -> EncouragementMessage {
        messages.randomElement() ?? messages[0]
    }
}

private enum LocalizationHelper {
    static func text(_ key: String) -> String {
        bundle.localizedString(forKey: key, value: nil, table: nil)
    }

    private static var bundle: Bundle {
        let defaults = UserDefaults.standard
        guard let selection = defaults.string(forKey: languageSelectionKey) else {
            return .main
        }
        let resource: String?
        switch selection {
        case "english":
            resource = "en"
        case "simplifiedChinese":
            resource = "zh-Hans"
        default:
            resource = nil
        }
        if let resource,
           let path = Bundle.main.path(forResource: resource, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle
        }
        return .main
    }

    private static let languageSelectionKey = "settings.language.selection"
}
