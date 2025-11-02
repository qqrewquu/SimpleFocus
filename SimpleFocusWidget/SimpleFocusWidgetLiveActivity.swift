//
//  SimpleFocusWidgetLiveActivity.swift
//  SimpleFocusWidget
//
//  Created by Codex on 2025-10-22.
//

import ActivityKit
import os
import SwiftUI
import WidgetKit

struct SimpleFocusWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SimpleFocusActivityAttributes.self) { context in
            widgetLogger.debug("Rendering lock screen with \(context.state.tasks.count) tasks")
            return LiveActivityLockScreenView(state: context.state)
                .activityBackgroundTint(Color.black.opacity(0.6))
                .activitySystemActionForegroundColor(Color.white)

        } dynamicIsland: { context in
            widgetLogger.debug("Rendering dynamic island with \(context.state.tasks.count) tasks")
            return DynamicIsland(
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

private let widgetLogger = Logger(subsystem: "com.zifengguo.SimpleFocus", category: "LiveActivityWidget")

#if DEBUG
private struct DebugLogView: View {
    init(_ message: @autoclosure () -> String) {
        print(message())
    }

    var body: some View {
        EmptyView()
    }
}
#endif
