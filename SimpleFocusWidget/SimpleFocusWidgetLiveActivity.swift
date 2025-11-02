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

private let liveActivityAccent = Color(red: 0.38, green: 0.72, blue: 1.0)

private struct LiveActivityLockScreenView: View {
    let state: SimpleFocusActivityAttributes.ContentState

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.black.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 14) {
                Text("SimpleFocus")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .center)

                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(state.tasks.enumerated()), id: \.element.id) { index, task in
                        HStack(spacing: 10) {
                            TaskStatusIndicator(isCompleted: task.isCompleted,
                                                accent: liveActivityAccent,
                                                size: 18,
                                                lineWidth: 1.5,
                                                checkmarkSize: 10)
                            Text(task.content)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(task.isCompleted ? Color.white.opacity(0.55) : Color.white)
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .allowsTightening(true)
                            Spacer()
                        }
                        if index < state.tasks.count - 1 {
                            Divider()
                                .overlay(Color.white.opacity(0.12))
                                .padding(.leading, 28)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    ProgressView(value: state.progress)
                        .progressViewStyle(.linear)
                        .tint(liveActivityAccent)

                    HStack(spacing: 6) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(liveActivityAccent)
                        Text(state.statusMessage)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.75))
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                }
            }
            .padding(.vertical, 18)
            .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

private struct CompactTaskListView: View {
    let tasks: [LiveActivityDisplayTask]

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(tasks) { task in
                HStack(spacing: 3) {
                    TaskStatusIndicator(isCompleted: task.isCompleted,
                                        accent: liveActivityAccent,
                                        size: 9,
                                        lineWidth: 1,
                                        checkmarkSize: 5)
                    Text(task.content)
                        .font(.caption2)
                        .foregroundColor(task.isCompleted ? Color.white.opacity(0.6) : Color.white)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
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
                LiveActivityDisplayTask(id: UUID(), content: "Finish Q3 Report", isCompleted: true),
                LiveActivityDisplayTask(id: UUID(), content: "Learn SwiftUI Basics", isCompleted: true),
                LiveActivityDisplayTask(id: UUID(), content: "Develop App UI With Widgets", isCompleted: false),
            ],
            totalTasks: 3,
            completedTasks: 2,
            remainingTasks: 1,
            progress: 2.0 / 3.0,
            statusMessage: "Daily Focus: 2/3 Tasks Completed"
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

private struct TaskStatusIndicator: View {
    let isCompleted: Bool
    let accent: Color
    let size: CGFloat
    let lineWidth: CGFloat
    let checkmarkSize: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(accent.opacity(0.85), lineWidth: lineWidth)
                .background(
                    Circle()
                        .fill(isCompleted ? accent.opacity(0.9) : Color.clear)
                )
                .frame(width: size, height: size)

            if isCompleted {
                Image(systemName: "checkmark")
                    .font(.system(size: checkmarkSize, weight: .bold))
                    .foregroundColor(.white)
            }
        }
    }
}

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
