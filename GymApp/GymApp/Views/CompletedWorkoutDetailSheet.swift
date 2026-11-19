import SwiftUI

public struct CompletedWorkoutDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: GymStore

    @State private var session: WorkoutSession
    @State private var showingEditSheet: Bool = false
    @State private var showingDeleteConfirmation: Bool = false
    @State private var selectedExerciseForDetail: Exercise? = nil
    @State private var isMuscleMapExpanded: Bool = true

    public init(session: WorkoutSession) {
        _session = State(initialValue: session)
    }

    private var dayWeight: Double? {
        store.measurements.first(where: {
            $0.type == .weight && Calendar.current.isDate($0.date, inSameDayAs: session.startTime)
        })?.value
    }

    private var durationText: String {
        let mins = session.durationMinutes
        if mins >= 60 {
            let h = mins / 60
            let m = mins % 60
            return "\(h)h \(m)min"
        } else {
            return "\(mins)min"
        }
    }

    private var volumeText: String {
        let kg = Int(round(session.totalTonnageKg))
        return "\(kg) kg"
    }

    private var prText: String {
        "\(session.prCount) PRs"
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                GymTheme.bg.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header Bar (X, Title, Bearbeiten) - Image 2 & 3 Style
                    HStack {
                        Button {
                            dismiss()
                            HapticFeedback.light()
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(GymTheme.surfaceElevated)
                                    .frame(width: 34, height: 34)
                                    .overlay(Circle().stroke(GymTheme.border, lineWidth: 0.8))

                                Image(systemName: "xmark")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(GymTheme.textSecondary)
                            }
                        }

                        Spacer()

                        Text(session.title)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(GymTheme.textPrimary)
                            .lineLimit(1)

                        Spacer()

                        HStack(spacing: 14) {
                            if let url = exportPDFURL {
                                ShareLink(
                                    item: url,
                                    preview: SharePreview("\(session.title).pdf", icon: Image(systemName: "doc.text.fill"))
                                ) {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(GymTheme.cyanAccent)
                                }
                                .accessibilityLabel("Workout als PDF teilen")
                            }

                            Button {
                                showingEditSheet = true
                                HapticFeedback.light()
                            } label: {
                                Text("Bearbeiten")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(Color(red: 0.25, green: 0.60, blue: 0.95))
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                    .padding(.bottom, 6)

                    // Scrollable Session Details
                    ScrollView {
                        VStack(alignment: .leading, spacing: 18) {
                            // Subtitle: Time, Day, Full Date (Image 2 & 3 Style)
                            Text(formatSessionDate(session.startTime))
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(GymTheme.textSecondary)
                                .padding(.horizontal, 4)

                            // Key Metrics Strip (Duration, Volume, PRs, optional Day Weight)
                            HStack(spacing: 16) {
                                HStack(spacing: 6) {
                                    Image(systemName: "clock")
                                        .font(.system(size: 13))
                                        .foregroundColor(GymTheme.textMuted)
                                    Text(durationText)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(GymTheme.textPrimary)
                                }

                                HStack(spacing: 6) {
                                    Image(systemName: "figure.strengthtraining.traditional")
                                        .font(.system(size: 13))
                                        .foregroundColor(GymTheme.textMuted)
                                    Text(volumeText)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(GymTheme.textPrimary)
                                }

                                HStack(spacing: 6) {
                                    Image(systemName: "trophy")
                                        .font(.system(size: 13))
                                        .foregroundColor(GymTheme.textMuted)
                                    Text(prText)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(GymTheme.textPrimary)
                                }

                                if let w = dayWeight {
                                    HStack(spacing: 6) {
                                        Image(systemName: "scalemass.fill")
                                            .font(.system(size: 13))
                                            .foregroundColor(GymTheme.cyanAccent)
                                        Text(formatWeight(w) + " kg")
                                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                                            .foregroundColor(GymTheme.cyanAccent)
                                    }
                                }

                                Spacer()
                            }
                            .padding(.horizontal, 4)

                            Divider()
                                .background(Color.white.opacity(0.08))

                            // Beteiligte Muskeln & Anatomische Rollen-Heatmap (Agonist, Synergist, Stabilisator, Antagonist visuell auf der Karte)
                            let roles = MuscleStimulusEngine.shared.resolveWorkoutFunctionalRoles(for: session)
                            VStack(alignment: .leading, spacing: 8) {
                                Button {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        isMuscleMapExpanded.toggle()
                                    }
                                    HapticFeedback.light()
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "figure.stand")
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(GymTheme.cyanAccent)

                                        Text("ANATOMISCHE ROLLEN-KARTE (AGONIST • ANTAGONIST • STABI)")
                                            .font(.system(size: 10, weight: .bold))
                                            .tracking(0.8)
                                            .foregroundColor(GymTheme.cyanAccent)

                                        Spacer()

                                        Image(systemName: isMuscleMapExpanded ? "chevron.up" : "chevron.down")
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundColor(GymTheme.textMuted)
                                    }
                                    .padding(10)
                                    .background(GymTheme.surfaceElevated)
                                    .cornerRadius(10)
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(GymTheme.borderSubtle, lineWidth: 1))
                                }
                                .buttonStyle(.plain)

                                if isMuscleMapExpanded {
                                    AnatomicalMuscleMapView(
                                        title: "Biomechanische Rollen-Karte",
                                        isInteractive: true,
                                        primaryZones: Set(roles.agonists),
                                        secondaryZones: Set(roles.synergists),
                                        stabilizerZones: Set(roles.stabilizers),
                                        antagonistZones: Set(roles.antagonists)
                                    )
                                    .padding(.top, 4)
                                }
                            }

                            // Exercise Sections (Image 2 & 3 Exact Layout)
                            VStack(spacing: 20) {
                                ForEach(session.exercises) { exRecord in
                                    exerciseSection(exRecord: exRecord)
                                }
                            }

                            // Somatic / Reha Notes if present
                            if !session.somaticNotes.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("NOTIZEN & SOMATIK")
                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                        .foregroundColor(GymTheme.textMuted)
                                    Text(session.somaticNotes)
                                        .font(.system(size: 12))
                                        .foregroundColor(GymTheme.textSecondary)
                                }
                                .padding(12)
                                .background(GymTheme.surfaceElevated)
                                .cornerRadius(10)
                            }

                            // Delete Workout Button
                            Button(role: .destructive) {
                                showingDeleteConfirmation = true
                                HapticFeedback.light()
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "trash")
                                        .font(.system(size: 13))
                                    Text("Workout aus Kalender und Verlauf loeschen")
                                        .font(.system(size: 13, weight: .semibold))
                                }
                                .foregroundColor(Color.red.opacity(0.85))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(GymTheme.surfaceElevated)
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.red.opacity(0.35), lineWidth: 1))
                            }
                            .buttonStyle(.plain)

                            Spacer(minLength: 40)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 10)
                    }
                }
            }
            .navigationBarHidden(true)
            .confirmationDialog("Workout loeschen", isPresented: $showingDeleteConfirmation) {
                Button("Workout endgueltig loeschen", role: .destructive) {
                    store.deleteSession(id: session.id)
                    dismiss()
                }
                Button("Abbrechen", role: .cancel) {}
            } message: {
                Text("Moechtest du dieses Workout wirklich aus deinem Verlauf und aus dem synchronisierten Google Kalender entfernen?")
            }
            .sheet(isPresented: $showingEditSheet) {
                EditCompletedSessionSheet(session: session) { updated in
                    self.session = updated
                    store.updateSession(updated)
                }
            }
            .sheet(item: $selectedExerciseForDetail) { ex in
                ExerciseDetailSheet(exercise: ex)
                    .environmentObject(store)
            }
        }
    }

    private func roleRow(title: String, zones: [AnatomicalZone], badgeColor: Color, description: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 6) {
                Circle()
                    .fill(badgeColor)
                    .frame(width: 8, height: 8)
                Text(title)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(GymTheme.textPrimary)
                Spacer()
                Text(zones.map { $0.displayName }.joined(separator: " • "))
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundColor(badgeColor)
            }
            Text(description)
                .font(.system(size: 9.5))
                .foregroundColor(GymTheme.textSecondary)
        }
        .padding(8)
        .background(GymTheme.surfaceElevated)
        .cornerRadius(6)
    }

    // MARK: - Exercise Section (Image 2 & 3 Style)
    private func exerciseSection(exRecord: WorkoutExerciseRecord) -> some View {
        let isCardio = exRecord.exercise.targetMuscle == .cardioConditioning || exRecord.exercise.equipment == .treadmill || exRecord.exercise.equipment == .outdoorRunning
        let (prim, sec, stab) = MuscleStimulusEngine.shared.resolveThreeTierZones(for: exRecord.exercise)

        return VStack(alignment: .leading, spacing: 8) {
            // Exercise Header line: Name on left, "1 Rm" or "Tempo" on right
            HStack(alignment: .firstTextBaseline) {
                Button {
                    selectedExerciseForDetail = exRecord.exercise
                    HapticFeedback.light()
                } label: {
                    Text(exRecord.exercise.name)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(GymTheme.textPrimary)
                }
                .buttonStyle(.plain)

                Spacer()

                Text(isCardio ? "Tempo" : "1 Rm")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(GymTheme.textPrimary)
            }

            // Exercise Functional Roles Tag Strip
            HStack(spacing: 6) {
                if !prim.isEmpty {
                    Text("Agonist: \(prim.map { $0.displayName }.joined(separator: ", "))")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Color(red: 0.95, green: 0.22, blue: 0.22))
                }
                if !sec.isEmpty {
                    Text("• Synergist: \(sec.prefix(2).map { $0.displayName }.joined(separator: ", "))")
                        .font(.system(size: 9))
                        .foregroundColor(Color(red: 1.00, green: 0.58, blue: 0.10))
                }
                if !stab.isEmpty {
                    Text("• Stabi: \(stab.prefix(2).map { $0.displayName }.joined(separator: ", "))")
                        .font(.system(size: 9))
                        .foregroundColor(Color(red: 0.08, green: 0.75, blue: 0.52))
                }
            }
            .padding(.bottom, 2)

            // Sets List
            VStack(spacing: 6) {
                ForEach(exRecord.sets) { setRec in
                    setRow(setRec: setRec, isCardio: isCardio)
                }
            }
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Set Row (Image 2 & 3 Style)
    private func setRow(setRec: WorkoutSetRecord, isCardio: Bool) -> some View {
        HStack(alignment: .center, spacing: 10) {
            // Set Indicator: 'W' in orange if warmup, otherwise setNumber
            if setRec.isWarmup {
                Text("W")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(Color(red: 0.95, green: 0.55, blue: 0.20)) // Warm orange
                    .frame(width: 22, alignment: .leading)
            } else {
                Text("\(setRec.setNumber)")
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundColor(GymTheme.textSecondary)
                    .frame(width: 22, alignment: .leading)
            }

            // Weight x Reps or Distance
            if isCardio {
                Text("\(formatDistance(setRec.weightKg)) km")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(GymTheme.textPrimary)
            } else {
                let weightStr = formatWeight(setRec.weightKg)
                HStack(spacing: 5) {
                    if let side = setRec.side, !side.isEmpty {
                        Text(side)
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(GymTheme.cyanAccent)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(GymTheme.cyanAccent.opacity(0.15))
                            .cornerRadius(4)
                    }

                    Text("\(weightStr) kg × \(setRec.reps)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(setRec.isWarmup ? Color(red: 0.95, green: 0.55, blue: 0.20) : GymTheme.textPrimary)

                    if let dur = setRec.executionDurationSeconds, dur > 0 {
                        Text("(\(dur)s)")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(GymTheme.cyanAccent.opacity(0.85))
                    } else if setRec.isTimeBased, let sec = setRec.durationSeconds ?? (setRec.reps > 0 ? setRec.reps : nil) {
                        Text("(\(sec)s)")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(GymTheme.cyanAccent.opacity(0.85))
                    }

                    if let rpe = setRec.rpe {
                        Text(rpe.truncatingRemainder(dividingBy: 1) == 0 ? "@\(Int(rpe))" : String(format: "@%.1f", rpe))
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(Color(red: 1.0, green: 0.65, blue: 0.15))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color(red: 1.0, green: 0.65, blue: 0.15).opacity(0.15))
                            .cornerRadius(4)
                    }
                }
            }

            // Badges: [1RM] [WEIGHT] (Image 2 Style)
            if setRec.isPR {
                HStack(spacing: 4) {
                    badgePill(text: "1RM")
                    badgePill(text: "WEIGHT")
                }
            }

            Spacer()

            // Right: Estimated 1RM or Pace / Tempo
            if isCardio {
                Text("0:00")
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundColor(GymTheme.textSecondary)
            } else {
                let oneRM = setRec.estimated1RM
                Text(oneRM > 0 ? "\(Int(round(oneRM)))" : "-")
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundColor(GymTheme.textSecondary)
            }
        }
        .padding(.vertical, 3)
    }

    private func badgePill(text: String) -> some View {
        HStack(spacing: 2) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 7))
            Text(text)
                .font(.system(size: 8, weight: .black, design: .monospaced))
        }
        .foregroundColor(Color(red: 0.05, green: 0.15, blue: 0.18))
        .padding(.horizontal, 5)
        .padding(.vertical, 2)
        .background(
            Capsule()
                .fill(Color(red: 0.45, green: 0.88, blue: 0.85)) // Cyan badge (Image 2)
        )
    }

    private func formatSessionDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "HH:mm, EEEE, d. MMM. yyyy"
        return formatter.string(from: date)
    }

    private func formatWeight(_ w: Double) -> String {
        w.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(w))" : String(format: "%.1f", w).replacingOccurrences(of: ".", with: ",")
    }

    private func formatDistance(_ d: Double) -> String {
        d.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(d))" : String(format: "%.1f", d).replacingOccurrences(of: ".", with: ",")
    }

    private var exportPDFURL: URL? {
        WorkoutExportService.generateWorkoutPDF(for: session, measuredWeightKg: dayWeight)
    }
}

