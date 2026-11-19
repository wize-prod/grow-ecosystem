import SwiftUI
import GrowCore

// MARK: - TodayUnifiedView (Merged Grow: Gym + Nutrition Ecosystem)
public struct TodayUnifiedView: View {
    @EnvironmentObject private var gymStore: GymStore
    @ObservedObject private var localStore = LocalStore.shared
    @ObservedObject private var healthService = HealthKitService.shared
    @ObservedObject private var userAccount = UserAccountService.shared

    @State private var selectedDate: Date = Date()
    @State private var isBalanceExpanded: Bool = true
    @State private var isWorkoutExpanded: Bool = true
    @State private var isFoodExpanded: Bool = true
    @State private var isShoppingExpanded: Bool = true
    @State private var showAllSupplements: Bool = false

    // Sheets
    @State private var showingGlobalSearch: Bool = false
    @State private var showingProfileAndSettings: Bool = false
    @State private var showingBiomechanikSheet: Bool = false
    @State private var showingMeasurementsSheet: Bool = false
    @State private var showingQuickAddMeal: Bool = false
    @State private var showingReceiptScanner: Bool = false
    @State private var showingSupplementsManagement: Bool = false
    @State private var showingPlanWorkout: Bool = false
    @State private var showingStartWorkout: Bool = false
    @State private var showingTagesbilanzDetail: Bool = false
    @State private var selectedPlannedWorkoutForPreview: PlannedWorkoutItem? = nil
    @State private var selectedCompletedSessionForDetail: WorkoutSession? = nil
    @State private var showingActiveWorkout: Bool = false
    @State private var inspectingMealLog: MealLogEntry? = nil

    // Shopping inline quick add
    @State private var newShoppingItemName: String = ""

    public init() {}

    private var dayKcal: Double {
        localStore.kcal(for: selectedDate)
    }

    private var dayProtein: Double {
        localStore.protein(for: selectedDate)
    }

    private var dayCarbs: Double {
        localStore.carbs(for: selectedDate)
    }

    private var dayFat: Double {
        localStore.fat(for: selectedDate)
    }

    private var activeBurnKcal: Double {
        let burn = healthService.activeEnergyBurnedToday
        return burn > 0 ? burn : 420.0
    }

    private var baseKcalTarget: Double { 1900.0 }
    private var baseProteinTarget: Double { 160.0 }
    private var baseCarbsTarget: Double { 200.0 }
    private var baseFatTarget: Double { 55.0 }

    // Dynamic targets: Base targets + burned calories dynamically expanding the budget
    private var dynamicKcalTarget: Double {
        baseKcalTarget + activeBurnKcal
    }

    private var dynamicProteinTarget: Double {
        let delta = min(25.0, (activeBurnKcal / 400.0) * 10.0)
        return baseProteinTarget + delta
    }

    private var dynamicCarbsTarget: Double {
        let delta = (activeBurnKcal * 0.60) / 4.0
        return baseCarbsTarget + delta
    }

    private var dynamicFatTarget: Double {
        let delta = (activeBurnKcal * 0.20) / 9.0
        return baseFatTarget + delta
    }

    private var proteinRingRatio: Double {
        min(1.0, max(0.005, dayProtein / max(1.0, dynamicProteinTarget)))
    }

    private var carbsRingRatio: Double {
        min(1.0, max(0.005, dayCarbs / max(1.0, dynamicCarbsTarget)))
    }

    private var fatRingRatio: Double {
        min(1.0, max(0.005, dayFat / max(1.0, dynamicFatTarget)))
    }

    public var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                GymTheme.bg.ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
                        // 1. Date Header & Fast Navigation
                        headerDateBar

                        // 2. Active Workout Session Banner (if running)
                        if gymStore.activeSession != nil {
                            activeWorkoutBanner
                        }

                        // 3. Section 1: Tagesbilanz (Konzentrische Ringe, Kalorien mittig, Makrozahlen)
                        tagesbilanzSection

                        // 4. Section 2: Training & Workout (Split, Übungen, Sätze)
                        trainingWorkoutSection

                        // 5. Section 3: Food + Supplement Log (Mahlzeiten & Zirkadianer Plan)
                        foodAndSupplementSection

                        // 6. Section 4: Biomechanik, Körpermaße & Messungen (am Seitenende)
                        quickActionButtonsRow

