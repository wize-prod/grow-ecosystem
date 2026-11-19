import SwiftUI
import UniformTypeIdentifiers

public struct StudyCalendarStripView: View {
    @Binding public var selectedDate: Date
    public var currentTrack: StudyTrack?
    public var showsDetailBanner: Bool
    @ObservedObject private var store = StudyStore.shared
    @ObservedObject private var calSync = StudyCalendarSyncService.shared

    @State private var selectedStepForDetail: RoadmapStep? = nil

    private let calendar = Calendar.current

    public init(selectedDate: Binding<Date>, currentTrack: StudyTrack? = nil, showsDetailBanner: Bool = true) {
        self._selectedDate = selectedDate
        self.currentTrack = currentTrack
        self.showsDetailBanner = showsDetailBanner
    }

    private var days: [Date] {
        let today = calendar.startOfDay(for: Date())
        var result: [Date] = []
        for i in (-7...7) {
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
                            CalendarDayPillView(
                                date: date,
                                isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                                isToday: calendar.isDateInToday(date),
                                appDots: store.ecosystemAppDots(for: date, track: currentTrack),
                                onSelect: {
                                    HapticFeedback.light()
                                    selectedDate = date
                                },
                                onDropTask: { payload, dropDate in
                                    handleDrop(payload: payload, targetDate: dropDate)
                                }
                            )
                            .id(calendar.startOfDay(for: date))
                        }
                    }
                    .padding(.horizontal, 4)
                }
                .onAppear {
                    let todayStart = calendar.startOfDay(for: Date())
                    proxy.scrollTo(todayStart, anchor: .center)
                }
            }

            // Planned Tasks Banner for Selected Day (Optional)
            if showsDetailBanner {
                let plannedSteps = store.plannedSteps(for: selectedDate, track: currentTrack)
                let plannedSubmods = store.plannedSubmodules(for: selectedDate, track: currentTrack)

                if !plannedSteps.isEmpty || !plannedSubmods.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: "calendar.badge.clock")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(StudyTheme.accent)
                            Text("Geplant für \(formattedShortDate(selectedDate)):")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(StudyTheme.textPrimary)
                            Spacer()
                            if calSync.isAuthorized {
                                Text("Google Calendar")
                                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                                    .foregroundColor(StudyTheme.accent)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(StudyTheme.accent.opacity(0.12))
                                    .cornerRadius(4)
                            }
                        }

                        ForEach(plannedSteps) { step in
                            Button {
                                selectedStepForDetail = step
                            } label: {
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(step.isCompleted ? StudyTheme.successGreen : StudyTheme.accent)
                                        .frame(width: 6, height: 6)
                                    Text(step.title)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(StudyTheme.textPrimary)
                                        .lineLimit(1)
                                    Spacer()
                                    Text("\(step.estimatedMinutes)m")
                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                        .foregroundColor(StudyTheme.textSecondary)
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundColor(StudyTheme.textMuted)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .background(StudyTheme.surfaceElevated)
                                .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }

                        ForEach(plannedSubmods, id: \.submodule.id) { item in
                            Button {
                                selectedStepForDetail = item.step
                            } label: {
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(item.submodule.isCompleted ? StudyTheme.successGreen : StudyTheme.purpleTrack)
                                        .frame(width: 6, height: 6)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.submodule.title)
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(StudyTheme.textPrimary)
                                            .lineLimit(1)
                                        Text(item.step.title)
                                            .font(.system(size: 9, weight: .regular))
                                            .foregroundColor(StudyTheme.textSecondary)
                                            .lineLimit(1)
                                    }
                                    Spacer()
                                    Text("\(item.submodule.durationMinutes)m")
                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                        .foregroundColor(StudyTheme.textSecondary)
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundColor(StudyTheme.textMuted)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(StudyTheme.surfaceElevated.opacity(0.8))
                                .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(12)
                    .liquidGlass(cornerRadius: 16)
                } else if !calendar.isDateInToday(selectedDate) {
                    HStack {
                        Text("Ausgewählt: \(formattedHeader(selectedDate))")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(StudyTheme.textSecondary)

                        Spacer()

                        Button {
                            HapticFeedback.light()
                            selectedDate = Date()
                        } label: {
                            Text("Heute")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(StudyTheme.strongBlue)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color.white.opacity(0.06))
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(Color.white.opacity(0.10), lineWidth: 0.8)
                                )
                        }
                        .buttonStyle(AppleTactileButtonStyle())
                    }
                    .padding(.top, 2)
                }
            }
        }
        .sheet(item: $selectedStepForDetail) { step in
            StepDetailSheet(step: step)
        }
    }

    private func handleDrop(payload: String, targetDate: Date) {
        if payload.hasPrefix("step:") {
            let stepId = String(payload.dropFirst(5))
            store.updateStepDetails(stepId: stepId, plannedDate: targetDate)
            selectedDate = targetDate
            HapticFeedback.success()
        } else if payload.hasPrefix("submodule:") {
            let parts = payload.components(separatedBy: ":")
            if parts.count == 3 {
                let parentId = parts[1]
                let subId = parts[2]
                store.updateSubmoduleDetails(parentStepId: parentId, submoduleId: subId, plannedDate: targetDate)
                selectedDate = targetDate
                HapticFeedback.success()
            }
        }
    }

    private func formattedHeader(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "d. MMMM yyyy"
        return formatter.string(from: date)
    }

    private func formattedShortDate(_ date: Date) -> String {
        if calendar.isDateInToday(date) { return "Heute" }
        if calendar.isDateInTomorrow(date) { return "Morgen" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "EE, d. MMM"
        return formatter.string(from: date)
    }
}

