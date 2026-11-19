import SwiftUI
import Combine

public struct HealthProfileSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var health = HealthKitService.shared
    @ObservedObject var store = LocalStore.shared
    @ObservedObject var calendarSync = CalendarSyncService.shared
    @ObservedObject var notifications = SupplementNotificationService.shared

    @State private var selectedDate: Date = Date()
    @State private var currentTime: Date = Date()
    @State private var inspectingLog: MealLogEntry?
    @State private var inspectingRecipeBatch: ConsumedRecipeBatchIdentifier? = nil
    @State private var isInspectingDailyProfile: Bool = false
    @State private var isBalanceExpanded: Bool = true
    @State private var isMealsExpanded: Bool = true
    @State private var isAnstehendExpanded: Bool = true
    @State private var showingAddMealSheet: Bool = false
    @State private var selectedPantryItemToLog: PantryItem? = nil

    @State private var showAllSupplements: Bool = false
    @State private var selectedExplanation: InfoExplanationItem? = nil
    @State private var showingSupplementsManagementSheet: Bool = false
    @State private var showingEditSupplementSheet: Bool = false
    @State private var editingSupplementDose: CircadianSupplementDose? = nil
    @State private var inspectingRecipeTemplate: MealTemplate? = nil
    @State private var lastDayObserved: Int = Calendar.current.component(.day, from: Date())

    public var isSheet: Bool

    let timer = Timer.publish(every: 60.0, on: .main, in: .common).autoconnect()

    private var mealLogTimeFormatter: DateFormatter {
        GrowFormatters.shortTime
    }

    public init(isSheet: Bool = true) {
        self.isSheet = isSheet
    }

    public var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                ScrollViewReader { scrollProxy in
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 14) {
                        // 1. DYNAMISCHE TAGESBILANZ & RINGE (Prominent auf der Oberfläche)
                        concentricNutritionRingsCard

                        // Trainingsreiz-Kompensation (Grow Telemetry Integration)
                        if let workout = store.latestSharedWorkout {
                            trainingStrainCard(workout)
                        }

                        // 1.5 TAGES-LEITSTAND & PROTOKOLL (Zusammenführung: Leitstand, Supplement-Log & Log)
                        unifiedDirectorAndLogSection

                        if isSheet {
                            Button(action: {
                                dismiss()
                            }) {
                                Text("Schließen")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(Theme.terracotta)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(RoundedRectangle(cornerRadius: 10).fill(Theme.surfaceElevated))
                            }
                            .padding(.top, 4)
                        }

                        Spacer().frame(height: 100)
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
                                        // Swiped left -> Step 1 day forward
                                        if let next = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) {
                                            HapticFeedbackService.shared.lightDetent()
                                            selectedDate = next
                                        }
                                    } else {
                                        // Swiped right -> Step 1 day backward
                                        if let prev = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) {
                                            HapticFeedbackService.shared.lightDetent()
                                            selectedDate = prev
                                        }
                                    }
                                }
                            }
                        }
                )

            }

            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Heute")
            .navigationBarTitleDisplayMode(store.isPadInstance ? .inline : .large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !Calendar.current.isDateInToday(selectedDate) {
                        Button("Heute") {
                            HapticFeedbackService.shared.lightDetent()
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedDate = Date()
                            }
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Theme.sageGreen)
                    }
                }

                ToolbarItemGroup(placement: .topBarTrailing) {
                    Menu {
                        Button(action: { showingSupplementsManagementSheet = true }) {
                            Label("Bedarfsprofil & Supplements", systemImage: "pills")
                        }
                        Button(action: {
                            health.fetchTodayHealthData()
                            store.syncTagesbilanzToBridge()
                        }) {
                            Label("HealthKit synchronisieren", systemImage: "arrow.triangle.2.circlepath")
                        }
                        Button(action: {
                            store.resetWater(date: selectedDate, sourceApp: "Growcery")
                        }) {
                            Label("Wasser zurücksetzen", systemImage: "drop")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundColor(Theme.textSecondary)
                    }

                    NutriCircularWaterButton()

                    Button(action: {
                        HapticFeedbackService.shared.mechanicalClick()
                        showingAddMealSheet = true
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Theme.bg)
                            .frame(width: 28, height: 28)
                            .background(Circle().fill(Theme.sageGreen))
                    }
                    .accessibilityLabel("Mahlzeit erfassen")
                }
            }
            .task {
                health.fetchTodayHealthData()
                store.syncTagesbilanzToBridge()
                calendarSync.triggerTodaySync(store: store)
            }
            .onChange(of: selectedDate) { _ in
                calendarSync.triggerTodaySync(store: store)
            }
            .onReceive(timer) { input in
                currentTime = input
                checkMidnightRollOverIfNeeded()
            }
            .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
                handleMidnightRollOver()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
                handleMidnightRollOver()
            }
            .sheet(item: $selectedExplanation) { item in
                InfoExplanationSheet(item: item)
            }
            .sheet(item: $inspectingLog) { log in
                EditMealLogSheet(log: log, store: store)
            }
            .sheet(item: $inspectingRecipeBatch) { batch in
                RecipeConsumedDetailSheet(recipeName: batch.name, batchId: batch.batchId, store: store)
            }
            .sheet(isPresented: $showingAddMealSheet) {
                QuickAddMealSheet(
                    targetDate: selectedDate,
                    store: store,
                    onSelectPantryItem: { item in
                        selectedPantryItemToLog = item
                    }
                )
            }
            .sheet(item: $selectedPantryItemToLog) { item in
                LogConsumptionSheet(
                    item: item,
                    store: store,
                    targetDate: selectedDate
                )
            }
            .sheet(isPresented: $isInspectingDailyProfile) {
                NutritionDetailSheet(dailyDate: selectedDate, store: store, activeBurn: health.activeEnergyBurned)
            }
            .sheet(isPresented: $showingSupplementsManagementSheet) {
                CircadianSupplementsManagementSheet(
                    selectedDate: selectedDate,
                    onDismiss: { showingSupplementsManagementSheet = false }
                )
                .environmentObject(store)
            }
            .sheet(isPresented: $showingEditSupplementSheet) {
                EditSupplementSheet(dose: editingSupplementDose)
                    .environmentObject(store)
            }
            .sheet(item: $inspectingRecipeTemplate) { tmpl in
                RecipeDetailSheet(template: tmpl, store: store)
            }

            .onChange(of: notifications.activeSupplementExplanation) { _ in
                if let item = notifications.activeSupplementExplanation {
                    selectedExplanation = item
                    isAnstehendExpanded = true
                    notifications.activeSupplementExplanation = nil
                }
            }
            .onChange(of: notifications.deepLinkRecipeName) { _ in
                guard let name = notifications.deepLinkRecipeName else { return }
                let all = store.activeMealTemplates.isEmpty ? store.mealTemplates : store.activeMealTemplates
                if name == "first" {
                    inspectingRecipeTemplate = all.first
                } else if let matched = all.first(where: { $0.name.lowercased().contains(name.lowercased()) }) {
                    inspectingRecipeTemplate = matched
                }
                notifications.deepLinkRecipeName = nil
            }
        }
        .presentationDragIndicator(.visible)
    }


    // MARK: - 1. Concentric Nutrition Rings (Apple Activity Style Hero)
    private var concentricNutritionRingsCard: some View {
        let dayProtein = store.protein(for: selectedDate)
        let targetProtein = max(1.0, store.targetProtein)
        let proteinRatio = min(1.0, max(0.0, dayProtein / targetProtein))

        let dayCarbs = store.carbs(for: selectedDate)
        let targetCarbs = max(1.0, store.targetCarbs)
        let carbsRatio = min(1.0, max(0.0, dayCarbs / targetCarbs))

        let dayFat = store.fat(for: selectedDate)
        let targetFat = max(1.0, store.targetFat)
        let fatRatio = min(1.0, max(0.0, dayFat / targetFat))

        let dayFiber = store.fiber(for: selectedDate)
        let dayWater = store.todayWater(date: selectedDate)
        let dayKcal = store.kcal(for: selectedDate)

        let proteinColor = Color(red: 0.96, green: 0.25, blue: 0.37)
        let carbsColor = Color(red: 0.58, green: 0.88, blue: 0.28)
        let fatColor = Color(red: 0.0, green: 0.82, blue: 0.92)

        return VStack(alignment: .leading, spacing: 16) {
            // Header with ⓘ Info Button
            HStack {
                Text("TAGESBILANZ")
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(Theme.textSecondary)
                    .tracking(0.6)
                Spacer()
                Button(action: {
                    HapticFeedbackService.shared.lightDetent()
                    selectedExplanation = InfoExplanationItem(
                        title: "Tagesbilanz & Stoffwechsel-Ziele",
                        category: "Klinische & Sportphysiologische Vorgaben",
                        summary: "Systematische Nährstoff- und Energiebilanzierung nach Recomp- und Reha-Kriterien (BWK Ulm).",
                        details: [
                            ExplanationDetail(label: "Protein (145–170 g / Std. 160 g)", text: "Sicherung der Muskelproteinsynthese und Geweberegeneration bei Rumpf- und Kraftbelastung."),
                            ExplanationDetail(label: "Ballaststoffe (25–35 g)", text: "BWK Ulm Reha-Pflicht (Bristol-Typ 4) zur Vermeidung intraabdominalen Drucks."),
                            ExplanationDetail(label: "Energiebudget (1.850–2.000 kcal)", text: "Grundbudget für kontrollierte Körperrekomposition zzgl. aktiver Leistungsumsatz."),
                            ExplanationDetail(label: "Hydratation (mind. 2,5 Liter)", text: "Unterstützung von Nierenfunktion, Nährstofftransport und Kreislaufstabilität.")
                        ]
                    )
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 13, weight: .medium))
                        Text("Ziele")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundColor(Theme.textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.white.opacity(0.08)))
                }
            }

            Button(action: {
                HapticFeedbackService.shared.lightDetent()
                isInspectingDailyProfile = true
            }) {
                HStack(spacing: 24) {
                    // Apple Fitness Activity Rings
                    ZStack {
                        // Outer Ring: Protein (Coral / Red)
                        Circle()
                            .stroke(Theme.ringProteinStart.opacity(0.18), lineWidth: 12)
                            .frame(width: 124, height: 124)
                        Circle()
                            .trim(from: 0, to: CGFloat(proteinRatio))
                            .stroke(
                                LinearGradient(colors: [Theme.ringProteinStart, Theme.ringProteinEnd], startPoint: .topLeading, endPoint: .bottomTrailing),
                                style: StrokeStyle(lineWidth: 12, lineCap: .round)
                            )
                            .frame(width: 124, height: 124)
                            .rotationEffect(.degrees(-90))
                            .shadow(color: Theme.ringProteinStart.opacity(proteinRatio > 0.05 ? 0.35 : 0), radius: 5, x: 0, y: 2)

                        // Middle Ring: Kohlenhydrate (Bright Green)
                        Circle()
                            .stroke(Theme.ringCarbsStart.opacity(0.18), lineWidth: 12)
                            .frame(width: 96, height: 96)
                        Circle()
                            .trim(from: 0, to: CGFloat(carbsRatio))
                            .stroke(
                                LinearGradient(colors: [Theme.ringCarbsStart, Theme.ringCarbsEnd], startPoint: .topLeading, endPoint: .bottomTrailing),
                                style: StrokeStyle(lineWidth: 12, lineCap: .round)
                            )
                            .frame(width: 96, height: 96)
                            .rotationEffect(.degrees(-90))
                            .shadow(color: Theme.ringCarbsStart.opacity(carbsRatio > 0.05 ? 0.35 : 0), radius: 5, x: 0, y: 2)

                        // Inner Ring: Fette (Electric Blue)
                        Circle()
                            .stroke(Theme.ringFatStart.opacity(0.18), lineWidth: 12)
                            .frame(width: 68, height: 68)
                        Circle()
                            .trim(from: 0, to: CGFloat(fatRatio))
                            .stroke(
                                LinearGradient(colors: [Theme.ringFatStart, Theme.ringFatEnd], startPoint: .topLeading, endPoint: .bottomTrailing),
                                style: StrokeStyle(lineWidth: 12, lineCap: .round)
                            )
                            .frame(width: 68, height: 68)
                            .rotationEffect(.degrees(-90))
                            .shadow(color: Theme.ringFatStart.opacity(fatRatio > 0.05 ? 0.35 : 0), radius: 5, x: 0, y: 2)
                    }
                    .frame(width: 130, height: 130)

                    VStack(alignment: .leading, spacing: 14) {
                        // Protein Metric
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Theme.ringProteinStart)
                                .frame(width: 8, height: 8)
                            VStack(alignment: .leading, spacing: 1) {
                                Text("Protein")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(Theme.textSecondary)
                                HStack(alignment: .firstTextBaseline, spacing: 3) {
                                    Text(String(format: "%.1f", dayProtein))
                                        .font(.system(size: 19, weight: .bold))
                                        .foregroundColor(Theme.textPrimary)
                                    Text("/ \(Int(targetProtein)) g")
                                        .font(.footnote.weight(.medium))
                                        .foregroundColor(Theme.textSecondary)
                                }
                            }
                        }

                        // Kohlenhydrate Metric
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Theme.ringCarbsStart)
                                .frame(width: 8, height: 8)
                            VStack(alignment: .leading, spacing: 1) {
                                Text("Kohlenhydrate")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(Theme.textSecondary)
                                HStack(alignment: .firstTextBaseline, spacing: 3) {
                                    Text("\(Int(dayCarbs))")
                                        .font(.system(size: 19, weight: .bold))
                                        .foregroundColor(Theme.textPrimary)
                                    Text("/ \(Int(targetCarbs)) g")
                                        .font(.footnote.weight(.medium))
                                        .foregroundColor(Theme.textSecondary)
                                }
                            }
                        }

                        // Fette Metric
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Theme.ringFatStart)
                                .frame(width: 8, height: 8)
                            VStack(alignment: .leading, spacing: 1) {
                                Text("Fette")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(Theme.textSecondary)
                                HStack(alignment: .firstTextBaseline, spacing: 3) {
                                    Text("\(Int(dayFat))")
                                        .font(.system(size: 19, weight: .bold))
                                        .foregroundColor(Theme.textPrimary)
                                    Text("/ \(Int(targetFat)) g")
                                        .font(.footnote.weight(.medium))
                                        .foregroundColor(Theme.textSecondary)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .buttonStyle(PlainButtonStyle())

            Divider().background(Color.white.opacity(0.08))

            // Secondary Pillars Row (Kalorien, Ballaststoffe, Wasser) - Apple Health Tile Style
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Kalorien")
                        .font(.caption.weight(.medium))
                        .foregroundColor(Theme.textSecondary)
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(Int(dayKcal))")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(Theme.textPrimary)
                        Text("/ 2k")
                            .font(.caption2)
                            .foregroundColor(Theme.textMuted)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Ballaststoffe")
                        .font(.caption.weight(.medium))
                        .foregroundColor(Theme.textSecondary)
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(String(format: "%.1f", dayFiber))
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(dayFiber >= 25 ? Theme.sageGreen : Theme.textPrimary)
                        Text("/ 30g")
                            .font(.caption2)
                            .foregroundColor(Theme.textMuted)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Wasser")
                        .font(.caption.weight(.medium))
                        .foregroundColor(Theme.textSecondary)
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(String(format: "%.1f", dayWater / 1000.0))
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(dayWater >= 2500 ? Theme.sageGreen : Theme.strongBlue)
                        Text("/ 2,5L")
                            .font(.caption2)
                            .foregroundColor(Theme.textMuted)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Theme.border, lineWidth: 0.8)
        )
    }

    // MARK: - Bristol-Stuhlform-Tracker (1-Tap BWK Ulm Viszeral-Reha)
    private var bristolStoolTrackerCard: some View {
        let currentScore = store.bristolScore(for: selectedDate)
        let dayFiber = store.fiber(for: selectedDate)

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("ABEND-CHECK-IN • BRISTOL-STUHLFORM")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(Theme.textMuted)
                        .tracking(0.8)
                    Text("BWK Ulm Viszeral-Reha (Typ 4 als Goldstandard)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Theme.textPrimary)
                }
                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 10))
                        .foregroundColor(dayFiber >= 25 ? Theme.sageGreen : Theme.warmSand)
                    Text("\(String(format: "%.1f", dayFiber))g / 25–35g")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(dayFiber >= 25 ? Theme.sageGreen : Theme.warmSand)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(RoundedRectangle(cornerRadius: 6).fill(Theme.surface))
            }

            // 1-Tap Bristol Scale Selector (Typ 1 bis 7)
            HStack(spacing: 6) {
                ForEach(1...7, id: \.self) { typeNum in
                    let isSelected = (currentScore == typeNum)
                    let isTarget = (typeNum == 4)

                    Button(action: {
                        store.setBristolScore(typeNum, for: selectedDate)
                    }) {
                        VStack(spacing: 3) {
                            Text("\(typeNum)")
                                .font(.system(size: 14, weight: .black, design: .monospaced))
                                .foregroundColor(isSelected ? Theme.bg : (isTarget ? Theme.sageGreen : Theme.textPrimary))
                            Text(isTarget ? "Ziel" : "T\(typeNum)")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(isSelected ? Theme.bg.opacity(0.8) : (isTarget ? Theme.sageGreen : Theme.textMuted))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(isSelected ? (isTarget ? Theme.sageGreen : Theme.warmSand) : Theme.surface)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(isSelected ? Color.clear : (isTarget ? Theme.sageGreen.opacity(0.6) : Theme.border), lineWidth: isTarget ? 1.5 : 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }

            if let score = currentScore {
                Text(bristolDescription(for: score))
                    .font(.system(size: 11))
                    .foregroundColor(score == 4 ? Theme.sageGreen : Theme.warmSand)
                    .padding(.top, 2)
            } else {
                Text("1-Tap Verifikation: Typ 4 sichert druckfreien Stuhlgang und schützt den Beckenboden nach Prolaps-OP.")
                    .font(.system(size: 10.5))
                    .foregroundColor(Theme.textSecondary)
                    .padding(.top, 2)
            }
        }
        .padding(14)
        .wellnessCard(borderColor: currentScore == 4 ? Theme.sageGreen.opacity(0.4) : Theme.border)
    }

    private func bristolDescription(for score: Int) -> String {
        switch score {
        case 1:
            return "Typ 1: Einzelne feste Kügelchen. Obstipation: Ballaststoffe (Flohsamen) und Trinkmenge akut steigern."
        case 2:
            return "Typ 2: Wurstförmig, aber klumpig. Verlangsamte Darmpassage: Erhöhter intraabdominaler Pressdruck droht."
        case 3:
            return "Typ 3: Wurstförmig mit rissiger Oberfläche. Normalbereich, Trinkmenge sicherstellen."
        case 4:
            return "Typ 4: Wurst- oder schlangenförmig, glatt und weich. Goldstandard der BWK Ulm Reha (Zero Intraabdominaldruck)."
        case 5:
            return "Typ 5: Weiche Klumpen mit klaren Kanten. Leicht und ohne Pressen zu entleeren."
        case 6:
            return "Typ 6: Fluffige, zerrissene Stücke, breiig. Beschleunigte Passage."
        case 7:
            return "Typ 7: Wässrig, keine festen Bestandteile. Akute Diarrhoe: Elektrolyte substituieren."
        default:
            return "Typ \(score) erfasst."
        }
    }

    // MARK: - Protein-Defizit Schnell-Log Leiste
    private var proteinDeficitQuickActionBar: some View {
        let isToday = Calendar.current.isDateInToday(selectedDate)
        guard isToday else { return AnyView(EmptyView()) }

        let dayProtein = store.protein(for: selectedDate)
        let target = store.targetProtein
        let deficit = max(0.0, target - dayProtein)

        if deficit > 5.0 {
            return AnyView(
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("PROTEIN-DEFIZIT: NOCH \(String(format: "%.1f", deficit))g BIS \(Int(target))g")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(Theme.warmSand)
                            .tracking(0.6)
                        Spacer()
                        Text("1-Tap Buchung")
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundColor(Theme.textMuted)
                    }

                    HStack(spacing: 8) {
                        Button(action: {
                            store.quickLogProteinSnack(
                                name: "Whey Protein Isolat Shake",
                                proteinGrams: 30.0,
                                kcal: 120.0,
                                carbs: 1.0,
                                fat: 0.5,
                                fiber: 0.0,
                                targetDate: selectedDate
                            )
                        }) {
                            VStack(spacing: 2) {
                                Text("+30g Shake")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(Theme.textPrimary)
                                Text("120 kcal")
                                    .font(.system(size: 9, design: .monospaced))
                                    .foregroundColor(Theme.textMuted)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Theme.surface))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 1))
                        }

                        Button(action: {
                            store.quickLogProteinSnack(
                                name: "Skyr / Magerquark (250g)",
                                proteinGrams: 27.5,
                                kcal: 155.0,
                                carbs: 10.0,
                                fat: 0.5,
                                fiber: 0.0,
                                targetDate: selectedDate
                            )
                        }) {
                            VStack(spacing: 2) {
                                Text("+27g Skyr")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(Theme.textPrimary)
                                Text("155 kcal")
                                    .font(.system(size: 9, design: .monospaced))
                                    .foregroundColor(Theme.textMuted)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Theme.surface))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 1))
                        }

                        Button(action: {
                            store.quickLogProteinSnack(
                                name: "Hähnchenbrustfilet (150g)",
                                proteinGrams: 45.0,
                                kcal: 165.0,
                                carbs: 0.0,
                                fat: 1.5,
                                fiber: 0.0,
                                targetDate: selectedDate
                            )
                        }) {
                            VStack(spacing: 2) {
                                Text("+45g Huhn")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(Theme.textPrimary)
                                Text("165 kcal")
                                    .font(.system(size: 9, design: .monospaced))
                                    .foregroundColor(Theme.textMuted)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Theme.surface))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 1))
                        }
                    }
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 10).fill(Theme.surfaceElevated))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border, lineWidth: 1))
            )
        } else {
            return AnyView(
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 13))
                        .foregroundColor(Theme.sageGreen)
                    Text("PROTEINZIEL ERREICHT (\(String(format: "%.1f", dayProtein))g / \(Int(target))g)")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(Theme.sageGreen)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 8).fill(Theme.surfaceElevated))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.sageGreen.opacity(0.3), lineWidth: 1))
            )
        }
    }

    // MARK: - Unified Log Section (Supplement-Tracking & Verbuchte Mahlzeiten)
    private var unifiedDirectorAndLogSection: some View {
        let dayLogs = store.logs(for: selectedDate)
        let dayProtein = store.protein(for: selectedDate)
        let dayKcal = store.kcal(for: selectedDate)
        let isToday = Calendar.current.isDateInToday(selectedDate)
        let isFuture = selectedDate > Calendar.current.startOfDay(for: Date()).addingTimeInterval(86400 - 1)

        let allDoses = store.allSupplements
        let untakenSupplements = isToday ? allDoses.filter {
            !store.isSupplementTaken(doseId: $0.id, date: selectedDate)
        } : []

        let takenSupplements = allDoses.filter {
            store.isSupplementTaken(doseId: $0.id, date: selectedDate)
        }

        let nextPendingDose: CircadianSupplementDose? = isToday ? (
            CircadianSupplementProtocol.nextScheduledDose(from: untakenSupplements, currentTime: currentTime) ?? untakenSupplements.first
        ) : nil

        let badgeText: String = {
            if isFuture { return "Zukunft" }
            return dayLogs.isEmpty ? "Keine Mahlzeiten" : "\(dayLogs.count) Mahlzeiten verbucht"
        }()

        return VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("LOG")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.textPrimary)
                    .tracking(0.8)
                Spacer()
                Text(badgeText)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(dayLogs.isEmpty ? Theme.warmSand : Theme.sageGreen)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Theme.surfaceElevated))
            }

            // 1. ZIRKADIANE SUPPLEMENTS (Falls für heute noch ausstehend)
            if isToday && !isFuture && !untakenSupplements.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Circle().fill(Theme.warmSand).frame(width: 5, height: 5)
                        Text("ANSTEHENDES SUPPLEMENT (\(untakenSupplements.count) OFFEN)")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(Theme.warmSand)
                        Spacer()
                        Button(action: {
                            showingSupplementsManagementSheet = true
                        }) {
                            HStack(spacing: 3) {
                                Text("Stack-Plan")
                                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                                Image(systemName: "slider.horizontal.3")
                                    .font(.system(size: 8))
                            }
                            .foregroundColor(Theme.textMuted)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }

                    if let nextDose = nextPendingDose {
                        let isAcute = isDoseInOneHourWindow(nextDose, currentTime: currentTime) || CircadianSupplementProtocol.isDosePast(dose: nextDose, currentTime: currentTime)
                        pendingSupplementRow(dose: nextDose, isAcute: isAcute)
                    }

                    circadianStackSummaryBar(allDoses: allDoses, selectedDate: selectedDate)
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 12).fill(Theme.surfaceElevated.opacity(0.5)))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border.opacity(0.6), lineWidth: 0.5))
            }

            // 2. HEUTE VERBUCHT (LOG & HISTORIE)
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("VERBUCHT (LOG)")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(Theme.textMuted)
                        .tracking(0.6)
                    Spacer()
                    Text("\(dayLogs.count) Mahlzeiten • \(Int(dayKcal)) kcal • \(String(format: "%.1f", dayProtein))g P")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(Theme.textSecondary)
                }

                if !takenSupplements.isEmpty {
                    VStack(spacing: 4) {
                        ForEach(takenSupplements) { s in
                            takenSupplementRow(dose: s)
                        }
                    }
                }

                eatenMealsSection(logs: dayLogs)
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14).fill(Theme.surface))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.sageGreen.opacity(0.35), lineWidth: 1))
    }

    private func openSupplementInspector(dose: CircadianSupplementDose) {
        HapticFeedbackService.shared.lightDetent()
        selectedExplanation = InfoExplanationItem(
            title: dose.name,
            category: "Zirkadianes Wirkstoff-Protokoll (\(dose.scheduledTime) Uhr)",
            summary: dose.noviceExplanation.isEmpty ? dose.benefit : dose.noviceExplanation,
            details: [
                ExplanationDetail(label: "Kurzzeit-Wirkung (0–4 Stunden)", text: dose.shortTermImpact.isEmpty ? dose.benefit : dose.shortTermImpact),
                ExplanationDetail(label: "Langzeit-Wirkung (Wochen & Monate)", text: dose.longTermImpact.isEmpty ? dose.mechanism : dose.longTermImpact),
                ExplanationDetail(label: "Biochemischer Mechanismus", text: dose.mechanism),
                ExplanationDetail(label: "Dosierung & Einnahme", text: "\(dose.dosage) • \(dose.instructions)"),
                ExplanationDetail(label: "Zielbereich & Organ-Fokus", text: dose.targetArea),
                ExplanationDetail(label: "Sicherheitsstandard", text: "Strikte Anti-Doppelgabe-Regel: Verpasste Dosen niemals aufaddieren oder nachholen.")
            ]
        )
    }

    private func pendingSupplementRow(dose: CircadianSupplementDose, isAcute: Bool = true) -> some View {
        HStack(spacing: 8) {
            Button(action: {
                openSupplementInspector(dose: dose)
            }) {
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(dose.scheduledTime)
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(isAcute ? Theme.warmSand : Theme.textSecondary)
                            Text(dose.shortName)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Theme.textPrimary)
                            Image(systemName: "info.circle")
                                .font(.system(size: 11))
                                .foregroundColor(Theme.warmSand.opacity(0.85))
                            if !isAcute {
                                Text("In Planung")
                                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                                    .foregroundColor(Theme.textMuted)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 1)
                                    .background(Capsule().fill(Theme.surface))
                            }
                        }
                        Text("\(dose.dosage) • \(dose.instructions)")
                            .font(.system(size: 10, weight: .regular))
                            .foregroundColor(Theme.textMuted)
                            .lineLimit(1)
                    }
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())

            Button(action: {
                HapticFeedbackService.shared.commitSuccess()
                store.toggleSupplement(doseId: dose.id, date: selectedDate)
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                    Text("Einnehmen")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                }
                .foregroundColor(Theme.bg)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Capsule().fill(isAcute ? Theme.warmSand : Theme.warmSand.opacity(0.8)))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 8).fill(Theme.surfaceElevated))
    }

    private func takenSupplementRow(dose: CircadianSupplementDose) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 12))
                .foregroundColor(Theme.sageGreen)
            Text(dose.scheduledTime)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(Theme.sageGreen)
            Button(action: {
                openSupplementInspector(dose: dose)
            }) {
                HStack(spacing: 4) {
                    Text("\(dose.shortName) (\(dose.dosage))")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Theme.textPrimary)
                    Image(systemName: "info.circle")
                        .font(.system(size: 10))
                        .foregroundColor(Theme.warmSand.opacity(0.8))
                }
            }
            .buttonStyle(PlainButtonStyle())
            Spacer()
            Button(action: {
                store.toggleSupplement(doseId: dose.id, date: selectedDate)
            }) {
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 9))
                    .foregroundColor(Theme.textMuted)
                    .padding(4)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(RoundedRectangle(cornerRadius: 6).fill(Theme.surfaceElevated.opacity(0.4)))
    }

    private func circadianStackSummaryBar(allDoses: [CircadianSupplementDose], selectedDate: Date) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(allDoses) { dose in
                    let isTaken = store.isSupplementTaken(doseId: dose.id, date: selectedDate)
                    Button(action: {
                        openSupplementInspector(dose: dose)
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: isTaken ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(isTaken ? Theme.sageGreen : Theme.warmSand)
                            Text(dose.scheduledTime)
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(isTaken ? Theme.sageGreen : Theme.textPrimary)
                            Text(dose.shortName)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(isTaken ? Theme.textMuted : Theme.textPrimary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(RoundedRectangle(cornerRadius: 6).fill(isTaken ? Theme.sageGreen.opacity(0.12) : Theme.surfaceElevated))
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(isTaken ? Theme.sageGreen.opacity(0.4) : Theme.border.opacity(0.5), lineWidth: 0.8))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.vertical, 2)
        }
    }

    // MARK: - 2. Was ich gegessen habe (Mahlzeiten-Tagebuch & Nachtragen)
    private func eatenMealsSection(logs: [MealLogEntry]) -> some View {
        let totalCost = store.cost(for: selectedDate)
        let totalCalories = store.kcal(for: selectedDate)

        return VStack(alignment: .leading, spacing: 10) {
            // Action Bar: + Mahlzeit erfassen / nachtragen & Cost
            HStack {
                Button(action: {
                    HapticFeedbackService.shared.lightDetent()
                    showingAddMealSheet = true
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 13, weight: .bold))
                        Text("Mahlzeit erfassen / nachtragen")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(Theme.bg)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Theme.sageGreen))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 1) {
                    Text("\(Int(totalCalories)) kcal")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(Theme.textPrimary)
                    Text("Kosten: \(String(format: "%.2f €", totalCost))")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(Theme.warmSand)
                }
            }

            let groupedEntries: [JournalGroupedEntry] = {
                var items: [JournalGroupedEntry] = []
                var seenBatchIds: Set<String> = []

                for log in logs {
                    if let bId = log.recipeBatchId, !bId.isEmpty {
                        if !seenBatchIds.contains(bId) {
                            seenBatchIds.insert(bId)
                            let matching = logs.filter { $0.recipeBatchId == bId }
                            items.append(
                                JournalGroupedEntry(
                                    id: bId,
                                    isRecipe: true,
                                    recipeName: log.recipeName ?? log.mealType,
                                    recipeBatchId: bId,
                                    singleLog: nil,
                                    batchLogs: matching
                                )
                            )
                        }
                    } else {
                        items.append(
                            JournalGroupedEntry(
                                id: log.id,
                                isRecipe: false,
                                recipeName: nil,
                                recipeBatchId: nil,
                                singleLog: log,
                                batchLogs: []
                            )
                        )
                    }
                }
                return items
            }()

            if groupedEntries.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "fork.knife")
                        .font(.system(size: 20))
                        .foregroundColor(Theme.textMuted)
                    Text("Noch keine Mahlzeiten für diesen Tag erfasst")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Theme.textMuted)
                    Button(action: {
                        HapticFeedbackService.shared.lightDetent()
                        showingAddMealSheet = true
                    }) {
                        Text("+ Jetzt Mahlzeit buchen")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Theme.sageGreen)
                            .padding(.top, 2)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .wellnessCard()
            } else {
                VStack(spacing: 6) {
                    ForEach(groupedEntries) { entry in
                        if entry.isRecipe, let bId = entry.recipeBatchId {
                            let rName = (entry.recipeName ?? "Rezept").replacingOccurrences(of: "^[0-9]+[.\\s]+", with: "", options: .regularExpression)
                            let rProt = entry.batchLogs.reduce(0) { $0 + $1.protein }
                            let rKcal = entry.batchLogs.reduce(0) { $0 + $1.kcal }
                            let rCost = entry.batchLogs.reduce(0) { $0 + $1.cost }
                            let logTime = entry.batchLogs.first?.timestamp

                            HStack(spacing: 10) {
                                Button(action: {
                                    HapticFeedbackService.shared.lightDetent()
                                    inspectingRecipeBatch = ConsumedRecipeBatchIdentifier(name: rName, batchId: bId)
                                }) {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(rName)
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(Theme.textPrimary)
                                            .lineLimit(1)
                                        HStack(spacing: 6) {
                                            if let t = logTime {
                                                Text(mealLogTimeFormatter.string(from: t))
                                                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                                                    .foregroundColor(Theme.warmSand)
                                                Text("•")
                                                    .foregroundColor(Theme.textMuted)
                                            }
                                            Text("\(String(format: "%.1f", rProt))g P")
                                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                                .foregroundColor(Color(red: 0.96, green: 0.25, blue: 0.37))
                                            Text("•")
                                                .foregroundColor(Theme.textMuted)
                                            Text("\(Int(rKcal)) kcal")
                                                .font(.system(size: 10, weight: .regular, design: .monospaced))
                                                .foregroundColor(Theme.textSecondary)
                                        }

                                        let hasLate = entry.batchLogs.contains { $0.isLateLPRWarning }
                                        let riskReason = entry.batchLogs.compactMap { $0.lprRiskReason }.first
                                        if hasLate || riskReason != nil {
                                            HStack(spacing: 4) {
                                                if hasLate {
                                                    Text("SPÄT-LOG (19:30+)")
                                                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                                                        .foregroundColor(Theme.terracotta)
                                                        .padding(.horizontal, 4)
                                                        .padding(.vertical, 1)
                                                        .background(Theme.terracotta.opacity(0.15))
                                                        .cornerRadius(3)
                                                }
                                                if let reason = riskReason {
                                                    Text("LPR: \(reason)")
                                                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                                                        .foregroundColor(Theme.warmSand)
                                                        .padding(.horizontal, 4)
                                                        .padding(.vertical, 1)
                                                        .background(Theme.warmSand.opacity(0.15))
                                                        .cornerRadius(3)
                                                        .lineLimit(1)
                                                }
                                            }
                                            .padding(.top, 1)
                                        }
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())

                                Spacer()

                                VStack(alignment: .trailing, spacing: 3) {
                                    Text(String(format: "%.2f €", rCost))
                                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                                        .foregroundColor(Theme.textSecondary)

                                    HStack(spacing: 6) {
                                        Button(action: {
                                            HapticFeedbackService.shared.lightDetent()
                                            inspectingRecipeBatch = ConsumedRecipeBatchIdentifier(name: rName, batchId: bId)
                                        }) {
                                            Text("Bearbeiten")
                                                .font(.system(size: 9, weight: .medium))
                                                .foregroundColor(Theme.warmSand)
                                        }
                                        Button(action: {
                                            HapticFeedbackService.shared.mechanicalClick()
                                            store.deleteRecipeBatch(batchId: bId)
                                        }) {
                                            Text("Löschen")
                                                .font(.system(size: 9, weight: .regular))
                                                .foregroundColor(Theme.terracotta)
                                        }
                                    }
                                }
                            }
                            .padding(8)
                            .wellnessCard(borderColor: Theme.sageGreen.opacity(0.35), cornerRadius: 8)
                        } else if let log = entry.singleLog {
                            let logName = log.foodName.replacingOccurrences(of: "^[0-9]+[.\\s]+", with: "", options: .regularExpression)
                            HStack(spacing: 10) {
                                Button(action: {
                                    HapticFeedbackService.shared.lightDetent()
                                    inspectingLog = log
                                }) {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(logName)
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(Theme.textPrimary)
                                            .lineLimit(1)
                                        HStack(spacing: 6) {
                                            Text(mealLogTimeFormatter.string(from: log.timestamp))
                                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                                .foregroundColor(Theme.warmSand)
                                            Text("•")
                                                .foregroundColor(Theme.textMuted)
                                            Text("\(String(format: "%.1f", log.protein))g P")
                                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                                .foregroundColor(Theme.sageGreen)
                                            Text("•")
                                                .foregroundColor(Theme.textMuted)
                                            Text("\(Int(log.kcal)) kcal")
                                                .font(.system(size: 10, weight: .regular, design: .monospaced))
                                                .foregroundColor(Theme.textSecondary)
                                        }

                                        if log.isLateLPRWarning || log.isLPRSphincterRisk {
                                            HStack(spacing: 4) {
                                                if log.isLateLPRWarning {
                                                    Text("SPÄT-LOG (19:30+)")
                                                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                                                        .foregroundColor(Theme.terracotta)
                                                        .padding(.horizontal, 4)
                                                        .padding(.vertical, 1)
                                                        .background(Theme.terracotta.opacity(0.15))
                                                        .cornerRadius(3)
                                                }
                                                if let reason = log.lprRiskReason {
                                                    Text("LPR: \(reason)")
                                                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                                                        .foregroundColor(Theme.warmSand)
                                                        .padding(.horizontal, 4)
                                                        .padding(.vertical, 1)
                                                        .background(Theme.warmSand.opacity(0.15))
                                                        .cornerRadius(3)
                                                        .lineLimit(1)
                                                }
                                            }
                                            .padding(.top, 1)
                                        }
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())

                                Spacer()

                                VStack(alignment: .trailing, spacing: 3) {
                                    Text(String(format: "%.2f €", log.cost))
                                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                                        .foregroundColor(Theme.textSecondary)

                                    HStack(spacing: 6) {
                                        Button(action: {
                                            HapticFeedbackService.shared.lightDetent()
                                            inspectingLog = log
                                        }) {
                                            Text("Bearbeiten")
                                                .font(.system(size: 9, weight: .medium))
                                                .foregroundColor(Theme.warmSand)
                                        }
                                        Button(action: {
                                            HapticFeedbackService.shared.mechanicalClick()
                                            store.deleteMealLog(id: log.id)
                                        }) {
                                            Text("Löschen")
                                                .font(.system(size: 9, weight: .regular))
                                                .foregroundColor(Theme.terracotta)
                                        }
                                    }
                                }
                            }
                            .padding(8)
                            .wellnessCard(borderColor: Theme.border, cornerRadius: 8)
                        }
                    }
                }
            }
        }
    }

