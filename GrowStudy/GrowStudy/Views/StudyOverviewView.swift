import SwiftUI
import UniformTypeIdentifiers

public struct StudyOverviewView: View {
    @EnvironmentObject private var store: StudyStore
    @ObservedObject private var calSync = StudyCalendarSyncService.shared

    @State private var selectedDate: Date = Date()
    @State private var showingLogPlanningSheet: Bool = false
    @State private var planningSheetTargetDate: Date = Date()
    @State private var selectedStepForDetail: RoadmapStep? = nil
    @State private var kanbanSearchText: String = ""
    @State private var showAddModuleSheet: Bool = false

    // Folder Architecture & Single Active Expanded Task
    @State private var selectedFolderId: String? = nil
    @State private var selectedSingleList: String? = nil
    @State private var isSidePanelVisible: Bool = true
    @State private var isListsSectionExpanded: Bool = true
    @State private var isTermineSectionTargeted: Bool = false
    @State private var activeExpandedTaskId: String? = nil
    @State private var showingCreateFolderAlert: Bool = false
    @State private var newFolderName: String = ""
    @State private var showingCreateListAlert: Bool = false
    @State private var newListName: String = ""
    @State private var folderToRename: StudyFolder? = nil
    @State private var renameFolderName: String = ""
    @State private var showingLabelsSheet: Bool = false
    @State private var isWorkoutsExpanded: Bool = true
    @State private var isMealsExpanded: Bool = false
    @State private var isSuppsExpanded: Bool = false
    @State private var isStudyExpanded: Bool = true

    public init() {}

