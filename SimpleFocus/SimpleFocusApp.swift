import OSLog
import SwiftData
import SwiftUI

@main
@MainActor
struct SimpleFocusApp: App {
    private let container: ModelContainer
    private let store: TaskStore
    private let liveActivityController: LiveActivityLifecycleController?
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @AppStorage("pendingOnboardingTask") private var pendingOnboardingTask: String = ""
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var languageManager = LanguageManager()
    @AppStorage(SettingsStorageKeys.cloudSyncEnabled, store: UserDefaults.appGroup) private var isCloudSyncEnabled: Bool = true
    private let persistenceLogger = Logger(subsystem: "com.zifengguo.SimpleFocus", category: "Persistence")

    init() {
        let defaults = UserDefaults.appGroup
        do {
            try PersistenceController.migrateIfNeeded(defaults: defaults)
            let mode = PersistenceController.desiredMode(using: defaults)
            container = try PersistenceController.makeContainer(for: mode)
        } catch {
            persistenceLogger.error("Failed to prepare persistence; falling back to local store. Error: \(error.localizedDescription, privacy: .public)")
            defaults.set(false, forKey: SettingsStorageKeys.cloudSyncEnabled)
            PersistenceController.setActiveMode(.local, defaults: defaults)
            do {
                container = try PersistenceController.makeContainer(for: .local)
            } catch {
                fatalError("Failed to establish fallback local store: \(error)")
            }
        }
        store = TaskStore(modelContext: container.mainContext)

#if canImport(ActivityKit)
        if #available(iOS 17.0, *) {
            let manager = SimpleFocusLiveActivityManager()
            liveActivityController = LiveActivityLifecycleController(manager: manager,
                                                                     stateBuilder: LiveActivityStateBuilder())
        } else {
            liveActivityController = nil
        }
#else
        liveActivityController = nil
#endif
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    MainTabView(store: store,
                                container: container,
                                liveActivityController: liveActivityController)
                } else {
                    OnboardingView(
                        viewModel: OnboardingViewModel(
                            onFinish: { goal in
                                pendingOnboardingTask = goal
                                hasCompletedOnboarding = true
                            },
                            onSkip: {
                                pendingOnboardingTask = ""
                                hasCompletedOnboarding = true
                            }
                        )
                    )
                    .modelContainer(container)
                }
            }
            .environmentObject(themeManager)
            .environmentObject(languageManager)
            .environment(\.themePalette, themeManager.palette)
            .environment(\.locale, languageManager.locale)
            .preferredColorScheme(themeManager.mode == .dark ? .dark : .light)
        }
    }
}
