import SwiftUI
import Combine

public struct ActiveWorkoutView: View {
    @EnvironmentObject private var store: GymStore
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var timerManager = WorkoutRestTimerManager.shared


    // Sheets & Dialogs
    @State private var showingFinishSheet = false
    @State private var showingMissingRPESheet = false
    @State private var showingAddExerciseSheet = false
    @State private var showingCancelAlert = false
    @State private var showingMuscleMap = false
    @State private var isInlineMuscleMapExpanded = false

    // Screenshot 1 Features (Workout Title Menu)
    @State private var showingEditTitleDialog = false
    @State private var editingWorkoutTitle = ""
    @State private var showingAdjustTimeSheet = false
    @State private var adjustedStartTime = Date()
    @State private var showingWorkoutNotesSheet = false
    @State private var workoutSomaticNotes = ""

    // Screenshot 2 Features (Edit Exercise Sheet)
    @State private var exerciseToEdit: Exercise? = nil
    @State private var exerciseForDetail: Exercise? = nil
    @State private var exerciseForCoach: Exercise? = nil
    @State private var exerciseRecordIdForCoach: UUID? = nil
    @State private var activeTimedSet: TimedSetContext? = nil

    @State private var somaticNotes: String = ""

    @State private var exerciseRecordToReplace: UUID? = nil
    @State private var showingReplaceExerciseSheet = false
    @State private var showingPlateCalculator = false
    @State private var plateCalculatorWeight: Double = 60.0
    @State private var expandedPlateDrawers: Set<UUID> = []
    @State private var manuallyEnabledWeightExercises: Set<UUID> = []

