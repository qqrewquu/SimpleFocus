//
//  CelebrationProvider.swift
//  SimpleFocus
//
//  Created by Codex on 2025-10-17.
//

import Foundation

struct CelebrationQuote: Equatable {
    let text: String
    let author: String
}

struct CompletionCelebration: Identifiable, Equatable {
    let id: UUID
    let title: String
    let quote: CelebrationQuote

    init(id: UUID = UUID(), title: String, quote: CelebrationQuote) {
        self.id = id
        self.title = title
        self.quote = quote
    }
}

protocol CelebrationProviding {
    func nextCelebration() -> CompletionCelebration
}

struct CelebrationProvider: CelebrationProviding {
    private var title: String {
        LocalizationHelper.text("恭喜完成全部任务！")
    }

    private let quotes: [CelebrationQuote] = [
        CelebrationQuote(text: "Stay hungry, stay foolish.", author: "Steve Jobs"),
        CelebrationQuote(text: "The future depends on what you do today.", author: "Mahatma Gandhi"),
        CelebrationQuote(text: "Well done is better than well said.", author: "Benjamin Franklin"),
        CelebrationQuote(text: "Focus on being productive instead of busy.", author: "Tim Ferriss"),
        CelebrationQuote(text: "Either you run the day or the day runs you.", author: "Jim Rohn")
    ]

    func nextCelebration() -> CompletionCelebration {
        let selected = quotes.randomElement() ?? quotes[0]
        return CompletionCelebration(title: title, quote: selected)
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
