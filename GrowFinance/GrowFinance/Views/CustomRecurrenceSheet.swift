import SwiftUI

public struct CustomRecurrenceSheet: View {
    @Environment(\.dismiss) private var dismiss

    @Binding public var rule: CustomRecurrenceRule
    public var onSave: (CustomRecurrenceRule) -> Void

    @State private var interval: Int
    @State private var unit: RecurrenceUnit
    @State private var selectedDays: Set<Int>
    @State private var endType: RecurrenceEndType
    @State private var endDate: Date
    @State private var maxOccurrences: Int

    private let dayLabels = [
        (1, "M"),
        (2, "T"),
        (3, "W"),
        (4, "T"),
        (5, "F"),
        (6, "S"),
        (7, "S")
    ]

    public init(rule: Binding<CustomRecurrenceRule>, onSave: @escaping (CustomRecurrenceRule) -> Void) {
        self._rule = rule
        self.onSave = onSave

        let current = rule.wrappedValue
        self._interval = State(initialValue: current.interval)
        self._unit = State(initialValue: current.unit)
        self._selectedDays = State(initialValue: Set(current.repeatDays))
        self._endType = State(initialValue: current.endType)
        self._endDate = State(initialValue: current.endDate ?? Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date())
        self._maxOccurrences = State(initialValue: current.maxOccurrences ?? 13)
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.12, green: 0.13, blue: 0.14).ignoresSafeArea()

                VStack(alignment: .leading, spacing: 22) {
                    // Header Title
                    Text("Custom recurrence")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.top, 8)

