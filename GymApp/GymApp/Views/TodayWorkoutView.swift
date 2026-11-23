import SwiftUI

public struct TodayWorkoutView: View {
    @EnvironmentObject private var store: GymStore
    @StateObject private var growceryService = GrowcerySyncService.shared
    @StateObject private var healthService = HealthKitService.shared
    @ObservedObject private var userAccount = UserAccountService.shared
    
    @State private var showingActiveWorkout = false
    @State private var showingProfileAndSettings = false
    @State private var showingStartWorkoutSheet = false
    @State private var isTagesdetailExpanded = true
    @State private var selectedDate = Date()
    @State private var selectedPlannedWorkoutForPreview: PlannedWorkoutItem? = nil
    @State private var selectedCompletedSessionForDetail: WorkoutSession? = nil
    @State private var showingPlanWorkoutSheet = false
    @State private var activeWorkoutMenuTarget: UnifiedDayWorkoutItem? = nil
    @State private var showingMeasurements = false
    @State private var showingDeepMuscleReport = false
    @State private var showingAthleticStandardGraph = false
    @State private var workoutToDelete: UnifiedDayWorkoutItem? = nil
    @State private var showingDeleteWorkoutDialog = false

    public var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                GymTheme.bg.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        // User Profile & Header
                        profileHeaderSection

                        // Active Workout Banner (if session is in progress)
                        if store.activeSession != nil {
                            activeSessionBanner
                        }

                        // Tapable Calendar Date Detail (Notes + Workouts on that day) positioned at bottom for one-handed reachability
                        selectedDateDetailCard

