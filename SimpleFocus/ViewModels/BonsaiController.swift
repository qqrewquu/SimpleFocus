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
    private let calendar: Calendar

    init(modelContext: ModelContext,
         calendar: Calendar = .current) {
        self.modelContext = modelContext
        self.calendar = calendar
        self.bonsai = BonsaiController.fetchOrCreate(in: modelContext)
    }

    func refresh() {
        if let latest = try? BonsaiController.fetchExisting(in: modelContext) {
            bonsai = latest
        }
    }

    @discardableResult
    func registerGrowthIfNeeded(for referenceDate: Date) -> (previous: Int, current: Int)? {
        let dayAnchor = calendar.startOfDay(for: referenceDate)
        if let last = bonsai.lastGrowthDate,
           calendar.isDate(last, inSameDayAs: dayAnchor) {
            return nil
        }

        objectWillChange.send()
        let previous = bonsai.growthPoints
        bonsai.growthPoints += 1
        bonsai.lastGrowthDate = dayAnchor
        persistChanges()
        return (previous, bonsai.growthPoints)
    }

    private func persistChanges() {
        do {
            try modelContext.save()
        } catch {
            print("[BonsaiController] Failed to persist Bonsai changes: \(error)")
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
