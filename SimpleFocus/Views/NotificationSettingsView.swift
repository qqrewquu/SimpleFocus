//
//  NotificationSettingsView.swift
//  SimpleFocus
//
//  Created by Codex on 2025-11-08.
//

import SwiftUI
import UIKit

struct NotificationSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @Environment(\.themePalette) private var theme
    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var languageManager: LanguageManager

    var body: some View {
        Form {
            Section {
                reminderToggle
                if viewModel.isReminderEnabled {
                    reminderPicker
                    Text(reminderSummaryText)
                        .font(.footnote)
                        .foregroundColor(theme.textSecondary)
                        .padding(.top, 4)
                } else {
                    Text(languageManager.localized("提醒未开启"))
                        .font(.footnote)
                        .foregroundColor(theme.textSecondary)
                }
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .background(theme.background.ignoresSafeArea())
        .navigationTitle(languageManager.localized("通知"))
        .navigationBarTitleDisplayMode(.inline)
        .tint(theme.primary)
        .alert(item: $viewModel.alertContext) { context in
            Alert(
                title: Text(context.title),
                message: Text(context.message),
                primaryButton: .default(Text(languageManager.localized("前往设置"))) {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        openURL(url)
                    }
                },
                secondaryButton: .cancel(Text(languageManager.localized("取消")))
            )
        }
    }

    private var reminderToggle: some View {
        Toggle(isOn: Binding(
            get: { viewModel.isReminderEnabled },
            set: { viewModel.setReminderEnabled($0) }
        )) {
            Text(languageManager.localized("每日提醒"))
        }
    }

    private var reminderPicker: some View {
        DatePicker(
            languageManager.localized("提醒时间"),
            selection: Binding(
                get: { viewModel.reminderTime },
                set: { viewModel.updateReminderTime($0) }
            ),
            displayedComponents: .hourAndMinute
        )
    }

    private var reminderSummaryText: String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.locale = languageManager.locale
        formatter.timeStyle = .short
        let timeString = formatter.string(from: viewModel.reminderTime)
        return languageManager.localizedFormat("将在每日 %@ 提醒你添加任务。", timeString)
    }
}