    public var body: some View {
        NavigationStack {
            ZStack {
                GymTheme.bg.ignoresSafeArea()

                if let session = store.activeSession {
                    VStack(spacing: 0) {
                        // Top Navigation Header
                        topHeaderBar

                        // Non-modal Floating Rest-Timer HUD (Automatischer Start, taktile Signale bei 30s & 0s)
                        if timerManager.isRunning {
                            activeRestTimerFloatingHUD(session: session)
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        ScrollViewReader { proxy in
                            ScrollView {
                                VStack(alignment: .leading, spacing: 18) {
                                    // Session Header (Title with Action Menu, Date, Live Elapsed Timer)
                                    sessionTitleAndLiveTimer(session: session)

                                    // Active Workout Muscle Map (All Involved Muscles)
                                    activeWorkoutMuscleMapCard(session: session)

                                    // Exercise Execution Cards
                                    ForEach(session.exercises) { exRecord in
                                        exerciseCard(exRecord: exRecord)
                                            .id(exRecord.id)
                                    }

                                    // Bottom Action Buttons
                                    bottomActionButtons

                                    Spacer(minLength: 40)
                                }
                                .padding(.horizontal, 16)
                                .padding(.top, 10)
                                .frame(maxWidth: 720)
                                .frame(maxWidth: .infinity)
                            }
                            .scrollDismissesKeyboard(.interactively)
                            .dismissKeyboardOnSwipeDown()
                            .onChange(of: store.activeSupersetTargetExerciseId) { newTargetId in
                                if let targetId = newTargetId {
                                    withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                                        proxy.scrollTo(targetId, anchor: .top)
                                    }
                                }
                            }
                        }
                    }
                } else {
                    VStack(spacing: 16) {
                        Text("Keine aktive Einheit")
                            .font(.headline)
                            .foregroundColor(GymTheme.textMuted)
                        Button("Schliessen") { dismiss() }
                            .font(.subheadline)
                            .foregroundColor(GymTheme.sageGreen)
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                if let session = store.activeSession {
                    self.editingWorkoutTitle = session.title
                    self.adjustedStartTime = session.startTime
                    self.workoutSomaticNotes = session.somaticNotes
                }
            }
            .confirmationDialog(
                "Moechtest du dieses Workout beenden oder abbrechen?",
                isPresented: $showingCancelAlert,
                titleVisibility: .visible
            ) {
                Button("1-Tap Exit-Skalar waehlen", role: .none) {
                    attemptFinishWorkout()
                }
                Button("Sofort verwerfen (Zero-Touch)", role: .destructive) {
                    store.cancelWorkout()
                    dismiss()
                }
                Button("Weiter trainieren", role: .cancel) {}
            }
            // Feature 1: Name des Workouts bearbeiten Dialog
            .alert("Name des Workouts bearbeiten", isPresented: $showingEditTitleDialog) {
                TextField("Workout-Titel", text: $editingWorkoutTitle)
                Button("Speichern") {
                    store.updateActiveWorkoutTitle(editingWorkoutTitle)
                }
                Button("Abbrechen", role: .cancel) {}
            }
            // Feature 2: Start-/Endzeit anpassen Sheet
            .sheet(isPresented: $showingAdjustTimeSheet) {
                adjustTimeSheet
            }
            // Feature 4: Notiz hinzufuegen Sheet
            .sheet(isPresented: $showingWorkoutNotesSheet) {
                workoutNotesSheet
            }
            // Screenshot 2 Feature: Uebung bearbeiten Sheet
            .sheet(item: $exerciseToEdit) { ex in
                EditExerciseSheet(exercise: ex)
                    .environmentObject(store)
            }
            .sheet(item: $exerciseForDetail) { ex in
                ExerciseDetailSheet(exercise: ex)
                    .environmentObject(store)
            }
            .sheet(isPresented: $showingFinishSheet) {
                WorkoutExitScalarSheet()
                    .environmentObject(store)
            }
            .sheet(isPresented: $showingMissingRPESheet) {
                WorkoutMissingRPESheet(
                    onAllRated: {
                        showingMissingRPESheet = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            showingFinishSheet = true
                        }
                    }
                )
                .environmentObject(store)
            }
            .sheet(isPresented: $showingAddExerciseSheet) {
                AddExerciseToSessionSheet { exercise in
                    store.addExerciseToActiveWorkout(exercise)
                }
                .environmentObject(store)
            }
            .sheet(isPresented: $showingReplaceExerciseSheet) {
                AddExerciseToSessionSheet(title: "Uebung ersetzen") { replacement in
                    if let recId = exerciseRecordToReplace {
                        store.replaceExerciseInActiveWorkout(exerciseRecordId: recId, with: replacement)
                        exerciseRecordToReplace = nil
                    }
                }
                .environmentObject(store)
            }
            .sheet(isPresented: $showingPlateCalculator) {
                PlateCalculatorSheet(initialWeightKg: plateCalculatorWeight)
            }
            .sheet(isPresented: $showingMuscleMap) {
                if let session = store.activeSession {
                    NavigationStack {
                        ZStack {
                            GymTheme.bg.ignoresSafeArea()
                            ScrollView {
                                VStack(alignment: .leading, spacing: 16) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(session.title)
                                            .font(.title3)
                                            .fontWeight(.bold)
                                            .foregroundColor(GymTheme.textPrimary)
                                        Text("Aktive Muskelbelastung gemaess absolvierter Saetze")
                                            .font(.caption)
                                            .foregroundColor(GymTheme.textSecondary)
                                    }
                                    .padding(.horizontal)
                                    .padding(.top, 8)

                                    let stimulusMap = MuscleStimulusEngine.shared.calculateStimulus(for: session)
                                    AnatomicalMuscleMapView(stimulusMap: stimulusMap)
                                        .padding(.horizontal)

                                    Spacer(minLength: 30)
                                }
                            }
                        }
                        .navigationTitle("Muskel-Heatmap")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("Fertig") {
                                    showingMuscleMap = false
                                }
                                .foregroundColor(GymTheme.sageGreen)
                            }
                        }
                    }
                }
            }
            .sheet(item: $exerciseForCoach) { ex in
                OlympicCoachView(exercise: ex) { prescribedWeight, prescribedReps, prescribedSets in
                    if let recId = exerciseRecordIdForCoach,
                       let session = store.activeSession,
                       let record = session.exercises.first(where: { $0.id == recId }) {
                        for setItem in record.sets where !setItem.isCompleted {
                            store.updateSet(exerciseId: recId, setId: setItem.id, weightKg: prescribedWeight, reps: prescribedReps)
                        }
                    }
                }
            }
            .sheet(item: $activeTimedSet) { ctx in
                TimedExerciseCountdownSheet(context: ctx) { completedSec in
                    store.updateSetDuration(exerciseId: ctx.exerciseId, setId: ctx.setId, seconds: completedSec)
                    if let session = store.activeSession,
                       let ex = session.exercises.first(where: { $0.id == ctx.exerciseId }),
                       let targetSet = ex.sets.first(where: { $0.id == ctx.setId }),
                       !targetSet.isCompleted {
                        store.toggleSet(exerciseId: ctx.exerciseId, setId: ctx.setId)
                    }
                }
            }
            .onChange(of: store.activeSession) { _, newSession in
                if newSession == nil {
                    dismiss()
                }
            }
            .onAppear {
                if store.activeSession == nil {
                    dismiss()
                }
            }
        }
    }

    // MARK: - Top Header Bar
    private var topHeaderBar: some View {
        HStack {
            // Stopwatch button
            Button {
                if store.isRestTimerRunning {
                    store.stopRestTimer()
                } else {
                    store.startRestTimer(seconds: 120)
                }
                HapticFeedback.light()
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(GymTheme.surfaceElevated)
                        .frame(width: 38, height: 38)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(GymTheme.border, lineWidth: 1)
                        )
                    Image(systemName: "stopwatch")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(store.isRestTimerRunning ? GymTheme.sageGreen : GymTheme.textSecondary)
                }
            }

            // Muscle Heatmap Button
            Button {
                showingMuscleMap = true
                HapticFeedback.light()
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(GymTheme.surfaceElevated)
                        .frame(width: 38, height: 38)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(GymTheme.border, lineWidth: 1)
                        )
                    Image(systemName: "figure.cross.training")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(GymTheme.sageGreen)
                }
            }

            // Pause / Resume Workout Button
            if let active = store.activeSession {
                Button {
                    store.toggleActiveWorkoutPause()
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(active.isPaused ? GymTheme.warningAmber.opacity(0.18) : GymTheme.surfaceElevated)
                            .frame(width: 38, height: 38)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(active.isPaused ? GymTheme.warningAmber : GymTheme.border, lineWidth: 1)
                            )
                        Image(systemName: active.isPaused ? "play.fill" : "pause.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(active.isPaused ? GymTheme.warningAmber : GymTheme.textSecondary)
                    }
                }
            }

            Spacer()

            // Sheet Grabber
            RoundedRectangle(cornerRadius: 2.5)
                .fill(GymTheme.borderFocused)
                .frame(width: 38, height: 5)

            Spacer()

            // Green Finish Button
            Button {
                attemptFinishWorkout()
            } label: {
                Text("Beenden")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(GymTheme.bg)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 8)
                    .background(GymTheme.finishGreen)
                    .cornerRadius(8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 6)
    }

    // MARK: - Session Title and Live Ticking Timer (Screenshot 1 Features)
    private func sessionTitleAndLiveTimer(session: WorkoutSession) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text(session.title)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(GymTheme.textPrimary)

                // Menu matching Screenshot 1 exactly
                Menu {
                    Button {
                        editingWorkoutTitle = session.title
                        showingEditTitleDialog = true
                    } label: {
                        Label("Name des Workouts bearbeiten", systemImage: "pencil")
                    }

                    Button {
                        adjustedStartTime = session.startTime
                        showingAdjustTimeSheet = true
                    } label: {
                        Label("Start-/Endzeit anpassen", systemImage: "clock.arrow.circlepath")
                    }

                    Button {
                        workoutSomaticNotes = session.somaticNotes
                        showingWorkoutNotesSheet = true
                    } label: {
                        Label("Notiz hinzufuegen", systemImage: "doc.text")
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(GymTheme.surfaceElevated)
                            .frame(width: 28, height: 28)
                            .overlay(
                                Circle().stroke(GymTheme.border, lineWidth: 1)
                            )
                        Image(systemName: "ellipsis")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(GymTheme.sageGreen)
                    }
                }
            }

            // Date row
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .font(.system(size: 12))
                    .foregroundColor(GymTheme.textMuted)
                Text(formattedDate(session.startTime))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(GymTheme.textSecondary)
            }

            // Live Timer Row (with pause and resume controls)
            LiveWorkoutElapsedView(session: session) {
                store.toggleActiveWorkoutPause()
            }

            // High-visibility paused notification banner
            if session.isPaused {
                HStack(spacing: 10) {
                    Image(systemName: "pause.circle.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(GymTheme.warningAmber)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Workout pausiert")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(GymTheme.warningAmber)
                        Text("Trainingszeit angehalten. Bereit fuer die naechste Runde.")
                            .font(.system(size: 11))
                            .foregroundColor(GymTheme.textSecondary)
                    }
                    Spacer()
                    Button {
                        store.resumeActiveWorkout()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 11, weight: .bold))
                            Text("Fortsetzen")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .foregroundColor(GymTheme.bg)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(GymTheme.finishGreen)
                        .cornerRadius(6)
                    }
                }
                .padding(10)
                .background(GymTheme.warningAmber.opacity(0.12))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(GymTheme.warningAmber.opacity(0.5), lineWidth: 1)
                )
                .padding(.top, 4)
            }
        }
        .padding(.top, 4)
    }

    private static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter
    }()

    private func formattedDate(_ date: Date) -> String {
        return Self.shortDateFormatter.string(from: date)
    }

    // MARK: - Non-Modal Rest Timer Floating HUD
    private func activeRestTimerFloatingHUD(session: WorkoutSession) -> some View {
        let minutes = timerManager.secondsRemaining / 60
        let seconds = timerManager.secondsRemaining % 60
        let timeString = String(format: "%02d:%02d", minutes, seconds)
        let nextUp = nextUpcomingSet(in: session)

        return VStack(spacing: 8) {
            HStack(alignment: .center, spacing: 12) {
                // Timer digits
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text(timeString)
                        .font(.system(size: 26, weight: .black, design: .monospaced))
                        .foregroundColor(timerManager.secondsRemaining <= 10 ? GymTheme.accentGold : GymTheme.textPrimary)
                    Text("PAUSE")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(GymTheme.textMuted)
                }

                Divider()
                    .frame(height: 24)
                    .background(GymTheme.borderSubtle)

                // Info (Superset target or next set)
                VStack(alignment: .leading, spacing: 2) {
                    if let note = timerManager.supersetNote {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 10))
                                .foregroundColor(Color(red: 0.35, green: 0.75, blue: 1.0))
                            Text(note)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Color(red: 0.35, green: 0.75, blue: 1.0))
                                .lineLimit(1)
                        }
                    } else if let next = nextUp {
                        Text("FOLGEND: \(next.exerciseName.uppercased())")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(GymTheme.sageGreen)
                            .lineLimit(1)
                        Text("Satz \(next.setIndex)/\(next.totalSets) • \(next.targetWeight > 0 ? "\(String(format: "%.1f", next.targetWeight)) kg" : "BW") × \(next.targetReps)")
                            .font(.system(size: 10))
                            .foregroundColor(GymTheme.textSecondary)
                    } else {
                        Text("ALLE SÄTZE VOLLSTÄNDIG")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(GymTheme.finishGreen)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Quick Adjust
                HStack(spacing: 4) {
                    Button {
                        store.adjustRestTimer(deltaSeconds: -15)
                    } label: {
                        Text("-15s")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(GymTheme.surfaceElevated)
                            .foregroundColor(GymTheme.textSecondary)
                            .cornerRadius(5)
                    }

                    Button {
                        store.adjustRestTimer(deltaSeconds: 15)
                    } label: {
                        Text("+15s")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(GymTheme.surfaceElevated)
                            .foregroundColor(Color(red: 0.35, green: 0.75, blue: 1.0))
                            .cornerRadius(5)
                    }
                }

                // Stop Rest Button
                Button {
                    store.stopRestTimer(playBell: true)
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(GymTheme.bg)
                        .padding(8)
                        .background(GymTheme.finishGreen)
                        .clipShape(Circle())
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(GymTheme.surface)
        .overlay(Rectangle().frame(height: 1).foregroundColor(GymTheme.borderSubtle), alignment: .bottom)
    }

    // MARK: - Integrated Barbell Sleeve Drawer (No sheet switch needed)
    private func inlineSleeveDrawer(exRecord: WorkoutExerciseRecord) -> some View {
        let currentWeight = exRecord.sets.last(where: { $0.weightKg > 0 })?.weightKg ?? exRecord.sets.first?.weightKg ?? 20.0
        let breakdown = PlateCalculatorEngine.calculate(targetWeightKg: currentWeight, barbellWeightKg: 20.0)

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "circle.grid.cross.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Color(red: 0.35, green: 0.75, blue: 1.0))
                    Text("HANTELSCHEIBEN-LEISTE (LANGHANTEL 20 KG)")
                        .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                        .foregroundColor(GymTheme.textSecondary)
                }

                Spacer()

                Text("Ziel: \(String(format: "%.1f", currentWeight)) kg")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(Color(red: 0.35, green: 0.75, blue: 1.0))
            }

            // Visual plate arrangement per side
            HStack(spacing: 6) {
                Text("PRO SEITE:")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(GymTheme.textMuted)

                if breakdown.platesPerSide.isEmpty {
                    Text("Nur leere Stange (20 kg)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(GymTheme.textSecondary)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 5) {
                            ForEach(breakdown.platesPerSide) { plate in
                                HStack(spacing: 2) {
                                    Text("\(plate.countPerSide)×")
                                        .font(.system(size: 10, weight: .bold))
                                    Text("\(plate.weightKg.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(plate.weightKg))" : String(format: "%.1f", plate.weightKg)) kg")
                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                }
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(plate.color)
                                .foregroundColor(plate.labelColor)
                                .cornerRadius(4)
                            }
                        }
                    }
                }
            }

            // Quick micro adjustments (+/- 2.5kg, +/- 5kg) for last set
            HStack(spacing: 6) {
                Text("Schnellanpassung:")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(GymTheme.textMuted)

                Button("-5 kg") {
                    if let lastSet = exRecord.sets.last {
                        let newWeight = max(20.0, lastSet.weightKg - 5.0)
                        store.updateSetWeight(exerciseId: exRecord.id, setId: lastSet.id, weight: newWeight)
                    }
                }
                .buttonStyle(.plain)
                .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(GymTheme.surfaceElevated)
                .foregroundColor(GymTheme.textSecondary)
                .cornerRadius(4)

                Button("-2.5 kg") {
                    if let lastSet = exRecord.sets.last {
                        let newWeight = max(20.0, lastSet.weightKg - 2.5)
                        store.updateSetWeight(exerciseId: exRecord.id, setId: lastSet.id, weight: newWeight)
                    }
                }
                .buttonStyle(.plain)
                .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(GymTheme.surfaceElevated)
                .foregroundColor(GymTheme.textSecondary)
                .cornerRadius(4)

                Button("+2.5 kg") {
                    if let lastSet = exRecord.sets.last {
                        let newWeight = lastSet.weightKg + 2.5
                        store.updateSetWeight(exerciseId: exRecord.id, setId: lastSet.id, weight: newWeight)
                    }
                }
                .buttonStyle(.plain)
                .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(GymTheme.surfaceElevated)
                .foregroundColor(GymTheme.sageGreen)
                .cornerRadius(4)

                Button("+5 kg") {
                    if let lastSet = exRecord.sets.last {
                        let newWeight = lastSet.weightKg + 5.0
                        store.updateSetWeight(exerciseId: exRecord.id, setId: lastSet.id, weight: newWeight)
                    }
                }
                .buttonStyle(.plain)
                .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(GymTheme.surfaceElevated)
                .foregroundColor(GymTheme.sageGreen)
                .cornerRadius(4)
            }
        }
        .padding(10)
        .background(GymTheme.surfaceElevated.opacity(0.8))
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(red: 0.35, green: 0.75, blue: 1.0).opacity(0.4), lineWidth: 1))
    }


    private func nextUpcomingSet(in session: WorkoutSession) -> (exerciseName: String, setIndex: Int, totalSets: Int, targetWeight: Double, targetReps: Int)? {
        for exRecord in session.exercises {
            if let uncompletedIdx = exRecord.sets.firstIndex(where: { !$0.isCompleted }) {
                let set = exRecord.sets[uncompletedIdx]
                return (
                    exerciseName: exRecord.exercise.name,
                    setIndex: uncompletedIdx + 1,
                    totalSets: exRecord.sets.count,
                    targetWeight: set.weightKg,
                    targetReps: set.reps
                )
            }
        }
        return nil
    }

    // MARK: - Exercise Card
    private func exerciseCard(exRecord: WorkoutExerciseRecord) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Exercise Header (Tappable Title opens ExerciseDetailSheet from Katalog)
            HStack(spacing: 8) {
                Button {
                    let resolved = store.exercises.first(where: { $0.id == exRecord.exercise.id || $0.name.caseInsensitiveCompare(exRecord.exercise.name) == .orderedSame }) ?? exRecord.exercise
                    exerciseForDetail = resolved
                    HapticFeedback.light()
                } label: {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text(exRecord.exercise.name)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(GymTheme.warmSand)

                            if let group = exRecord.supersetGroupId {
                                HStack(spacing: 3) {
                                    Image(systemName: "link")
                                        .font(.system(size: 8, weight: .bold))
                                    Text("SUPERSATZ \(group)")
                                        .font(.system(size: 9, weight: .black, design: .monospaced))
                                }
                                .foregroundColor(Color(red: 0.35, green: 0.75, blue: 1.0))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(red: 0.15, green: 0.35, blue: 0.60).opacity(0.3))
                                .cornerRadius(4)
                            }

                            Image(systemName: "info.circle")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(GymTheme.textMuted)
                        }

                        Text("\(exRecord.exercise.targetMuscle.rawValue) • \(exRecord.exercise.equipment.rawValue)")
                            .font(.system(size: 11))
                            .foregroundColor(GymTheme.textSecondary)
                    }
                }
                .buttonStyle(.plain)

                Spacer()

                // Plate Calculator Quick Access (Toggles Inline Sleeve Drawer)
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        if expandedPlateDrawers.contains(exRecord.id) {
                            expandedPlateDrawers.remove(exRecord.id)
                        } else {
                            expandedPlateDrawers.insert(exRecord.id)
                        }
                    }
                    HapticFeedback.light()
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(expandedPlateDrawers.contains(exRecord.id) ? Color(red: 0.15, green: 0.35, blue: 0.60).opacity(0.35) : GymTheme.surfaceElevated)
                            .frame(width: 32, height: 32)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(expandedPlateDrawers.contains(exRecord.id) ? Color(red: 0.35, green: 0.75, blue: 1.0) : GymTheme.border, lineWidth: 1)
                            )
                        Image(systemName: "circle.grid.cross")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(red: 0.35, green: 0.75, blue: 1.0))
                    }
                }

                // Exercise Action Menu (Includes Screenshot 2 "Uebung bearbeiten"!)
                Menu {
                    Button {
                        exerciseToEdit = exRecord.exercise
                    } label: {
                        Label("Uebung bearbeiten", systemImage: "slider.horizontal.3")
                    }

                    Button {
                        plateCalculatorWeight = exRecord.sets.last?.weightKg ?? 60.0
                        showingPlateCalculator = true
                        HapticFeedback.light()
                    } label: {
                        Label("Scheibenrechner (Plates)", systemImage: "circle.grid.cross")
                    }

                    Button {
                        showingWorkoutNotesSheet = true
                    } label: {
                        Label("Notiz hinzufuegen", systemImage: "doc.text")
                    }

                    Button {
                        exerciseRecordIdForCoach = exRecord.id
                        exerciseForCoach = exRecord.exercise
                        HapticFeedback.light()
                    } label: {
                        Label("Olympic Coach (Last & Reps)", systemImage: "cpu")
                    }

                    Button {
                        store.startRestTimer(seconds: exRecord.exercise.dynamicRestSeconds)
                    } label: {
                        Label("Ruhezeiten aktualisieren", systemImage: "arrow.clockwise")
                    }

                    Button {
                        exerciseRecordToReplace = exRecord.id
                        showingReplaceExerciseSheet = true
                        HapticFeedback.light()
                    } label: {
                        Label("Uebung ersetzen", systemImage: "arrow.triangle.2.circlepath")
                    }

                    Button {
                        store.toggleSuperset(for: exRecord.id)
                    } label: {
                        if exRecord.supersetGroupId != nil {
                            Label("Supersatz aufloesen", systemImage: "rectangle.stack.badge.minus")
                        } else {
                            Label("Supersatz verbinden", systemImage: "rectangle.stack.badge.plus")
                        }
                    }

                    let currentShowsWeight = exRecord.sets.contains(where: { $0.weightKg > 0 }) || manuallyEnabledWeightExercises.contains(exRecord.id)
                    Button {
                        if manuallyEnabledWeightExercises.contains(exRecord.id) {
                            manuallyEnabledWeightExercises.remove(exRecord.id)
                        } else {
                            manuallyEnabledWeightExercises.insert(exRecord.id)
                        }
                        HapticFeedback.light()
                    } label: {
                        Label(currentShowsWeight ? "Gewichtsspalte ausblenden" : "Gewichtsspalte einblenden (+kg)", systemImage: "scalemass")
                    }

                    Divider()

                    Button(role: .destructive) {
                        store.removeExerciseFromActiveWorkout(exerciseId: exRecord.id)
                    } label: {
                        Label("Uebung loeschen", systemImage: "xmark")
                    }
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(GymTheme.surfaceElevated)
                            .frame(width: 32, height: 32)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(GymTheme.border, lineWidth: 1)
                            )
                        Image(systemName: "ellipsis")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(GymTheme.sageGreen)
                    }
                }
            }

            // Inline Sleeve-Drawer (Einklappbare Hantelscheiben-Leiste ohne Sheet-Wechsel)
            if expandedPlateDrawers.contains(exRecord.id) {
                inlineSleeveDrawer(exRecord: exRecord)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            // Auto-Progression Engine (RPE-basiert: +2,5 kg bei RPE <= 8, Gewicht halten bei RPE 10)
            if let reco = AutoProgressionEngine.evaluateProgression(exerciseId: exRecord.id, exerciseName: exRecord.exercise.name, sets: exRecord.sets) {
                HStack(spacing: 6) {
                    Image(systemName: reco.isProgressionAvailable ? "arrow.up.right.circle.fill" : "equal.circle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(reco.isProgressionAvailable ? GymTheme.finishGreen : GymTheme.accentGold)

                    Text(reco.actionBadge.uppercased())
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                        .foregroundColor(reco.isProgressionAvailable ? GymTheme.finishGreen : GymTheme.accentGold)

                    Text("•")
                        .foregroundColor(GymTheme.textMuted)

                    Text(reco.rationale)
                        .font(.system(size: 10))
                        .foregroundColor(GymTheme.textSecondary)
                        .lineLimit(1)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(GymTheme.surfaceElevated)
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(reco.isProgressionAvailable ? GymTheme.finishGreen.opacity(0.4) : GymTheme.accentGold.opacity(0.4), lineWidth: 1)
                )
            }

            // Table Columns Header
            let isTimeEx = exRecord.exercise.isTimeBased || exRecord.sets.contains(where: { $0.isTimeBased })
            let showsWeight = exRecord.sets.contains(where: { $0.weightKg > 0 }) || manuallyEnabledWeightExercises.contains(exRecord.id)
            HStack(spacing: 8) {
                Text("Set")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(GymTheme.textSecondary)
                    .frame(width: exRecord.exercise.isUnilateral ? 58 : 36, alignment: .leading)

                if showsWeight {
                    Text("+kg")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(GymTheme.textSecondary)
                        .frame(width: 74, alignment: .center)
                }

                Text(isTimeEx ? "Dauer" : "Wiederh.")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(GymTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)

                Text("RPE")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(GymTheme.textSecondary)
                    .frame(width: 42, alignment: .center)

                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(GymTheme.textSecondary)
                    .frame(width: 36, alignment: .center)

                Image(systemName: "trash")
                    .font(.system(size: 10))
                    .foregroundColor(Color.clear)
                    .frame(width: 24, alignment: .center)
            }
            .padding(.top, 2)

            // Set Rows
            VStack(spacing: 8) {
                ForEach(exRecord.sets) { setRec in
                    setRow(exerciseId: exRecord.id, setRec: setRec)
                }
            }

            // Rest Indicator Line
            HStack {
                Rectangle()
                    .fill(GymTheme.border)
                    .frame(height: 1)

                Text(formatRestDuration(exRecord.exercise.defaultRestSeconds))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(GymTheme.sageGreen)
                    .padding(.horizontal, 8)

                Rectangle()
                    .fill(GymTheme.border)
                    .frame(height: 1)
            }
            .padding(.vertical, 4)

            // Action Buttons: Warmup-Engine + Set
            HStack(spacing: 8) {
                Button {
                    store.autoGenerateWarmupSets(for: exRecord.id)
                    HapticFeedback.light()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 11))
                        Text("Warmup-Sätze")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(GymTheme.accentGold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(GymTheme.surfaceElevated)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(GymTheme.accentGold.opacity(0.35), lineWidth: 1)
                    )
                }

                Button {
                    store.addSet(to: exRecord.id)
                    HapticFeedback.light()
                } label: {
                    Text("+ Set (\(formatRestDuration(exRecord.exercise.defaultRestSeconds)))")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(GymTheme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(GymTheme.surfaceElevated)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(GymTheme.border, lineWidth: 1)
                        )
                }
            }
        }
        .somaCard()
    }

    private func formatRestDuration(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }

    private func formatDuration(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        if mins > 0 {
            return String(format: "%d:%02d min", mins, secs)
        } else {
            return "\(secs)s"
        }
    }

    // MARK: - Active Workout Muscle Map Card (All Involved Muscles)
    private func activeWorkoutMuscleMapCard(session: WorkoutSession) -> some View {
        let stimulusMap = MuscleStimulusEngine.shared.calculateStimulus(for: session)
        let activeMuscles = session.exercises.map { $0.exercise.targetMuscle.rawValue }
        let uniqueMuscles = Array(Set(activeMuscles))

        return VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isInlineMuscleMapExpanded.toggle()
                }
                HapticFeedback.light()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "figure.stand")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(GymTheme.cyanAccent)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("BETEILIGTE MUSKELN & ANATOMIE")
                            .font(.system(size: 9, weight: .bold))
                            .tracking(0.8)
                            .foregroundColor(GymTheme.cyanAccent)
                        Text(uniqueMuscles.isEmpty ? "Noch keine Uebungen" : uniqueMuscles.joined(separator: " • "))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(GymTheme.textSecondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    Image(systemName: isInlineMuscleMapExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(GymTheme.textMuted)
                }
                .padding(10)
                .background(GymTheme.surfaceElevated)
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(GymTheme.borderSubtle, lineWidth: 1))
            }
            .buttonStyle(.plain)

            if isInlineMuscleMapExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    AnatomicalMuscleMapView(stimulusMap: stimulusMap)
                        .padding(.top, 4)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - Set Row
    private func setRow(exerciseId: UUID, setRec: WorkoutSetRecord) -> some View {
        let currentExercise = store.activeSession?.exercises.first(where: { $0.id == exerciseId })
        let exName = currentExercise?.exercise.name ?? ""
        let setIndex = currentExercise?.sets.firstIndex(where: { $0.id == setRec.id }) ?? (setRec.setNumber - 1)
        let prev = store.previousPerformance(for: exName, setIndex: setIndex)
        let isTimeBased = setRec.isTimeBased || (currentExercise?.exercise.isTimeBased ?? false)

        return HStack(spacing: 8) {
            // Set Number pill with Menu for deleting sets and toggling mode
            HStack(spacing: 4) {
                Menu {
                    Button(role: .destructive) {
                        store.deleteSet(exerciseId: exerciseId, setId: setRec.id)
                        HapticFeedback.light()
                    } label: {
                        Label("Satz loeschen", systemImage: "trash")
                    }

                    Button {
                        store.toggleSetIsTimeBased(exerciseId: exerciseId, setId: setRec.id)
                        HapticFeedback.light()
                    } label: {
                        Label(isTimeBased ? "Auf Wiederholungen wechseln" : "Auf Zeit/Dauer wechseln (Plank)", systemImage: "stopwatch")
                    }
                } label: {
                    ZStack {
                        if setRec.isWarmup {
                            Text("W")
                                .font(.system(size: 11, weight: .black, design: .monospaced))
                                .foregroundColor(GymTheme.accentGold)
                                .frame(width: 32, height: 32)
                                .background(GymTheme.accentGold.opacity(0.18))
                                .cornerRadius(6)
                                .overlay(RoundedRectangle(cornerRadius: 6).stroke(GymTheme.accentGold.opacity(0.4), lineWidth: 1))
                        } else if setRec.isPR {
                            VStack(spacing: 1) {
                                Text("PR")
                                    .font(.system(size: 8, weight: .black, design: .monospaced))
                                    .foregroundColor(GymTheme.accentGold)
                                Text("\(setRec.setNumber)")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(GymTheme.textPrimary)
                            }
                            .frame(width: 32, height: 32)
                            .background(GymTheme.accentGold.opacity(0.15))
                            .cornerRadius(6)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(GymTheme.accentGold, lineWidth: 1.2))
                        } else {
                            VStack(spacing: 1) {
                                Text("\(setRec.setNumber)")
                                    .font(.system(size: setRec.isCompleted && (setRec.executionDurationSeconds ?? 0) > 0 ? 11 : 12, weight: .bold))
                                    .foregroundColor(GymTheme.textPrimary)
                                if setRec.isCompleted, let dur = setRec.executionDurationSeconds, dur > 0 {
                                    Text("\(dur)s")
                                        .font(.system(size: 7.5, weight: .semibold, design: .monospaced))
                                        .foregroundColor(GymTheme.cyanAccent)
                                }
                            }
                            .frame(width: 32, height: 32)
                            .background(GymTheme.surfaceElevated)
                            .cornerRadius(6)
                        }
                    }
                }
                .buttonStyle(.plain)

                if currentExercise?.exercise.isUnilateral == true {
                    Button {
                        let cur = setRec.side ?? (setRec.setNumber % 2 == 1 ? "links" : "rechts")
                        let next: String
                        if cur == "links" { next = "rechts" }
                        else if cur == "rechts" { next = "beidseitig" }
                        else { next = "links" }
                        store.updateSetSide(exerciseId: exerciseId, setId: setRec.id, side: next)
                    } label: {
                        Text(sideLabel(setRec.side, setNumber: setRec.setNumber))
                            .font(.system(size: 9, weight: .black, design: .monospaced))
                            .foregroundColor(GymTheme.cyanAccent)
                            .frame(width: 22, height: 32)
                            .background(GymTheme.cyanAccent.opacity(0.15))
                            .cornerRadius(6)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(GymTheme.cyanAccent.opacity(0.4), lineWidth: 0.8))
                    }
                    .buttonStyle(.plain)
                }
            }

            let showsWeight = setRec.weightKg > 0 || manuallyEnabledWeightExercises.contains(exerciseId) || (currentExercise?.sets.contains(where: { $0.weightKg > 0 }) ?? false)

            // +kg Stepper Input Field
            if showsWeight {
                HStack(spacing: 0) {
                    Button {
                        adjustWeight(by: -2.5, exerciseId: exerciseId, setId: setRec.id, current: setRec.weightKg)
                    } label: {
                        Image(systemName: "minus")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(GymTheme.textMuted)
                            .frame(width: 14, height: 32)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button("- 10 kg") { adjustWeight(by: -10, exerciseId: exerciseId, setId: setRec.id, current: setRec.weightKg) }
                        Button("- 5 kg") { adjustWeight(by: -5, exerciseId: exerciseId, setId: setRec.id, current: setRec.weightKg) }
                        Button("- 2.5 kg") { adjustWeight(by: -2.5, exerciseId: exerciseId, setId: setRec.id, current: setRec.weightKg) }
                        Button("- 1.25 kg") { adjustWeight(by: -1.25, exerciseId: exerciseId, setId: setRec.id, current: setRec.weightKg) }
                    }

                    TextField("0", value: Binding(
                        get: { setRec.weightKg },
                        set: { store.updateSetWeight(exerciseId: exerciseId, setId: setRec.id, weight: $0) }
                    ), format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundColor(GymTheme.textPrimary)
                    .frame(minWidth: 42)

                    Button {
                        adjustWeight(by: 2.5, exerciseId: exerciseId, setId: setRec.id, current: setRec.weightKg)
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(GymTheme.textMuted)
                            .frame(width: 14, height: 32)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button("+ 1.25 kg") { adjustWeight(by: 1.25, exerciseId: exerciseId, setId: setRec.id, current: setRec.weightKg) }
                        Button("+ 2.5 kg") { adjustWeight(by: 2.5, exerciseId: exerciseId, setId: setRec.id, current: setRec.weightKg) }
                        Button("+ 5 kg") { adjustWeight(by: 5, exerciseId: exerciseId, setId: setRec.id, current: setRec.weightKg) }
                        Button("+ 10 kg") { adjustWeight(by: 10, exerciseId: exerciseId, setId: setRec.id, current: setRec.weightKg) }
                    }
                }
                .frame(width: 74, height: 32)
                .background(GymTheme.surfaceElevated)
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(GymTheme.border, lineWidth: 1)
                )
            }

            // Reps OR Duration Stepper
            if isTimeBased {
                let currentSec = setRec.durationSeconds ?? (setRec.reps > 20 ? setRec.reps : 60)
                HStack(spacing: 0) {
                    Button {
                        let newSec = max(5, currentSec - 15)
                        store.updateSetDuration(exerciseId: exerciseId, setId: setRec.id, seconds: newSec)
                        HapticFeedback.light()
                    } label: {
                        Image(systemName: "minus")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(GymTheme.textMuted)
                            .frame(width: 14, height: 32)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button("- 60s") { store.updateSetDuration(exerciseId: exerciseId, setId: setRec.id, seconds: max(5, currentSec - 60)) }
                        Button("- 30s") { store.updateSetDuration(exerciseId: exerciseId, setId: setRec.id, seconds: max(5, currentSec - 30)) }
                        Button("- 15s") { store.updateSetDuration(exerciseId: exerciseId, setId: setRec.id, seconds: max(5, currentSec - 15)) }
                    }

                    Button {
                        activeTimedSet = TimedSetContext(
                            exerciseId: exerciseId,
                            setId: setRec.id,
                            exerciseName: exName,
                            setNumber: setRec.setNumber,
                            targetSeconds: currentSec
                        )
                        HapticFeedback.light()
                    } label: {
                        Text(formatDuration(currentSec))
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(GymTheme.sageGreen)
                            .lineLimit(1)
                            .frame(minWidth: 42)
                    }
                    .buttonStyle(.plain)

                    Button {
                        let newSec = currentSec + 15
                        store.updateSetDuration(exerciseId: exerciseId, setId: setRec.id, seconds: newSec)
                        HapticFeedback.light()
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(GymTheme.textMuted)
                            .frame(width: 14, height: 32)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button("+ 15s") { store.updateSetDuration(exerciseId: exerciseId, setId: setRec.id, seconds: currentSec + 15) }
                        Button("+ 30s") { store.updateSetDuration(exerciseId: exerciseId, setId: setRec.id, seconds: currentSec + 30) }
                        Button("+ 60s (1 min)") { store.updateSetDuration(exerciseId: exerciseId, setId: setRec.id, seconds: currentSec + 60) }
                        Button("+ 2 min") { store.updateSetDuration(exerciseId: exerciseId, setId: setRec.id, seconds: currentSec + 120) }
                        Button("+ 5 min (300s)") { store.updateSetDuration(exerciseId: exerciseId, setId: setRec.id, seconds: currentSec + 300) }
                        Button("Exakt 5 Minuten (Plank)") { store.updateSetDuration(exerciseId: exerciseId, setId: setRec.id, seconds: 300) }
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 32, maxHeight: 32)
                .background(GymTheme.surfaceElevated)
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(GymTheme.border, lineWidth: 1)
                )
            } else {
                HStack(spacing: 0) {
                    Button {
                        adjustReps(by: -1, exerciseId: exerciseId, setId: setRec.id, current: setRec.reps)
                    } label: {
                        Image(systemName: "minus")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(GymTheme.textMuted)
                            .frame(width: 14, height: 32)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button("- 5 Wdh") { adjustReps(by: -5, exerciseId: exerciseId, setId: setRec.id, current: setRec.reps) }
                        Button("- 2 Wdh") { adjustReps(by: -2, exerciseId: exerciseId, setId: setRec.id, current: setRec.reps) }
                        Button("- 1 Wdh") { adjustReps(by: -1, exerciseId: exerciseId, setId: setRec.id, current: setRec.reps) }
                    }

                    TextField("0", value: Binding(
                        get: { setRec.reps },
                        set: { store.updateSetReps(exerciseId: exerciseId, setId: setRec.id, reps: $0) }
                    ), format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundColor(GymTheme.textPrimary)
                    .frame(minWidth: 36)

                    Button {
                        adjustReps(by: 1, exerciseId: exerciseId, setId: setRec.id, current: setRec.reps)
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(GymTheme.textMuted)
                            .frame(width: 14, height: 32)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button("+ 1 Wdh") { adjustReps(by: 1, exerciseId: exerciseId, setId: setRec.id, current: setRec.reps) }
                        Button("+ 2 Wdh") { adjustReps(by: 2, exerciseId: exerciseId, setId: setRec.id, current: setRec.reps) }
                        Button("+ 5 Wdh") { adjustReps(by: 5, exerciseId: exerciseId, setId: setRec.id, current: setRec.reps) }
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 32, maxHeight: 32)
                .background(GymTheme.surfaceElevated)
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(GymTheme.border, lineWidth: 1)
                )
            }

            // RPE Scaler Button / Menu (Requirement: RPE for every set)
            Menu {
                Button("RPE 10 (Maximal / 0 RIR)") { store.updateSetRPE(exerciseId: exerciseId, setId: setRec.id, rpe: 10.0) }
                Button("RPE 9.5 (Kaum 1 Rep moeglich)") { store.updateSetRPE(exerciseId: exerciseId, setId: setRec.id, rpe: 9.5) }
                Button("RPE 9 (1 Rep im Tank / 1 RIR)") { store.updateSetRPE(exerciseId: exerciseId, setId: setRec.id, rpe: 9.0) }
                Button("RPE 8.5 (1-2 Reps im Tank)") { store.updateSetRPE(exerciseId: exerciseId, setId: setRec.id, rpe: 8.5) }
                Button("RPE 8 (2 Reps im Tank / 2 RIR)") { store.updateSetRPE(exerciseId: exerciseId, setId: setRec.id, rpe: 8.0) }
                Button("RPE 7.5 (2-3 Reps im Tank)") { store.updateSetRPE(exerciseId: exerciseId, setId: setRec.id, rpe: 7.5) }
                Button("RPE 7 (3 Reps im Tank / 3 RIR)") { store.updateSetRPE(exerciseId: exerciseId, setId: setRec.id, rpe: 7.0) }
                Button("RPE 6 (Leicht / 4+ RIR)") { store.updateSetRPE(exerciseId: exerciseId, setId: setRec.id, rpe: 6.0) }
                if setRec.rpe != nil {
                    Button("RPE zuruecksetzen", role: .destructive) { store.updateSetRPE(exerciseId: exerciseId, setId: setRec.id, rpe: nil) }
                }
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(rpeBgColor(setRec.rpe))
                        .frame(width: 42, height: 32)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(rpeBorderColor(setRec.rpe), lineWidth: 1)
                        )

                    if let r = setRec.rpe {
                        Text(r.truncatingRemainder(dividingBy: 1) == 0 ? "@\(Int(r))" : String(format: "@%.1f", r))
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(rpeTextColor(setRec.rpe))
                    } else {
                        Text("RPE")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(GymTheme.textMuted)
                    }
                }
            }
            .buttonStyle(.plain)

            // Checkmark button (48pt touch area)
            Button {
                if isTimeBased {
                    let currentSec = setRec.durationSeconds ?? (setRec.reps > 20 ? setRec.reps : 60)
                    if setRec.durationSeconds == nil || setRec.durationSeconds == 0 {
                        store.updateSetDuration(exerciseId: exerciseId, setId: setRec.id, seconds: currentSec)
                    }
                }
                store.toggleSet(exerciseId: exerciseId, setId: setRec.id)
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(setRec.isCompleted ? GymTheme.finishGreen : GymTheme.surfaceElevated)
                        .frame(width: 34, height: 32)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(setRec.isCompleted ? Color.clear : GymTheme.border, lineWidth: 1)
                        )
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(setRec.isCompleted ? GymTheme.bg : GymTheme.textMuted)
                }
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .contextMenu {
                if isTimeBased {
                    Button("Direkt abhaken (ohne Timer)") {
                        let currentSec = setRec.durationSeconds ?? (setRec.reps > 20 ? setRec.reps : 60)
                        if setRec.durationSeconds == nil || setRec.durationSeconds == 0 {
                            store.updateSetDuration(exerciseId: exerciseId, setId: setRec.id, seconds: currentSec)
                        }
                        store.toggleSet(exerciseId: exerciseId, setId: setRec.id)
                    }
                    Button("Countdown-Timer oeffnen") {
                        let currentSec = setRec.durationSeconds ?? (setRec.reps > 20 ? setRec.reps : 60)
                        activeTimedSet = TimedSetContext(
                            exerciseId: exerciseId,
                            setId: setRec.id,
                            exerciseName: exName,
                            setNumber: setRec.setNumber,
                            targetSeconds: currentSec
                        )
                    }
                }
            }

            // Direct delete set button (Requirement 2)
            Button {
                store.deleteSet(exerciseId: exerciseId, setId: setRec.id)
                HapticFeedback.light()
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 11))
                    .foregroundColor(GymTheme.textMuted.opacity(0.4))
                    .frame(width: 24, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private func formatWeight(_ kg: Double) -> String {
        if kg.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(kg))"
        } else {
            return String(format: "%.1f", kg)
        }
    }

    private func adjustWeight(by delta: Double, exerciseId: UUID, setId: UUID, current: Double) {
        let newWeight = max(0, current + delta)
        store.updateSetWeight(exerciseId: exerciseId, setId: setId, weight: newWeight)
        HapticFeedback.light()
    }

    private func adjustReps(by delta: Int, exerciseId: UUID, setId: UUID, current: Int) {
        let newReps = max(0, current + delta)
        store.updateSetReps(exerciseId: exerciseId, setId: setId, reps: newReps)
        HapticFeedback.light()
    }

    // MARK: - RPE Pre-Finish Guard
    private var hasUnratedSets: Bool {
        guard let session = store.activeSession else { return false }
        for ex in session.exercises {
            for setRec in ex.sets {
                if setRec.isCompleted && setRec.rpe == nil && !setRec.isWarmup {
                    return true
                }
            }
        }
        return false
    }

    private func attemptFinishWorkout() {
        showingFinishSheet = true
        HapticFeedback.medium()
    }

    private func rpeBgColor(_ rpe: Double?) -> Color {
        guard let r = rpe else { return GymTheme.surfaceElevated }
        if r >= 9.5 { return Color.red.opacity(0.25) }
        if r >= 8.5 { return Color.orange.opacity(0.22) }
        if r >= 7.5 { return GymTheme.warmAmber.opacity(0.20) }
        return GymTheme.sageGreen.opacity(0.18)
    }

    private func rpeBorderColor(_ rpe: Double?) -> Color {
        guard let r = rpe else { return GymTheme.border }
        if r >= 9.5 { return Color.red.opacity(0.7) }
        if r >= 8.5 { return Color.orange.opacity(0.6) }
        if r >= 7.5 { return GymTheme.warmAmber.opacity(0.6) }
        return GymTheme.sageGreen.opacity(0.6)
    }

    private func rpeTextColor(_ rpe: Double?) -> Color {
        guard let r = rpe else { return GymTheme.textMuted }
        if r >= 9.5 { return Color.red }
        if r >= 8.5 { return Color.orange }
        if r >= 7.5 { return GymTheme.warmAmber }
        return GymTheme.sageGreen
    }

    private func sideLabel(_ side: String?, setNumber: Int = 1) -> String {
        if let s = side {
            if s.lowercased().starts(with: "l") && !s.lowercased().contains("+") { return "L" }
            if s.lowercased().starts(with: "r") { return "R" }
            if s.lowercased().contains("beid") || s.lowercased().contains("+") { return "L+R" }
            return s.uppercased()
        }
        return setNumber % 2 == 1 ? "L" : "R"
    }

    // MARK: - Bottom Action Buttons
    private var bottomActionButtons: some View {
        VStack(spacing: 12) {
            Button {
                showingAddExerciseSheet = true
                HapticFeedback.light()
            } label: {
                Text("Uebungen hinzufuegen")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(GymTheme.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(GymTheme.surfaceElevated)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(GymTheme.border, lineWidth: 1)
                    )
            }

            Button {
                attemptFinishWorkout()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "flag.checkered")
                        .font(.caption)
                    Text("Einheit abschliessen (1-Tap Exit-Skalar)")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(GymTheme.finishGreen)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(GymTheme.surfaceElevated)
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(GymTheme.finishGreen.opacity(0.4), lineWidth: 1))
            }

            Button {
                showingCancelAlert = true
                HapticFeedback.medium()
            } label: {
                Text("Workout abbrechen")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(GymTheme.terracotta)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(GymTheme.terracotta.opacity(0.12))
                    .cornerRadius(10)
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Feature 2: Start-/Endzeit anpassen Sheet
    private var adjustTimeSheet: some View {
        NavigationStack {
            ZStack {
                GymTheme.bg.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 20) {
                    Text("STARTZEIT ANPASSEN")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .tracking(1.0)
                        .foregroundColor(GymTheme.textSecondary)

                    DatePicker("Startzeit", selection: $adjustedStartTime, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.graphical)
                        .tint(GymTheme.sageGreen)
                        .padding(12)
                        .background(GymTheme.surface)
                        .cornerRadius(12)

                    Button {
                        store.updateActiveWorkoutStartTime(adjustedStartTime)
                        showingAdjustTimeSheet = false
                    } label: {
                        Text("Startzeit uebernehmen")
                            .font(.headline)
                            .foregroundColor(GymTheme.bg)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(GymTheme.sageGreen)
                            .cornerRadius(10)
                    }

                    Spacer()
                }
                .padding(16)
            }
            .navigationTitle("Startzeit anpassen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") { showingAdjustTimeSheet = false }
                        .foregroundColor(GymTheme.textSecondary)
                }
            }
        }
    }

    // MARK: - Feature 4: Notiz hinzufuegen Sheet
    private var workoutNotesSheet: some View {
        NavigationStack {
            ZStack {
                GymTheme.bg.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 16) {
                    Text("SOMATISCHE NOTIZEN")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .tracking(1.0)
                        .foregroundColor(GymTheme.textSecondary)

                    TextEditor(text: $workoutSomaticNotes)
                        .font(.subheadline)
                        .foregroundColor(GymTheme.textPrimary)
                        .padding(12)
                        .background(GymTheme.surface)
                        .cornerRadius(10)
                        .frame(height: 180)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(GymTheme.border, lineWidth: 1)
                        )

                    Button {
                        store.updateActiveWorkoutNotes(workoutSomaticNotes)
                        showingWorkoutNotesSheet = false
                    } label: {
                        Text("Notiz speichern")
                            .font(.headline)
                            .foregroundColor(GymTheme.bg)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(GymTheme.sageGreen)
                            .cornerRadius(10)
                    }

                    Spacer()
                }
                .padding(16)
            }
            .navigationTitle("Workout-Notiz")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Schliessen") { showingWorkoutNotesSheet = false }
                        .foregroundColor(GymTheme.textSecondary)
                }
            }
        }
    }

    // MARK: - Finish Workout Sheet
    @ViewBuilder
    private var finishWorkoutSheet: some View {
        if let session = store.activeSession {
            FlowCheckInSheet(
                sessionId: session.id,
                programId: nil,
                onComplete: { rpe, notes in
                    Task {
                        await store.finishWorkout(rpe: rpe, notes: notes)
                        showingFinishSheet = false
                        dismiss()
                    }
                }
            )
            .environmentObject(store)
        } else {
            EmptyView()
        }
    }
}