    public var body: some View {
        NavigationStack {
            GeometryReader { geo in
                let kanbanCardHeight = max(geo.size.height - 80, 780)

                ScrollView {
                    VStack(spacing: 16) {
                        // 1. 2-Way Google Calendar Panel Strip
                        StudyCalendarStripView(
                            selectedDate: $selectedDate,
                            currentTrack: nil,
                            showsDetailBanner: false
                        )

                        // 2. Merged Termine & Lerneinheiten Section (For Selected Date)
                        mergedTermineAndLogSectionForSelectedDate

                        // 3. Kanban-Board (Google Tasks Architecture für alle Module & Phasen)
                        kanbanBoardSection(cardHeight: kanbanCardHeight)
                    }
                    .padding(16)
                }
            }
            .background(
                Group {
                    Button("Widerrufen") {
                        store.undo()
                    }
                    .keyboardShortcut("z", modifiers: .command)

                    Button("Wiederholen") {
                        store.redo()
                    }
                    .keyboardShortcut("z", modifiers: [.command, .shift])
                }
                .opacity(0.0001)
                .frame(width: 0, height: 0)
            )
            .onKeyPress(KeyEquivalent("z"), phases: .down) { press in
                if press.modifiers == [.command, .shift] {
                    store.redo()
                    return .handled
                } else if press.modifiers == .command {
                    store.undo()
                    return .handled
                }
                return .ignored
            }
            .background(Color(red: 0.08, green: 0.08, blue: 0.09).ignoresSafeArea())
            .navigationTitle("Übersicht")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    StudyCircularProfileButton()
                }
            }
            .sheet(isPresented: $showingLogPlanningSheet) {
                StudyLogPlanningSheet(targetDate: planningSheetTargetDate)
                    .environmentObject(store)
            }
            .sheet(item: $selectedStepForDetail) { step in
                StepDetailSheet(step: step)
                    .environmentObject(store)
            }
            .sheet(isPresented: $showAddModuleSheet) {
                AddCustomModuleSheet()
                    .environmentObject(store)
            }
            .sheet(isPresented: $showingLabelsSheet) {
                TaskLabelsManagementSheet()
                    .environmentObject(store)
            }
            .alert("Neuen Ordner erstellen", isPresented: $showingCreateFolderAlert) {
                TextField("Ordnername (z. B. Mathematik)", text: $newFolderName)
                Button("Abbrechen", role: .cancel) {}
                Button("Erstellen") {
                    let clean = newFolderName.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !clean.isEmpty {
                        let f = store.createFolder(name: clean)
                        selectedFolderId = f.id
                    }
                }
            } message: {
                Text("Erstelle einen Ordner, um mehrere Aufgabenlisten per Drag & Drop zu bündeln.")
            }
            .alert("Neue Liste erstellen", isPresented: $showingCreateListAlert) {
                TextField("Listenname (z. B. Lineare Algebra)", text: $newListName)
                Button("Abbrechen", role: .cancel) {}
                Button("Erstellen") {
                    let clean = newListName.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !clean.isEmpty {
                        _ = store.createList(name: clean, inFolderId: selectedFolderId)
                    }
                }
            } message: {
                Text("Erstellt eine neue Liste nach Google-Tasks-Standard.")
            }
            .alert("Ordner umbenennen", isPresented: Binding(
                get: { folderToRename != nil },
                set: { if !$0 { folderToRename = nil } }
            )) {
                TextField("Neuer Name", text: $renameFolderName)
                Button("Abbrechen", role: .cancel) { folderToRename = nil }
                Button("Speichern") {
                    if let f = folderToRename {
                        store.renameFolder(id: f.id, newName: renameFolderName)
                    }
                    folderToRename = nil
                }
            }
        }
    }

    // MARK: - 3. Merged Termine & Lerneinheiten Section (Date-Specific Log & Appointments)
    private var mergedTermineAndLogSectionForSelectedDate: some View {
        let plannedSteps = store.plannedSteps(for: selectedDate)
        let plannedSubs = store.plannedSubmodules(for: selectedDate)
        let dayWorkouts = store.workouts(for: selectedDate)
        let dayMeals = store.meals(for: selectedDate)
        let daySupps = store.supplements(for: selectedDate)
        let totalItems = plannedSteps.count + plannedSubs.count + dayWorkouts.count + dayMeals.count + daySupps.count

        return VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("ECOSYSTEM TAGESPLAN & LOGS")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(StudyTheme.warmSand)
                            .tracking(0.8)

                        if calSync.isAuthorized {
                            Text("Google Cal")
                                .font(.system(size: 8.5, weight: .semibold, design: .monospaced))
                                .foregroundColor(StudyTheme.accent)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1.5)
                                .background(StudyTheme.accent.opacity(0.12))
                                .cornerRadius(4)
                        }
                    }

                    Text(formattedDateHeader(selectedDate))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(StudyTheme.textPrimary)
                }

                Spacer()

                // "+ Modul planen / loggen" Button
                Button(action: {
                    HapticFeedback.medium()
                    planningSheetTargetDate = selectedDate
                    showingLogPlanningSheet = true
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 12, weight: .bold))
                        Text("+ Planen / Loggen")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(StudyTheme.bg)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(StudyTheme.strongBlue))
                }
                .buttonStyle(.plain)
            }

            // Content: Empty State or Scheduled Items List
            if totalItems == 0 {
                HStack(spacing: 10) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 15))
                        .foregroundColor(StudyTheme.textMuted)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Keine Ereignisse für dieses Datum")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(StudyTheme.textSecondary)

                        Text("Weder Aufgaben, Workouts noch Ernährung für dieses Datum geloggt oder terminiert.")
                            .font(.system(size: 10.5))
                            .foregroundColor(StudyTheme.textMuted)
                    }

                    Spacer()
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 10).fill(StudyTheme.surfaceElevated))
            } else {
                VStack(spacing: 12) {
                    // 1. Workouts from Grow (Gym)
                    if !dayWorkouts.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Button(action: {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                    isWorkoutsExpanded.toggle()
                                }
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "figure.strengthtraining.traditional")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(StudyTheme.strongBlue)
                                    Text("TRAINING (GROW)")
                                        .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                                        .foregroundColor(StudyTheme.strongBlue)

                                    Spacer()

                                    let isDone = dayWorkouts.first?.isCompleted == true
                                    Text(isDone ? "Absolviert" : "Geplant")
                                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                                        .foregroundColor(isDone ? StudyTheme.appleGreen : StudyTheme.strongBlue)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.white.opacity(0.06))
                                        .cornerRadius(4)

                                    Image(systemName: isWorkoutsExpanded ? "chevron.up" : "chevron.down")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(StudyTheme.textMuted)
                                }
                            }
                            .buttonStyle(.plain)

                            if isWorkoutsExpanded {
                                ForEach(dayWorkouts) { item in
                                    sharedWorkoutRow(item: item)
                                }
                            } else if let firstWorkout = dayWorkouts.first {
                                sharedWorkoutRow(item: firstWorkout)
                            }
                        }
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.02)))
                    }

                    // 2. Meals from Growcery (Nutrition)
                    if !dayMeals.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Button(action: {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                    isMealsExpanded.toggle()
                                }
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "leaf.fill")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(StudyTheme.appleGreen)
                                    Text("ERNÄHRUNG & REZEPTE (GROWCERY)")
                                        .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                                        .foregroundColor(StudyTheme.appleGreen)

                                    Spacer()

                                    let totalP = dayMeals.reduce(0.0) { $0 + $1.protein }
                                    let totalK = dayMeals.reduce(0.0) { $0 + $1.kcal }
                                    Text("\(Int(totalP))g P • \(Int(totalK)) kcal")
                                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                                        .foregroundColor(StudyTheme.appleGreen)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(StudyTheme.appleGreen.opacity(0.12))
                                        .cornerRadius(4)

                                    Image(systemName: isMealsExpanded ? "chevron.up" : "chevron.down")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(StudyTheme.textMuted)
                                }
                            }
                            .buttonStyle(.plain)

                            if isMealsExpanded {
                                ForEach(dayMeals) { meal in
                                    sharedMealRow(meal: meal)
                                }
                            } else if let latest = dayMeals.last {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text("LETZTER EINTRAG: \(latest.mealType.uppercased())")
                                            .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                                            .foregroundColor(StudyTheme.appleGreen)
                                        Spacer()
                                        Text("Tippen für alle Mahlzeiten (\(dayMeals.count))")
                                            .font(.system(size: 8.5))
                                            .foregroundColor(StudyTheme.textMuted)
                                    }
                                    sharedMealRow(meal: latest)
                                }
                            }
                        }
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.02)))
                    }

                    // 3. Circadian Supplements
                    if !daySupps.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Button(action: {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                    isSuppsExpanded.toggle()
                                }
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "pill.fill")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(StudyTheme.warmSand)
                                    Text("ZIRKADIANE SUPPLEMENTE")
                                        .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                                        .foregroundColor(StudyTheme.warmSand)

                                    Spacer()

                                    let takenCount = daySupps.filter { $0.isTaken }.count
                                    Text("\(takenCount)/\(daySupps.count) genommen")
                                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                                        .foregroundColor(takenCount == daySupps.count ? StudyTheme.appleGreen : StudyTheme.textMuted)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.white.opacity(0.06))
                                        .cornerRadius(4)

                                    Image(systemName: isSuppsExpanded ? "chevron.up" : "chevron.down")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(StudyTheme.textMuted)
                                }
                            }
                            .buttonStyle(.plain)

                            if isSuppsExpanded {
                                ForEach(daySupps) { supp in
                                    sharedSupplementRow(supp: supp)
                                }
                            } else if let nextSupp = upcomingSupplement(from: daySupps) {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text("NÄCHSTE DOSIS: \(nextSupp.timeString) UHR")
                                            .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                                            .foregroundColor(StudyTheme.warmSand)
                                        Spacer()
                                        Text("Tippen für alle Dosen (\(daySupps.count))")
                                            .font(.system(size: 8.5))
                                            .foregroundColor(StudyTheme.textMuted)
                                    }
                                    sharedSupplementRow(supp: nextSupp)
                                }
                            }
                        }
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.02)))
                    }

                    // 4. Study Tasks & Submodules
                    if !plannedSteps.isEmpty || !plannedSubs.isEmpty {
                        let totalCount = plannedSteps.count + plannedSubs.count
                        VStack(alignment: .leading, spacing: 6) {
                            Button(action: {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                    isStudyExpanded.toggle()
                                }
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "book.closed.fill")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(StudyTheme.amber)
                                    Text("AUFGABEN & LERNEINHEITEN")
                                        .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                                        .foregroundColor(StudyTheme.amber)

                                    Spacer()

                                    Text("\(totalCount) Aufgaben")
                                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                                        .foregroundColor(StudyTheme.amber)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(StudyTheme.amber.opacity(0.12))
                                        .cornerRadius(4)

                                    Image(systemName: isStudyExpanded ? "chevron.up" : "chevron.down")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(StudyTheme.textMuted)
                                }
                            }
                            .buttonStyle(.plain)

                            if isStudyExpanded {
                                ForEach(plannedSteps) { step in
                                    loggedStepRow(step: step)
                                }
                                ForEach(plannedSubs, id: \.submodule.id) { item in
                                    loggedSubmoduleRow(step: item.step, submodule: item.submodule)
                                }
                            } else {
                                if let firstStep = plannedSteps.first {
                                    loggedStepRow(step: firstStep)
                                } else if let firstSub = plannedSubs.first {
                                    loggedSubmoduleRow(step: firstSub.step, submodule: firstSub.submodule)
                                }
                                if totalCount > 1 {
                                    Text("+ \(totalCount - 1) weitere Aufgaben (Tippen zum Aufklappen)")
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundColor(StudyTheme.textMuted)
                                        .padding(.leading, 8)
                                }
                            }
                        }
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.02)))
                    }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(isTermineSectionTargeted ? StudyTheme.strongBlue.opacity(0.18) : StudyTheme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(isTermineSectionTargeted ? StudyTheme.strongBlue : StudyTheme.border, lineWidth: isTermineSectionTargeted ? 2 : 1)
        )
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isTermineSectionTargeted)
        .onDrop(of: [UTType.text.identifier, "public.text"], isTargeted: $isTermineSectionTargeted) { providers in
            for provider in providers {
                _ = provider.loadObject(ofClass: String.self) { payload, _ in
                    guard let payload = payload else { return }
                    Task { @MainActor in
                        handleDropToSelectedDate(payload: payload)
                    }
                }
            }
            return true
        }
    }

    private func handleDropToSelectedDate(payload: String) {
        if payload.hasPrefix("step:") {
            let stepId = String(payload.dropFirst(5))
            store.updateStepDetails(stepId: stepId, plannedDate: selectedDate)
            HapticFeedback.success()
        } else if payload.hasPrefix("submodule:") {
            let parts = payload.components(separatedBy: ":")
            if parts.count == 3 {
                let parentId = parts[1]
                let subId = parts[2]
                store.updateSubmoduleDetails(parentStepId: parentId, submoduleId: subId, plannedDate: selectedDate)
                HapticFeedback.success()
            }
        }
    }

    // MARK: - Row Renderers
    private func sharedWorkoutRow(item: SharedWorkoutScheduleItem) -> some View {
        HStack(spacing: 10) {
            Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 16))
                .foregroundColor(item.isCompleted ? StudyTheme.appleGreen : StudyTheme.strongBlue)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(StudyTheme.textPrimary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    if let tonnage = item.totalTonnageKg, tonnage > 0 {
                        Text("\(Int(tonnage)) kg Tonnage")
                            .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                            .foregroundColor(StudyTheme.strongBlue)
                    }
                    if let dur = item.durationMinutes, dur > 0 {
                        Text("• \(dur) Min.")
                            .font(.system(size: 9.5, design: .monospaced))
                            .foregroundColor(StudyTheme.textMuted)
                    }
                    if !item.exerciseNames.isEmpty {
                        Text("• \(item.exerciseNames.prefix(3).joined(separator: ", "))")
                            .font(.system(size: 9.5))
                            .foregroundColor(StudyTheme.textSecondary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            if let url = URL(string: "grow://session") {
                Link(destination: url) {
                    Text("Grow")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(StudyTheme.strongBlue)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3.5)
                        .background(StudyTheme.strongBlue.opacity(0.15))
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 10).fill(StudyTheme.surfaceElevated))
    }

    private func sharedMealRow(meal: SharedLoggedMeal) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "fork.knife.circle.fill")
                .font(.system(size: 16))
                .foregroundColor(StudyTheme.appleGreen)

            VStack(alignment: .leading, spacing: 2) {
                Text(meal.foodName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(StudyTheme.textPrimary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(meal.mealType)
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(StudyTheme.appleGreen)
                    Text("• \(Int(meal.protein))g Protein")
                        .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                        .foregroundColor(StudyTheme.textPrimary)
                    Text("• \(Int(meal.kcal)) kcal")
                        .font(.system(size: 9.5, design: .monospaced))
                        .foregroundColor(StudyTheme.textMuted)
                }
            }

            Spacer()

            if let url = URL(string: "growcery://recipe") {
                Link(destination: url) {
                    Text("Growcery")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(StudyTheme.appleGreen)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3.5)
                        .background(StudyTheme.appleGreen.opacity(0.15))
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 10).fill(StudyTheme.surfaceElevated))
    }

    private func sharedSupplementRow(supp: SharedSupplementScheduleItem) -> some View {
        HStack(spacing: 10) {
            Image(systemName: supp.isTaken ? "checkmark.circle.fill" : "pill.fill")
                .font(.system(size: 15))
                .foregroundColor(supp.isTaken ? StudyTheme.appleGreen : StudyTheme.warmSand)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(supp.timeString) • \(supp.title)")
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundColor(StudyTheme.textPrimary)
                    .lineLimit(1)

                Text("\(supp.dosage) — \(supp.targetEffect)")
                    .font(.system(size: 9.5))
                    .foregroundColor(StudyTheme.textMuted)
            }

            Spacer()

            Text(supp.isTaken ? "Genommen" : "Ausstehend")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(supp.isTaken ? StudyTheme.appleGreen : StudyTheme.textMuted)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.white.opacity(0.06))
                .cornerRadius(4)
        }
        .padding(9)
        .background(RoundedRectangle(cornerRadius: 10).fill(StudyTheme.surfaceElevated))
    }

    private func upcomingSupplement(from supps: [SharedSupplementScheduleItem]) -> SharedSupplementScheduleItem? {
        guard !supps.isEmpty else { return nil }
        let now = Date()
        let cal = Calendar.current
        let currentHour = cal.component(.hour, from: now)
        let currentMinute = cal.component(.minute, from: now)
        let currentMinutes = currentHour * 60 + currentMinute

        let sorted = supps.sorted { $0.timeString < $1.timeString }

        // Naechste ausstehende Dosis nach aktueller Uhrzeit
        for item in sorted {
            let parts = item.timeString.components(separatedBy: ":")
            if parts.count == 2, let h = Int(parts[0]), let m = Int(parts[1]) {
                let itemMinutes = h * 60 + m
                if itemMinutes >= currentMinutes && !item.isTaken {
                    return item
                }
            }
        }

        // Falls alle zeitlich ueberschritten sind, die erste noch nicht eingenommene
        if let firstUntaken = sorted.first(where: { !$0.isTaken }) {
            return firstUntaken
        }

        return sorted.first
    }

    private func loggedStepRow(step: RoadmapStep) -> some View {
        HStack(spacing: 10) {
            // Interactive Completion Checkbox
            Button(action: {
                HapticFeedback.success()
                store.toggleCompletion(for: step)
            }) {
                Image(systemName: step.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18))
                    .foregroundColor(step.isCompleted ? StudyTheme.sageGreen : StudyTheme.textMuted)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(step.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(StudyTheme.textPrimary)
                    .lineLimit(1)
                    .strikethrough(step.isCompleted)

                HStack(spacing: 6) {
                    Text("Modul \(step.sequenceNumber)")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(StudyTheme.warmSand)

                    Text("• 17:00 - 18:30 Uhr (Google Cal)")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(StudyTheme.textMuted)
                }
            }

            Spacer()

            Button {
                HapticFeedback.light()
                store.updateStepDetails(stepId: step.id, clearPlannedDate: true)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(StudyTheme.textMuted)
                    .frame(width: 24, height: 24)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(6)
            }
            .buttonStyle(.plain)
            .help("Aus Tagesplanung entfernen")

            Button(action: {
                selectedStepForDetail = step
            }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(StudyTheme.textMuted)
            }
            .buttonStyle(.plain)
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 8).fill(StudyTheme.surface))
        .onDrag {
            NSItemProvider(object: "step:\(step.id)" as NSString)
        }
        .contextMenu {
            Button(role: .destructive) {
                store.updateStepDetails(stepId: step.id, clearPlannedDate: true)
            } label: {
                Label("Termin entfernen", systemImage: "calendar.badge.minus")
            }
        }
    }

    private func loggedSubmoduleRow(step: RoadmapStep, submodule: StudySubmodule) -> some View {
        HStack(spacing: 10) {
            Button(action: {
                HapticFeedback.success()
                store.toggleSubmoduleCompletion(stepId: step.id, submoduleId: submodule.id)
            }) {
                Image(systemName: submodule.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18))
                    .foregroundColor(submodule.isCompleted ? StudyTheme.sageGreen : StudyTheme.textMuted)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(submodule.title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(StudyTheme.textPrimary)
                    .lineLimit(1)
                    .strikethrough(submodule.isCompleted)

                HStack(spacing: 6) {
                    Text(submodule.type.rawValue)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(StudyTheme.cyanAccent)

                    Text("• ~\(submodule.durationMinutes) min")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(StudyTheme.textMuted)
                }
            }

            Spacer()

            Button {
                HapticFeedback.light()
                store.updateSubmoduleDetails(parentStepId: step.id, submoduleId: submodule.id, clearPlannedDate: true)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(StudyTheme.textMuted)
                    .frame(width: 24, height: 24)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(6)
            }
            .buttonStyle(.plain)
            .help("Aus Tagesplanung entfernen")
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 8).fill(StudyTheme.surface))
        .onDrag {
            NSItemProvider(object: "submodule:\(step.id):\(submodule.id)" as NSString)
        }
        .contextMenu {
            Button(role: .destructive) {
                store.updateSubmoduleDetails(parentStepId: step.id, submoduleId: submodule.id, clearPlannedDate: true)
            } label: {
                Label("Termin entfernen", systemImage: "calendar.badge.minus")
            }
        }
    }

    private func formattedDateHeader(_ date: Date) -> String {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateStyle = .medium

        if calendar.isDateInToday(date) {
            return "Heute, \(formatter.string(from: date))"
        } else if calendar.isDateInTomorrow(date) {
            return "Morgen, \(formatter.string(from: date))"
        } else if calendar.isDateInYesterday(date) {
            return "Gestern, \(formatter.string(from: date))"
        }
        return formatter.string(from: date)
    }

    // MARK: - 4. Kanban-Board (Google Tasks Architecture mit Ordnern & Seitenleiste)
    private func kanbanBoardSection(cardHeight: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: 3-Linien-Button (Drawer Toggle), Titel, Suche
            HStack(spacing: 10) {
                // Button aus 3 horizontalen Linien (Drawer Toggle)
                Button(action: {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                        isSidePanelVisible.toggle()
                    }
                    HapticFeedback.selection()
                }) {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(isSidePanelVisible ? StudyTheme.strongBlue : StudyTheme.textSecondary)
                        .padding(8)
                        .background(Circle().fill(Color.white.opacity(isSidePanelVisible ? 0.12 : 0.05)))
                }
                .buttonStyle(.plain)
                .help("Seitenleiste für Ordner & Listen ein-/ausblenden")

                VStack(alignment: .leading, spacing: 2) {
                    Text("MODULE & AUFGABEN")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(StudyTheme.warmSand)
                        .tracking(0.8)

                    Text("Kanban-Board")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Color.white)
                }

                Spacer()

                // Schnelle Suchleiste
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 12))
                        .foregroundColor(StudyTheme.textMuted)

                    TextField("Suchen...", text: $kanbanSearchText)
                        .font(.system(size: 12))
                        .foregroundColor(StudyTheme.textPrimary)
                        .autocorrectionDisabled()

                    if !kanbanSearchText.isEmpty {
                        Button {
                            kanbanSearchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 11))
                                .foregroundColor(StudyTheme.textMuted)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 5)
                .padding(.horizontal, 10)
                .background(Color.white.opacity(0.06))
                .cornerRadius(8)
                .frame(minWidth: 260, maxWidth: 480)
            }
            .padding(.horizontal, 4)

            // Hauptbereich: Einklappbare Seitenleiste (Google Tasks Style) + Horizontales Kanban-Board
            HStack(alignment: .top, spacing: 14) {
                if isSidePanelVisible {
                    tasksSidePanelDrawer(height: cardHeight)
                        .frame(width: 250)
                        .transition(.asymmetric(
                            insertion: .move(edge: .leading).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                }

                // Horizontales Kanban-Board (showsIndicators: false entfernt den schwarzen Balken)
                let displayedPhases = currentDisplayedPhases
                if displayedPhases.isEmpty {
                    emptyFolderDropPlaceholder(height: cardHeight)
                        .frame(maxWidth: .infinity)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .top, spacing: 16) {
                            ForEach(displayedPhases, id: \.self) { phase in
                                GoogleTasksColumnCard(
                                    phaseTitle: phase,
                                    searchText: kanbanSearchText,
                                    activeExpandedTaskId: $activeExpandedTaskId,
                                    onSelectStep: { step in
                                        selectedStepForDetail = step
                                    }
                                )
                                .frame(width: 360, height: cardHeight)
                            }
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 2)
                    }
                    .onDrop(of: [UTType.text.identifier, "public.text"], isTargeted: nil) { providers in
                        for provider in providers {
                            _ = provider.loadObject(ofClass: String.self) { payload, _ in
                                guard let payload = payload else { return }
                                Task { @MainActor in
                                    if payload.hasPrefix("step:") {
                                        let stepId = String(payload.dropFirst(5))
                                        store.updateStepDetails(stepId: stepId, clearPlannedDate: true)
                                        HapticFeedback.success()
                                    } else if payload.hasPrefix("submodule:") {
                                        let parts = payload.components(separatedBy: ":")
                                        if parts.count == 3 {
                                            store.updateSubmoduleDetails(parentStepId: parts[1], submoduleId: parts[2], clearPlannedDate: true)
                                            HapticFeedback.success()
                                        }
                                    }
                                }
                            }
                        }
                        return true
                    }
                }
            }
        }
        .padding(.top, 10)
    }

    private var currentDisplayedPhases: [String] {
        if let single = selectedSingleList {
            return [single]
        }
        guard let fid = selectedFolderId else {
            return store.allPhases()
        }
        return store.lists(in: fid)
    }

    // MARK: - Google Tasks Side Panel Drawer
    private func tasksSidePanelDrawer(height: CGFloat) -> some View {
        return VStack(alignment: .leading, spacing: 12) {
            // 1. Google Tasks "+ Erstellen" Pill Button
            Menu {
                Button {
                    newListName = ""
                    showingCreateListAlert = true
                } label: {
                    Label("Neue Liste erstellen", systemImage: "plus")
                }

                Button {
                    newFolderName = ""
                    showingCreateFolderAlert = true
                } label: {
                    Label("Neuen Ordner erstellen", systemImage: "folder.badge.plus")
                }

                Divider()

                Button {
                    showingLabelsSheet = true
                } label: {
                    Label("Labels verwalten...", systemImage: "tag")
                }

                Button {
                    showAddModuleSheet = true
                } label: {
                    Label("Ausführliches Modul anlegen...", systemImage: "doc.badge.plus")
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                    Text("Erstellen")
                        .font(.system(size: 13, weight: .semibold))
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(StudyTheme.textMuted)
                }
                .foregroundColor(Color.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            // 2. "Alle Aufgaben" Navigation Row (ohne verwirrende Gesamtzahl)
            let isAllSelected = (selectedFolderId == nil && selectedSingleList == nil)
            Button {
                HapticFeedback.selection()
                withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                    selectedFolderId = nil
                    selectedSingleList = nil
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(isAllSelected ? StudyTheme.strongBlue : StudyTheme.textMuted)

                    Text("Alle Aufgaben")
                        .font(.system(size: 13, weight: isAllSelected ? .bold : .medium))
                        .foregroundColor(isAllSelected ? Color.white : StudyTheme.textSecondary)

                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(isAllSelected ? StudyTheme.strongBlue.opacity(0.2) : Color.clear)
                )
            }
            .buttonStyle(.plain)
            .help("Alle Aufgaben anzeigen")

            Divider()
                .background(Color.white.opacity(0.08))

            // 3. "Listen & Ordner" Section Header
            HStack {
                Text("LISTEN & ORDNER")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(StudyTheme.textMuted)
                    .tracking(0.6)

                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isListsSectionExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isListsSectionExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(StudyTheme.textMuted)
                        .padding(4)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 4)

            if isListsSectionExpanded {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 6) {
                        // Ordner mit ihren Listen
                        ForEach(store.folders) { folder in
                            SidePanelFolderRow(
                                folder: folder,
                                isSelected: selectedFolderId == folder.id && selectedSingleList == nil,
                                onSelect: {
                                    HapticFeedback.selection()
                                    withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                                        selectedFolderId = folder.id
                                        selectedSingleList = nil
                                    }
                                },
                                onDropList: { droppedListName in
                                    store.moveList(listName: droppedListName, toFolderId: folder.id)
                                },
                                onRename: {
                                    renameFolderName = folder.name
                                    folderToRename = folder
                                },
                                onDelete: {
                                    if selectedFolderId == folder.id {
                                        selectedFolderId = nil
                                    }
                                    store.deleteFolder(id: folder.id)
                                }
                            )

                            // Wenn dieser Ordner ausgewählt ist, zeige die Listen in ihm
                            if selectedFolderId == folder.id {
                                let folderLists = store.lists(in: folder.id)
                                VStack(alignment: .leading, spacing: 3) {
                                    ForEach(folderLists, id: \.self) { listName in
                                        SidePanelListRow(
                                            listName: listName,
                                            isIndented: true,
                                            isSelected: selectedSingleList == listName,
                                            taskCount: store.steps(in: listName).count,
                                            onSelect: {
                                                HapticFeedback.selection()
                                                withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                                                    selectedSingleList = (selectedSingleList == listName) ? nil : listName
                                                }
                                            },
                                            onRemoveFromFolder: {
                                                store.moveList(listName: listName, toFolderId: nil)
                                            }
                                        )
                                    }
                                }
                                .padding(.leading, 14)
                            }
                        }

                        // Ungrouped Lists (Listen ohne Ordner)
                        let ungrouped = store.ungroupedLists()
                        if !ungrouped.isEmpty {
                            if !store.folders.isEmpty {
                                Text("Weitere Listen")
                                    .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                                    .foregroundColor(StudyTheme.textMuted.opacity(0.8))
                                    .padding(.top, 4)
                                    .padding(.horizontal, 4)
                            }

                            ForEach(ungrouped, id: \.self) { listName in
                                SidePanelListRow(
                                    listName: listName,
                                    isIndented: false,
                                    isSelected: selectedSingleList == listName,
                                    taskCount: store.steps(in: listName).count,
                                    onSelect: {
                                        HapticFeedback.selection()
                                        withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                                            selectedSingleList = (selectedSingleList == listName) ? nil : listName
                                            selectedFolderId = nil
                                        }
                                    },
                                    onRemoveFromFolder: nil
                                )
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
                .frame(maxHeight: max(height - 200, 320))

                Divider()
                    .background(Color.white.opacity(0.08))

                // Unten: Direkte Aktionen "+ Neue Liste" & "+ Neuer Ordner"
                VStack(alignment: .leading, spacing: 4) {
                    Button {
                        HapticFeedback.light()
                        newListName = ""
                        showingCreateListAlert = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus")
                                .font(.system(size: 11, weight: .bold))
                            Text("Neue Liste erstellen")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(StudyTheme.strongBlue)
                        .padding(.vertical, 5)
                        .padding(.horizontal, 6)
                    }
                    .buttonStyle(.plain)

                    Button {
                        HapticFeedback.light()
                        newFolderName = ""
                        showingCreateFolderAlert = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "folder.badge.plus")
                                .font(.system(size: 11, weight: .bold))
                            Text("Neuen Ordner erstellen")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(StudyTheme.textSecondary)
                        .padding(.vertical, 5)
                        .padding(.horizontal, 6)
                    }
                    .buttonStyle(.plain)

                    Button {
                        HapticFeedback.light()
                        showingLabelsSheet = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "tag")
                                .font(.system(size: 11, weight: .bold))
                            Text("Labels verwalten (\(store.labels.count))")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(StudyTheme.textSecondary)
                        .padding(.vertical, 5)
                        .padding(.horizontal, 6)
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(red: 0.11, green: 0.11, blue: 0.13))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .frame(height: height)
    }

    private func emptyFolderDropPlaceholder(height: CGFloat) -> some View {
        let currentFolder = store.folders.first(where: { $0.id == selectedFolderId })
        let folderName = currentFolder?.name ?? "Ordner"

        return VStack(spacing: 14) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 38))
                .foregroundColor(StudyTheme.strongBlue.opacity(0.85))
                .padding(.top, 12)

            Text("\(folderName) ist noch leer")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(Color.white)

            Text("Ziehe eine Aufgabenliste per Drag & Drop hierher (oder auf den Ordner in der Seitenleiste), um sie hinzuzufügen.")
                .font(.system(size: 12))
                .foregroundColor(StudyTheme.textMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)

            HStack(spacing: 12) {
                Button("+ Neue Liste in diesem Ordner anlegen") {
                    newListName = ""
                    showingCreateListAlert = true
                }
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(StudyTheme.bg)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Capsule().fill(StudyTheme.strongBlue))
                .buttonStyle(.plain)

                Button("Alle Aufgaben anzeigen") {
                    selectedFolderId = nil
                    selectedSingleList = nil
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(StudyTheme.textSecondary)
                .buttonStyle(.plain)
            }
            .padding(.top, 6)
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .background(Color(red: 0.12, green: 0.12, blue: 0.13))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.white.opacity(0.08), style: StrokeStyle(lineWidth: 1.5, dash: [6, 6]))
        )
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
        .onDrop(of: [UTType.text.identifier, "public.text"], isTargeted: nil) { providers in
            for provider in providers {
                _ = provider.loadObject(ofClass: String.self) { listName, _ in
                    guard let listName = listName, let fid = selectedFolderId else { return }
                    Task { @MainActor in
                        store.moveList(listName: listName, toFolderId: fid)
                    }
                }
            }
            return true
        }
    }
}

