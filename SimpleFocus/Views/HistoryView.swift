//
//  HistoryView.swift
//  SimpleFocus
//
//  Created by Codex on 2025-10-22.
//

import SwiftData
import SwiftUI

@MainActor
struct HistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var calendarViewModel: FocusCalendarViewModel
    var showsDismissButton: Bool = true
    @Environment(\.themePalette) private var theme

    init(calendarViewModel: FocusCalendarViewModel, showsDismissButton: Bool = true) {
        _calendarViewModel = StateObject(wrappedValue: calendarViewModel)
        self.showsDismissButton = showsDismissButton
    }

    var body: some View {
        NavigationStack {
            FocusCalendarView(viewModel: calendarViewModel)
                .navigationTitle("专注日历")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    if showsDismissButton {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("完成") {
                                dismiss()
                            }
                            .foregroundColor(theme.textPrimary)
                        }
                    }
                }
        }
        .background(theme.background.ignoresSafeArea())
    }
}

#Preview {
    let container = try! ModelContainer(for: TaskItem.self,
                                        configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let store = TaskStore(modelContext: container.mainContext)
    return HistoryView(calendarViewModel: FocusCalendarViewModel(store: store))
        .modelContainer(container)
}
