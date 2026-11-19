import SwiftUI

// MARK: - Exercise Catalog View
public struct ExerciseCatalogView: View {
    @EnvironmentObject private var store: GymStore
    @State private var selectedMuscle: MuscleGroup? = nil
    @State private var selectedAnatomicalZone: AnatomicalZone? = nil
    @State private var showOnlyRehaSafe = false
    @State private var selectedExercise: Exercise? = nil
    @State private var showingActiveWorkout = false

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                GymTheme.bg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // Interactive Anatomy Map
                        AnatomicalMuscleMapView(
                            title: "Anatomy Map",
                            isInteractive: true,
                            primaryZones: selectedAnatomicalZone != nil ? [selectedAnatomicalZone!] : [],
                            secondaryZones: [],
                            stabilizerZones: [],
                            onSelectZone: { zone in
                                if selectedAnatomicalZone == zone {
                                    selectedAnatomicalZone = nil
                                } else {
                                    selectedAnatomicalZone = zone
                                    selectedMuscle = nil
                                }
                            }
                        )
                        .padding(.horizontal, 16)

                        // Filter Bar
                        ExerciseCatalogFilterBarView(
                            selectedMuscle: $selectedMuscle,
                            selectedAnatomicalZone: $selectedAnatomicalZone,
                            showOnlyRehaSafe: $showOnlyRehaSafe
                        )

                        // Active Zone Filter Notice (if zone is selected)
                        if let zone = selectedAnatomicalZone {
                            HStack {
                                Text("Gefiltert nach: \(zone.displayName)")
                                    .font(.caption.bold())
                                    .foregroundColor(Color(red: 0.95, green: 0.45, blue: 0.05))

                                Spacer()

                                Button {
                                    selectedAnatomicalZone = nil
                                } label: {
                                    Text("Filter loeschen")
                                        .font(.caption)
                                        .foregroundColor(GymTheme.textMuted)
                                }
                            }
                            .padding(.horizontal, 20)
                        }

                        // Exercise List Items
                        LazyVStack(spacing: 10) {
                            ForEach(filteredExercises) { exercise in
                                Button {
                                    selectedExercise = exercise
                                    HapticFeedback.light()
                                } label: {
                                    ExerciseCatalogRowView(exercise: exercise)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .background(GymTheme.surfaceElevated)
                                        .cornerRadius(14)
                                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(GymTheme.border, lineWidth: 1))
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button {
                                        store.startSingleExerciseWorkout(exercise: exercise)
                                        showingActiveWorkout = true
                                        HapticFeedback.medium()
                                    } label: {
                                        Label("Einzeluebung starten", systemImage: "play.circle.fill")
                                    }

                                    Button {
                                        selectedExercise = exercise
                                        HapticFeedback.light()
                                    } label: {
                                        Label("Details ansehen", systemImage: "info.circle")
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.top, 10)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Geraete & Uebungen")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selectedExercise, onDismiss: {
                if store.activeSession != nil {
                    showingActiveWorkout = true
                }
            }) { exercise in
                ExerciseDetailSheet(exercise: exercise)
            }
            .sheet(isPresented: $showingActiveWorkout) {
                if store.activeSession != nil {
                    ActiveWorkoutView()
                        .environmentObject(store)
                }
            }
            .onChange(of: store.activeSession) { _, newSession in
                if newSession == nil {
                    showingActiveWorkout = false
                }
            }
        }
    }

    private var filteredExercises: [Exercise] {
        var result = store.exercises

        if let zone = selectedAnatomicalZone {
            result = result.filter { ex in
                let zones = MuscleStimulusEngine.shared.resolveThreeTierZones(for: ex)
                return zones.primary.contains(zone) || zones.secondary.contains(zone) || zones.stabilizers.contains(zone)
            }
        } else if let muscle = selectedMuscle {
            result = result.filter { $0.targetMuscle == muscle }
        }

        if showOnlyRehaSafe {
            result = result.filter { $0.isBWKRehaSafe }
        }

        return result
    }
}

// MARK: - Filter Bar Subview
public struct ExerciseCatalogFilterBarView: View {
    @Binding public var selectedMuscle: MuscleGroup?
    @Binding public var selectedAnatomicalZone: AnatomicalZone?
    @Binding public var showOnlyRehaSafe: Bool

    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button {
                    selectedMuscle = nil
                    selectedAnatomicalZone = nil
                    HapticFeedback.light()
                } label: {
                    Text("Alle")
                        .font(.caption.bold())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(selectedMuscle == nil && selectedAnatomicalZone == nil ? GymTheme.primary : GymTheme.surfaceElevated)
                        .foregroundColor(selectedMuscle == nil && selectedAnatomicalZone == nil ? GymTheme.bg : GymTheme.textSecondary)
                        .cornerRadius(8)
                }