// MARK: - Circadian Schedule Window (Regel: Nur aktuelles Zeitfenster auf dem Heute-Tab)
public enum CircadianScheduleWindow: String, CaseIterable {
    case morning = "MORGEN (05:00 - 10:30 UHR)"
    case midday = "MITTAG (10:30 - 14:30 UHR)"
    case afternoon = "PRE-WORKOUT & NACHMITTAG (14:30 - 18:30 UHR)"
    case evening = "ABEND & NACHTRUHE (18:30 - 05:00 UHR)"

    public static func currentWindow(for date: Date = Date()) -> CircadianScheduleWindow {
        let hour = Calendar.current.component(.hour, from: date)
        let minute = Calendar.current.component(.minute, from: date)
        let totalMinutes = hour * 60 + minute

        if totalMinutes >= 5 * 60 && totalMinutes < 10 * 60 + 30 {
            return .morning
        } else if totalMinutes >= 10 * 60 + 30 && totalMinutes < 14 * 60 + 30 {
            return .midday
        } else if totalMinutes >= 14 * 60 + 30 && totalMinutes < 18 * 60 + 30 {
            return .afternoon
        } else {
            return .evening
        }
    }

    public func matchesDose(_ dose: CircadianSupplementDose) -> Bool {
        switch self {
        case .morning:
            return dose.scheduledTime.contains("06:")
        case .midday:
            return dose.scheduledTime.contains("11:")
        case .afternoon:
            return dose.scheduledTime.contains("16:")
        case .evening:
            return dose.scheduledTime.contains("21:")
        }
    }

