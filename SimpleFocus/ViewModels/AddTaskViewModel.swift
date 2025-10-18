//
//  AddTaskViewModel.swift
//  SimpleFocus
//
//  Created by Codex on 2025-10-17.
//

import Combine
import Foundation

enum TaskInputError: Error, Equatable {
    case emptyContent
    case limitReached
}

@MainActor
final class AddTaskViewModel: ObservableObject {
    static let maxLength = 20

    @Published var content: String = "" {
        didSet {
            if content.count > Self.maxLength {
                content = String(content.prefix(Self.maxLength))
            }
        }
    }

    var canSubmit: Bool {
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private let store: TaskStore

    init(store: TaskStore) {
        self.store = store
    }

    func submit(content overrideContent: String? = nil) throws -> TaskItem {
        let rawContent = overrideContent ?? content
        let trimmed = rawContent.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw TaskInputError.emptyContent
        }

        if try store.isDailyLimitReached() {
            throw TaskInputError.limitReached
        }

        let finalContent = String(trimmed.prefix(Self.maxLength))
        let task = try store.createTask(with: finalContent)
        if overrideContent == nil {
            content = ""
        }
        return task
    }
}