// MARK: - Calendar Day Pill View mit Drop-Target für Aufgaben & Submodule
struct CalendarDayPillView: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let appDots: [Color]
    let onSelect: () -> Void
    let onDropTask: (String, Date) -> Void

    @State private var isTargeted: Bool = false
    private let calendar = Calendar.current

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 3) {
                Text(weekdayAbbreviation(date))
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(isSelected ? Color.white : (isToday ? StudyTheme.strongBlue : StudyTheme.textMuted))

                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundColor(isSelected ? Color.white : StudyTheme.textPrimary)

                HStack(spacing: 2.0) {
                    let visibleDots = Array(appDots.prefix(4))
                    if !visibleDots.isEmpty {
                        ForEach(Array(visibleDots.enumerated()), id: \.offset) { _, dotColor in
                            Circle()
                                .fill(isSelected && isBlueLike(dotColor) ? Color.white : dotColor)
                                .frame(width: 4, height: 4)
                        }
                    } else {
                        Color.clear.frame(width: 4, height: 4)
                    }
                }
                .frame(height: 6)
                .padding(.bottom, 3)
            }
            .frame(width: 46, height: 64)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isTargeted ? StudyTheme.strongBlue.opacity(0.35) : (isSelected ? StudyTheme.strongBlue : Color.white.opacity(0.05)))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(
                        isTargeted ? StudyTheme.strongBlue : (isSelected ? StudyTheme.strongBlue : (isToday ? StudyTheme.strongBlue.opacity(0.6) : Color.white.opacity(0.08))),
                        lineWidth: isTargeted ? 2 : 0.8
                    )
            )
            .scaleEffect(isTargeted ? 1.08 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isTargeted)
        }
        .buttonStyle(AppleTactileButtonStyle())
        .onDrop(of: [UTType.text.identifier, "public.text"], isTargeted: $isTargeted) { providers in
            for provider in providers {
                _ = provider.loadObject(ofClass: String.self) { payload, _ in
                    guard let payload = payload else { return }
                    Task { @MainActor in
                        onDropTask(payload, date)
                    }
                }
            }
            return true
        }
    }

    private func isBlueLike(_ color: Color) -> Bool {
        return color == StudyTheme.strongBlue || color == Color(red: 0.25, green: 0.58, blue: 0.98)
    }

    private func weekdayAbbreviation(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "EE"
        return formatter.string(from: date).replacingOccurrences(of: ".", with: "").uppercased()
    }
}
