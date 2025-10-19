import SwiftData
import SwiftUI
import WidgetKit

struct ContentView: View {
    @StateObject private var viewModel: TaskListViewModel
    @StateObject private var addTaskViewModel: AddTaskViewModel
    @State private var isPresentingAddTask = false
#if DEBUG
    @State private var isShowingResetAlert = false
#endif

    init(store: TaskStore) {
        _viewModel = StateObject(wrappedValue: TaskListViewModel(store: store))
        _addTaskViewModel = StateObject(wrappedValue: AddTaskViewModel(store: store))
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 16) {
                header
                content
            }
            .padding(.horizontal, 24)
            .padding(.top, 48)
            .padding(.bottom, 32)

            if viewModel.canAddTask {
                addTaskButton
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.background.ignoresSafeArea())
        .task {
            try? await viewModel.refresh()
        }
#if DEBUG
        .alert("清空今天的任务？", isPresented: $isShowingResetAlert) {
            Button("取消", role: .cancel) {}
            Button("清空", role: .destructive) {
                resetTodayTasksForDebug()
            }
        } message: {
            Text("该操作仅用于调试，将删除今天的所有任务。")
        }
#endif
        .sheet(isPresented: $isPresentingAddTask) {
            AddTaskSheet(viewModel: addTaskViewModel,
                         limitState: viewModel.limitState) { newTask in
                isPresentingAddTask = false
                awaitRefreshAfterAdding(task: newTask)
            }
            .presentationDetents([.fraction(0.38), .medium])
            .presentationDragIndicator(.visible)
            .presentationBackground(AppTheme.background)
        }
        .sheet(item: Binding(
            get: { viewModel.celebration },
            set: { value in
                if value == nil {
                    viewModel.dismissCelebration()
                }
            }
        )) { celebration in
            CompletionCelebrationView(celebration: celebration) {
                viewModel.dismissCelebration()
            }
            .presentationDetents([.fraction(0.38)])
            .presentationDragIndicator(.visible)
            .presentationBackground(AppTheme.background)
        }
    }

    private var header: some View {
        ZStack {
            Text("SimpleFocus")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(AppTheme.textPrimary)

#if DEBUG
            HStack {
                Spacer()
                debugMenu
            }
            .padding(.trailing, 4)
#endif
        }
        .frame(maxWidth: .infinity)
    }

#if DEBUG
    private var debugMenu: some View {
        Menu {
            Button(role: .destructive) {
                isShowingResetAlert = true
            } label: {
                Label("清空今天的任务", systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(AppTheme.textSecondary)
                .padding(8)
        }
        .contentShape(Rectangle())
    }
#endif

    @ViewBuilder
    private var content: some View {
        if viewModel.hasTasks {
            List {
                ForEach(viewModel.tasks) { task in
                    TaskRow(task: task,
                            isCompleting: viewModel.recentlyCompletedTaskIDs.contains(task.id)) {
                        completeTask(task)
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.clear)
        } else if let limitState = viewModel.limitState {
            Spacer()
            LimitReachedView(limitState: limitState)
            Spacer()
        } else {
            Spacer()
            Text("请添加你的第一个专注任务")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(AppTheme.textSecondary)
            Spacer()
        }
    }

    private var addTaskButton: some View {
        Button {
            isPresentingAddTask = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 28, weight: .bold))
                .frame(width: 64, height: 64)
                .foregroundColor(AppTheme.textPrimary)
                .background(AppTheme.primary)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.4), radius: 16, x: 0, y: 8)
        }
        .padding(.trailing, 24)
        .padding(.bottom, 32)
    }
}

#Preview {
    PreviewContainerView()
}

private struct PreviewContainerView: View {
    @State private var container: ModelContainer = {
        let schema = Schema([TaskItem.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: configuration)
    }()

    var body: some View {
        let store = TaskStore(modelContext: container.mainContext)
        return ContentView(store: store)
            .modelContainer(container)
    }
}

private struct TaskRow: View {
    let task: TaskItem
    let isCompleting: Bool
    let onComplete: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Button(action: onComplete) {
                ZStack {
                    Circle()
                        .stroke(AppTheme.textPrimary.opacity(0.9), lineWidth: 2)
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(isCompleting ? AppTheme.primary : .clear)
                        )
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppTheme.textPrimary)
                        .opacity(isCompleting ? 1 : 0)
                }
            }
            .buttonStyle(.plain)

            Text(task.content)
                .font(.system(size: 18))
                .foregroundColor(AppTheme.textPrimary)

            Spacer()
        }
        .padding(.vertical, 12)
        .opacity(isCompleting ? 0.2 : 1)
        .animation(.easeInOut(duration: 0.25), value: isCompleting)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
}

private struct LimitReachedView: View {
    let limitState: EncouragementMessage

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(AppTheme.surfaceElevated)
                    .frame(width: 96, height: 96)
                Image(systemName: "sparkles")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(AppTheme.accentGradient)
            }
            .padding(.bottom, 4)

            Text(limitState.message)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(AppTheme.accentGradient)
                .multilineTextAlignment(.center)

            Text(limitState.encouragement)
                .font(.system(size: 17))
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .padding(.horizontal, 40)
    }
}

private extension ContentView {
    func awaitRefreshAfterAdding(task: TaskItem) {
        Task {
            do {
                try await viewModel.refresh()
                WidgetCenter.shared.reloadAllTimelines()
            } catch {
                assertionFailure("Failed to refresh after adding task: \(error)")
            }
        }
    }

    func completeTask(_ task: TaskItem) {
        Task {
            do {
                try await viewModel.complete(task: task)
                try await viewModel.refresh(animate: true)
                viewModel.clearCompletionAnimation(for: task.id)
                WidgetCenter.shared.reloadAllTimelines()
            } catch {
                assertionFailure("Failed to complete task: \(error)")
            }
        }
    }

#if DEBUG
    func resetTodayTasksForDebug() {
        Task {
            do {
                try await viewModel.resetTodayTasks()
                addTaskViewModel.content = ""
            } catch {
                assertionFailure("Failed to clear today's tasks: \(error)")
            }
        }
    }
#endif
}