                        // Biomechanik, Körpermaße & Leistungsstandard (Migrated from Profile)
                        biomechanicsAndStandardsSection

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .frame(maxWidth: 720)
                    .frame(maxWidth: .infinity)
                }
                .scrollDismissesKeyboard(.interactively)
                .dismissKeyboardOnTap()
                .simultaneousGesture(
                    DragGesture(minimumDistance: 25)
                        .onEnded { value in
                            let horizontalDistance = value.translation.width
                            let verticalDistance = value.translation.height
                            if abs(horizontalDistance) > abs(verticalDistance) * 1.2 && abs(horizontalDistance) > 35 {
                                if horizontalDistance < 0 {
                                    advanceDate(by: 1)
                                } else {
                                    advanceDate(by: -1)
                                }
                            } else if verticalDistance > 25 {
                                hideKeyboard()
                            }
                        }
                )
            }
            .sheet(isPresented: $showingProfileAndSettings) {
                EcosystemProfileAndSettingsSheet()
                    .environmentObject(store)
            }
            .sheet(isPresented: $showingStartWorkoutSheet, onDismiss: {
                if store.activeSession != nil {
                    showingActiveWorkout = true
                }
            }) {
                StartWorkoutQuickSheet()
                    .environmentObject(store)
            }
            .sheet(isPresented: $showingActiveWorkout) {
                ActiveWorkoutView()
                    .environmentObject(store)
            }
            .onChange(of: store.activeSession) { _, newSession in
                if newSession == nil {
                    showingActiveWorkout = false
                }
            }
            .sheet(item: $selectedPlannedWorkoutForPreview) { planned in
                WorkoutPreviewSheet(plannedItem: planned) {
                    store.startWorkout(from: planned)
                    showingActiveWorkout = true
                }
                .environmentObject(store)
            }
            .sheet(item: $selectedCompletedSessionForDetail) { session in
                CompletedWorkoutDetailSheet(session: session)
                    .environmentObject(store)
            }
            .sheet(isPresented: $showingPlanWorkoutSheet) {
                PlanWorkoutSheet(targetDate: selectedDate)
                    .environmentObject(store)
            }
            .sheet(isPresented: $showingMeasurements) {
                NavigationStack {
                    MeasurementsView()
                }
                .environmentObject(store)
            }
            .sheet(isPresented: $showingDeepMuscleReport) {
                DeepMuscleReportSheet()
                    .environmentObject(store)
            }
            .sheet(isPresented: $showingAthleticStandardGraph) {
                AthleticStandardGraphView()
                    .environmentObject(store)
            }
            .confirmationDialog(
                "Workout aus Kalender löschen",
                isPresented: $showingDeleteWorkoutDialog,
                presenting: workoutToDelete
            ) { item in
                Button("Aus Kalender und Verlauf löschen", role: .destructive) {
                    deleteUnifiedWorkout(item)
                }
                Button("Abbrechen", role: .cancel) {}
            } message: { item in
                Text("Möchtest du '\(item.title)' wirklich aus dem Kalender und deinem Trainingsverlauf löschen?")
            }
            .confirmationDialog(
                activeWorkoutMenuTarget?.title ?? "Einheit",
                isPresented: Binding(
                    get: { activeWorkoutMenuTarget != nil },
                    set: { if !$0 { activeWorkoutMenuTarget = nil } }
                ),
                titleVisibility: .visible
            ) {
                if let target = activeWorkoutMenuTarget {
                    switch target.source {
                    case .planned(let planned):
                        if !planned.isCompleted {
                            Button("Einheit starten") {
                                store.startWorkout(from: planned)
                                showingActiveWorkout = true
                            }
                        }
                        Button("Vorschau anzeigen") {
                            selectedPlannedWorkoutForPreview = planned
                        }
                        Button(planned.isCompleted ? "Als offen markieren" : "Als absolviert markieren") {
                            store.togglePlannedWorkoutCompletion(id: planned.id)
                        }
                        Button("Einheit entfernen", role: .destructive) {
                            store.removePlannedWorkout(id: planned.id)
                        }

                    case .completedGrow(let session):
                        Button("Details ansehen") {
                            selectedCompletedSessionForDetail = session
                        }
                        Button("Erneut trainieren (Wiederholen)") {
                            store.startWorkout()
                            showingActiveWorkout = true
                        }
                        Button("Aus Verlauf entfernen", role: .destructive) {
                            store.deleteSession(id: session.id)
                        }

                    case .completedExternal:
                        Button("In Apple Health anzeigen") {}
                    }
                    Button("Abbrechen", role: .cancel) {}
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: 8) {
                        GymCircularProfileButton {
                            showingProfileAndSettings = true
                        }

                        if !Calendar.current.isDateInToday(selectedDate) {
                            Button("Heute") {
                                HapticFeedback.light()
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedDate = Date()
                                }
                            }
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(GymTheme.strongBlue)
                        }
                    }
                }

                ToolbarItemGroup(placement: .topBarTrailing) {
                    Menu {
                        Button(action: { showingMeasurements = true }) {
                            Label("Koerpermasse & Messungen", systemImage: "ruler.fill")
                        }
                        Button(action: { showingDeepMuscleReport = true }) {
                            Label("Tiefen-Muskel-Report", systemImage: "figure.strengthtraining.traditional")
                        }
                        Button(action: { showingAthleticStandardGraph = true }) {
                            Label("Leistungsstandards", systemImage: "chart.line.uptrend.xyaxis")
                        }
                        Button(action: {
                            healthService.fetchAllHealthData()
                            growceryService.refreshData()
                        }) {
                            Label("HealthKit synchronisieren", systemImage: "arrow.triangle.2.circlepath")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundColor(GymTheme.textSecondary)
                    }

                    Button(action: {
                        HapticFeedback.mechanicalClick()
                        showingStartWorkoutSheet = true
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(GymTheme.bg)
                            .frame(width: 28, height: 28)
                            .background(Circle().fill(GymTheme.strongBlue))
                    }
                    .accessibilityLabel("Workout starten")
                }
            }
        }
    }

    // MARK: - Profile & Header Section
    private var profileHeaderSection: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(currentDateString().uppercased())
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(GymTheme.textPrimary)
                Text(Calendar.current.isDateInToday(selectedDate) ? "HEUTE • REGELTRAINING" : "\(formattedFullDate(selectedDate).uppercased())")
                    .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                    .foregroundColor(GymTheme.strongBlue)
                    .tracking(0.6)
            }
            Spacer()
            WeatherHeaderSection()
        }
        .padding(.top, 4)
    }

    // MARK: - Measured Weight Header (Waage-Scan & Messung)
    private func measuredWeightHeader(isExpanded: Bool) -> some View {
        let dayWeight = store.measurements.first(where: {
            $0.type == .weight && Calendar.current.isDate($0.date, inSameDayAs: selectedDate)
        })?.value
        let latestWeight = store.latestMeasurement(for: .weight)?.value

        return HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(Calendar.current.isDateInToday(selectedDate) ? "HEUTE • KÖRPERGEWICHT" : "\(formattedDay(selectedDate).uppercased()) • GEWICHT")
                        .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                        .tracking(0.8)
                        .foregroundColor(GymTheme.cyanAccent)

                    if dayWeight != nil {
                        Text("ERFASST")
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(GymTheme.sageGreen.opacity(0.2))
                            .foregroundColor(GymTheme.sageGreen)
                            .cornerRadius(3)
                    }
                }

                if let weight = dayWeight {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(String(format: "%.1f", weight).replacingOccurrences(of: ".", with: ","))
                            .font(.system(size: 20, weight: .bold, design: .monospaced))
                            .foregroundColor(GymTheme.textPrimary)
                        Text("kg")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(GymTheme.textSecondary)
                    }
                } else if let fallback = latestWeight {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(String(format: "%.1f", fallback).replacingOccurrences(of: ".", with: ","))
                            .font(.system(size: 18, weight: .semibold, design: .monospaced))
                            .foregroundColor(GymTheme.textSecondary)
                        Text("kg (letzter Stand)")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(GymTheme.textMuted)
                    }
                } else {
                    Text("Noch kein Gewicht erfasst")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(GymTheme.textMuted)
                }
            }

            Spacer()
        }
    }

    private func deleteUnifiedWorkout(_ item: UnifiedDayWorkoutItem) {
        switch item.source {
        case .planned(let planned):
            store.removePlannedWorkout(id: planned.id)
        case .completedGrow(let session):
            store.deleteSession(id: session.id)
        case .completedExternal:
            break
        }
        HapticFeedback.light()
    }

    // MARK: - Tapable Calendar Selected Date Detail (Notes + Workouts on that day)
    private var selectedDateDetailCard: some View {
        let daySessions = store.sessions.filter { Calendar.current.isDate($0.startTime, inSameDayAs: selectedDate) }
        let dayExternal = healthService.syncedWorkouts.filter { ext in
            Calendar.current.isDate(ext.startDate, inSameDayAs: selectedDate) &&
            !daySessions.contains { abs($0.startTime.timeIntervalSince(ext.startDate)) < 1800 }
        }
        let dayPlanned = store.plannedWorkouts.filter { Calendar.current.isDate($0.plannedDate, inSameDayAs: selectedDate) }
        let totalCount = daySessions.count + dayExternal.count
        let isToday = Calendar.current.isDateInToday(selectedDate)

        return Group {
            if !isTagesdetailExpanded {
                VStack(spacing: 10) {
                    measuredWeightHeader(isExpanded: false)

                    Divider().background(GymTheme.borderSubtle)

                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isTagesdetailExpanded = true
                        }
                        HapticFeedback.light()
                    } label: {
                        HStack {
                            Text("\(formattedFullDate(selectedDate)) • \(totalCount) Einheiten • Tippen zum Öffnen")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(GymTheme.textSecondary)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(GymTheme.strongBlue)
                        }
                    }
                    .buttonStyle(.plain)
                }
                .wellnessCard(borderColor: GymTheme.border, cornerRadius: 18)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    // Header with Measured Weight & Collapse Chevron
                    HStack(alignment: .top) {
                        measuredWeightHeader(isExpanded: true)

                        if !isToday {
                            Button("Heute") {
                                selectedDate = Date()
                                HapticFeedback.light()
                            }
                            .font(.caption2)
                            .foregroundColor(GymTheme.strongBlue)
                            .padding(.leading, 4)
                        }

                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isTagesdetailExpanded = false
                            }
                            HapticFeedback.light()
                        } label: {
                            Image(systemName: "chevron.up")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(GymTheme.textMuted)
                                .padding(4)
                        }
                    }

                    // Unified Day Workouts Section (Geplante & Absolvierte Einheiten vereint)
                    let unifiedItems: [UnifiedDayWorkoutItem] = {
                        var list: [UnifiedDayWorkoutItem] = []
                        // 1. Absolvierte Grow Einheiten
                        for session in daySessions {
                            list.append(UnifiedDayWorkoutItem(
                                id: "session-\(session.id.uuidString)",
                                title: session.title,
                                subtitle: "\(session.durationMinutes) min • \(session.exercises.count) Uebungen • \(Int(session.totalTonnageKg)) kg Tonnage",
                                isCompleted: true,
                                date: session.startTime,
                                source: .completedGrow(session)
                            ))
                        }
                        // 2. Absolvierte externe Einheiten (Apple Health / Google Fit)
                        for ext in dayExternal {
                            list.append(UnifiedDayWorkoutItem(
                                id: "ext-\(ext.id.uuidString)",
                                title: ext.title,
                                subtitle: "\(ext.durationFormatted) • \(Int(ext.caloriesBurned)) kcal (Apple Health)",
                                isCompleted: true,
                                date: ext.startDate,
                                source: .completedExternal(ext)
                            ))
                        }
                        // 3. Geplante Einheiten (sofern nicht bereits als identische Session gelistet)
                        for planned in dayPlanned {
                            let alreadyListed = daySessions.contains { s in
                                s.title == planned.title && abs(s.startTime.timeIntervalSince(planned.plannedDate)) < 7200
                            }
                            if !alreadyListed {
                                list.append(UnifiedDayWorkoutItem(
                                    id: "planned-\(planned.id.uuidString)",
                                    title: planned.title,
                                    subtitle: planned.programName.isEmpty ? "\(planned.exerciseNames.count) Uebungen • Geplant" : "\(planned.programName) • Geplant",
                                    isCompleted: planned.isCompleted,
                                    date: planned.plannedDate,
                                    source: .planned(planned)
                                ))
                            }
                        }
                        return list
                    }()

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "calendar.badge.clock")
                                .font(.caption2)
                                .foregroundColor(GymTheme.strongBlue)
                            Text("EINHEITEN (TAGESPLAN & VERLAUF) (\(unifiedItems.count))")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(GymTheme.textMuted)
                            Spacer()

                            Button {
                                showingPlanWorkoutSheet = true
                                HapticFeedback.light()
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 9, weight: .bold))
                                    Text("Planen / Hinzufuegen")
                                        .font(.system(size: 10, weight: .bold))
                                }
                                .foregroundColor(GymTheme.strongBlue)
                            }
                        }

                        if unifiedItems.isEmpty {
                            Button {
                                showingPlanWorkoutSheet = true
                                HapticFeedback.light()
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "calendar.badge.plus")
                                        .font(.system(size: 13))
                                        .foregroundColor(GymTheme.strongBlue)
                                    Text("Keine Einheit fuer diesen Tag • Tippen zum Planen / Hinzufuegen")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(GymTheme.textMuted)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 10))
                                        .foregroundColor(GymTheme.textMuted)
                                }
                                .padding(12)
                                .background(GymTheme.surface)
                                .cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(GymTheme.borderSubtle, lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        } else {
                            VStack(spacing: 8) {
                                ForEach(unifiedItems) { item in
                                    HStack(spacing: 8) {
                                        Button {
                                            switch item.source {
                                            case .planned(let planned):
                                                selectedPlannedWorkoutForPreview = planned
                                            case .completedGrow(let session):
                                                selectedCompletedSessionForDetail = session
                                            case .completedExternal:
                                                activeWorkoutMenuTarget = item
                                            }
                                            HapticFeedback.light()
                                        } label: {
                                            HStack(spacing: 10) {
                                                if item.isCompleted {
                                                    ZStack {
                                                        Circle()
                                                            .fill(GymTheme.sageGreen)
                                                            .frame(width: 22, height: 22)
                                                        Image(systemName: "checkmark")
                                                            .font(.system(size: 10, weight: .bold))
                                                            .foregroundColor(.white)
                                                    }
                                                    .frame(width: 24)
                                                } else {
                                                    Circle()
                                                        .stroke(GymTheme.strongBlue, lineWidth: 1.5)
                                                        .frame(width: 18, height: 18)
                                                        .frame(width: 24)
                                                }

                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(item.title)
                                                        .font(.system(size: 12, weight: .semibold))
                                                        .foregroundColor(item.isCompleted ? GymTheme.textSecondary : GymTheme.textPrimary)
                                                        .strikethrough(item.isCompleted)
                                                    Text(item.subtitle)
                                                        .font(.system(size: 10))
                                                        .foregroundColor(GymTheme.textSecondary)
                                                }

                                                Spacer()
                                            }
                                        }
                                        .buttonStyle(.plain)

                                        if case .planned(let planned) = item.source, !item.isCompleted {
                                            Button {
                                                HapticFeedback.medium()
                                                store.startWorkout(from: planned)
                                                showingActiveWorkout = true
                                            } label: {
                                                HStack(spacing: 4) {
                                                    Image(systemName: "play.fill")
                                                        .font(.system(size: 9))
                                                    Text("Starten")
                                                        .font(.system(size: 11, weight: .bold))
                                                }
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 6)
                                                .background(GymTheme.sageGreen)
                                                .foregroundColor(.white)
                                                .cornerRadius(6)
                                            }
                                            .buttonStyle(.plain)
                                        }

                                        if case .completedExternal = item.source {
                                            // External HealthKit workouts
                                        } else {
                                            Button {
                                                workoutToDelete = item
                                                showingDeleteWorkoutDialog = true
                                                HapticFeedback.light()
                                            } label: {
                                                Image(systemName: "trash")
                                                    .font(.system(size: 11))
                                                    .foregroundColor(GymTheme.terracotta)
                                                    .padding(6)
                                            }
                                            .buttonStyle(.plain)
                                            .accessibilityLabel("Workout löschen")
                                        }

                                        Button {
                                            activeWorkoutMenuTarget = item
                                            HapticFeedback.light()
                                        } label: {
                                            Image(systemName: "ellipsis")
                                                .font(.system(size: 11))
                                                .foregroundColor(GymTheme.textMuted)
                                                .padding(6)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding(10)
                                    .background(GymTheme.surface)
                                    .cornerRadius(8)
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(GymTheme.borderSubtle, lineWidth: 1))
                                }
                            }
                        }
                    }
                }
                .wellnessCard(borderColor: GymTheme.border, cornerRadius: 18)
            }
        }
    }




    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "de_DE")
        f.dateFormat = "EEEE"
        return f
    }()

    private static let fullDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "de_DE")
        f.dateFormat = "d. MMMM yyyy"
        return f
    }()

    private func formattedDay(_ date: Date) -> String {
        return Self.dayFormatter.string(from: date)
    }

    private func formattedFullDate(_ date: Date) -> String {
        return Self.fullDateFormatter.string(from: date)
    }

    private func advanceDate(by days: Int) {
        if let newDate = Calendar.current.date(byAdding: .day, value: days, to: selectedDate) {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedDate = newDate
            }
            HapticFeedback.selection()
        }
    }

    // MARK: - Active Session Banner
    private var activeSessionBanner: some View {
        Button {
            showingActiveWorkout = true
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(store.activeSession?.title ?? "Training")
                        .font(.headline)
                        .foregroundColor(GymTheme.textPrimary)
                    Text("Laufende Einheit fortsetzen")
                        .font(.caption)
                        .foregroundColor(GymTheme.terracotta)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(GymTheme.sageGreen)
            }
            .wellnessCard(borderColor: GymTheme.terracotta.opacity(0.6), cornerRadius: 18)
        }
    }

    // MARK: - Biomechanik, Körpermaße & Leistungsstandard Section (Migrated from Profile)
    private var biomechanicsAndStandardsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("BIOMECHANIK, KOERPERMASSE & LEISTUNGSSTANDARD")
                    .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                    .foregroundColor(GymTheme.textMuted)
                    .tracking(0.8)

                Spacer()

                Text("TELEMETRIE")
                    .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                    .foregroundColor(GymTheme.cyanAccent)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(GymTheme.cyanAccent.opacity(0.15))
                    .cornerRadius(4)
            }
            .padding(.horizontal, 2)

            // 1. Körpermaße & Messungen Launcher
            Button {
                showingMeasurements = true
                HapticFeedback.light()
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(GymTheme.surfaceElevated)
                            .frame(width: 40, height: 40)
                        Image(systemName: "ruler.fill")
                            .font(.system(size: 16))
                            .foregroundColor(GymTheme.warmSand)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text("Koerpermasse & Messungen")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(GymTheme.textPrimary)
                            Spacer()
                            Text("\(store.measurements.count) Eintraege")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(GymTheme.textMuted)
                        }
                        Text("Gewicht, Bauchumfang, KFA & V-Taper erfassen")
                            .font(.system(size: 11))
                            .foregroundColor(GymTheme.textSecondary)
                    }

                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundColor(GymTheme.textMuted)
                }
                .padding(12)
                .background(GymTheme.surfaceElevated.opacity(0.8))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(GymTheme.border, lineWidth: 1))
            }
            .buttonStyle(.plain)

            // 2. Tiefenmuskel-Index (TMI) Launcher
            Button {
                showingDeepMuscleReport = true
                HapticFeedback.light()
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(GymTheme.surfaceElevated)
                            .frame(width: 40, height: 40)
                        Image(systemName: "figure.core.training")
                            .font(.system(size: 16))
                            .foregroundColor(GymTheme.terracotta)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text("Tiefenmuskel-Index (TMI)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(GymTheme.textPrimary)
                            Spacer()
                            Text("4-Schichten")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(GymTheme.terracotta)
                        }
                        Text("Transversus, Multifidi, Beckenboden & Rotatoren Status")
                            .font(.system(size: 11))
                            .foregroundColor(GymTheme.textSecondary)
                    }

                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundColor(GymTheme.textMuted)
                }
                .padding(12)
                .background(GymTheme.surfaceElevated.opacity(0.8))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(GymTheme.border, lineWidth: 1))
            }
            .buttonStyle(.plain)

            // 3. Leistungs-Standard & RPG-Gates Launcher
            Button {
                showingAthleticStandardGraph = true
                HapticFeedback.light()
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(GymTheme.surfaceElevated)
                            .frame(width: 40, height: 40)
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 16))
                            .foregroundColor(GymTheme.warmAmber)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text("Leistungs-Standards & Athletik")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(GymTheme.textPrimary)
                            Spacer()
                        }
                        Text("6-Saeulen-Matrix & BFT-Dienstnormen")
                            .font(.system(size: 11))
                            .foregroundColor(GymTheme.textSecondary)
                    }

                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundColor(GymTheme.textMuted)
                }
                .padding(12)
                .background(GymTheme.surfaceElevated.opacity(0.8))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(GymTheme.border, lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 4)
    }





    private static let currentHeaderDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "EEEE, d. MMMM"
        return formatter
    }()

    private func currentDateString() -> String {
        return Self.currentHeaderDateFormatter.string(from: Date())
    }

}

