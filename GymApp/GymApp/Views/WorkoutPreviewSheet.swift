import SwiftUI

public struct WorkoutPreviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: GymStore

    public let plannedItem: PlannedWorkoutItem?
    public let template: WorkoutTemplate?
    public let onStartWorkout: () -> Void

    @State private var selectedExerciseForDetail: Exercise? = nil
    @State private var isMuscleMapExpanded: Bool = true
    @State private var expandedExerciseIds: Set<UUID> = []
    @State private var showingDeleteConfirmation: Bool = false

    public init(
        plannedItem: PlannedWorkoutItem? = nil,
        template: WorkoutTemplate? = nil,
        onStartWorkout: @escaping () -> Void
    ) {
        self.plannedItem = plannedItem
        self.template = template
        self.onStartWorkout = onStartWorkout
    }

    public struct PreviewExerciseEntry: Identifiable {
        public let id: UUID
        public let exercise: Exercise
        public let targetSets: Int
        public let targetReps: Int
        public let targetSeconds: Int?
        public let isTimeBased: Bool
        public let targetWeightKg: Double
        public let restSeconds: Int

        public var isIsometricOrTimed: Bool {
            isTimeBased || targetSeconds != nil || exercise.isTimeBased || (exercise.isExplicitlyTimeBased == true)
        }

        public var targetSummaryText: String {
            if isIsometricOrTimed {
                let secs = targetSeconds ?? (targetReps > 0 ? targetReps : 10)
                return "\(targetSets) Saetze × \(secs)s Hold"
            } else {
                return "\(targetSets) Saetze × \(targetReps) Wdh."
            }
        }

        public var singleSetTargetText: String {
            if isIsometricOrTimed {
                let secs = targetSeconds ?? (targetReps > 0 ? targetReps : 10)
                return "\(secs)s isometrischer Halt"
            } else {
                return "\(targetReps) Wiederholungen"
            }
        }
    }

    private var workoutTitle: String {
        template?.name ?? plannedItem?.title ?? "Geplantes Workout"
    }

    private var resolvedTemplate: WorkoutTemplate? {
        if let t = template { return t }
        if let p = plannedItem, let tId = p.templateId {
            return store.templates.first(where: { $0.id == tId })
        }
        if let p = plannedItem {
            return store.templates.first(where: { $0.name.caseInsensitiveCompare(p.title) == .orderedSame })
        }
        return nil
    }

    private var exerciseEntries: [PreviewExerciseEntry] {
        if let tmpl = resolvedTemplate {
            return tmpl.items.map { item in
                PreviewExerciseEntry(
                    id: item.id,
                    exercise: item.exercise,
                    targetSets: item.targetSets,
                    targetReps: item.targetReps,
                    targetSeconds: item.targetSeconds,
                    isTimeBased: item.isTimeBased,
                    targetWeightKg: item.targetWeightKg,
                    restSeconds: item.restSeconds
                )
            }
        }
        if let p = plannedItem, !p.exerciseNames.isEmpty {
            return p.exerciseNames.compactMap { name in
                if let ex = store.exercises.first(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) {
                    let isT = ex.isTimeBased || (ex.isExplicitlyTimeBased == true)
                    return PreviewExerciseEntry(
                        id: UUID(),
                        exercise: ex,
                        targetSets: ex.defaultSets,
                        targetReps: ex.defaultReps,
                        targetSeconds: isT ? ex.defaultReps : nil,
                        isTimeBased: isT,
                        targetWeightKg: 0.0,
                        restSeconds: ex.defaultRestSeconds
                    )
                }
                return nil
            }
        }
        // Fallback default exercises
        return store.exercises.prefix(3).map { ex in
            PreviewExerciseEntry(
                id: UUID(),
                exercise: ex,
                targetSets: ex.defaultSets,
                targetReps: ex.defaultReps,
                targetSeconds: nil,
                isTimeBased: false,
                targetWeightKg: 0.0,
                restSeconds: ex.defaultRestSeconds
            )
        }
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                GymTheme.bg.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header Bar (X, Title)
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

                        VStack(spacing: 2) {
                            Text(workoutTitle)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(GymTheme.textPrimary)
                                .lineLimit(1)
                            Text("\(exerciseEntries.count) UEBUNGEN • VORSCHAU")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(GymTheme.strongBlue)
                                .tracking(0.8)
                        }

                        Spacer()

                        Circle()
                            .fill(Color.clear)
                            .frame(width: 34, height: 34)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                    .padding(.bottom, 12)

                    // Exercise List with Sets & Reps
                    ScrollView {
                        VStack(spacing: 12) {
                            // Beteiligte Muskelgruppen (Anatomical Heatmap)
                            let items = exerciseEntries.map { entry in
                                WorkoutTemplateItem(
                                    exercise: entry.exercise,
                                    targetSets: entry.targetSets,
                                    targetReps: entry.targetReps,
                                    targetSeconds: entry.targetSeconds,
                                    isTimeBased: entry.isTimeBased,
                                    targetWeightKg: entry.targetWeightKg,
                                    restSeconds: entry.restSeconds
                                )
                            }
                            let stimulusMap = MuscleStimulusEngine.shared.calculateStimulus(from: items)

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

                                        Text("BETEILIGTE MUSKELN & ANATOMIE")
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
                                    AnatomicalMuscleMapView(stimulusMap: stimulusMap)
                                        .padding(.top, 4)
                                }
                            }

                            // Exercise entries
                            ForEach(exerciseEntries) { entry in
                                exerciseCard(entry: entry)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 24)
                    }

                    // Bottom Action Button: "Workout beginnen"
                    VStack(spacing: 8) {
                        Button {
                            dismiss()
                            onStartWorkout()
                            HapticFeedback.medium()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 14, weight: .bold))
                                Text("Workout beginnen")
                                    .font(.system(size: 15, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(GymTheme.strongBlue)
                            )
                            .shadow(color: GymTheme.strongBlue.opacity(0.35), radius: 8, x: 0, y: 4)
                        }
                        .buttonStyle(.plain)

                        if let planned = plannedItem {
                            Button(role: .destructive) {
                                showingDeleteConfirmation = true
                                HapticFeedback.light()
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "trash")
                                        .font(.system(size: 12))
                                    Text("Aus Kalender entfernen")
                                        .font(.system(size: 13, weight: .semibold))
                                }
                                .foregroundColor(Color.red.opacity(0.85))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(GymTheme.surfaceElevated)
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.red.opacity(0.3), lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                    .padding(.top, 8)
                    .background(GymTheme.bg)
                }
            }
            .navigationBarHidden(true)
            .confirmationDialog("Workout aus Kalender entfernen", isPresented: $showingDeleteConfirmation) {
                if let planned = plannedItem {
                    Button("Aus Kalender loeschen", role: .destructive) {
                        store.removePlannedWorkout(id: planned.id)
                        dismiss()
                    }
                }
                Button("Abbrechen", role: .cancel) {}
            } message: {
                Text("Moechtest du dieses geplante Workout wirklich aus dem Kalender entfernen?")
            }
            .sheet(item: $selectedExerciseForDetail) { exercise in
                ExerciseDetailSheet(exercise: exercise)
                    .environmentObject(store)
            }
        }
    }

    private func exerciseCard(entry: PreviewExerciseEntry) -> some View {
        let isExpanded = expandedExerciseIds.contains(entry.id)

        return VStack(alignment: .leading, spacing: 0) {
            // Main Tappable Card Header
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if isExpanded {
                        expandedExerciseIds.remove(entry.id)
                    } else {
                        expandedExerciseIds.insert(entry.id)
                    }
                }
                HapticFeedback.light()
            } label: {
                HStack(spacing: 12) {
                    // Left: Exercise Thumbnail / Icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color(red: 0.10, green: 0.12, blue: 0.15))
                            .frame(width: 44, height: 44)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(GymTheme.borderSubtle, lineWidth: 1)
                            )

                        Image(systemName: exerciseIconName(for: entry.exercise))
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(entry.exercise.isBWKRehaSafe ? GymTheme.sageGreen : GymTheme.warmSand)
                    }

                    // Center: Exercise Name, Sets × Reps badge, Details
                    VStack(alignment: .leading, spacing: 3) {
                        Text(entry.exercise.name)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(GymTheme.textPrimary)
                            .lineLimit(1)

                        HStack(spacing: 6) {
                            Text(entry.targetSummaryText)
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(GymTheme.strongBlue)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(GymTheme.strongBlue.opacity(0.16))
                                .cornerRadius(4)

                            Text("•")
                                .font(.system(size: 10))
                                .foregroundColor(GymTheme.textMuted)

                            Text(entry.targetWeightKg > 0 ? String(format: "%.1f kg", entry.targetWeightKg) : "0 kg (Bodyweight)")
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundColor(GymTheme.textSecondary)
                        }

                        Text("\(entry.exercise.targetMuscle.rawValue) • Pause: \(entry.restSeconds)s")
                            .font(.system(size: 10.5, weight: .medium))
                            .foregroundColor(GymTheme.textMuted)
                            .lineLimit(1)
                    }

                    Spacer()

                    // Right: Chevron Indicator
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(GymTheme.textMuted)
                        .padding(.trailing, 4)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)

            // Expanded Set-by-Set Breakdown (Revealed on Tap)
            if isExpanded {
                Divider()
                    .background(GymTheme.borderSubtle)
                    .padding(.horizontal, 14)

                VStack(alignment: .leading, spacing: 8) {
                    Text("SAETZE & VORGABEN (\(entry.targetSets) SAETZE)")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(GymTheme.textMuted)
                        .tracking(0.6)

                    ForEach(1...entry.targetSets, id: \.self) { setNum in
                        HStack(spacing: 10) {
                            Text("Satz \(setNum)")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(GymTheme.textSecondary)
                                .frame(width: 50, alignment: .leading)

                            Text(entry.singleSetTargetText)
                                .font(.system(size: 11.5, weight: .semibold))
                                .foregroundColor(GymTheme.textPrimary)

                            Spacer()

                            Text(entry.targetWeightKg > 0 ? String(format: "%.1f kg", entry.targetWeightKg) : "0 kg")
                                .font(.system(size: 10.5, weight: .medium, design: .monospaced))
                                .foregroundColor(GymTheme.textMuted)

                            Text("•  \(entry.restSeconds)s Pause")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(GymTheme.textMuted)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(GymTheme.surfaceElevated.opacity(0.5))
                        .cornerRadius(6)
                    }

                    if !entry.exercise.executionNotes.isEmpty {
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "info.circle")
                                .font(.system(size: 11))
                                .foregroundColor(GymTheme.warmSand)
                            Text(entry.exercise.executionNotes)
                                .font(.system(size: 10.5))
                                .foregroundColor(GymTheme.textSecondary)
                                .lineLimit(3)
                        }
                        .padding(.top, 2)
                    }

                    Button {
                        selectedExerciseForDetail = entry.exercise
                        HapticFeedback.light()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "books.vertical.fill")
                                .font(.system(size: 10))
                            Text("Uebungsanleitung & Video im Katalog")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .foregroundColor(GymTheme.strongBlue)
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 14)
                .padding(.top, 10)
                .padding(.bottom, 12)
                .transition(.opacity)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(red: 0.12, green: 0.14, blue: 0.18))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    private func exerciseIconName(for ex: Exercise) -> String {
        switch ex.targetMuscle {
        case .chest: return "figure.strengthtraining.traditional"
        case .back, .lowerBack: return "figure.rower"
        case .shoulders: return "figure.arms.open"
        case .legs, .glutesPosterior: return "figure.walk"
        case .arms: return "dumbbell.fill"
        case .functionalCore: return "figure.core.training"
        case .cardioConditioning: return "figure.run"
        case .mobilityFlexibility: return "figure.flexibility"
        }
    }
}
