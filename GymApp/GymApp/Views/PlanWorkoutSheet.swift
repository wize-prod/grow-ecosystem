import SwiftUI

public struct PlanWorkoutSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: GymStore

    public let targetDate: Date

    @State private var selectedDate: Date
    @State private var isMarkedCompleted: Bool = false
    @State private var customTitle: String = ""
    @State private var customNotes: String = ""
    @State private var showingCustomBuilder: Bool = false

    public init(targetDate: Date) {
        self.targetDate = targetDate
        _selectedDate = State(initialValue: targetDate)
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                GymTheme.bg.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // 1. Datum & Status-Auswahl (Vergangenheit, Gegenwart, Zukunft)
                        dateAndStatusCard

                        // 2. Freie benutzerdefinierte Einheit
                        customWorkoutCard

                        // 3. Aus Vorlagen planen / eintragen
                        templatesCard

                        // 4. Aus Programmen planen / eintragen
                        programsCard

                        Spacer(minLength: 40)
                    }
                    .padding(16)
                }
                .scrollDismissesKeyboard(.interactively)
                .dismissKeyboardOnTap()
                .dismissKeyboardOnSwipeDown()
            }
            .navigationTitle("Einheit planen / eintragen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Schliessen") { dismiss() }
                        .foregroundColor(GymTheme.textMuted)
                }
            }
        }
    }

    // MARK: - 1. Date & Status Card
    private var dateAndStatusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("DATUM & STATUS")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(GymTheme.textMuted)
                    Text(formatFullDate(selectedDate))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(GymTheme.textPrimary)
                }
                Spacer()
                Image(systemName: isMarkedCompleted ? "checkmark.circle.fill" : "calendar.badge.clock")
                    .font(.system(size: 22))
                    .foregroundColor(isMarkedCompleted ? GymTheme.sageGreen : GymTheme.strongBlue)
            }

            DatePicker(
                "Datum",
                selection: $selectedDate,
                displayedComponents: [.date]
            )
            .datePickerStyle(.compact)
            .labelsHidden()

            Divider().background(GymTheme.borderSubtle)

            // Status Toggle (Geplant vs. Bereits absolviert)
            Picker("Status", selection: $isMarkedCompleted) {
                Text("Geplant (Offen)").tag(false)
                Text("Bereits absolviert").tag(true)
            }
            .pickerStyle(.segmented)
        }
        .padding(14)
        .wellnessCard(borderColor: GymTheme.border, cornerRadius: 16)
    }

    // MARK: - 2. Custom Workout Card
    private var customWorkoutCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("EIGENE EINHEIT ERSTELLEN")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(GymTheme.textMuted)

            TextField("Titel der Einheit (z.B. Brust & Trizeps)", text: $customTitle)
                .font(.system(size: 13))
                .padding(10)
                .background(GymTheme.surfaceElevated)
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(GymTheme.borderSubtle, lineWidth: 1))

            TextField("Notizen / Fokus (optional)", text: $customNotes)
                .font(.system(size: 12))
                .padding(10)
                .background(GymTheme.surfaceElevated)
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(GymTheme.borderSubtle, lineWidth: 1))

            Button {
                guard !customTitle.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                store.addHistoricalOrPlannedWorkout(
                    title: customTitle.trimmingCharacters(in: .whitespaces),
                    date: selectedDate,
                    isCompleted: isMarkedCompleted,
                    notes: customNotes
                )
                dismiss()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: isMarkedCompleted ? "checkmark.circle" : "plus.circle")
                    Text(isMarkedCompleted ? "Als absolviert speichern" : "Als geplante Einheit anlegen")
                }
                .font(.system(size: 12, weight: .bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(customTitle.trimmingCharacters(in: .whitespaces).isEmpty ? GymTheme.surfaceElevated : GymTheme.strongBlue)
                .foregroundColor(customTitle.trimmingCharacters(in: .whitespaces).isEmpty ? GymTheme.textMuted : GymTheme.bg)
                .cornerRadius(8)
            }
            .disabled(customTitle.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(14)
        .wellnessCard(borderColor: GymTheme.border, cornerRadius: 16)
    }

    // MARK: - 3. Aus Vorlagen
    private var templatesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("AUS VORLAGEN")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(GymTheme.textMuted)

            ForEach(store.templates) { template in
                Button {
                    planTemplate(template)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(template.name)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(GymTheme.textPrimary)
                            Text("\(template.category) • \(template.items.count) Uebungen • ~\(template.estimatedMinutes) min")
                                .font(.system(size: 11))
                                .foregroundColor(GymTheme.textSecondary)
                        }
                        Spacer()
                        Image(systemName: isMarkedCompleted ? "checkmark.circle.fill" : "plus.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(isMarkedCompleted ? GymTheme.sageGreen : GymTheme.strongBlue)
                    }
                    .padding(12)
                    .background(GymTheme.surfaceElevated)
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(GymTheme.borderSubtle, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .wellnessCard(borderColor: GymTheme.border, cornerRadius: 16)
    }

    // MARK: - 4. Aus Programmen
    private var programsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("AUS PROGRAMMEN")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(GymTheme.textMuted)

            ForEach(store.programs.prefix(3)) { program in
                ForEach(program.allSessions.prefix(3)) { session in
                    Button {
                        planProgramSession(session, program: program)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(session.title)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(GymTheme.textPrimary)
                                Text("\(program.name) • \(session.exercises.count) Uebungen")
                                    .font(.system(size: 10.5))
                                    .foregroundColor(GymTheme.textSecondary)
                            }
                            Spacer()
                            Image(systemName: isMarkedCompleted ? "checkmark.circle.fill" : "calendar.badge.plus")
                                .font(.system(size: 16))
                                .foregroundColor(isMarkedCompleted ? GymTheme.sageGreen : GymTheme.strongBlue)
                        }
                        .padding(10)
                        .background(GymTheme.surfaceElevated)
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .wellnessCard(borderColor: GymTheme.border, cornerRadius: 16)
    }

    private func planTemplate(_ template: WorkoutTemplate) {
        store.addHistoricalOrPlannedWorkout(
            title: template.name,
            date: selectedDate,
            isCompleted: isMarkedCompleted,
            templateId: template.id,
            notes: template.summary,
            exerciseNames: template.items.map { $0.exercise.name }
        )
        dismiss()
    }

    private func planProgramSession(_ session: ProgramSession, program: TrainingProgram) {
        let item = PlannedWorkoutItem(
            programId: program.id,
            programName: program.name,
            sessionId: session.id,
            dayNumber: session.dayNumber,
            title: session.title,
            plannedDate: selectedDate,
            isCompleted: isMarkedCompleted,
            completedAt: isMarkedCompleted ? selectedDate : nil,
            modalityRaw: session.modality.rawValue,
            exerciseNames: session.exercises.map { $0.name }
        )
        store.plannedWorkouts.append(item)
        store.savePlannedWorkouts()
        HapticFeedback.success()

        if !isMarkedCompleted {
            Task { @MainActor in
                if let eventId = await CalendarSyncService.shared.schedulePlannedWorkoutEvent(planned: item, template: nil) {
                    if let idx = store.plannedWorkouts.firstIndex(where: { $0.id == item.id }) {
                        store.plannedWorkouts[idx].calendarEventId = eventId
                        store.savePlannedWorkouts()
                    }
                }
            }
        }
        dismiss()
    }

    private func formatFullDate(_ d: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateStyle = .full
        return formatter.string(from: d)
    }
}
