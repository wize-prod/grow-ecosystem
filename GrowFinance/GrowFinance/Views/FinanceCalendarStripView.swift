import SwiftUI

public struct FinanceCalendarStripView: View {
    @Binding public var selectedDate: Date
    @Binding public var isDetailExpanded: Bool
    @ObservedObject private var store = FinanceStore.shared
    @ObservedObject private var calSync = CalendarSyncService.shared

    private let calendar = Calendar.current

    public init(selectedDate: Binding<Date>, isDetailExpanded: Binding<Bool> = .constant(true)) {
        self._selectedDate = selectedDate
        self._isDetailExpanded = isDetailExpanded
    }

    private var days: [Date] {
        let today = calendar.startOfDay(for: Date())
        var result: [Date] = []
        // Show 10 days in past and 14 days in future (to observe upcoming fixed costs)
        for i in (-10...14) {
            if let d = calendar.date(byAdding: .day, value: i, to: today) {
                result.append(d)
            }
        }
        return result
    }

    public var body: some View {
        VStack(spacing: 8) {
            // Calendar Scroll Strip
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(days, id: \.self) { date in
                            dayPill(for: date)
                                .id(calendar.startOfDay(for: date))
                        }
                    }
                    .padding(.horizontal, 2)
                }
                .onAppear {
                    let todayStart = calendar.startOfDay(for: Date())
                    proxy.scrollTo(todayStart, anchor: .center)
                }
            }

            // Historical or future indicator banner
            if !calendar.isDateInToday(selectedDate) {
                HStack {
                    Text("Ausgewählt: \(formattedHeader(selectedDate))")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(FinanceTheme.textSecondary)

                    Spacer()

                    Button {
                        HapticFeedback.light()
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedDate = Date()
                            isDetailExpanded = true
                        }
                    } label: {
                        Text("Heute")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(FinanceTheme.accent)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.white.opacity(0.06)))
                            .overlay(Capsule().stroke(Color.white.opacity(0.10), lineWidth: 0.8))
                    }
                    .buttonStyle(AppleTactileButtonStyle())
                }
                .padding(.top, 2)
            }
        }
    }

    private func dayPill(for date: Date) -> some View {
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let isToday = calendar.isDateInToday(date)
        let hasFixedCost = store.recurringFixedCostsThisMonth.contains { cost in
            guard let due = cost.expectedDueDateThisMonth else { return false }
            return calendar.isDate(due, inSameDayAs: date)
        }
        let matchingTx = store.transactions.first { calendar.isDate($0.date, inSameDayAs: date) }
        let hasTx = matchingTx != nil

        return Button {
            HapticFeedback.light()
            withAnimation(.easeInOut(duration: 0.2)) {
                if isSelected {
                    isDetailExpanded.toggle()
                } else {
                    selectedDate = date
                    isDetailExpanded = true
                }
            }
        } label: {
            VStack(spacing: 4) {
                Text(weekdayAbbreviation(date))
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(isSelected ? FinanceTheme.background : (isToday ? FinanceTheme.accent : FinanceTheme.textSecondary))

                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundColor(isSelected ? FinanceTheme.background : FinanceTheme.textPrimary)

                // Status Indicator Dot
                Circle()
                    .fill(
                        isSelected ? FinanceTheme.background :
                        (hasFixedCost ? FinanceTheme.warning :
                         (hasTx ? ((matchingTx?.amount ?? 0) > 0 ? FinanceTheme.positive : FinanceTheme.accent) : Color.clear))
                    )
                    .frame(width: 4, height: 4)
            }
            .frame(width: 44, height: 58)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? FinanceTheme.accent : Color.white.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(
                        isSelected ? FinanceTheme.accent : (isToday ? FinanceTheme.accent.opacity(0.6) : Color.white.opacity(0.08)),
                        lineWidth: 0.8
                    )
            )
        }
        .buttonStyle(AppleTactileButtonStyle())
    }

    private func weekdayAbbreviation(_ date: Date) -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "de_DE")
        df.dateFormat = "EE"
        return df.string(from: date).uppercased().replacingOccurrences(of: ".", with: "")
    }

    private func formattedHeader(_ date: Date) -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "de_DE")
        df.dateFormat = "EEEE, d. MMMM yyyy"
        return df.string(from: date)
    }
}
