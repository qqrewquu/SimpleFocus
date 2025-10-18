import SwiftUI
import WidgetKit

struct SimpleFocusWidget: Widget {
    let kind = "SimpleFocusWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            SimpleFocusWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("SimpleFocus")
        .description("快速查看今日最重要的任务。")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    }
}

@MainActor
struct Provider: TimelineProvider {
    private let builder = TaskWidgetTimelineBuilder()
    private let fetcher = WidgetTaskFetcher()

    func placeholder(in context: Context) -> SimpleFocusWidgetEntry {
        SimpleFocusWidgetEntry(date: Date(),
                               state: .tasks([
                                   SimpleFocusWidgetTask(id: UUID(), content: "样例任务 A"),
                                   SimpleFocusWidgetTask(id: UUID(), content: "样例任务 B")
                               ]))
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleFocusWidgetEntry) -> Void) {
        Task {
            let entry = await makeEntry(for: Date())
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleFocusWidgetEntry>) -> Void) {
        Task {
            let date = Date()
            let entry = await makeEntry(for: date)
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: date) ?? date.addingTimeInterval(1800)
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }

    private func makeEntry(for date: Date) async -> SimpleFocusWidgetEntry {
        let tasks = await fetcher.fetchTasks(for: date)
        return builder.buildEntry(for: date, tasks: tasks)
    }
}
