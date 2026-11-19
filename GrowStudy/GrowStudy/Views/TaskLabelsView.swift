import SwiftUI

// MARK: - 24 Google Tasks / Calendar Palette Swatches
public enum GoogleTaskColors {
    public static let palette: [String] = [
        // Reihe 1: Rottöne, Orange, Gelb
        "#E67C73", "#D50000", "#F4511E", "#E65100", "#F6BF26", "#F57C00", "#E4C441", "#FBC02D",
        // Reihe 2: Grüntöne, Petrol, Blau
        "#D8E273", "#B3D146", "#33B679", "#0B8043", "#00897B", "#039BE5", "#3F51B5", "#1976D2",
        // Reihe 3: Lila, Violett, Erd- und Grautöne
        "#7986CB", "#9C27B0", "#8E24AA", "#BA68C8", "#8D6E63", "#616161", "#A79B8E", "#D7CCC8"
    ]
}

// MARK: - Google Tasks Style Color Picker Sheet
public struct GoogleColorPickerSheet: View {
    @Binding var selectedHex: String
    @Environment(\.dismiss) private var dismiss
    @State private var tempHex: String = ""

    public init(selectedHex: Binding<String>) {
        self._selectedHex = selectedHex
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("Farbe auswählen")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                Text("Textfarbe wird automatisch angepasst.")
                    .font(.system(size: 13))
                    .foregroundColor(StudyTheme.textMuted)
            }

            // 24 Swatches Grid (3 Reihen x 8 Spalten)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 8), spacing: 12) {
                ForEach(GoogleTaskColors.palette, id: \.self) { hex in
                    Button {
                        tempHex = hex
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 32, height: 32)

                            if tempHex.lowercased() == hex.lowercased() {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            // Vorschau & Hex-Eingabe
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color(hex: tempHex))
                        .frame(width: 44, height: 44)
                    Text("A")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Hex-Farbwert")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(StudyTheme.textMuted)
                    HStack {
                        Text("#")
                            .foregroundColor(StudyTheme.textMuted)
                        TextField("Farbe", text: Binding(
                            get: { tempHex.replacingOccurrences(of: "#", with: "") },
                            set: { tempHex = "#" + $0 }
                        ))
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(.white)
                        .textFieldStyle(.plain)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.12), lineWidth: 1))
                }
            }
            .padding(.top, 6)

            Spacer()

            // Footer Buttons
            HStack {
                Spacer()
                Button("Abbrechen") {
                    dismiss()
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(StudyTheme.textMuted)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)

                Button("Auswählen") {
                    selectedHex = tempHex
                    dismiss()
                }
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.black)
                .padding(.horizontal, 18)
                .padding(.vertical, 8)
                .background(Color(red: 0.55, green: 0.76, blue: 0.98))
                .cornerRadius(18)
            }
        }
        .padding(22)
#if targetEnvironment(macCatalyst)
        .frame(minWidth: 360, maxWidth: 420, minHeight: 340)
#endif
        .background(Color(red: 0.12, green: 0.12, blue: 0.13))
        .onAppear {
            tempHex = selectedHex
        }
    }
}

// MARK: - Task Labels Management Sheet (Matching User Screenshot 1)
public struct TaskLabelsManagementSheet: View {
    @EnvironmentObject private var store: StudyStore
    @Environment(\.dismiss) private var dismiss

    @State private var workingLabels: [TaskColorLabel] = []
    @State private var activeColorPickerLabelId: String? = nil
    @State private var pickingColorHex: String = "#039BE5"

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Labels")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(StudyTheme.textMuted)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 14)

            Divider().background(Color.white.opacity(0.08))

            // Scrollbare Liste der Labels
            ScrollView {
                VStack(spacing: 12) {
                    ForEach($workingLabels) { $lbl in
                        HStack(spacing: 10) {
                            // Farbauswahl-Knopf mit Punkt & kleinem Pfeil
                            Button {
                                pickingColorHex = lbl.colorHex
                                activeColorPickerLabelId = lbl.id
                            } label: {
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(Color(hex: lbl.colorHex))
                                        .frame(width: 18, height: 18)
                                    Image(systemName: "arrowtriangle.down.fill")
                                        .font(.system(size: 7))
                                        .foregroundColor(StudyTheme.textMuted)
                                }
                                .padding(6)
                                .background(Color.white.opacity(0.04))
                                .cornerRadius(6)
                            }
                            .buttonStyle(.plain)

                            // Label-Name Eingabefeld
                            TextField("Label-Name eingeben", text: $lbl.name)
                                .font(.system(size: 13.5))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.08), lineWidth: 1))

