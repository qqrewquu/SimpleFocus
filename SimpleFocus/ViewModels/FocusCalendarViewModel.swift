//
//  FocusCalendarViewModel.swift
//  SimpleFocus
//
//  Created by Codex on 2025-10-29.
//

import Combine
import Foundation

struct FocusCalendarDay: Identifiable, Hashable {
    enum Identifier: Hashable {
        case placeholder(UUID)
        case date(Date)
    }

    let identifier: Identifier
    let tasks: [TaskItem]

    var id: Identifier { identifier }

    var date: Date? {
        if case let .date(value) = identifier {
            return value
        }
        return nil
    }

    static func placeholder() -> FocusCalendarDay {
        FocusCalendarDay(identifier: .placeholder(UUID()), tasks: [])
    }

    static func day(date: Date, tasks: [TaskItem]) -> FocusCalendarDay {
        FocusCalendarDay(identifier: .date(date), tasks: tasks)
    }
}

@MainActor
final class FocusCalendarViewModel: ObservableObject {
    @Published private(set) var currentMonth: Date
    @Published private(set) var tasksByDay: [Date: [TaskItem]] = [:]

    private let store: TaskStore
    private var calendar: Calendar

    private lazy var monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate("yyyy MMMM")
        return formatter
    }()
    private lazy var detailFormatter: DateFormatter = FocusCalendarViewModel.makeDetailFormatter(calendar: calendar)

    init(store: TaskStore, calendar: Calendar = FocusCalendarViewModel.makeCalendar()) {
        self.store = store
        self.calendar = calendar
        self.currentMonth = calendar.startOfMonth(for: Date())
    }

    func refresh() async {
        do {
            let tasks = try await store.fetchAllTasks()
            let grouped = Dictionary(grouping: tasks) { task in
                calendar.startOfDay(for: task.creationDate)
            }
            tasksByDay = grouped.mapValues { tasks in
                tasks.sorted { $0.creationDate < $1.creationDate }
            }
        } catch {
            print("[SimpleFocus] Failed to load tasks for calendar: \(error)")
            tasksByDay = [:]
        }
    }

    func goToPreviousMonth() {
        guard let newDate = calendar.date(byAdding: DateComponents(month: -1), to: currentMonth) else { return }
        currentMonth = calendar.startOfMonth(for: newDate)
    }

    func goToNextMonth() {
        guard let newDate = calendar.date(byAdding: DateComponents(month: 1), to: currentMonth) else { return }
        currentMonth = calendar.startOfMonth(for: newDate)
    }

    func monthTitle() -> String {
        let text = monthFormatter.string(from: currentMonth)
        return text.uppercased()
    }

    func daysForCurrentMonth() -> [FocusCalendarDay] {
        guard let range = calendar.range(of: .day, in: .month, for: currentMonth) else {
            return []
        }

        let firstWeekday = calendar.component(.weekday, from: currentMonth)
        let leadingEmpty = (firstWeekday - calendar.firstWeekday + 7) % 7

        var days: [FocusCalendarDay] = []
        days.reserveCapacity(range.count + leadingEmpty + 7)

        for _ in 0..<leadingEmpty {
            days.append(.placeholder())
        }

        for day in range {
            if let date = calendar.date(byAdding: DateComponents(day: day - 1), to: currentMonth) {
                let normalized = calendar.startOfDay(for: date)
                let tasks = tasksByDay[normalized] ?? []
                days.append(.day(date: normalized, tasks: tasks))
            }
        }

        while days.count % 7 != 0 {
            days.append(.placeholder())
        }

        return days
    }

    func tasks(on date: Date) -> [TaskItem] {
        let normalized = calendar.startOfDay(for: date)
        return tasksByDay[normalized] ?? []
    }

    func displayString(for date: Date) -> String {
        detailFormatter.string(from: date).uppercased()
    }
}

private extension FocusCalendarViewModel {
    nonisolated static func makeDetailFormatter(calendar: Calendar) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate("yyyy MMMM d")
        return formatter
    }

    nonisolated static func makeCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale.current
        calendar.firstWeekday = 1 // Sunday
        return calendar
    }
}

private extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components) ?? date
    }
}
