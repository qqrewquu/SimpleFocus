import SwiftUI

@main
struct SimpleFocusApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @AppStorage("pendingOnboardingTask") private var pendingOnboardingTask: String = ""
    @StateObject private var lifecycleManager = AppLifecycleManager()
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var languageManager = LanguageManager()

    var body: some Scene {
        WindowGroup {
            let context = lifecycleManager.context
            Group {
                if hasCompletedOnboarding {
                    MainTabView(store: context.store,
                                container: context.container,
                                liveActivityController: context.liveActivityController)
                        .id(context.id)
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
                    .modelContainer(context.container)
                }
            }
            .environmentObject(themeManager)
            .environmentObject(languageManager)
            .environmentObject(lifecycleManager)
            .environment(\.themePalette, themeManager.palette)
            .environment(\.locale, languageManager.locale)
            .preferredColorScheme(themeManager.mode == .dark ? .dark : .light)
        }
    }
}
