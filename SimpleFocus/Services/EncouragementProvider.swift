//
//  EncouragementProvider.swift
//  SimpleFocus
//
//  Created by Codex on 2025-10-17.
//

import Foundation

struct EncouragementMessage: Equatable {
    let message: String
    let encouragement: String
}

protocol EncouragementProviding {
    func nextMessage() -> EncouragementMessage
}

struct EncouragementProvider: EncouragementProviding {
    private let messages: [EncouragementMessage] = [
        EncouragementMessage(message: "今日三件大事已妥善安排。",
                             encouragement: "给自己一点掌声，明天继续保持节奏。"),
        EncouragementMessage(message: "今天的焦点任务已经排满。",
                             encouragement: "好好充电，明天从容再战。"),
        EncouragementMessage(message: "任务额度已满，保持专注！",
                             encouragement: "留些精力给明天，你正走在正确的路上。")
    ]

    func nextMessage() -> EncouragementMessage {
        messages.randomElement() ?? messages[0]
    }
}
