import SwiftUI

public struct GymCalendarStripView: View {
    @Binding public var selectedDate: Date
    @Binding public var isDetailExpanded: Bool
    @ObservedObject private var store = GymStore.shared
    @ObservedObject private var calSync = CalendarSyncService.shared

    private let calendar = Calendar.current

    public init(selectedDate: Binding<Date>, isDetailExpanded: Binding<Bool> = .constant(true)) {
        self._selectedDate = selectedDate
        self._isDetailExpanded = isDetailExpanded
    }

    private var days: [Date] {
        let today = calendar.startOfDay(for: Date())
        let sel = calendar.startOfDay(for: selectedDate)
        let minDate = min(today, sel)
        let maxDate = max(today, sel)

        guard let start = calendar.date(byAdding: .day, value: -14, to: minDate),
              let end = calendar.date(byAdding: .day, value: 7, to: maxDate) else {
            return []
        }

        var result: [Date] = []
        var current = start
        while current <= end {
            result.append(current)
            guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
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
                    let target = calendar.startOfDay(for: selectedDate)
                    proxy.scrollTo(target, anchor: .center)
                }
                .onChange(of: selectedDate) { _, newDate in
                    withAnimation(.easeInOut(duration: 0.25)) {
                        proxy.scrollTo(calendar.startOfDay(for: newDate), anchor: .center)
                    }
                }
            }

            // Historical or future indicator banner
            if !calendar.isDateInToday(selectedDate) {
                HStack {
                    Text("Ausgewählt: \(formattedHeader(selectedDate))")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(GymTheme.textSecondary)

                    Spacer()

                    Button {
                        HapticFeedback.light()
                        selectedDate = Date()
                    } label: {
                        Text("Heute")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(GymTheme.strongBlue)
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
        let hasCompletedSession = store.hasWorkoutOnDate(date)
        let hasNote = !store.note(for: date).isEmpty
        let hasPlanned = store.plannedWorkouts.contains { calendar.isDate($0.plannedDate, inSameDayAs: date) }

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
                    .foregroundColor(isSelected ? Color.white : (isToday ? GymTheme.strongBlue : GymTheme.textMuted))

                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundColor(isSelected ? Color.white : GymTheme.textPrimary)

                // Completion / Planned / Note dot
                HStack(spacing: 2) {
                    if hasCompletedSession {
                        Circle()
                            .fill(isSelected ? Color.white : GymTheme.sageGreen)
                            .frame(width: 4, height: 4)
                    } else if hasPlanned {
                        Circle()
                            .fill(isSelected ? Color.white : GymTheme.warmAmber)
                            .frame(width: 4, height: 4)
                    }
                    if hasNote {
                        Circle()
                            .fill(isSelected ? Color.white : GymTheme.strongBlue)
                            .frame(width: 4, height: 4)
                    }
                    if !hasCompletedSession && !hasPlanned && !hasNote {
                        Circle()
                            .fill(Color.clear)
                            .frame(width: 4, height: 4)
                    }
                }
            }
            .frame(width: 44, height: 58)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? GymTheme.strongBlue : Color.white.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(
                        isSelected ? GymTheme.strongBlue : (isToday ? GymTheme.strongBlue.opacity(0.6) : Color.white.opacity(0.08)),
                        lineWidth: 0.8
                    )
            )
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
