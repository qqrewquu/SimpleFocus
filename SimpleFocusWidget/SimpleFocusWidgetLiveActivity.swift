//
//  SimpleFocusWidgetLiveActivity.swift
//  SimpleFocusWidget
//
//  Created by Codex on 2025-10-22.
//

import ActivityKit
import SwiftUI
import WidgetKit

struct LiveActivityDisplayTask: Codable, Hashable, Identifiable {
    let id: UUID
    let content: String
    let isCompleted: Bool
}

struct LiveActivityContentState: Codable, Hashable {
    let displayedTasks: [LiveActivityDisplayTask]
    let totalTasks: Int
    let completedTasks: Int
    let remainingTasks: Int
    let progress: Double
    let statusMessage: String
}

@available(iOS 17.0, *)
struct SimpleFocusActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public let tasks: [LiveActivityDisplayTask]
        public let totalTasks: Int
        public let completedTasks: Int
        public let remainingTasks: Int
        public let progress: Double
        public let statusMessage: String

        init(from state: LiveActivityContentState) {
            tasks = state.displayedTasks
            totalTasks = state.totalTasks
            completedTasks = state.completedTasks
            remainingTasks = state.remainingTasks
            progress = state.progress
            statusMessage = state.statusMessage
        }
    }

    var title: String = "SimpleFocus"
}

struct SimpleFocusWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SimpleFocusActivityAttributes.self) { context in
            LiveActivityLockScreenView(state: context.state)
                .activityBackgroundTint(Color.black.opacity(0.6))
                .activitySystemActionForegroundColor(Color.white)

        } dynamicIsland: { context in
            DynamicIsland(
                expanded: {
                    DynamicIslandExpandedRegion(.leading) {
                        CompactTaskListView(tasks: Array(context.state.tasks.prefix(1)))
                    }
                    DynamicIslandExpandedRegion(.trailing) {
                        CompactTaskListView(tasks: Array(context.state.tasks.dropFirst().prefix(1)))
                            .multilineTextAlignment(.trailing)
                    }
                    DynamicIslandExpandedRegion(.bottom) {
                        Text(context.state.statusMessage)
                            .font(.footnote)
                            .foregroundColor(Color.white.opacity(0.9))
                    }
                },
                compactLeading: {
                    CountBadgeView(count: context.state.remainingTasks,
                                    systemImage: "list.bullet")
                },
                compactTrailing: {
                    Text("\(Int((context.state.progress * 100).rounded()))%")
                        .font(.caption)
                        .bold()
                        .foregroundColor(Color.white)
                },
                minimal: {
                    CountBadgeView(count: context.state.remainingTasks,
                                    systemImage: "circlebadge")
                }
            )
            .keylineTint(Color(red: 0.38, green: 0.72, blue: 1.0))
        }
    }
}

private struct LiveActivityLockScreenView: View {
    let state: SimpleFocusActivityAttributes.ContentState

    private let accent = Color(red: 0.38, green: 0.72, blue: 1.0)

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("SimpleFocus")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)

            VStack(alignment: .leading, spacing: 12) {
                ForEach(state.tasks) { task in
                    HStack(spacing: 12) {
                        Circle()
                            .strokeBorder(accent.opacity(0.8), lineWidth: 2)
                            .frame(width: 22, height: 22)
                        Text(task.content)
                            .font(.headline)
                            .foregroundColor(.white)
                            .lineLimit(1)
                        Spacer()
                    }
                }
            }

            ProgressView(value: state.progress)
                .progressViewStyle(.linear)
                .tint(accent)

            Text(state.statusMessage)
                .font(.footnote)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct CompactTaskListView: View {
    let tasks: [LiveActivityDisplayTask]

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(tasks) { task in
                Text(task.content)
                    .font(.caption2)
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
        }
    }
}

private struct CountBadgeView: View {
    let count: Int
    let systemImage: String

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.15))
                .frame(width: 30, height: 30)
            VStack(spacing: 2) {
                Image(systemName: systemImage)
                    .font(.system(size: 10, weight: .semibold))
                Text("\(count)")
                    .font(.system(size: 11, weight: .bold))
            }
            .foregroundColor(.white)
        }
    }
}

#if DEBUG
extension LiveActivityContentState {
    static var previewState: LiveActivityContentState {
        LiveActivityContentState(
            displayedTasks: [
                LiveActivityDisplayTask(id: UUID(), content: "Finish Q3 Report", isCompleted: false),
                LiveActivityDisplayTask(id: UUID(), content: "Learn SwiftUI Basics", isCompleted: false),
                LiveActivityDisplayTask(id: UUID(), content: "Develop App UI", isCompleted: false),
            ],
            totalTasks: 3,
            completedTasks: 1,
            remainingTasks: 2,
            progress: 1.0 / 3.0,
            statusMessage: "Daily Focus: 2/3 Tasks Left"
        )
    }
}

#Preview("Live Activity", as: .content, using: SimpleFocusActivityAttributes()) {
    SimpleFocusWidgetLiveActivity()
} contentStates: {
    SimpleFocusActivityAttributes.ContentState(from: .previewState)
}
#endif