                Button {
                    showOnlyRehaSafe.toggle()
                    HapticFeedback.light()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: showOnlyRehaSafe ? "checkmark.circle.fill" : "shield")
                            .font(.caption)
                        Text("BWK Reha Safe")
                            .font(.caption.bold())
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(showOnlyRehaSafe ? GymTheme.sageGreen : GymTheme.surfaceElevated)
                    .foregroundColor(showOnlyRehaSafe ? GymTheme.bg : GymTheme.textSecondary)
                    .cornerRadius(8)
                }

                ForEach(MuscleGroup.allCases, id: \.self) { muscle in
                    Button {
                        if selectedMuscle == muscle {
                            selectedMuscle = nil
                        } else {
                            selectedMuscle = muscle
                            selectedAnatomicalZone = nil
                        }
                        HapticFeedback.light()
                    } label: {
                        Text(muscle.rawValue)
                            .font(.caption.bold())
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedMuscle == muscle ? GymTheme.primary : GymTheme.surfaceElevated)
                            .foregroundColor(selectedMuscle == muscle ? GymTheme.bg : GymTheme.textSecondary)
                            .cornerRadius(8)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - Row Subview
public struct ExerciseCatalogRowView: View {
    public let exercise: Exercise

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(exercise.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(GymTheme.textPrimary)

                Spacer()

                if exercise.isBWKContraindicated {
                    Text("BWK REHA SPERRE")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(GymTheme.terracotta.opacity(0.2))
                        .foregroundColor(GymTheme.terracotta)
                        .cornerRadius(4)
                } else if exercise.isBWKRehaSafe {
                    Text("BWK Safe")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(GymTheme.sageGreen.opacity(0.2))
                        .foregroundColor(GymTheme.sageGreen)
                        .cornerRadius(4)
                }
            }

            HStack(spacing: 8) {
                Text(exercise.difficulty)
                    .font(.caption2)
                    .foregroundColor(GymTheme.textSecondary)

                Text("•")
                    .font(.caption2)
                    .foregroundColor(GymTheme.border)

                Text(exercise.categoryType)
                    .font(.caption2)
                    .foregroundColor(GymTheme.textSecondary)

                Text("•")
                    .font(.caption2)
                    .foregroundColor(GymTheme.border)

                Text(exercise.equipment.rawValue)
                    .font(.caption2)
                    .foregroundColor(GymTheme.textMuted)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Rich Exercise Detail Sheet (Coordinator)
public struct ExerciseDetailSheet: View {
    public let exercise: Exercise
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: GymStore

    @State private var selectedTab: Int = 0
    @State private var showingEditSheet = false
    @State private var linkedExerciseForDetail: Exercise? = nil
    @State private var showingRecordHistorySheet = false
    @State private var fullscreenChartMetric: ExerciseChartMetric? = nil
    @State private var selectedTimeframe: ChartTimeframe = .lastThreeMonths

    private let tabs = ["Über", "Verlauf", "Charts", "Rekorde"]

    public init(exercise: Exercise) {
        self.exercise = exercise
    }

    private var liveExercise: Exercise {
        store.exercises.first(where: { $0.id == exercise.id }) ??
        store.exercises.first(where: { $0.name.caseInsensitiveCompare(exercise.name) == .orderedSame }) ??
        exercise
    }

    private var allSessionsForAnalytics: [WorkoutSession] {
        var result = store.sessions
        if let active = store.activeSession {
            var activeCopy = active
            activeCopy.exercises = active.exercises.compactMap { ex in
                var exCopy = ex
                exCopy.sets = ex.sets.filter { $0.isCompleted }
                return exCopy.sets.isEmpty ? nil : exCopy
            }
            if !activeCopy.exercises.isEmpty {
                result.insert(activeCopy, at: 0)
            }
        }
        return result
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                GymTheme.bg.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header Bar (X, Title, Bearbeiten)
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(GymTheme.surfaceElevated)
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(GymTheme.border, lineWidth: 1)
                                    )
                                Image(systemName: "xmark")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(GymTheme.textSecondary)
                            }
                        }

                        Spacer()

                        Text(liveExercise.name)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(GymTheme.textPrimary)
                            .lineLimit(1)

                        Spacer()

                        HStack(spacing: 10) {
                            Button {
                                store.startSingleExerciseWorkout(exercise: liveExercise)
                                dismiss()
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 10, weight: .bold))
                                    Text("Starten")
                                        .font(.system(size: 13, weight: .bold))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(GymTheme.strongBlue)
                                .cornerRadius(8)
                            }

                            Button {
                                showingEditSheet = true
                            } label: {
                                Text("Bearbeiten")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(Color(red: 0.20, green: 0.60, blue: 0.95))
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 12)

                    // 4-Segment Tab Bar (Über, Verlauf, Charts, Rekorde)
                    HStack(spacing: 4) {
                        ForEach(0..<tabs.count, id: \.self) { idx in
                            Button {
                                selectedTab = idx
                                HapticFeedback.light()
                            } label: {
                                Text(tabs[idx])
                                    .font(.system(size: 13, weight: selectedTab == idx ? .bold : .medium))
                                    .foregroundColor(selectedTab == idx ? GymTheme.bg : GymTheme.textSecondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(
                                        selectedTab == idx
                                            ? GymTheme.sageGreen
                                            : Color.clear
                                    )
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(4)
                    .background(GymTheme.surfaceElevated)
                    .cornerRadius(10)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 14)

                    // Tab Content
                    ScrollView {
                        VStack(alignment: .leading, spacing: 18) {
                            if selectedTab == 0 {
                                ExerciseDetailAboutTab(
                                    exercise: liveExercise,
                                    onSelectLinkedExercise: { linked in
                                        linkedExerciseForDetail = linked
                                    }
                                )
                            } else if selectedTab == 1 {
                                ExerciseDetailHistoryTab(
                                    exercise: liveExercise,
                                    sessions: allSessionsForAnalytics
                                )
                            } else if selectedTab == 2 {
                                ExerciseDetailChartsTab(
                                    exercise: liveExercise,
                                    sessions: allSessionsForAnalytics,
                                    selectedTimeframe: $selectedTimeframe,
                                    onExpandChart: { metric in
                                        fullscreenChartMetric = metric
                                    }
                                )
                            } else {
                                ExerciseDetailRecordsTab(
                                    exercise: liveExercise,
                                    sessions: allSessionsForAnalytics,
                                    onShowRecordHistory: {
                                        showingRecordHistorySheet = true
                                    }
                                )
                            }

                            Spacer(minLength: 40)
                        }
                        .padding(.horizontal, 16)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingEditSheet) {
                EditExerciseSheet(exercise: liveExercise)
                    .environmentObject(store)
            }
            .sheet(item: $linkedExerciseForDetail) { linkedEx in
                ExerciseDetailSheet(exercise: linkedEx)
                    .environmentObject(store)
            }
            .sheet(isPresented: $showingRecordHistorySheet) {
                ExercisePRHistorySheet(
                    exercise: exercise,
                    milestones: ExerciseAnalyticsHelper.computePRMilestones(for: exercise, sessions: allSessionsForAnalytics)
                )
            }
            .sheet(item: $fullscreenChartMetric) { metric in
                ExerciseFullscreenChartView(
                    exercise: exercise,
                    metric: metric,
                    dataPoints: ExerciseAnalyticsHelper.extractDataPoints(for: exercise, metric: metric, timeframe: selectedTimeframe, sessions: allSessionsForAnalytics),
                    timeframe: selectedTimeframe
                )
            }
        }
    }
}

// MARK: - Tab 1: Über (Independent Subview)
public struct ExerciseDetailAboutTab: View {
    public let exercise: Exercise
    public let onSelectLinkedExercise: (Exercise) -> Void

    public var body: some View {
        let zones = MuscleStimulusEngine.shared.resolveThreeTierZones(for: exercise)

        VStack(alignment: .leading, spacing: 18) {
            // Exercise Header (Name, Target Muscle & Equipment Badges)
            VStack(alignment: .leading, spacing: 8) {
                Text(exercise.name)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(GymTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 8) {
                    Text(exercise.targetMuscle.rawValue.uppercased())
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(GymTheme.primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(GymTheme.primary.opacity(0.15))
                        .cornerRadius(6)

                    Text(exercise.equipment.rawValue)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(GymTheme.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(GymTheme.surfaceElevated)
                        .cornerRadius(6)

                    if exercise.isUnilateral {
                        Text("UNILATERAL")
                            .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                            .foregroundColor(GymTheme.warmAmber)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(GymTheme.warmAmber.opacity(0.15))
                            .cornerRadius(5)
                    }
                }
            }
            .padding(.horizontal, 4)

            if exercise.isBWKContraindicated {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(GymTheme.terracotta)
                        Text("BWK ULM REHA HARD-BLOCK")
                            .font(.system(size: 11, weight: .black, design: .monospaced))
                            .foregroundColor(GymTheme.terracotta)
                    }
                    Text("Strikt kontraindiziert (Post-Analprolaps-Operation). Crunches und Sit-ups erzeugen schädlichen intraabdominalen Druck. Nur funktionelle Rumpfstabilisation (Planks, Glute Bridges, Bird-Dog, Pallof Press) gestattet.")
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundColor(GymTheme.textPrimary)
                }
                .padding(12)
                .background(GymTheme.terracotta.opacity(0.15))
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(GymTheme.terracotta.opacity(0.4), lineWidth: 1))
            }

            // 1. Anatomical Muscle Heatmap (Posterior & Anterior View)
            AnatomicalMuscleMapView(
                title: "\(exercise.targetMuscle.rawValue) auf der Muskelkarte",
                isInteractive: true,
                primaryZones: Set(zones.primary),
                secondaryZones: Set(zones.secondary),
                stabilizerZones: Set(zones.stabilizers)
            )

            // 2. Animierte Bewegungsvorschau & Kinematik (Looping GIF)
            AnimatedExercisePreviewCard(exercise: exercise)

            // 3. Anleitung & Ausfuehrung Card
            ExerciseAboutUnifiedInstructionsCard(exercise: exercise)

            // 4. Exercise Details Parameter Card
            ExerciseAboutDetailsCard(exercise: exercise)

            // 5. Variation & Progressionen
            if !exercise.easierOptions.isEmpty || !exercise.harderOptions.isEmpty {
                ExerciseAboutProgressionLinksCard(
                    exercise: exercise,
                    onSelectExercise: onSelectLinkedExercise
                )
            }
        }
    }
}



