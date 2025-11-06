//
//  SettingsViewModel.swift
//  SimpleFocus
//
//  Created by Codex on 2025-10-29.
//

import Combine
import Foundation

@MainActor
final class SettingsViewModel: ObservableObject {
    enum AlertContext: Identifiable {
        case notificationsDenied

        var id: String {
            switch self {
            case .notificationsDenied:
                return "notificationsDenied"
            }
        }

        var title: String {
            switch self {
            case .notificationsDenied:
                return "通知权限未开启"
            }
        }

        var message: String {
            switch self {
            case .notificationsDenied:
                return "要启用每日提醒，请在系统设置中允许 SimpleFocus 发送通知。"
            }
        }
    }

    private enum StorageKeys {
        static let reminderEnabled = "settings.reminder.enabled"
        static let reminderTime = "settings.reminder.time"
    }

    @Published var isReminderEnabled: Bool
    @Published var reminderTime: Date
    @Published var alertContext: AlertContext?

    private let scheduler: ReminderNotificationScheduling
    private let defaults: UserDefaults
    private let calendar: Calendar

    init(scheduler: ReminderNotificationScheduling,
         defaults: UserDefaults = .standard,
         calendar: Calendar = .current) {
        self.scheduler = scheduler
        self.defaults = defaults
        self.calendar = calendar

        let storedEnabled = defaults.bool(forKey: StorageKeys.reminderEnabled)
        let storedDate = defaults.object(forKey: StorageKeys.reminderTime) as? Date
        let normalizedDefault = SettingsViewModel.defaultReminderTime(using: calendar)

        self.isReminderEnabled = storedEnabled
        self.reminderTime = SettingsViewModel.normalize(storedDate ?? normalizedDefault, calendar: calendar)

        if storedDate == nil {
            defaults.set(self.reminderTime, forKey: StorageKeys.reminderTime)
        }
    }

    func setReminderEnabled(_ isOn: Bool) {
        guard isReminderEnabled != isOn else { return }
        isReminderEnabled = isOn

        Task {
            if isOn {
                await handleEnableReminder()
            } else {
                defaults.set(false, forKey: StorageKeys.reminderEnabled)
                await scheduler.cancelDailyReminder()
            }
        }
    }

    func updateReminderTime(_ date: Date) {
        let normalized = SettingsViewModel.normalize(date, calendar: calendar)
        guard reminderTime != normalized else { return }

        reminderTime = normalized
        defaults.set(normalized, forKey: StorageKeys.reminderTime)

        guard isReminderEnabled else { return }

        Task {
            await scheduler.scheduleDailyReminder(at: normalized)
        }
    }

    var reminderSummaryText: String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale.current
        formatter.timeStyle = .short
        return "将在每日 \(formatter.string(from: reminderTime)) 提醒你添加任务。"
    }

    var versionDisplayText: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "–"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "–"
        return "版本号 \(version) (Build \(build))"
    }

    private func handleEnableReminder() async {
        let authorization = await scheduler.ensureAuthorization()

        switch authorization {
        case .authorized:
            defaults.set(true, forKey: StorageKeys.reminderEnabled)
            await scheduler.scheduleDailyReminder(at: reminderTime)
        case .denied:
            defaults.set(false, forKey: StorageKeys.reminderEnabled)
            await MainActor.run {
                isReminderEnabled = false
                alertContext = .notificationsDenied
            }
        }
    }

    private static func normalize(_ date: Date, calendar: Calendar) -> Date {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        return calendar.date(from: components) ?? date
    }

    private static func defaultReminderTime(using calendar: Calendar) -> Date {
        var components = DateComponents()
        components.hour = 9
        components.minute = 0
        return calendar.date(from: components) ?? Date()
    }
}