// MARK: - Side Panel Folder Row (Google Tasks Drawer)
struct SidePanelFolderRow: View {
    let folder: StudyFolder
    let isSelected: Bool
    let onSelect: () -> Void
    let onDropList: (String) -> Void
    let onRename: () -> Void
    let onDelete: () -> Void

    @State private var isTargeted: Bool = false
    @EnvironmentObject private var store: StudyStore

    var body: some View {
        let count = store.lists(in: folder.id).count

        HStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: isSelected ? "folder.fill" : "folder")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(isSelected ? StudyTheme.strongBlue : (isTargeted ? StudyTheme.strongBlue : StudyTheme.textSecondary))

                Text(folder.name)
                    .font(.system(size: 12.5, weight: isSelected ? .bold : .medium))
                    .foregroundColor(isSelected ? Color.white : StudyTheme.textPrimary)
                    .lineLimit(1)

                Spacer(minLength: 4)

                Text("\(count)")
                    .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                    .foregroundColor(isSelected ? StudyTheme.strongBlue : StudyTheme.textMuted)
            }

            Menu {
                Button("Ordner umbenennen") {
                    onRename()
                }
                Button("Ordner löschen", role: .destructive) {
                    onDelete()
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 11))
                    .foregroundColor(StudyTheme.textMuted)
                    .padding(4)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(isTargeted ? StudyTheme.strongBlue.opacity(0.3) : (isSelected ? StudyTheme.strongBlue.opacity(0.18) : Color.white.opacity(0.03)))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(isTargeted ? StudyTheme.strongBlue : (isSelected ? StudyTheme.strongBlue.opacity(0.6) : Color.clear), lineWidth: isTargeted ? 1.8 : 1)
        )
        .scaleEffect(isTargeted ? 1.03 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isTargeted)
        .onDrop(of: [UTType.text.identifier, "public.text"], isTargeted: $isTargeted) { providers in
            for provider in providers {
                _ = provider.loadObject(ofClass: String.self) { listName, _ in
                    guard let listName = listName else { return }
                    Task { @MainActor in
                        onDropList(listName)
                    }
                }
            }
            return true
        }
    }
}