                            // Lösch-Knopf
                            Button {
                                workingLabels.removeAll(where: { $0.id == lbl.id })
                            } label: {
                                Image(systemName: "trash")
                                    .font(.system(size: 12))
                                    .foregroundColor(StudyTheme.textMuted.opacity(0.7))
                                    .padding(6)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(20)
            }

            Divider().background(Color.white.opacity(0.08))

            // Footer: + Button links, Cancel & Save rechts
            HStack {
                Button {
                    let randomHex = GoogleTaskColors.palette[workingLabels.count % GoogleTaskColors.palette.count]
                    workingLabels.append(TaskColorLabel(name: "", colorHex: randomHex))
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.08))
                            .frame(width: 36, height: 36)
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(.plain)

                Spacer()

                Button("Abbrechen") {
                    dismiss()
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(StudyTheme.textMuted)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)

                Button("Speichern") {
                    let clean = workingLabels.map { lbl -> TaskColorLabel in
                        var copy = lbl
                        copy.name = copy.name.trimmingCharacters(in: .whitespacesAndNewlines)
                        if copy.name.isEmpty { copy.name = "Neues Label" }
                        return copy
                    }
                    store.setLabels(clean)
                    dismiss()
                }
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.black)
                .padding(.horizontal, 18)
                .padding(.vertical, 8)
                .background(Color(red: 0.55, green: 0.76, blue: 0.98))
                .cornerRadius(18)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
#if targetEnvironment(macCatalyst)
        .frame(minWidth: 380, maxWidth: 460, minHeight: 400, maxHeight: 540)
#endif
        .background(Color(red: 0.12, green: 0.12, blue: 0.13))
        .onAppear {
            workingLabels = store.labels
        }
        .sheet(isPresented: Binding(
            get: { activeColorPickerLabelId != nil },
            set: { if !$0 { activeColorPickerLabelId = nil } }
        )) {
            GoogleColorPickerSheet(selectedHex: Binding(
                get: { pickingColorHex },
                set: { newHex in
                    pickingColorHex = newHex
                    if let targetId = activeColorPickerLabelId,
                       let idx = workingLabels.firstIndex(where: { $0.id == targetId }) {
                        workingLabels[idx].colorHex = newHex
                    }
                }
            ))
        }
    }
}

// MARK: - Custom Recurrence Picker Sheet
public struct CustomRecurrencePickerSheet: View {
    let initialRule: CustomRecurrenceRule?
    let onSave: (CustomRecurrenceRule?) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var isRecurring: Bool = false
    @State private var interval: Int = 1
    @State private var unit: RecurrenceUnit = .week
    @State private var repeatDays: Set<Int> = [1] // 1 = Mo, ..., 7 = So
    @State private var endType: RecurrenceEndType = .never
    @State private var endDate: Date = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
    @State private var maxOccurrences: Int = 10

    public init(initialRule: CustomRecurrenceRule?, onSave: @escaping (CustomRecurrenceRule?) -> Void) {
        self.initialRule = initialRule
        self.onSave = onSave
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Wiederholung")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(StudyTheme.textMuted)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 12)

            Divider().background(Color.white.opacity(0.08))

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    // Aktivierungs-Toggle
                    Toggle("Wiederkehrendes Ereignis", isOn: $isRecurring)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .tint(StudyTheme.strongBlue)

                    if isRecurring {
                        // Intervall & Einheit
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Wiederholen alle")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(StudyTheme.textMuted)

                            HStack(spacing: 10) {
                                Stepper("\(interval)", value: $interval, in: 1...99)
                                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white)
                                    .frame(width: 100)

                                Picker("Einheit", selection: $unit) {
                                    Text("Tag(e)").tag(RecurrenceUnit.day)
                                    Text("Woche(n)").tag(RecurrenceUnit.week)
                                    Text("Monat(e)").tag(RecurrenceUnit.month)
                                    Text("Jahr(e)").tag(RecurrenceUnit.year)
                                }
                                .pickerStyle(.segmented)
                            }
                        }

