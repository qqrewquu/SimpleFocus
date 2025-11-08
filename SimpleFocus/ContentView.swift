import SwiftData
import SwiftUI
import WidgetKit

struct ContentView: View {
    @StateObject private var viewModel: TaskListViewModel
    @StateObject private var addTaskViewModel: AddTaskViewModel
    @ObservedObject private var focusCalendarViewModel: FocusCalendarViewModel
    @ObservedObject private var bonsaiController: BonsaiController
    private let store: TaskStore
    @Environment(\.themePalette) private var theme

    @State private var isPresentingAddTask = false
    @AppStorage("hasNewBonsaiGrowth") private var hasNewBonsaiGrowth: Bool = false
    @AppStorage("pendingOnboardingTask") private var pendingOnboardingTask: String = ""

    @State private var editingTask: TaskItem?
    @State private var editingText: String = ""
    @State private var editingOriginalText: String = ""
    @State private var editingErrorMessage: String?
    @State private var skipAutoCommitUntil: Date?
    @FocusState private var focusedTaskID: UUID?

#if DEBUG
    @State private var isShowingResetAlert = false
    @State private var isShowingOnboardingResetAlert = false
#endif

    @MainActor
    init(store: TaskStore,
         liveActivityController: LiveActivityLifecycleController? = nil,
         focusCalendarViewModel: FocusCalendarViewModel? = nil,
         bonsaiController: BonsaiController) {
        self.store = store
        let taskListViewModel = TaskListViewModel(store: store)
        if let liveActivityController {
            taskListViewModel.setLiveActivityController(liveActivityController)
        }
        let calendarViewModel = focusCalendarViewModel ?? FocusCalendarViewModel(store: store)
        _viewModel = StateObject(wrappedValue: taskListViewModel)
        _addTaskViewModel = StateObject(wrappedValue: AddTaskViewModel(store: store))
        _focusCalendarViewModel = ObservedObject(initialValue: calendarViewModel)
        _bonsaiController = ObservedObject(initialValue: bonsaiController)
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
        .background(theme.background.ignoresSafeArea())
        .task {
            try? await viewModel.refresh()
            await MainActor.run {
                handlePendingOnboardingPrefill()
            }
        }
        .onChange(of: pendingOnboardingTask) { _, _ in
            handlePendingOnboardingPrefill()
        }
        .onChange(of: isPresentingAddTask) { _, newValue in
            if !newValue {
                pendingOnboardingTask = ""
            }
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
        .alert("重置 Onboarding 流程？", isPresented: $isShowingOnboardingResetAlert) {
            Button("取消", role: .cancel) {}
            Button("重置", role: .destructive) {
                resetOnboardingForDebug()
            }
        } message: {
            Text("此操作会清除引导完成状态。重启应用后将重新进入 Onboarding。")
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
            .presentationBackground(theme.background)
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
            .presentationBackground(theme.background)
        }
    }

    private var header: some View {
        ZStack {
            Text("SimpleFocus")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(theme.textPrimary)

            HStack {
                Spacer()
                if editingTask != nil {
                    Button("完成") {
                        Task {
                            _ = await commitEditing()
                        }
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(theme.primary)
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

            Button {
                isShowingOnboardingResetAlert = true
            } label: {
                Label("重置 Onboarding", systemImage: "arrow.counterclockwise")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(theme.textSecondary)
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
                    if let editingTask, editingTask.id == task.id {
                        EditingTaskRow(task: task,
                                       isPending: viewModel.isPendingCompletion(task.id),
                                       text: $editingText,
                                       errorMessage: editingErrorMessage,
                                       focusBinding: $focusedTaskID,
                                       onComplete: { completeTask(task) },
                                       onSubmit: {
                                           Task { _ = await commitEditing() }
                                       },
                                       onFocusLost: {
                                           handleFocusLost(for: task.id)
                                       })
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    } else {
                        DisplayTaskRow(task: task,
                                        isPending: viewModel.isPendingCompletion(task.id),
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
            .onChange(of: editingText) { _, newValue in
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
                .foregroundColor(theme.textSecondary)
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
                .foregroundColor(theme.textPrimary)
                .background(theme.primary)
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
        let schema = Schema([TaskItem.self, Bonsai.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: configuration)
    }()

    var body: some View {
        let store = TaskStore(modelContext: container.mainContext)
        let focusVM = FocusCalendarViewModel(store: store)
        let bonsaiController = BonsaiController(modelContext: container.mainContext)
        return ContentView(store: store,
                           focusCalendarViewModel: focusVM,
                           bonsaiController: bonsaiController)
            .modelContainer(container)
    }
}

private struct DisplayTaskRow: View {
    let task: TaskItem
    let isPending: Bool
    let onComplete: () -> Void
    let onEdit: () -> Void
    @Environment(\.themePalette) private var theme

    var body: some View {
        HStack(spacing: 16) {
            completeButton

            Text(task.content)
                .font(.system(size: 18))
                .foregroundColor(theme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture(perform: onEdit)
                .accessibilityLabel("编辑任务：\(task.content)")
                .accessibilityHint("双击以修改内容")
        }
        .padding(.vertical, 12)
        .opacity(isPending ? 0.3 : 1)
        .animation(.easeInOut(duration: 0.25), value: isPending)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    private var completeButton: some View {
        Button(action: onComplete) {
            ZStack {
                Circle()
                    .stroke(theme.textPrimary.opacity(0.9), lineWidth: 2)
                    .frame(width: 28, height: 28)
                    .background(
                        Circle()
                            .fill(isPending ? theme.primary : .clear)
                    )
                Image(systemName: "checkmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(theme.textPrimary)
                    .opacity(isPending ? 1 : 0)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct EditingTaskRow: View {
    let task: TaskItem
    let isPending: Bool
    @Binding var text: String
    let errorMessage: String?
    let focusBinding: FocusState<UUID?>.Binding
    let onComplete: () -> Void
    let onSubmit: () -> Void
    let onFocusLost: () -> Void
    @Environment(\.themePalette) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 16) {
                completeButton

                TextField("编辑任务", text: $text)
                    .font(.system(size: 18))
                    .foregroundColor(theme.textPrimary)
                    .submitLabel(.done)
                    .focused(focusBinding, equals: task.id)
                    .onSubmit(onSubmit)
                    .onChange(of: focusBinding.wrappedValue) { newValue in
                        if newValue != task.id {
                            onFocusLost()
                        }
                    }
                    .onChange(of: text) { _, newValue in
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
        .opacity(isPending ? 0.3 : 1)
        .animation(.easeInOut(duration: 0.25), value: isPending)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    private var completeButton: some View {
        Button(action: onComplete) {
            ZStack {
                Circle()
                    .stroke(theme.textPrimary.opacity(0.9), lineWidth: 2)
                    .frame(width: 28, height: 28)
                    .background(
                        Circle()
                            .fill(isPending ? theme.primary : .clear)
                    )
                Image(systemName: "checkmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(theme.textPrimary)
                    .opacity(isPending ? 1 : 0)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct LimitReachedView: View {
    let limitState: EncouragementMessage
    @Environment(\.themePalette) private var theme

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(theme.surfaceElevated)
                    .frame(width: 96, height: 96)
                Image(systemName: "sparkles")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(theme.accentGradient)
            }
            .padding(.bottom, 4)

            Text(limitState.message)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(theme.accentGradient)
                .multilineTextAlignment(.center)

            Text(limitState.encouragement)
                .font(.system(size: 17))
                .foregroundColor(theme.textSecondary)
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
                await focusCalendarViewModel.refresh()
                await evaluateBonsaiGrowth()
            } catch {
                assertionFailure("Failed to refresh after adding task: \(error)")
            }
        }
    }

    func handlePendingOnboardingPrefill(force: Bool = false) {
        let trimmed = pendingOnboardingTask.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if !viewModel.canAddTask {
            pendingOnboardingTask = ""
            return
        }

        guard force || !isPresentingAddTask else { return }

        addTaskViewModel.content = String(trimmed.prefix(AddTaskViewModel.maxLength))
        isPresentingAddTask = true
    }

    func completeTask(_ task: TaskItem) {
        Task {
            if let editingTask, editingTask.id == task.id {
                let success = await commitEditing()
                guard success else { return }
            }
            let calendarViewModel = focusCalendarViewModel
            viewModel.toggleCompletion(for: task) {
                Task {
                    WidgetCenter.shared.reloadAllTimelines()
                    await calendarViewModel.refresh()
                    await evaluateBonsaiGrowth()
                }
            }
        }
    }

    func beginEditing(_ task: TaskItem) {
        Task { await activateEditing(for: task) }
    }

    @MainActor
    private func activateEditing(for task: TaskItem) async {
        print("[InlineEdit] activateEditing start for task=\(task.id), current=\(editingTask?.id.uuidString ?? "nil")")
        if editingTask?.id == task.id {
            print("[InlineEdit] already editing same task, refocusing")
            focusedTaskID = task.id
            return
        }

        if let current = editingTask, current.id != task.id {
            print("[InlineEdit] switching from task=\(current.id) to \(task.id), committing current first")
            let success = await commitEditing()
            guard success else { return }
        }

        editingTask = task
        editingText = task.content
        editingOriginalText = task.content
        editingErrorMessage = nil
        focusedTaskID = task.id
        skipAutoCommitUntil = Date().addingTimeInterval(0.3)
        if let deadline = skipAutoCommitUntil {
            print("[InlineEdit] set skip window until \(deadline)")
        }
        print("[InlineEdit] now editing task=\(task.id), text=\(task.content)")
    }

    @MainActor
    private func handleFocusLost(for taskID: UUID) {
        guard let current = editingTask, current.id == taskID else { return }
        if let deadline = skipAutoCommitUntil, Date() < deadline {
            print("[InlineEdit] focus lost ignored (skip window active)")
            return
        }
        print("[InlineEdit] focus lost commit for task=\(taskID)")
        Task {
            _ = await commitEditing()
        }
    }

    @MainActor
    @discardableResult
    func commitEditing() async -> Bool {
        print("[InlineEdit] commit requested, current task=\(editingTask?.id.uuidString ?? "nil") text=\(editingText)")
        guard let task = editingTask else {
            return true
        }

        let trimmed = editingText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            editingErrorMessage = "请输入任务内容"
            focusedTaskID = task.id
            print("[InlineEdit] commit aborted: empty content")
            return false
        }

        let normalized = String(trimmed.prefix(TaskContentPolicy.maxLength))
        if normalized == editingOriginalText {
            endEditing()
            print("[InlineEdit] commit skipped: no content change")
            return true
        }

        do {
            try await viewModel.edit(task: task, newContent: normalized)
            WidgetCenter.shared.reloadAllTimelines()
            await focusCalendarViewModel.refresh()
            await evaluateBonsaiGrowth()
            endEditing()
            print("[InlineEdit] commit success: updated to \(normalized)")
            return true
        } catch TaskInputError.emptyContent {
            editingErrorMessage = "请输入任务内容"
            focusedTaskID = task.id
            print("[InlineEdit] commit failed: empty content error thrown")
            return false
        } catch TaskUpdateError.completedTask {
            editingErrorMessage = "已完成的任务无法编辑"
            focusedTaskID = task.id
            print("[InlineEdit] commit failed: completed task error")
            return false
        } catch {
            editingErrorMessage = "保存失败，请重试"
            focusedTaskID = task.id
            print("[InlineEdit] commit failed: \(error)")
            return false
        }
    }

    @MainActor
    func endEditing() {
        editingTask = nil
        print("[InlineEdit] endEditing reset state")
        editingText = ""
        editingOriginalText = ""
        editingErrorMessage = nil
        focusedTaskID = nil
        skipAutoCommitUntil = nil
    }

#if DEBUG
    func resetTodayTasksForDebug() {
        Task {
            do {
                try await viewModel.resetTodayTasks()
                addTaskViewModel.content = ""
                await focusCalendarViewModel.refresh()
                await evaluateBonsaiGrowth()
            } catch {
                assertionFailure("Failed to clear today's tasks: \(error)")
            }
        }
    }

    func resetOnboardingForDebug() {
        pendingOnboardingTask = ""
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
    }
#endif

    private func evaluateBonsaiGrowth(referenceDate: Date = Date()) async {
        do {
            let tasks = try await store.fetchTasksForToday(referenceDate: referenceDate)
            guard !tasks.isEmpty else { return }
            guard tasks.allSatisfy(\.isCompleted) else { return }
            if let change = bonsaiController.registerGrowthIfNeeded(for: referenceDate) {
                hasNewBonsaiGrowth = true
                if Self.bonsaiReviewThresholds.contains(where: { change.previous < $0 && change.current >= $0 }) {
                    AppState.attemptReviewRequest(source: "bonsai_growth_\(change.current)")
                }
            }
        } catch {
            print("[Bonsai] Failed to evaluate growth: \(error)")
        }
    }

    private static let bonsaiReviewThresholds: [Int] = [3, 8, 16, 31, 51]
}
