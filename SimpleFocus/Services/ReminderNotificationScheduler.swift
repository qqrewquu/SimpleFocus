//
//  ReminderNotificationScheduler.swift
//  SimpleFocus
//
//  Created by Codex on 2025-10-29.
//

import Foundation
import UserNotifications

enum ReminderAuthorizationResult {
    case authorized
    case denied
}

protocol ReminderNotificationScheduling {
    func ensureAuthorization() async -> ReminderAuthorizationResult
    func scheduleDailyReminder(at time: Date) async
    func cancelDailyReminder() async
}

struct ReminderNotificationScheduler: ReminderNotificationScheduling {
    private let notificationCenter: UNUserNotificationCenter
    private let calendar: Calendar
    private let identifier = "simplefocus.daily.reminder"

    init(notificationCenter: UNUserNotificationCenter = .current(),
         calendar: Calendar = .current) {
        self.notificationCenter = notificationCenter
        self.calendar = calendar
    }

    func ensureAuthorization() async -> ReminderAuthorizationResult {
        let settings = await notificationCenter.notificationSettings()

        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return .authorized
        case .denied:
            return .denied
        case .notDetermined:
            do {
                let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound])
                if granted {
                    return .authorized
                }
                let refreshed = await notificationCenter.notificationSettings()
                switch refreshed.authorizationStatus {
                case .authorized, .provisional, .ephemeral:
                    return .authorized
                default:
                    return .denied
                }
            } catch {
                return .denied
            }
        @unknown default:
            return .denied
        }
    }

    func scheduleDailyReminder(at time: Date) async {
        await cancelDailyReminder()

        let components = calendar.dateComponents([.hour, .minute], from: time)

        let content = UNMutableNotificationContent()
        content.title = LocalizationHelper.text("SimpleFocus 提醒")
        content.body = LocalizationHelper.text("写下今天最重要的三件事，保持专注。")
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        do {
            try await notificationCenter.add(request)
        } catch {
            // Silently fail; the view model will handle retry strategies if needed.
            print("[SimpleFocus] Failed to schedule reminder: \\(error)")
        }
    }

    func cancelDailyReminder() async {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}

private enum LocalizationHelper {
    static func text(_ key: String) -> String {
        bundle.localizedString(forKey: key, value: nil, table: nil)
    }

    private static var bundle: Bundle {
        let defaults = UserDefaults.standard
        guard let selection = defaults.string(forKey: languageSelectionKey) else {
            return .main
        }
        let resource: String?
        switch selection {
        case "english":
            resource = "en"
        case "simplifiedChinese":
            resource = "zh-Hans"
        default:
            resource = nil
        }
        if let resource,
           let path = Bundle.main.path(forResource: resource, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle
        }
        return .main
    }

    private static let languageSelectionKey = "settings.language.selection"
}
