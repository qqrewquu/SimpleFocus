import SwiftData
import WidgetKit

@MainActor
struct WidgetTaskFetcher {
    func fetchTasks(for date: Date) async -> [TaskItem] {
        do {
            let store = try TaskStore.makeSharedStore()
            let tasks = try await store.fetchIncompleteTasksForToday(referenceDate: date)
            return tasks
        } catch {
            return []
        }
    }
}
