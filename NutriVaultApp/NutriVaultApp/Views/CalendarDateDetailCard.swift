import SwiftUI

public struct CalendarDateDetailCard: View {
    @Binding public var selectedDate: Date
    @Binding public var isDetailExpanded: Bool
    @ObservedObject var store = LocalStore.shared
    @ObservedObject var notifications = SupplementNotificationService.shared

    @State private var currentTime = Date()
    @State private var showAllSupplements: Bool = false
    @State private var inspectingLog: MealLogEntry? = nil
    @State private var inspectingRecipeBatch: ConsumedRecipeBatchIdentifier? = nil
    @State private var activeSupplementExplanation: InfoExplanationItem? = nil
    @State private var showingAddPastMealSheet: Bool = false

    private let calendar = Calendar.current
    let timer = Timer.publish(every: 60.0, on: .main, in: .common).autoconnect()

    public init(selectedDate: Binding<Date>, isDetailExpanded: Binding<Bool>) {
        self._selectedDate = selectedDate
        self._isDetailExpanded = isDetailExpanded
    }

    public var body: some View {
        let isToday = calendar.isDateInToday(selectedDate)
        let dayLogs = store.logs(for: selectedDate)
        let suppCount = store.completedSupplementsCount(date: selectedDate)
        let totalCost = store.cost(for: selectedDate)

        VStack(alignment: .leading, spacing: 14) {
            // Header Bar
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Theme.sageGreen)
                        Text(isToday ? "HEUTE • MAHLZEITEN & WIRKSTOFFE" : "TAGESDETAIL • \(weekdayName(selectedDate).uppercased())")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Theme.sageGreen)
                            .tracking(0.6)
                    }
                    Text(formattedFullDate(selectedDate))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Theme.textPrimary)
                }
                Spacer()

                HStack(spacing: 8) {
                    Text(String(format: "%.2f €", totalCost))
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(Theme.warmSand)

                    Button {
                        withAnimation(.easeInOut(duration: 0.22)) {
                            isDetailExpanded = false
                        }
                        HapticFeedbackService.shared.lightDetent()
                    } label: {
                        Image(systemName: "chevron.up")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Theme.textMuted)
                            .padding(6)
                            .background(Circle().fill(Theme.surfaceElevated))
                    }
                }
            }

            // SECTION 1: ZIRKADIANE WIRKSTOFFE (SUPPLEMENTE)
            circadianSupplementsSection(isToday: isToday, suppCount: suppCount)

            Divider().background(Theme.border)

            // SECTION 2: VERZEHRTE MAHLZEITEN
            mealsSection(dayLogs: dayLogs)

            Divider().background(Theme.border)

            // SECTION 3: TAGESNOTIZEN (PERSISTENT IN daily_notes.json)
            dailyNotesSection

            Divider().background(Theme.border)

            // Bottom Thumb-Zone Collapse Button (iPhone 16 Pro Max Ergonomie)
            Button(action: {
                withAnimation(.easeInOut(duration: 0.22)) {
                    isDetailExpanded = false
                }
                HapticFeedbackService.shared.lightDetent()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 11, weight: .bold))
                    Text("Tagesdetails einklappen")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(Theme.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 10).fill(Theme.surfaceElevated))
            }
        }
        .padding(14)
        .wellnessCard(borderColor: Theme.sageGreen.opacity(0.3))
        .onReceive(timer) { input in
            currentTime = input
        }
        .sheet(item: $inspectingLog) { log in
            EditMealLogSheet(log: log, store: store)
        }
        .sheet(item: $inspectingRecipeBatch) { batch in
            RecipeConsumedDetailSheet(recipeName: batch.name, batchId: batch.batchId, store: store)
        }
        .sheet(item: $activeSupplementExplanation) { info in
            InfoExplanationSheet(item: info)
        }
        .sheet(isPresented: $showingAddPastMealSheet) {
            AddPastMealSheet(targetDate: selectedDate, store: store)
        }
    }

    // MARK: - Section 1: Circadian Supplements
    private func circadianSupplementsSection(isToday: Bool, suppCount: Int) -> some View {
        let currentWindowDoses = CircadianSupplementProtocol.dailySchedule.filter { dose in
            CircadianSupplementProtocol.isDoseInCurrentWindow(dose: dose, currentTime: currentTime)
        }
        let nextDose = CircadianSupplementProtocol.nextScheduledDose(currentTime: currentTime)

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 5) {
                    Image(systemName: "pills.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Theme.sageGreen)
                    Text("ZIRKADIANE WIRKSTOFFE")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Theme.textMuted)
                        .tracking(0.6)
                }

                Spacer()

                Text("\(suppCount)/\(CircadianSupplementProtocol.dailySchedule.count) eingenommen")
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .foregroundColor(suppCount == CircadianSupplementProtocol.dailySchedule.count ? Theme.sageGreen : Theme.warmSand)

                Button(action: {
                    HapticFeedbackService.shared.lightDetent()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showAllSupplements.toggle()
                    }
                }) {
                    Text(showAllSupplements ? "Aktives Fenster" : "Alle 10")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Theme.sageGreen)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(RoundedRectangle(cornerRadius: 4).fill(Theme.surfaceElevated))
                }
            }

            if showAllSupplements || !isToday {
                VStack(spacing: 6) {
                    ForEach(CircadianSupplementProtocol.dailySchedule) { dose in
                        supplementItemRow(dose: dose)
                    }
                }
            } else {
                if currentWindowDoses.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Theme.sageGreen)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Aktuelles Wirkstoff-Fenster erledigt")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(Theme.textPrimary)
                            if let next = nextDose {
                                Text("Nächste Dosis um \(next.scheduledTime) Uhr: \(next.name)")
                                    .font(.system(size: 10))
                                    .foregroundColor(Theme.textMuted)
                            }
                        }
                        Spacer()
                    }
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Theme.surfaceElevated))
                } else {
                    VStack(spacing: 6) {
                        ForEach(currentWindowDoses) { dose in
                            supplementItemRow(dose: dose)
                        }
                    }
                }
            }
        }
    }

    private func supplementItemRow(dose: CircadianSupplementDose) -> some View {
        let isTaken = store.isSupplementTaken(doseId: dose.id, date: selectedDate)

        return HStack(spacing: 8) {
            Button(action: {
                store.toggleSupplement(doseId: dose.id, date: selectedDate)
            }) {
                Image(systemName: isTaken ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isTaken ? Theme.sageGreen : Theme.textMuted)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(dose.scheduledTime)
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(Theme.warmSand)

                    Text(dose.name)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(isTaken ? Theme.textSecondary : Theme.textPrimary)
                        .strikethrough(isTaken)

                    Spacer()

                    Text(dose.dosage)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(Theme.textSecondary)
                }

                Text("\(dose.targetArea) • \(dose.instructions)")
                    .font(.system(size: 9))
                    .foregroundColor(Theme.textMuted)
                    .lineLimit(1)
            }

            Button {
                HapticFeedbackService.shared.lightDetent()
                activeSupplementExplanation = InfoExplanationItem(
                    title: dose.name,
                    category: "Zirkadianer Wirkstoff (\(dose.scheduledTime) Uhr)",
                    summary: "\(dose.mechanism). \(dose.benefit)",
                    details: [
                        ExplanationDetail(label: "Dosierung", text: dose.dosage),
                        ExplanationDetail(label: "Zielbereich", text: dose.targetArea),
                        ExplanationDetail(label: "Einnahmehinweis", text: dose.instructions),
                        ExplanationDetail(label: "Wirkmechanismus", text: dose.mechanism),
                        ExplanationDetail(label: "Sicherheits-Standard", text: "Strikte Anti-Doppelgabe-Regel: Verpasste Dosen nicht nachholen.")
                    ]
                )
            } label: {
                Image(systemName: "info.circle")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.textMuted)
            }
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 8).fill(Theme.surfaceElevated))
    }

    // MARK: - Section 2: Meals
    private func mealsSection(dayLogs: [MealLogEntry]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 5) {
                    Image(systemName: "fork.knife")
                        .font(.system(size: 10))
                        .foregroundColor(Theme.warmSand)
                    Text("VERZEHRTE MAHLZEITEN")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Theme.textMuted)
                        .tracking(0.6)
                }
                Spacer()

                Button {
                    HapticFeedbackService.shared.lightDetent()
                    showingAddPastMealSheet = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text("Mahlzeit nachtragen")
                    }
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(Theme.sageGreen)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(RoundedRectangle(cornerRadius: 4).fill(Theme.surfaceElevated))
                }

                Text("\(dayLogs.count) Einträge")
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .foregroundColor(Theme.textMuted)
            }

            if dayLogs.isEmpty {
                Text("Keine Mahlzeiten an diesem Tag erfasst.")
                    .font(.system(size: 11))
                    .foregroundColor(Theme.textMuted)
                    .padding(.vertical, 4)
            } else {
                let grouped = groupLogs(dayLogs)
                VStack(spacing: 6) {
                    ForEach(grouped) { item in
                        if item.isRecipe, let batch = item.batchLogs {
                            recipeGroupCard(item: item, batch: batch)
                        } else if let log = item.singleLog {
                            singleMealRow(log: log)
                        }
                    }
                }
            }
        }
    }

    private func singleMealRow(log: MealLogEntry) -> some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(log.foodName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                    .lineLimit(1)
                Text("\(Int(log.weightGrams)) g • \(log.mealType)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(Theme.textMuted)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(log.kcal)) kcal")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.textPrimary)
                Text("+\(Int(log.protein)) g P")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundColor(Theme.sageGreen)
            }

            Button {
                HapticFeedbackService.shared.lightDetent()
                inspectingLog = log
            } label: {
                Image(systemName: "pencil.circle")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.textMuted)
            }
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 8).fill(Theme.surfaceElevated))
    }

    private func recipeGroupCard(item: JournalGroupedItem, batch: [MealLogEntry]) -> some View {
        let batchKcal = batch.reduce(0.0) { $0 + $1.kcal }
        let batchProtein = batch.reduce(0.0) { $0 + $1.protein }

        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: "book.closed.fill")
                            .font(.system(size: 10))
                            .foregroundColor(Theme.sageGreen)
                        Text(item.recipeName)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Theme.textPrimary)
                            .lineLimit(1)
                    }
                    Text("Rezept-Verbund (\(batch.count) Zutaten)")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(Theme.textMuted)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(batchKcal)) kcal")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(Theme.textPrimary)
                    Text("+\(Int(batchProtein)) g P")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundColor(Theme.sageGreen)
                }

                Button {
                    HapticFeedbackService.shared.lightDetent()
                    if let batchId = item.recipeBatchId {
                        inspectingRecipeBatch = ConsumedRecipeBatchIdentifier(name: item.recipeName, batchId: batchId)
                    }
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.sageGreen)
                }
            }

            // Sub-rows for each ingredient in the recipe
            VStack(spacing: 4) {
                ForEach(batch) { log in
                    HStack {
                        Text("• \(Int(log.weightGrams))g \(log.foodName)")
                            .font(.system(size: 10))
                            .foregroundColor(Theme.textSecondary)
                        Spacer()
                        Text("+\(Int(log.protein))g P")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(Theme.sageGreen.opacity(0.8))

                        Button {
                            HapticFeedbackService.shared.lightDetent()
                            inspectingLog = log
                        } label: {
                            Image(systemName: "pencil")
                                .font(.system(size: 10))
                                .foregroundColor(Theme.textMuted)
                        }
                    }
                    .padding(.vertical, 1)
                }
            }
            .padding(.leading, 8)
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 8).fill(Theme.surfaceElevated))
    }

    // MARK: - Section 3: Daily Notes (daily_notes.json)
    private var dailyNotesSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                HStack(spacing: 5) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 10))
                        .foregroundColor(Theme.warmSand)
                    Text("TAGESNOTIZEN (WOHLBEFINDEN, REHA, REFLUX)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Theme.textMuted)
                        .tracking(0.6)
                }
                Spacer()
            }

            ZStack(alignment: .topLeading) {
                if store.note(for: selectedDate).isEmpty {
                    Text("Notiz für diesen Tag erfassen (z. B. Stuhlgang Typ 4, Reflux-Symptome, Reha-Fortschritt)...")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.textMuted)
                        .padding(.top, 8)
                        .padding(.leading, 5)
                }

                TextEditor(text: Binding(
                    get: { store.note(for: selectedDate) },
                    set: { store.setNote($0, for: selectedDate) }
                ))
                .font(.system(size: 11))
                .foregroundColor(Theme.textPrimary)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 56)
            }
            .padding(6)
            .background(RoundedRectangle(cornerRadius: 8).fill(Theme.surfaceElevated))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 1))
        }
    }

    // MARK: - Helpers
    private static let weekdayFormatter: DateFormatter = {
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

    private func weekdayName(_ date: Date) -> String {
        return Self.weekdayFormatter.string(from: date)
    }

    private func formattedFullDate(_ date: Date) -> String {
        return Self.fullDateFormatter.string(from: date)
    }

    private func groupLogs(_ logs: [MealLogEntry]) -> [JournalGroupedItem] {
        var items: [JournalGroupedItem] = []
        var seenBatchIds: Set<String> = []

        for log in logs {
            if let bId = log.recipeBatchId, !bId.isEmpty {
                if !seenBatchIds.contains(bId) {
                    seenBatchIds.insert(bId)
                    let matching = logs.filter { $0.recipeBatchId == bId }
                    items.append(
                        JournalGroupedItem(
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
                    JournalGroupedItem(
                        id: log.id,
                        isRecipe: false,
                        recipeName: log.mealType,
                        recipeBatchId: nil,
                        singleLog: log,
                        batchLogs: nil
                    )
                )
            }
        }
        return items
    }
}

public struct JournalGroupedItem: Identifiable {
    public let id: String
    public let isRecipe: Bool
    public let recipeName: String
    public let recipeBatchId: String?
    public let singleLog: MealLogEntry?
    public let batchLogs: [MealLogEntry]?
}
