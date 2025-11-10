//
//  SettingsView.swift
//  SimpleFocus
//
//  Created by Codex on 2025-10-29.
//

import MessageUI
import SwiftUI
import UIKit

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    var showsDoneButton: Bool = true

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.themePalette) private var theme
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var languageManager: LanguageManager
    @State private var mailAlert: MailAlert?
    @State private var showingMailComposer = false

    private let appStoreReviewURL = URL(string: "https://apps.apple.com/app/id0000000000?action=write-review")
    private let shareURL = URL(string: "https://apps.apple.com/app/id0000000000")
    private let feedbackEmailAddress = "zifeng.guo09@outlook.com"

    var body: some View {
        let strings = SettingsStrings(languageManager: languageManager)
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    generalSettingsCard
                    supportUsCard
                    versionFooter
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 40)
            }
            .background(theme.background.ignoresSafeArea())
            .navigationTitle(strings.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if showsDoneButton {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(strings.done) {
                            dismiss()
                        }
                        .foregroundColor(theme.primary)
                    }
                }
            }
            .tint(theme.primary)
        }
        .alert(item: $viewModel.alertContext) { context in
            let strings = SettingsStrings(languageManager: languageManager)
            return Alert(
                title: Text(context.title),
                message: Text(context.message),
                primaryButton: .default(Text(strings.openSystemSettings)) {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        openURL(url)
                    }
                },
                secondaryButton: .cancel(Text(strings.cancel))
            )
        }
        .alert(item: $mailAlert) { _ in
            let strings = SettingsStrings(languageManager: languageManager)
            return Alert(
                title: Text(strings.mailUnavailableTitle),
                message: Text(strings.mailUnavailableMessage),
                primaryButton: .default(Text(strings.copyEmail)) {
                    UIPasteboard.general.string = feedbackEmailAddress
                },
                secondaryButton: .cancel(Text(strings.okay))
            )
        }
        .sheet(isPresented: $showingMailComposer) {
            mailComposerSheet
        }
    }

    private var generalSettingsCard: some View {
        let strings = SettingsStrings(languageManager: languageManager)
        return settingsCard(title: strings.generalSection) {
            appearanceRow
            cardDivider
            NavigationLink {
                LanguageSelectionView()
            } label: {
                SettingsRow(title: strings.languageRowTitle,
                            value: languageManager.displayName(for: languageManager.selection))
            }
            .buttonStyle(.plain)
            cardDivider
            NavigationLink {
                NotificationSettingsView(viewModel: viewModel)
            } label: {
                SettingsRow(title: strings.notificationsRowTitle,
                            value: languageManager.localized(viewModel.isReminderEnabled ? "已开启" : "未开启"))
            }
            .buttonStyle(.plain)
            cardDivider
            liveActivityRow
        }
    }

    private var supportUsCard: some View {
        let strings = SettingsStrings(languageManager: languageManager)
        return settingsCard(title: strings.supportSection) {
            Button {
                if let appStoreReviewURL {
                    openURL(appStoreReviewURL)
                }
            } label: {
                SupportActionRow(icon: "🌟", title: strings.rateTitle)
            }
            .buttonStyle(.plain)
            cardDivider
            if let shareURL {
                let shareMessage = languageManager.localizedFormat("SimpleFocus 让你每天专注三件事。一起试试：%@", shareURL.absoluteString)
                ShareLink(item: shareURL,
                          subject: Text("SimpleFocus"),
                          message: Text(shareMessage)) {
                    SupportActionRow(icon: "👍", title: strings.shareTitle)
                }
                .buttonStyle(.plain)
            }
            cardDivider
            Button {
                handleFeedbackTap()
            } label: {
                SupportActionRow(icon: "✉️", title: strings.feedbackTitle)
            }
            .buttonStyle(.plain)
        }
    }

    private var versionFooter: some View {
        let strings = SettingsStrings(languageManager: languageManager)
        return Text(strings.versionDisplayText(version: viewModel.appVersion,
                                              build: viewModel.buildNumber))
            .font(.caption)
            .foregroundColor(theme.textSecondary)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(theme.surfaceElevated)
            .cornerRadius(16)
    }

    private var appearanceRow: some View {
        let strings = SettingsStrings(languageManager: languageManager)
        return HStack(spacing: 16) {
            Text(strings.appearanceTitle)
                .font(.body)
                .foregroundColor(theme.textPrimary)
            Spacer()
            Picker(strings.appearanceTitle, selection: Binding(get: { themeManager.mode },
                                              set: { themeManager.mode = $0 })) {
                ForEach(AppThemeMode.allCases) { mode in
                    Text(mode.localizedTitle(using: languageManager)).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(maxWidth: 180)
            .tint(theme.primary)
        }
    }

    private var liveActivityRow: some View {
        let strings = SettingsStrings(languageManager: languageManager)
        return HStack(spacing: 16) {
            Text(strings.liveActivityTitle)
                .font(.body)
                .foregroundColor(theme.textPrimary)
            Spacer()
            Toggle(isOn: Binding(get: { viewModel.isLiveActivityEnabled },
                                  set: { viewModel.setLiveActivityEnabled($0) })) {
                EmptyView()
            }
            .labelsHidden()
            .tint(theme.primary)
        }
    }

    @ViewBuilder
    private func settingsCard<Content: View>(title: String,
                                             @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)
                .foregroundColor(theme.textPrimary)
            content()
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.surfaceElevated)
        .cornerRadius(24)
    }

    private var cardDivider: some View {
        Rectangle()
            .fill(theme.surfaceMuted)
            .frame(height: 1)
    }

    private var feedbackURL: URL? {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = feedbackEmailAddress
        components.queryItems = [
            URLQueryItem(name: "subject", value: languageManager.localized("[SimpleFocus App] 用户反馈")),
            URLQueryItem(name: "body", value: languageManager.localized("你好 SimpleFocus 团队：\n\n"))
        ]
        return components.url
    }

    private func handleFeedbackTap() {
        if MFMailComposeViewController.canSendMail() {
            showingMailComposer = true
            return
        }

        if let url = feedbackURL {
            sendFeedbackFallback(url)
        } else {
            mailAlert = .mailUnavailable
        }
    }

    private func sendFeedbackFallback(_ url: URL) {
        openURL(url) { success in
            if success == false {
                mailAlert = .mailUnavailable
            }
        }
    }
}

