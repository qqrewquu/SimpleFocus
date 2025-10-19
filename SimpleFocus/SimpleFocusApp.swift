import SwiftData
import SwiftUI

@main
struct SimpleFocusApp: App {
    private let container: ModelContainer
    private let store: TaskStore

    init() {
        do {
            guard let sharedURL = AppGroup.containerURL()?.appending(path: "SimpleFocus.store") else {
                fatalError("Unable to locate shared App Group container.")
            }
            let configuration = ModelConfiguration(url: sharedURL)
            container = try ModelContainer(for: TaskItem.self, configurations: configuration)
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