// MARK: - Completed Session Card Subview
struct CompletedSessionCard: View {
    let session: WorkoutSession
    var onTap: (() -> Void)? = nil
    @EnvironmentObject private var store: GymStore

    private var summaryText: String {
        guard !session.exercises.isEmpty else { return "" }
        return session.exercises.map { "\($0.exercise.name) (\($0.completedSetsCount) Sätze)" }.joined(separator: " • ")
    }

    private var statsText: String {
        "\(session.durationMinutes) min • \(Int(session.totalTonnageKg)) kg"
    }

    var body: some View {
        Button {
            onTap?()
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(session.title)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(GymTheme.textPrimary)
                    Spacer()
                    Text(statsText)
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundColor(GymTheme.sageGreen)

                    Button {
                        store.deleteSession(id: session.id)
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 10))
                            .foregroundColor(GymTheme.textMuted)
                            .padding(4)
                    }
                }

                if !summaryText.isEmpty {
                    Text(summaryText)
                        .font(.system(size: 10))
                        .foregroundColor(GymTheme.textSecondary)
                        .lineLimit(2)
                }
            }
            .padding(10)
            .background(GymTheme.surface)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                store.deleteSession(id: session.id)
            } label: {
                Label("Einheit loeschen", systemImage: "trash")
            }
        }
    }
}