    public func matchesHour(_ hour: Int) -> Bool {
        switch self {
        case .morning:
            return hour >= 5 && hour < 11
        case .midday:
            return hour >= 10 && hour < 15
        case .afternoon:
            return hour >= 14 && hour < 19
        case .evening:
            return hour >= 18 || hour < 5
        }
    }

    public var nextWindowName: String {
        switch self {
        case .morning: return "Mittag (10:30 - 14:30 Uhr)"
        case .midday: return "Pre-Workout & Nachmittag (14:30 - 18:30 Uhr)"
        case .afternoon: return "Abend & Nachtruhe (ab 18:30 Uhr)"
        case .evening: return "Morgen (ab 05:00 Uhr)"
        }
    }
}

    // MARK: - Midnight Auto-Refresh Engine (00:00:00 Synchronisation)
    private func handleMidnightRollOver() {
        let now = Date()
        currentTime = now
        let calendar = Calendar.current
        let currentDay = calendar.component(.day, from: now)
        guard currentDay != lastDayObserved else { return }
        lastDayObserved = currentDay

        let yesterday = calendar.date(byAdding: .day, value: -1, to: now) ?? now
        if calendar.isDate(selectedDate, inSameDayAs: yesterday) || calendar.isDateInToday(selectedDate) {
            selectedDate = now
        }
        store.handleMidnightReset()
        HapticFeedbackService.shared.lightDetent()
    }

    private func checkMidnightRollOverIfNeeded() {
        let now = Date()
        let calendar = Calendar.current
        let currentDay = calendar.component(.day, from: now)
        if currentDay != lastDayObserved {
            handleMidnightRollOver()
        }
    }

    // MARK: - 3. Dynamischer Fahrplan "Anstehend" (Schedule Window Doktrin)
    // MARK: - 3. Dynamischer Fahrplan "Anstehend" (Schedule Window Doktrin: ±60 Minuten)
    private func isWithinOneHourWindow(scheduledHour: Int, scheduledMinute: Int, currentTime: Date = Date()) -> Bool {
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: currentTime)
        let currentMinute = calendar.component(.minute, from: currentTime)
        let currentMins = currentHour * 60 + currentMinute
        let scheduledMins = scheduledHour * 60 + scheduledMinute

        var diff = scheduledMins - currentMins
        if diff > 720 {
            diff -= 1440
        } else if diff < -720 {
            diff += 1440
        }

        return diff >= -60 && diff <= 60
    }

    private func isDoseInOneHourWindow(_ dose: CircadianSupplementDose, currentTime: Date = Date()) -> Bool {
        let parts = dose.scheduledTime.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2 else { return false }
        return isWithinOneHourWindow(scheduledHour: parts[0], scheduledMinute: parts[1], currentTime: currentTime)
    }

    private func currentDayPendingCount() -> Int {
        let isToday = Calendar.current.isDateInToday(selectedDate)
        guard isToday else { return 0 }

        return store.allSupplements
            .filter { isDoseInOneHourWindow($0, currentTime: currentTime) && !store.isSupplementTaken(doseId: $0.id, date: selectedDate) }
            .count
    }

    private func supplementRow(dose: CircadianSupplementDose) -> some View {
        let isTaken = store.isSupplementTaken(doseId: dose.id, date: selectedDate)
        return HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 6) {
                    Text(dose.scheduledTime)
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(Theme.warmSand)
                    Text(dose.shortName)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.textPrimary)
                }
                Text("\(dose.dosage) • \(dose.instructions)")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(Theme.textMuted)
                    .lineLimit(1)
            }

            Spacer()

            // Info Button (ⓘ) with rich bodily impact & full name
            Button(action: {
                HapticFeedbackService.shared.lightDetent()
                selectedExplanation = InfoExplanationItem(
                    title: dose.name,
                    category: "Zirkadianes Supplement (\(dose.scheduledTime) Uhr)",
                    summary: dose.noviceExplanation.isEmpty ? dose.benefit : dose.noviceExplanation,
                    details: [
                        ExplanationDetail(label: "Kurzzeit-Wirkung (0-4 Stunden)", text: dose.shortTermImpact.isEmpty ? dose.benefit : dose.shortTermImpact),
                        ExplanationDetail(label: "Langzeit-Wirkung (Wochen & Monate)", text: dose.longTermImpact.isEmpty ? dose.mechanism : dose.longTermImpact),
                        ExplanationDetail(label: "Biochemischer Mechanismus", text: dose.mechanism),
                        ExplanationDetail(label: "Dosierung & Einnahme", text: "\(dose.dosage) • \(dose.instructions)"),
                        ExplanationDetail(label: "Zielbereich", text: dose.targetArea),
                        ExplanationDetail(label: "Sicherheitsstandard", text: "Strikte Anti-Doppelgabe-Regel: Verpasste Dosen niemals aufaddieren oder nachholen.")
                    ]
                )
            }) {
                Image(systemName: "info.circle")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.warmSand)
                    .padding(4)
            }
            .buttonStyle(PlainButtonStyle())

            // Small Checkbox Button on RIGHT side (mit Anti-Doppelgabe-Sperre)
            Button(action: {
                store.toggleSupplement(doseId: dose.id, date: selectedDate)
            }) {
                ZStack {
                    Circle()
                        .fill(isTaken ? Theme.sageGreen : Theme.surface)
                        .frame(width: 26, height: 26)
                        .overlay(Circle().stroke(isTaken ? Theme.sageGreen : Theme.border, lineWidth: 1))
                    Image(systemName: isTaken ? "lock.fill" : "plus")
                        .font(.system(size: isTaken ? 9 : 11, weight: .bold))
                        .foregroundColor(isTaken ? Theme.bg : Theme.warmSand)
                }
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(isTaken)
        }
        .padding(8)
        .contextMenu {
            if isTaken {
                Button {
                    store.toggleSupplement(doseId: dose.id, date: selectedDate, forceUnlock: true)
                } label: {
                    Label("Sperre aufheben (Korrektur)", systemImage: "lock.open")
                }
            }

            Button {
                editingSupplementDose = dose
                showingEditSupplementSheet = true
            } label: {
                Label("Bearbeiten", systemImage: "pencil")
            }

            Button(role: .destructive) {
                store.deleteSupplementDose(id: dose.id)
            } label: {
                Label("Löschen", systemImage: "trash")
            }
        }
        .background(RoundedRectangle(cornerRadius: 8).fill(Theme.surfaceElevated))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 1))
    }

    private func metricTile(title: String, value: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(Theme.textMuted)
                .tracking(0.5)
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .monospaced))
                .foregroundColor(accent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 8).fill(Theme.surfaceElevated))
    }

    private var dynamicDateTitle: String {
        let cal = Calendar.current
        if cal.isDateInToday(selectedDate) {
            return "Heute"
        } else if cal.isDateInYesterday(selectedDate) {
            return "Gestern"
        } else {
            let df = DateFormatter()
            df.locale = Locale(identifier: "de_DE")
            df.dateFormat = "d. MMMM"
            return df.string(from: selectedDate)
        }
    }

    // MARK: - Trainingsreiz-Kompensation (Grow Integration)
    @ViewBuilder
    private func trainingStrainCard(_ workout: SharedWorkoutPayload) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "figure.run")
                        .foregroundColor(Color(red: 0.85, green: 0.40, blue: 0.20))
                    Text("TRAININGSREIZ-KOMPENSATION (GROW)")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(red: 0.85, green: 0.40, blue: 0.20))
                }
                Spacer()
                Text("\(workout.durationMinutes) min • RPE \(workout.perceivedExertionRPE)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Theme.textMuted)
            }

            Text(workout.title)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Theme.textPrimary)

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("GESAMTTONNAGE")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundColor(Theme.textMuted)
                    Text("\(Int(workout.totalTonnageKg)) kg")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(Theme.textPrimary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("AKTIVER UMSATZ")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundColor(Theme.textMuted)
                    Text("+\(Int(workout.caloriesBurned)) kcal")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(Theme.warmSand)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("ERHOLUNGSBEDARF")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundColor(Theme.textMuted)
                    if store.hasHeavyLegDayStimulus {
                        Text("+35g Carbs • +500ml")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Theme.sageGreen)
                    } else {
                        Text("Erhaltungsbudget")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Theme.textSecondary)
                    }
                }
            }

            if store.hasHeavyLegDayStimulus {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Theme.sageGreen)
                        .frame(width: 6, height: 6)
                    Text("Schwerer Beintag (> 10.000 kg Volumen): Tagesziel automatisch um +35g Kohlenhydrate und +500ml Wasser angehoben.")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Theme.sageGreen)
                }
                .padding(.top, 2)
            }
        }
        .padding(12)
        .background(Color(white: 0.10))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(red: 0.85, green: 0.40, blue: 0.20).opacity(0.35), lineWidth: 1)
        )
    }
}

