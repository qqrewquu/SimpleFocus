import SwiftData
import SwiftUI
import WidgetKit

struct ContentView: View {
    @StateObject private var viewModel: TaskListViewModel
    @StateObject private var addTaskViewModel: AddTaskViewModel
    @StateObject private var historyViewModel: HistoryViewModel
    @StateObject private var historyNavigation = HistoryNavigationState()

    @State private var isPresentingAddTask = false

    @State private var editingTask: TaskItem?
    @State private var editingText: String = ""
    @State private var editingOriginalText: String = ""
    @State private var editingErrorMessage: String?
    @FocusState private var focusedTaskID: UUID?

#if DEBUG
    @State private var isShowingResetAlert = false
#endif

    @MainActor
    init(store: TaskStore, liveActivityController: LiveActivityLifecycleController? = nil) {
        let taskListViewModel = TaskListViewModel(store: store)
        if let liveActivityController {
            taskListViewModel.setLiveActivityController(liveActivityController)
        }
        _viewModel = StateObject(wrappedValue: taskListViewModel)
        _addTaskViewModel = StateObject(wrappedValue: AddTaskViewModel(store: store))
        _historyViewModel = StateObject(wrappedValue: HistoryViewModel(store: store))
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
        .sheet(isPresented: historySheetBinding) {
            HistoryView(viewModel: historyViewModel)
                .presentationDetents([.large])
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

            HStack {
                historyButton
                Spacer()
                if editingTask != nil {
                    Button("完成") {
                        Task {
                            _ = await commitEditing()
                        }
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(AppTheme.primary)
                }
#if DEBUG
                debugMenu
#endif
            }
            .padding(.horizontal, 4)
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

    private var historyButton: some View {
        Button {
            if editingTask == nil {
                historyNavigation.showHistory()
            } else {
                Task {
                    let success = await commitEditing()
                    if success {
                        await MainActor.run {
                            historyNavigation.showHistory()
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 18, weight: .semibold))
                Text("历史")
                    .font(.system(size: 17, weight: .semibold))
            }
            .foregroundColor(AppTheme.textSecondary)
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(
                Capsule()
                    .fill(AppTheme.surfaceElevated)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("查看历史记录")
        .offset(x: -16)
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.hasTasks {
            List {
                ForEach(viewModel.tasks) { task in
                    if let editingTask, editingTask.id == task.id {
                        EditingTaskRow(task: task,
                                       isCompleting: viewModel.recentlyCompletedTaskIDs.contains(task.id),
                                       text: $editingText,
                                       errorMessage: editingErrorMessage,
                                       focusBinding: $focusedTaskID,
                                       onComplete: { completeTask(task) },
                                       onSubmit: {
                                           Task {
                                               _ = await commitEditing()
                                           }
                                       },
                                       onFocusLost: {
                                           if self.editingTask?.id == task.id {
                                               Task {
                                                   _ = await commitEditing()
                                               }
                                           }
                                       })
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    } else {
                        DisplayTaskRow(task: task,
                                        isCompleting: viewModel.recentlyCompletedTaskIDs.contains(task.id),
                                        onComplete: { completeTask(task) },
                                        onEdit: { beginEditing(task) })
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .onChange(of: editingText) { newValue in
                if editingTask != nil && !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    editingErrorMessage = nil
                }
            }
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
            if editingTask == nil {
                isPresentingAddTask = true
            } else {
                Task {
                    let success = await commitEditing()
                    if success {
                        await MainActor.run {
                            isPresentingAddTask = true
                        }
                    }
                }
            }
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

private struct DisplayTaskRow: View {
    let task: TaskItem
    let isCompleting: Bool
    let onComplete: () -> Void
    let onEdit: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            completeButton

            Text(task.content)
                .font(.system(size: 18))
                .foregroundColor(AppTheme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture(perform: onEdit)
                .accessibilityLabel("编辑任务：\(task.content)")
                .accessibilityHint("双击以修改内容")
        }
        .padding(.vertical, 12)
        .opacity(isCompleting ? 0.2 : 1)
        .animation(.easeInOut(duration: 0.25), value: isCompleting)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    private var completeButton: some View {
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
    }
}

private struct EditingTaskRow: View {
    let task: TaskItem
    let isCompleting: Bool
    @Binding var text: String
    let errorMessage: String?
    let focusBinding: FocusState<UUID?>.Binding
    let onComplete: () -> Void
    let onSubmit: () -> Void
    let onFocusLost: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 16) {
                completeButton

                TextField("编辑任务", text: $text)
                    .font(.system(size: 18))
                    .foregroundColor(AppTheme.textPrimary)
                    .submitLabel(.done)
                    .focused(focusBinding, equals: task.id)
                    .onSubmit(onSubmit)
                    .onChange(of: focusBinding.wrappedValue) { newValue in
                        if newValue != task.id {
                            onFocusLost()
                        }
                    }
                    .onChange(of: text) { newValue in
                        if newValue.count > TaskContentPolicy.maxLength {
                            text = String(newValue.prefix(TaskContentPolicy.maxLength))
                        }
                    }
                    .onAppear {
                        focusBinding.wrappedValue = task.id
                    }
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundColor(.red.opacity(0.85))
                    .padding(.leading, 44)
            }
        }
        .padding(.vertical, 12)
        .animation(.easeInOut(duration: 0.25), value: isCompleting)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    private var completeButton: some View {
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
    var historySheetBinding: Binding<Bool> {
        Binding(
            get: { historyNavigation.isShowingHistory },
            set: { newValue in
                if newValue {
                    historyNavigation.showHistory()
                } else {
                    historyNavigation.dismissHistory()
                }
            }
        )
    }

    func awaitRefreshAfterAdding(task: TaskItem) {
        Task {
            do {
                try await viewModel.refresh()
                WidgetCenter.shared.reloadAllTimelines()
                try await historyViewModel.loadHistory()
            } catch {
                assertionFailure("Failed to refresh after adding task: \(error)")
            }
        }
    }

    func completeTask(_ task: TaskItem) {
        Task {
            if let editingTask, editingTask.id == task.id {
                let success = await commitEditing()
                guard success else { return }
            }
            do {
                try await viewModel.complete(task: task)
                try await viewModel.refresh(animate: true)
                viewModel.clearCompletionAnimation(for: task.id)
                WidgetCenter.shared.reloadAllTimelines()
                try await historyViewModel.loadHistory()
            } catch {
                assertionFailure("Failed to complete task: \(error)")
            }
        }
    }

    func beginEditing(_ task: TaskItem) {
        if editingTask?.id == task.id {
            return
        }

        Task {
            if let current = editingTask, current.id != task.id {
                let success = await commitEditing()
                guard success else { return }
            }

            await MainActor.run {
                editingTask = task
                editingText = task.content
                editingOriginalText = task.content
                editingErrorMessage = nil
                focusedTaskID = task.id
            }
        }
    }

    @discardableResult
    func commitEditing() async -> Bool {
        guard let task = editingTask else {
            return true
        }

        let trimmed = editingText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            await MainActor.run {
                editingErrorMessage = "请输入任务内容"
                focusedTaskID = task.id
            }
            return false
        }

        let normalized = String(trimmed.prefix(TaskContentPolicy.maxLength))
        if normalized == editingOriginalText {
            await MainActor.run {
                endEditing()
            }
            return true
        }

        do {
            try await viewModel.edit(task: task, newContent: normalized)
            await MainActor.run {
                WidgetCenter.shared.reloadAllTimelines()
            }
            try await historyViewModel.loadHistory()
            await MainActor.run {
                endEditing()
            }
            return true
        } catch TaskInputError.emptyContent {
            await MainActor.run {
                editingErrorMessage = "请输入任务内容"
                focusedTaskID = task.id
            }
            return false
        } catch TaskUpdateError.completedTask {
            await MainActor.run {
                editingErrorMessage = "已完成的任务无法编辑"
                focusedTaskID = task.id
            }
            return false
        } catch {
            await MainActor.run {
                editingErrorMessage = "保存失败，请重试"
                focusedTaskID = task.id
            }
            return false
        }
    }

    @MainActor
    func endEditing() {
        editingTask = nil
        editingText = ""
        editingOriginalText = ""
        editingErrorMessage = nil
        focusedTaskID = nil
    }

#if DEBUG
    func resetTodayTasksForDebug() {
        Task {
            do {
                try await viewModel.resetTodayTasks()
                addTaskViewModel.content = ""
                try await historyViewModel.loadHistory()
            } catch {
                assertionFailure("Failed to clear today's tasks: \(error)")
            }
        }
    }
#endif
}
