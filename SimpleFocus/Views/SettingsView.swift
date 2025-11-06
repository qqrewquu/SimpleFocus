//
//  SettingsView.swift
//  SimpleFocus
//
//  Created by Codex on 2025-10-29.
//

import SwiftUI
import UIKit

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    private let appStoreURL = URL(string: "https://apps.apple.com/app/id0000000000?action=write-review")
    private let feedbackMailURL = URL(string: "mailto:support@simplefocus.app?subject=SimpleFocus%20反馈")

    var body: some View {
        NavigationStack {
            Form {
                notificationSection
                aboutSection
                versionSection
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.primary)
                }
            }
        }
        .preferredColorScheme(.dark)
        .alert(item: $viewModel.alertContext) { context in
            Alert(
                title: Text(context.title),
                message: Text(context.message),
                primaryButton: .default(Text("前往设置")) {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        openURL(url)
                    }
                },
                secondaryButton: .cancel(Text("取消"))
            )
        }
    }

    private var notificationSection: some View {
        Section(header: Text("通知").font(.subheadline)) {
            Toggle(isOn: Binding(
                get: { viewModel.isReminderEnabled },
                set: { viewModel.setReminderEnabled($0) }
            )) {
                Text("每日提醒")
            }
            .toggleStyle(.switch)

            if viewModel.isReminderEnabled {
                DatePicker(
                    "提醒时间",
                    selection: Binding(
                        get: { viewModel.reminderTime },
                        set: { viewModel.updateReminderTime($0) }
                    ),
                    displayedComponents: .hourAndMinute
                )

                Text(viewModel.reminderSummaryText)
                    .font(.footnote)
                    .foregroundColor(AppTheme.textSecondary)
            } else {
                Text("提醒未开启")
                    .font(.footnote)
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
        .listRowBackground(AppTheme.surfaceElevated)
        .tint(AppTheme.primary)
    }

    private var aboutSection: some View {
        Section(header: Text("关于").font(.subheadline)) {
            Button {
                if let appStoreURL {
                    openURL(appStoreURL)
                }
            } label: {
                Label("在 App Store 上评价", systemImage: "star.fill")
            }

            Button {
                if let feedbackMailURL {
                    openURL(feedbackMailURL)
                }
            } label: {
                Label("反馈与建议", systemImage: "envelope.fill")
            }
        }
        .listRowBackground(AppTheme.surfaceElevated)
    }

    private var versionSection: some View {
        Section {
            HStack {
                Spacer()
                Text(viewModel.versionDisplayText)
                    .font(.caption2)
                    .foregroundColor(AppTheme.textSecondary)
                Spacer()
            }
            .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
        }
        .listRowBackground(AppTheme.surfaceElevated)
    }
}