// MARK: - Add Exercise to Active Session Sheet
struct AddExerciseToSessionSheet: View {
    var title: String = "Uebung hinzufuegen"
    let onSelect: (Exercise) -> Void
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: GymStore
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            ZStack {
                GymTheme.bg.ignoresSafeArea()

                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(GymTheme.textMuted)
                        TextField("Uebung suchen", text: $searchText)
                            .foregroundColor(GymTheme.textPrimary)
                    }
                    .padding(10)
                    .background(GymTheme.surface)
                    .cornerRadius(8)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                    List {
                        ForEach(filteredExercises) { ex in
                            Button {
                                onSelect(ex)
                                HapticFeedback.light()
                                dismiss()
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(ex.name)
                                            .font(.subheadline)
                                            .foregroundColor(GymTheme.textPrimary)
                                        Text("\(ex.targetMuscle.rawValue) | \(ex.equipment.rawValue)")
                                            .font(.caption2)
                                            .foregroundColor(GymTheme.textSecondary)
                                    }
                                    Spacer()
                                    if ex.isBWKRehaSafe {
                                        Text("Reha Safe")
                                            .font(.caption2)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(GymTheme.sageGreen.opacity(0.2))
                                            .foregroundColor(GymTheme.sageGreen)
                                            .cornerRadius(4)
                                    }
                                }
                            }
                            .listRowBackground(GymTheme.surface)
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .scrollDismissesKeyboard(.interactively)
                }
            }
            .dismissKeyboardOnSwipeDown()
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Schliessen") { dismiss() }
                        .foregroundColor(GymTheme.textSecondary)
                }
            }
        }
    }

    private var filteredExercises: [Exercise] {
        let eligible = store.exercises.filter { !($0.isContraindicated || $0.isBWKContraindicated) }
        return ExerciseSearchEngine.shared.search(query: searchText, in: eligible, store: store)
    }
}

