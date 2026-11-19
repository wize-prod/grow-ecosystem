import SwiftUI

public struct CareCalendarStripView: View {
    @Binding public var selectedDate: Date
    @ObservedObject var store = GrowCareStore.shared

    private let calendar = Calendar.current
    private let dayCount = 14

    public init(selectedDate: Binding<Date>) {
        self._selectedDate = selectedDate
    }

    private var pastDays: [Date] {
        let today = calendar.startOfDay(for: Date())
        var days: [Date] = []
        for i in (0..<dayCount).reversed() {
            if let d = calendar.date(byAdding: .day, value: -i, to: today) {
                days.append(d)
            }
        }
        return days
    }

    public var body: some View {
        VStack(spacing: 8) {
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(pastDays, id: \.self) { date in
                            dayPill(for: date)
                                .id(calendar.startOfDay(for: date))
                        }
                    }
                    .padding(.horizontal, 2)
                }
                .onAppear {
                    let todayStart = calendar.startOfDay(for: Date())
                    proxy.scrollTo(todayStart, anchor: .trailing)
                }
            }

            if !calendar.isDateInToday(selectedDate) {
                HStack {
                    Text("Historische Ansicht: \(formattedHeader(selectedDate))")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(CareTheme.warmSand)
                    Spacer()
                    Button(action: {
                        let haptic = UIImpactFeedbackGenerator(style: .light)
                        haptic.impactOccurred()
                        selectedDate = Date()
                    }) {
                        Text("Heute anzeigen")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(CareTheme.careLilac)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.white.opacity(0.06)))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 4)
            }
        }
    }

    @ViewBuilder
    private func dayPill(for date: Date) -> some View {
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let isToday = calendar.isDateInToday(date)
        let dayKey = store.dateKey(for: date)

        let completedRoutines = store.completedRoutineIds[dayKey]?.count ?? 0
        let completedChores = store.completedChoreIds[dayKey]?.count ?? 0
        let totalCompleted = completedRoutines + completedChores

        Button(action: {
            let haptic = UIImpactFeedbackGenerator(style: .light)
            haptic.impactOccurred()
            selectedDate = date
        }) {
            VStack(spacing: 4) {
                Text(shortWeekday(date))
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(isSelected ? CareTheme.bg : (isToday ? CareTheme.careLilac : CareTheme.textSecondary))

                Text(dayNumber(date))
                    .font(.system(size: 14, weight: isSelected ? .bold : .semibold, design: .monospaced))
                    .foregroundColor(isSelected ? CareTheme.bg : CareTheme.textPrimary)

                // Activity dot indicator
                Circle()
                    .fill(totalCompleted > 0 ? (isSelected ? CareTheme.bg : CareTheme.careSage) : Color.clear)
                    .frame(width: 4, height: 4)
            }
            .frame(width: 44, height: 62)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? CareTheme.careLilac : (isToday ? Color.white.opacity(0.08) : CareTheme.surface))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(
                        isSelected ? CareTheme.careLilac : (isToday ? CareTheme.careLilac.opacity(0.4) : CareTheme.border),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func shortWeekday(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "EE"
        return formatter.string(from: date).uppercased().replacingOccurrences(of: ".", with: "")
    }

    private func dayNumber(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    private func formattedHeader(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "EEEE, d. MMMM"
        return formatter.string(from: date)
    }
}

