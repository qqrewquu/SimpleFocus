//
//  BonsaiController.swift
//  SimpleFocus
//
//  Created by Codex on 2025-10-29.
//

import Combine
import Foundation
import SwiftData

@MainActor
final class BonsaiController: ObservableObject {
    @Published private(set) var bonsai: Bonsai

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.bonsai = BonsaiController.fetchOrCreate(in: modelContext)
    }

    func refresh() {
        if let latest = try? BonsaiController.fetchExisting(in: modelContext) {
            bonsai = latest
        }
    }

    private static func fetchOrCreate(in context: ModelContext) -> Bonsai {
        if let existing = try? fetchExisting(in: context) {
            return existing
        }

        let bonsai = Bonsai()
        context.insert(bonsai)
        do {
            try context.save()
        } catch {
            print("[BonsaiController] Failed to save new bonsai: \(error)")
        }
        return bonsai
    }

    private static func fetchExisting(in context: ModelContext) throws -> Bonsai? {
        var descriptor = FetchDescriptor<Bonsai>(
            sortBy: [SortDescriptor(\.creationDate, order: .forward)]
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
}