// MARK: - Instructions Card
public struct ExerciseAboutUnifiedInstructionsCard: View {
    public let exercise: Exercise

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .foregroundColor(GymTheme.sageGreen)
                    .font(.system(size: 16, weight: .bold))

                Text("Anleitung & Ausfuehrung")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(GymTheme.textPrimary)
            }

            // A. Setup & Ausgangsposition
            if !exercise.setup.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(GymTheme.primary)
                        Text("SETUP & AUSGANGSPOSITION")
                            .font(.system(size: 10.5, weight: .bold))
                            .tracking(0.8)
                            .foregroundColor(GymTheme.primary)
                    }

                    Text(exercise.setup)
                        .font(.system(size: 13.5))
                        .foregroundColor(GymTheme.textSecondary)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(12)
                .background(Color(red: 0.12, green: 0.14, blue: 0.18).opacity(0.6))
                .cornerRadius(12)
            }

            // B. Schritt-fuer-Schritt Bewegungsablauf
            VStack(alignment: .leading, spacing: 12) {
                Text("BEWEGUNGSABLAUF")
                    .font(.system(size: 10.5, weight: .bold))
                    .tracking(0.8)
                    .foregroundColor(GymTheme.textMuted)

                ForEach(Array(resolvedInstructionSteps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 10) {
                        Text("\(index + 1).")
                            .font(.system(size: 13.5, weight: .bold))
                            .foregroundColor(GymTheme.textPrimary)
                            .frame(width: 22, alignment: .leading)

                        Text(step)
                            .font(.system(size: 13.5))
                            .foregroundColor(GymTheme.textSecondary)
                            .lineSpacing(2.5)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            // C. Mentale Cues & Fokuspunkte
            if !exercise.cues.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(GymTheme.sageGreen)
                        Text("MENTALE CUES & FOKUSPUNKTE")
                            .font(.system(size: 10.5, weight: .bold))
                            .tracking(0.8)
                            .foregroundColor(GymTheme.sageGreen)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(exercise.cues, id: \.self) { cue in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(GymTheme.sageGreen)
                                    .padding(.top, 4)

                                Text(cue)
                                    .font(.system(size: 13))
                                    .foregroundColor(GymTheme.textSecondary)
                                    .lineSpacing(2)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
                .padding(12)
                .background(Color(red: 0.12, green: 0.14, blue: 0.18).opacity(0.6))
                .cornerRadius(12)
            }

            // D. Typische Fehler (Mistakes to Avoid)
            if !exercise.commonMistakes.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color(red: 0.94, green: 0.22, blue: 0.18))
                        Text("TYPISCHE FEHLER")
                            .font(.system(size: 10.5, weight: .bold))
                            .tracking(0.8)
                            .foregroundColor(Color(red: 0.94, green: 0.22, blue: 0.18))
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(exercise.commonMistakes, id: \.self) { mistake in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(Color(red: 0.94, green: 0.22, blue: 0.18))
                                    .padding(.top, 4)

                                Text(mistake)
                                    .font(.system(size: 13))
                                    .foregroundColor(GymTheme.textSecondary)
                                    .lineSpacing(2)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
                .padding(12)
                .background(Color(red: 0.94, green: 0.22, blue: 0.18).opacity(0.08))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(red: 0.94, green: 0.22, blue: 0.18).opacity(0.25), lineWidth: 1))
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 0.08, green: 0.09, blue: 0.11))
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(red: 0.18, green: 0.20, blue: 0.25), lineWidth: 1))
    }

    private var resolvedInstructionSteps: [String] {
        let raw = !exercise.execution.isEmpty ? exercise.execution : exercise.executionNotes
        if !raw.isEmpty {
            let lines = raw.components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            if !lines.isEmpty {
                return lines.map { line in
                    if let regex = try? NSRegularExpression(pattern: "^[0-9]+[\\.\\)]\\s*") {
                        let range = NSRange(location: 0, length: line.utf16.count)
                        return regex.stringByReplacingMatches(in: line, options: [], range: range, withTemplate: "")
                    }
                    return line
                }
            }
        }
        return [
            "Startposition stabil einnehmen und Rumpfspannung aufbauen.",
            "Die Bewegung kontrolliert ueber den vollen Bewegungsumfang ausfuehren.",
            "Am Umkehrpunkt fuer 1 Sekunde halten und kontrolliert zurueckfuehren."
        ]
    }
}

// MARK: - Exercise Details Parameter Card
public struct ExerciseAboutDetailsCard: View {
    public let exercise: Exercise

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "list.bullet.rectangle.fill")
                    .foregroundColor(GymTheme.primary)
                    .font(.system(size: 15, weight: .bold))

                Text("Uebungs-Parameter")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(GymTheme.textPrimary)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                detailItem(label: "SCHWIERIGKEIT", value: exercise.difficulty, icon: "gauge.medium")
                detailItem(label: "KATEGORIE", value: exercise.categoryType, icon: "tag.fill")
                detailItem(label: "MECHANIK", value: exercise.mechanics, icon: "gearshape.2.fill")
                detailItem(label: "BEWEGUNGSMUSTER", value: exercise.movementPattern, icon: "figure.walk")
                detailItem(label: "KRAFTTYP", value: exercise.force, icon: "bolt.fill")
                detailItem(label: "AUSRUESTUNG", value: exercise.equipment.rawValue, icon: "dumbbell.fill")
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 0.08, green: 0.09, blue: 0.11))
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(red: 0.18, green: 0.20, blue: 0.25), lineWidth: 1))
    }

    private func detailItem(label: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(GymTheme.textMuted)
                Text(label)
                    .font(.system(size: 9.5, weight: .bold))
                    .tracking(0.6)
                    .foregroundColor(GymTheme.textMuted)
            }

            Text(value.isEmpty ? "Standard" : value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(GymTheme.textPrimary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color(red: 0.12, green: 0.14, blue: 0.18).opacity(0.6))
        .cornerRadius(10)
    }
}

// MARK: - Progression Links Card
public struct ExerciseAboutProgressionLinksCard: View {
    public let exercise: Exercise
    public let onSelectExercise: (Exercise) -> Void
    @EnvironmentObject private var store: GymStore

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.triangle.branch")
                    .foregroundColor(Color(red: 0.20, green: 0.60, blue: 0.95))
                    .font(.system(size: 15, weight: .bold))

