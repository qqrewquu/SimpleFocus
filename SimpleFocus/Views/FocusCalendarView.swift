//
//  FocusCalendarView.swift
//  SimpleFocus
//
//  Created by Codex on 2025-10-29.
//

import SwiftUI

struct FocusCalendarView: View {
    @StateObject private var viewModel: FocusCalendarViewModel
    @State private var selectedDate: Date?
    @Environment(\.themePalette) private var theme

    init(viewModel: FocusCalendarViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                monthNavigator
                weekdayHeader
                calendarGrid
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 32)
        }
        .background(theme.background.ignoresSafeArea())
        .navigationTitle("专注日历")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.refresh()
        }
        .sheet(item: Binding(
            get: {
                selectedDate.flatMap { date in
                    FocusCalendarSelection(date: date, tasks: viewModel.tasks(on: date))
                }
            },
            set: { selection in
                selectedDate = selection?.date
            }
        )) { selection in
            DayDetailView(date: selection.date,
                          tasks: selection.tasks,
                          titleText: viewModel.displayString(for: selection.date))
                .presentationDetents([.fraction(0.45), .medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackground(theme.background)
        }
    }

    private var monthNavigator: some View {
        HStack {
            Button {
                viewModel.goToPreviousMonth()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(theme.textSecondary)
                    .padding(8)
            }
            .buttonStyle(.plain)

            Spacer()

            Text(viewModel.monthTitle())
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(theme.textPrimary)

            Spacer()

            Button {
                viewModel.goToNextMonth()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(theme.textSecondary)
                    .padding(8)
            }
            .buttonStyle(.plain)
        }
    }

    private var weekdayHeader: some View {
        let symbols = FocusCalendarViewModel.staticWeekdaySymbols
        return HStack {
            ForEach(symbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(theme.textSecondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var calendarGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 7)
        let days = viewModel.daysForCurrentMonth()
        return LazyVGrid(columns: columns, spacing: 12) {
            ForEach(days) { day in
                DayCellView(day: day) { date in
                    selectedDate = date
                }
            }
        }
    }
}

private struct FocusCalendarSelection: Identifiable {
    let date: Date
    let tasks: [TaskItem]

    var id: Date { date }
}

private extension FocusCalendarViewModel {
    static let staticWeekdaySymbols: [String] = ["日", "一", "二", "三", "四", "五", "六"]
}
