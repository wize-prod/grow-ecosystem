import SwiftUI

public struct CalendarStripView: View {
    @Binding public var selectedDate: Date
    @Binding public var isDetailExpanded: Bool
    @ObservedObject var store = LocalStore.shared

    private let calendar = Calendar.current
    private let dayCount = 14

    public init(selectedDate: Binding<Date>, isDetailExpanded: Binding<Bool> = .constant(true)) {
        self._selectedDate = selectedDate
        self._isDetailExpanded = isDetailExpanded
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
                        .foregroundColor(Theme.warmSand)
                    Spacer()
                    Button(action: {
                        HapticFeedbackService.shared.lightDetent()
                        selectedDate = Date()
                    }) {
                        Text("Heute anzeigen")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Theme.sageGreen)
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
        let p = store.protein(for: date)
        let hasLogs = !store.logs(for: date).isEmpty
        let isFulfilled = p >= store.targetProtein

        return Button(action: {
            HapticFeedbackService.shared.lightDetent()
            withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                if isSelected {
                    isDetailExpanded.toggle()
                } else {
                    selectedDate = date
                    isDetailExpanded = true
                }
            }
        }) {
            VStack(spacing: 6) {
                Text(weekdayAbbreviation(date))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(isSelected ? Theme.textPrimary : Theme.textSecondary)

                ZStack {
                    Circle()
                        .fill(isSelected ? Theme.sageGreen : (isToday ? Color.white.opacity(0.12) : Color.clear))
                        .frame(width: 36, height: 36)
                        .shadow(color: isSelected ? Theme.sageGreen.opacity(0.35) : Color.clear, radius: 6, x: 0, y: 3)

                    Text("\(calendar.component(.day, from: date))")
                        .font(.system(size: 16, weight: isSelected || isToday ? .bold : .medium))
                        .foregroundColor(isSelected ? Color.black : (isToday ? Theme.sageGreen : Theme.textPrimary))
                }

                // Completion dot indicator
                Circle()
                    .fill(isFulfilled ? Theme.sageGreen : (hasLogs ? Theme.warmSand : Color.clear))
                    .frame(width: 5, height: 5)
            }
            .frame(width: 44, height: 72)
            .contentShape(Rectangle())
        }
        .buttonStyle(AppleTactileButtonStyle())
    }

    private static let weekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "EE"
        return formatter
    }()

    private static let headerFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "d. MMMM yyyy"
        return formatter
    }()

    private func weekdayAbbreviation(_ date: Date) -> String {
        return Self.weekdayFormatter.string(from: date).replacingOccurrences(of: ".", with: "").uppercased()
    }

    private func formattedHeader(_ date: Date) -> String {
        return Self.headerFormatter.string(from: date)
    }
}
