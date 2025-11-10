import SwiftData
import SwiftUI
import WidgetKit

struct ContentView: View {
    @StateObject private var viewModel: TaskListViewModel
    @ObservedObject private var focusCalendarViewModel: FocusCalendarViewModel
    @ObservedObject private var bonsaiController: BonsaiController
    private let store: TaskStore
    @Environment(\.themePalette) private var theme
    @EnvironmentObject private var languageManager: LanguageManager

    @AppStorage("hasNewBonsaiGrowth") private var hasNewBonsaiGrowth: Bool = false
    @AppStorage("pendingOnboardingTask") private var pendingOnboardingTask: String = ""

    @State private var inlineTaskContent: String = ""
    @State private var inlineErrorMessage: String?
    @FocusState private var isInlineInputFocused: Bool
    @State private var inlineInputFrame: CGRect = .zero
    @State private var editingRowFrame: CGRect = .zero
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
        _focusCalendarViewModel = ObservedObject(initialValue: calendarViewModel)
        _bonsaiController = ObservedObject(initialValue: bonsaiController)
    }

    var body: some View {
        VStack(spacing: 16) {
            header
            content
        }
        .padding(.horizontal, 24)
        .padding(.top, 48)
        .padding(.bottom, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.background.ignoresSafeArea())
        .coordinateSpace(name: "content-space")
        .task {
            try? await viewModel.refresh()
            await MainActor.run {
                handlePendingOnboardingPrefill()
            }
        }
        .onChange(of: pendingOnboardingTask) { _, _ in
            handlePendingOnboardingPrefill()
        }
        .onChange(of: editingTask?.id) { _, newValue in
            if newValue == nil {
                editingRowFrame = .zero
            }
        }
        .onChange(of: isInlineInputFocused) { _, isFocused in
            if !isFocused {
                handleInlineFocusLost()
            }
        }
        .onChange(of: inlineTaskContent) { _, newValue in
            if !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                inlineErrorMessage = nil
            }
        }
        .onPreferenceChange(InlineInputFramePreferenceKey.self) { newFrame in
            inlineInputFrame = newFrame
        }
        .onPreferenceChange(EditingRowFramePreferenceKey.self) { newFrame in
            editingRowFrame = newFrame
        }
        .overlay(alignment: .center) {
            if isInlineInputFocused || editingTask != nil {
                Color.clear
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0, coordinateSpace: .named("content-space"))
                            .onEnded { value in
                                let translation = value.translation
                                let tapLike = abs(translation.width) < 6 && abs(translation.height) < 6
                                guard tapLike else { return }
                                handleGlobalTap(at: value.location)
                            }
                    )
            }
        }
#if DEBUG
        .alert(languageManager.localized("清空今天的任务？"), isPresented: $isShowingResetAlert) {
            Button(languageManager.localized("取消"), role: .cancel) {}
            Button(languageManager.localized("清空"), role: .destructive) {
                resetTodayTasksForDebug()
            }
        } message: {
            Text(languageManager.localized("该操作仅用于调试，将删除今天的所有任务。"))
        }
        .alert(languageManager.localized("重置 Onboarding 流程？"), isPresented: $isShowingOnboardingResetAlert) {
            Button(languageManager.localized("取消"), role: .cancel) {}
            Button(languageManager.localized("重置"), role: .destructive) {
                resetOnboardingForDebug()
            }
        } message: {
            Text(languageManager.localized("此操作会清除引导完成状态。重启应用后将重新进入 Onboarding。"))
        }
