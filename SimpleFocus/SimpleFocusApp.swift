import SwiftData
import SwiftUI

@main
struct SimpleFocusApp: App {
    private let container: ModelContainer
    private let store: TaskStore
    private let liveActivityController: LiveActivityLifecycleController?
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @AppStorage("pendingOnboardingTask") private var pendingOnboardingTask: String = ""

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
            container = try ModelContainer(for: TaskItem.self, configurations: configuration)
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
            if hasCompletedOnboarding {
                ContentView(store: store, liveActivityController: liveActivityController)
                    .modelContainer(container)
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
    }
}
