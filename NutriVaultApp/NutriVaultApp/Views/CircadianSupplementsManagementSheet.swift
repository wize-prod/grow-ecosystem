import SwiftUI

// MARK: - Circadian Supplements Management Sheet
public struct CircadianSupplementsManagementSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: LocalStore
    @ObservedObject private var notifications = SupplementNotificationService.shared

    public var selectedDate: Date
    public var onDismiss: () -> Void

    @State private var expandedDoseId: String? = nil
    @State private var showingEditSheet: Bool = false
    @State private var selectedDoseToEdit: CircadianSupplementDose? = nil
    @State private var showResetConfirmation: Bool = false

    public init(selectedDate: Date = Date(), onDismiss: @escaping () -> Void) {
        self.selectedDate = selectedDate
        self.onDismiss = onDismiss
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Protocol Overview Card
                    protocolOverviewHeader

                    let morningDoses = store.allSupplements.filter {
                        let hour = supplementHour($0)
                        return hour < 11
                    }
                    if !morningDoses.isEmpty {
                        supplementSection(
                            title: "MORGEN • NEUROTRANSMITTER & ATP",
                            timeRange: "06:00 - 10:59 Uhr",
                            doses: morningDoses
                        )
                    }

                    let noonDoses = store.allSupplements.filter {
                        let hour = supplementHour($0)
                        return hour >= 11 && hour < 15
                    }
                    if !noonDoses.isEmpty {
                        supplementSection(
                            title: "MITTAG • KNOCHEN & ZELLSCHUTZ",
                            timeRange: "11:00 - 14:59 Uhr",
                            doses: noonDoses
                        )
                    }

                    let afternoonDoses = store.allSupplements.filter {
                        let hour = supplementHour($0)
                        return hour >= 15 && hour < 19
                    }
                    if !afternoonDoses.isEmpty {
                        supplementSection(
                            title: "PRE-WORKOUT & NACHMITTAG • NITRAT & RECOVERY",
                            timeRange: "15:00 - 18:59 Uhr",
                            doses: afternoonDoses
                        )
                    }

                    let eveningDoses = store.allSupplements.filter {
                        let hour = supplementHour($0)
                        return hour >= 19
                    }
                    if !eveningDoses.isEmpty {
                        supplementSection(
                            title: "ABEND & NACHTRUHE • CARNOSIN & ZNS-RELAXATION",
                            timeRange: "19:00 - 23:59 Uhr",
                            doses: eveningDoses
                        )
                    }

                    // Reset button
                    Button(action: {
                        showResetConfirmation = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Standard-Fahrplan wiederherstellen")
                        }
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Theme.textMuted)
                        .padding(.vertical, 8)
                    }

                    // Safety standard note
                    safetyNoteCard

                    Spacer().frame(height: 30)
                }
                .padding(16)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Zirkadiane Supplements")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        HapticFeedbackService.shared.mechanicalClick()
                        notifications.toggleNotifications()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: notifications.isNotificationsEnabled ? "bell.badge.fill" : "bell.slash")
                                .font(.system(size: 11))
                            Text(notifications.isNotificationsEnabled ? "Push aktiv" : "Push aus")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .foregroundColor(notifications.isNotificationsEnabled ? Theme.sageGreen : Theme.textMuted)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        Button(action: {
                            HapticFeedbackService.shared.lightDetent()
                            selectedDoseToEdit = nil
                            showingEditSheet = true
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Theme.warmSand)
                        }

                        Button("Fertig") {
                            onDismiss()
                            dismiss()
                        }
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Theme.warmSand)
                    }
                }
            }
            .sheet(isPresented: $showingEditSheet) {
                EditSupplementSheet(dose: selectedDoseToEdit)
                    .environmentObject(store)
            }
            .confirmationDialog("Standard-Fahrplan wiederherstellen?", isPresented: $showResetConfirmation, titleVisibility: .visible) {
                Button("Auf Werkseinstellungen zurücksetzen", role: .destructive) {
                    store.resetSupplementsToDefault()
                }
                Button("Abbrechen", role: .cancel) {}
            } message: {
                Text("Alle benutzerdefinierten Einnahmepläne werden durch die wissenschaftliche Standard-Konfiguration ersetzt.")
            }
        }
        .presentationDragIndicator(.visible)
    }

    private func supplementHour(_ dose: CircadianSupplementDose) -> Int {
        let parts = dose.scheduledTime.split(separator: ":")
        if let h = parts.first, let val = Int(h) {
            return val
        }
        return 0
    }

    private var protocolOverviewHeader: some View {
        let takenCount = store.allSupplements.filter {
            store.isSupplementTaken(doseId: $0.id, date: selectedDate)
        }.count
        let totalCount = store.allSupplements.count
        let progress = totalCount > 0 ? Double(takenCount) / Double(totalCount) : 0.0

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("ZIRKADIANER DOSIERUNGS-FAHRPLAN")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(Theme.warmSand)
                        .tracking(0.6)
                    Text("\(takenCount) von \(totalCount) Dosen genommen")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Theme.textPrimary)
                }
                Spacer()
                ZStack {
                    Circle()
                        .stroke(Theme.border, lineWidth: 3)
                        .frame(width: 36, height: 36)
                    Circle()
                        .trim(from: 0, to: CGFloat(progress))
                        .stroke(Theme.sageGreen, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 36, height: 36)
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(Theme.textPrimary)
                }
            }

            Text("Wissenschaftlich getaktetes Einnahmeschema zur Maximierung von Bioverfügbarkeit, Muskelproteinsynthese und ZNS-Regeneration.")
                .font(.system(size: 11))
                .foregroundColor(Theme.textMuted)
        }
        .padding(14)
        .wellnessCard()
    }

    private func supplementSection(title: String, timeRange: String, doses: [CircadianSupplementDose]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.textMuted)
                    .tracking(0.5)
                Spacer()
                Text(timeRange)
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(Theme.warmSand)
            }

            VStack(spacing: 8) {
                ForEach(doses) { dose in
                    detailedDoseCard(dose: dose)
                }
            }
        }
    }

    private func detailedDoseCard(dose: CircadianSupplementDose) -> some View {
        let isTaken = store.isSupplementTaken(doseId: dose.id, date: selectedDate)
        let isExpanded = expandedDoseId == dose.id
        let isMissed = CircadianSupplementProtocol.isDoseMissed(dose: dose) && !isTaken && Calendar.current.isDateInToday(selectedDate)

        return VStack(alignment: .leading, spacing: 0) {
            // Main Row Header
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(dose.scheduledTime + " Uhr")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(Theme.warmSand)

                        Text("•")
                            .foregroundColor(Theme.textMuted)

                        Text(dose.targetArea)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Theme.textSecondary)

                        if isMissed {
                            Text("Verpasst")
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundColor(Theme.terracotta)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(RoundedRectangle(cornerRadius: 3).fill(Theme.terracotta.opacity(0.15)))
                        }
                    }

                    Text(dose.name)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Theme.textPrimary)

                    Text(dose.dosage)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(Theme.textMuted)
                }

                Spacer()

                // Edit Button
                Button(action: {
                    HapticFeedbackService.shared.lightDetent()
                    selectedDoseToEdit = dose
                    showingEditSheet = true
                }) {
                    Image(systemName: "pencil")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textMuted)
                        .padding(6)
                }

                // Expand / Info indicator
                Button(action: {
                    HapticFeedbackService.shared.lightDetent()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        expandedDoseId = isExpanded ? nil : dose.id
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.warmSand)
                        .padding(6)
                }

                // Checkbox toggle
                Button(action: {
                    store.toggleSupplement(doseId: dose.id, date: selectedDate)
                }) {
                    ZStack {
                        Circle()
                            .fill(isTaken ? Theme.sageGreen : Theme.surface)
                            .frame(width: 28, height: 28)
                            .overlay(Circle().stroke(isTaken ? Theme.sageGreen : Theme.border, lineWidth: 1.5))
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(isTaken ? Theme.bg : Theme.textMuted)
                    }
                }
            }
            .padding(12)

            // Expanded Details View
            if isExpanded {
                Divider().background(Theme.border.opacity(0.5))

                VStack(alignment: .leading, spacing: 10) {
                    // Einnahme Instruktion
                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.warmSand)
                        Text(dose.instructions)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Theme.textSecondary)
                    }

                    // Novice Kurzzeit-Wirkung
                    if !dose.shortTermImpact.isEmpty {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("KURZZEIT-WIRKUNG (0-4 STUNDEN)")
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundColor(Theme.sageGreen)
                            Text(dose.shortTermImpact)
                                .font(.system(size: 11))
                                .foregroundColor(Theme.textPrimary)
                        }
                    }

                    // Novice Langzeit-Wirkung
                    if !dose.longTermImpact.isEmpty {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("LANGZEIT-WIRKUNG (WOCHEN & MONATE)")
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundColor(Theme.warmSand)
                            Text(dose.longTermImpact)
                                .font(.system(size: 11))
                                .foregroundColor(Theme.textPrimary)
                        }
                    }

                    // Biochemischer Mechanismus
                    VStack(alignment: .leading, spacing: 2) {
                        Text("BIOCHEMISCHER MECHANISMUS")
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundColor(Theme.textMuted)
                        Text(dose.mechanism)
                            .font(.system(size: 10))
                            .foregroundColor(Theme.textSecondary)
                    }

                    // Nährwerte falls vorhanden
                    if dose.kcal > 0 || dose.protein > 0 {
                        HStack(spacing: 12) {
                            Text(String(format: "%.0f kcal", dose.kcal))
                            Text(String(format: "%.1fg Protein", dose.protein))
                            Text(String(format: "%.1fg Carbs", dose.carbs))
                            Text(String(format: "%.1fg Fett", dose.fat))
                        }
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(Theme.textMuted)
                    }

                    // Delete button in expanded card
                    HStack {
                        Spacer()
                        Button(role: .destructive, action: {
                            store.deleteSupplementDose(id: dose.id)
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "trash")
                                Text("Löschen")
                            }
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Theme.terracotta)
                            .padding(.top, 4)
                        }
                    }
                }
                .padding(12)
                .background(Theme.surface)
            }
        }
        .contextMenu {
            Button {
                selectedDoseToEdit = dose
                showingEditSheet = true
            } label: {
                Label("Bearbeiten", systemImage: "pencil")
            }

            Button(role: .destructive) {
                store.deleteSupplementDose(id: dose.id)
            } label: {
                Label("Löschen", systemImage: "trash")
            }
        }
        .wellnessCard(borderColor: isTaken ? Theme.sageGreen.opacity(0.4) : Theme.border)
    }

    private var safetyNoteCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("SICHERHEITSSTANDARD: ANTI-DOPPELGABE-REGEL")
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(Theme.warmSand)
            Text("Verpasste Dosen werden niemals aufaddiert oder nachgeholt. Bei Zeitfenster-Überschreitung wird die Dosis übersprungen, um die circadiane Rezeptor-Sensitivität und Magenruhe zu wahren.")
                .font(.system(size: 10))
                .foregroundColor(Theme.textMuted)
        }
        .padding(12)
        .wellnessCard()
    }
}