private extension SettingsView {
    var mailComposerSheet: some View {
        MailComposeView(recipients: [feedbackEmailAddress],
                        subject: languageManager.localized("[SimpleFocus App] 用户反馈"),
                        body: languageManager.localized("你好 SimpleFocus 团队：\n\n")) { result in
            showingMailComposer = false
            if case .failure = result {
                mailAlert = .mailUnavailable
            }
        }
    }
}

private struct SettingsRow: View {
    let title: String
    var value: String?
    @Environment(\.themePalette) private var theme

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .foregroundColor(theme.textPrimary)
            Spacer()
            if let value {
                SettingsValueBadge(text: value)
            }
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundColor(theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct SettingsValueBadge: View {
    let text: String
    @Environment(\.themePalette) private var theme

    var body: some View {
        Text(text)
            .font(.subheadline)
            .foregroundColor(theme.textPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(theme.surfaceMuted)
            .clipShape(Capsule())
    }
}

private struct SupportActionRow: View {
    let icon: String
    let title: String
    @Environment(\.themePalette) private var theme

    var body: some View {
        HStack(spacing: 12) {
            Text(icon)
                .font(.title3)
            Text(title)
                .foregroundColor(theme.textPrimary)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundColor(theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

private enum MailAlert: Identifiable {
    case mailUnavailable

    var id: Int { 0 }
}

private struct SettingsStrings {
    let languageManager: LanguageManager

    var title: String { languageManager.localized("设置") }
    var done: String { languageManager.localized("完成") }
    var generalSection: String { languageManager.localized("通用设置") }
    var languageRowTitle: String { languageManager.localized("语言") }
    var notificationsRowTitle: String { languageManager.localized("通知") }
    var supportSection: String { languageManager.localized("支持我们") }
    var rateTitle: String { languageManager.localized("给个 5 星好评") }
    var shareTitle: String { languageManager.localized("把 SimpleFocus 推荐给好友") }
    var feedbackTitle: String { languageManager.localized("给我发送邮件提建议哦") }
    var appearanceTitle: String { languageManager.localized("外观") }
    var liveActivityTitle: String { languageManager.localized("实时活动") }
    var openSystemSettings: String { languageManager.localized("前往设置") }
    var cancel: String { languageManager.localized("取消") }
    var mailUnavailableTitle: String { languageManager.localized("无法打开邮箱") }
    var mailUnavailableMessage: String { languageManager.localized("请先在系统中配置邮件账号，或复制邮箱地址后使用其它应用发送。") }
    var copyEmail: String { languageManager.localized("复制邮箱") }
    var okay: String { languageManager.localized("好的") }

    func versionDisplayText(version: String, build: String) -> String {
        languageManager.localizedFormat("版本号 %@ (Build %@)", version, build)
    }
}
