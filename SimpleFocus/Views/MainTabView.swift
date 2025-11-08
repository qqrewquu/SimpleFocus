//
//  MainTabView.swift
//  SimpleFocus
//
//  Created by Codex on 2025-10-29.
//

import SwiftData
import SwiftUI

struct MainTabView: View {
    private enum Tab {
        case home
        case bonsai
        case history
        case settings
    }

    private let store: TaskStore
    private let container: ModelContainer
    private let liveActivityController: LiveActivityLifecycleController?

    @State private var selectedTab: Tab = .home
    @StateObject private var focusCalendarViewModel: FocusCalendarViewModel
    @StateObject private var settingsViewModel: SettingsViewModel

    init(store: TaskStore,
         container: ModelContainer,
         liveActivityController: LiveActivityLifecycleController?) {
        self.store = store
        self.container = container
        self.liveActivityController = liveActivityController
        _focusCalendarViewModel = StateObject(wrappedValue: FocusCalendarViewModel(store: store))
        _settingsViewModel = StateObject(wrappedValue: SettingsViewModel(scheduler: ReminderNotificationScheduler()))
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            ContentView(store: store,
                        liveActivityController: liveActivityController,
                        focusCalendarViewModel: focusCalendarViewModel)
                .tabItem {
                    Label("主页", systemImage: "list.bullet")
                }
                .tag(Tab.home)

            BonsaiPlaceholderView()
                .tabItem {
                    Label("盆景", systemImage: "leaf.fill")
                }
                .tag(Tab.bonsai)

            HistoryView(calendarViewModel: focusCalendarViewModel,
                        showsDismissButton: false)
                .tabItem {
                    Label("历史", systemImage: "clock.arrow.circlepath")
                }
                .tag(Tab.history)

            SettingsView(viewModel: settingsViewModel,
                         showsDoneButton: false)
                .tabItem {
                    Label("设置", systemImage: "gearshape.fill")
                }
                .tag(Tab.settings)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .modelContainer(container)
    }
}
