//
//  AppLifecycleManager.swift
//  SimpleFocus
//
//  Created by Codex on 2025-11-09.
//

import Combine
import OSLog
import SwiftData
import SwiftUI

@MainActor
final class AppLifecycleManager: ObservableObject {
    struct Context: Identifiable {
        let id = UUID()
        let container: ModelContainer
        let store: TaskStore
        let liveActivityController: LiveActivityLifecycleController?
    }

    @Published private(set) var context: Context

    private let logger = Logger(subsystem: "com.zifengguo.SimpleFocus", category: "Persistence")

    init() {
        context = AppLifecycleManager.buildContext(logger: logger)
    }

    func restart() {
        context = AppLifecycleManager.buildContext(logger: logger)
    }
}

@MainActor
private extension AppLifecycleManager {
    static func buildContext(logger: Logger) -> Context {
        let defaults = UserDefaults.appGroup
        do {
            try PersistenceController.migrateIfNeeded(defaults: defaults)
            let mode = PersistenceController.desiredMode(using: defaults)
            let container = try PersistenceController.makeContainer(for: mode)
            return Context(container: container,
                           store: TaskStore(modelContext: container.mainContext),
                           liveActivityController: makeLiveActivityController())
        } catch {
            logger.error("Failed to prepare persistence; falling back to local store. Error: \(error.localizedDescription, privacy: .public)")
            defaults.set(false, forKey: SettingsStorageKeys.cloudSyncEnabled)
            PersistenceController.setActiveMode(.local, defaults: defaults)
            do {
                let container = try PersistenceController.makeContainer(for: .local)
                return Context(container: container,
                               store: TaskStore(modelContext: container.mainContext),
                               liveActivityController: makeLiveActivityController())
            } catch {
                fatalError("Failed to establish fallback local store: \(error)")
            }
        }
    }

    static func makeLiveActivityController() -> LiveActivityLifecycleController? {
#if canImport(ActivityKit)
        if #available(iOS 17.0, *) {
            let manager = SimpleFocusLiveActivityManager()
            return LiveActivityLifecycleController(manager: manager,
                                                   stateBuilder: LiveActivityStateBuilder())
        }
#endif
        return nil
    }
}