public struct ConsumedRecipeBatchIdentifier: Identifiable {
    public var id: String { batchId }
    public var name: String
    public var batchId: String

    public init(name: String, batchId: String) {
        self.name = name
        self.batchId = batchId
    }
}

struct JournalGroupedEntry: Identifiable {
    var id: String
    var isRecipe: Bool
    var recipeName: String?
    var recipeBatchId: String?
    var singleLog: MealLogEntry?
    var batchLogs: [MealLogEntry]
}

public struct RecipeConsumedDetailSheet: View {
    public let recipeName: String
    public let batchId: String
    @ObservedObject var store: LocalStore
    @Environment(\.dismiss) private var dismiss

    @State private var editingLog: MealLogEntry?
    @State private var inspectingLog: MealLogEntry? = nil

    public init(recipeName: String, batchId: String, store: LocalStore) {
        self.recipeName = recipeName
        self.batchId = batchId
        self.store = store
    }

    private var batchLogs: [MealLogEntry] {
        store.mealLogs.filter { $0.recipeBatchId == batchId }
    }

    private var totalWeight: Double {
        batchLogs.reduce(0) { $0 + $1.weightGrams }
    }

    private var totalKcal: Double {
        batchLogs.reduce(0) { $0 + $1.kcal }
    }

    private var totalProtein: Double {
        batchLogs.reduce(0) { $0 + $1.protein }
    }