#endif
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

            HStack(spacing: 12) {
#if DEBUG
                debugMenu
#else
                Color.clear.frame(width: 32, height: 32)
#endif
                Spacer()
                if editingTask != nil {
                    Button(languageManager.localized("完成")) {
                        Task {
                            _ = await commitEditing()
                        }
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(theme.primary)
                } else if canSubmitInlineTask {
                    Button(languageManager.localized("完成")) {
                        submitInlineTask()
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(theme.primary)
                }
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
                Label(languageManager.localized("清空今天的任务"), systemImage: "trash")
            }

            Button {
                isShowingOnboardingResetAlert = true
            } label: {
                Label(languageManager.localized("重置 Onboarding"), systemImage: "arrow.counterclockwise")
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
        let tasks = viewModel.tasks
        List {
            listContent(for: tasks)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .onChange(of: editingText) { _, newValue in
            if editingTask != nil && !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                editingErrorMessage = nil
            }
        }
    }

    private func inlineAddRow(isEmptyState: Bool) -> some View {
        InlineAddTaskRow(text: $inlineTaskContent,
                         placeholder: placeholderText(totalTaskCount: viewModel.totalTasksToday),
                         isEmptyState: isEmptyState,
                         errorMessage: inlineErrorMessage,
                         focusBinding: $isInlineInputFocused,
                         onSubmit: submitInlineTask)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: isEmptyState ? 24 : 8,
                                      leading: 0,
                                      bottom: isEmptyState ? 24 : 8,
                                      trailing: 0))
    }

    private func encouragementRow(limitState: EncouragementMessage) -> some View {
        LimitReachedView(limitState: limitState)
            .padding(.vertical, 24)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 12, leading: 0, bottom: 12, trailing: 0))
    }

    private func placeholderText(totalTaskCount: Int) -> String {
        switch totalTaskCount {
        case 0:
            return languageManager.localized("让我们从定义第一个专注点开始吧！")
        case 1:
            return languageManager.localized("很棒！下一个是什么？")
        case 2:
            return languageManager.localized("最后一个，让今天变得完美！")
        default:
            return ""
        }
    }

    private var canSubmitInlineTask: Bool {
        !inlineTaskContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && viewModel.canAddTask
    }

    @ViewBuilder
    private func listContent(for tasks: [TaskItem]) -> some View {
        if tasks.isEmpty {
            if viewModel.canAddTask {
                inlineAddRow(isEmptyState: true)
            } else if let limitState = viewModel.limitState {
                encouragementRow(limitState: limitState)
            }
        } else {
            ForEach(tasks) { task in
                taskRowView(for: task)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .contentShape(Rectangle())
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            deleteTask(task)
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                        .tint(.red)
                    }
            }

            if viewModel.canAddTask {
                inlineAddRow(isEmptyState: false)
            }
        }
    }

    @ViewBuilder
    private func taskRowView(for task: TaskItem) -> some View {
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
        } else {
            DisplayTaskRow(task: task,
                            isPending: viewModel.isPendingCompletion(task.id),
                            onComplete: { completeTask(task) },
                            onEdit: { beginEditing(task) })
        }
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
        .background(
            GeometryReader { proxy in
                Color.clear.preference(key: EditingRowFramePreferenceKey.self,
                                       value: proxy.frame(in: .named("content-space")))
            }
        )
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

private struct InlineAddTaskRow: View {
    @Binding var text: String
    let placeholder: String
    let isEmptyState: Bool
    let errorMessage: String?
    let focusBinding: FocusState<Bool>.Binding
    let onSubmit: () -> Void
    @Environment(\.themePalette) private var theme