// MARK: - Isolated Live Elapsed Workout Timer View
struct LiveWorkoutElapsedView: View {
    let session: WorkoutSession
    var onTogglePause: (() -> Void)? = nil
    @State private var elapsedSeconds: Int = 0
    private let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: session.isPaused ? "pause.circle.fill" : "clock")
                .font(.system(size: 12))
                .foregroundColor(session.isPaused ? GymTheme.warningAmber : GymTheme.textMuted)

            Text(elapsedFormattedString)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundColor(session.isPaused ? GymTheme.warningAmber : GymTheme.warmSand)

            if session.isPaused {
                Text("PAUSIERT")
                    .font(.system(size: 9, weight: .black))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(GymTheme.warningAmber.opacity(0.2))
                    .foregroundColor(GymTheme.warningAmber)
                    .cornerRadius(4)
            }

            if let toggle = onTogglePause {
                Button {
                    toggle()
                    HapticFeedback.light()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: session.isPaused ? "play.fill" : "pause.fill")
                            .font(.system(size: 9, weight: .bold))
                        Text(session.isPaused ? "Fortsetzen" : "Pausieren")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(session.isPaused ? GymTheme.finishGreen.opacity(0.18) : GymTheme.surfaceElevated)
                    .foregroundColor(session.isPaused ? GymTheme.finishGreen : GymTheme.textSecondary)
                    .cornerRadius(5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(session.isPaused ? GymTheme.finishGreen.opacity(0.6) : GymTheme.border, lineWidth: 1)
                    )
                }
            }
        }
        .onAppear {
            updateElapsed()
        }
        .onChange(of: session.isPaused) { _ in
            updateElapsed()
        }
        .onReceive(timer) { _ in
            if !session.isPaused {
                updateElapsed()
            }
        }
    }

    private func updateElapsed() {
        var diff = Date().timeIntervalSince(session.startTime) - session.pausedIntervals
        if session.isPaused, let lastPause = session.lastPauseTime {
            diff -= Date().timeIntervalSince(lastPause)
        }
        elapsedSeconds = max(0, Int(diff))
    }

    private var elapsedFormattedString: String {
        let minutes = elapsedSeconds / 60
        let seconds = elapsedSeconds % 60
        if minutes >= 60 {
            let hours = minutes / 60
            let remMin = minutes % 60
            return String(format: "%d:%02d:%02d", hours, remMin, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

// MARK: - Workout Missing RPE Sheet
public struct WorkoutMissingRPESheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: GymStore
    let onAllRated: () -> Void

    private let standardRPEValues: [Double] = [6.0, 7.0, 7.5, 8.0, 8.5, 9.0, 9.5, 10.0]

    private struct UnratedEntry: Identifiable {
        let id: UUID
        let exerciseId: UUID
        let exerciseName: String
        let setNumber: Int
        let reps: Int
        let durationSeconds: Int?
        let isTimeBased: Bool
        let weightKg: Double
    }

    private var currentUnrated: [UnratedEntry] {
        guard let session = store.activeSession else { return [] }
        var result: [UnratedEntry] = []
        for ex in session.exercises {
            for setRec in ex.sets {
                if setRec.isCompleted && setRec.rpe == nil && !setRec.isWarmup {
                    result.append(
                        UnratedEntry(
                            id: setRec.id,
                            exerciseId: ex.id,
                            exerciseName: ex.exercise.name,
                            setNumber: setRec.setNumber,
                            reps: setRec.reps,
                            durationSeconds: setRec.durationSeconds,
                            isTimeBased: setRec.isTimeBased,
                            weightKg: setRec.weightKg
                        )
                    )
                }
            }
        }
        return result
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                GymTheme.bg.ignoresSafeArea()

                VStack(spacing: 0) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 14) {
                            // Header Banner
                            VStack(alignment: .leading, spacing: 4) {
                                Text("RPE-PFLICHTBEWERTUNG")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .tracking(1.0)
                                    .foregroundColor(GymTheme.warningAmber)

                                Text("Bewerte alle absolvierten Saetze")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(GymTheme.textPrimary)

                                Text("Fuer eine praezise Belastungs- und Erholungssteuerung benoetigt jeder Satz eine RPE-Einstufung (Rating of Perceived Exertion) vor dem Abschluss.")
                                    .font(.system(size: 11))
                                    .foregroundColor(GymTheme.textSecondary)
                                    .lineSpacing(2)

                                if !currentUnrated.isEmpty {
                                    Button {
                                        for item in currentUnrated {
                                            store.updateSetRPE(exerciseId: item.exerciseId, setId: item.id, rpe: 7.5)
                                        }
                                        HapticFeedback.success()
                                    } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: "bolt.fill")
                                                .font(.system(size: 11))
                                            Text("Alle unbewerteten Sätze auf RPE 7.5 setzen")
                                                .font(.system(size: 11, weight: .bold))
                                        }
                                        .foregroundColor(GymTheme.warmAmber)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(GymTheme.warmAmber.opacity(0.15))
                                        .cornerRadius(8)
                                    }
                                    .buttonStyle(.plain)
                                    .padding(.top, 4)
                                }
                            }
                            .padding(14)
                            .background(GymTheme.surfaceElevated)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(GymTheme.warningAmber.opacity(0.3), lineWidth: 1))

                            if currentUnrated.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "checkmark.seal.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(GymTheme.finishGreen)

                                    Text("Alle Saetze bewertet!")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(GymTheme.textPrimary)

                                    Text("Das Workout kann nun planmaessig abgeschlossen werden.")
                                        .font(.system(size: 12))
                                        .foregroundColor(GymTheme.textSecondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 30)
                            } else {
                                ForEach(currentUnrated) { item in
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Text(item.exerciseName)
                                                .font(.system(size: 13, weight: .bold))
                                                .foregroundColor(GymTheme.textPrimary)

                                            Spacer()

                                            Text("Satz \(item.setNumber)")
                                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                                .foregroundColor(GymTheme.strongBlue)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(GymTheme.strongBlue.opacity(0.15))
                                                .cornerRadius(4)
                                        }

                                        HStack(spacing: 6) {
                                            if item.weightKg > 0 {
                                                Text("\(String(format: "%.1f", item.weightKg)) kg")
                                                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                                                    .foregroundColor(GymTheme.textSecondary)
                                            }
                                            if item.isTimeBased {
                                                Text("\(item.durationSeconds ?? item.reps)s")
                                                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                                                    .foregroundColor(GymTheme.textSecondary)
                                            } else {
                                                Text("\(item.reps) Wdh")
                                                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                                                    .foregroundColor(GymTheme.textSecondary)
                                            }
                                        }

                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack(spacing: 6) {
                                                ForEach(standardRPEValues, id: \.self) { rpeVal in
                                                    Button {
                                                        store.updateSetRPE(exerciseId: item.exerciseId, setId: item.id, rpe: rpeVal)
                                                        HapticFeedback.selection()
                                                    } label: {
                                                        Text(rpeVal.truncatingRemainder(dividingBy: 1) == 0 ? "@\(Int(rpeVal))" : String(format: "@%.1f", rpeVal))
                                                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                                                            .foregroundColor(GymTheme.textPrimary)
                                                            .padding(.horizontal, 10)
                                                            .padding(.vertical, 7)
                                                            .background(GymTheme.surfaceElevated)
                                                            .cornerRadius(6)
                                                            .overlay(
                                                                RoundedRectangle(cornerRadius: 6)
                                                                    .stroke(GymTheme.border, lineWidth: 1)
                                                            )
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    .padding(12)
                                    .background(GymTheme.surfaceElevated.opacity(0.6))
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(GymTheme.border, lineWidth: 1)
                                    )
                                }
                            }
                        }
                        .padding(16)
                    }

                    // Bottom Bar
                    VStack(spacing: 10) {
                        if currentUnrated.isEmpty {
                            Button {
                                onAllRated()
                            } label: {
                                HStack(spacing: 8) {
                                    Text("Weiter zum Abschluss")
                                        .font(.system(size: 14, weight: .bold))
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 12, weight: .bold))
                                }
                                .foregroundColor(GymTheme.bg)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(GymTheme.finishGreen)
                                .cornerRadius(10)
                            }
                        } else {
                            Text("\(currentUnrated.count) Satz/Sätze noch ohne RPE")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(GymTheme.warningAmber)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)

                            Button {
                                for item in currentUnrated {
                                    store.updateSetRPE(exerciseId: item.exerciseId, setId: item.id, rpe: 7.0)
                                }
                                onAllRated()
                            } label: {
                                Text("Ohne RPE abschließen (Default @7.0)")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(GymTheme.textSecondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(GymTheme.surfaceElevated)
                                    .cornerRadius(8)
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(GymTheme.border, lineWidth: 1))
                            }
                        }

                        Button {
                            dismiss()
                        } label: {
                            Text("Zurueck zum Workout")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(GymTheme.textMuted)
                        }
                    }
                    .padding(16)
                    .background(GymTheme.surfaceElevated)
                }
            }
            .navigationTitle("RPE Bewertung")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Schliessen") {
                        dismiss()
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(GymTheme.textSecondary)
                }
            }
        }
    }
}

