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
        content.title = "SimpleFocus 提醒"
        content.body = "写下今天最重要的三件事，保持专注。"
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