    private var totalCarbs: Double {
        batchLogs.reduce(0) { $0 + $1.carbs }
    }

    private var totalFat: Double {
        batchLogs.reduce(0) { $0 + $1.fat }
    }

    private var totalFiber: Double {
        batchLogs.reduce(0) { $0 + $1.fiber }
    }

    private var totalCost: Double {
        batchLogs.reduce(0) { $0 + $1.cost }
    }

    private var cleanTitle: String {
        recipeName.replacingOccurrences(of: "^[0-9]+[.\\s]+", with: "", options: .regularExpression)
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header Bar
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("VERZEHRTES REZEPT")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(Theme.warmSand)
                            .tracking(1.0)
                        Text(cleanTitle)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(Theme.textPrimary)
                    }
                    Spacer()
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Fertig")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Theme.sageGreen)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(Theme.surfaceElevated))
                    }
                }
                .padding(16)
                .background(Theme.bg)

                Divider().background(Theme.border)

                ScrollView {
                    VStack(spacing: 14) {
                        // Summary Stats Card
                        VStack(spacing: 8) {
                            HStack(spacing: 8) {
                                statTile(title: "GESAMTGEWICHT", value: "\(Int(totalWeight)) g", color: Theme.warmSand)
                                statTile(title: "KALORIEN", value: "\(Int(totalKcal)) kcal", color: Theme.textPrimary)
                                statTile(title: "KOSTEN", value: String(format: "%.2f €", totalCost), color: Theme.sageLight)
                            }

                            HStack(spacing: 8) {
                                statTile(title: "PROTEIN", value: String(format: "%.1f g", totalProtein), color: Color(red: 0.96, green: 0.25, blue: 0.37))
                                statTile(title: "CARBS", value: "\(Int(totalCarbs)) g", color: Color(red: 0.58, green: 0.88, blue: 0.28))
                                statTile(title: "FETT", value: "\(Int(totalFat)) g", color: Color(red: 0.0, green: 0.82, blue: 0.92))
                                statTile(title: "FASER", value: String(format: "%.1f g", totalFiber), color: Theme.sageGreen)
                            }
                        }
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Theme.surfaceElevated))

                        // Ingredients Breakdown
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("ENTHALTENE ZUTATEN (\(batchLogs.count))")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(Theme.textMuted)
                                    .tracking(0.8)
                                Spacer()
                            }

                            if batchLogs.isEmpty {
                                Text("Keine Zutaten mehr im Eintrag vorhanden.")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(Theme.textMuted)
                                    .padding(.vertical, 12)
                            } else {
                                VStack(spacing: 6) {
                                    ForEach(batchLogs) { log in
                                        HStack(spacing: 10) {
                                            Button(action: {
                                                HapticFeedbackService.shared.lightDetent()
                                                inspectingLog = log
                                            }) {
                                                VStack(alignment: .leading, spacing: 2) {
                                                    HStack(spacing: 5) {
                                                        Text(log.foodName)
                                                            .font(.system(size: 13, weight: .semibold))
                                                            .foregroundColor(Theme.textPrimary)
                                                            .lineLimit(1)
                                                        Image(systemName: "info.circle")
                                                            .font(.system(size: 11))
                                                            .foregroundColor(Theme.sageGreen)
                                                    }
                                                    HStack(spacing: 4) {
                                                        Text("\(Int(log.weightGrams))g")
                                                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                                                            .foregroundColor(Theme.warmSand)
                                                        Text("•")
                                                            .foregroundColor(Theme.textMuted)
                                                        Text("\(String(format: "%.1f", log.protein))g P")
                                                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                                                            .foregroundColor(Theme.sageGreen)
                                                        Text("•")
                                                            .foregroundColor(Theme.textMuted)
                                                        Text("\(Int(log.kcal)) kcal")
                                                            .font(.system(size: 10, weight: .regular, design: .monospaced))
                                                            .foregroundColor(Theme.textSecondary)
                                                    }
                                                }
                                            }
                                            .buttonStyle(PlainButtonStyle())

                                            Spacer()

                                            VStack(alignment: .trailing, spacing: 2) {
                                                Text(String(format: "%.2f €", log.cost))
                                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                                    .foregroundColor(Theme.textSecondary)

                                                HStack(spacing: 6) {
                                                    Button(action: {
                                                        HapticFeedbackService.shared.lightDetent()
                                                        editingLog = log
                                                    }) {
                                                        Text("Bearbeiten")
                                                            .font(.system(size: 9, weight: .medium))
                                                            .foregroundColor(Theme.warmSand)
                                                    }
                                                    Button(action: {
                                                        HapticFeedbackService.shared.mechanicalClick()
                                                        store.deleteMealLog(id: log.id)
                                                    }) {
                                                        Text("Entfernen")
                                                            .font(.system(size: 9, weight: .regular))
                                                            .foregroundColor(Theme.terracotta)
                                                    }
                                                }
                                            }
                                        }
                                        .padding(8)
                                        .wellnessCard(borderColor: Theme.border, cornerRadius: 8)
                                    }
                                }
                            }
                        }

                        // Danger Zone: Delete Whole Recipe
                        Button(action: {
                            HapticFeedbackService.shared.mechanicalClick()
                            store.deleteRecipeBatch(batchId: batchId)
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                    .font(.system(size: 12, weight: .semibold))
                                Text("Gesamtes Rezept aus Tagebuch löschen")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundColor(Theme.terracotta)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(RoundedRectangle(cornerRadius: 10).fill(Theme.surfaceElevated))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.terracotta.opacity(0.3), lineWidth: 1))
                        }
                        .padding(.top, 8)
                    }
                    .padding(16)
                }
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationBarHidden(true)
            .sheet(item: $editingLog) { log in
                EditMealLogSheet(log: log, store: store)
            }
            .sheet(item: $inspectingLog) { log in
                NutritionDetailSheet(log: log, store: store)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    private func statTile(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(Theme.textMuted)
                .tracking(0.5)
            Text(value)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(6)
        .background(RoundedRectangle(cornerRadius: 6).fill(Theme.surface))
    }
}