// MARK: - Side Panel List Row (Draggable to Folders)
struct SidePanelListRow: View {
    let listName: String
    let isIndented: Bool
    let isSelected: Bool
    let taskCount: Int
    let onSelect: () -> Void
    let onRemoveFromFolder: (() -> Void)?

    @EnvironmentObject private var store: StudyStore

    var body: some View {
        HStack(spacing: 7) {
            HStack(spacing: 7) {
                Image(systemName: isIndented ? "list.bullet.indent" : "list.bullet")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(isSelected ? StudyTheme.strongBlue : StudyTheme.textMuted)

                Text(listName)
                    .font(.system(size: 12, weight: isSelected ? .bold : .regular))
                    .foregroundColor(isSelected ? Color.white : StudyTheme.textSecondary)
                    .lineLimit(1)

                Spacer(minLength: 4)

                Text("\(taskCount)")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundColor(isSelected ? StudyTheme.strongBlue : StudyTheme.textMuted)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                onSelect()
            }

            Menu {
                if let onRemoveFromFolder = onRemoveFromFolder {
                    Button("Aus Ordner entfernen") {
                        onRemoveFromFolder()
                    }
                } else if !store.folders.isEmpty {
                    Menu("In Ordner verschieben") {
                        ForEach(store.folders) { folder in
                            Button(folder.name) {
                                store.moveList(listName: listName, toFolderId: folder.id)
                            }
                        }
                    }
                }
                Button("Liste löschen", role: .destructive) {
                    store.deleteList(name: listName)
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 10))
                    .foregroundColor(StudyTheme.textMuted)
                    .padding(3)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(isSelected ? StudyTheme.strongBlue.opacity(0.18) : Color.clear)
        )
        .onDrag {
            NSItemProvider(object: listName as NSString)
        }
    }
}

