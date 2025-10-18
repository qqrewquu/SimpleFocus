import SwiftData
import SwiftUI

@main
struct SimpleFocusApp: App {
    private let container: ModelContainer
    private let store: TaskStore

    init() {
        do {
            if AppGroup.containerURL() != nil {
                container = try ModelContainer(for: TaskItem.self,
                                               configurations: ModelConfiguration(groupContainerIdentifier: AppGroup.identifier))
            } else {
                container = try ModelContainer(for: TaskItem.self)
            }
        } catch {
            fatalError("Failed to create model container: \(error)")
        }
        store = TaskStore(modelContext: container.mainContext)
    }

    var body: some Scene {
        WindowGroup {
            ContentView(store: store)
                .modelContainer(container)
        }
    }
}
