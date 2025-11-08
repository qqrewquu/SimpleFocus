//
//  MainTabView.swift
//  SimpleFocus
//
//  Created by Codex on 2025-10-29.
//

import SwiftData
import SwiftUI
import UIKit

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
    @AppStorage("hasNewBonsaiGrowth") private var hasNewBonsaiGrowth: Bool = false

    @State private var selectedTab: Tab = .home
    @StateObject private var focusCalendarViewModel: FocusCalendarViewModel
    @StateObject private var settingsViewModel: SettingsViewModel
    @StateObject private var bonsaiController: BonsaiController
    @Environment(\.themePalette) private var theme
    @EnvironmentObject private var themeManager: ThemeManager

    init(store: TaskStore,
         container: ModelContainer,
         liveActivityController: LiveActivityLifecycleController?) {
        self.store = store
        self.container = container
        self.liveActivityController = liveActivityController
        let context = container.mainContext
        _focusCalendarViewModel = StateObject(wrappedValue: FocusCalendarViewModel(store: store))
        _settingsViewModel = StateObject(wrappedValue: SettingsViewModel(scheduler: ReminderNotificationScheduler()))
        _bonsaiController = StateObject(wrappedValue: BonsaiController(modelContext: context))
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            ContentView(store: store,
                        liveActivityController: liveActivityController,
                        focusCalendarViewModel: focusCalendarViewModel,
                        bonsaiController: bonsaiController)
                .tabItem {
                    Label("主页", systemImage: "list.bullet")
                }
                .tag(Tab.home)

            BonsaiView(controller: bonsaiController)
                .tabItem {
                    Label("盆景", systemImage: "leaf.fill")
                }
                .tag(Tab.bonsai)
                .badge(hasNewBonsaiGrowth ? "●" : nil)

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
        .tint(theme.tabActive)
        .background(theme.background.ignoresSafeArea())
        .modelContainer(container)
        .onAppear {
            applyTabAppearance(for: theme)
        }
        .onChange(of: themeManager.mode) { _ in
            applyTabAppearance(for: themeManager.palette)
        }
        .onChange(of: selectedTab) { _, newValue in
            if newValue == .bonsai {
                hasNewBonsaiGrowth = false
            }
        }
    }

    private func applyTabAppearance(for palette: AppThemePalette) {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(palette.background)

        let itemAppearance = UITabBarItemAppearance()
        itemAppearance.normal.iconColor = UIColor(palette.tabInactive)
        itemAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(palette.tabInactive)]
        itemAppearance.selected.iconColor = UIColor(palette.tabActive)
        itemAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(palette.tabActive)]

        appearance.stackedLayoutAppearance = itemAppearance
        appearance.inlineLayoutAppearance = itemAppearance
        appearance.compactInlineLayoutAppearance = itemAppearance

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}
