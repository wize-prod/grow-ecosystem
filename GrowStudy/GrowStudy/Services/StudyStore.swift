import Foundation
import SwiftUI
import Combine
import UniformTypeIdentifiers

@MainActor
public final class StudyStore: ObservableObject {
    public static let shared = StudyStore()

    @Published public var steps: [RoadmapStep] = []
    @Published public var quotes: [StoicQuote] = []
    @Published public var activeTrack: StudyTrack = .wirtschaftsinformatik
    @Published public var currentQuote: StoicQuote
    @Published public var streakDays: Int = 1
    @Published public var totalStudyMinutesToday: Int = 0
    
    // Focus Timer State
    @Published public var isFocusTimerRunning: Bool = false
    @Published public var focusTimerSecondsRemaining: Int = 1500 // 25 min default
    @Published public var activeTimerStepId: String? = nil

    public var activeTimerTitle: String? {
        guard let id = activeTimerStepId else { return nil }
        if let step = steps.first(where: { $0.id == id }) {
            return step.title
        }
        for step in steps {
            if let sub = step.submodules.first(where: { $0.id == id }) {
                return sub.title
            }
        }
        return nil
    }

    public var activeTimerStep: RoadmapStep? {
        guard let id = activeTimerStepId else { return nil }
        if let step = steps.first(where: { $0.id == id }) {
            return step
        }
        for step in steps {
            if step.submodules.contains(where: { $0.id == id }) {
                return step
            }
        }
        return nil
    }

    public var activeTimerSubmodule: StudySubmodule? {
        guard let id = activeTimerStepId else { return nil }
        for step in steps {
            if let sub = step.submodules.first(where: { $0.id == id }) {
                return sub
            }
        }
        return nil
    }

    // Folder Architecture & Custom Lists
    @Published public var folders: [StudyFolder] = []
    @Published public var customListNames: [String] = []

    // Task Color Labels (Google Tasks Standard)
    @Published public var labels: [TaskColorLabel] = []

    // Water & Hydration State (3-App Synced)
    @Published public var todayWaterMl: Double = 0.0
    @Published public var targetWaterMl: Double = 2500.0

    // Ecosystem Shared Schedule & History (Past, Present & Future)
    @Published public var sharedMeals: [SharedLoggedMeal] = []
    @Published public var sharedWorkouts: [SharedWorkoutScheduleItem] = []
    @Published public var sharedSupplements: [SharedSupplementScheduleItem] = []

    private var timerCancellable: AnyCancellable?
    private let fileManager = FileManager.default
    private let progressURL: URL
    private let subtasksURL: URL
    private let submodulesURL: URL
    private let planningURL: URL
    private let customizationsURL: URL
    private let allStepsURL: URL
    private let foldersURL: URL
    private let customListsURL: URL
    private let labelsURL: URL

    private init() {
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.progressURL = docs.appendingPathComponent("study_progress.json")
        self.subtasksURL = docs.appendingPathComponent("study_subtasks.json")
        self.submodulesURL = docs.appendingPathComponent("study_submodules.json")
        self.planningURL = docs.appendingPathComponent("study_planning.json")
        self.customizationsURL = docs.appendingPathComponent("study_custom_attachments.json")
        self.allStepsURL = docs.appendingPathComponent("study_all_steps_v2.json")
        self.foldersURL = docs.appendingPathComponent("study_folders.json")
        self.customListsURL = docs.appendingPathComponent("study_custom_lists.json")
        self.labelsURL = docs.appendingPathComponent("study_task_labels.json")
        
        let allQuotes = RoadmapCatalogSeed.defaultQuotes()
        self.quotes = allQuotes
        self.currentQuote = allQuotes.first ?? StoicQuote(quote: "Disziplin bedeutet Freiheit.", author: "Jocko Willink", category: "Fokus")

        loadData()
        loadFolders()
        loadCustomLists()
        loadLabels()
        rotateQuote()
        syncWaterFromBridge()
        syncMacrosFromBridge()
        syncWorkoutsFromBridge()
        syncSupplementsFromBridge()
        syncEcosystemScheduleFromBridge()

        DarwinNotificationCenter.observe(DarwinNotificationCenter.waterUpdated) { [weak self] in
            Task { @MainActor in
                self?.syncWaterFromBridge()
            }
        }
        DarwinNotificationCenter.observe(DarwinNotificationCenter.macrosUpdated) { [weak self] in
            Task { @MainActor in
                self?.syncMacrosFromBridge()
            }
        }
        DarwinNotificationCenter.observe(DarwinNotificationCenter.fieldNotesUpdated) { [weak self] in
            Task { @MainActor in
                self?.syncWorkoutsFromBridge()
            }
        }
        DarwinNotificationCenter.observe(DarwinNotificationCenter.suppsUpdated) { [weak self] in
            Task { @MainActor in
                self?.syncSupplementsFromBridge()
            }
        }
        DarwinNotificationCenter.observe(DarwinNotificationCenter.mealsLedgerUpdated) { [weak self] in
            Task { @MainActor [weak self] in
                self?.sharedMeals = GrowSuiteBridge.shared.loadMealsLedger().meals
            }
        }
        DarwinNotificationCenter.observe(DarwinNotificationCenter.workoutScheduleLedgerUpdated) { [weak self] in
            Task { @MainActor [weak self] in
                self?.sharedWorkouts = GrowSuiteBridge.shared.loadWorkoutScheduleLedger().items
            }
        }
        DarwinNotificationCenter.observe(DarwinNotificationCenter.supplementScheduleLedgerUpdated) { [weak self] in
            Task { @MainActor [weak self] in
                self?.sharedSupplements = GrowSuiteBridge.shared.loadSupplementScheduleLedger().items
            }
        }
    }

    public func syncWaterFromBridge() {
        let payload = GrowSuiteBridge.shared.loadWater()
        self.todayWaterMl = payload.totalWaterMl
        self.targetWaterMl = payload.targetWaterMl > 0 ? payload.targetWaterMl : 2500.0
    }

    public func syncMacrosFromBridge() {
        guard let payload = GrowSuiteBridge.shared.loadMacros() else { return }
        let isToday = Calendar.current.isDate(payload.timestamp, inSameDayAs: Date())
        guard isToday else { return }
        
        var didChange = false
        // 1. Frühstück (ab 40g Protein)
        if payload.protein >= 40.0 {
            if let idx = steps.firstIndex(where: { $0.id == "nutri-breakfast" }), !steps[idx].isCompleted {
                steps[idx].isCompleted = true
                for s in 0..<steps[idx].submodules.count {
                    steps[idx].submodules[s].isCompleted = true
                }
                didChange = true
            }
        }
        // 2. Mittagessen (ab 90g Protein kumuliert)
        if payload.protein >= 90.0 {
            if let idx = steps.firstIndex(where: { $0.id == "nutri-lunch" }), !steps[idx].isCompleted {
                steps[idx].isCompleted = true
                for s in 0..<steps[idx].submodules.count {
                    steps[idx].submodules[s].isCompleted = true
                }
                didChange = true
            }
        }
        // 3. Abendessen & Tagesziel (ab 145g Protein)
        if payload.protein >= 145.0 {
            if let idx = steps.firstIndex(where: { $0.id == "nutri-dinner" }), !steps[idx].isCompleted {
                steps[idx].isCompleted = true
                for s in 0..<steps[idx].submodules.count {
                    steps[idx].submodules[s].isCompleted = true
                }
                didChange = true
            }
        }
        if didChange {
            saveAllSteps()
            saveProgress()
        }
    }

    public func syncWorkoutsFromBridge() {
        guard let workout = GrowSuiteBridge.shared.loadLatestWorkout() else { return }
        let isToday = Calendar.current.isDate(workout.completionDate, inSameDayAs: Date())
        guard isToday else { return }
        
        var didChange = false
        let lowerTitle = workout.title.lowercased()
        let matchingStepId: String?
        if lowerTitle.contains("push") {
            matchingStepId = "gym-push-a"
        } else if lowerTitle.contains("pull") {
            matchingStepId = "gym-pull-a"
        } else if lowerTitle.contains("leg") || lowerTitle.contains("bein") {
            matchingStepId = "gym-legs-a"
        } else if lowerTitle.contains("upper") || lowerTitle.contains("oberkörper") {
            matchingStepId = "gym-upper-b"
        } else if lowerTitle.contains("cardio") || lowerTitle.contains("kardio") || lowerTitle.contains("zone 2") {
            matchingStepId = "gym-cardio-zone2"
        } else {
            matchingStepId = steps.first(where: { $0.track == .gym && !$0.isCompleted })?.id
        }
        
        if let targetId = matchingStepId,
           let idx = steps.firstIndex(where: { $0.id == targetId }),
           !steps[idx].isCompleted {
            steps[idx].isCompleted = true
            for s in 0..<steps[idx].submodules.count {
                steps[idx].submodules[s].isCompleted = true
            }
            didChange = true
        }
        if didChange {
            saveAllSteps()
            saveProgress()
        }
    }

