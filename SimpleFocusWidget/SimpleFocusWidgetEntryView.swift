import SwiftUI
import WidgetKit

struct SimpleFocusWidgetEntryView: View {
    var entry: SimpleFocusWidgetEntry

    var body: some View {
        switch entry.state {
        case .tasks(let tasks):
            TaskListView(tasks: tasks)
        case .empty(let message):
            EmptyView(message: message)
        }
    }
}

private struct TaskListView: View {
    let tasks: [SimpleFocusWidgetTask]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("今日专注")
                .font(.headline)
                .foregroundColor(.white.opacity(0.9))

            ForEach(tasks.prefix(3)) { task in
                HStack(spacing: 6) {
                    Image(systemName: "circle")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    Text(task.content)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(white: 0.12))
    }
}

private struct EmptyView: View {
    let message: EncouragementMessage

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(message.message)
                .font(.headline)
                .foregroundColor(.white)
                .lineLimit(2)

            Text(message.encouragement)
                .font(.footnote)
                .foregroundColor(.white.opacity(0.7))
                .lineLimit(3)

            Spacer(minLength: 0)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(white: 0.12))
    }
}

#Preview(as: .systemSmall) {
    SimpleFocusWidget()
} timeline: {
    SimpleFocusWidgetEntry(date: Date(),
                           state: .tasks([
                               SimpleFocusWidgetTask(id: UUID(), content: "准备设计评审"),
                               SimpleFocusWidgetTask(id: UUID(), content: "写周报"),
                               SimpleFocusWidgetTask(id: UUID(), content: "预约牙医")
                           ]))

    SimpleFocusWidgetEntry(date: Date(),
                           state: .empty(EncouragementMessage(message: "今日三项大事已安排。",
                                                               encouragement: "享受片刻放松，明天继续前进。")))
}
