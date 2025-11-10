import SwiftData
import SwiftUI

@main
struct SimpleFocusApp: App {
    private let container: ModelContainer
    private let store: TaskStore
    private let liveActivityController: LiveActivityLifecycleController?
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @AppStorage("pendingOnboardingTask") private var pendingOnboardingTask: String = ""
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var languageManager = LanguageManager()

    init() {
        do {
            if let containerURL = AppGroup.containerURL() {
                print("[SimpleFocus] App Group container: \(containerURL.path(percentEncoded: false))")
                do {
                    let contents = try FileManager.default.contentsOfDirectory(at: containerURL,
                                                                               includingPropertiesForKeys: nil,
                                                                               options: [.skipsHiddenFiles])
                    if contents.isEmpty {
                        print("[SimpleFocus] App Group container is empty.")
                    } else {
                        for item in contents {
                            print("[SimpleFocus] App Group item: \(item.lastPathComponent)")
                        }
                    }
                } catch {
                    print("[SimpleFocus] Failed to list App Group contents: \(error)")
                }
            } else {
                print("[SimpleFocus] App Group container unavailable.")
            }

            guard let sharedURL = AppGroup.containerURL()?.appending(path: "SimpleFocus.sqlite",
                                                                     directoryHint: .notDirectory) else {
                fatalError("Unable to locate shared App Group container file.")
            }
            let configuration = ModelConfiguration(url: sharedURL)
            container = try ModelContainer(for: TaskItem.self, Bonsai.self, configurations: configuration)
        } catch {
            fatalError("Failed to create model container: \(error)")
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