// MARK: - Folder Pill View
struct FolderPillView<MenuContent: View>: View {
    let title: String
    let count: Int
    let icon: String
    let isSelected: Bool
    let onSelect: () -> Void
    let onDropList: (String) -> Void
    let menuContent: () -> MenuContent

    init(
        title: String,
        count: Int,
        icon: String,
        isSelected: Bool,
        onSelect: @escaping () -> Void,
        onDropList: @escaping (String) -> Void,
        @ViewBuilder menuContent: @escaping () -> MenuContent
    ) {
        self.title = title
        self.count = count
        self.icon = icon
        self.isSelected = isSelected
        self.onSelect = onSelect
        self.onDropList = onDropList
        self.menuContent = menuContent
    }

    @State private var isTargeted: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            Button(action: onSelect) {
                HStack(spacing: 6) {
                    Image(systemName: isSelected ? "\(icon).fill" : icon)
                        .font(.system(size: 11))
                        .foregroundColor(isSelected ? StudyTheme.bg : (isTargeted ? StudyTheme.strongBlue : StudyTheme.textMuted))

                    Text(title)
                        .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                        .foregroundColor(isSelected ? StudyTheme.bg : Color.white)

                    Text("\(count)")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1.5)
                        .background(isSelected ? Color.black.opacity(0.2) : Color.white.opacity(0.08))
                        .foregroundColor(isSelected ? StudyTheme.bg : StudyTheme.textSecondary)
                        .cornerRadius(6)
                }
            }
            .buttonStyle(.plain)

            if !(MenuContent.self == EmptyView.self) {
                Menu {
                    menuContent()
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 10))
                        .foregroundColor(isSelected ? StudyTheme.bg.opacity(0.8) : StudyTheme.textMuted)
                        .padding(.leading, -2)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(isSelected ? StudyTheme.strongBlue : (isTargeted ? StudyTheme.strongBlue.opacity(0.3) : Color.white.opacity(0.05)))
        )
        .overlay(
            Capsule()
                .stroke(isTargeted ? StudyTheme.strongBlue : (isSelected ? StudyTheme.strongBlue : Color.white.opacity(0.1)), lineWidth: isTargeted ? 2 : 1)
        )
        .scaleEffect(isTargeted ? 1.05 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isTargeted)
        .onDrop(of: [UTType.text.identifier, "public.text"], isTargeted: $isTargeted) { providers in
            for provider in providers {
                _ = provider.loadObject(ofClass: String.self) { listName, _ in
                    guard let listName = listName else { return }
                    Task { @MainActor in
                        onDropList(listName)
                    }
                }
            }
            return true
        }
    }
}

extension FolderPillView where MenuContent == EmptyView {
    init(
        title: String,
        count: Int,
        icon: String,
        isSelected: Bool,
        onSelect: @escaping () -> Void,
        onDropList: @escaping (String) -> Void
    ) {
        self.init(
            title: title,
            count: count,
            icon: icon,
            isSelected: isSelected,
            onSelect: onSelect,
            onDropList: onDropList,
            menuContent: { EmptyView() }
        )
    }
}