                        Spacer(minLength: 90)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .frame(maxWidth: 720)
                    .frame(maxWidth: .infinity)
                }
                .scrollDismissesKeyboard(.interactively)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 25)
                        .onEnded { value in
                            let hDiff = value.translation.width
                            let vDiff = value.translation.height
                            if abs(hDiff) > abs(vDiff) * 1.3 && abs(hDiff) > 35 {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    if hDiff < 0 {
                                        advanceDate(by: 1)
                                    } else {
                                        advanceDate(by: -1)
                                    }
                                }
                            }
                        }
                )

                // Schwebende Aktions-Buttons unten rechts (+ Button über Wasser-Tracker)
                VStack(spacing: 12) {
                    floatingQuickAddMenu
                    NutriCircularWaterButton()
                }
                .padding(.trailing, 20)
                .padding(.bottom, 24)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    GymCircularProfileButton {
                        showingProfileAndSettings = true
                    }
                }

                ToolbarItem(placement: .principal) {
                    VStack(spacing: 1) {
                        Text("HEUTE")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(GymTheme.textPrimary)
                            .tracking(0.8)
                        Text(formatHeaderDate(selectedDate))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(GymTheme.textSecondary)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        HapticFeedback.light()
                        showingGlobalSearch = true
                    }) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(GymTheme.textPrimary)
                            .padding(8)
                            .background(Circle().fill(GymTheme.surfaceElevated))
                    }
                    .buttonStyle(.plain)
                }
            }
            .sheet(isPresented: $showingGlobalSearch) {
                GrowUnifiedSearchView()
            }
            .sheet(isPresented: $showingProfileAndSettings) {
                EcosystemProfileAndSettingsSheet()
                    .environmentObject(gymStore)
            }
            .sheet(isPresented: $showingTagesbilanzDetail) {
                let profile = localStore.dailyProfile(for: selectedDate)
                NutritionDetailSheet(
                    title: "Tagesbilanz & Mikronährstoffe",
                    subtitle: formatHeaderDate(selectedDate),
                    storeName: "Ecosystem Ernährung",
                    packSizeText: "\(localStore.logs(for: selectedDate).count) Mahlzeiten",
                    priceText: nil,
                    kcal: dayKcal,
                    protein: dayProtein,
                    carbs: dayCarbs,
                    fat: dayFat,
                    fiber: profile.fiber ?? 0.0,
                    profile: profile
                )
            }
            .sheet(item: $selectedPlannedWorkoutForPreview) { planned in
                WorkoutPreviewSheet(plannedItem: planned) {
                    gymStore.startWorkout(from: planned)
                    showingActiveWorkout = true
                }
                .environmentObject(gymStore)
            }
            .sheet(item: $selectedCompletedSessionForDetail) { session in
                CompletedWorkoutDetailSheet(session: session)
                    .environmentObject(gymStore)
            }
            .sheet(isPresented: $showingActiveWorkout) {
                ActiveWorkoutView()
                    .environmentObject(gymStore)
            }
            .sheet(isPresented: $showingBiomechanikSheet) {
                NavigationStack {
                    AnatomicalMuscleMapView()
                }
                .environmentObject(gymStore)
            }
            .sheet(isPresented: $showingMeasurementsSheet) {
                NavigationStack {
                    MeasurementsView()
                }
                .environmentObject(gymStore)
            }
            .sheet(isPresented: $showingQuickAddMeal) {
                QuickAddMealSheet(targetDate: selectedDate, store: localStore) { item in
                    localStore.depleteAndLog(item: item, amount: 100.0, targetDate: selectedDate)
                }
            }
            .sheet(isPresented: $showingReceiptScanner) {
                ReceiptScannerView()
            }
            .sheet(isPresented: $showingSupplementsManagement) {
                CircadianSupplementsManagementSheet(selectedDate: selectedDate) {
                    showingSupplementsManagement = false
                }
                .environmentObject(localStore)
            }
            .sheet(isPresented: $showingPlanWorkout) {
                PlanWorkoutSheet(targetDate: selectedDate)
                    .environmentObject(gymStore)
            }
            .sheet(item: $inspectingMealLog) { log in
                EditMealLogSheet(log: log, store: localStore)
            }
        }
    }

    // MARK: - 1. Date Header Bar
    private var headerDateBar: some View {
        HStack {
            Button(action: { advanceDate(by: -1) }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(GymTheme.textSecondary)
                    .padding(8)
                    .background(Circle().fill(GymTheme.surfaceElevated))
            }
            .buttonStyle(.plain)

            Spacer()

            if !Calendar.current.isDateInToday(selectedDate) {
                Button("Zu Heute springen") {
                    HapticFeedback.light()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedDate = Date()
                    }
                }
                .font(.system(size: 11.5, weight: .bold, design: .monospaced))
                .foregroundColor(GymTheme.sageGreen)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Capsule().fill(GymTheme.surfaceElevated))
            } else {
                Text("Heutiger Fokus")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(GymTheme.textMuted)
            }

            Spacer()

            Button(action: { advanceDate(by: 1) }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(GymTheme.textSecondary)
                    .padding(8)
                    .background(Circle().fill(GymTheme.surfaceElevated))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - 2. Quick Action Buttons Row (Biomechanik & Messungen)
    private var quickActionButtonsRow: some View {
        HStack(spacing: 8) {
            Button(action: {
                HapticFeedback.light()
                showingBiomechanikSheet = true
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "figure.walk.motion")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(GymTheme.terracotta)
                    Text("Biomechanik")
                        .font(.system(size: 11.5, weight: .bold))
                        .foregroundColor(GymTheme.textPrimary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(GymTheme.surfaceElevated)
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(GymTheme.border, lineWidth: 1))
            }
            .buttonStyle(.plain)

            Button(action: {
                HapticFeedback.light()
                showingMeasurementsSheet = true
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "ruler")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(GymTheme.cyanAccent)
                    Text("Körpermaße & Messungen")
                        .font(.system(size: 11.5, weight: .bold))
                        .foregroundColor(GymTheme.textPrimary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(GymTheme.surfaceElevated)
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(GymTheme.border, lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - 3. Active Workout Banner
    private var activeWorkoutBanner: some View {
        Button(action: {
            HapticFeedback.medium()
            // Navigate back to live workout session
        }) {
            HStack(spacing: 12) {
                Circle()
                    .fill(Color.red)
                    .frame(width: 10, height: 10)
                    .overlay(Circle().stroke(Color.red.opacity(0.4), lineWidth: 4))

                VStack(alignment: .leading, spacing: 2) {
                    Text("AKTIVES TRAINING LÄUFT")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(Color.red)
                    Text(gymStore.activeSession?.title ?? "Einheit läuft")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(GymTheme.textPrimary)
                }

                Spacer()

                Text("Fortsetzen")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(GymTheme.bg)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Color.red))
            }
            .padding(12)
            .background(GymTheme.surfaceElevated)
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.red.opacity(0.5), lineWidth: 1.2))
        }
        .buttonStyle(.plain)
    }

    // MARK: - 4. Section 1: Tagesbilanz (Nutrition & Calorie Balance with Concentric Rings)
    private var tagesbilanzSection: some View {
        Button(action: {
            HapticFeedback.light()
            showingTagesbilanzDetail = true
        }) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Image(systemName: "flame.circle.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(GymTheme.terracotta)
                    Text("TAGESBILANZ")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(GymTheme.textPrimary)
                        .tracking(0.6)

                    Spacer()

                    HStack(spacing: 4) {
                        Text("Vitamine & Details")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(GymTheme.cyanAccent)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(GymTheme.cyanAccent)
                    }
                }

                HStack(spacing: 20) {
                    concentricNutritionRings

                    VStack(alignment: .leading, spacing: 10) {
                        macroNumberRow(
                            title: "Protein",
                            current: dayProtein,
                            target: dynamicProteinTarget,
                            color: GymTheme.ringProteinStart
                        )
                        macroNumberRow(
                            title: "Carbs",
                            current: dayCarbs,
                            target: dynamicCarbsTarget,
                            color: GymTheme.ringCarbsStart
                        )
                        macroNumberRow(
                            title: "Fett",
                            current: dayFat,
                            target: dynamicFatTarget,
                            color: GymTheme.ringFatStart
                        )
                    }
                }
                .padding(.vertical, 4)
            }
            .padding(14)
            .background(GymTheme.surface)
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(GymTheme.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func macroNumberRow(title: String, current: Double, target: Double, color: Color) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(title)
                .font(.system(size: 12.5, weight: .semibold))
                .foregroundColor(GymTheme.textPrimary)
            Spacer()
            Text(String(format: "%.0f / %.0f g", current, target))
                .font(.system(size: 12.5, weight: .bold, design: .monospaced))
                .foregroundColor(color)
        }
    }

    private var concentricNutritionRings: some View {
        ZStack {
            // Background Tracks
            Circle()
                .stroke(GymTheme.ringProteinStart.opacity(0.15), lineWidth: 8)
                .frame(width: 96, height: 96)
            Circle()
                .stroke(GymTheme.ringCarbsStart.opacity(0.15), lineWidth: 8)
                .frame(width: 76, height: 76)
            Circle()
                .stroke(GymTheme.ringFatStart.opacity(0.15), lineWidth: 8)
                .frame(width: 56, height: 56)

            // Protein Ring (Outer)
            Circle()
                .trim(from: 0.0, to: CGFloat(proteinRingRatio))
                .stroke(
                    LinearGradient(
                        colors: [GymTheme.ringProteinStart, GymTheme.ringProteinEnd],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: 96, height: 96)

            // Carbs Ring (Middle)
            Circle()
                .trim(from: 0.0, to: CGFloat(carbsRingRatio))
                .stroke(
                    LinearGradient(
                        colors: [GymTheme.ringCarbsStart, GymTheme.ringCarbsEnd],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: 76, height: 76)

            // Fat Ring (Inner)
            Circle()
                .trim(from: 0.0, to: CGFloat(fatRingRatio))
                .stroke(
                    LinearGradient(
                        colors: [GymTheme.ringFatStart, GymTheme.ringFatEnd],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: 56, height: 56)

            // Center Consumed Calories Display as Numbers
            VStack(spacing: 0) {
                Text(String(format: "%.0f", dayKcal))
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(GymTheme.textPrimary)
                Text("kcal")
                    .font(.system(size: 8, weight: .semibold, design: .monospaced))
                    .foregroundColor(GymTheme.textMuted)
            }
        }
        .frame(width: 104, height: 104)
    }

    private var floatingQuickAddMenu: some View {
        Menu {
            Button(action: {
                HapticFeedback.light()
                showingQuickAddMeal = true
            }) {
                Label("Mahlzeit erfassen (Food Log)", systemImage: "fork.knife")
            }

            Button(action: {
                HapticFeedback.light()
                showingReceiptScanner = true
            }) {
                Label("Beleg scannen (OCR Quittung)", systemImage: "doc.viewfinder")
            }

            Button(action: {
                HapticFeedback.light()
                showingPlanWorkout = true
            }) {
                Label("Workout planen", systemImage: "calendar.badge.plus")
            }

            Button(action: {
                HapticFeedback.medium()
                gymStore.startWorkout()
                showingActiveWorkout = true
            }) {
                Label("Workout jetzt starten", systemImage: "play.circle.fill")
            }

            Button(action: {
                HapticFeedback.light()
                showingSupplementsManagement = true
            }) {
                Label("Supplements verwalten", systemImage: "pills.fill")
            }
        } label: {
            ZStack {
                Circle()
                    .fill(GymTheme.terracotta)
                    .frame(width: 46, height: 46)
                    .shadow(color: Color.black.opacity(0.35), radius: 5, x: 0, y: 2)
                Image(systemName: "plus")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(.plain)
    }

    private var todayMovedTonnage: Double {
        var total: Double = 0.0
        let daySessions = gymStore.sessions.filter { Calendar.current.isDate($0.startTime, inSameDayAs: selectedDate) }
        for s in daySessions {
            for e in s.exercises {
                for set in e.sets where set.isCompleted {
                    total += (set.weightKg * Double(set.reps))
                }
            }
        }
        return total
    }

    private func metricTile(title: String, value: String, unit: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .foregroundColor(GymTheme.textMuted)
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                    .foregroundColor(color)
                Text(unit)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(GymTheme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(GymTheme.surfaceElevated)
        .cornerRadius(8)
    }

    private func macroChip(label: String, val: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(GymTheme.textMuted)
            Text(val)
                .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
        .background(GymTheme.surfaceElevated.opacity(0.6))
        .cornerRadius(6)
    }

    // MARK: - 5. Section 2: Training & Workout (Split & Übungen)
    private var trainingWorkoutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isWorkoutExpanded.toggle()
                }
            }) {
                HStack {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(GymTheme.terracotta)
                    Text("TRAINING & WORKOUT")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(GymTheme.textPrimary)
                        .tracking(0.6)

                    Spacer()

                    let todayItems = workoutsForDate(selectedDate)
                    Text("\(todayItems.count) Einheiten")
                        .font(.system(size: 10.5, weight: .semibold, design: .monospaced))
                        .foregroundColor(GymTheme.textSecondary)

                    Image(systemName: isWorkoutExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(GymTheme.textMuted)
                }
            }
            .buttonStyle(.plain)

            if isWorkoutExpanded {
                let items = workoutsForDate(selectedDate)
                if items.isEmpty {
                    VStack(spacing: 8) {
                        Text("Kein Workout für diesen Tag geplant")
                            .font(.system(size: 12))
                            .foregroundColor(GymTheme.textMuted)

                        Button(action: {
                            showingPlanWorkout = true
                        }) {
                            Label("Workout planen", systemImage: "plus.circle")
                                .font(.system(size: 11.5, weight: .semibold))
                                .foregroundColor(GymTheme.terracotta)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(GymTheme.surfaceElevated)
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                } else {
                    VStack(spacing: 8) {
                        ForEach(items) { item in
                            HStack(spacing: 10) {
                                Button(action: {
                                    HapticFeedback.light()
                                    if let planned = item.plannedItem {
                                        selectedPlannedWorkoutForPreview = planned
                                    } else if let session = item.session {
                                        selectedCompletedSessionForDetail = session
                                    }
                                }) {
                                    HStack(spacing: 10) {
                                        Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                                            .font(.system(size: 15))
                                            .foregroundColor(item.isCompleted ? GymTheme.sageGreen : GymTheme.textMuted)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(item.title)
                                                .font(.system(size: 13, weight: .semibold))
                                                .foregroundColor(GymTheme.textPrimary)
                                            Text(item.isCompleted ? "Absolviert (Tippen für Details)" : "Geplant (Tippen für Details)")
                                                .font(.system(size: 10, design: .monospaced))
                                                .foregroundColor(item.isCompleted ? GymTheme.sageGreen : GymTheme.warmAmber)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)

                                Spacer()

                                if !item.isCompleted {
                                    Button("Starten") {
                                        HapticFeedback.medium()
                                        if let planned = item.plannedItem {
                                            gymStore.startWorkout(from: planned)
                                        } else {
                                            gymStore.startWorkout()
                                        }
                                        showingActiveWorkout = true
                                    }
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(GymTheme.bg)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Capsule().fill(GymTheme.terracotta))
                                }

                                Button(action: {
                                    HapticFeedback.light()
                                    if let planned = item.plannedItem {
                                        gymStore.removePlannedWorkout(id: planned.id)
                                    } else if let session = item.session {
                                        gymStore.deleteSession(id: session.id)
                                    }
                                }) {
                                    Image(systemName: "trash")
                                        .font(.system(size: 11))
                                        .foregroundColor(GymTheme.textMuted)
                                        .padding(4)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(10)
                            .background(GymTheme.surfaceElevated)
                            .cornerRadius(10)
                            .contextMenu {
                                Button(role: .destructive) {
                                    if let planned = item.plannedItem {
                                        gymStore.removePlannedWorkout(id: planned.id)
                                    } else if let session = item.session {
                                        gymStore.deleteSession(id: session.id)
                                    }
                                } label: {
                                    Label("Einheit löschen", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(14)
        .background(GymTheme.surface)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(GymTheme.border, lineWidth: 1))
    }

    // MARK: - 6. Section 3: Food + Supplement Log
    private var foodAndSupplementSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isFoodExpanded.toggle()
                }
            }) {
                HStack {
                    Image(systemName: "fork.knife.circle.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(GymTheme.sageGreen)
                    Text("FOOD & SUPPLEMENT LOG")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(GymTheme.textPrimary)
                        .tracking(0.6)

                    Spacer()

                    let dayLogs = localStore.logs(for: selectedDate)
                    Text("\(dayLogs.count) Mahlzeiten")
                        .font(.system(size: 10.5, weight: .semibold, design: .monospaced))
                        .foregroundColor(GymTheme.textSecondary)

                    Image(systemName: isFoodExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(GymTheme.textMuted)
                }
            }
            .buttonStyle(.plain)

            if isFoodExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    // A. Zirkadiane Supplements (Vorschau & Direkt-Check)
                    circadianSupplementsMiniCard

                    // B. Mahlzeiten-Log
                    let dayLogs = localStore.logs(for: selectedDate)
                    if dayLogs.isEmpty {
                        Text("Noch keine Mahlzeiten für diesen Tag eingetragen.")
                            .font(.system(size: 11.5))
                            .foregroundColor(GymTheme.textMuted)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 6)
                    } else {
                        VStack(spacing: 6) {
                            ForEach(dayLogs) { log in
                                HStack(spacing: 8) {
                                    Button(action: {
                                        inspectingMealLog = log
                                    }) {
                                        HStack(spacing: 8) {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(log.foodName)
                                                    .font(.system(size: 12.5, weight: .semibold))
                                                    .foregroundColor(GymTheme.textPrimary)
                                                    .lineLimit(1)
                                                Text(String(format: "%.0f g • %@", log.weightGrams, formatLogTime(log.timestamp)))
                                                    .font(.system(size: 9.5))
                                                    .foregroundColor(GymTheme.textMuted)
                                            }

                                            Spacer()

                                            HStack(spacing: 8) {
                                                Text(String(format: "%.0f kcal", log.kcal))
                                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                                    .foregroundColor(GymTheme.textPrimary)
                                                Text(String(format: "%.0fg P", log.protein))
                                                    .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                                                    .foregroundColor(GymTheme.sageGreen)
                                            }
                                        }
                                    }
                                    .buttonStyle(.plain)

                                    Button(action: {
                                        HapticFeedback.light()
                                        localStore.deleteMealLog(id: log.id)
                                    }) {
                                        Image(systemName: "trash")
                                            .font(.system(size: 11))
                                            .foregroundColor(GymTheme.textMuted)
                                            .padding(4)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background(GymTheme.surfaceElevated)
                                .cornerRadius(8)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        localStore.deleteMealLog(id: log.id)
                                    } label: {
                                        Label("Mahlzeit löschen", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }

                    // Button Mahlzeit erfassen
                    Button(action: {
                        HapticFeedback.light()
                        showingQuickAddMeal = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle")
                            Text("Mahlzeit erfassen")
                        }
                        .font(.system(size: 11.5, weight: .semibold))
                        .foregroundColor(GymTheme.sageGreen)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background(GymTheme.surfaceElevated.opacity(0.7))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .background(GymTheme.surface)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(GymTheme.border, lineWidth: 1))
    }

    // Computed Upcoming Supplement Dose (Poka-Yoke: blends out past forgotten doses, focuses on the next actionable dose)
    private var upcomingSupplementDose: CircadianSupplementDose? {
        let doses = localStore.allSupplements
        guard !doses.isEmpty else { return nil }

        let isToday = Calendar.current.isDateInToday(selectedDate)
        if !isToday {
            if selectedDate < Date() {
                return nil
            } else {
                return doses.first
            }
        }

        let cal = Calendar.current
        let now = Date()
        let currentMins = cal.component(.hour, from: now) * 60 + cal.component(.minute, from: now)

        // Doses scheduled in the future or within a 15-minute active window
        let candidates = doses.filter { dose in
            let doseMins = CircadianSupplementProtocol.minutesFromMidnight(timeString: dose.scheduledTime)
            return doseMins >= (currentMins - 15)
        }

        // Return first untaken upcoming dose
        if let nextUntaken = candidates.first(where: { !localStore.isSupplementTaken(doseId: $0.id, date: selectedDate) }) {
            return nextUntaken
        }

        // If all remaining candidates are taken, show the first candidate
        return candidates.first
    }

    // Mini-Card: Zirkadiane Supplements (Fokus auf anstehendes Supplement)
    private var circadianSupplementsMiniCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label(showAllSupplements ? "ZIRKADIANE SUPPLEMENTS (ALLE)" : "NÄCHSTES SUPPLEMENT", systemImage: "pills.fill")
                    .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                    .foregroundColor(GymTheme.cyanAccent)
                Spacer()

                Button(showAllSupplements ? "Nur Nächstes" : "Alle (\(localStore.allSupplements.count))") {
                    HapticFeedback.light()
                    showAllSupplements.toggle()
                }
                .font(.system(size: 9.5, weight: .semibold, design: .monospaced))
                .foregroundColor(GymTheme.textSecondary)

                Button("Verwalten") {
                    showingSupplementsManagement = true
                }
                .font(.system(size: 9.5, weight: .semibold))
                .foregroundColor(GymTheme.strongBlue)
            }

            let doses = localStore.allSupplements
            if doses.isEmpty {
                Text("Standardplan: Rhodiola 06:00 • Malat 06:30 • D3/K2 11:45 • Nitrat 16:00 • Omega-3 16:45 • Bisglycinat 21:00")
                    .font(.system(size: 10))
                    .foregroundColor(GymTheme.textMuted)
            } else if !showAllSupplements {
                // Focus View: Only show the upcoming supplement; hide past ones even if forgotten
                if let dose = upcomingSupplementDose {
                    let isTaken = localStore.isSupplementTaken(doseId: dose.id, date: selectedDate)
                    HStack(spacing: 8) {
                        Text(dose.scheduledTime)
                            .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                            .foregroundColor(isTaken ? GymTheme.textMuted : GymTheme.cyanAccent)
                            .frame(width: 44, alignment: .leading)

                        VStack(alignment: .leading, spacing: 1) {
                            Text(dose.name)
                                .font(.system(size: 11, weight: isTaken ? .regular : .semibold))
                                .foregroundColor(isTaken ? GymTheme.textSecondary : GymTheme.textPrimary)
                                .strikethrough(isTaken, color: GymTheme.textMuted)
                                .lineLimit(1)

                            Text(dose.benefit)
                                .font(.system(size: 9))
                                .foregroundColor(GymTheme.textMuted)
                                .lineLimit(1)
                        }

                        Spacer(minLength: 4)

                        Text(dose.dosage)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(GymTheme.textMuted)

                        Button(action: {
                            HapticFeedback.success()
                            localStore.toggleSupplement(doseId: dose.id, date: selectedDate)
                        }) {
                            Image(systemName: isTaken ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(isTaken ? GymTheme.sageGreen : GymTheme.cyanAccent)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(GymTheme.surfaceElevated)
                    .cornerRadius(8)
                } else {
                    HStack {
                        Text("Alle anstehenden Dosen für heute abgeschlossen")
                            .font(.system(size: 10.5, weight: .medium))
                            .foregroundColor(GymTheme.sageGreen)
                        Spacer()
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(GymTheme.surfaceElevated.opacity(0.4))
                    .cornerRadius(8)
                }
            } else {
                // Expanded View: Alle Dosen mit Batch-Abhaken
                VStack(spacing: 4) {
                    ForEach(doses) { dose in
                        let isTaken = localStore.isSupplementTaken(doseId: dose.id, date: selectedDate)
                        HStack(spacing: 8) {
                            Text(dose.scheduledTime)
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(isTaken ? GymTheme.textMuted : GymTheme.cyanAccent)
                                .frame(width: 42, alignment: .leading)

                            Text(dose.name)
                                .font(.system(size: 11, weight: isTaken ? .regular : .medium))
                                .foregroundColor(isTaken ? GymTheme.textSecondary : GymTheme.textPrimary)
                                .strikethrough(isTaken, color: GymTheme.textMuted)
                                .lineLimit(1)

                            Spacer(minLength: 0)

                            Text(dose.dosage)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(GymTheme.textMuted)

                            Button(action: {
                                localStore.toggleSupplement(doseId: dose.id, date: selectedDate)
                            }) {
                                Image(systemName: isTaken ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(isTaken ? GymTheme.sageGreen : GymTheme.textMuted)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(GymTheme.surfaceElevated.opacity(isTaken ? 0.3 : 0.7))
                        .cornerRadius(6)
                    }
                }
            }
        }
        .padding(10)
        .background(GymTheme.surfaceElevated.opacity(0.5))
        .cornerRadius(10)
    }

    // MARK: - 7. Section 4: Einkaufsliste (Einkauf + Quittungen)
    private var einkaufslisteSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isShoppingExpanded.toggle()
                }
            }) {
                HStack {
                    Image(systemName: "cart.circle.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(GymTheme.warmAmber)
                    Text("EINKAUFSLISTE & QUITTUNGEN")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(GymTheme.textPrimary)
                        .tracking(0.6)

                    Spacer()

                    let pending = localStore.shoppingList.filter { !$0.isChecked }.count
                    Text("\(pending) Artikel offen")
                        .font(.system(size: 10.5, weight: .semibold, design: .monospaced))
                        .foregroundColor(GymTheme.textSecondary)

                    Image(systemName: isShoppingExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(GymTheme.textMuted)
                }
            }
            .buttonStyle(.plain)

            if isShoppingExpanded {
                VStack(alignment: .leading, spacing: 10) {
                    // Inline Quick Add
                    HStack(spacing: 6) {
                        TextField("Neuer Artikel...", text: $newShoppingItemName)
                            .font(.system(size: 12))
                            .textFieldStyle(.plain)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(GymTheme.surfaceElevated)
                            .cornerRadius(6)
                            .onSubmit { commitQuickShoppingItem() }

                        Button("Hinzufügen") {
                            commitQuickShoppingItem()
                        }
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(GymTheme.bg)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(GymTheme.warmAmber)
                        .cornerRadius(6)
                    }

                    // Offene Artikel
                    let pendingItems = localStore.shoppingList.filter { !$0.isChecked }
                    if pendingItems.isEmpty {
                        Text("Keine offenen Artikel auf der Einkaufsliste.")
                            .font(.system(size: 11.5))
                            .foregroundColor(GymTheme.textMuted)
                            .padding(.vertical, 4)
                    } else {
                        VStack(spacing: 4) {
                            ForEach(pendingItems.prefix(5)) { item in
                                HStack(spacing: 8) {
                                    Button(action: {
                                        localStore.toggleShoppingItem(id: item.id)
                                    }) {
                                        Image(systemName: "square")
                                            .font(.system(size: 13))
                                            .foregroundColor(GymTheme.textMuted)
                                    }
                                    .buttonStyle(.plain)

                                    Text(item.name)
                                        .font(.system(size: 12))
                                        .foregroundColor(GymTheme.textPrimary)

                                    Spacer()

                                    Text(item.store)
                                        .font(.system(size: 9.5, weight: .medium, design: .monospaced))
                                        .foregroundColor(GymTheme.textMuted)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(GymTheme.surfaceElevated.opacity(0.6))
                                .cornerRadius(6)
                            }
                        }
                    }

                    Divider().background(GymTheme.border)

                    // Quittungen OCR Action
                    HStack {
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Quittungen & Belege")
                                .font(.system(size: 11.5, weight: .semibold))
                                .foregroundColor(GymTheme.textPrimary)
                            Text("\(localStore.receipts.count) Belege im Archiv")
                                .font(.system(size: 9.5))
                                .foregroundColor(GymTheme.textMuted)
                        }

                        Spacer()

                        Button(action: {
                            HapticFeedback.light()
                            showingReceiptScanner = true
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "doc.viewfinder")
                                Text("Beleg scannen")
                            }
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(GymTheme.bg)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(GymTheme.warmAmber))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(14)
        .background(GymTheme.surface)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(GymTheme.border, lineWidth: 1))
    }

    // MARK: - Helpers
    private func advanceDate(by days: Int) {
        if let next = Calendar.current.date(byAdding: .day, value: days, to: selectedDate) {
            HapticFeedback.light()
            selectedDate = next
        }
    }

    private func formatHeaderDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "de_DE")
        f.dateFormat = "EEEE, d. MMMM"
        return f.string(from: date)
    }

    private func formatLogTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "de_DE")
        f.dateFormat = "HH:mm"
        return f.string(from: date)
    }

    private func workoutsForDate(_ date: Date) -> [DayWorkoutEntry] {
        var entries: [DayWorkoutEntry] = []
        let dayPlanned = gymStore.plannedWorkouts.filter { Calendar.current.isDate($0.plannedDate, inSameDayAs: date) }
        for p in dayPlanned {
            entries.append(DayWorkoutEntry(id: p.id.uuidString, title: p.title, isCompleted: p.isCompleted, plannedItem: p, session: nil))
        }
        let daySessions = gymStore.sessions.filter { Calendar.current.isDate($0.startTime, inSameDayAs: date) }
        for s in daySessions {
            if !entries.contains(where: { $0.title == s.title }) {
                entries.append(DayWorkoutEntry(id: s.id.uuidString, title: s.title, isCompleted: true, plannedItem: nil, session: s))
            }
        }
        return entries
    }

    private func commitQuickShoppingItem() {
        let clean = newShoppingItemName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        localStore.addCustomShoppingItem(name: clean, brand: "", price: 0.0, store: "Penny", quantity: 1, category: "Lebensmittel")
        newShoppingItemName = ""
        HapticFeedback.success()
    }
}

public struct DayWorkoutEntry: Identifiable {
    public var id: String
    public var title: String
    public var isCompleted: Bool
    public var plannedItem: PlannedWorkoutItem?
    public var session: WorkoutSession?
}
