//
//  TaskItem.swift
//  SimpleFocus
//
//  Created by Codex on 2025-10-17.
//

import Foundation
import SwiftData

@Model
final class TaskItem: Identifiable {
    var id: UUID = UUID()
    var content: String = ""
    var creationDate: Date = Date()
    var isCompleted: Bool = false

    init(id: UUID = UUID(),
         content: String,
         creationDate: Date = Date(),
         isCompleted: Bool = false) {
        self.id = id
        self.content = content
        self.creationDate = creationDate
        self.isCompleted = isCompleted
    }
}