    public func syncSupplementsFromBridge() {
        let supps = GrowSuiteBridge.shared.loadSupplements()
        guard !supps.takenDoseIds.isEmpty else { return }
        guard let idx = steps.firstIndex(where: { $0.id == "nutri-circadian-supps" }) else { return }
        var didChange = false
        
        for (doseId, _) in supps.takenDoseIds {
            let lowerDose = doseId.lowercased()
            if lowerDose.contains("rhodiola") || lowerDose.contains("malat") {
                if let sIdx = steps[idx].submodules.firstIndex(where: { $0.id == "nutri-supp-sm-1" }), !steps[idx].submodules[sIdx].isCompleted {
                    steps[idx].submodules[sIdx].isCompleted = true
                    didChange = true
                }
            } else if lowerDose.contains("d3") || lowerDose.contains("k2") {
                if let sIdx = steps[idx].submodules.firstIndex(where: { $0.id == "nutri-supp-sm-2" }), !steps[idx].submodules[sIdx].isCompleted {
                    steps[idx].submodules[sIdx].isCompleted = true
                    didChange = true
                }
            } else if lowerDose.contains("omega") {
                if let sIdx = steps[idx].submodules.firstIndex(where: { $0.id == "nutri-supp-sm-3" }), !steps[idx].submodules[sIdx].isCompleted {
                    steps[idx].submodules[sIdx].isCompleted = true
                    didChange = true
                }
            } else if lowerDose.contains("glycinat") || lowerDose.contains("bisglycinat") {
                if let sIdx = steps[idx].submodules.firstIndex(where: { $0.id == "nutri-supp-sm-4" }), !steps[idx].submodules[sIdx].isCompleted {
                    steps[idx].submodules[sIdx].isCompleted = true
                    didChange = true
                }
            }
        }
        if steps[idx].submodules.allSatisfy({ $0.isCompleted }) && !steps[idx].isCompleted {
            steps[idx].isCompleted = true
            didChange = true
        }
        if didChange {
            saveAllSteps()
            saveProgress()
        }
    }

    public func logWater(amountMl: Double, sourceApp: String = "GrowStudy") {
        GrowSuiteBridge.shared.logWater(amountMl: amountMl, date: Date(), sourceApp: sourceApp)
        syncWaterFromBridge()
        HapticFeedback.success()
    }

    public func resetWater(sourceApp: String = "GrowStudy") {
        GrowSuiteBridge.shared.resetWater(date: Date(), sourceApp: sourceApp)
        syncWaterFromBridge()
        HapticFeedback.medium()
    }