                Text("Variationen & Progressionen")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(GymTheme.textPrimary)
            }

            // Regressions
            if !exercise.easierOptions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color(red: 0.20, green: 0.60, blue: 0.95))
                        Text("LEICHTERE OPTIONEN (REGRESSIONS)")
                            .font(.system(size: 10.5, weight: .bold))
                            .tracking(0.8)
                            .foregroundColor(Color(red: 0.20, green: 0.60, blue: 0.95))
                    }

                    VStack(spacing: 6) {
                        ForEach(exercise.easierOptions, id: \.self) { option in
                            linkRow(name: option, isProgression: false)
                        }
                    }
                }
            }

            // Progressions
            if !exercise.harderOptions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color(red: 0.95, green: 0.45, blue: 0.05))
                        Text("SCHWERERE OPTIONEN (PROGRESSIONS)")
                            .font(.system(size: 10.5, weight: .bold))
                            .tracking(0.8)
                            .foregroundColor(Color(red: 0.95, green: 0.45, blue: 0.05))
                    }

                    VStack(spacing: 6) {
                        ForEach(exercise.harderOptions, id: \.self) { option in
                            linkRow(name: option, isProgression: true)
                        }
                    }
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 0.08, green: 0.09, blue: 0.11))
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(red: 0.18, green: 0.20, blue: 0.25), lineWidth: 1))
    }

    private func linkRow(name: String, isProgression: Bool) -> some View {
        let matched = matchExerciseInStore(name: name)

        return Button {
            if let matched = matched {
                onSelectExercise(matched)
                HapticFeedback.light()
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: isProgression ? "arrow.up.forward.circle.fill" : "arrow.down.forward.circle.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(isProgression ? Color(red: 0.95, green: 0.45, blue: 0.05) : Color(red: 0.20, green: 0.60, blue: 0.95))

                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.system(size: 13.5, weight: .semibold))
                        .foregroundColor(GymTheme.textPrimary)
                        .multilineTextAlignment(.leading)

                    if let matched = matched {
                        Text("\(matched.targetMuscle.rawValue) • \(matched.equipment.rawValue)")
                            .font(.system(size: 11))
                            .foregroundColor(GymTheme.textMuted)
                    }
                }

                Spacer()

                if matched != nil {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(GymTheme.textMuted)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(red: 0.12, green: 0.14, blue: 0.18).opacity(0.8))
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(GymTheme.borderSubtle, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .disabled(matched == nil)
    }

    private func matchExerciseInStore(name: String) -> Exercise? {
        let clean = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if let exact = store.exercises.first(where: { $0.name.lowercased() == clean }) {
            return exact
        }
        if let contained = store.exercises.first(where: {
            let exName = $0.name.lowercased()
            return clean.contains(exName) || exName.contains(clean)
        }) {
            return contained
        }
        let keywords = clean.components(separatedBy: CharacterSet.alphanumerics.inverted).filter { $0.count > 3 }
        if let keywordMatch = store.exercises.first(where: { ex in
            let exLower = ex.name.lowercased()
            return keywords.contains(where: { exLower.contains($0) })
        }) {
            return keywordMatch
        }
        return nil
    }
}

// MARK: - Tab 2: Verlauf (Independent Subview)
public struct ExerciseDetailHistoryTab: View {
    public let exercise: Exercise
    public let sessions: [WorkoutSession]

    public var body: some View {
        let historySessions = sessions.filter { session in
            session.exercises.contains(where: {
                $0.exercise.name.caseInsensitiveCompare(exercise.name) == .orderedSame || $0.exercise.id == exercise.id
            })
        }.sorted(by: { $0.startTime > $1.startTime })

        VStack(alignment: .leading, spacing: 14) {
            Text("Historie (\(historySessions.count) Einheiten)")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(GymTheme.textPrimary)

            if historySessions.isEmpty {
                Text("Keine vergangenen Trainings mit dieser Uebung protokolliert.")
                    .font(.caption)
                    .foregroundColor(GymTheme.textMuted)
                    .padding(.vertical, 12)
            } else {
                ForEach(historySessions) { session in
                    if let exRecord = session.exercises.first(where: {
                        $0.exercise.name.caseInsensitiveCompare(exercise.name) == .orderedSame || $0.exercise.id == exercise.id
                    }) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(formatDate(session.startTime))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(GymTheme.textPrimary)
                                Spacer()
                                Text(session.title)
                                    .font(.caption)
                                    .foregroundColor(GymTheme.textSecondary)
                            }

                            ForEach(exRecord.sets) { setRec in
                                HStack {
                                    Text("Satz \(setRec.setNumber)")
                                        .font(.caption2)
                                        .foregroundColor(GymTheme.textMuted)
                                    Spacer()
                                    let isTime = setRec.isTimeBased || exRecord.exercise.isTimeBased
                                    if isTime {
                                        let dur = setRec.durationSeconds ?? setRec.reps
                                        if setRec.weightKg > 0 {
                                            Text("\(formatWeight(setRec.weightKg)) kg • \(dur)s")
                                                .font(.caption)
                                                .fontWeight(.medium)
                                                .foregroundColor(GymTheme.textPrimary)
                                        } else {
                                            Text("\(dur)s Hold")
                                                .font(.caption)
                                                .fontWeight(.medium)
                                                .foregroundColor(GymTheme.cyanAccent)
                                        }
                                    } else {
                                        if setRec.weightKg > 0 {
                                            Text("\(formatWeight(setRec.weightKg)) kg x \(setRec.reps)")
                                                .font(.caption)
                                                .fontWeight(.medium)
                                                .foregroundColor(GymTheme.textPrimary)
                                        } else {
                                            Text("\(setRec.reps) Wdh (BW)")
                                                .font(.caption)
                                                .fontWeight(.medium)
                                                .foregroundColor(GymTheme.textPrimary)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(12)
                        .background(GymTheme.surfaceElevated)
                        .cornerRadius(10)
                    }
                }
            }
        }
    }

    private func formatWeight(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(value))"
        } else {
            return String(format: "%.1f", value).replacingOccurrences(of: ".", with: ",")
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Tab 3: Charts (Independent Subview)
public struct ExerciseDetailChartsTab: View {
    public let exercise: Exercise
    public let sessions: [WorkoutSession]
    @Binding public var selectedTimeframe: ChartTimeframe
    public let onExpandChart: (ExerciseChartMetric) -> Void

    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            ForEach(ExerciseChartMetric.allCases) { metric in
                ExerciseChartCardView(
                    exercise: exercise,
                    metric: metric,
                    dataPoints: ExerciseAnalyticsHelper.extractDataPoints(for: exercise, metric: metric, timeframe: selectedTimeframe, sessions: sessions),
                    selectedTimeframe: $selectedTimeframe,
                    onExpand: {
                        onExpandChart(metric)
                    }
                )
            }
        }
    }
}

// MARK: - Tab 4: Rekorde (Independent Subview)
public struct ExerciseDetailRecordsTab: View {
    public let exercise: Exercise
    public let sessions: [WorkoutSession]
    public let onShowRecordHistory: () -> Void

