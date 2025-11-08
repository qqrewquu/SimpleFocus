//
//  DayCellView.swift
//  SimpleFocus
//
//  Created by Codex on 2025-10-29.
//

import SwiftUI

struct DayCellView: View {
    let day: FocusCalendarDay
    let onSelect: (Date) -> Void
    @Environment(\.themePalette) private var theme

    init(day: FocusCalendarDay, onSelect: @escaping (Date) -> Void) {
        self.day = day
        self.onSelect = onSelect
    }

    var body: some View {
        if let date = day.date {
            Button {
                onSelect(date)
            } label: {
                GeometryReader { geometry in
                    let size = geometry.size
                    ZStack(alignment: .bottom) {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(theme.surfaceMuted)

                        if day.tasks.isEmpty == false {
                            let tieredColor = colorForCompletionTier
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(tieredColor)
                                .frame(height: size.height * completionRatio)
                                .mask(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                )
                                .animation(.easeInOut(duration: 0.25), value: completionRatio)
                        }

                        Text(dayNumber(for: date))
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(foregroundColor)
                            .padding(.bottom, 6)
                    }
                }
                .aspectRatio(1, contentMode: .fit)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(accessibilityDescription(for: date))
        } else {
            Rectangle()
                .fill(Color.clear)
                .aspectRatio(1, contentMode: .fit)
        }
    }

    private func dayNumber(for date: Date) -> String {
        let calendar = Calendar.current
        let day = calendar.component(.day, from: date)
        return "\(day)"
    }

    private var foregroundColor: Color {
        day.tasks.isEmpty ? theme.textSecondary : theme.textPrimary
    }

    private var completionRatio: CGFloat {
        let total = day.tasks.count
        guard total > 0 else { return 0 }
        let completed = day.tasks.filter(\.isCompleted).count
        return CGFloat(completed) / CGFloat(total)
    }

    private var colorForCompletionTier: Color {
        let total = max(day.tasks.count, 1)
        let completed = day.tasks.filter(\.isCompleted).count
        let ratio = CGFloat(completed) / CGFloat(total)

        switch ratio {
        case 0:
            return theme.surfaceMuted
        case ..<0.34:
            return theme.primary.opacity(0.35)
        case ..<0.67:
            return Color(red: 0.0, green: 181 / 255, blue: 1.0).opacity(0.65)
        default:
            return theme.primary
        }
    }

    private func accessibilityDescription(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMMM d")
        let dateString = formatter.string(from: date)

        let completed = day.tasks.filter(\.isCompleted).count
        let total = day.tasks.count
        if total == 0 {
            return "\(dateString)，无任务"
        }
        let percentage = Int(round(Double(completed) / Double(total) * 100))
        return "\(dateString)，完成 \(completed)/\(total)（\(percentage)%）"
    }
}