    // MARK: - Robuste JSON Decoder & Encoder mit Multi-Format Date Support
    private var appDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { d in
            let container = try d.singleValueContainer()
            if let string = try? container.decode(String.self) {
                if let date = ISO8601DateFormatter().date(from: string) {
                    return date
                }
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                if let date = formatter.date(from: string) {
                    return date
                }
            }
            if let double = try? container.decode(Double.self) {
                return Date(timeIntervalSinceReferenceDate: double)
            }
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: d.codingPath, debugDescription: "Invalid date format"))
        }
        return decoder
    }

    private var appEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        return encoder
    }

    // MARK: - Undo / Redo Infrastructure (Cmd+Z / Shift+Cmd+Z)
    public struct AppSnapshot {
        public let steps: [RoadmapStep]
        public let folders: [StudyFolder]
        public let customListNames: [String]
    }

    private var isUndoingOrRedoing: Bool = false
    private var undoStack: [AppSnapshot] = []
    private var redoStack: [AppSnapshot] = []

    public var canUndo: Bool { !undoStack.isEmpty }
    public var canRedo: Bool { !redoStack.isEmpty }

    public func recordUndoSnapshot() {
        guard !isUndoingOrRedoing else { return }
        let snapshot = AppSnapshot(steps: steps, folders: folders, customListNames: customListNames)
        undoStack.append(snapshot)
        if undoStack.count > 50 {
            undoStack.removeFirst()
        }
        redoStack.removeAll()
    }

    public func undo() {
        guard let previous = undoStack.popLast() else { return }
        let current = AppSnapshot(steps: steps, folders: folders, customListNames: customListNames)
        redoStack.append(current)
        isUndoingOrRedoing = true
        self.steps = previous.steps
        self.folders = previous.folders
        self.customListNames = previous.customListNames
        saveAllData()
        isUndoingOrRedoing = false
        HapticFeedback.medium()
    }

    public func redo() {
        guard let next = redoStack.popLast() else { return }
        let current = AppSnapshot(steps: steps, folders: folders, customListNames: customListNames)
        undoStack.append(current)
        isUndoingOrRedoing = true
        self.steps = next.steps
        self.folders = next.folders
        self.customListNames = next.customListNames
        saveAllData()
        isUndoingOrRedoing = false
        HapticFeedback.medium()
    }

    public func saveAllData() {
        saveProgress()
        saveAllSteps()
        saveFolders()
        saveCustomLists()
        StudyMultiDeviceSyncService.shared.broadcastSync()
    }

    public var progressMap: [String: Bool] {
        var map: [String: Bool] = [:]
        for s in steps { map[s.id] = s.isCompleted }
        return map
    }

    public var subtasksMap: [String: [String: Bool]] {
        var map: [String: [String: Bool]] = [:]
        for s in steps {
            var sub: [String: Bool] = [:]
            for st in s.subtasks { sub[st.id] = st.isDone }
            map[s.id] = sub
        }
        return map
    }

    public var submodulesMap: [String: [String: Bool]] {
        var map: [String: [String: Bool]] = [:]
        for s in steps {
            var sub: [String: Bool] = [:]
            for sm in s.submodules { sub[sm.id] = sm.isCompleted }
            map[s.id] = sub
        }
        return map
    }

    public var planningMap: [String: StepPlanningRecord] {
        var planMap: [String: StepPlanningRecord] = [:]
        for s in steps {
            var subMap: [String: SubmodulePlanningRecord] = [:]
            for sm in s.submodules {
                if sm.plannedDate != nil || sm.calendarEventId != nil {
                    subMap[sm.id] = SubmodulePlanningRecord(plannedDate: sm.plannedDate, calendarEventId: sm.calendarEventId)
                }
            }
            if s.plannedDate != nil || s.calendarEventId != nil || !subMap.isEmpty {
                planMap[s.id] = StepPlanningRecord(
                    stepPlannedDate: s.plannedDate,
                    stepCalendarEventId: s.calendarEventId,
                    submodules: subMap
                )
            }
        }
        return planMap
    }

    // MARK: - Daten laden & speichern
    public func loadData() {
        var defaultSteps: [RoadmapStep] = []

        if let data = try? Data(contentsOf: allStepsURL),
           let saved = try? appDecoder.decode([RoadmapStep].self, from: data),
           !saved.isEmpty {
            defaultSteps = saved
            let seedSteps = RoadmapCatalogSeed.defaultSteps()

            // Enrich or update care, chore, gym and nutrition catalog steps with full instructions
            for seed in seedSteps {
                if let idx = defaultSteps.firstIndex(where: { $0.id == seed.id }) {
                    if seed.track == .care || seed.track == .chores || seed.track == .gym || seed.track == .nutrition {
                        let isDone = defaultSteps[idx].isCompleted
                        let oldSubs = defaultSteps[idx].submodules
                        let oldSubtasks = defaultSteps[idx].subtasks
                        var updated = seed
                        updated.isCompleted = isDone
                        for sIdx in 0..<updated.submodules.count {
                            if let found = oldSubs.first(where: { $0.id == updated.submodules[sIdx].id }) {
                                updated.submodules[sIdx].isCompleted = found.isCompleted
                                updated.submodules[sIdx].plannedDate = found.plannedDate
                            }
                        }
                        for stIdx in 0..<updated.subtasks.count {
                            if let found = oldSubtasks.first(where: { $0.id == updated.subtasks[stIdx].id }) {
                                updated.subtasks[stIdx].isDone = found.isDone
                            }
                        }
                        defaultSteps[idx] = updated
                    }
                } else {
                    defaultSteps.append(seed)
                }
            }

            // Remove any obsolete dummy items from earlier builds
            defaultSteps.removeAll { s in
                (s.track == .care || s.track == .chores || s.track == .gym || s.track == .nutrition) &&
                !seedSteps.contains(where: { $0.id == s.id })
            }
        } else {
            defaultSteps = RoadmapCatalogSeed.defaultSteps()
        }
        
        // Load step-level completion
        if let data = try? Data(contentsOf: progressURL),
           let savedProgress = try? appDecoder.decode([String: Bool].self, from: data) {
            for i in 0..<defaultSteps.count {
                if let isDone = savedProgress[defaultSteps[i].id] {
                    defaultSteps[i].isCompleted = isDone
                }
            }
        }

        // Load subtask-level completion
        if let subData = try? Data(contentsOf: subtasksURL),
           let savedSubtasks = try? appDecoder.decode([String: [String: Bool]].self, from: subData) {
            for i in 0..<defaultSteps.count {
                let stepId = defaultSteps[i].id
                if let stepSubtasks = savedSubtasks[stepId] {
                    for j in 0..<defaultSteps[i].subtasks.count {
                        let subId = defaultSteps[i].subtasks[j].id
                        if let subDone = stepSubtasks[subId] {
                            defaultSteps[i].subtasks[j].isDone = subDone
                        }
                    }
                }
            }
        }

        // Load submodule-level completion
        if let smData = try? Data(contentsOf: submodulesURL),
           let savedSubmodules = try? appDecoder.decode([String: [String: Bool]].self, from: smData) {
            for i in 0..<defaultSteps.count {
                let stepId = defaultSteps[i].id
                if let stepSubmods = savedSubmodules[stepId] {
                    for j in 0..<defaultSteps[i].submodules.count {
                        let smId = defaultSteps[i].submodules[j].id
                        if let smDone = stepSubmods[smId] {
                            defaultSteps[i].submodules[j].isCompleted = smDone
                        }
                    }
                }
            }
        }

        // Load planning dates and calendar event IDs
        if let planData = try? Data(contentsOf: planningURL),
           let savedPlanning = try? appDecoder.decode([String: StepPlanningRecord].self, from: planData) {
            for i in 0..<defaultSteps.count {
                let stepId = defaultSteps[i].id
                if let rec = savedPlanning[stepId] {
                    defaultSteps[i].plannedDate = rec.stepPlannedDate
                    defaultSteps[i].calendarEventId = rec.stepCalendarEventId
                    for j in 0..<defaultSteps[i].submodules.count {
                        let smId = defaultSteps[i].submodules[j].id
                        if let smRec = rec.submodules[smId] {
                            defaultSteps[i].submodules[j].plannedDate = smRec.plannedDate
                            defaultSteps[i].submodules[j].calendarEventId = smRec.calendarEventId
                        }
                    }
                }
            }
        }

        // Load custom user-added submodules & resources
        if let custData = try? Data(contentsOf: customizationsURL),
           let savedCust = try? appDecoder.decode([String: StepCustomizationRecord].self, from: custData) {
            for i in 0..<defaultSteps.count {
                let stepId = defaultSteps[i].id
                if let rec = savedCust[stepId] {
                    for sm in rec.customSubmodules {
                        if !defaultSteps[i].submodules.contains(where: { $0.id == sm.id }) {
                            defaultSteps[i].submodules.append(sm)
                        }
                    }
                    for res in rec.customResources {
                        if !defaultSteps[i].resources.contains(where: { $0.id == res.id }) {
                            defaultSteps[i].resources.append(res)
                        }
                    }
                }
            }
        }

        self.steps = defaultSteps
        saveAllSteps()
    }

    public func saveProgress() {
        var progressMap: [String: Bool] = [:]
        var subtaskMap: [String: [String: Bool]] = [:]
        var submoduleMap: [String: [String: Bool]] = [:]
        
        for s in steps {
            progressMap[s.id] = s.isCompleted
            
            var subs: [String: Bool] = [:]
            for st in s.subtasks {
                subs[st.id] = st.isDone
            }
            subtaskMap[s.id] = subs

            var submods: [String: Bool] = [:]
            for sm in s.submodules {
                submods[sm.id] = sm.isCompleted
            }
            submoduleMap[s.id] = submods
        }
        
        if let data = try? JSONEncoder().encode(progressMap) {
            try? data.write(to: progressURL)
        }
        if let subData = try? JSONEncoder().encode(subtaskMap) {
            try? subData.write(to: subtasksURL)
        }
        if let smData = try? JSONEncoder().encode(submoduleMap) {
            try? smData.write(to: submodulesURL)
        }
        savePlanning()
    }

    public func savePlanning() {
        var planMap: [String: StepPlanningRecord] = [:]
        for s in steps {
            var subMap: [String: SubmodulePlanningRecord] = [:]
            for sm in s.submodules {
                if sm.plannedDate != nil || sm.calendarEventId != nil {
                    subMap[sm.id] = SubmodulePlanningRecord(plannedDate: sm.plannedDate, calendarEventId: sm.calendarEventId)
                }
            }
            if s.plannedDate != nil || s.calendarEventId != nil || !subMap.isEmpty {
                planMap[s.id] = StepPlanningRecord(
                    stepPlannedDate: s.plannedDate,
                    stepCalendarEventId: s.calendarEventId,
                    submodules: subMap
                )
            }
        }
        if let data = try? appEncoder.encode(planMap) {
            try? data.write(to: planningURL)
        }
    }

    // MARK: - Linear Step-Gating Engine
    public func status(for step: RoadmapStep) -> StepStatus {
        if step.isCompleted {
            return .completed
        }
        
        if !step.prerequisiteIds.isEmpty {
            for preId in step.prerequisiteIds {
                if let preStep = steps.first(where: { $0.id == preId }), !preStep.isCompleted {
                    return .locked
                }
            }
        }

        let trackSteps = steps(for: step.track).sorted(by: { $0.sequenceNumber < $1.sequenceNumber })
        if let firstUnfinished = trackSteps.first(where: { !$0.isCompleted }), firstUnfinished.id == step.id {
            return .inProgress
        }

        return .available
    }

    public func isStepLocked(_ step: RoadmapStep) -> Bool {
        status(for: step) == .locked
    }

    public func steps(for track: StudyTrack) -> [RoadmapStep] {
        steps.filter { $0.track == track }.sorted(by: { $0.sequenceNumber < $1.sequenceNumber })
    }

    public func allPhases() -> [String] {
        var seen = Set<String>()
        var list: [String] = []
        for step in steps {
            if !step.phase.isEmpty && !seen.contains(step.phase) {
                seen.insert(step.phase)
                list.append(step.phase)
            }
        }
        for cl in customListNames {
            if !seen.contains(cl) {
                seen.insert(cl)
                list.append(cl)
            }
        }
        return list
    }

    public func steps(in phase: String) -> [RoadmapStep] {
        steps.filter { $0.phase == phase }.sorted(by: { $0.sequenceNumber < $1.sequenceNumber })
    }

    public func ungroupedLists() -> [String] {
        let all = allPhases()
        let grouped = Set(folders.flatMap { $0.listNames })
        return all.filter { !grouped.contains($0) }
    }

    public func phases(for track: StudyTrack) -> [String] {
        var seen = Set<String>()
        var list: [String] = []
        for step in steps(for: track) {
            if !step.phase.isEmpty && !seen.contains(step.phase) {
                seen.insert(step.phase)
                list.append(step.phase)
            }
        }
        for cl in customListNames {
            if !seen.contains(cl) {
                seen.insert(cl)
                list.append(cl)
            }
        }
        return list
    }

    public func steps(for track: StudyTrack, in phase: String) -> [RoadmapStep] {
        steps(for: track).filter { $0.phase == phase }
    }

    public func nextAvailableStep(for track: StudyTrack) -> RoadmapStep? {
        let trackSteps = steps(for: track)
        return trackSteps.first(where: { !$0.isCompleted && status(for: $0) != .locked })
    }

    public func completedCount(for track: StudyTrack) -> Int {
        steps(for: track).filter { $0.isCompleted }.count
    }

    public func totalCount(for track: StudyTrack) -> Int {
        steps(for: track).count
    }

    public func progress(for track: StudyTrack) -> Double {
        let total = Double(totalCount(for: track))
        guard total > 0 else { return 0.0 }
        return Double(completedCount(for: track)) / total
    }

    public func subtaskStats(for track: StudyTrack) -> (completed: Int, total: Int, ratio: Double) {
        let trackSteps = steps(for: track)
        var comp = 0
        var tot = 0
        for s in trackSteps {
            for st in s.subtasks {
                tot += 1
                if st.isDone { comp += 1 }
            }
            for sm in s.submodules {
                tot += 1
                if sm.isCompleted { comp += 1 }
            }
        }
        let ratio = tot > 0 ? Double(comp) / Double(tot) : 0.0
        return (comp, tot, ratio)
    }

    // MARK: - Handlungen
    public func completeStep(id: String) {
        if let idx = steps.firstIndex(where: { $0.id == id }) {
            steps[idx].isCompleted = true
            steps[idx].completedDate = Date()
            for sIdx in 0..<steps[idx].subtasks.count {
                steps[idx].subtasks[sIdx].isDone = true
            }
            for smIdx in 0..<steps[idx].submodules.count {
                steps[idx].submodules[smIdx].isCompleted = true
            }
            totalStudyMinutesToday += steps[idx].estimatedMinutes
            saveProgress()
            HapticFeedback.success()
        }
    }

    public func toggleStep(id: String) {
        recordUndoSnapshot()
        var sIdx = steps.firstIndex(where: { $0.id == id })
        if sIdx == nil {
            sIdx = steps.firstIndex(where: { "\($0.sequenceNumber)" == id })
        }
        guard let idx = sIdx else { return }

        // Recurrence-Logik: Falls wiederkehrend und bisher nicht abgeschlossen
        if !steps[idx].isCompleted, let rule = steps[idx].recurrenceRule {
            var updatedRule = rule
            updatedRule.completedOccurrences += 1
            steps[idx].recurrenceRule = updatedRule

            if !updatedRule.isExpired {
                let baseDate = steps[idx].plannedDate ?? Date()
                let nextDate = updatedRule.nextOccurrence(from: baseDate)
                steps[idx].plannedDate = nextDate
                steps[idx].isCompleted = false
                steps[idx].completedDate = nil

                // Submodule und Subtasks für den nächsten Turnus zurücksetzen
                for s in 0..<steps[idx].subtasks.count {
                    steps[idx].subtasks[s].isDone = false
                }
                for sm in 0..<steps[idx].submodules.count {
                    steps[idx].submodules[sm].isCompleted = false
                    steps[idx].submodules[sm].completedDate = nil
                }
                HapticFeedback.success()
                saveAllSteps()
                saveProgress()
                return
            }
        }

        steps[idx].isCompleted.toggle()
        let isDone = steps[idx].isCompleted
        steps[idx].completedDate = isDone ? Date() : nil

        if isDone {
            for s in 0..<steps[idx].subtasks.count {
                steps[idx].subtasks[s].isDone = true
            }
            for sm in 0..<steps[idx].submodules.count {
                steps[idx].submodules[sm].isCompleted = true
                steps[idx].submodules[sm].completedDate = Date()
            }
            HapticFeedback.success()
        } else {
            // Revert auf unvollständig: Submodule und Subtasks ebenfalls sauber zurücksetzen
            for s in 0..<steps[idx].subtasks.count {
                steps[idx].subtasks[s].isDone = false
            }
            for sm in 0..<steps[idx].submodules.count {
                steps[idx].submodules[sm].isCompleted = false
                steps[idx].submodules[sm].completedDate = nil
            }
            HapticFeedback.light()
        }

        saveAllSteps()
        saveProgress()
    }

    public func toggleCompletion(for step: RoadmapStep) {
        toggleStep(id: step.id)
    }

    public func toggleSubmoduleCompletion(stepId: String? = nil, submoduleId: String) {
        toggleSubmodule(stepId: stepId, submoduleId: submoduleId)
    }

    public func toggleSubtask(stepId: String, subtaskId: String) {
        recordUndoSnapshot()
        guard let sIdx = steps.firstIndex(where: { $0.id == stepId }) else { return }
        guard let stIdx = steps[sIdx].subtasks.firstIndex(where: { $0.id == subtaskId }) else { return }
        
        steps[sIdx].subtasks[stIdx].isDone.toggle()
        
        let allDone = steps[sIdx].subtasks.allSatisfy { $0.isDone } && steps[sIdx].submodules.allSatisfy { $0.isCompleted }
        if allDone && (!steps[sIdx].subtasks.isEmpty || !steps[sIdx].submodules.isEmpty) {
            steps[sIdx].isCompleted = true
            steps[sIdx].completedDate = Date()
            HapticFeedback.success()
        } else if !allDone && steps[sIdx].isCompleted {
            steps[sIdx].isCompleted = false
            HapticFeedback.light()
        } else {
            HapticFeedback.light()
        }
        
        saveAllSteps()
        saveProgress()
    }

    public func toggleSubmodule(stepId: String? = nil, submoduleId: String) {
        recordUndoSnapshot()
        var targetSIdx = stepId != nil ? steps.firstIndex(where: { $0.id == stepId }) : nil
        var targetSmIdx: Int? = nil

        if let si = targetSIdx {
            targetSmIdx = steps[si].submodules.firstIndex(where: { $0.id == submoduleId })
        }

        if targetSIdx == nil || targetSmIdx == nil {
            for i in 0..<steps.count {
                if let smIndex = steps[i].submodules.firstIndex(where: { $0.id == submoduleId }) {
                    targetSIdx = i
                    targetSmIdx = smIndex
                    break
                }
            }
        }

        guard let sIdx = targetSIdx, let smIdx = targetSmIdx else { return }

        // Recurrence-Check für Unteraufgaben
        if !steps[sIdx].submodules[smIdx].isCompleted, let rule = steps[sIdx].submodules[smIdx].recurrenceRule {
            var updatedRule = rule
            updatedRule.completedOccurrences += 1
            steps[sIdx].submodules[smIdx].recurrenceRule = updatedRule

            if !updatedRule.isExpired {
                let baseDate = steps[sIdx].submodules[smIdx].plannedDate ?? Date()
                let nextDate = updatedRule.nextOccurrence(from: baseDate)
                steps[sIdx].submodules[smIdx].plannedDate = nextDate
                steps[sIdx].submodules[smIdx].isCompleted = false
                steps[sIdx].submodules[smIdx].completedDate = nil

                totalStudyMinutesToday += steps[sIdx].submodules[smIdx].durationMinutes
                HapticFeedback.success()
                saveAllSteps()
                saveProgress()
                return
            }
        }

        steps[sIdx].submodules[smIdx].isCompleted.toggle()
        let isDone = steps[sIdx].submodules[smIdx].isCompleted
        steps[sIdx].submodules[smIdx].completedDate = isDone ? Date() : nil

        if isDone {
            totalStudyMinutesToday += steps[sIdx].submodules[smIdx].durationMinutes
            HapticFeedback.success()
        } else {
            totalStudyMinutesToday = max(0, totalStudyMinutesToday - steps[sIdx].submodules[smIdx].durationMinutes)
            HapticFeedback.light()
        }

        // Modul-Status synchronisieren
        let allSubsDone = steps[sIdx].submodules.allSatisfy { $0.isCompleted }
        let allTasksDone = steps[sIdx].subtasks.allSatisfy { $0.isDone }
        if allSubsDone && allTasksDone && (!steps[sIdx].submodules.isEmpty || !steps[sIdx].subtasks.isEmpty) {
            steps[sIdx].isCompleted = true
            steps[sIdx].completedDate = Date()
        } else {
            steps[sIdx].isCompleted = false
            steps[sIdx].completedDate = nil
        }

        saveAllSteps()
        saveProgress()
    }

    public func existingPhases(for track: StudyTrack) -> [String] {
        var phases: [String] = []
        for step in steps(for: track) {
            if !step.phase.isEmpty && !phases.contains(step.phase) {
                phases.append(step.phase)
            }
        }
        return phases
    }

    @discardableResult
    public func addCustomModule(
        track: StudyTrack,
        phase: String,
        title: String,
        subtitle: String,
        type: StepType,
        hours: Double,
        youtubeURL: String? = nil,
        planForDate: Date? = nil
    ) -> RoadmapStep {
        let count = steps(for: track).count
        var submods: [StudySubmodule] = []
        if let yt = youtubeURL, !yt.isEmpty {
            let isFile = yt.hasPrefix("file://")
            let isPlaylist = yt.contains("playlist") || yt.contains("list=")
            let subType: SubmoduleType = isFile ? .pdfDocument : (isPlaylist ? .youtubePlaylist : (yt.contains("youtube") ? .youtubeVideo : .webModule))
            submods.append(StudySubmodule(
                id: UUID().uuidString,
                title: title,
                type: subType,
                url: yt,
                durationMinutes: max(15, Int(hours * 60)),
                isCompleted: false,
                isUserAdded: true
            ))
        }

        let newStep = RoadmapStep(
            id: UUID().uuidString,
            track: track,
            phase: phase.isEmpty ? "Benutzerdefinierte Module" : phase,
            sequenceNumber: count + 1,
            title: title,
            subtitle: subtitle,
            type: type,
            estimatedHours: hours,
            estimatedMinutes: Int(hours * 60),
            category: "Custom",
            difficulty: "All Levels",
            primaryURL: youtubeURL,
            submodules: submods,
            isCompleted: false
        )
        steps.append(newStep)
        saveAllSteps()
        if let pDate = planForDate {
            planStep(stepId: newStep.id, date: pDate)
        }
        HapticFeedback.success()
        return newStep
    }

    // MARK: - Anhang- & Datei-Management (PDFs, Dokumente & Links)
    public nonisolated func saveAttachmentFile(from sourceURL: URL) -> URL? {
        let fm = FileManager.default
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let attachmentsDir = docs.appendingPathComponent("Attachments", isDirectory: true)

        if !fm.fileExists(atPath: attachmentsDir.path) {
            try? fm.createDirectory(at: attachmentsDir, withIntermediateDirectories: true)
        }

        let cleanFileName = sourceURL.lastPathComponent.replacingOccurrences(of: " ", with: "_")
        let destinationURL = attachmentsDir.appendingPathComponent("\(UUID().uuidString.prefix(8))_\(cleanFileName)")

        let didAccess = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if didAccess {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }

        do {
            if fm.fileExists(atPath: destinationURL.path) {
                try fm.removeItem(at: destinationURL)
            }
            try fm.copyItem(at: sourceURL, to: destinationURL)
            return destinationURL
        } catch {
            // Robuster Fallback: Direktes Byte-Lesen & Schreiben (vermeidet Sandbox-Copy-Fehler)
            if let data = try? Data(contentsOf: sourceURL) {
                do {
                    try data.write(to: destinationURL, options: .atomic)
                    return destinationURL
                } catch {
                    return nil
                }
            }
            return nil
        }
    }

    // MARK: - Drag & Drop File Handling (PDFs, Dokumente & Skripte)
    public static let supportedDropTypes: [UTType] = [
        .pdf,
        .item,
        .content,
        .data,
        .fileURL
    ]

    public func importDroppedFiles(
        from providers: [NSItemProvider],
        targetStepId: String? = nil,
        targetSubmoduleId: String? = nil,
        targetTrack: StudyTrack? = nil,
        targetPhase: String? = nil,
        isResourceOnly: Bool = false
    ) {
        for provider in providers {
            // Priorität 1: loadObject mit URL (optimale Finder & Files API)
            if provider.canLoadObject(ofClass: URL.self) {
                _ = provider.loadObject(ofClass: URL.self) { [weak self] url, error in
                    guard let self = self else { return }
                    if let url = url, let saved = self.saveAttachmentFile(from: url) {
                        let fileName = url.deletingPathExtension().lastPathComponent
                        Task { @MainActor in
                            self.applyImportedFile(
                                url: saved,
                                suggestedTitle: fileName,
                                targetStepId: targetStepId,
                                targetSubmoduleId: targetSubmoduleId,
                                targetTrack: targetTrack,
                                targetPhase: targetPhase,
                                isResourceOnly: isResourceOnly
                            )
                        }
                        return
                    }
                    self.loadFileRepresentationFallback(
                        provider: provider,
                        targetStepId: targetStepId,
                        targetSubmoduleId: targetSubmoduleId,
                        targetTrack: targetTrack,
                        targetPhase: targetPhase,
                        isResourceOnly: isResourceOnly
                    )
                }
            } else {
                self.loadFileRepresentationFallback(
                    provider: provider,
                    targetStepId: targetStepId,
                    targetSubmoduleId: targetSubmoduleId,
                    targetTrack: targetTrack,
                    targetPhase: targetPhase,
                    isResourceOnly: isResourceOnly
                )
            }
        }
    }

    private func loadFileRepresentationFallback(
        provider: NSItemProvider,
        targetStepId: String?,
        targetSubmoduleId: String?,
        targetTrack: StudyTrack?,
        targetPhase: String?,
        isResourceOnly: Bool
    ) {
        if provider.hasItemConformingToTypeIdentifier(UTType.item.identifier) {
            provider.loadFileRepresentation(forTypeIdentifier: UTType.item.identifier) { [weak self] tempURL, error in
                guard let self = self else { return }
                if let tempURL = tempURL, let saved = self.saveAttachmentFile(from: tempURL) {
                    let fileName = tempURL.deletingPathExtension().lastPathComponent
                    Task { @MainActor in
                        self.applyImportedFile(
                            url: saved,
                            suggestedTitle: fileName,
                            targetStepId: targetStepId,
                            targetSubmoduleId: targetSubmoduleId,
                            targetTrack: targetTrack,
                            targetPhase: targetPhase,
                            isResourceOnly: isResourceOnly
                        )
                    }
                    return
                }
                self.loadItemFallback(
                    provider: provider,
                    targetStepId: targetStepId,
                    targetSubmoduleId: targetSubmoduleId,
                    targetTrack: targetTrack,
                    targetPhase: targetPhase,
                    isResourceOnly: isResourceOnly
                )
            }
        } else {
            self.loadItemFallback(
                provider: provider,
                targetStepId: targetStepId,
                targetSubmoduleId: targetSubmoduleId,
                targetTrack: targetTrack,
                targetPhase: targetPhase,
                isResourceOnly: isResourceOnly
            )
        }
    }

    nonisolated private func loadItemFallback(
        provider: NSItemProvider,
        targetStepId: String?,
        targetSubmoduleId: String?,
        targetTrack: StudyTrack?,
        targetPhase: String?,
        isResourceOnly: Bool
    ) {
        let typeId = UTType.fileURL.identifier
        if provider.hasItemConformingToTypeIdentifier(typeId) {
            provider.loadItem(forTypeIdentifier: typeId, options: nil) { [weak self] item, error in
                guard let self = self else { return }
                var sourceURL: URL? = nil
                if let url = item as? URL {
                    sourceURL = url
                } else if let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                    sourceURL = url
                }

                if let url = sourceURL {
                    let needsAccess = url.startAccessingSecurityScopedResource()
                    defer {
                        if needsAccess { url.stopAccessingSecurityScopedResource() }
                    }
                    if let savedURL = self.saveAttachmentFile(from: url) {
                        let fileName = url.deletingPathExtension().lastPathComponent
                        Task { @MainActor in
                            self.applyImportedFile(
                                url: savedURL,
                                suggestedTitle: fileName,
                                targetStepId: targetStepId,
                                targetSubmoduleId: targetSubmoduleId,
                                targetTrack: targetTrack,
                                targetPhase: targetPhase,
                                isResourceOnly: isResourceOnly
                            )
                        }
                    }
                }
            }
        }
    }

    private func applyImportedFile(
        url: URL,
        suggestedTitle: String,
        targetStepId: String?,
        targetSubmoduleId: String?,
        targetTrack: StudyTrack?,
        targetPhase: String?,
        isResourceOnly: Bool
    ) {
        let cleanTitle = suggestedTitle
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let finalTitle = cleanTitle.isEmpty ? "PDF-Dokument" : cleanTitle
        let ext = url.pathExtension.uppercased()
        let resourceType = ext.isEmpty ? "PDF" : ext

        if let stepId = targetStepId {
            if let subId = targetSubmoduleId {
                self.addResourceToSubmodule(
                    stepId: stepId,
                    submoduleId: subId,
                    title: finalTitle,
                    url: url.absoluteString,
                    type: resourceType
                )
            } else if isResourceOnly {
                self.addResource(
                    to: stepId,
                    title: finalTitle,
                    url: url.absoluteString,
                    type: resourceType
                )
            } else {
                self.addSubmodule(
                    to: stepId,
                    title: finalTitle,
                    type: .pdfDocument,
                    url: url.absoluteString,
                    durationMinutes: 25
                )
            }
        } else {
            let track = targetTrack ?? self.activeTrack
            let phase = targetPhase ?? (self.existingPhases(for: track).first ?? "Eigene Skripte & PDFs")
            self.addCustomModule(
                track: track,
                phase: phase,
                title: finalTitle,
                subtitle: "Importiertes Dokument (\(resourceType))",
                type: .reading,
                hours: 1.5,
                youtubeURL: url.absoluteString
            )
        }
        HapticFeedback.success()
    }

    @discardableResult
    public func addSubmodule(
        to stepId: String,
        title: String,
        type: SubmoduleType,
        url: String?,
        durationMinutes: Int = 25,
        planForDate: Date? = nil
    ) -> StudySubmodule? {
        guard let idx = steps.firstIndex(where: { $0.id == stepId }) else { return nil }
        let sub = StudySubmodule(
            id: UUID().uuidString,
            title: title,
            type: type,
            url: url,
            durationMinutes: max(5, durationMinutes),
            isCompleted: false,
            isUserAdded: true
        )
        steps[idx].submodules.append(sub)
        saveAllSteps()
        if let pDate = planForDate {
            planSubmodule(stepId: stepId, submoduleId: sub.id, date: pDate)
        }
        HapticFeedback.success()
        return sub
    }

    public func deleteSubmodule(from stepId: String, submoduleId: String) {
        recordUndoSnapshot()
        guard let sIdx = steps.firstIndex(where: { $0.id == stepId }) else { return }
        steps[sIdx].submodules.removeAll(where: { $0.id == submoduleId })
        saveAllSteps()
        HapticFeedback.light()
    }

    // MARK: - Google Tasks Architecture & Direct Drag-and-Drop Operations

    public func moveStep(stepId: String, toPhase: String) {
        recordUndoSnapshot()
        guard let idx = steps.firstIndex(where: { $0.id == stepId }) else { return }
        steps[idx].phase = toPhase
        saveAllSteps()
        saveProgress()
        HapticFeedback.medium()
    }

    public func reorderStep(stepId: String, beforeStepId: String) {
        guard stepId != beforeStepId else { return }
        recordUndoSnapshot()
        guard let fromIdx = steps.firstIndex(where: { $0.id == stepId }),
              let toIdx = steps.firstIndex(where: { $0.id == beforeStepId }) else { return }
        let step = steps.remove(at: fromIdx)
        let newToIdx = steps.firstIndex(where: { $0.id == beforeStepId }) ?? toIdx
        steps.insert(step, at: newToIdx)
        
        let targetPhase = step.phase
        var seq = 1
        for i in 0..<steps.count {
            if steps[i].phase == targetPhase {
                steps[i].sequenceNumber = seq
                seq += 1
            }
        }
        saveAllSteps()
        HapticFeedback.light()
    }

    public func indentStep(stepId: String) {
        recordUndoSnapshot()
        guard let idx = steps.firstIndex(where: { $0.id == stepId }) else { return }
        let currentStep = steps[idx]
        let currentPhase = currentStep.phase
        
        // Finde den vorherigen Schritt in derselben Phase
        let phaseSteps = steps.filter { $0.phase == currentPhase }
        guard let phaseIdx = phaseSteps.firstIndex(where: { $0.id == stepId }), phaseIdx > 0 else { return }
        let prevStep = phaseSteps[phaseIdx - 1]
        guard let prevIdx = steps.firstIndex(where: { $0.id == prevStep.id }) else { return }
        
        // Wandle den aktuellen Schritt in ein Submodul des vorherigen Schritts um
        let newSubmodule = StudySubmodule(
            id: currentStep.id,
            title: currentStep.title,
            type: .webModule,
            url: currentStep.primaryURL,
            durationMinutes: Int(currentStep.estimatedHours * 60),
            isCompleted: currentStep.isCompleted,
            plannedDate: currentStep.plannedDate,
            isUserAdded: true,
            attachedResources: currentStep.resources,
            notes: currentStep.notes,
            recurrenceRule: currentStep.recurrenceRule,
            labelId: currentStep.labelId
        )
        steps[prevIdx].submodules.append(newSubmodule)
        steps[prevIdx].submodules.append(contentsOf: currentStep.submodules)
        
        steps.remove(at: idx)
        saveAllSteps()
        saveProgress()
        HapticFeedback.medium()
    }

    public func unindentSubmodule(submoduleId: String, parentStepId: String) {
        recordUndoSnapshot()
        guard let pIdx = steps.firstIndex(where: { $0.id == parentStepId }) else { return }
        guard let smIdx = steps[pIdx].submodules.firstIndex(where: { $0.id == submoduleId }) else { return }
        let sub = steps[pIdx].submodules.remove(at: smIdx)
        
        let parentStep = steps[pIdx]
        let newStep = RoadmapStep(
            id: sub.id,
            track: parentStep.track,
            phase: parentStep.phase,
            sequenceNumber: parentStep.sequenceNumber + 1,
            title: sub.title,
            subtitle: "",
            type: .webModule,
            estimatedHours: max(0.5, Double(sub.durationMinutes) / 60.0),
            category: "Aufgabe",
            difficulty: "Normal",
            primaryURL: sub.url,
            resources: sub.attachedResources ?? [],
            notes: sub.notes ?? "",
            isCompleted: sub.isCompleted,
            plannedDate: sub.plannedDate,
            recurrenceRule: sub.recurrenceRule,
            labelId: sub.labelId
        )
        steps.insert(newStep, at: pIdx + 1)
        
        var seq = 1
        for i in 0..<steps.count {
            if steps[i].phase == parentStep.phase {
                steps[i].sequenceNumber = seq
                seq += 1
            }
        }
        
        saveAllSteps()
        saveProgress()
        HapticFeedback.medium()
    }

    public func updateStepDetails(
        stepId: String,
        title: String? = nil,
        notes: String? = nil,
        plannedDate: Date? = nil,
        clearPlannedDate: Bool = false,
        recurrenceRule: CustomRecurrenceRule? = nil,
        clearRecurrenceRule: Bool = false,
        labelId: String? = nil,
        clearLabel: Bool = false
    ) {
        recordUndoSnapshot()
        guard let idx = steps.firstIndex(where: { $0.id == stepId }) else { return }
        if let t = title { steps[idx].title = t }
        if let n = notes { steps[idx].notes = n }
        if clearPlannedDate {
            steps[idx].plannedDate = nil
            if let oldEventId = steps[idx].calendarEventId {
                StudyCalendarSyncService.shared.removeEvent(withIdentifier: oldEventId)
                steps[idx].calendarEventId = nil
            }
        } else if let d = plannedDate {
            steps[idx].plannedDate = d
        }
        if clearRecurrenceRule {
            steps[idx].recurrenceRule = nil
        } else if let r = recurrenceRule {
            steps[idx].recurrenceRule = r
        }
        if clearLabel {
            steps[idx].labelId = nil
        } else if let l = labelId {
            steps[idx].labelId = l
        }
        saveAllSteps()
        savePlanning()
        saveProgress()
    }

    public func updateSubmoduleDetails(
        parentStepId: String,
        submoduleId: String,
        title: String? = nil,
        notes: String? = nil,
        plannedDate: Date? = nil,
        clearPlannedDate: Bool = false,
        recurrenceRule: CustomRecurrenceRule? = nil,
        clearRecurrenceRule: Bool = false,
        labelId: String? = nil,
        clearLabel: Bool = false
    ) {
        recordUndoSnapshot()
        guard let pIdx = steps.firstIndex(where: { $0.id == parentStepId }) else { return }
        guard let smIdx = steps[pIdx].submodules.firstIndex(where: { $0.id == submoduleId }) else { return }
        if let t = title { steps[pIdx].submodules[smIdx].title = t }
        if let n = notes { steps[pIdx].submodules[smIdx].notes = n }
        if clearPlannedDate {
            steps[pIdx].submodules[smIdx].plannedDate = nil
            if let oldEventId = steps[pIdx].submodules[smIdx].calendarEventId {
                StudyCalendarSyncService.shared.removeEvent(withIdentifier: oldEventId)
                steps[pIdx].submodules[smIdx].calendarEventId = nil
            }
        } else if let d = plannedDate {
            steps[pIdx].submodules[smIdx].plannedDate = d
        }
        if clearRecurrenceRule {
            steps[pIdx].submodules[smIdx].recurrenceRule = nil
        } else if let r = recurrenceRule {
            steps[pIdx].submodules[smIdx].recurrenceRule = r
        }
        if clearLabel {
            steps[pIdx].submodules[smIdx].labelId = nil
        } else if let l = labelId {
            steps[pIdx].submodules[smIdx].labelId = l
        }
        saveAllSteps()
        savePlanning()
        saveProgress()
    }

    public func moveSubmoduleToPhase(submoduleId: String, fromStepId: String, toPhase: String) {
        recordUndoSnapshot()
        guard let fromSIdx = steps.firstIndex(where: { $0.id == fromStepId }) else { return }
        guard let smIdx = steps[fromSIdx].submodules.firstIndex(where: { $0.id == submoduleId }) else { return }
        let sub = steps[fromSIdx].submodules.remove(at: smIdx)

        if let toSIdx = steps.firstIndex(where: { $0.phase == toPhase }) {
            steps[toSIdx].submodules.append(sub)
        } else {
            let nextSeq = (steps.filter { $0.phase == toPhase }.map { $0.sequenceNumber }.max() ?? 0) + 1
            let newStep = RoadmapStep(
                id: "step-\(UUID().uuidString.prefix(8))",
                track: steps[fromSIdx].track,
                phase: toPhase,
                sequenceNumber: nextSeq,
                title: sub.title,
                subtitle: "",
                type: .webModule,
                estimatedHours: max(0.5, Double(sub.durationMinutes) / 60.0),
                category: "Aufgabe",
                difficulty: "Normal",
                submodules: [sub],
                isCompleted: sub.isCompleted
            )
            steps.append(newStep)
        }
        saveAllSteps()
        saveProgress()
        HapticFeedback.medium()
    }

    public func moveSubmodule(submoduleId: String, fromStepId: String, toStepId: String) {
        recordUndoSnapshot()
        guard let fromSIdx = steps.firstIndex(where: { $0.id == fromStepId }) else { return }
        guard let toSIdx = steps.firstIndex(where: { $0.id == toStepId }) else { return }
        guard let smIdx = steps[fromSIdx].submodules.firstIndex(where: { $0.id == submoduleId }) else { return }
        let sub = steps[fromSIdx].submodules.remove(at: smIdx)
        steps[toSIdx].submodules.append(sub)
        saveAllSteps()
        saveProgress()
        HapticFeedback.medium()
    }

    public func deleteStep(id: String) {
        recordUndoSnapshot()
        steps.removeAll(where: { $0.id == id })
        saveAllSteps()
        saveProgress()
        HapticFeedback.light()
    }

    public func deleteCompletedTasks(inPhase phase: String) {
        recordUndoSnapshot()
        for i in 0..<steps.count {
            if steps[i].phase == phase {
                steps[i].submodules.removeAll(where: { $0.isCompleted })
            }
        }
        steps.removeAll(where: { $0.phase == phase && $0.isCompleted && $0.submodules.isEmpty })
        saveAllSteps()
        saveProgress()
        HapticFeedback.medium()
    }

    // MARK: - Folder Architecture & List Management

    public func loadFolders() {
        if let data = try? Data(contentsOf: foldersURL),
           let saved = try? appDecoder.decode([StudyFolder].self, from: data),
           !saved.isEmpty {
            self.folders = saved
            ensureDefaultFolders()
        } else {
            self.folders = defaultFolders()
            saveFolders()
        }
    }

    private func defaultFolders() -> [StudyFolder] {
        [
            StudyFolder(name: "Mathematik", listNames: ["Phase 0: OMB+ Mathematik & Vorbereitung"]),
            StudyFolder(name: "Wirtschaftsinformatik", listNames: [
                "Phase 0: Wirtschaftsinformatik Vorbereitung",
                "Phase 2: Administrative Meilensteine",
                "Phase 3: Hochschule Hannover Semester 1"
            ]),
            StudyFolder(name: "BFD", listNames: ["Phase 1: BFD-Zertifikate 2027 (29 Freistellungstage)", "Phase 1: BFD-Zertifikate 2027"]),
            StudyFolder(name: "Training", listNames: [
                "Trainingsplan (4er-Split)",
                "Kardio & Regeneration"
            ]),
            StudyFolder(name: "Ernährung", listNames: [
                "Tägliche Mahlzeiten & Makros",
                "Meal-Prep & Vorratskauf (Growcery)"
            ]),
            StudyFolder(name: "Pflege & Dermatologie", listNames: [
                "Morgen-Routine (Gesicht & UV-Schutz)",
                "Abend-Routine (Reinigung & Barriere)",
                "Bartpflege & Pseudofolliculitis Barbae",
                "Afro 4C Haarpflege & Scalp Detox",
                "Körper, Intim & Bundeswehr-Marschschutz"
            ]),
            StudyFolder(name: "Haushalt & Chores", listNames: [
                "Tägliche Kasernen-Chores (Stube & Lüften)",
                "Wöchentlicher Turnus (Ausrüstung & Wäsche)",
                "Wäsche & Kantenreine Spindordnung"
            ])
        ]
    }

    private func ensureDefaultFolders() {
        var didChange = false
        let defaults = defaultFolders()
        for df in defaults {
            if let idx = folders.firstIndex(where: { $0.name.lowercased() == df.name.lowercased() }) {
                for list in df.listNames {
                    if !folders[idx].listNames.contains(list) {
                        folders[idx].listNames.append(list)
                        didChange = true
                    }
                }
            } else {
                folders.append(df)
                didChange = true
            }
        }
        if didChange {
            saveFolders()
        }
    }

    public func saveFolders() {
        if let data = try? JSONEncoder().encode(folders) {
            try? data.write(to: foldersURL)
        }
    }

    @discardableResult
    public func createFolder(name: String) -> StudyFolder {
        recordUndoSnapshot()
        let clean = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalName = clean.isEmpty ? "Neuer Ordner" : clean
        let folder = StudyFolder(name: finalName)
        folders.append(folder)
        saveFolders()
        HapticFeedback.success()
        return folder
    }

    public func deleteFolder(id: String) {
        recordUndoSnapshot()
        folders.removeAll(where: { $0.id == id })
        saveFolders()
        HapticFeedback.medium()
    }

    public func renameFolder(id: String, newName: String) {
        let clean = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        recordUndoSnapshot()
        if let idx = folders.firstIndex(where: { $0.id == id }) {
            folders[idx].name = clean
            saveFolders()
            HapticFeedback.light()
        }
    }

    public func moveList(listName: String, toFolderId targetFolderId: String?) {
        recordUndoSnapshot()
        for i in 0..<folders.count {
            folders[i].listNames.removeAll(where: { $0 == listName })
        }
        if let tid = targetFolderId, let idx = folders.firstIndex(where: { $0.id == tid }) {
            if !folders[idx].listNames.contains(listName) {
                folders[idx].listNames.append(listName)
            }
        }
        saveFolders()
        HapticFeedback.medium()
    }

    public func folder(for listName: String) -> StudyFolder? {
        folders.first(where: { $0.listNames.contains(listName) })
    }

    public func lists(in folderId: String) -> [String] {
        guard let f = folders.first(where: { $0.id == folderId }) else { return [] }
        return f.listNames
    }

    public func ungroupedLists(for track: StudyTrack = .wirtschaftsinformatik) -> [String] {
        let all = phases(for: track)
        let grouped = Set(folders.flatMap { $0.listNames })
        return all.filter { !grouped.contains($0) }
    }

    // MARK: - Custom Lists

    public func loadCustomLists() {
        if let data = try? Data(contentsOf: customListsURL),
           let saved = try? appDecoder.decode([String].self, from: data) {
            self.customListNames = saved
        } else {
            self.customListNames = []
        }
    }

    public func saveCustomLists() {
        if let data = try? JSONEncoder().encode(customListNames) {
            try? data.write(to: customListsURL)
        }
    }

    @discardableResult
    public func createList(name: String, inFolderId folderId: String? = nil) -> String {
        recordUndoSnapshot()
        let clean = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return "" }
        if !customListNames.contains(clean) {
            customListNames.append(clean)
            saveCustomLists()
        }
        if let fid = folderId {
            moveList(listName: clean, toFolderId: fid)
        }
        HapticFeedback.success()
        return clean
    }

    public func deleteList(name: String) {
        recordUndoSnapshot()
        customListNames.removeAll(where: { $0 == name })
        saveCustomLists()
        for i in 0..<folders.count {
            folders[i].listNames.removeAll(where: { $0 == name })
        }
        saveFolders()
        steps.removeAll(where: { $0.phase == name })
        saveAllSteps()
        HapticFeedback.medium()
    }

    public func renameList(oldName: String, newName: String) {
        let clean = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty, clean != oldName else { return }
        recordUndoSnapshot()

        if let idx = customListNames.firstIndex(of: oldName) {
            customListNames[idx] = clean
            saveCustomLists()
        }

        var foldersChanged = false
        for i in 0..<folders.count {
            if let idx = folders[i].listNames.firstIndex(of: oldName) {
                folders[i].listNames[idx] = clean
                foldersChanged = true
            }
        }
        if foldersChanged {
            saveFolders()
        }

        for i in 0..<steps.count {
            if steps[i].phase == oldName {
                steps[i].phase = clean
            }
        }
        saveAllSteps()
        HapticFeedback.success()
    }

    // MARK: - Task Color Labels Management

    public func loadLabels() {
        if let data = try? Data(contentsOf: labelsURL),
           let saved = try? appDecoder.decode([TaskColorLabel].self, from: data),
           !saved.isEmpty {
            self.labels = saved
        } else {
            self.labels = defaultLabels()
            saveLabels()
        }
    }

    private func defaultLabels() -> [TaskColorLabel] {
        [
            TaskColorLabel(name: "Gesundheit & Pflege", colorHex: "#0B8043"),
            TaskColorLabel(name: "Dienst & Bundeswehr", colorHex: "#33B679"),
            TaskColorLabel(name: "Wirtschaftsinformatik", colorHex: "#039BE5"),
            TaskColorLabel(name: "BFD-Zertifikate", colorHex: "#8E24AA"),
            TaskColorLabel(name: "Finanzen & Budget", colorHex: "#F6BF26"),
            TaskColorLabel(name: "Deep Work (Fokus)", colorHex: "#D50000"),
            TaskColorLabel(name: "Quick Hit (<5min)", colorHex: "#3F51B5")
        ]
    }

    public func saveLabels() {
        if let data = try? JSONEncoder().encode(labels) {
            try? data.write(to: labelsURL)
        }
    }

    public func setLabels(_ newLabels: [TaskColorLabel]) {
        self.labels = newLabels
        saveLabels()
        HapticFeedback.success()
    }

    public func label(for id: String?) -> TaskColorLabel? {
        guard let id = id else { return nil }
        return labels.first(where: { $0.id == id })
    }

    public func addResource(to stepId: String, title: String, url: String, type: String = "Web", badge: String? = nil) {
        guard let idx = steps.firstIndex(where: { $0.id == stepId }) else { return }
        let res = StepResource(
            id: UUID().uuidString,
            title: title,
            url: url,
            type: type,
            badge: badge,
            isUserAdded: true
        )
        steps[idx].resources.append(res)
        saveAllSteps()
        HapticFeedback.success()
    }

    public func deleteResource(from stepId: String, resourceId: String) {
        guard let sIdx = steps.firstIndex(where: { $0.id == stepId }) else { return }
        steps[sIdx].resources.removeAll(where: { $0.id == resourceId })
        saveAllSteps()
        HapticFeedback.light()
    }

    // MARK: - Modul- & Kurs-Bearbeitung
    public func updateStep(_ updatedStep: RoadmapStep) {
        guard let idx = steps.firstIndex(where: { $0.id == updatedStep.id }) else { return }
        steps[idx] = updatedStep
        saveAllSteps()
        HapticFeedback.success()
    }

    public func updateSubmodule(stepId: String? = nil, updatedSubmodule: StudySubmodule) {
        var targetStepIdx: Int? = nil
        var targetSubmodIdx: Int? = nil

        if let sId = stepId, let idx = steps.firstIndex(where: { $0.id == sId }) {
            if let smIdx = steps[idx].submodules.firstIndex(where: { $0.id == updatedSubmodule.id }) {
                targetStepIdx = idx
                targetSubmodIdx = smIdx
            }
        }

        // Robuster Fallback: Durchsuche alle Schritte nach der Submodul-ID
        if targetStepIdx == nil {
            for i in 0..<steps.count {
                if let smIdx = steps[i].submodules.firstIndex(where: { $0.id == updatedSubmodule.id }) {
                    targetStepIdx = i
                    targetSubmodIdx = smIdx
                    break
                }
            }
        }

        guard let sIdx = targetStepIdx, let smIdx = targetSubmodIdx else {
            return
        }

        steps[sIdx].submodules[smIdx] = updatedSubmodule
        saveAllSteps()
        HapticFeedback.success()
    }

    public func addResourceToSubmodule(stepId: String? = nil, submoduleId: String, title: String, url: String, type: String = "Web") {
        var sIdx = stepId != nil ? steps.firstIndex(where: { $0.id == stepId }) : nil
        var smIdx: Int? = nil

        if let si = sIdx {
            smIdx = steps[si].submodules.firstIndex(where: { $0.id == submoduleId })
        }

        if sIdx == nil || smIdx == nil {
            for i in 0..<steps.count {
                if let subIndex = steps[i].submodules.firstIndex(where: { $0.id == submoduleId }) {
                    sIdx = i
                    smIdx = subIndex
                    break
                }
            }
        }

        guard let targetSIdx = sIdx, let targetSmIdx = smIdx else { return }

        let newRes = StepResource(
            id: UUID().uuidString,
            title: title,
            url: url,
            type: type,
            isUserAdded: true
        )
        if steps[targetSIdx].submodules[targetSmIdx].attachedResources == nil {
            steps[targetSIdx].submodules[targetSmIdx].attachedResources = []
        }
        steps[targetSIdx].submodules[targetSmIdx].attachedResources?.append(newRes)

        // Falls das Submodul bisher keine primäre URL hatte, verknüpfe diese direkt
        if steps[targetSIdx].submodules[targetSmIdx].url == nil || steps[targetSIdx].submodules[targetSmIdx].url?.isEmpty == true {
            steps[targetSIdx].submodules[targetSmIdx].url = url
            if type == "PDF" || url.hasPrefix("file://") {
                steps[targetSIdx].submodules[targetSmIdx].type = .pdfDocument
            }
        }

        saveAllSteps()
        HapticFeedback.success()
    }

    public func deleteResourceFromSubmodule(stepId: String? = nil, submoduleId: String, resourceId: String) {
        var sIdx = stepId != nil ? steps.firstIndex(where: { $0.id == stepId }) : nil
        var smIdx: Int? = nil

        if let si = sIdx {
            smIdx = steps[si].submodules.firstIndex(where: { $0.id == submoduleId })
        }

        if sIdx == nil || smIdx == nil {
            for i in 0..<steps.count {
                if let subIndex = steps[i].submodules.firstIndex(where: { $0.id == submoduleId }) {
                    sIdx = i
                    smIdx = subIndex
                    break
                }
            }
        }

        guard let targetSIdx = sIdx, let targetSmIdx = smIdx else { return }

        steps[targetSIdx].submodules[targetSmIdx].attachedResources?.removeAll(where: { $0.id == resourceId })
        saveAllSteps()
        HapticFeedback.light()
    }

    public func saveAllSteps() {
        do {
            let data = try appEncoder.encode(steps)
            try data.write(to: allStepsURL, options: .atomic)
        } catch {
            print("Failed to save steps to allStepsURL:", error)
        }
        saveCustomizations()
        saveProgress()
    }

    public func saveCustomizations() {
        var recordMap: [String: StepCustomizationRecord] = [:]
        for s in steps {
            let addedSubs = s.submodules.filter { $0.isUserAdded == true }
            let addedRes = s.resources.filter { $0.isUserAdded == true }
            if !addedSubs.isEmpty || !addedRes.isEmpty {
                recordMap[s.id] = StepCustomizationRecord(customSubmodules: addedSubs, customResources: addedRes)
            }
        }
        if let data = try? JSONEncoder().encode(recordMap) {
            try? data.write(to: customizationsURL)
        }
    }

    public func rotateQuote() {
        if let random = quotes.randomElement() {
            self.currentQuote = random
        }
    }

    // MARK: - Focus Timer (Pomodoro Engine)
    public func startFocusTimer(for stepId: String, minutes: Int = 25) {
        self.activeTimerStepId = stepId
        self.focusTimerSecondsRemaining = minutes * 60
        self.isFocusTimerRunning = true
        
        timerCancellable?.cancel()
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                if self.focusTimerSecondsRemaining > 0 {
                    self.focusTimerSecondsRemaining -= 1
                } else {
                    self.isFocusTimerRunning = false
                    self.timerCancellable?.cancel()
                    if let sid = self.activeTimerStepId {
                        if self.steps.contains(where: { $0.id == sid }) {
                            self.completeStep(id: sid)
                        } else {
                            for step in self.steps {
                                if step.submodules.contains(where: { $0.id == sid }) {
                                    self.toggleSubmoduleCompletion(stepId: step.id, submoduleId: sid)
                                    break
                                }
                            }
                        }
                    }
                    HapticFeedback.success()
                }
            }
        HapticFeedback.medium()
    }

    public func stopFocusTimer() {
        self.isFocusTimerRunning = false
        self.timerCancellable?.cancel()
        HapticFeedback.light()
    }

    // MARK: - Modul & Submodul Tages-Planung & Kalender-Sync
    public func planStep(stepId: String, date: Date?, syncToCalendar: Bool = true) {
        recordUndoSnapshot()
        guard let idx = steps.firstIndex(where: { $0.id == stepId }) else { return }
        
        // If unplanning or replacing, remove old calendar event if exists
        if let oldEventId = steps[idx].calendarEventId {
            StudyCalendarSyncService.shared.removeEvent(withIdentifier: oldEventId)
            steps[idx].calendarEventId = nil
        }
        
        steps[idx].plannedDate = date
        savePlanning()
        
        if let planned = date, syncToCalendar {
            let step = steps[idx]
            Task {
                let result = await StudyCalendarSyncService.shared.syncPlannedStudyEvent(
                    title: step.title,
                    track: step.track,
                    date: planned,
                    durationMinutes: step.estimatedMinutes,
                    notes: step.subtitle
                )
                if result.success, let eventId = result.eventId {
                    await MainActor.run {
                        if let currentIdx = self.steps.firstIndex(where: { $0.id == stepId }) {
                            self.steps[currentIdx].calendarEventId = eventId
                            self.savePlanning()
                        }
                    }
                }
            }
        }
        HapticFeedback.medium()
    }

    public func planSubmodule(stepId: String, submoduleId: String, date: Date?, syncToCalendar: Bool = true) {
        recordUndoSnapshot()
        guard let stepIdx = steps.firstIndex(where: { $0.id == stepId }) else { return }
        guard let subIdx = steps[stepIdx].submodules.firstIndex(where: { $0.id == submoduleId }) else { return }
        
        if let oldEventId = steps[stepIdx].submodules[subIdx].calendarEventId {
            StudyCalendarSyncService.shared.removeEvent(withIdentifier: oldEventId)
            steps[stepIdx].submodules[subIdx].calendarEventId = nil
        }
        
        steps[stepIdx].submodules[subIdx].plannedDate = date
        savePlanning()
        
        if let planned = date, syncToCalendar {
            let step = steps[stepIdx]
            let sub = step.submodules[subIdx]
            Task {
                let result = await StudyCalendarSyncService.shared.syncPlannedStudyEvent(
                    title: "\(step.title): \(sub.title)",
                    track: step.track,
                    date: planned,
                    durationMinutes: sub.durationMinutes,
                    notes: sub.type.rawValue + (sub.url != nil ? "\nLink: \(sub.url!)" : "")
                )
                if result.success, let eventId = result.eventId {
                    await MainActor.run {
                        if let currentStepIdx = self.steps.firstIndex(where: { $0.id == stepId }),
                           let currentSubIdx = self.steps[currentStepIdx].submodules.firstIndex(where: { $0.id == submoduleId }) {
                            self.steps[currentStepIdx].submodules[currentSubIdx].calendarEventId = eventId
                            self.savePlanning()
                        }
                    }
                }
            }
        }
        HapticFeedback.medium()
    }

    public func plannedSteps(for date: Date, track: StudyTrack? = nil) -> [RoadmapStep] {
        let cal = Calendar.current
        return steps.filter { step in
            if let t = track, step.track != t { return false }
            if let pd = step.plannedDate {
                if cal.isDate(pd, inSameDayAs: date) { return true }
                if let rule = step.recurrenceRule, !rule.isExpired, rule.isScheduled(on: date, startingFrom: pd) {
                    return true
                }
            }
            return false
        }
    }

    public func plannedSubmodules(for date: Date, track: StudyTrack? = nil) -> [(step: RoadmapStep, submodule: StudySubmodule)] {
        let cal = Calendar.current
        var result: [(step: RoadmapStep, submodule: StudySubmodule)] = []
        for step in steps {
            if let t = track, step.track != t { continue }
            for sub in step.submodules {
                if let pd = sub.plannedDate {
                    if cal.isDate(pd, inSameDayAs: date) {
                        result.append((step: step, submodule: sub))
                    } else if let rule = sub.recurrenceRule, !rule.isExpired, rule.isScheduled(on: date, startingFrom: pd) {
                        result.append((step: step, submodule: sub))
                    }
                }
            }
        }
        return result
    }

    public func hasPlannedItems(for date: Date, track: StudyTrack? = nil) -> Bool {
        let cal = Calendar.current
        for step in steps {
            if let t = track, step.track != t { continue }
            if let pd = step.plannedDate {
                if cal.isDate(pd, inSameDayAs: date) { return true }
                if let rule = step.recurrenceRule, !rule.isExpired, rule.isScheduled(on: date, startingFrom: pd) {
                    return true
                }
            }
            for sub in step.submodules {
                if let pd = sub.plannedDate {
                    if cal.isDate(pd, inSameDayAs: date) { return true }
                    if let rule = sub.recurrenceRule, !rule.isExpired, rule.isScheduled(on: date, startingFrom: pd) {
                        return true
                    }
                }
            }
        }
        return false
    }

    public func syncEcosystemScheduleFromBridge() {
        self.sharedMeals = GrowSuiteBridge.shared.loadMealsLedger().meals
        self.sharedWorkouts = GrowSuiteBridge.shared.loadWorkoutScheduleLedger().items
        self.sharedSupplements = GrowSuiteBridge.shared.loadSupplementScheduleLedger().items
    }

    public func workouts(for date: Date) -> [SharedWorkoutScheduleItem] {
        let cal = Calendar.current
        return sharedWorkouts.filter { cal.isDate($0.scheduledDate, inSameDayAs: date) }
    }

    public func meals(for date: Date) -> [SharedLoggedMeal] {
        let cal = Calendar.current
        return sharedMeals.filter { cal.isDate($0.timestamp, inSameDayAs: date) }
    }

    public func supplements(for date: Date) -> [SharedSupplementScheduleItem] {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        let ds = fmt.string(from: date)
        return sharedSupplements.filter { $0.dateString == ds }
    }

    public func hasFinanceEvent(for date: Date) -> Bool {
        let day = Calendar.current.component(.day, from: date)
        // Feste Rhythmen: 28. (Targobank Tilgung), 1. (Monats-Budget), 15. (Halbmonats-Audit)
        return day == 28 || day == 1 || day == 15
    }

    public func ecosystemAppDots(for date: Date, track: StudyTrack? = nil) -> [Color] {
        var dots: [Color] = []

        // 1. Growcery (Essen / Mahlzeiten / Rezepte / Supplements) -> Gruen
        if !meals(for: date).isEmpty || !supplements(for: date).isEmpty {
            dots.append(Color(red: 0.30, green: 0.80, blue: 0.45))
        }

        // 2. Grow (Gym / Workout-Splits) -> Rot
        if !workouts(for: date).isEmpty {
            dots.append(Color(red: 0.95, green: 0.30, blue: 0.35))
        }

        // 3. GrowStudy (Akademik / Aufgaben / Module) -> Blau
        let hasStudy = !plannedSteps(for: date, track: track).isEmpty || !plannedSubmodules(for: date, track: track).isEmpty
        if hasStudy {
            dots.append(Color(red: 0.25, green: 0.58, blue: 0.98))
        }

        // 4. GrowFinance (Finanzen / Fixkosten / Tilgung) -> Gelb
        if hasFinanceEvent(for: date) {
            dots.append(Color(red: 0.98, green: 0.78, blue: 0.20))
        }

        return Array(dots.prefix(4))
    }

    public func plannedItemsCount(for date: Date, track: StudyTrack? = nil) -> Int {
        let studyCount = plannedSteps(for: date, track: track).count + plannedSubmodules(for: date, track: track).count
        let wCount = workouts(for: date).count
        let mCount = meals(for: date).count
        let sCount = supplements(for: date).isEmpty ? 0 : 1
        return studyCount + wCount + mCount + sCount
    }
}

// MARK: - Planning Persistence Models
public struct StepPlanningRecord: Codable {
    public var stepPlannedDate: Date?
    public var stepCalendarEventId: String?
    public var submodules: [String: SubmodulePlanningRecord]

    public init(stepPlannedDate: Date? = nil, stepCalendarEventId: String? = nil, submodules: [String: SubmodulePlanningRecord] = [:]) {
        self.stepPlannedDate = stepPlannedDate
        self.stepCalendarEventId = stepCalendarEventId
        self.submodules = submodules
    }
}

public struct SubmodulePlanningRecord: Codable {
    public var plannedDate: Date?
    public var calendarEventId: String?

    public init(plannedDate: Date? = nil, calendarEventId: String? = nil) {
        self.plannedDate = plannedDate
        self.calendarEventId = calendarEventId
    }
}
