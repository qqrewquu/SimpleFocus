import SwiftData
import WidgetKit

@MainActor
struct WidgetTaskFetcher {
    func fetchTasks(for date: Date) async -> [TaskItem] {
        do {
            let store = try TaskStore.makeSharedStore()
            let tasks = try await store.fetchIncompleteTasksForToday(referenceDate: date)
            print("[SimpleFocusWidget] Fetched \(tasks.count) task(s) for \(date.formatted())")
            return tasks
        } catch {
            print("[SimpleFocusWidget] Failed to fetch tasks: \(error)")
            return []
        }
    }
}