    public var body: some View {
        let maxReps = ExerciseAnalyticsHelper.computeMaxReps(for: exercise, sessions: sessions)
        let maxWeight = ExerciseAnalyticsHelper.computeMaxWeight(for: exercise, sessions: sessions)
        let maxVolume = ExerciseAnalyticsHelper.computeMaxVolume(for: exercise, sessions: sessions)
        let longestTime = ExerciseAnalyticsHelper.computeLongestDuration(for: exercise, sessions: sessions)
        let fastestTime = ExerciseAnalyticsHelper.computeFastestDuration(for: exercise, sessions: sessions)

        VStack(alignment: .leading, spacing: 20) {
            // Header: PERSÖNLICHE REKORDE
            VStack(alignment: .leading, spacing: 10) {
                Text("PERSÖNLICHE REKORDE (PRS)")
                    .font(.system(size: 12, weight: .bold))
                    .tracking(1.0)
                    .foregroundColor(GymTheme.textMuted)

                VStack(spacing: 0) {
                    // 1. Time-based metrics (Longest / Fastest Time)
                    if exercise.isTimeBased || longestTime > 0 {
                        recordMetricRow(
                            title: "Längste Haltedauer (Longest Time)",
                            value: longestTime > 0 ? "\(longestTime) s" : "-"
                        )

                        Divider()
                            .background(GymTheme.border.opacity(0.6))

                        recordMetricRow(
                            title: "Schnellste Satzdauer (Fastest Time)",
                            value: fastestTime > 0 ? "\(fastestTime) s" : "-"
                        )

                        Divider()
                            .background(GymTheme.border.opacity(0.6))
                    }

                    // 2. Max Weight
                    recordMetricRow(
                        title: "Maximales Gewicht",
                        value: maxWeight > 0 ? "\(formatWeight(maxWeight)) kg" : "-"
                    )

                    Divider()
                        .background(GymTheme.border.opacity(0.6))

                    // 3. Max Volume
                    recordMetricRow(
                        title: "Maximales Volumen (Einzelsitzung)",
                        value: maxVolume > 0 ? "\(formatWeight(maxVolume)) kg" : "-"
                    )

                    Divider()
                        .background(GymTheme.border.opacity(0.6))

                    // 4. Max Reps
                    recordMetricRow(
                        title: exercise.isTimeBased ? "Haltewiederholungen" : "Maximale Wiederholungen",
                        value: maxReps > 0 ? "\(maxReps)" : "-"
                    )
                }
                .background(Color(red: 0.08, green: 0.09, blue: 0.11))
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(red: 0.18, green: 0.20, blue: 0.25), lineWidth: 1))
            }

            // Prominenter Action Button: Rekordverlauf anzeigen
            Button {
                onShowRecordHistory()
                HapticFeedback.light()
            } label: {
                Text("Rekordverlauf anzeigen")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(GymTheme.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(red: 0.14, green: 0.16, blue: 0.20))
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color(red: 0.24, green: 0.27, blue: 0.33), lineWidth: 1)
                    )
            }
        }
    }

    private func recordMetricRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 14.5, weight: .semibold))
                .foregroundColor(GymTheme.textPrimary)

            Spacer()

            Text(value)
                .font(.system(size: 15, weight: .bold, design: .monospaced))
                .foregroundColor(value == "-" ? GymTheme.textMuted : GymTheme.cyanAccent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 15)
    }

    private func formatWeight(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(value))"
        } else {
            return String(format: "%.1f", value).replacingOccurrences(of: ".", with: ",")
        }
    }
}

// MARK: - Exercise Analytics Helper
public enum ExerciseAnalyticsHelper {
    public static func computeMaxReps(for exercise: Exercise, sessions: [WorkoutSession]) -> Int {
        let completed = sessions.flatMap { $0.exercises }
            .filter { $0.exercise.name.caseInsensitiveCompare(exercise.name) == .orderedSame || $0.exercise.id == exercise.id }
            .flatMap { $0.sets }
            .filter { $0.isCompleted }
        if exercise.isTimeBased {
            return completed.map { $0.durationSeconds ?? $0.reps }.max() ?? 0
        }
        return completed.map { $0.reps }.max() ?? 0
    }

    public static func computeLongestDuration(for exercise: Exercise, sessions: [WorkoutSession]) -> Int {
        let completed = sessions.flatMap { $0.exercises }
            .filter { $0.exercise.name.caseInsensitiveCompare(exercise.name) == .orderedSame || $0.exercise.id == exercise.id }
            .flatMap { $0.sets }
            .filter { $0.isCompleted }
        return completed.compactMap { $0.durationSeconds }.max() ?? 0
    }

    public static func computeFastestDuration(for exercise: Exercise, sessions: [WorkoutSession]) -> Int {
        let completed = sessions.flatMap { $0.exercises }
            .filter { $0.exercise.name.caseInsensitiveCompare(exercise.name) == .orderedSame || $0.exercise.id == exercise.id }
            .flatMap { $0.sets }
            .filter { $0.isCompleted }
        let valid = completed.compactMap { $0.durationSeconds }.filter { $0 > 0 }
        return valid.min() ?? 0
    }

    public static func computeMaxWeight(for exercise: Exercise, sessions: [WorkoutSession]) -> Double {
        let completed = sessions.flatMap { $0.exercises }
            .filter { $0.exercise.name.caseInsensitiveCompare(exercise.name) == .orderedSame || $0.exercise.id == exercise.id }
            .flatMap { $0.sets }
            .filter { $0.isCompleted }
        return completed.map { $0.weightKg }.max() ?? 0
    }

    public static func computeMaxVolume(for exercise: Exercise, sessions: [WorkoutSession]) -> Double {
        var maxVol: Double = 0
        for session in sessions {
            let exRecs = session.exercises.filter {
                $0.exercise.name.caseInsensitiveCompare(exercise.name) == .orderedSame || $0.exercise.id == exercise.id
            }
            let vol = exRecs.flatMap { $0.sets }.filter { $0.isCompleted }.reduce(0.0) { $0 + ($1.weightKg * Double($1.reps)) }
            if vol > maxVol {
                maxVol = vol
            }
        }
        return maxVol
    }

    public static func extractDataPoints(
        for exercise: Exercise,
        metric: ExerciseChartMetric,
        timeframe: ChartTimeframe,
        sessions: [WorkoutSession]
    ) -> [(date: Date, value: Double)] {
        let now = Date()
        let filteredSessions = sessions
            .filter { !$0.isEarlyTermination }
            .filter { session in
                if let limit = timeframe.daysLimit,
                   let cutoff = Calendar.current.date(byAdding: .day, value: -limit, to: now) {
                    return session.startTime >= cutoff
                }
                return true
            }
            .sorted { $0.startTime < $1.startTime }

        var results: [(date: Date, value: Double)] = []

        for session in filteredSessions {
            guard let exRec = session.exercises.first(where: {
                $0.exercise.name.caseInsensitiveCompare(exercise.name) == .orderedSame || $0.exercise.id == exercise.id
            }) else { continue }

            let completed = exRec.sets.filter { $0.isCompleted }
            guard !completed.isEmpty else { continue }

            switch metric {
            case .bestSetMaxWeight:
                let maxWeight = completed.map { $0.weightKg }.max() ?? 0
                results.append((session.startTime, maxWeight))
            case .totalVolumeAdded:
                let vol = completed.reduce(0.0) { $0 + ($1.weightKg * Double($1.reps)) }
                results.append((session.startTime, vol))
            case .estimated1RM:
                let max1RM = completed.map { set in
                    OneRepMaxFormula.calculateAccurate1RM(weightKg: set.weightKg, reps: set.reps, rpe: set.rpe)
                }.max() ?? 0
                results.append((session.startTime, max1RM))
            case .maxConsecutiveReps:
                let maxReps = completed.map { $0.reps }.max() ?? 0
                results.append((session.startTime, Double(maxReps)))
            case .totalReps:
                let total = completed.reduce(0) { $0 + $1.reps }
                results.append((session.startTime, Double(total)))
            }
        }

        return results
    }