// MARK: - External Synced Workout Card Subview (Google Fit / Apple Health)
struct ExternalWorkoutCard: View {
    let item: ExternalWorkoutItem

    private var durationMin: Int {
        max(1, Int(item.durationSeconds / 60.0))
    }

    private var statsText: String {
        var parts: [String] = ["\(durationMin) min"]
        if item.caloriesBurned > 0 {
            parts.append("\(Int(item.caloriesBurned)) kcal")
        }
        if let km = item.distanceMeters, km > 0 {
            parts.append(item.distanceKmFormatted)
        }
        return parts.joined(separator: " • ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                HStack(spacing: 4) {
                    Circle()
                        .fill(GymTheme.strongBlue)
                        .frame(width: 6, height: 6)
                    Text(item.sourceName)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(GymTheme.strongBlue)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(GymTheme.strongBlue.opacity(0.15))
                .cornerRadius(4)

                Text(item.title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(GymTheme.textPrimary)
                    .lineLimit(1)

                Spacer()

                Text(statsText)
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundColor(GymTheme.sageGreen)

                Button {
                    HealthKitService.shared.removeSyncedWorkout(id: item.id)
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 10))
                        .foregroundColor(GymTheme.textMuted)
                        .padding(4)
                }
            }

            HStack {
                Text(item.activityType)
                    .font(.system(size: 10))
                    .foregroundColor(GymTheme.textSecondary)

                Spacer()

                Text(item.startDate.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(GymTheme.textMuted)
            }
        }
        .padding(10)
        .background(GymTheme.surface)
        .cornerRadius(8)
        .contextMenu {
            Button(role: .destructive) {
                HealthKitService.shared.removeSyncedWorkout(id: item.id)
            } label: {
                Label("Externe Einheit entfernen", systemImage: "trash")
            }
        }
    }
}