    var body: some View {
        return VStack(alignment: .leading, spacing: 10) {
            TextField(placeholder,
                      text: $text,
                      onCommit: onSubmit)
                .font(.system(size: isEmptyState ? 20 : 18,
                              weight: isEmptyState ? .semibold : .regular))
                .foregroundColor(theme.textPrimary)
                .submitLabel(.done)
                .focused(focusBinding)
                .onChange(of: text) { _, newValue in
                    if newValue.count > TaskContentPolicy.maxLength {
                        text = String(newValue.prefix(TaskContentPolicy.maxLength))
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 18)
                .background(theme.surfaceElevated)
                .cornerRadius(20)
                .background(
                    GeometryReader { proxy in
                        Color.clear.preference(key: InlineInputFramePreferenceKey.self,
                                               value: proxy.frame(in: .named("content-space")))
                    }
                )
                .contentShape(Rectangle())

            if isEmptyState {
                Text("建议：任务保持在20字以内，以便锁屏显示。")
                    .font(.footnote)
                    .foregroundColor(theme.textSecondary)
                    .padding(.leading, 18)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let errorMessage, !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundColor(.red.opacity(0.85))
                    .padding(.leading, 18)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
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

    func submitInlineTask() {
        let trimmed = inlineTaskContent.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            inlineErrorMessage = languageManager.localized("请输入任务内容")
            isInlineInputFocused = true
            return
        }

        Task {
            do {
                let task = try viewModel.addTask(content: trimmed)
                awaitRefreshAfterAdding(task: task)
                await MainActor.run {
                    inlineTaskContent = ""
                    inlineErrorMessage = nil
                    isInlineInputFocused = true
                }
            } catch TaskInputError.limitReached {
                await MainActor.run {
                    inlineErrorMessage = languageManager.localized("今天的三项任务已满，暂无法再添加")
                    isInlineInputFocused = false
                }
            } catch TaskInputError.emptyContent {
                await MainActor.run {
                    inlineErrorMessage = languageManager.localized("请输入任务内容")
                    isInlineInputFocused = true
                }
            } catch {
                await MainActor.run {
                    inlineErrorMessage = languageManager.localized("发生未知错误，请稍后再试")
                }
            }
        }
    }

    func handleInlineFocusLost() {
        guard inlineErrorMessage == nil else { return }
        let trimmed = inlineTaskContent.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        submitInlineTask()
    }

    func handleGlobalTap(at point: CGPoint) {
        if isInlineInputFocused,
           inlineInputFrame.isValid,
           !inlineInputFrame.contains(point) {
            isInlineInputFocused = false
        }
        if editingTask != nil,
           editingRowFrame.isValid,
           !editingRowFrame.contains(point) {
            focusedTaskID = nil
        }
    }

    func handlePendingOnboardingPrefill(force: Bool = false) {
        let trimmed = pendingOnboardingTask.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if !viewModel.canAddTask {
            pendingOnboardingTask = ""
            return
        }

        if !force && !inlineTaskContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return
        }

        inlineTaskContent = String(trimmed.prefix(TaskContentPolicy.maxLength))
        inlineErrorMessage = nil
        pendingOnboardingTask = ""
        isInlineInputFocused = true
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

    func deleteTask(_ task: TaskItem) {
        Task {
            do {
                if let editingTask, editingTask.id == task.id {
                    await MainActor.run { endEditing() }
                }
                try await viewModel.delete(task: task)
                WidgetCenter.shared.reloadAllTimelines()
                await focusCalendarViewModel.refresh()
                await evaluateBonsaiGrowth()
            } catch {
                assertionFailure("Failed to delete task: \(error)")
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
            editingErrorMessage = languageManager.localized("请输入任务内容")
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
            editingErrorMessage = languageManager.localized("请输入任务内容")
            focusedTaskID = task.id
            print("[InlineEdit] commit failed: empty content error thrown")
            return false
        } catch TaskUpdateError.completedTask {
            editingErrorMessage = languageManager.localized("已完成的任务无法编辑")
            focusedTaskID = task.id
            print("[InlineEdit] commit failed: completed task error")
            return false
        } catch {
            editingErrorMessage = languageManager.localized("保存失败，请重试")
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
                inlineTaskContent = ""
                inlineErrorMessage = nil
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

private struct InlineInputFramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        let candidate = nextValue()
        if candidate.isValid {
            value = candidate
        }
    }
}

private struct EditingRowFramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        let candidate = nextValue()
        if candidate.isValid {
            value = candidate
        }
    }
}

private extension CGRect {
    var isValid: Bool {
        !(origin.x.isNaN || origin.y.isNaN || size.width.isNaN || size.height.isNaN)
            && size.width.isFinite && size.height.isFinite && size.width >= 0 && size.height >= 0
    }
}