    public static func computePRMilestones(for exercise: Exercise, sessions: [WorkoutSession]) -> [ExercisePRMilestone] {
        let sortedSessions = sessions
            .filter { !$0.isEarlyTermination }
            .sorted { $0.startTime < $1.startTime }

        var milestones: [ExercisePRMilestone] = []
        var currentW: Double = 0
        var currentR: Int = 0
        var currentV: Double = 0

        for session in sortedSessions {
            guard let exRec = session.exercises.first(where: {
                $0.exercise.name.caseInsensitiveCompare(exercise.name) == .orderedSame || $0.exercise.id == exercise.id
            }) else { continue }

            let completed = exRec.sets.filter { $0.isCompleted }
            guard !completed.isEmpty else { continue }

            if let maxW = completed.map({ $0.weightKg }).max(), maxW > currentW && maxW > 0 {
                milestones.append(ExercisePRMilestone(
                    date: session.startTime,
                    type: .weight,
                    value: maxW,
                    previousValue: currentW,
                    sessionTitle: session.title
                ))
                currentW = maxW
            }

            if let maxR = completed.map({ $0.reps }).max(), maxR > currentR && maxR > 0 {
                milestones.append(ExercisePRMilestone(
                    date: session.startTime,
                    type: .reps,
                    value: Double(maxR),
                    previousValue: Double(currentR),
                    sessionTitle: session.title
                ))
                currentR = maxR
            }

            let vol = completed.reduce(0.0) { $0 + ($1.weightKg * Double($1.reps)) }
            if vol > currentV && vol > 0 {
                milestones.append(ExercisePRMilestone(
                    date: session.startTime,
                    type: .volume,
                    value: vol,
                    previousValue: currentV,
                    sessionTitle: session.title
                ))
                currentV = vol
            }
        }

        return milestones.sorted { $0.date > $1.date }
    }
}

// MARK: - Exercise Chart & Record Models
public enum ExerciseChartMetric: String, CaseIterable, Identifiable {
    case bestSetMaxWeight = "Best Set (Max Weight)"
    case totalVolumeAdded = "Total Volume Added"
    case estimated1RM = "Geschätztes 1RM (xRM)"
    case maxConsecutiveReps = "Max aufeinanderfolgende Wiederholungen"
    case totalReps = "Gesamte Wiederh."

    public var id: String { rawValue }

    public var unit: String {
        switch self {
        case .bestSetMaxWeight: return "kg"
        case .totalVolumeAdded: return "kg"
        case .estimated1RM: return "kg"
        case .maxConsecutiveReps: return "wiederh."
        case .totalReps: return "wiederh."
        }
    }

    public var defaultYBounds: (min: Double, max: Double) {
        switch self {
        case .bestSetMaxWeight: return (0, 140)
        case .totalVolumeAdded: return (0, 2000)
        case .estimated1RM: return (0, 160)
        case .maxConsecutiveReps: return (10, 20)
        case .totalReps: return (0, 120)
        }
    }
}

public enum ChartTimeframe: String, CaseIterable, Identifiable {
    case lastThreeMonths = "Letzte 3 Monate"
    case lastSixMonths = "Letzte 6 Monate"
    case allTime = "Gesamter Verlauf"

    public var id: String { rawValue }

    public var daysLimit: Int? {
        switch self {
        case .lastThreeMonths: return 90
        case .lastSixMonths: return 180
        case .allTime: return nil
        }
    }
}

public struct ExercisePRMilestone: Identifiable {
    public let id = UUID()
    public let date: Date
    public let type: PRType
    public let value: Double
    public let previousValue: Double
    public let sessionTitle: String

    public enum PRType: String {
        case weight = "Max Gewicht"
        case reps = "Max Wiederholungen"
        case volume = "Max Volumen"

        public var unit: String {
            switch self {
            case .weight: return "kg"
            case .reps: return "Wdh."
            case .volume: return "kg"
            }
        }
    }
}

// MARK: - Exercise Chart Card View
public struct ExerciseChartCardView: View {
    public let exercise: Exercise
    public let metric: ExerciseChartMetric
    public let dataPoints: [(date: Date, value: Double)]
    @Binding public var selectedTimeframe: ChartTimeframe
    public let onExpand: () -> Void

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header Bar
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(exercise.name)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(GymTheme.textPrimary)

                    Text(metric.rawValue)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(GymTheme.textSecondary)
                }

                Spacer()

                HStack(spacing: 12) {
                    // Expand Button
                    Button {
                        onExpand()
                        HapticFeedback.light()
                    } label: {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Color(red: 0.20, green: 0.60, blue: 0.95))
                            .frame(width: 30, height: 30)
                            .background(Color(red: 0.14, green: 0.22, blue: 0.32))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    // Options Menu
                    Menu {
                        Section("Zeitbereich") {
                            ForEach(ChartTimeframe.allCases) { tf in
                                Button {
                                    selectedTimeframe = tf
                                } label: {
                                    if selectedTimeframe == tf {
                                        Label(tf.rawValue, systemImage: "checkmark")
                                    } else {
                                        Text(tf.rawValue)
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color(red: 0.20, green: 0.60, blue: 0.95))
                            .frame(width: 30, height: 30)
                            .background(Color(red: 0.14, green: 0.22, blue: 0.32))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }

            // Chart Canvas Area
            ExerciseTrendCanvasView(
                metric: metric,
                dataPoints: dataPoints,
                height: 150,
                accentColor: Color(red: 0.65, green: 0.45, blue: 0.95),
                isExpanded: false
            )
        }
        .padding(16)
        .background(Color(red: 0.08, green: 0.09, blue: 0.11))
        .cornerRadius(18)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color(red: 0.18, green: 0.20, blue: 0.25), lineWidth: 1))
    }
}

// MARK: - Exercise Trend Canvas View
public struct ExerciseTrendCanvasView: View {
    public let metric: ExerciseChartMetric
    public let dataPoints: [(date: Date, value: Double)]
    public let height: CGFloat
    public let accentColor: Color
    public var isExpanded: Bool = false
    public var onSelectIndex: ((Int?) -> Void)? = nil

    private var timeAxisLabels: [String] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")