                        // Wochentage (nur bei Einheit = Woche)
                        if unit == .week {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("An folgenden Tagen")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(StudyTheme.textMuted)

                                HStack(spacing: 6) {
                                    let days = [
                                        (1, "Mo"), (2, "Di"), (3, "Mi"), (4, "Do"),
                                        (5, "Fr"), (6, "Sa"), (7, "So")
                                    ]
                                    ForEach(days, id: \.0) { dayNum, dayName in
                                        let isSelected = repeatDays.contains(dayNum)
                                        Button {
                                            if isSelected {
                                                if repeatDays.count > 1 {
                                                    repeatDays.remove(dayNum)
                                                }
                                            } else {
                                                repeatDays.insert(dayNum)
                                            }
                                        } label: {
                                            Text(dayName)
                                                .font(.system(size: 11.5, weight: .bold))
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 7)
                                                .background(isSelected ? StudyTheme.strongBlue : Color.white.opacity(0.06))
                                                .foregroundColor(isSelected ? .white : StudyTheme.textSecondary)
                                                .cornerRadius(6)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }

                        // Endet
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Endet")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(StudyTheme.textMuted)

                            VStack(alignment: .leading, spacing: 10) {
                                Button {
                                    endType = .never
                                } label: {
                                    HStack {
                                        Image(systemName: endType == .never ? "largecircle.fill.circle" : "circle")
                                            .foregroundColor(endType == .never ? StudyTheme.strongBlue : StudyTheme.textMuted)
                                        Text("Nie")
                                            .font(.system(size: 13))
                                            .foregroundColor(.white)
                                    }
                                }
                                .buttonStyle(.plain)

                                Button {
                                    endType = .onDate
                                } label: {
                                    HStack {
                                        Image(systemName: endType == .onDate ? "largecircle.fill.circle" : "circle")
                                            .foregroundColor(endType == .onDate ? StudyTheme.strongBlue : StudyTheme.textMuted)
                                        Text("Am Datum")
                                            .font(.system(size: 13))
                                            .foregroundColor(.white)
                                        if endType == .onDate {
                                            DatePicker("", selection: $endDate, displayedComponents: .date)
                                                .labelsHidden()
                                        }
                                    }
                                }
                                .buttonStyle(.plain)

                                Button {
                                    endType = .afterOccurrences
                                } label: {
                                    HStack {
                                        Image(systemName: endType == .afterOccurrences ? "largecircle.fill.circle" : "circle")
                                            .foregroundColor(endType == .afterOccurrences ? StudyTheme.strongBlue : StudyTheme.textMuted)
                                        Text("Nach")
                                            .font(.system(size: 13))
                                            .foregroundColor(.white)
                                        if endType == .afterOccurrences {
                                            Stepper("\(maxOccurrences) Mal", value: $maxOccurrences, in: 1...100)
                                                .labelsHidden()
                                                .font(.system(size: 12, design: .monospaced))
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(20)
            }

            Divider().background(Color.white.opacity(0.08))

            // Footer
            HStack {
                if isRecurring {
                    Button("Entfernen", role: .destructive) {
                        onSave(nil)
                        dismiss()
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.red.opacity(0.85))
                }

                Spacer()

                Button("Abbrechen") {
                    dismiss()
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(StudyTheme.textMuted)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

                Button("Fertig") {
                    if isRecurring {
                        let rule = CustomRecurrenceRule(
                            interval: interval,
                            unit: unit,
                            repeatDays: Array(repeatDays).sorted(),
                            endType: endType,
                            endDate: endType == .onDate ? endDate : nil,
                            maxOccurrences: endType == .afterOccurrences ? maxOccurrences : nil,
                            completedOccurrences: initialRule?.completedOccurrences ?? 0
                        )
                        onSave(rule)
                    } else {
                        onSave(nil)
                    }
                    dismiss()
                }
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.black)
                .padding(.horizontal, 18)
                .padding(.vertical, 8)
                .background(Color(red: 0.55, green: 0.76, blue: 0.98))
                .cornerRadius(18)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
#if targetEnvironment(macCatalyst)
        .frame(minWidth: 360, maxWidth: 420, minHeight: 380, maxHeight: 480)
#endif
        .background(Color(red: 0.12, green: 0.12, blue: 0.13))
        .onAppear {
            if let r = initialRule {
                isRecurring = true
                interval = r.interval
                unit = r.unit
                repeatDays = Set(r.repeatDays.isEmpty ? [1] : r.repeatDays)
                endType = r.endType
                if let ed = r.endDate { endDate = ed }
                if let mo = r.maxOccurrences { maxOccurrences = mo }
            } else {
                isRecurring = false
                let currentWeekday = Calendar.current.component(.weekday, from: Date())
                let iso = currentWeekday == 1 ? 7 : currentWeekday - 1
                repeatDays = [iso]
            }
        }
    }
}
