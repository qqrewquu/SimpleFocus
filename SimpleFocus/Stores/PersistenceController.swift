//
//  PersistenceController.swift
//  SimpleFocus
//
//  Created by Codex on 2025-11-09.
//

import Foundation
import SwiftData

enum DataStorageMode: String {
    case local
    case cloud
}

enum PersistenceError: Error {
    case missingAppGroupContainer
}

enum PersistenceController {
    static func desiredMode(using defaults: UserDefaults = .appGroup) -> DataStorageMode {
        if defaults.object(forKey: SettingsStorageKeys.cloudSyncEnabled) == nil {
            defaults.set(true, forKey: SettingsStorageKeys.cloudSyncEnabled)
        }
        return defaults.bool(forKey: SettingsStorageKeys.cloudSyncEnabled) ? .cloud : .local
    }

    static func activeMode(using defaults: UserDefaults = .appGroup) -> DataStorageMode {
        if let raw = defaults.string(forKey: SettingsStorageKeys.activeStorageMode),
           let mode = DataStorageMode(rawValue: raw) {
            return mode
        }
        defaults.set(DataStorageMode.local.rawValue, forKey: SettingsStorageKeys.activeStorageMode)
        return .local
    }

    static func setActiveMode(_ mode: DataStorageMode, defaults: UserDefaults = .appGroup) {
        defaults.set(mode.rawValue, forKey: SettingsStorageKeys.activeStorageMode)
    }

    /// Ensures the data in the destination storage matches the user's preferred storage mode.
    @discardableResult
    static func migrateIfNeeded(defaults: UserDefaults = .appGroup) throws -> Bool {
        let desired = desiredMode(using: defaults)
        let current = activeMode(using: defaults)
        guard desired != current else { return false }

        try migrateData(from: current, to: desired)
        setActiveMode(desired, defaults: defaults)
        return true
    }

    static func makeContainer(for mode: DataStorageMode) throws -> ModelContainer {
        let configuration: ModelConfiguration
        switch mode {
        case .local:
            guard let sharedURL = AppGroup.containerURL()?.appending(path: CloudSyncConfig.storeFilename,
                                                                     directoryHint: .notDirectory) else {
                throw PersistenceError.missingAppGroupContainer
            }
            configuration = ModelConfiguration(url: sharedURL)
        case .cloud:
            configuration = ModelConfiguration(cloudKitContainerIdentifier: CloudSyncConfig.containerIdentifier)
        }
        return try ModelContainer(for: TaskItem.self, Bonsai.self, configurations: configuration)
    }

    private static func migrateData(from sourceMode: DataStorageMode,
                                    to destinationMode: DataStorageMode) throws {
        let sourceContainer = try makeContainer(for: sourceMode)
        let destinationContainer = try makeContainer(for: destinationMode)
        let sourceContext = sourceContainer.mainContext
        let destinationContext = destinationContainer.mainContext

        let sourceTasks = try sourceContext.fetch(FetchDescriptor<TaskItem>())
        let sourceBonsai = try sourceContext.fetch(FetchDescriptor<Bonsai>())

        let destinationTasks = try destinationContext.fetch(FetchDescriptor<TaskItem>())
        destinationTasks.forEach { destinationContext.delete($0) }
        let destinationBonsai = try destinationContext.fetch(FetchDescriptor<Bonsai>())
        destinationBonsai.forEach { destinationContext.delete($0) }

        for task in sourceTasks {
            let copy = TaskItem(id: task.id,
                                content: task.content,
                                creationDate: task.creationDate,
                                isCompleted: task.isCompleted)
            destinationContext.insert(copy)
        }

        for bonsai in sourceBonsai {
            let copy = Bonsai(creationDate: bonsai.creationDate,
                              growthPoints: bonsai.growthPoints,
                              lastGrowthDate: bonsai.lastGrowthDate)
            destinationContext.insert(copy)
        }

        try destinationContext.save()
    }
}