                    // Repeat every section
                    HStack(spacing: 12) {
                        Text("Repeat every")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(Color(white: 0.85))

                        // Number input / stepper
                        HStack(spacing: 8) {
                            Text("\(interval)")
                                .font(.system(size: 15, weight: .medium, design: .monospaced))
                                .foregroundColor(.white)
                                .frame(minWidth: 24)

                            VStack(spacing: 1) {
                                Button {
                                    interval += 1
                                    HapticFeedback.light()
                                } label: {
                                    Image(systemName: "chevron.up")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(Color(white: 0.7))
                                }
                                Button {
                                    if interval > 1 {
                                        interval -= 1
                                        HapticFeedback.light()
                                    }
                                } label: {
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(Color(white: 0.7))
                                }
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color(white: 0.20)))

                        // Unit Picker Menu (day, week, month, year)
                        Menu {
                            ForEach(RecurrenceUnit.allCases) { u in
                                Button(u.rawValue) {
                                    unit = u
                                    HapticFeedback.light()
                                }
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Text(unit.rawValue)
                                    .font(.system(size: 15, weight: .regular))
                                    .foregroundColor(.white)
                                Image(systemName: "arrowtriangle.down.fill")
                                    .font(.system(size: 8))
                                    .foregroundColor(Color(white: 0.7))
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Color(white: 0.20)))
                        }
                    }

                    // Repeat on weekdays (if unit == .week)
                    if unit == .week {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Repeat on")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(Color(white: 0.7))

                            HStack(spacing: 8) {
                                ForEach(dayLabels, id: \.0) { (dayIdx, label) in
                                    let isSelected = selectedDays.contains(dayIdx)
                                    Button {
                                        if isSelected {
                                            if selectedDays.count > 1 {
                                                selectedDays.remove(dayIdx)
                                            }
                                        } else {
                                            selectedDays.insert(dayIdx)
                                        }
                                        HapticFeedback.light()
                                    } label: {
                                        ZStack {
                                            Circle()
                                                .fill(isSelected ? Color(red: 0.65, green: 0.78, blue: 0.98) : Color(white: 0.22))
                                                .frame(width: 36, height: 36)
                                            Text(label)
                                                .font(.system(size: 13, weight: .semibold))
                                                .foregroundColor(isSelected ? Color(red: 0.08, green: 0.16, blue: 0.28) : Color(white: 0.8))
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    // Ends section
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Ends")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(Color(white: 0.7))

                        // Radio option: Never
                        Button {
                            endType = .never
                            HapticFeedback.light()
                        } label: {
                            HStack(spacing: 12) {
                                radioIcon(selected: endType == .never)
                                Text("Never")
                                    .font(.system(size: 15))
                                    .foregroundColor(.white)
                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)

                        // Radio option: On Date
                        Button {
                            endType = .onDate
                            HapticFeedback.light()
                        } label: {
                            HStack(spacing: 12) {
                                radioIcon(selected: endType == .onDate)
                                Text("On")
                                    .font(.system(size: 15))
                                    .foregroundColor(.white)

                                DatePicker(
                                    "",
                                    selection: $endDate,
                                    displayedComponents: .date
                                )
                                .labelsHidden()
                                .datePickerStyle(.compact)
                                .colorScheme(.dark)
                                .disabled(endType != .onDate)
                                .opacity(endType == .onDate ? 1.0 : 0.5)

                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)

                        // Radio option: After occurrences
                        Button {
                            endType = .afterOccurrences
                            HapticFeedback.light()
                        } label: {
                            HStack(spacing: 12) {
                                radioIcon(selected: endType == .afterOccurrences)
                                Text("After")
                                    .font(.system(size: 15))
                                    .foregroundColor(.white)

                                HStack(spacing: 8) {
                                    Text("\(maxOccurrences)")
                                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                                        .foregroundColor(.white)
                                        .frame(minWidth: 20)

                                    VStack(spacing: 1) {
                                        Button {
                                            maxOccurrences += 1
                                            endType = .afterOccurrences
                                            HapticFeedback.light()
                                        } label: {
                                            Image(systemName: "chevron.up")
                                                .font(.system(size: 8, weight: .bold))
                                                .foregroundColor(Color(white: 0.7))
                                        }
                                        Button {
                                            if maxOccurrences > 1 {
                                                maxOccurrences -= 1
                                                endType = .afterOccurrences
                                                HapticFeedback.light()
                                            }
                                        } label: {
                                            Image(systemName: "chevron.down")
                                                .font(.system(size: 8, weight: .bold))
                                                .foregroundColor(Color(white: 0.7))
                                        }
                                    }
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(RoundedRectangle(cornerRadius: 6).fill(Color(white: 0.20)))
                                .opacity(endType == .afterOccurrences ? 1.0 : 0.5)

                                Text("occurrences")
                                    .font(.system(size: 15))
                                    .foregroundColor(Color(white: 0.85))

                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer()

                    // Bottom Action Buttons: Cancel and Done
                    HStack {
                        Spacer()

                        Button("Cancel") {
                            HapticFeedback.light()
                            dismiss()
                        }
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color(red: 0.65, green: 0.78, blue: 0.98))
                        .padding(.trailing, 16)

                        Button {
                            HapticFeedback.success()
                            let updatedRule = CustomRecurrenceRule(
                                interval: interval,
                                unit: unit,
                                repeatDays: Array(selectedDays),
                                endType: endType,
                                endDate: endType == .onDate ? endDate : nil,
                                maxOccurrences: endType == .afterOccurrences ? maxOccurrences : nil,
                                completedOccurrences: rule.completedOccurrences
                            )
                            rule = updatedRule
                            onSave(updatedRule)
                            dismiss()
                        } label: {
                            Text("Done")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(Color(red: 0.08, green: 0.16, blue: 0.28))
                                .padding(.horizontal, 22)
                                .padding(.vertical, 10)
                                .background(Capsule().fill(Color(red: 0.65, green: 0.78, blue: 0.98)))
                        }
                    }
                    .padding(.bottom, 12)
                }
                .padding(20)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func radioIcon(selected: Bool) -> some View {
        ZStack {
            Circle()
                .stroke(selected ? Color(red: 0.65, green: 0.78, blue: 0.98) : Color(white: 0.4), lineWidth: 2)
                .frame(width: 20, height: 20)
            if selected {
                Circle()
                    .fill(Color(red: 0.65, green: 0.78, blue: 0.98))
                    .frame(width: 10, height: 10)
            }
        }
    }
}