// MARK: - Edit / Create Supplement Sheet
public struct EditSupplementSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: LocalStore

    public let existingDose: CircadianSupplementDose?

    @State private var name: String
    @State private var dosage: String
    @State private var scheduledDate: Date
    @State private var targetArea: String
    @State private var mechanism: String
    @State private var benefit: String
    @State private var instructions: String
    @State private var kcalString: String
    @State private var proteinString: String
    @State private var carbsString: String
    @State private var fatString: String
    @State private var fiberString: String
    @State private var showDeleteConfirmation: Bool = false

    public init(dose: CircadianSupplementDose? = nil) {
        self.existingDose = dose
        _name = State(initialValue: dose?.name ?? "")
        _dosage = State(initialValue: dose?.dosage ?? "")
        _targetArea = State(initialValue: dose?.targetArea ?? "Allgemein & Zellschutz")
        _mechanism = State(initialValue: dose?.mechanism ?? "")
        _benefit = State(initialValue: dose?.benefit ?? "")
        _instructions = State(initialValue: dose?.instructions ?? "")
        _kcalString = State(initialValue: dose != nil && dose!.kcal > 0 ? String(format: "%.1f", dose!.kcal) : "")
        _proteinString = State(initialValue: dose != nil && dose!.protein > 0 ? String(format: "%.1f", dose!.protein) : "")
        _carbsString = State(initialValue: dose != nil && dose!.carbs > 0 ? String(format: "%.1f", dose!.carbs) : "")
        _fatString = State(initialValue: dose != nil && dose!.fat > 0 ? String(format: "%.1f", dose!.fat) : "")
        _fiberString = State(initialValue: dose != nil && dose!.fiber > 0 ? String(format: "%.1f", dose!.fiber) : "")

        var initialDate = Date()
        if let timeStr = dose?.scheduledTime {
            let parts = timeStr.split(separator: ":")
            if parts.count == 2, let h = Int(parts[0]), let m = Int(parts[1]) {
                var comps = Calendar.current.dateComponents([.year, .month, .day], from: Date())
                comps.hour = h
                comps.minute = m
                initialDate = Calendar.current.date(from: comps) ?? Date()
            }
        }
        _scheduledDate = State(initialValue: initialDate)
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && !dosage.trimmingCharacters(in: .whitespaces).isEmpty
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Basisdaten
                        VStack(alignment: .leading, spacing: 12) {
                            Text("BASISDATEN")
                                .font(.system(size: 10, weight: .bold))
                                .tracking(0.8)
                                .foregroundColor(Theme.warmSand)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Name des Supplements")
                                    .font(.caption)
                                    .foregroundColor(Theme.textMuted)
                                TextField("z. B. Vitamin D3 + K2", text: $name)
                                    .textFieldStyle(.plain)
                                    .padding(10)
                                    .background(Theme.surface)
                                    .foregroundColor(Theme.textPrimary)
                                    .cornerRadius(8)
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 1))
                            }

                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Dosierung")
                                        .font(.caption)
                                        .foregroundColor(Theme.textMuted)
                                    TextField("z. B. 5.000 IE", text: $dosage)
                                        .textFieldStyle(.plain)
                                        .padding(10)
                                        .background(Theme.surface)
                                        .foregroundColor(Theme.textPrimary)
                                        .cornerRadius(8)
                                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 1))
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Einnahmezeit")
                                        .font(.caption)
                                        .foregroundColor(Theme.textMuted)
                                    DatePicker("", selection: $scheduledDate, displayedComponents: .hourAndMinute)
                                        .labelsHidden()
                                        .padding(4)
                                }
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Zielbereich / Fokus")
                                    .font(.caption)
                                    .foregroundColor(Theme.textMuted)
                                TextField("z. B. Knochen, Energie, ZNS & Schlaf", text: $targetArea)
                                    .textFieldStyle(.plain)
                                    .padding(10)
                                    .background(Theme.surface)
                                    .foregroundColor(Theme.textPrimary)
                                    .cornerRadius(8)
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 1))
                            }
                        }
                        .wellnessCard()

                        // Einnahme & Wirkung
                        VStack(alignment: .leading, spacing: 12) {
                            Text("EINNAHME & PHYSIOLOGISCHER NUTZEN")
                                .font(.system(size: 10, weight: .bold))
                                .tracking(0.8)
                                .foregroundColor(Theme.warmSand)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Einnahmehinweis")
                                    .font(.caption)
                                    .foregroundColor(Theme.textMuted)
                                TextField("z. B. Zu einer Mahlzeit mit stillem Wasser", text: $instructions)
                                    .textFieldStyle(.plain)
                                    .padding(10)
                                    .background(Theme.surface)
                                    .foregroundColor(Theme.textPrimary)
                                    .cornerRadius(8)
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 1))
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Biochemischer Mechanismus / Nutzen")
                                    .font(.caption)
                                    .foregroundColor(Theme.textMuted)
                                TextField("z. B. Optimiert Calciumresorption und Zellregeneration", text: $mechanism, axis: .vertical)
                                    .lineLimit(2...4)
                                    .textFieldStyle(.plain)
                                    .padding(10)
                                    .background(Theme.surface)
                                    .foregroundColor(Theme.textPrimary)
                                    .cornerRadius(8)
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 1))
                            }
                        }
                        .wellnessCard()

                        // Nährwerte (Optional)
                        VStack(alignment: .leading, spacing: 12) {
                            Text("MAKRONÄHRWERTE (OPTIONAL)")
                                .font(.system(size: 10, weight: .bold))
                                .tracking(0.8)
                                .foregroundColor(Theme.warmSand)

                            HStack(spacing: 8) {
                                macroInputField(title: "kcal", text: $kcalString)
                                macroInputField(title: "Protein (g)", text: $proteinString)
                                macroInputField(title: "Carbs (g)", text: $carbsString)
                                macroInputField(title: "Fett (g)", text: $fatString)
                            }
                        }
                        .wellnessCard()

                        // Löschen-Button (falls vorhanden)
                        if let ex = existingDose {
                            Button(role: .destructive) {
                                showDeleteConfirmation = true
                            } label: {
                                HStack {
                                    Spacer()
                                    Image(systemName: "trash")
                                    Text("Supplement löschen")
                                    Spacer()
                                }
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Theme.terracotta)
                                .padding(.vertical, 12)
                                .background(Theme.surface)
                                .cornerRadius(10)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border, lineWidth: 1))
                            }
                            .confirmationDialog("Supplement wirklich löschen?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                                Button("Endgültig löschen", role: .destructive) {
                                    store.deleteSupplementDose(id: ex.id)
                                    dismiss()
                                }
                                Button("Abbrechen", role: .cancel) {}
                            } message: {
                                Text("Das Supplement wird aus dem täglichen Einnahmeplan entfernt.")
                            }
                        }

                        Spacer().frame(height: 30)
                    }
                    .padding(16)
                }
            }
            .navigationTitle(existingDose == nil ? "Neues Supplement" : "Supplement bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                    .foregroundColor(Theme.warmSand)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        save()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(isValid ? Theme.sageGreen : Theme.textMuted)
                    .disabled(!isValid)
                }
            }
        }
    }

    private func macroInputField(title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 9))
                .foregroundColor(Theme.textMuted)
            TextField("0", text: text)
                .keyboardType(.decimalPad)
                .textFieldStyle(.plain)
                .font(.system(size: 11, design: .monospaced))
                .padding(8)
                .background(Theme.surface)
                .foregroundColor(Theme.textPrimary)
                .cornerRadius(6)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.border, lineWidth: 1))
        }
    }

    private func save() {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let timeStr = formatter.string(from: scheduledDate)

        let dose = CircadianSupplementDose(
            id: existingDose?.id ?? "supp_custom_\(UUID().uuidString.prefix(8))",
            name: name.trimmingCharacters(in: .whitespaces),
            dosage: dosage.trimmingCharacters(in: .whitespaces),
            scheduledTime: timeStr,
            mechanism: mechanism.trimmingCharacters(in: .whitespaces).isEmpty ? "Physiologische Unterstützung" : mechanism.trimmingCharacters(in: .whitespaces),
            benefit: benefit.trimmingCharacters(in: .whitespaces).isEmpty ? "Optimierung der Vitalwerte" : benefit.trimmingCharacters(in: .whitespaces),
            targetArea: targetArea.trimmingCharacters(in: .whitespaces).isEmpty ? "Allgemeine Gesundheit" : targetArea.trimmingCharacters(in: .whitespaces),
            instructions: instructions.trimmingCharacters(in: .whitespaces).isEmpty ? "Mit stillem Wasser einnehmen" : instructions.trimmingCharacters(in: .whitespaces),
            shortTermImpact: existingDose?.shortTermImpact ?? "",
            longTermImpact: existingDose?.longTermImpact ?? "",
            noviceExplanation: existingDose?.noviceExplanation ?? "",
            kcal: Double(kcalString.replacingOccurrences(of: ",", with: ".")) ?? 0.0,
            protein: Double(proteinString.replacingOccurrences(of: ",", with: ".")) ?? 0.0,
            carbs: Double(carbsString.replacingOccurrences(of: ",", with: ".")) ?? 0.0,
            fat: Double(fatString.replacingOccurrences(of: ",", with: ".")) ?? 0.0,
            fiber: Double(fiberString.replacingOccurrences(of: ",", with: ".")) ?? 0.0
        )

        store.saveSupplementDose(dose)
        dismiss()
    }
}