        if dataPoints.count >= 2,
           let first = dataPoints.first?.date,
           let last = dataPoints.last?.date {
            let days = calendar.dateComponents([.day], from: first, to: last).day ?? 0
            if days > 365 {
                let startYear = calendar.component(.year, from: first)
                let endYear = calendar.component(.year, from: last)
                if endYear > startYear && (endYear - startYear) <= 4 {
                    var labels: [String] = []
                    for y in startYear...endYear {
                        labels.append("\(y)")
                    }
                    return labels
                }
                formatter.dateFormat = "MMM. yy"
                let mid1 = first.addingTimeInterval(last.timeIntervalSince(first) * 0.33)
                let mid2 = first.addingTimeInterval(last.timeIntervalSince(first) * 0.66)
                return [
                    formatter.string(from: first).uppercased(),
                    formatter.string(from: mid1).uppercased(),
                    formatter.string(from: mid2).uppercased(),
                    formatter.string(from: last).uppercased()
                ]
            } else if days > 90 {
                formatter.dateFormat = "MMM. yy"
                let mid = first.addingTimeInterval(last.timeIntervalSince(first) * 0.5)
                return [
                    formatter.string(from: first).uppercased(),
                    formatter.string(from: mid).uppercased(),
                    formatter.string(from: last).uppercased()
                ]
            } else {
                formatter.dateFormat = "d. MMM."
                let mid = first.addingTimeInterval(last.timeIntervalSince(first) * 0.5)
                return [
                    formatter.string(from: first).uppercased(),
                    formatter.string(from: mid).uppercased(),
                    formatter.string(from: last).uppercased()
                ]
            }
        } else {
            formatter.dateFormat = "MMM."
            var labels: [String] = []
            let now = Date()
            for offset in stride(from: 2, through: 0, by: -1) {
                if let d = calendar.date(byAdding: .month, value: -offset, to: now) {
                    labels.append(formatter.string(from: d).uppercased())
                }
            }
            return labels
        }
    }

    private var yBounds: (min: Double, max: Double) {
        if dataPoints.count >= 2 {
            let values = dataPoints.map { $0.value }
            let minVal = values.min() ?? metric.defaultYBounds.min
            let maxVal = values.max() ?? metric.defaultYBounds.max
            let padding = max(1.0, (maxVal - minVal) * 0.15)
            return (max(0, minVal - padding), maxVal + padding)
        } else {
            return metric.defaultYBounds
        }
    }

    public var body: some View {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(red: 0.08, green: 0.09, blue: 0.11))

                GeometryReader { geo in
                    let w = geo.size.width
                    let h = geo.size.height

                    // Horizontal Grid Lines
                    Path { path in
                        path.move(to: CGPoint(x: 10, y: h * 0.15))
                        path.addLine(to: CGPoint(x: w - 75, y: h * 0.15))

                        path.move(to: CGPoint(x: 10, y: h * 0.50))
                        path.addLine(to: CGPoint(x: w - 75, y: h * 0.50))

                        path.move(to: CGPoint(x: 10, y: h * 0.85))
                        path.addLine(to: CGPoint(x: w - 75, y: h * 0.85))
                    }
                    .stroke(Color(red: 0.16, green: 0.18, blue: 0.23), style: StrokeStyle(lineWidth: 0.8, dash: [4, 4]))

                    // Vertical Month Divider Lines
                    Path { path in
                        path.move(to: CGPoint(x: (w - 75) * 0.33, y: 10))
                        path.addLine(to: CGPoint(x: (w - 75) * 0.33, y: h - 10))

                        path.move(to: CGPoint(x: (w - 75) * 0.66, y: 10))
                        path.addLine(to: CGPoint(x: (w - 75) * 0.66, y: h - 10))
                    }
                    .stroke(Color(red: 0.14, green: 0.16, blue: 0.21), style: StrokeStyle(lineWidth: 0.8, dash: [4, 4]))

                    // Y-Axis Labels on the Right
                    VStack(alignment: .trailing) {
                        Text(formatYValue(yBounds.max))
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(GymTheme.textMuted)

                        Spacer()

                        Text(formatYValue((yBounds.min + yBounds.max) * 0.5))
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundColor(GymTheme.textMuted.opacity(0.75))

                        Spacer()

                        Text(formatYValue(yBounds.min))
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(GymTheme.textMuted)
                    }
                    .frame(width: 70, height: h * 0.75, alignment: .trailing)
                    .position(x: w - 38, y: h * 0.50)

                    // Data Plot Area
                    let plotWidth = max(20, w - 85)
                    let plotHeight = max(20, h * 0.70)
                    let plotOffsetY = h * 0.15

                    if dataPoints.count >= 2 {
                        let points = normalizedPoints(width: plotWidth, height: plotHeight, offsetY: plotOffsetY)

                        Path { path in
                            if let first = points.first {
                                path.move(to: CGPoint(x: first.x, y: plotOffsetY + plotHeight))
                                for pt in points {
                                    path.addLine(to: pt)
                                }
                                if let last = points.last {
                                    path.addLine(to: CGPoint(x: last.x, y: plotOffsetY + plotHeight))
                                }
                                path.closeSubpath()
                            }
                        }
                        .fill(
                            LinearGradient(
                                colors: [
                                    accentColor.opacity(0.24),
                                    accentColor.opacity(0.01)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                        Path { path in
                            for (idx, pt) in points.enumerated() {
                                if idx == 0 {
                                    path.move(to: pt)
                                } else {
                                    path.addLine(to: pt)
                                }
                            }
                        }
                        .stroke(accentColor, style: StrokeStyle(lineWidth: 2.8, lineCap: .round, lineJoin: .round))

                        ForEach(0..<points.count, id: \.self) { idx in
                            let pt = points[idx]
                            Circle()
                                .fill(Color(red: 0.08, green: 0.09, blue: 0.11))
                                .frame(width: 8, height: 8)
                                .overlay(
                                    Circle()
                                        .stroke(accentColor, lineWidth: 2)
                                )
                                .position(pt)
                        }
                    } else if let single = dataPoints.first {
                        let (minY, maxY) = yBounds
                        let rangeY = max(1.0, maxY - minY)
                        let normY = (single.value - minY) / rangeY
                        let lineY = plotOffsetY + plotHeight * (1.0 - CGFloat(normY))

                        Path { path in
                            path.move(to: CGPoint(x: 10, y: plotOffsetY + plotHeight))
                            path.addLine(to: CGPoint(x: 10, y: lineY))
                            path.addLine(to: CGPoint(x: plotWidth, y: lineY))
                            path.addLine(to: CGPoint(x: plotWidth, y: plotOffsetY + plotHeight))
                            path.closeSubpath()
                        }
                        .fill(
                            LinearGradient(
                                colors: [accentColor.opacity(0.18), accentColor.opacity(0.01)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                        Path { path in
                            path.move(to: CGPoint(x: 10, y: lineY))
                            path.addLine(to: CGPoint(x: plotWidth, y: lineY))
                        }
                        .stroke(accentColor, style: StrokeStyle(lineWidth: 2.6, lineCap: .round))

                        let midX = 10 + (plotWidth - 10) * 0.5
                        Circle()
                            .fill(Color(red: 0.08, green: 0.09, blue: 0.11))
                            .frame(width: 10, height: 10)
                            .overlay(Circle().stroke(accentColor, lineWidth: 2.5))
                            .position(x: midX, y: lineY)

                        Text("\(formatYValue(single.value))")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(accentColor)
                            .position(x: midX, y: lineY - 14)
                    } else {
                        let baselineY = plotOffsetY + plotHeight * 0.50

                        Path { path in
                            path.move(to: CGPoint(x: 10, y: plotOffsetY + plotHeight))
                            path.addLine(to: CGPoint(x: 10, y: baselineY))
                            path.addLine(to: CGPoint(x: plotWidth, y: baselineY))
                            path.addLine(to: CGPoint(x: plotWidth, y: plotOffsetY + plotHeight))
                            path.closeSubpath()
                        }
                        .fill(
                            LinearGradient(
                                colors: [accentColor.opacity(0.12), accentColor.opacity(0.01)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                        Path { path in
                            path.move(to: CGPoint(x: 10, y: baselineY))
                            path.addLine(to: CGPoint(x: plotWidth, y: baselineY))
                        }
                        .stroke(accentColor.opacity(0.75), style: StrokeStyle(lineWidth: 2.0, lineCap: .round))

                        VStack(spacing: 4) {
                            Text("Referenz-Baseline: \(formatYValue((yBounds.min + yBounds.max) * 0.5))")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(accentColor)

                            Text("Sobald Workouts geloggt werden, folgt die Linie deinen Realsätzen.")
                                .font(.system(size: 9))
                                .foregroundColor(GymTheme.textSecondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.65))
                        .cornerRadius(6)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
            .frame(height: height)

            HStack {
                ForEach(0..<timeAxisLabels.count, id: \.self) { idx in
                    Text(timeAxisLabels[idx])
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(GymTheme.textMuted)

                    if idx < timeAxisLabels.count - 1 {
                        Spacer()
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 4)
        }
    }

    private func normalizedPoints(width: CGFloat, height: CGFloat, offsetY: CGFloat) -> [CGPoint] {
        guard dataPoints.count >= 2 else { return [] }
        let (minY, maxY) = yBounds
        let rangeY = max(1.0, maxY - minY)

        guard let firstDate = dataPoints.first?.date,
              let lastDate = dataPoints.last?.date,
              lastDate > firstDate else {
            return dataPoints.enumerated().map { idx, dp in
                let x = 14 + (width - 28) * (CGFloat(idx) / CGFloat(dataPoints.count - 1))
                let normY = (dp.value - minY) / rangeY
                let y = offsetY + height * (1.0 - CGFloat(normY))
                return CGPoint(x: x, y: y)
            }
        }

        let totalTime = lastDate.timeIntervalSince(firstDate)
        return dataPoints.map { dp in
            let frac = CGFloat(dp.date.timeIntervalSince(firstDate) / totalTime)
            let x = 14 + (width - 28) * frac
            let normY = (dp.value - minY) / rangeY
            let y = offsetY + height * (1.0 - CGFloat(normY))
            return CGPoint(x: x, y: y)
        }
    }

    private func formatYValue(_ val: Double) -> String {
        if val.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(val)) \(metric.unit)"
        } else {
            return String(format: "%.0f %@", val, metric.unit)
        }
    }
}

// MARK: - Fullscreen / Expanded Chart Modal
public struct ExerciseFullscreenChartView: View {
    public let exercise: Exercise
    public let metric: ExerciseChartMetric
    public let dataPoints: [(date: Date, value: Double)]
    public let timeframe: ChartTimeframe
    @Environment(\.dismiss) private var dismiss

    @State private var touchedPointIndex: Int? = nil

    public var body: some View {
        NavigationStack {
            ZStack {
                GymTheme.bg.ignoresSafeArea()

                VStack(spacing: 16) {
                    // Top Header Bar
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(exercise.name)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(GymTheme.textPrimary)

                            Text(metric.rawValue)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(GymTheme.textSecondary)
                        }

                        Spacer()

                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(GymTheme.textSecondary)
                                .padding(8)
                                .background(GymTheme.surfaceElevated)
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                    // Large Interactive Canvas
                    ExerciseTrendCanvasView(
                        metric: metric,
                        dataPoints: dataPoints,
                        height: 380,
                        accentColor: Color(red: 0.65, green: 0.45, blue: 0.95),
                        isExpanded: true,
                        onSelectIndex: { idx in
                            touchedPointIndex = idx
                        }
                    )
                    .padding(.horizontal, 16)

                    if let idx = touchedPointIndex, idx < dataPoints.count {
                        let pt = dataPoints[idx]
                        HStack(spacing: 12) {
                            Text(formatDate(pt.date))
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(GymTheme.textMuted)

                            Spacer()

                            Text(String(format: "%.1f %@", pt.value, metric.unit))
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(Color(red: 0.65, green: 0.45, blue: 0.95))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color(red: 0.12, green: 0.14, blue: 0.18))
                        .cornerRadius(12)
                        .padding(.horizontal, 20)
                    }

                    Spacer()

                    // Bottom Action Toolbar (Minimize & Share)
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "arrow.down.right.and.arrow.up.left")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(GymTheme.textSecondary)
                                .padding(12)
                                .background(GymTheme.surfaceElevated)
                                .clipShape(Circle())
                        }

                        Spacer()

                        ShareLink(item: shareText) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(GymTheme.textSecondary)
                                .padding(12)
                                .background(GymTheme.surfaceElevated)
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                }
            }
            .navigationBarHidden(true)
        }
    }

    private var shareText: String {
        let maxVal = dataPoints.map { $0.value }.max() ?? 0
        return "Grow Trainingsanalyse: \(exercise.name)\nMetrik: \(metric.rawValue)\nDatenpunkte: \(dataPoints.count)\nBestwert: \(String(format: "%.1f", maxVal)) \(metric.unit)"
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Exercise PR History Sheet
public struct ExercisePRHistorySheet: View {
    public let exercise: Exercise
    public let milestones: [ExercisePRMilestone]
    @Environment(\.dismiss) private var dismiss

    public var body: some View {
        NavigationStack {
            ZStack {
                GymTheme.bg.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Historische Rekorde")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(GymTheme.textPrimary)

                            Text("Chronologische Meilensteine fuer \(exercise.name)")
                                .font(.system(size: 13))
                                .foregroundColor(GymTheme.textMuted)
                        }
                        .padding(.top, 10)

                        if milestones.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "trophy")
                                    .font(.system(size: 38))
                                    .foregroundColor(GymTheme.textMuted)
                                    .padding(.top, 24)

                                Text("Keine Rekorde verzeichnet")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(GymTheme.textPrimary)

                                Text("Sobald du Trainingseinheiten mit dieser Uebung absolvierst, werden Bestleistungen fuer Gewicht, Wiederholungen und Volumen automatisch hier archiviert.")
                                    .font(.system(size: 13))
                                    .foregroundColor(GymTheme.textMuted)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 20)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 30)
                            .background(Color(red: 0.08, green: 0.09, blue: 0.11))
                            .cornerRadius(16)
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(red: 0.18, green: 0.20, blue: 0.25), lineWidth: 1))
                        } else {
                            VStack(spacing: 12) {
                                ForEach(milestones) { m in
                                    milestoneRow(m)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Rekordverlauf")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(GymTheme.textSecondary)
                    }
                }
            }
        }
    }

    private func milestoneRow(_ m: ExercisePRMilestone) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(formatDate(m.date))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(GymTheme.textMuted)

                Spacer()

                Text(m.sessionTitle)
                    .font(.system(size: 12))
                    .foregroundColor(GymTheme.textSecondary)
                    .lineLimit(1)
            }

            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(badgeColor(for: m.type))
                        .frame(width: 8, height: 8)

                    Text(m.type.rawValue)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(GymTheme.textPrimary)
                }

                Spacer()

                HStack(spacing: 6) {
                    Text(formatMilestoneValue(m.value, type: m.type))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(GymTheme.textPrimary)

                    if m.previousValue > 0 {
                        let diff = m.value - m.previousValue
                        Text("+\(formatMilestoneValue(diff, type: m.type))")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(GymTheme.sageGreen)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(GymTheme.sageGreen.opacity(0.15))
                            .cornerRadius(4)
                    }
                }
            }
        }
        .padding(14)
        .background(Color(red: 0.08, green: 0.09, blue: 0.11))
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(red: 0.18, green: 0.20, blue: 0.25), lineWidth: 1))
    }

    private func badgeColor(for type: ExercisePRMilestone.PRType) -> Color {
        switch type {
        case .weight: return GymTheme.sageGreen
        case .reps: return Color(red: 0.20, green: 0.60, blue: 0.95)
        case .volume: return Color(red: 0.65, green: 0.45, blue: 0.95)
        }
    }

    private func formatMilestoneValue(_ val: Double, type: ExercisePRMilestone.PRType) -> String {
        if val.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(val)) \(type.unit)"
        } else {
            return String(format: "%.1f %@", val, type.unit)
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