// MARK: - Quick Start Modal Triggered by FAB (+)
public enum TrainingDiscipline: String, CaseIterable, Identifiable {
    case krafttraining = "Kraft"
    case calisthenics = "Calisthenics"
    case cardio = "Cardio"
    case stretching = "Stretching"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .krafttraining: return "figure.strengthtraining.traditional"
        case .calisthenics: return "figure.gymnastics"
        case .cardio: return "figure.run"
        case .stretching: return "figure.cooldown"
        }
    }

    public var accentColor: Color {
        switch self {
        case .krafttraining: return GymTheme.strongBlue
        case .calisthenics: return GymTheme.accentGold
        case .cardio: return GymTheme.terracotta
        case .stretching: return GymTheme.sageGreen
        }
    }

    public func matches(template: WorkoutTemplate) -> Bool {
        let text = "\(template.category) \(template.folderName) \(template.name)".lowercased()
        switch self {
        case .krafttraining:
            return text.contains("kraft") || text.contains("hypertrophie") || text.contains("push") || text.contains("pull") || text.contains("leg") || text.contains("bank") || (!text.contains("calisthenics") && !text.contains("cardio") && !text.contains("stretching") && !text.contains("dehn"))
        case .calisthenics:
            return text.contains("calisthenics") || text.contains("bodyweight") || text.contains("eigengewicht") || text.contains("stube")
        case .cardio:
            return text.contains("cardio") || text.contains("ausdauer") || text.contains("lauf") || text.contains("running") || text.contains("bike") || text.contains("erg")
        case .stretching:
            return text.contains("stretch") || text.contains("dehn") || text.contains("mobil") || text.contains("reha") || text.contains("yoga")
        }
    }
}