// MARK: - Edit Completed Session Sheet
public struct EditCompletedSessionSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var sessionTitle: String
    @State private var somaticNotes: String
    @State private var startTime: Date
    @State private var endTime: Date
    private var originalSession: WorkoutSession
    public let onSave: (WorkoutSession) -> Void

    public init(session: WorkoutSession, onSave: @escaping (WorkoutSession) -> Void) {
        self.originalSession = session
        _sessionTitle = State(initialValue: session.title)
        _somaticNotes = State(initialValue: session.somaticNotes)
        _startTime = State(initialValue: session.startTime)
        _endTime = State(initialValue: session.endTime ?? session.startTime.addingTimeInterval(3600))
        self.onSave = onSave
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                GymTheme.bg.ignoresSafeArea()

                Form {
                    Section("Titel & Notizen") {
                        TextField("Workout-Titel", text: $sessionTitle)
                            .foregroundColor(GymTheme.textPrimary)
                        TextField("Notizen", text: $somaticNotes, axis: .vertical)
                            .lineLimit(2...5)
                            .foregroundColor(GymTheme.textPrimary)
                    }
                    .listRowBackground(GymTheme.surfaceElevated)

                    Section("Zeitfenster") {
                        DatePicker("Startzeit", selection: $startTime)
                        DatePicker("Endzeit", selection: $endTime)
                    }
                    .listRowBackground(GymTheme.surfaceElevated)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Workout bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") { dismiss() }
                        .foregroundColor(GymTheme.textSecondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Speichern") {
                        var updated = originalSession
                        updated.title = sessionTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                        updated.somaticNotes = somaticNotes
                        updated.startTime = startTime
                        updated.endTime = endTime
                        onSave(updated)
                        dismiss()
                        HapticFeedback.success()
                    }
                    .font(.headline)
                    .foregroundColor(GymTheme.strongBlue)
                }
            }
        }
    }
}