public enum EquipmentModeFilter: String, CaseIterable, Identifiable {
    case all = "Alle"
    case withEquipment = "Mit Equipment"
    case withoutEquipment = "Ohne Equipment"

    public var id: String { rawValue }

    public func matches(template: WorkoutTemplate) -> Bool {
        switch self {
        case .all: return true
        case .withEquipment:
            let isWithout = template.items.allSatisfy { $0.targetWeightKg == 0 && ($0.exercise.equipment == .bodyweight || $0.exercise.equipment == .roomFurniture || $0.exercise.equipment == .matArea || $0.exercise.equipment == .stretchingMat) }
            return !isWithout
        case .withoutEquipment:
            let isWithout = template.items.allSatisfy { $0.targetWeightKg == 0 && ($0.exercise.equipment == .bodyweight || $0.exercise.equipment == .roomFurniture || $0.exercise.equipment == .matArea || $0.exercise.equipment == .stretchingMat) }
            return isWithout
        }
    }
}

struct StartWorkoutQuickSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: GymStore
    @StateObject private var growceryService = GrowcerySyncService.shared

    @State private var exerciseSearchText: String = ""
    @State private var inspectingExercise: Exercise? = nil
    @State private var selectedLocationMode: TrainingLocationMode = .gymWithWeights
    @State private var selectedDiscipline: TrainingDiscipline = .krafttraining
    @State private var selectedEquipmentMode: EquipmentModeFilter = .all

    private var recommendation: DailyWorkoutRecommendation {
        OlympicCoachEngine.shared.generateDailyRecommendation(
            sessionsHistory: store.allSessionsWithExternal,
            templates: store.templates,
            growcerySync: growceryService.syncState,
            locationMode: selectedLocationMode,
            userPreferences: store.userPreferences
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                GymTheme.bg.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Section 0: Instant Exercise Catalog Search
                        exerciseSearchSection

                        // Section 1: Olympic Coach Daily Recommendation & Location Mode
                        coachRecommendationSection

                        // Section 2: Disciplines & Equipment Filtered Templates
                        disciplineAndEquipmentSection

                        // Section 3: Free Session
                        freeSessionSection

                        Spacer(minLength: 40)
                    }
                    .padding(16)
                }
                .scrollDismissesKeyboard(.interactively)
                .dismissKeyboardOnTap()
            }
            .navigationTitle("Workout starten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Abbrechen") { dismiss() }
                        .foregroundColor(GymTheme.textMuted)
                }
            }
            .sheet(item: $inspectingExercise) { ex in
                ExerciseDetailSheet(exercise: ex)
                    .environmentObject(store)
            }
            .onAppear {
                if let idx = CommandLine.arguments.firstIndex(of: "-SearchExercise"), idx + 1 < CommandLine.arguments.count {
                    let q = CommandLine.arguments[idx + 1]
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        self.exerciseSearchText = q
                    }
                }
                if let idx = CommandLine.arguments.firstIndex(of: "-InspectExercise"), idx + 1 < CommandLine.arguments.count {
                    let q = CommandLine.arguments[idx + 1]
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        self.inspectingExercise = store.exercises.first(where: { $0.name.localizedCaseInsensitiveContains(q) })
                    }
                }
            }
        }
    }

    // MARK: - 0. Exercise Catalog Search Section
    private var exerciseSearchSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("UEBUNG SUCHEN & STARTEN")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .tracking(1.0)
                .foregroundColor(GymTheme.textMuted)

            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(GymTheme.textMuted)
                TextField("Uebung im Katalog suchen (z. B. Latziehen, RDL)...", text: $exerciseSearchText)
                    .font(.system(size: 13))
                    .foregroundColor(GymTheme.textPrimary)
                if !exerciseSearchText.isEmpty {
                    Button {
                        exerciseSearchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(GymTheme.textMuted)
                    }
                }
            }
            .padding(10)
            .background(GymTheme.surfaceElevated)
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(GymTheme.border, lineWidth: 1))

            if !exerciseSearchText.trimmingCharacters(in: .whitespaces).isEmpty {
                let matches = store.exercises.filter {
                    $0.name.localizedCaseInsensitiveContains(exerciseSearchText) ||
                    $0.targetMuscle.rawValue.localizedCaseInsensitiveContains(exerciseSearchText)
                }.prefix(6)

                if matches.isEmpty {
                    Text("Keine Uebung gefunden")
                        .font(.caption)
                        .foregroundColor(GymTheme.textMuted)
                        .padding(.vertical, 6)
                } else {
                    VStack(spacing: 6) {
                        ForEach(matches) { ex in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(ex.name)
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(GymTheme.textPrimary)
                                    Text("\(ex.targetMuscle.rawValue) • \(ex.equipment.rawValue)")
                                        .font(.system(size: 10))
                                        .foregroundColor(GymTheme.textSecondary)
                                }
                                Spacer()

                                Button {
                                    inspectingExercise = ex
                                } label: {
                                    Image(systemName: "info.circle")
                                        .font(.system(size: 14))
                                        .foregroundColor(GymTheme.cyanAccent)
                                        .padding(6)
                                }
                                .buttonStyle(.plain)

                                Button {
                                    store.startSingleExerciseWorkout(exercise: ex)
                                    HapticFeedback.medium()
                                    dismiss()
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "play.fill")
                                            .font(.system(size: 10, weight: .bold))
                                        Text("Start")
                                            .font(.system(size: 11, weight: .bold))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(GymTheme.strongBlue)
                                    .cornerRadius(6)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(8)
                            .background(GymTheme.surfaceElevated)
                            .cornerRadius(8)
                        }
                    }
                }
            }
        }
    }

    // MARK: - 1. Coach Recommendation Section
    private var coachRecommendationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("OLYMPIC COACH EMPFEHLUNG")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1.0)
                        .foregroundColor(GymTheme.sageGreen)
                    Text(recommendation.recommendedFocus)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(GymTheme.textPrimary)
                }
                Spacer()
                Text(recommendation.readinessLabel)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(GymTheme.sageGreen)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(GymTheme.surfaceElevated))
            }

            // Location & Equipment Mode Switcher
            VStack(alignment: .leading, spacing: 6) {
                Text("TRAININGS-ORT & EQUIPMENT")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(0.8)
                    .foregroundColor(GymTheme.textMuted)

                HStack(spacing: 6) {
                    ForEach(TrainingLocationMode.allCases) { mode in
                        Button {
                            selectedLocationMode = mode
                            HapticFeedback.selection()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: mode.icon)
                                    .font(.system(size: 10))
                                Text(mode.rawValue)
                                    .font(.system(size: 10, weight: selectedLocationMode == mode ? .bold : .medium))
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 4)
                            .background(selectedLocationMode == mode ? GymTheme.strongBlue : GymTheme.surfaceElevated)
                            .foregroundColor(selectedLocationMode == mode ? GymTheme.bg : GymTheme.textSecondary)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(selectedLocationMode == mode ? GymTheme.strongBlue : GymTheme.border, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Rationale
            Text(recommendation.rationale)
                .font(.system(size: 12))
                .foregroundColor(GymTheme.textSecondary)
                .lineSpacing(2)

            // Recommended Exercises List (derived from recommended template)
            let recommendedTemplate: WorkoutTemplate? = {
                if let tplId = recommendation.templateId,
                   let uuid = UUID(uuidString: tplId) {
                    return store.templates.first(where: { $0.id == uuid })
                }
                return nil
            }()

            if let tpl = recommendedTemplate, !tpl.items.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("EMPFOHLENE UEBUNGEN (\(tpl.name.uppercased()))")
                            .font(.system(size: 9, weight: .bold))
                            .tracking(0.8)
                            .foregroundColor(GymTheme.textMuted)
                        Spacer()
                        Text("\(recommendation.targetVolumeSets) Saetze Ziel")
                            .font(.system(size: 9, weight: .semibold, design: .monospaced))
                            .foregroundColor(GymTheme.sageGreen)
                    }

                    ForEach(tpl.items.prefix(4)) { item in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.exercise.name)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(GymTheme.textPrimary)
                                Text("\(item.targetSets) Saetze x \(item.targetReps) Wdh • \(item.exercise.targetMuscle.rawValue)")
                                    .font(.system(size: 10))
                                    .foregroundColor(GymTheme.textSecondary)
                            }
                            Spacer()
                        }
                        .padding(8)
                        .background(GymTheme.surfaceElevated)
                        .cornerRadius(6)
                    }
                }
            } else if !recommendation.laggingMuscles.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("FOKUS-MUSKELGRUPPEN")
                        .font(.system(size: 9, weight: .bold))
                        .tracking(0.8)
                        .foregroundColor(GymTheme.textMuted)

                    Text(recommendation.laggingMuscles.joined(separator: " • "))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(GymTheme.warmSand)
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(GymTheme.surfaceElevated)
                        .cornerRadius(6)
                }
            }

            // Start Button
            Button {
                if let tplId = recommendation.templateId,
                   let uuid = UUID(uuidString: tplId),
                   let tpl = store.templates.first(where: { $0.id == uuid }) {
                    store.startWorkout(from: tpl)
                } else {
                    store.startWorkout()
                }
                HapticFeedback.medium()
                dismiss()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "play.fill")
                    Text("Empfohlenes Training starten")
                }
                .font(.system(size: 14, weight: .bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(GymTheme.strongBlue)
                .foregroundColor(GymTheme.bg)
                .cornerRadius(10)
            }
            .padding(.top, 4)
        }
        .somaCard(borderColor: GymTheme.sageGreen.opacity(0.4))
    }

    // MARK: - 2. Discipline & Equipment Filtered Section
    private var disciplineAndEquipmentSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("TRAININGS-KATEGORIE & EQUIPMENT")
                .font(.system(size: 10, weight: .bold))
                .tracking(1.0)
                .foregroundColor(GymTheme.textMuted)

            // Discipline Selector
            HStack(spacing: 6) {
                ForEach(TrainingDiscipline.allCases) { discipline in
                    Button {
                        selectedDiscipline = discipline
                        HapticFeedback.selection()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: discipline.icon)
                                .font(.system(size: 10))
                            Text(discipline.rawValue)
                                .font(.system(size: 10, weight: selectedDiscipline == discipline ? .bold : .medium))
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 4)
                        .background(selectedDiscipline == discipline ? discipline.accentColor : GymTheme.surfaceElevated)
                        .foregroundColor(selectedDiscipline == discipline ? .white : GymTheme.textSecondary)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(selectedDiscipline == discipline ? discipline.accentColor : GymTheme.border, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            // Equipment Mode Selector
            HStack(spacing: 6) {
                ForEach(EquipmentModeFilter.allCases) { eqMode in
                    Button {
                        selectedEquipmentMode = eqMode
                        HapticFeedback.selection()
                    } label: {
                        Text(eqMode.rawValue)
                            .font(.system(size: 10, weight: selectedEquipmentMode == eqMode ? .bold : .medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(selectedEquipmentMode == eqMode ? GymTheme.surfaceSubtle : GymTheme.surfaceElevated)
                            .foregroundColor(selectedEquipmentMode == eqMode ? GymTheme.textPrimary : GymTheme.textMuted)
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(selectedEquipmentMode == eqMode ? GymTheme.borderFocused : GymTheme.border, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            // Filtered Templates List
            let filteredTemplates = store.templates.filter { tpl in
                selectedDiscipline.matches(template: tpl) && selectedEquipmentMode.matches(template: tpl)
            }

            if filteredTemplates.isEmpty {
                VStack(spacing: 6) {
                    Text("Keine Vorlagen fuer diese Auswahl")
                        .font(.caption)
                        .foregroundColor(GymTheme.textMuted)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(GymTheme.surface)
                .cornerRadius(10)
            } else {
                VStack(spacing: 8) {
                    ForEach(filteredTemplates) { template in
                        Button {
                            store.startWorkout(from: template)
                            HapticFeedback.light()
                            dismiss()
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(template.name)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(GymTheme.textPrimary)
                                    Text("\(template.items.count) Uebungen • \(template.category)")
                                        .font(.system(size: 10))
                                        .foregroundColor(GymTheme.textSecondary)
                                }
                                Spacer()
                                Image(systemName: "play.fill")
                                    .font(.caption2)
                                    .foregroundColor(GymTheme.textMuted)
                            }
                            .padding(10)
                            .background(GymTheme.surfaceElevated)
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - 4. Free Session Section
    private var freeSessionSection: some View {
        Button {
            store.startWorkout()
            HapticFeedback.medium()
            dismiss()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Leeres Workout starten")
                        .font(.headline)
                        .foregroundColor(GymTheme.bg)
                    Text("Freies Satz- & Uebungstracking ohne Schablone")
                        .font(.caption)
                        .foregroundColor(GymTheme.bg.opacity(0.85))
                }
                Spacer()
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .foregroundColor(GymTheme.bg)
            }
            .padding(16)
            .background(GymTheme.strongBlue)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Weather Header Section
public struct WeatherHeaderSection: View {
    @ObservedObject private var weatherService = WeatherService.shared

    public init() {}

    public var body: some View {
        if let weather = weatherService.currentWeather {
            Button(action: {
                HapticFeedback.light()
                weatherService.refresh()
            }) {
                HStack(spacing: 5) {
                    Image(systemName: weather.sfSymbolName)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(GymTheme.sageGreen)

                    Text("\(Int(round(weather.temperature)))°")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(GymTheme.textPrimary)

                    Text("H:\(Int(round(weather.highTemp)))° T:\(Int(round(weather.lowTemp)))°")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundColor(GymTheme.textSecondary)

                    if weather.rainProbability > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "drop.fill")
                                .font(.system(size: 7))
                                .foregroundColor(GymTheme.sageLight)
                            Text("\(weather.rainProbability)%")
                                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                                .foregroundColor(GymTheme.sageLight)
                        }
                    }
                }
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(RoundedRectangle(cornerRadius: 7).fill(GymTheme.surfaceElevated))
            }
            .buttonStyle(PlainButtonStyle())
        } else {
            Button(action: {
                HapticFeedback.light()
                weatherService.refresh()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "cloud.sun.fill")
                        .font(.system(size: 10))
                        .foregroundColor(GymTheme.textMuted)
                    Text("--°C")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(GymTheme.textMuted)
                }
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(RoundedRectangle(cornerRadius: 7).fill(GymTheme.surfaceElevated))
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}
