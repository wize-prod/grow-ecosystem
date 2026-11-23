import Foundation
import SwiftUI
import Combine
import AVFoundation
import GrowCore
import SQLite3

// MARK: - Planned Workout Item in Tagesdetail
public struct PlannedWorkoutItem: Identifiable, Codable, Equatable {
    public var id: UUID
    public var programId: UUID
    public var programName: String
    public var sessionId: UUID
    public var dayNumber: Int
    public var title: String
    public var plannedDate: Date
    public var isCompleted: Bool
    public var completedAt: Date?
    public var modalityRaw: String
    public var templateId: UUID?
    public var calendarEventId: String?
    public var notes: String
    public var exerciseNames: [String]

    public init(
        id: UUID = UUID(),
        programId: UUID = UUID(),
        programName: String = "",
        sessionId: UUID = UUID(),
        dayNumber: Int = 1,
        title: String,
        plannedDate: Date,
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        modalityRaw: String = "kraft",
        templateId: UUID? = nil,
        calendarEventId: String? = nil,
        notes: String = "",
        exerciseNames: [String] = []
    ) {
        self.id = id
        self.programId = programId
        self.programName = programName
        self.sessionId = sessionId
        self.dayNumber = dayNumber
        self.title = title
        self.plannedDate = plannedDate
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.modalityRaw = modalityRaw
        self.templateId = templateId
        self.calendarEventId = calendarEventId
        self.notes = notes
        self.exerciseNames = exerciseNames
    }

    enum CodingKeys: String, CodingKey {
        case id, programId, programName, sessionId, dayNumber, title, plannedDate
        case isCompleted, completedAt, modalityRaw, templateId, calendarEventId, notes, exerciseNames
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        programId = try container.decodeIfPresent(UUID.self, forKey: .programId) ?? UUID()
        programName = try container.decodeIfPresent(String.self, forKey: .programName) ?? ""
        sessionId = try container.decodeIfPresent(UUID.self, forKey: .sessionId) ?? UUID()
        dayNumber = try container.decodeIfPresent(Int.self, forKey: .dayNumber) ?? 1
        title = try container.decode(String.self, forKey: .title)
        plannedDate = try container.decode(Date.self, forKey: .plannedDate)
        isCompleted = try container.decodeIfPresent(Bool.self, forKey: .isCompleted) ?? false
        completedAt = try container.decodeIfPresent(Date.self, forKey: .completedAt)
        modalityRaw = try container.decodeIfPresent(String.self, forKey: .modalityRaw) ?? "kraft"
        templateId = try container.decodeIfPresent(UUID.self, forKey: .templateId)
        calendarEventId = try container.decodeIfPresent(String.self, forKey: .calendarEventId)
        notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
        exerciseNames = try container.decodeIfPresent([String].self, forKey: .exerciseNames) ?? []
    }
}

// MARK: - Decoupled Rest Timer Manager (High-Performance 1Hz Timer Isolation)
@MainActor
public final class WorkoutRestTimerManager: ObservableObject {
    public static let shared = WorkoutRestTimerManager()

    @Published public var secondsRemaining: Int = 0
    @Published public var isRunning: Bool = false
    @Published public var supersetNote: String? = nil
    public var targetEndTime: Date? = nil

    private var cancellable: AnyCancellable?
    private let notificationId = "grow_rest_timer_notification"

    private init() {
        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] _ in
            self?.recalculateRemaining()
        }
    }

    public func recalculateRemaining() {
        guard isRunning, let target = targetEndTime else { return }
        let rem = Int(ceil(target.timeIntervalSinceNow))
        if rem > 0 {
            secondsRemaining = rem
        } else {
            secondsRemaining = 0
            stop(playBell: true)
        }
    }

    public func start(seconds: Int, supersetTargetExerciseName: String? = nil) {
        cancellable?.cancel()
        let duration = max(5, seconds)
        secondsRemaining = duration
        targetEndTime = Date().addingTimeInterval(TimeInterval(duration))
        isRunning = true
        supersetNote = supersetTargetExerciseName

        scheduleNotification(duration: duration, targetName: supersetTargetExerciseName)

        cancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, self.isRunning, let target = self.targetEndTime else { return }
                let rem = Int(ceil(target.timeIntervalSinceNow))
                if rem > 0 {
                    self.secondsRemaining = rem
                    if rem == 30 {
                        HapticFeedback.warning()
                    }
                    if rem <= 5 && rem >= 1 {
                        BoxingBellAudioService.shared.playCountdownBeep()
                        HapticFeedback.light()
                    }
                } else {
                    self.secondsRemaining = 0
                    self.stop(playBell: true)
                }
            }
    }

    private func scheduleNotification(duration: Int, targetName: String?) {
        let content = UNMutableNotificationContent()
        content.title = "Pause beendet"
        content.body = targetName != nil ? "Weiter mit: \(targetName!)" : "Zeit fuer den naechsten Satz!"
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(duration), repeats: false)
        let request = UNNotificationRequest(identifier: notificationId, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    public func adjust(deltaSeconds: Int) {
        if let target = targetEndTime {
            let newTarget = target.addingTimeInterval(TimeInterval(deltaSeconds))
            targetEndTime = newTarget
            let rem = max(5, Int(ceil(newTarget.timeIntervalSinceNow)))
            secondsRemaining = rem
            scheduleNotification(duration: rem, targetName: supersetNote)
        } else {
            secondsRemaining = max(5, secondsRemaining + deltaSeconds)
        }
        HapticFeedback.light()
    }

    public func stop(playBell: Bool = false) {
        isRunning = false
        supersetNote = nil
        targetEndTime = nil
        cancellable?.cancel()
        cancellable = nil
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationId])
        if playBell {
            BoxingBellAudioService.shared.playBoxingBell()
            HapticFeedback.success()
        }
        GymStore.shared.markSetStarted()
    }
}

@MainActor
public final class GymStore: ObservableObject {
    public static let shared = GymStore()

    @Published public var exercises: [Exercise] = []
    @Published public var templates: [WorkoutTemplate] = []
    @Published public var sessions: [WorkoutSession] = []
    @Published public var measurements: [BodyMeasurementEntry] = []
    @Published public var programs: [TrainingProgram] = []
    @Published public var enrollments: [ProgramEnrollment] = []
    @Published public var plannedWorkouts: [PlannedWorkoutItem] = []
    @Published public var benchmarkRegistry: BenchmarkRegistryState = BenchmarkRegistryState()
    @Published public var flowFeedbacks: [FlowPostSessionFeedback] = []
    @Published public var partialSessions: [OlympicCoachEngine.PartialSessionRecord] = []
    @Published public var userPreferences: UserExercisePreferenceProfile = UserExercisePreferenceProfile()
    @Published public var activeAdaptiveConstraints: [String: String] = [:]
    @Published public var dailyNotes: [String: String] = [:]
    @Published public var tuningMatrix: CoachTuningMatrix = CoachTuningMatrix()
    @Published public var isPresentingActiveWorkout: Bool = false
    @Published public var inspectingCompletedSession: WorkoutSession? = nil
    @Published public var activeSession: WorkoutSession? {
        didSet {
            if let session = activeSession {
                saveAsync(session, to: activeSessionURL)
            } else {
                try? FileManager.default.removeItem(at: activeSessionURL)
                isPresentingActiveWorkout = false
            }
        }
    }
    @Published public var activeSetStartTime: Date? = nil

    public func markSetStarted() {
        activeSetStartTime = Date()
    }

    // MARK: - Exercise Favorites & Search Popularity Engine
    @Published public var favoriteExerciseNames: Set<String> = []
    @Published public var exerciseSearchCounts: [String: Int] = [:]

    private let favoritesStorageKey = "gym_favorite_exercise_names_v1"
    private let searchCountsStorageKey = "gym_exercise_search_counts_v1"

    public func loadFavoritesAndSearchStats() {
        if let favArr = UserDefaults.standard.stringArray(forKey: favoritesStorageKey) {
            favoriteExerciseNames = Set(favArr)
        } else {
            favoriteExerciseNames = ["Einarmige Liegestuetze", "Liegestuetze (BWK-konform kontrolliert)", "Unterarmstuetz / Plank"]
        }
        if let dict = UserDefaults.standard.dictionary(forKey: searchCountsStorageKey) as? [String: Int] {
            exerciseSearchCounts = dict
        }
    }

    public func isFavorite(exerciseName: String) -> Bool {
        favoriteExerciseNames.contains(exerciseName)
    }

    public func toggleFavorite(exerciseName: String) {
        if favoriteExerciseNames.contains(exerciseName) {
            favoriteExerciseNames.remove(exerciseName)
        } else {
            favoriteExerciseNames.insert(exerciseName)
        }
        UserDefaults.standard.set(Array(favoriteExerciseNames), forKey: favoritesStorageKey)
        HapticFeedback.light()
    }

    public func recordExerciseSearch(query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return }
        for ex in exercises {
            if ex.name.localizedCaseInsensitiveContains(trimmed) {
                exerciseSearchCounts[ex.name, default: 0] += 1
            }
        }
        UserDefaults.standard.set(exerciseSearchCounts, forKey: searchCountsStorageKey)
    }

    public func recordExerciseInteraction(exerciseName: String) {
        exerciseSearchCounts[exerciseName, default: 0] += 3
        UserDefaults.standard.set(exerciseSearchCounts, forKey: searchCountsStorageKey)
    }

    public func exercisePopularityScore(_ exercise: Exercise) -> Int {
        var score = 0
        if favoriteExerciseNames.contains(exercise.name) {
            score += 100
        }
        let targetName = exercise.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        var loggedCount = 0
        for s in sessions {
            if s.exercises.contains(where: { $0.exercise.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == targetName }) {
                loggedCount += 1
            }
        }
        score += loggedCount * 10
        let searchCount = exerciseSearchCounts[exercise.name] ?? 0
        score += searchCount * 5
        return score
    }

    // Decoupled Rest Timer Properties (Forwarding to WorkoutRestTimerManager to prevent global invalidation)
    public var restTimer: WorkoutRestTimerManager { WorkoutRestTimerManager.shared }
    public var activeRestTimerSeconds: Int { WorkoutRestTimerManager.shared.secondsRemaining }
    public var isRestTimerRunning: Bool { WorkoutRestTimerManager.shared.isRunning }
    public var activeRestTimerSupersetNote: String? { WorkoutRestTimerManager.shared.supersetNote }
    public var activeSupersetTargetExerciseId: UUID? = nil
    public var targetWaterMl: Double = 2500.0

    // High-Performance Cached Metrics & Lookup Maps
    private let storageQueue = DispatchQueue(label: "com.grow.gym.storage", qos: .utility)
    private var _cachedAllSessionsWithExternal: [WorkoutSession]? = nil
    private var _cachedWorkoutDateKeys: Set<String>? = nil

    private var healthKitCancellable: AnyCancellable?
    private let fileManager = FileManager.default

    private init() {
        loadData()
        loadFavoritesAndSearchStats()
        syncWorkoutScheduleToBridge()

        healthKitCancellable = HealthKitService.shared.$syncedWorkouts
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.invalidateSessionCaches()
                self?.objectWillChange.send()
            }
        let defaults = ExerciseCatalogSeed.defaultExercises()
        var currentNames = Set(exercises.map { $0.name })
        var exercisesUpdated = false
        for def in defaults {
            if !currentNames.contains(def.name) {
                exercises.append(def)
                currentNames.insert(def.name)
                exercisesUpdated = true
            } else if let idx = exercises.firstIndex(where: { $0.name == def.name }), exercises[idx].targetMuscle != def.targetMuscle {
                exercises[idx].targetMuscle = def.targetMuscle
                exercisesUpdated = true
            }
        }
        if exercises.isEmpty {
            exercises = defaults
            exercisesUpdated = true
        }
        // Migrate legacy MuscleWiki references and backfill rich technical details
        for i in 0..<exercises.count {
            if exercises[i].executionNotes.contains("MuscleWiki") {
                if let def = defaults.first(where: { $0.name == exercises[i].name }) {
                    exercises[i].executionNotes = def.executionNotes
                } else {
                    exercises[i].executionNotes = exercises[i].executionNotes.replacingOccurrences(of: "MuscleWiki", with: "Biomechanik")
                }
                exercisesUpdated = true
            }
            if exercises[i].setup.isEmpty || exercises[i].commonMistakes.isEmpty {
                ExerciseCatalogSeed.enrichExercise(&exercises[i])
                exercisesUpdated = true
            }
        }
        if exercisesUpdated {
            saveExercises()
        }

        // Poka-Yoke & Muda-Eliminierung: Keine automatische Zwangs-Injektion vorgefertigter Templates.
        // Die Trainingssteuerung erfolgt datengetrieben via MCP und KI basierend auf akuter Ermüdung und Fortschritt.
        savePlannedWorkouts()

        syncWaterFromBridge()

        DarwinNotificationCenter.observe(DarwinNotificationCenter.waterUpdated) { [weak self] in
            Task { @MainActor in
                self?.syncWaterFromBridge()
            }
        }

        NotificationCenter.default.addObserver(forName: UIApplication.significantTimeChangeNotification, object: nil, queue: .main) { [weak self] _ in
            self?.syncWaterFromBridge()
        }
    }

    // MARK: - Integrierte Historie (Grow + Google Health / Apple Health)
    public func invalidateSessionCaches() {
        _cachedAllSessionsWithExternal = nil
        _cachedWorkoutDateKeys = nil
    }

    public func refreshEcosystemBridgeCache() {
        // Cache synchronization hook
    }

    public var allSessionsWithExternal: [WorkoutSession] {
        if let cached = _cachedAllSessionsWithExternal {
            return cached
        }
        let external = HealthKitService.shared.syncedWorkouts.map { $0.asWorkoutSession() }
        let nonDuplicateExternal = external.filter { ext in
            !sessions.contains { internalSession in
                abs(internalSession.startTime.timeIntervalSince(ext.startTime)) < 1800
            }
        }
        let merged = (sessions + nonDuplicateExternal).sorted(by: { $0.startTime > $1.startTime })
        _cachedAllSessionsWithExternal = merged
        return merged
    }

    public func hasWorkoutOnDate(_ date: Date) -> Bool {
        let key = Self.dateKey(for: date)
        if let keys = _cachedWorkoutDateKeys {
            return keys.contains(key)
        }
        var set = Set<String>()
        for session in allSessionsWithExternal {
            set.insert(Self.dateKey(for: session.startTime))
        }
        _cachedWorkoutDateKeys = set
        return set.contains(key)
    }

    public func clearAllSessions() {
        self.sessions = []
        saveSessions()
        HapticFeedback.success()
    }

    public func clearAllMeasurements() {
        self.measurements = []
        saveMeasurements()
        HapticFeedback.success()
    }

    public func resetToBundeswehrCatalog() {
        self.exercises = ExerciseCatalogSeed.defaultExercises()
        self.templates = []
        self.sessions = []
        saveExercises()
        saveTemplates()
        saveSessions()
        HapticFeedback.success()
    }

    public func resetAllProgressToZero() {
        self.sessions = []
        self.measurements = []
        self.enrollments = []
        self.dailyNotes = [:]
        self.plannedWorkouts = []
        self.flowFeedbacks = []
        self.partialSessions = []
        self.benchmarkRegistry = BenchmarkRegistryState()
        saveSessions()
        saveMeasurements()
        saveEnrollments()
        saveDailyNotes()
        savePlannedWorkouts()
        saveBenchmarks()
        refreshEcosystemBridgeCache()
        HapticFeedback.success()
    }

    // MARK: - Dateipfade & Multi-User Partitioning
    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    public var currentUserStorageDirectory: URL {
        let key = UserAccountService.shared.currentAccount.userKey
        let dir = documentsDirectory
            .appendingPathComponent("userData", isDirectory: true)
            .appendingPathComponent(key, isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
            if key == "primary_wize_prod" {
                migrateLegacyFilesIfNeeded(to: dir)
            }
        }
        return dir
    }

    private func migrateLegacyFilesIfNeeded(to targetDir: URL) {
        let fileNames = [
            "exercises.json", "templates.json", "sessions.json", "workout_sessions.json",
            "measurements.json", "programs.json", "enrollments.json", "benchmarks.json",
            "flow_feedbacks.json", "partial_sessions.json", "adaptive_constraints.json",
            "daily_notes.json", "planned_workouts.json"
        ]
        for name in fileNames {
            let src = documentsDirectory.appendingPathComponent(name)
            let dst = targetDir.appendingPathComponent(name)
            if fileManager.fileExists(atPath: src.path) && !fileManager.fileExists(atPath: dst.path) {
                try? fileManager.copyItem(at: src, to: dst)
            }
        }
    }

    private var exercisesURL: URL {
        currentUserStorageDirectory.appendingPathComponent("exercises.json")
    }

    private var templatesURL: URL {
        currentUserStorageDirectory.appendingPathComponent("templates.json")
    }

    private var sessionsURL: URL {
        currentUserStorageDirectory.appendingPathComponent("sessions.json")
    }

    private var measurementsURL: URL {
        currentUserStorageDirectory.appendingPathComponent("measurements.json")
    }

    private var programsURL: URL {
        currentUserStorageDirectory.appendingPathComponent("programs.json")
    }

    private var enrollmentsURL: URL {
        currentUserStorageDirectory.appendingPathComponent("enrollments.json")
    }

    private var benchmarksURL: URL {
        currentUserStorageDirectory.appendingPathComponent("benchmarks.json")
    }

    private var flowFeedbacksURL: URL {
        currentUserStorageDirectory.appendingPathComponent("flow_feedbacks.json")
    }

    private var partialSessionsURL: URL {
        currentUserStorageDirectory.appendingPathComponent("partial_sessions.json")
    }

    private var constraintsURL: URL {
        currentUserStorageDirectory.appendingPathComponent("adaptive_constraints.json")
    }

    private var dailyNotesURL: URL {
        currentUserStorageDirectory.appendingPathComponent("daily_notes.json")
    }

    private var plannedWorkoutsURL: URL {
        currentUserStorageDirectory.appendingPathComponent("planned_workouts.json")
    }

    private var userPreferencesURL: URL {
        currentUserStorageDirectory.appendingPathComponent("user_preferences.json")
    }

    private var coachTuningMatrixURL: URL {
        currentUserStorageDirectory.appendingPathComponent("coach_tuning_matrix.json")
    }

    private var activeSessionURL: URL {
        currentUserStorageDirectory.appendingPathComponent("active_session.json")
    }

    // MARK: - Laden und Speichern
    public func loadData() {
        if let data = try? Data(contentsOf: exercisesURL),
           let loaded = try? JSONDecoder().decode([Exercise].self, from: data),
           !loaded.isEmpty {
            self.exercises = loaded
        } else {
            self.exercises = ExerciseCatalogSeed.defaultExercises()
            saveExercises()
        }
        if let data = try? Data(contentsOf: templatesURL),
           let loaded = try? JSONDecoder().decode([WorkoutTemplate].self, from: data) {
            self.templates = loaded
        }
        if let data = try? Data(contentsOf: sessionsURL),
           let loaded = try? JSONDecoder().decode([WorkoutSession].self, from: data) {
            self.sessions = loaded
        } else if let data = try? Data(contentsOf: documentsDirectory.appendingPathComponent("workout_sessions.json")),
                  let loaded = try? JSONDecoder().decode([WorkoutSession].self, from: data) {
            self.sessions = loaded
        }
        // Fake 1-Minuten Workouts (< 120 Sekunden ohne Uebungen) eliminieren
        let initialSessionCount = self.sessions.count
        self.sessions.removeAll { s in
            let dur = s.endTime?.timeIntervalSince(s.startTime) ?? Double(s.durationMinutes * 60)
            return dur < 120.0 && s.exercises.isEmpty
        }
        if self.sessions.count != initialSessionCount {
            saveSessions()
        }

        // User Mandate: Reset all legacy weight entries to 0.0kg (overall app tonnage = 0kg)
        resetOverallAppTonnage()

        if let data = try? Data(contentsOf: measurementsURL),
           let loaded = try? JSONDecoder().decode([BodyMeasurementEntry].self, from: data) {
            self.measurements = loaded
            if let w = loaded.first(where: { $0.type == .weight })?.value {
                let bf = loaded.first(where: { $0.type == .bodyFat })?.value
                DynamicFitnessEngine.shared.recalculate(customWeightKg: w, customFatPct: bf)
            }
        }
        if let data = try? Data(contentsOf: programsURL),
           let loaded = try? JSONDecoder().decode([TrainingProgram].self, from: data) {
            self.programs = loaded
        } else {
            self.programs = []
        }

        if let data = try? Data(contentsOf: dailyNotesURL),
           let loaded = try? JSONDecoder().decode([String: String].self, from: data) {
            self.dailyNotes = loaded
        }
        if let data = try? Data(contentsOf: enrollmentsURL),
           let loaded = try? JSONDecoder().decode([ProgramEnrollment].self, from: data) {
            self.enrollments = loaded
        }
        if let data = try? Data(contentsOf: plannedWorkoutsURL),
           let loaded = try? JSONDecoder().decode([PlannedWorkoutItem].self, from: data) {
            self.plannedWorkouts = loaded
        }
        // Poka-Yoke cross-reconciliation: ensure planned workouts with a completed session are marked isCompleted
        for s in self.sessions {
            if let pId = s.plannedWorkoutId,
               let pIdx = self.plannedWorkouts.firstIndex(where: { $0.id == pId }) {
                if !self.plannedWorkouts[pIdx].isCompleted {
                    self.plannedWorkouts[pIdx].isCompleted = true
                    self.plannedWorkouts[pIdx].completedAt = s.endTime
                }
            }
        }
        if let data = try? Data(contentsOf: benchmarksURL),
           let loaded = try? JSONDecoder().decode(BenchmarkRegistryState.self, from: data) {
            self.benchmarkRegistry = loaded
        }
        if let data = try? Data(contentsOf: flowFeedbacksURL),
           let loaded = try? JSONDecoder().decode([FlowPostSessionFeedback].self, from: data) {
            self.flowFeedbacks = loaded
        }
        if let data = try? Data(contentsOf: partialSessionsURL),
           let loaded = try? JSONDecoder().decode([OlympicCoachEngine.PartialSessionRecord].self, from: data) {
            self.partialSessions = loaded
        }
        if let data = try? Data(contentsOf: userPreferencesURL),
           let loaded = try? JSONDecoder().decode(UserExercisePreferenceProfile.self, from: data) {
            self.userPreferences = loaded
        }
        if let data = try? Data(contentsOf: constraintsURL),
           let loaded = try? JSONDecoder().decode([String: String].self, from: data) {
            self.activeAdaptiveConstraints = loaded
        }
        if let data = try? Data(contentsOf: coachTuningMatrixURL),
           let loaded = try? JSONDecoder().decode(CoachTuningMatrix.self, from: data) {
            self.tuningMatrix = loaded
        } else if let data = try? Data(contentsOf: documentsDirectory.appendingPathComponent("coach_tuning_matrix.json")),
                  let loaded = try? JSONDecoder().decode(CoachTuningMatrix.self, from: data) {
            self.tuningMatrix = loaded
        } else {
            self.tuningMatrix = CoachTuningMatrix()
            saveTuningMatrix()
        }
        OlympicCoachEngine.shared.tuningMatrix = self.tuningMatrix

        if let data = try? Data(contentsOf: activeSessionURL),
           let loaded = try? JSONDecoder().decode(WorkoutSession.self, from: data) {
            let isAlreadyCompletedInSessions = self.sessions.contains(where: { $0.id == loaded.id })
            let isPlannedAlreadyCompletedInSessions = loaded.plannedWorkoutId.flatMap { pId in
                self.sessions.contains(where: { $0.plannedWorkoutId == pId })
            } ?? false
            let isPlannedAlreadyCompleted = loaded.plannedWorkoutId.flatMap { pId in
                self.plannedWorkouts.first(where: { $0.id == pId })?.isCompleted
            } ?? false

            if !isAlreadyCompletedInSessions && !isPlannedAlreadyCompletedInSessions && !isPlannedAlreadyCompleted && loaded.endTime == nil {
                self.activeSession = loaded
            } else {
                try? FileManager.default.removeItem(at: activeSessionURL)
                self.activeSession = nil
            }
        }

        refreshEcosystemBridgeCache()
        generateGrowDossierDocument()
        syncCloudWorkoutsOverTheAir()
    }

    // MARK: - Over-The-Air Cloud Sync (Firestore & Cloudflare Bridge)
    public func syncCloudWorkoutsOverTheAir() {
        guard let url = URL(string: "https://julian-actually-reproduce-completing.trycloudflare.com/api/workouts") else { return }
        var request = URLRequest(url: url)
        request.timeoutInterval = 4.0

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self, let data = data, error == nil else { return }
            guard let items = try? JSONDecoder().decode([PlannedWorkoutItem].self, from: data), !items.isEmpty else { return }
            DispatchQueue.main.async {
                self.plannedWorkouts = items
                self.savePlannedWorkouts()
            }
        }.resume()
    }

    public func saveTuningMatrix() {
        saveAsync(tuningMatrix, to: coachTuningMatrixURL)
        saveAsync(tuningMatrix, to: documentsDirectory.appendingPathComponent("coach_tuning_matrix.json"))
        OlympicCoachEngine.shared.tuningMatrix = self.tuningMatrix
    }

    private func saveAsync<T: Encodable>(_ object: T, to url: URL) {
        // Atomic immediate write to prevent data loss on app termination
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? enc.encode(object) {
            try? data.write(to: url, options: .atomic)
        }
    }

    public func saveUserPreferences() {
        saveAsync(userPreferences, to: userPreferencesURL)
        generateGrowDossierDocument()
    }

    public func generateGrowDossierDocument() {
        let docs = documentsDirectory
        let exportURL = docs.appendingPathComponent("GROW_ATHLETE_DOSSIER.md")

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "dd.MM.yyyy HH:mm 'Uhr'"
        let dateStr = formatter.string(from: Date())

        let banister = OlympicCoachEngine.shared.calculateBanisterMetrics(sessionsHistory: sessions)
        let readiness = OlympicCoachEngine.shared.calculateBackgroundReadiness(sessionsHistory: sessions)
        let symmetry = OlympicCoachEngine.shared.calculateSkeletalSymmetry(sessionsHistory: sessions)

        var md = """
        # GROW ATHLETEN- & TRAININGS-DOSSIER
        Export-Datum: \(dateStr)
        Nutzer-ID: \(UserAccountService.shared.currentAccount.googleAccountEmail) (\(UserAccountService.shared.currentAccount.username))
        System: Olympic Coach Background Autoregulation Engine

        ## 1. Banister Impuls-Response Stressmodell (ATL / CTL / TSB)
        - Chronische Fitness (CTL / 28-Tage Baseline): \(String(format: "%.1f", banister.chronicTrainingLoadCTL))
        - Akute Ermüdung (ATL / 7-Tage Belastung): \(String(format: "%.1f", banister.acuteTrainingLoadATL))
        - Training Stress Balance (TSB / Formzustand): \(String(format: "%.1f", banister.trainingStressBalanceTSB))
        - Systemischer Readiness-Score: \(String(format: "%.0f %%", readiness.score * 100.0)) (\(readiness.label))
        - Ermüdungs-Klassifikation: \(banister.fatigueStateLabel)
        - Coach-Direktive: \(banister.adaptationRecommendation)

        ## 2. Skelettale & Muskelketten-Symmetrie
        - Oberkörper-Sätze (Woche): \(symmetry.upperBodyWeeklySets)
        - Unterkörper-Sätze (Woche): \(symmetry.lowerBodyWeeklySets)
        - Ober- zu Unterkörper-Verhältnis: \(String(format: "%.2f", symmetry.upperToLowerRatio)):1
        - Push / Pull Verhältnis: \(String(format: "%.2f", symmetry.pushToPullRatio)):1
        - Anterior / Posterior Verhältnis: \(String(format: "%.2f", symmetry.anteriorToPosteriorRatio)):1
        - Struktureller Reibungsindex: \(String(format: "%.2f", symmetry.structuralFrictionIndex))
        - Oberkörper-Dominanz / Dysbalance: \(symmetry.isUpperDominantFrictionDetected ? "JA (Autoregulation aktiv)" : "NEIN (Symmetrisch)")
        - Kinetische Korrektur-Direktive: \(symmetry.biomechanicalCorrectionDirective)

        ## 3. Präferenz-, Divergenz- & Habitus-Muster
        - Bevorzugter Ausrüstungs-Stil: \(userPreferences.preferredEquipmentStyle)
        - Gesamtzahl protokollierter Workouts: \(userPreferences.totalSessionsCount)
        - Spontane Divergenzen ("Zur Sonne"): \(userPreferences.totalDeviationsCount)
        - Top 5 favorisierte Übungen:
        """

        let sortedEx = userPreferences.exerciseSelectionFrequencies.sorted(by: { $0.value > $1.value }).prefix(5)
        for (exName, freq) in sortedEx {
            md += "\n  - \(exName): \(freq) Sätze absolviert"
        }

        md += "\n\n## 4. Aktive 72-Stunden Muskel-Dämpfungen (Schmerz & Auslassungs-Schutz)\n"
        let now = Date()
        var hasActiveDampers = false
        for (muscle, damper) in userPreferences.muscleDistressDampers {
            if let t = userPreferences.muscleDistressTimestamps[muscle], now.timeIntervalSince(t) < 72.0 * 3600.0 {
                let remainingHours = max(0, Int((72.0 * 3600.0 - now.timeIntervalSince(t)) / 3600.0))
                md += "- **\(muscle)**: Dämpfungsfaktor \(String(format: "%.2f", damper)) (-50% Last) | Noch \(remainingHours)h aktiv bis Reset\n"
                hasActiveDampers = true
            }
        }
        if !hasActiveDampers {
            md += "- Keine akuten Muskel-Dämpfungen aktiv. Volle Belastungsfreigabe auf allen Muskelketten.\n"
        }

        md += "\n## 5. Trainings-Historie (Letzte 10 Einheiten)\n"
        md += "| Datum | Workout | Dauer | Tonnage | kcal | RPE | Status |\n"
        md += "| :--- | :--- | :--- | :--- | :--- | :--- | :--- |\n"
        let recent = sessions.prefix(10)
        let df = DateFormatter()
        df.dateFormat = "dd.MM.yy"
        for s in recent {
            let d = df.string(from: s.startTime)
            let dur = "\(s.durationMinutes)m"
            let ton = "\(Int(s.totalTonnageKg)) kg"
            let kc = "\(Int(s.estimatedCaloriesBurned))"
            let rpe = "\(s.perceivedExertionRPE)"
            let status = s.isEarlyTermination ? "Abbruch (\(s.terminationReason ?? "Dienst"))" : "Komplett"
            md += "| \(d) | \(s.title) | \(dur) | \(ton) | \(kc) | \(rpe) | \(status) |\n"
        }

        try? md.write(to: exportURL, atomically: true, encoding: .utf8)
    }

    public func flushAllSync() {
        storageQueue.sync {
            let enc = JSONEncoder()
            enc.outputFormatting = [.prettyPrinted, .sortedKeys]
            if let d = try? enc.encode(self.exercises) { try? d.write(to: self.exercisesURL, options: .atomic) }
            if let d = try? enc.encode(self.templates) { try? d.write(to: self.templatesURL, options: .atomic) }
            if let d = try? enc.encode(self.sessions) { try? d.write(to: self.sessionsURL, options: .atomic) }
            if let d = try? enc.encode(self.measurements) { try? d.write(to: self.measurementsURL, options: .atomic) }
            if let d = try? enc.encode(self.programs) { try? d.write(to: self.programsURL, options: .atomic) }
            if let d = try? enc.encode(self.enrollments) { try? d.write(to: self.enrollmentsURL, options: .atomic) }
            if let d = try? enc.encode(self.benchmarkRegistry) { try? d.write(to: self.benchmarksURL, options: .atomic) }
            if let d = try? enc.encode(self.flowFeedbacks) { try? d.write(to: self.flowFeedbacksURL, options: .atomic) }
            if let d = try? enc.encode(self.dailyNotes) { try? d.write(to: self.dailyNotesURL, options: .atomic) }
            if let d = try? enc.encode(self.plannedWorkouts) { try? d.write(to: self.plannedWorkoutsURL, options: .atomic) }
            if let d = try? enc.encode(self.partialSessions) { try? d.write(to: self.partialSessionsURL, options: .atomic) }
            if let d = try? enc.encode(self.userPreferences) { try? d.write(to: self.userPreferencesURL, options: .atomic) }
            if let d = try? enc.encode(self.activeAdaptiveConstraints) { try? d.write(to: self.constraintsURL, options: .atomic) }
        }
        generateGrowDossierDocument()
    }

    public func switchUserContext() {
        _ = currentUserStorageDirectory
        invalidateSessionCaches()
        _cachedWorkoutDateKeys = nil
        self.sessions = []
        self.measurements = []
        self.templates = []
        self.dailyNotes = [:]
        self.enrollments = []
        self.plannedWorkouts = []
        self.flowFeedbacks = []
        self.partialSessions = []
        self.activeAdaptiveConstraints = [:]
        self.benchmarkRegistry = BenchmarkRegistryState()

        loadData()
        objectWillChange.send()
    }

    public func saveDailyNotes() {
        saveAsync(dailyNotes, to: dailyNotesURL)
    }

    public func savePlannedWorkouts() {
        saveAsync(plannedWorkouts, to: plannedWorkoutsURL)
        syncWorkoutScheduleToBridge()
    }

    private static let sharedDateKeyFormatter: DateFormatter = {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.timeZone = Calendar.current.timeZone
        return fmt
    }()

    public static func dateKey(for date: Date) -> String {
        return sharedDateKeyFormatter.string(from: date)
    }

    public func note(for date: Date) -> String {
        let key = Self.dateKey(for: date)
        return dailyNotes[key] ?? ""
    }

    public func setNote(_ text: String, for date: Date) {
        let key = Self.dateKey(for: date)
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            dailyNotes.removeValue(forKey: key)
        } else {
            dailyNotes[key] = trimmed
        }
        saveDailyNotes()
    }

    public func saveExercises() {
        saveAsync(exercises, to: exercisesURL)
    }

    public func saveTemplates() {
        saveAsync(templates, to: templatesURL)
    }

    public func saveSessions() {
        invalidateSessionCaches()
        refreshEcosystemBridgeCache()
        saveAsync(sessions, to: sessionsURL)
        generateGrowDossierDocument()
        syncWorkoutScheduleToBridge()
    }

    public func syncWorkoutScheduleToBridge() {
        var items: [SharedWorkoutScheduleItem] = []

        // 1. Past & present completed workout sessions
        for session in sessions {
            let names = session.exercises.map { $0.exercise.name }
            let tonnage = session.exercises.reduce(0.0) { sum, ex in
                sum + ex.sets.reduce(0.0) { s, set in s + (set.weightKg * Double(set.reps)) }
            }
            let dur = Int(max(0, (session.endTime ?? Date()).timeIntervalSince(session.startTime)) / 60)
            items.append(SharedWorkoutScheduleItem(
                id: session.id.uuidString,
                title: session.title.isEmpty ? "Workout-Session" : session.title,
                scheduledDate: session.startTime,
                isCompleted: true,
                completedAt: session.endTime,
                exerciseNames: names,
                notes: session.somaticNotes,
                totalTonnageKg: tonnage,
                durationMinutes: dur > 0 ? dur : 45
            ))
        }

        // 2. Future and present planned workouts
        for planned in plannedWorkouts {
            if !items.contains(where: { Calendar.current.isDate($0.scheduledDate, inSameDayAs: planned.plannedDate) && $0.title == planned.title }) {
                items.append(SharedWorkoutScheduleItem(
                    id: planned.id.uuidString,
                    title: planned.title,
                    scheduledDate: planned.plannedDate,
                    isCompleted: planned.isCompleted,
                    completedAt: planned.completedAt,
                    exerciseNames: planned.exerciseNames,
                    notes: planned.notes
                ))
            }
        }

        let ledger = SharedWorkoutScheduleLedger(items: items, lastUpdated: Date())
        GrowSuiteBridge.shared.saveWorkoutScheduleLedger(ledger)
    }

    public func resetOverallAppTonnage() {
        var modified = false
        for sIdx in 0..<sessions.count {
            for eIdx in 0..<sessions[sIdx].exercises.count {
                for setIdx in 0..<sessions[sIdx].exercises[eIdx].sets.count {
                    if sessions[sIdx].exercises[eIdx].sets[setIdx].weightKg != 0.0 {
                        sessions[sIdx].exercises[eIdx].sets[setIdx].weightKg = 0.0
                        modified = true
                    }
                }
            }
        }
        if modified {
            saveSessions()
        }
        invalidateSessionCaches()
        refreshEcosystemBridgeCache()
    }

    public func saveMeasurements() {
        refreshEcosystemBridgeCache()
        saveAsync(measurements, to: measurementsURL)
    }

    public func savePrograms() {
        saveAsync(programs, to: programsURL)
    }

    public func saveEnrollments() {
        saveAsync(enrollments, to: enrollmentsURL)
    }

    public func saveBenchmarks() {
        saveAsync(benchmarkRegistry, to: benchmarksURL)
    }

    public func saveFlowFeedbacks() {
        saveAsync(flowFeedbacks, to: flowFeedbacksURL)
    }

    public func syncExternalData() {
        GrowcerySyncService.shared.refreshData()
        syncWaterFromBridge()
        HapticFeedback.success()
    }

    // MARK: - Exercise Resolver & Catalog Linker
    public func resolveExercise(named name: String) -> Exercise {
        // 1. Exact match
        if let exact = exercises.first(where: { $0.name == name }) {
            return exact
        }
        
        // 2. Stripped parenthetical match
        let cleaned = name.replacingOccurrences(of: "\\s*\\([^)]*\\)", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        
        if let fuzzy = exercises.first(where: {
            let catClean = $0.name.replacingOccurrences(of: "\\s*\\([^)]*\\)", with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
            return catClean == cleaned || $0.name.lowercased() == cleaned || $0.name.lowercased().contains(cleaned) || cleaned.contains(catClean)
        }) {
            return fuzzy
        }
        
        // 3. Heuristic fallback and auto-registration
        let lower = name.lowercased()
        let muscle: MuscleGroup
        if lower.contains("curl-up") || lower.contains("plank") || lower.contains("bird-dog") || lower.contains("deadbug") || lower.contains("rumpf") || lower.contains("core") || lower.contains("pallof") || lower.contains("becken") || lower.contains("hollow body") || lower.contains("toter kaefer") || lower.contains("stir-the-pot") || lower.contains("beckenkippen") {
            muscle = .functionalCore
        } else if lower.contains("squat") || lower.contains("bein") || lower.contains("ausfallschritt") || lower.contains("wade") || lower.contains("step-up") || lower.contains("sissy") {
            muscle = .legs
        } else if lower.contains("glute") || lower.contains("bridge") || lower.contains("hip") || lower.contains("clamshell") || lower.contains("abdukt") || lower.contains("froggers") || lower.contains("piriformis") || lower.contains("hyperextension") {
            muscle = .glutesPosterior
        } else if lower.contains("ruder") || lower.contains("row") || lower.contains("pull-up") || lower.contains("klimm") || lower.contains("lat") || lower.contains("hang") || lower.contains("shrug") {
            muscle = .back
        } else if lower.contains("liegestuetz") || lower.contains("push-up") || lower.contains("brust") || lower.contains("chest") || lower.contains("bankdruecken") || lower.contains("pec") {
            muscle = .chest
        } else if lower.contains("schulter") || lower.contains("seitheben") || lower.contains("face") || lower.contains("scapul") || lower.contains("serratus") || lower.contains("press") || lower.contains("raise") {
            muscle = .shoulders
        } else if lower.contains("curl") || lower.contains("trizeps") || lower.contains("bizeps") || lower.contains("dip") {
            muscle = .arms
        } else if lower.contains("lauf") || lower.contains("sprint") || lower.contains("intervall") || lower.contains("cooper") {
            muscle = .cardioConditioning
        } else {
            muscle = .mobilityFlexibility
        }
        
        let equip: EquipmentType
        if lower.contains("kabel") || lower.contains("seil") || lower.contains("latzug") || lower.contains("tau") {
            equip = .cableCrossoverTower
        } else if lower.contains("kurzhantel") || lower.contains("kh") || lower.contains("dumb") {
            equip = .dumbBells
        } else if lower.contains("langhantel") || lower.contains("sz") || lower.contains("t-bar") {
            equip = .flatBenchBarbell
        } else if lower.contains("stange") || lower.contains("klimmzug") || lower.contains("bar hang") {
            equip = .pullUpBar
        } else if lower.contains("ring") {
            equip = .gymRings
        } else if lower.contains("barren") || lower.contains("dip") {
            equip = .dipStation
        } else if lower.contains("lauf") || lower.contains("run") {
            equip = .outdoorRunning
        } else if lower.contains("stuhl") || lower.contains("tisch") || lower.contains("bett") || lower.contains("tuer") || lower.contains("stube") || lower.contains("wand") || lower.contains("hocker") {
            equip = .roomFurniture
        } else if lower.contains("matte") || lower.contains("stretch") || lower.contains("dehnung") {
            equip = .stretchingMat
        } else {
            equip = .bodyweight
        }
        
        let isReha = !lower.contains("crunch") && !lower.contains("sit-up")
        var newEx = Exercise(
            name: name,
            targetMuscle: muscle,
            equipment: equip,
            isBWKRehaSafe: isReha,
            executionNotes: "Biomedizinisch verifiziertes Protokoll fuer maximale Reha- und Hypertrophie-Konformitaet.",
            defaultSets: 3,
            defaultReps: 10,
            defaultRestSeconds: 75
        )
        ExerciseCatalogSeed.enrichExercise(&newEx)
        exercises.append(newEx)
        saveExercises()
        return newEx
    }

    public func syncWaterFromBridge() {
        let waterPayload = GrowSuiteBridge.shared.loadWater()
        if let idx = measurements.firstIndex(where: { $0.type == .waterIntake && Calendar.current.isDateInToday($0.date) }) {
            if abs(measurements[idx].value - waterPayload.totalWaterMl) < 0.5 {
                return
            }
            measurements[idx].value = waterPayload.totalWaterMl
            saveAsync(measurements, to: measurementsURL)
        } else if waterPayload.totalWaterMl > 0 {
            let entry = BodyMeasurementEntry(
                type: .waterIntake,
                value: waterPayload.totalWaterMl,
                date: Date(),
                note: "Sync aus GrowSuite"
            )
            measurements.insert(entry, at: 0)
            saveAsync(measurements, to: measurementsURL)
        }
    }

    public func logWater(amountMl: Double, date: Date = Date(), sourceApp: String = "Grow") {
        let current = todayWater()
        let newTotal = max(0.0, current + amountMl)
        addMeasurement(type: .waterIntake, value: newTotal, note: "+\(Int(amountMl)) ml (\(sourceApp))")
        GrowSuiteBridge.shared.logWater(amountMl: amountMl, date: date, sourceApp: sourceApp)
    }

    public func resetWater(date: Date = Date(), sourceApp: String = "Grow") {
        addMeasurement(type: .waterIntake, value: 0.0, note: "Reset 0 ml (\(sourceApp))")
        GrowSuiteBridge.shared.resetWater(date: date, sourceApp: sourceApp)
    }

    public func todayWater() -> Double {
        if let existing = measurements.first(where: { $0.type == .waterIntake && Calendar.current.isDateInToday($0.date) }) {
            return existing.value
        }
        let bridgeWater = GrowSuiteBridge.shared.loadWater()
        return bridgeWater.totalWaterMl
    }

    // MARK: - Messungen
    public func addMeasurement(type: MeasurementType, value: Double, date: Date = Date(), note: String = "") {
        let entry = BodyMeasurementEntry(type: type, value: value, date: date, note: note)
        if let idx = measurements.firstIndex(where: { $0.type == type && Calendar.current.isDate($0.date, inSameDayAs: date) }) {
            measurements[idx] = entry
        } else {
            measurements.insert(entry, at: 0)
        }
        saveMeasurements()

        // Bidirektionale Synchronisation mit GrowSuiteBridge
        if type == .waterIntake {
            GrowSuiteBridge.shared.setTotalWater(totalMl: value, sourceApp: "Grow")
        } else if type == .weight {
            DynamicFitnessEngine.shared.recalculate(customWeightKg: value)
        } else if type == .bodyFat {
            DynamicFitnessEngine.shared.recalculate(customFatPct: value)
        }

        HapticFeedback.success()
    }

    public func latestMeasurement(for type: MeasurementType) -> BodyMeasurementEntry? {
        if type == .waterIntake {
            let val = todayWater()
            return BodyMeasurementEntry(type: .waterIntake, value: val, date: Date(), note: "Live Bridge")
        }
        return measurements.first(where: { $0.type == type })
    }

    // MARK: - Circadian Training Profile Analysis
    public struct CircadianTrainingWindow {
        public let preferredHour: Int
        public let slotTitle: String
        public let sessionsCompletedInWindow: Int
        public let totalSessionsTracked: Int
        public let recommendationAdvice: String
    }

    public func analyzeCircadianTrainingPattern() -> CircadianTrainingWindow {
        let completed = sessions.filter { !$0.exercises.isEmpty }
        guard !completed.isEmpty else {
            return CircadianTrainingWindow(
                preferredHour: 19,
                slotTitle: "Abend-Fokus (19:00 - 20:30 Uhr)",
                sessionsCompletedInWindow: 0,
                totalSessionsTracked: 0,
                recommendationAdvice: "Noch keine ausreichende Historie. Standard-Stubenfenster um 19:30 Uhr aktiv."
            )
        }

        var hourBuckets: [Int: Int] = [:]
        for s in completed {
            let hour = Calendar.current.component(.hour, from: s.startTime)
            hourBuckets[hour, default: 0] += 1
        }

        let bestHour = hourBuckets.max(by: { $0.value < $1.value })?.key ?? 19
        let count = hourBuckets[bestHour] ?? 1

        let slotTitle: String
        let advice: String
        switch bestHour {
        case 5...8:
            slotTitle = "Morgen-Fokus (05:30 - 08:00 Uhr)"
            advice = "Hohe sympathikotone Wachheit nach MVPA. Ideal fuer Core-Stabilitaet und Schnellkraft."
        case 11...14:
            slotTitle = "Mittags-Fokus (11:30 - 14:00 Uhr)"
            advice = "Metabolisches Peak-Fenster vor der Truppenkueche."
        case 16...18:
            slotTitle = "Nachmittags-Fokus (16:30 - 18:30 Uhr)"
            advice = "Dienstschluss-Fenster. Koerperkerntemperatur und Muskelkraft auf zirkadianem Tagesmaximum."
        case 19...21:
            slotTitle = "Abend-Fokus (19:00 - 21:00 Uhr)"
            advice = "Stuben-Fokus. Nach Dienstschluss und vor dem Fastenstart. Ideal fuer Calisthenics und Rumpfkontrolle."
        default:
            slotTitle = "Nacht/Sonder-Fenster (\(bestHour):00 Uhr)"
            advice = "Aussergewoehnliches Zeitfenster. Auf ausreichende CPAP-Schlafhygiene achten."
        }

        return CircadianTrainingWindow(
            preferredHour: bestHour,
            slotTitle: slotTitle,
            sessionsCompletedInWindow: count,
            totalSessionsTracked: completed.count,
            recommendationAdvice: advice
        )
    }

    // MARK: - Workout Steuerung
    public func startWorkout(from template: WorkoutTemplate? = nil) {
        if let t = template {
            // Autoregulierte JARVIS-Adaption (Echtzeit-Anpassung bei Spontan-Wahlen & Ermuedung)
            let recommendation = OlympicCoachEngine.shared.generateDailyRecommendation(
                sessionsHistory: allSessionsWithExternal,
                templates: templates,
                growcerySync: GrowcerySyncService.shared.syncState,
                userPreferences: self.userPreferences
            )

            let isDivergence: Bool
            if let recId = recommendation.templateId, let recUUID = UUID(uuidString: recId) {
                isDivergence = (recUUID != t.id)
            } else {
                isDivergence = true
            }

            let adapted = OlympicCoachEngine.shared.adaptSpontaneousSession(
                chosenTemplate: t,
                recommendation: recommendation,
                sessionsHistory: allSessionsWithExternal,
                userPreferences: self.userPreferences,
                exercisesCatalog: self.exercises
            )

            if isDivergence {
                self.userPreferences = OlympicCoachEngine.shared.recordSpontaneousDivergence(
                    chosenTemplate: t,
                    recommendation: recommendation,
                    sessionsHistory: allSessionsWithExternal,
                    currentProfile: self.userPreferences
                )
                self.saveUserPreferences()
            }

            let exerciseRecords: [WorkoutExerciseRecord]
            if t.category.contains("Stube") || t.category.contains("Calisthenics") || t.name.contains("Stuben-Workout") {
                exerciseRecords = t.items.map { item in
                    let isTime = item.exercise.isTimeBased || item.isTimeBased
                    let duration = item.targetSeconds ?? (isTime ? item.targetReps : nil)
                    let setCount = (item.exercise.isUnilateral && item.targetSets % 2 != 0) ? (item.targetSets + 1) : item.targetSets
                    let sets: [WorkoutSetRecord] = (1...setCount).map { idx in
                        let sideStr: String? = item.exercise.isUnilateral ? (idx % 2 == 1 ? "links" : "rechts") : nil
                        return WorkoutSetRecord(
                            setNumber: idx,
                            weightKg: item.targetWeightKg,
                            reps: isTime ? (duration ?? 60) : item.targetReps,
                            durationSeconds: duration,
                            isTimeBased: isTime,
                            isCompleted: false,
                            side: sideStr
                        )
                    }
                    return WorkoutExerciseRecord(
                        exercise: item.exercise,
                        sets: sets,
                        notes: ""
                    )
                }
            } else {
                exerciseRecords = adapted.adaptedExercises.map { item in
                    let isTime = item.exercise.isTimeBased
                    let duration = isTime ? item.prescribedReps : nil
                    let setCount = (item.exercise.isUnilateral && item.prescribedSets % 2 != 0) ? (item.prescribedSets + 1) : item.prescribedSets
                    let sets: [WorkoutSetRecord] = (1...setCount).map { idx in
                        let sideStr: String? = item.exercise.isUnilateral ? (idx % 2 == 1 ? "links" : "rechts") : nil
                        return WorkoutSetRecord(
                            setNumber: idx,
                            weightKg: item.prescribedWeightKg,
                            reps: item.prescribedReps,
                            durationSeconds: duration,
                            isTimeBased: isTime,
                            isCompleted: false,
                            side: sideStr
                        )
                    }
                    return WorkoutExerciseRecord(
                        exercise: item.exercise,
                        sets: sets,
                        notes: item.adaptationReason.isEmpty ? "" : "[JARVIS: \(item.adaptationReason)]"
                    )
                }
            }

            self.activeSession = WorkoutSession(
                templateId: t.id,
                title: t.name,
                startTime: Date(),
                exercises: exerciseRecords,
                somaticNotes: adapted.coachDirectiveExplanation
            )
        } else {
            // Leeres Workout beginnen
            self.activeSession = WorkoutSession(
                title: "Freies Workout",
                startTime: Date(),
                exercises: []
            )
        }
        self.isPresentingActiveWorkout = true
        markSetStarted()
        HapticFeedback.medium()
    }

    public func startSingleExerciseWorkout(exercise: Exercise) {
        let setsCount = max(1, exercise.defaultSets)
        let repsCount = max(1, exercise.defaultReps)

        var suggestedWeight: Double = 0.0
        for pastSession in sessions {
            if let pastRecord = pastSession.exercises.first(where: { $0.exercise.id == exercise.id || $0.exercise.name.caseInsensitiveCompare(exercise.name) == .orderedSame }) {
                if let lastCompleted = pastRecord.sets.last(where: { $0.isCompleted && $0.weightKg > 0 }) {
                    suggestedWeight = lastCompleted.weightKg
                    break
                }
            }
        }

        let sets: [WorkoutSetRecord] = (1...setsCount).map { idx in
            WorkoutSetRecord(
                setNumber: idx,
                weightKg: suggestedWeight,
                reps: repsCount,
                isCompleted: false
            )
        }

        let exerciseRecord = WorkoutExerciseRecord(
            exercise: exercise,
            sets: sets,
            notes: ""
        )

        self.activeSession = WorkoutSession(
            title: exercise.name,
            startTime: Date(),
            exercises: [exerciseRecord],
            somaticNotes: "Einzeluebung: \(exercise.name)"
        )
        self.isPresentingActiveWorkout = true
        markSetStarted()
        HapticFeedback.medium()
    }

    public func startWorkout(from planned: PlannedWorkoutItem) {
        if let tmplId = planned.templateId, let template = templates.first(where: { $0.id == tmplId }) {
            startWorkout(from: template)
            self.activeSession?.plannedWorkoutId = planned.id
            return
        }
        if let template = templates.first(where: { $0.name.caseInsensitiveCompare(planned.title) == .orderedSame }) {
            startWorkout(from: template)
            self.activeSession?.plannedWorkoutId = planned.id
            return
        }
        if let program = programs.first(where: { $0.id == planned.programId }),
           let session = program.allSessions.first(where: { $0.id == planned.sessionId }) {
            startProgramSession(session, in: program)
            self.activeSession?.plannedWorkoutId = planned.id
            return
        }
        var records: [WorkoutExerciseRecord] = []
        if !planned.exerciseNames.isEmpty {
            records = planned.exerciseNames.compactMap { name in
                let ex: Exercise? = {
                    if let exact = exercises.first(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) {
                        return exact
                    }
                    let norm = ExerciseSearchEngine.normalize(name)
                    if let normMatch = exercises.first(where: { ExerciseSearchEngine.normalize($0.name) == norm }) {
                        return normMatch
                    }
                    if let searchMatch = ExerciseSearchEngine.shared.search(query: name, in: exercises, store: self).first {
                        return searchMatch
                    }
                    let tokens = name.components(separatedBy: CharacterSet.alphanumerics.inverted)
                        .filter { $0.count >= 4 }
                    for token in tokens {
                        let tokenNorm = ExerciseSearchEngine.normalize(token)
                        if let tokenMatch = exercises.first(where: { ExerciseSearchEngine.normalize($0.name).contains(tokenNorm) }) {
                            return tokenMatch
                        }
                    }
                    return nil
                }()

                if let ex = ex {
                    let setCount = ex.isUnilateral ? 4 : 3
                    let sets = (1...setCount).map { idx in
                        let sideStr: String? = ex.isUnilateral ? (idx % 2 == 1 ? "links" : "rechts") : nil
                        let prev = previousPerformance(for: ex.name, setIndex: idx - 1)
                        let defaultWeight = prev?.weightKg ?? 0.0
                        let defaultReps = prev?.reps ?? (ex.defaultReps > 0 ? ex.defaultReps : 10)
                        return WorkoutSetRecord(
                            setNumber: idx,
                            weightKg: defaultWeight,
                            reps: defaultReps,
                            isTimeBased: ex.isTimeBased,
                            isCompleted: false,
                            side: sideStr
                        )
                    }
                    return WorkoutExerciseRecord(exercise: ex, sets: sets)
                }
                return nil
            }
        }
        self.activeSession = WorkoutSession(
            plannedWorkoutId: planned.id,
            title: planned.title,
            startTime: Date(),
            exercises: records
        )
        self.isPresentingActiveWorkout = true
        HapticFeedback.medium()
    }

    public func toggleSuperset(for exerciseRecordId: UUID) {
        guard var session = activeSession else { return }
        guard let idx = session.exercises.firstIndex(where: { $0.id == exerciseRecordId }) else { return }

        if let currentGroup = session.exercises[idx].supersetGroupId {
            session.exercises[idx].supersetGroupId = nil
            let remaining = session.exercises.filter { $0.supersetGroupId == currentGroup }
            if remaining.count <= 1 {
                for rIdx in session.exercises.indices where session.exercises[rIdx].supersetGroupId == currentGroup {
                    session.exercises[rIdx].supersetGroupId = nil
                }
            }
        } else {
            var targetGroup: String? = nil
            if idx > 0, let prevGroup = session.exercises[idx - 1].supersetGroupId {
                targetGroup = prevGroup
            } else if idx + 1 < session.exercises.count, let nextGroup = session.exercises[idx + 1].supersetGroupId {
                targetGroup = nextGroup
            } else {
                let existingGroups = Set(session.exercises.compactMap { $0.supersetGroupId })
                for letter in ["A", "B", "C", "D", "E"] {
                    if !existingGroups.contains(letter) {
                        targetGroup = letter
                        break
                    }
                }
                if targetGroup == nil { targetGroup = "A" }
                if idx > 0 && session.exercises[idx - 1].supersetGroupId == nil {
                    session.exercises[idx - 1].supersetGroupId = targetGroup
                } else if idx + 1 < session.exercises.count && session.exercises[idx + 1].supersetGroupId == nil {
                    session.exercises[idx + 1].supersetGroupId = targetGroup
                }
            }
            session.exercises[idx].supersetGroupId = targetGroup
        }
        self.activeSession = session
        HapticFeedback.light()
    }

    // MARK: - Previous Performance & Historical 1RM Lookups (LiftLog & openGym Standard)

    /// Retrieves the completed performance of the exact same set index from the most recent previous session of this exercise.
    public func previousPerformance(for exerciseName: String, setIndex: Int) -> (weightKg: Double, reps: Int)? {
        let trimmedTarget = exerciseName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        for session in sessions {
            if let exRecord = session.exercises.first(where: {
                $0.exercise.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == trimmedTarget
            }) {
                let completedSets = exRecord.sets.filter { $0.isCompleted }
                if setIndex < completedSets.count {
                    let set = completedSets[setIndex]
                    if set.weightKg > 0 || set.reps > 0 {
                        return (set.weightKg, set.reps)
                    }
                } else if let lastSet = completedSets.last, lastSet.weightKg > 0 || lastSet.reps > 0 {
                    return (lastSet.weightKg, lastSet.reps)
                }
            }
        }
        return nil
    }

    /// Computes the historical personal record (PR) estimated 1RM for an exercise across all past completed sessions.
    public func historicalMax1RM(for exerciseName: String) -> Double {
        let trimmedTarget = exerciseName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        var max1RM: Double = 0.0
        for session in sessions {
            for ex in session.exercises where ex.exercise.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == trimmedTarget {
                for s in ex.sets where s.isCompleted && s.weightKg > 0 && s.reps > 0 {
                    let e1RM = s.estimated1RM
                    if e1RM > max1RM {
                        max1RM = e1RM
                    }
                }
            }
        }
        return max1RM
    }

    /// Autofills weight and reps from previous performance for a set.
    public func autofillSetFromPrevious(exerciseId: UUID, setId: UUID, weightKg: Double, reps: Int) {
        guard var session = activeSession else { return }
        if let exIndex = session.exercises.firstIndex(where: { $0.id == exerciseId }),
           let setIndex = session.exercises[exIndex].sets.firstIndex(where: { $0.id == setId }) {
            session.exercises[exIndex].sets[setIndex].weightKg = weightKg
            session.exercises[exIndex].sets[setIndex].reps = reps
            self.activeSession = session
            HapticFeedback.light()
        }
    }

    public func toggleSet(exerciseId: UUID, setId: UUID) {
        guard var session = activeSession else { return }

        if let exIndex = session.exercises.firstIndex(where: { $0.id == exerciseId }) {
            if let setIndex = session.exercises[exIndex].sets.firstIndex(where: { $0.id == setId }) {
                session.exercises[exIndex].sets[setIndex].isCompleted.toggle()
                let completed = session.exercises[exIndex].sets[setIndex].isCompleted

                if completed {
                    let now = Date()
                    session.exercises[exIndex].sets[setIndex].timestamp = now

                    // Satz-Dauer (Execution Duration) erfassen
                    if session.exercises[exIndex].sets[setIndex].executionDurationSeconds == nil {
                        let startTime = self.activeSetStartTime ?? session.startTime
                        let elapsed = Int(now.timeIntervalSince(startTime))
                        if elapsed >= 2 && elapsed <= 600 {
                            session.exercises[exIndex].sets[setIndex].executionDurationSeconds = elapsed
                        }
                    }

                    // Append-Only SQLite WAL Persistence (WCDB / SQLite WAL Pattern)
                    let finishedSet = session.exercises[exIndex].sets[setIndex]
                    let sessionIdStr = session.id.uuidString
                    let exTitle = session.exercises[exIndex].exercise.name
                    let setIdxNum = Int32(setIndex + 1)
                    let weightVal = finishedSet.weightKg
                    let repsVal = Int32(finishedSet.reps)
                    let rpeVal = finishedSet.rpe ?? 8.0
                    let isWarmupVal = finishedSet.isWarmup ? Int32(1) : Int32(0)

                    GrowMMKV.shared.set(Double(repsVal), forKey: "grow_last_reps_\(exTitle)")

                    GrowDatabase.shared.performAsync { db in
                        guard let db = db else { return }
                        var stmt: OpaquePointer?
                        let sql = "INSERT OR REPLACE INTO workout_sets (id, workout_id, exercise_name, set_index, weight_kg, reps, rpe, is_warmup) VALUES (?, ?, ?, ?, ?, ?, ?, ?);"
                        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
                            sqlite3_bind_text(stmt, 1, (setId.uuidString as NSString).utf8String, -1, nil)
                            sqlite3_bind_text(stmt, 2, (sessionIdStr as NSString).utf8String, -1, nil)
                            sqlite3_bind_text(stmt, 3, (exTitle as NSString).utf8String, -1, nil)
                            sqlite3_bind_int(stmt, 4, setIdxNum)
                            sqlite3_bind_double(stmt, 5, weightVal)
                            sqlite3_bind_int(stmt, 6, repsVal)
                            sqlite3_bind_double(stmt, 7, rpeVal)
                            sqlite3_bind_int(stmt, 8, isWarmupVal)
                            sqlite3_step(stmt)
                        }
                        sqlite3_finalize(stmt)
                    }

                    // Evaluate if this set establishes a new estimated 1RM Personal Record (PR)
                    let currentSet = session.exercises[exIndex].sets[setIndex]
                    let current1RM = currentSet.estimated1RM
                    let exName = session.exercises[exIndex].exercise.name
                    let histMax = historicalMax1RM(for: exName)
                    let sessionMax = session.exercises[exIndex].sets
                        .filter { $0.id != setId && $0.isCompleted }
                        .map { $0.estimated1RM }
                        .max() ?? 0.0
                    let prThreshold = max(histMax, sessionMax)

                    if current1RM > prThreshold && prThreshold > 0.0 && currentSet.weightKg > 0 {
                        session.exercises[exIndex].sets[setIndex].isPR = true
                        HapticFeedback.success()
                    } else {
                        session.exercises[exIndex].sets[setIndex].isPR = false
                        HapticFeedback.success()
                    }

                    // Superset-Wechsel-Timer: Automatische Umschaltung des Fokus auf Uebung B mit angepasster 30s-Transition-Pause
                    let exRecord = session.exercises[exIndex]
                    if let groupId = exRecord.supersetGroupId,
                       let partnerIndex = session.exercises.firstIndex(where: { $0.id != exRecord.id && $0.supersetGroupId == groupId }) {
                        let partner = session.exercises[partnerIndex]
                        self.activeSupersetTargetExerciseId = partner.id
                        startRestTimer(seconds: 30, supersetTargetExerciseName: partner.exercise.name)
                    } else {
                        self.activeSupersetTargetExerciseId = nil
                        startRestTimer(seconds: session.exercises[exIndex].exercise.dynamicRestSeconds)
                    }
                } else {
                    session.exercises[exIndex].sets[setIndex].isPR = false
                    session.exercises[exIndex].sets[setIndex].executionDurationSeconds = nil
                    HapticFeedback.light()
                }
            }
        }
        self.activeSession = session
    }

    // MARK: - Warmup-Engine (Automatische Aufwaermsatz-Generierung)
    public func autoGenerateWarmupSets(for exerciseId: UUID) {
        guard var session = activeSession else { return }
        guard let exIndex = session.exercises.firstIndex(where: { $0.id == exerciseId }) else { return }

        // Finde den ersten Arbeitssatz (nicht-Warmup Satz mit Gewicht > 0)
        let workingSets = session.exercises[exIndex].sets.filter { !$0.isWarmup }
        let baseWeight = workingSets.first?.weightKg ?? 60.0

        // Entferne vorherige Warmup-Saetze
        session.exercises[exIndex].sets.removeAll(where: { $0.isWarmup })

        func roundPlate(_ val: Double) -> Double {
            max(20.0, (val / 2.5).rounded() * 2.5)
        }

        var warmups: [WorkoutSetRecord] = []
        if baseWeight > 20.0 {
            // W1: Stange (20 kg) x 10
            warmups.append(WorkoutSetRecord(setNumber: 1, weightKg: 20.0, reps: 10, isWarmup: true))
            if baseWeight >= 50.0 {
                // W2: 50% x 5
                warmups.append(WorkoutSetRecord(setNumber: 2, weightKg: roundPlate(baseWeight * 0.50), reps: 5, isWarmup: true))
            }
            if baseWeight >= 70.0 {
                // W3: 70% x 3
                warmups.append(WorkoutSetRecord(setNumber: 3, weightKg: roundPlate(baseWeight * 0.70), reps: 3, isWarmup: true))
            }
            if baseWeight >= 90.0 {
                // W4: 85% x 1
                warmups.append(WorkoutSetRecord(setNumber: 4, weightKg: roundPlate(baseWeight * 0.85), reps: 1, isWarmup: true))
            }
        }

        let existingWorking = session.exercises[exIndex].sets
        var reindexed: [WorkoutSetRecord] = []
        for (idx, ws) in existingWorking.enumerated() {
            var copy = ws
            copy.setNumber = idx + 1
            reindexed.append(copy)
        }

        session.exercises[exIndex].sets = warmups + reindexed
        self.activeSession = session
        HapticFeedback.success()
    }

    public func updateSetRPE(exerciseId: UUID, setId: UUID, rpe: Double?) {
        guard var session = activeSession else { return }
        if let exIndex = session.exercises.firstIndex(where: { $0.id == exerciseId }) {
            if let setIndex = session.exercises[exIndex].sets.firstIndex(where: { $0.id == setId }) {
                session.exercises[exIndex].sets[setIndex].rpe = rpe
            }
        }
        self.activeSession = session
        HapticFeedback.light()
    }

    public func updateSetSide(exerciseId: UUID, setId: UUID, side: String?) {
        guard var session = activeSession else { return }
        if let exIndex = session.exercises.firstIndex(where: { $0.id == exerciseId }) {
            if let setIndex = session.exercises[exIndex].sets.firstIndex(where: { $0.id == setId }) {
                session.exercises[exIndex].sets[setIndex].side = side
            }
        }
        self.activeSession = session
        HapticFeedback.light()
    }

    public func updateSetWeight(exerciseId: UUID, setId: UUID, weight: Double) {
        guard var session = activeSession else { return }
        if let exIndex = session.exercises.firstIndex(where: { $0.id == exerciseId }) {
            if let setIndex = session.exercises[exIndex].sets.firstIndex(where: { $0.id == setId }) {
                session.exercises[exIndex].sets[setIndex].weightKg = max(0, weight)
            }
        }
        self.activeSession = session
    }

    public func updateSetReps(exerciseId: UUID, setId: UUID, reps: Int) {
        guard var session = activeSession else { return }
        if let exIndex = session.exercises.firstIndex(where: { $0.id == exerciseId }) {
            if let setIndex = session.exercises[exIndex].sets.firstIndex(where: { $0.id == setId }) {
                session.exercises[exIndex].sets[setIndex].reps = max(0, reps)
            }
        }
        self.activeSession = session
    }

    public func updateSet(exerciseId: UUID, setId: UUID, weightKg: Double, reps: Int) {
        guard var session = activeSession else { return }
        if let exIndex = session.exercises.firstIndex(where: { $0.id == exerciseId }) {
            if let setIndex = session.exercises[exIndex].sets.firstIndex(where: { $0.id == setId }) {
                session.exercises[exIndex].sets[setIndex].weightKg = max(0, weightKg)
                session.exercises[exIndex].sets[setIndex].reps = max(0, reps)
            }
        }
        self.activeSession = session
    }

    public func addExerciseToActiveWorkout(_ exercise: Exercise) {
        guard var session = activeSession else { return }
        // Hard-block contraindicated exercises (Crunches / Sit-ups according to BWK Ulm Reha guidelines)
        if exercise.isBWKContraindicated {
            HapticFeedback.error()
            return
        }
        let isTime = exercise.isTimeBased
        let defDuration = isTime ? 60 : nil
        let initialSets = (1...exercise.defaultSets).map { idx in
            if let prev = previousPerformance(for: exercise.name, setIndex: idx - 1) {
                return WorkoutSetRecord(
                    setNumber: idx,
                    weightKg: prev.weightKg,
                    reps: prev.reps,
                    durationSeconds: defDuration,
                    isTimeBased: isTime
                )
            } else {
                return WorkoutSetRecord(
                    setNumber: idx,
                    weightKg: 0.0,
                    reps: exercise.defaultReps,
                    durationSeconds: defDuration,
                    isTimeBased: isTime
                )
            }
        }
        let record = WorkoutExerciseRecord(exercise: exercise, sets: initialSets)
        session.exercises.append(record)
        self.activeSession = session
        HapticFeedback.light()
    }

    public func addSet(to exerciseId: UUID) {
        guard var session = activeSession else { return }
        if let exIndex = session.exercises.firstIndex(where: { $0.id == exerciseId }) {
            let nextNum = session.exercises[exIndex].sets.count + 1
            let lastSet = session.exercises[exIndex].sets.last
            let prev = previousPerformance(for: session.exercises[exIndex].exercise.name, setIndex: nextNum - 1)
            let defaultWeight = lastSet?.weightKg ?? prev?.weightKg ?? 0.0
            let defaultReps = lastSet?.reps ?? prev?.reps ?? 10
            let isTime = session.exercises[exIndex].exercise.isTimeBased || (lastSet?.isTimeBased ?? false)
            let defDuration = lastSet?.durationSeconds ?? (isTime ? 60 : nil)
            let newSet = WorkoutSetRecord(
                setNumber: nextNum,
                weightKg: defaultWeight,
                reps: defaultReps,
                durationSeconds: defDuration,
                isTimeBased: isTime,
                isCompleted: false
            )
            session.exercises[exIndex].sets.append(newSet)
            self.activeSession = session
            HapticFeedback.light()
        }
    }

    public func updateSetDuration(exerciseId: UUID, setId: UUID, seconds: Int) {
        guard var session = activeSession else { return }
        if let exIndex = session.exercises.firstIndex(where: { $0.id == exerciseId }) {
            if let setIndex = session.exercises[exIndex].sets.firstIndex(where: { $0.id == setId }) {
                session.exercises[exIndex].sets[setIndex].durationSeconds = max(0, seconds)
                session.exercises[exIndex].sets[setIndex].executionDurationSeconds = max(0, seconds)
                session.exercises[exIndex].sets[setIndex].isTimeBased = true
            }
        }
        self.activeSession = session
    }

    public func toggleSetIsTimeBased(exerciseId: UUID, setId: UUID) {
        guard var session = activeSession else { return }
        if let exIndex = session.exercises.firstIndex(where: { $0.id == exerciseId }) {
            if let setIndex = session.exercises[exIndex].sets.firstIndex(where: { $0.id == setId }) {
                session.exercises[exIndex].sets[setIndex].isTimeBased.toggle()
                if session.exercises[exIndex].sets[setIndex].isTimeBased && (session.exercises[exIndex].sets[setIndex].durationSeconds == nil || session.exercises[exIndex].sets[setIndex].durationSeconds == 0) {
                    session.exercises[exIndex].sets[setIndex].durationSeconds = 60
                }
            }
        }
        self.activeSession = session
    }

    public func deleteSet(exerciseId: UUID, setId: UUID) {
        guard var session = activeSession else { return }
        if let exIndex = session.exercises.firstIndex(where: { $0.id == exerciseId }) {
            session.exercises[exIndex].sets.removeAll(where: { $0.id == setId })
            for (idx, _) in session.exercises[exIndex].sets.enumerated() {
                session.exercises[exIndex].sets[idx].setNumber = idx + 1
            }
            self.activeSession = session
            HapticFeedback.soft()
        }
    }

    public func removeExerciseFromActiveWorkout(exerciseId: UUID) {
        guard var session = activeSession else { return }
        session.exercises.removeAll(where: { $0.id == exerciseId })
        self.activeSession = session
        HapticFeedback.soft()
    }

    // MARK: - Rest Timer Delegation
    public func startRestTimer(seconds: Int, supersetTargetExerciseName: String? = nil) {
        WorkoutRestTimerManager.shared.start(seconds: seconds, supersetTargetExerciseName: supersetTargetExerciseName)
    }

    public func adjustRestTimer(deltaSeconds: Int) {
        WorkoutRestTimerManager.shared.adjust(deltaSeconds: deltaSeconds)
    }

    public func stopRestTimer(playBell: Bool = false) {
        WorkoutRestTimerManager.shared.stop(playBell: playBell)
    }

    // MARK: - Workout Beenden
    public func finishWorkout(rpe: Int, notes: String) async {
        guard var session = activeSession else { return }
        stopRestTimer()

        let now = Date()
        session.endTime = now
        if session.isPaused, let lastPause = session.lastPauseTime {
            session.pausedIntervals += now.timeIntervalSince(lastPause)
            session.isPaused = false
            session.lastPauseTime = nil
        }
        session.perceivedExertionRPE = rpe
        session.somaticNotes = notes

        let durationMinutes = Double(session.durationMinutes)
        let tonnageKilo = session.totalTonnageKg / 1000.0
        let estimatedKcal = max(50.0, (durationMinutes * 5.5) + (tonnageKilo * 20.0))
        session.estimatedCaloriesBurned = estimatedKcal

        // Poka-Yoke: Auto-fill baseline RPE (7.5) for completed sets left unrated to preserve physiological models
        for exIdx in session.exercises.indices {
            for setIdx in session.exercises[exIdx].sets.indices {
                if session.exercises[exIdx].sets[setIdx].isCompleted && session.exercises[exIdx].sets[setIdx].rpe == nil {
                    session.exercises[exIdx].sets[setIdx].rpe = 7.5
                }
            }
        }

        // Archivieren
        self.sessions.insert(session, at: 0)
        self.saveSessions()

        // JARVIS: Praeferenzen und Trainingsmuster im Hintergrund lernen
        self.userPreferences = OlympicCoachEngine.shared.recordCompletedSession(
            session: session,
            currentProfile: self.userPreferences
        )
        self.saveUserPreferences()

        // Bidirektionale Synchronisation an Growcery (NutriVault)
        let musclesHit = Array(Set(session.exercises.map { $0.exercise.targetMuscle.rawValue }))
        let isReha = session.exercises.contains(where: { $0.exercise.targetMuscle == .functionalCore })
        let workoutPayload = SharedWorkoutPayload(
            workoutId: session.id.uuidString,
            title: session.title,
            completionDate: session.endTime ?? Date(),
            durationMinutes: session.durationMinutes,
            totalTonnageKg: session.totalTonnageKg,
            caloriesBurned: estimatedKcal,
            perceivedExertionRPE: session.perceivedExertionRPE,
            muscleGroupsHit: musclesHit,
            isBWKReha: isReha
        )
        GrowSuiteBridge.shared.saveWorkout(workoutPayload)

        // 2-Wege Synchronisation nach Apple Health & Google Kalender (Outbound)
        let hkSuccess = await HealthKitService.shared.saveWorkout(session: session)
        if hkSuccess {
            if let idx = self.sessions.firstIndex(where: { $0.id == session.id }) {
                self.sessions[idx].isSyncedToHealthKit = true
                self.saveSessions()
            }
        }

        if let calId = await CalendarSyncService.shared.syncCompletedSession(session: session) {
            if let idx = self.sessions.firstIndex(where: { $0.id == session.id }) {
                self.sessions[idx].calendarEventId = calId
                self.sessions[idx].isSyncedToCalendar = true
                self.saveSessions()
            }
        }

        // 3. Automatischer Google Tasks Check-off: Liste "Gesundheit"
        await GoogleTasksSyncService.shared.checkOffWorkoutTask(sessionTitle: session.title)

        // Zugehoerige geplante Einheit als erledigt markieren
        if let plannedId = session.plannedWorkoutId,
           let pIdx = self.plannedWorkouts.firstIndex(where: { $0.id == plannedId }) {
            self.plannedWorkouts[pIdx].isCompleted = true
            self.plannedWorkouts[pIdx].completedAt = session.endTime
            self.savePlannedWorkouts()
        } else if let pIdx = self.plannedWorkouts.firstIndex(where: {
            Calendar.current.isDate($0.plannedDate, inSameDayAs: session.startTime) &&
            !$0.isCompleted &&
            $0.title.caseInsensitiveCompare(session.title) == .orderedSame
        }) {
            self.plannedWorkouts[pIdx].isCompleted = true
            self.plannedWorkouts[pIdx].completedAt = session.endTime
            self.savePlannedWorkouts()
        }

        // Benchmarks automatisch ableiten und in BenchmarkRegistry eintragen
        for exRecord in session.exercises {
            let completed = exRecord.sets.filter { $0.isCompleted && $0.reps > 0 }
            guard !completed.isEmpty else { continue }

            // 1. Wenn mit Gewicht: Berechne bestes 1RM nach praeziser Brzycki / Epley Formel
            let weightedSets = completed.filter { $0.weightKg > 0 }
            if let bestWeighted = weightedSets.max(by: { a, b in
                OneRepMaxFormula.calculateAccurate1RM(weightKg: a.weightKg, reps: a.reps, rpe: a.rpe) <
                OneRepMaxFormula.calculateAccurate1RM(weightKg: b.weightKg, reps: b.reps, rpe: b.rpe)
            }) {
                let estimated1RM = OneRepMaxFormula.calculateAccurate1RM(weightKg: bestWeighted.weightKg, reps: bestWeighted.reps, rpe: bestWeighted.rpe)
                self.recordBenchmark(
                    metricType: .estimated1RM,
                    exerciseKey: exRecord.exercise.name,
                    value: (estimated1RM * 10).rounded() / 10,
                    unit: "kg",
                    sourceProgram: session.title
                )
            }

            // 2. Maximalwiederholungen fuer Bodyweight / Calisthenics
            if let maxRepsSet = completed.max(by: { $0.reps < $1.reps }) {
                if exRecord.exercise.equipment == .bodyweight || maxRepsSet.weightKg == 0 {
                    self.recordBenchmark(
                        metricType: .bodyweightMaxReps,
                        exerciseKey: exRecord.exercise.name,
                        value: Double(maxRepsSet.reps),
                        unit: "Wdh",
                        sourceProgram: session.title
                    )
                }
            }
        }

        self.activeSession = nil

        HapticFeedback.success()
        GrowcerySyncService.shared.refreshData()
    }

    // MARK: - 1-Tap Exit-Skalar Abschluss (Verbesserung 2)
    public func finishWorkoutWithScalar(exitCode: Int) async {
        guard var session = activeSession else { return }
        stopRestTimer()
        let now = Date()
        session.endTime = now
        if session.isPaused, let lastPause = session.lastPauseTime {
            session.pausedIntervals += now.timeIntervalSince(lastPause)
            session.isPaused = false
            session.lastPauseTime = nil
        }
        session.isEarlyTermination = (exitCode != 0)
        session.terminationReason = {
            switch exitCode {
            case 1: return "Dienstlicher Abbruch / Zeitnot"
            case 2: return "Systemische Erschoepfung"
            case 3: return "Lokaler Schmerz / Gelenk"
            default: return "Planmaessig beendet"
            }
        }()

        let durationMinutes = Double(session.durationMinutes)
        let tonnageKilo = session.totalTonnageKg / 1000.0
        let estimatedKcal = max(50.0, (durationMinutes * 5.5) + (tonnageKilo * 20.0))
        session.estimatedCaloriesBurned = estimatedKcal

        // Poka-Yoke: Auto-fill baseline RPE (7.5) for completed sets left unrated
        for exIdx in session.exercises.indices {
            for setIdx in session.exercises[exIdx].sets.indices {
                if session.exercises[exIdx].sets[setIdx].isCompleted && session.exercises[exIdx].sets[setIdx].rpe == nil {
                    session.exercises[exIdx].sets[setIdx].rpe = 7.5
                }
            }
        }

        self.sessions.insert(session, at: 0)
        self.saveSessions()

        // 1-Tap Exit-Skalar mathematische Auswertung
        let eval = OlympicCoachEngine.shared.evaluateExitScalar(
            exitCode: exitCode,
            session: session,
            currentProfile: self.userPreferences
        )
        self.userPreferences = eval.updatedProfile
        self.saveUserPreferences()

        // Bidirektionale Synchronisation an Growcery (NutriVault)
        let musclesHit = Array(Set(session.exercises.map { $0.exercise.targetMuscle.rawValue }))
        let isReha = session.exercises.contains(where: { $0.exercise.targetMuscle == .functionalCore })
        let workoutPayload = SharedWorkoutPayload(
            workoutId: session.id.uuidString,
            title: session.title,
            completionDate: session.endTime ?? Date(),
            durationMinutes: session.durationMinutes,
            totalTonnageKg: session.totalTonnageKg,
            caloriesBurned: estimatedKcal,
            perceivedExertionRPE: session.perceivedExertionRPE,
            muscleGroupsHit: musclesHit,
            isBWKReha: isReha
        )
        GrowSuiteBridge.shared.saveWorkout(workoutPayload)

        // Apple Health & Google Kalender Synchronisation
        let hkSuccess = await HealthKitService.shared.saveWorkout(session: session)
        if hkSuccess {
            if let idx = self.sessions.firstIndex(where: { $0.id == session.id }) {
                self.sessions[idx].isSyncedToHealthKit = true
                self.saveSessions()
            }
        }

        if let calId = await CalendarSyncService.shared.syncCompletedSession(session: session) {
            if let idx = self.sessions.firstIndex(where: { $0.id == session.id }) {
                self.sessions[idx].calendarEventId = calId
                self.sessions[idx].isSyncedToCalendar = true
                self.saveSessions()
            }
        }

        await GoogleTasksSyncService.shared.checkOffWorkoutTask(sessionTitle: session.title)

        // Zugehoerige geplante Einheit als erledigt markieren
        if let plannedId = session.plannedWorkoutId,
           let pIdx = self.plannedWorkouts.firstIndex(where: { $0.id == plannedId }) {
            self.plannedWorkouts[pIdx].isCompleted = true
            self.plannedWorkouts[pIdx].completedAt = session.endTime
            self.savePlannedWorkouts()
        } else if let pIdx = self.plannedWorkouts.firstIndex(where: {
            Calendar.current.isDate($0.plannedDate, inSameDayAs: session.startTime) &&
            !$0.isCompleted &&
            $0.title.caseInsensitiveCompare(session.title) == .orderedSame
        }) {
            self.plannedWorkouts[pIdx].isCompleted = true
            self.plannedWorkouts[pIdx].completedAt = session.endTime
            self.savePlannedWorkouts()
        }

        // Benchmarks ableiten
        for exRecord in session.exercises {
            let completed = exRecord.sets.filter { $0.isCompleted && $0.reps > 0 }
            guard !completed.isEmpty else { continue }

            let weightedSets = completed.filter { $0.weightKg > 0 }
            if let bestWeighted = weightedSets.max(by: { a, b in
                OneRepMaxFormula.calculateAccurate1RM(weightKg: a.weightKg, reps: a.reps, rpe: a.rpe) <
                OneRepMaxFormula.calculateAccurate1RM(weightKg: b.weightKg, reps: b.reps, rpe: b.rpe)
            }) {
                let estimated1RM = OneRepMaxFormula.calculateAccurate1RM(weightKg: bestWeighted.weightKg, reps: bestWeighted.reps, rpe: bestWeighted.rpe)
                self.recordBenchmark(
                    metricType: .estimated1RM,
                    exerciseKey: exRecord.exercise.name,
                    value: (estimated1RM * 10).rounded() / 10,
                    unit: "kg",
                    sourceProgram: session.title
                )
            }

            if let maxRepsSet = completed.max(by: { $0.reps < $1.reps }) {
                if exRecord.exercise.equipment == .bodyweight || maxRepsSet.weightKg == 0 {
                    self.recordBenchmark(
                        metricType: .bodyweightMaxReps,
                        exerciseKey: exRecord.exercise.name,
                        value: Double(maxRepsSet.reps),
                        unit: "Wdh",
                        sourceProgram: session.title
                    )
                }
            }
        }

        self.activeSession = nil
        HapticFeedback.success()
        GrowcerySyncService.shared.refreshData()
    }

    public func cancelWorkout() {
        stopRestTimer()
        if var session = self.activeSession {
            session.endTime = Date()
            session.isEarlyTermination = true
            session.terminationReason = "Workout vorzeitig abgebrochen (Zero-Touch)"

            // Zero-Touch Auto-Deduction (Verbesserung 2):
            // Berechnet C_Gruppe = Saetze abgeschlossen / Saetze geplant.
            // Falls C_Gruppe == 0,0 fuer eine geplante Muskelgruppe, wird die 72h-Daempfung ohne Rueckfrage geschaltet.
            var profile = self.userPreferences
            let omissionMult = tuningMatrix.dampers.omission_damper_multiplier
            let now = session.endTime ?? Date()
            let durationSeconds = now.timeIntervalSince(session.startTime)
            let totalCompletedSets = session.exercises.flatMap { $0.sets }.filter { $0.isCompleted }.count

            // Nur Daempfer berechnen, wenn das Workout nicht versehentlich gestartet und direkt verworfen wurde
            if durationSeconds >= 180 || totalCompletedSets > 0 {
                for item in session.exercises {
                    let plannedSets = item.sets.count
                    let completedSets = item.sets.filter { $0.isCompleted }.count
                    let muscle = item.exercise.targetMuscle.rawValue

                    if plannedSets > 0 && completedSets == 0 {
                        profile.muscleDistressDampers[muscle] = omissionMult
                        profile.muscleDistressTimestamps[muscle] = now
                    }
                }
            }

            self.userPreferences = OlympicCoachEngine.shared.recordCompletedSession(
                session: session,
                currentProfile: profile
            )
            self.saveUserPreferences()
        }
        self.activeSession = nil
        HapticFeedback.light()
    }

    public func abortAndDebriefWorkout(debriefRecord: WorkoutDebriefRecord) async {
        guard var session = activeSession else { return }
        stopRestTimer()
        session.endTime = Date()
        session.perceivedExertionRPE = debriefRecord.perceivedExertionRPE
        session.somaticNotes = debriefRecord.notes.isEmpty ? debriefRecord.coachResult.diagnoseText : "\(debriefRecord.notes) [Debrief: \(debriefRecord.coachResult.scenarioBadge)]"
        session.isEarlyTermination = true
        session.terminationReason = debriefRecord.primaryReason.rawValue
        session.debriefRecord = debriefRecord

        sessions.append(session)
        saveSessions()

        GrowTelemetryService.shared.logLogicViolation(
            appName: "Grow",
            category: .athleticStrain,
            title: "Workout vorzeitig beendet",
            detail: "Session '\(session.title)' vorzeitig abgebrochen (RPE: \(debriefRecord.perceivedExertionRPE), Abbruch-Szenario: \(debriefRecord.coachResult.scenarioBadge)).",
            metadata: ["session": session.title, "reason": debriefRecord.primaryReason.rawValue, "rpe": "\(debriefRecord.perceivedExertionRPE)"]
        )

        var dropoutReason: OlympicCoachEngine.DropoutReason = .acuteExhaustion
        switch debriefRecord.primaryReason {
        case .pacingOverreach, .lacticBurnout:
            dropoutReason = .acuteExhaustion
        case .administrativeDuty:
            dropoutReason = .timeConstraint
        case .orthopedicVisceralPain:
            dropoutReason = .orthopedicVisceral
        default:
            dropoutReason = .voluntaryRest
        }

        let partial = OlympicCoachEngine.PartialSessionRecord(
            id: UUID(),
            date: session.endTime ?? Date(),
            programId: nil,
            plannedVolumeOrDistance: debriefRecord.plannedMetric,
            achievedVolumeOrDistance: debriefRecord.achievedMetric,
            completionPercentage: debriefRecord.plannedVsAchievedRatio * 100.0,
            achievedPaceOrLoad: debriefRecord.notes,
            dropoutReason: dropoutReason,
            perceivedExertionRPE: debriefRecord.perceivedExertionRPE,
            daysSinceLastSession: debriefRecord.daysSinceLastWorkout
        )
        partialSessions.append(partial)
        savePartialSessions()

        activeAdaptiveConstraints["LastScenarioBadge"] = debriefRecord.coachResult.scenarioBadge
        activeAdaptiveConstraints["PaceOrLoadCap"] = debriefRecord.coachResult.paceOrLoadCap
        activeAdaptiveConstraints["NextConstraint"] = debriefRecord.coachResult.nextWorkoutConstraint
        saveAdaptiveConstraints()

        self.activeSession = nil
        HapticFeedback.success()
    }

    public func savePartialSessions() {
        saveAsync(partialSessions, to: partialSessionsURL)
    }

    public func saveAdaptiveConstraints() {
        saveAsync(activeAdaptiveConstraints, to: constraintsURL)
    }

    public func deleteSession(id: UUID) {
        if let s = sessions.first(where: { $0.id == id }) {
            CalendarSyncService.shared.removeCalendarEvent(identifier: s.calendarEventId)
            // Falls an eine geplante Einheit gekoppelt, deren Status zuruecksetzen
            if let plannedId = s.plannedWorkoutId,
               let pIdx = plannedWorkouts.firstIndex(where: { $0.id == plannedId }) {
                plannedWorkouts[pIdx].isCompleted = false
                plannedWorkouts[pIdx].completedAt = nil
                savePlannedWorkouts()
            }
        }
        sessions.removeAll(where: { $0.id == id })
        saveSessions()
        syncWorkoutScheduleToBridge()
        HapticFeedback.soft()
    }

    public func updateSession(_ session: WorkoutSession) {
        if let idx = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions[idx] = session
            saveSessions()
            HapticFeedback.success()

            Task { @MainActor in
                if let calId = await CalendarSyncService.shared.syncCompletedSession(session: session) {
                    if let sIdx = self.sessions.firstIndex(where: { $0.id == session.id }) {
                        self.sessions[sIdx].calendarEventId = calId
                        self.saveSessions()
                    }
                }
            }
        }
    }

    // MARK: - Template & Folder Management
    @Published public var customFolders: [String] = [
        "Kraft & Hypertrophie",
        "Calisthenics & Goetter-Module",
        "MilFit & Bundeswehr-Dienstsport",
        "Mobilitaet, Prehab & Dekompression"
    ]

    public func addFolder(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty && !customFolders.contains(trimmed) {
            customFolders.append(trimmed)
            HapticFeedback.success()
        }
    }

    public func deleteFolder(name: String) {
        customFolders.removeAll(where: { $0 == name })
        HapticFeedback.soft()
    }

    public func addTemplate(_ template: WorkoutTemplate) {
        templates.append(template)
        saveTemplates()
    }

    public func updateTemplate(_ template: WorkoutTemplate) {
        if let idx = templates.firstIndex(where: { $0.id == template.id }) {
            templates[idx] = template
            saveTemplates()
            HapticFeedback.success()
        } else {
            addTemplate(template)
        }
    }

    public func duplicateTemplate(_ template: WorkoutTemplate) {
        var copy = template
        copy.id = UUID()
        copy.name = "\(template.name) (Kopie)"
        addTemplate(copy)
        HapticFeedback.light()
    }

    public func deleteTemplate(id: UUID) {
        templates.removeAll(where: { $0.id == id })
        saveTemplates()
        HapticFeedback.soft()
    }

    public func deleteTemplate(at offsets: IndexSet) {
        templates.remove(atOffsets: offsets)
        saveTemplates()
    }

    public func addExercise(_ exercise: Exercise) {
        exercises.append(exercise)
        saveExercises()
    }

    public func updateExercise(_ exercise: Exercise) {
        let foundIdx = exercises.firstIndex(where: { $0.id == exercise.id })
            ?? exercises.firstIndex(where: { $0.name.caseInsensitiveCompare(exercise.name) == .orderedSame })
        if let idx = foundIdx {
            exercises[idx] = exercise
            saveExercises()

            for tIdx in 0..<templates.count {
                for iIdx in 0..<templates[tIdx].items.count {
                    if templates[tIdx].items[iIdx].exercise.id == exercise.id ||
                       templates[tIdx].items[iIdx].exercise.name.caseInsensitiveCompare(exercise.name) == .orderedSame {
                        templates[tIdx].items[iIdx].exercise = exercise
                    }
                }
            }
            saveTemplates()

            if var active = activeSession {
                for eIdx in 0..<active.exercises.count {
                    if active.exercises[eIdx].exercise.id == exercise.id ||
                       active.exercises[eIdx].exercise.name.caseInsensitiveCompare(exercise.name) == .orderedSame {
                        active.exercises[eIdx].exercise = exercise
                    }
                }
                activeSession = active
            }

            HapticFeedback.success()
        }
    }

    public func renameExercise(id: UUID, newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if let idx = exercises.firstIndex(where: { $0.id == id }) {
            let oldName = exercises[idx].name
            exercises[idx].name = trimmed
            saveExercises()

            for tIdx in 0..<templates.count {
                for iIdx in 0..<templates[tIdx].items.count {
                    if templates[tIdx].items[iIdx].exercise.id == id || templates[tIdx].items[iIdx].exercise.name == oldName {
                        templates[tIdx].items[iIdx].exercise.name = trimmed
                    }
                }
            }
            saveTemplates()

            if var active = activeSession {
                for exIdx in 0..<active.exercises.count {
                    if active.exercises[exIdx].exercise.id == id || active.exercises[exIdx].exercise.name == oldName {
                        active.exercises[exIdx].exercise.name = trimmed
                    }
                }
                self.activeSession = active
            }
            HapticFeedback.success()
        }
    }

    public func replaceExerciseInActiveWorkout(exerciseRecordId: UUID, with newExercise: Exercise) {
        guard var session = activeSession else { return }
        if let exIndex = session.exercises.firstIndex(where: { $0.id == exerciseRecordId }) {
            session.exercises[exIndex].exercise = newExercise
            self.activeSession = session
            HapticFeedback.success()
        }
    }

    public func archiveExercise(id: UUID) {
        exercises.removeAll(where: { $0.id == id })
        saveExercises()
        HapticFeedback.soft()
    }

    public func transferExerciseData(from fromId: UUID, to toId: UUID) {
        guard let source = exercises.first(where: { $0.id == fromId }),
              let target = exercises.first(where: { $0.id == toId }) else { return }

        for sIdx in 0..<sessions.count {
            for exIdx in 0..<sessions[sIdx].exercises.count {
                if sessions[sIdx].exercises[exIdx].exercise.id == source.id {
                    sessions[sIdx].exercises[exIdx].exercise = target
                }
            }
        }
        saveSessions()
        HapticFeedback.success()
    }

    // MARK: - Active Workout In-Session Editing
    public func updateActiveWorkoutTitle(_ newTitle: String) {
        let trimmed = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        activeSession?.title = trimmed
        HapticFeedback.light()
    }

    public func updateActiveWorkoutStartTime(_ newDate: Date) {
        activeSession?.startTime = newDate
        HapticFeedback.light()
    }

    public func updateActiveWorkoutNotes(_ notes: String) {
        activeSession?.somaticNotes = notes
        HapticFeedback.light()
    }

    // MARK: - Active Workout Pause & Resume
    public func pauseActiveWorkout() {
        guard var session = activeSession, !session.isPaused else { return }
        session.isPaused = true
        session.lastPauseTime = Date()
        self.activeSession = session
        HapticFeedback.medium()
    }

    public func resumeActiveWorkout() {
        guard var session = activeSession, session.isPaused else { return }
        if let lastPause = session.lastPauseTime {
            session.pausedIntervals += Date().timeIntervalSince(lastPause)
        }
        session.isPaused = false
        session.lastPauseTime = nil
        self.activeSession = session
        HapticFeedback.medium()
    }

    public func toggleActiveWorkoutPause() {
        guard let session = activeSession else { return }
        if session.isPaused {
            resumeActiveWorkout()
        } else {
            pauseActiveWorkout()
        }
    }

    // MARK: - Program & Multi-Program Enrollment Management
    public var activeEnrollments: [ProgramEnrollment] {
        enrollments.filter { $0.isActive }
    }

    public func activeEnrollment(for block: ProgramBlock) -> ProgramEnrollment? {
        enrollments.first(where: { $0.block == block && $0.isActive })
    }

    public func primaryActiveEnrollment() -> (program: TrainingProgram, enrollment: ProgramEnrollment)? {
        guard let activeEnr = enrollments.first(where: { $0.isActive }),
              let prog = programs.first(where: { $0.id == activeEnr.programId }) else {
            return nil
        }
        return (prog, activeEnr)
    }

    public func activePrograms() -> [(program: TrainingProgram, enrollment: ProgramEnrollment)] {
        enrollments.filter { $0.isActive }.compactMap { enr in
            guard let prog = programs.first(where: { $0.id == enr.programId }) else { return nil }
            return (prog, enr)
        }
    }

    /// Schreibt den Nutzer in ein Programm ein. Unterstuetzt gleichzeitige Mehrfachprogramme.
    public func enroll(in program: TrainingProgram, replaceSameBlock: Bool = false) {
        if replaceSameBlock {
            for i in 0..<enrollments.count {
                if enrollments[i].block == program.block {
                    enrollments[i].isActive = false
                }
            }
        }

        if let idx = enrollments.firstIndex(where: { $0.programId == program.id }) {
            enrollments[idx].isActive = true
            enrollments[idx].lastCompletedAt = enrollments[idx].lastCompletedAt ?? Date()
        } else {
            let newEnrollment = ProgramEnrollment(
                programId: program.id,
                block: program.block,
                enrolledAt: Date(),
                lastCompletedAt: nil,
                currentCycle: 1,
                currentWeek: 1,
                currentSessionIndex: 0,
                completedSessionIds: [],
                cycleHistory: [],
                flowTuningOffsetPercent: 0.0,
                isActive: true
            )
            enrollments.append(newEnrollment)
        }
        saveEnrollments()
        scheduleProgramInTagesdetail(program: program)
        HapticFeedback.success()
    }

    /// Fuegt alle Tage des Programms fuer heute und die Zukunft in das Tagesdetail ein
    public func scheduleProgramInTagesdetail(program: TrainingProgram, startDate: Date = Date()) {
        let calendar = Calendar.current
        let allSessions = program.allSessions
        let today = calendar.startOfDay(for: startDate)
        let intervalDays = max(1, 7 / max(1, program.daysPerWeek))

        for (idx, session) in allSessions.enumerated() {
            let alreadyPlanned = plannedWorkouts.contains { $0.programId == program.id && $0.sessionId == session.id }
            if !alreadyPlanned {
                let dayOffset = idx * intervalDays
                let plannedDate = calendar.date(byAdding: .day, value: dayOffset, to: today) ?? today
                let item = PlannedWorkoutItem(
                    programId: program.id,
                    programName: program.name,
                    sessionId: session.id,
                    dayNumber: session.dayNumber > 0 ? session.dayNumber : (idx + 1),
                    title: session.title,
                    plannedDate: plannedDate,
                    isCompleted: false,
                    modalityRaw: session.modality.rawValue
                )
                plannedWorkouts.append(item)
            }
        }
        savePlannedWorkouts()
    }

    public func planWorkout(
        title: String,
        date: Date,
        templateId: UUID? = nil,
        notes: String = "",
        exerciseNames: [String] = []
    ) {
        var item = PlannedWorkoutItem(
            programId: UUID(),
            programName: "",
            sessionId: UUID(),
            dayNumber: 1,
            title: title,
            plannedDate: date,
            isCompleted: false,
            modalityRaw: "kraft",
            templateId: templateId,
            notes: notes,
            exerciseNames: exerciseNames
        )

        let template = templates.first(where: { $0.id == templateId })
        if let tmpl = template, exerciseNames.isEmpty {
            item.exerciseNames = tmpl.items.map { $0.exercise.name }
        }

        plannedWorkouts.append(item)
        savePlannedWorkouts()
        HapticFeedback.success()

        Task { @MainActor in
            if let calId = await CalendarSyncService.shared.schedulePlannedWorkoutEvent(planned: item, template: template) {
                if let pIdx = self.plannedWorkouts.firstIndex(where: { $0.id == item.id }) {
                    self.plannedWorkouts[pIdx].calendarEventId = calId
                    self.savePlannedWorkouts()
                }
            }
        }
    }

    public func removePlannedWorkout(id: UUID) {
        if let item = plannedWorkouts.first(where: { $0.id == id }) {
            CalendarSyncService.shared.removeCalendarEvent(identifier: item.calendarEventId)
            // Gekoppelte Session ebenfalls entfernen, um Zombie-Workouts zu verhindern
            if let sIdx = sessions.firstIndex(where: { $0.plannedWorkoutId == id }) {
                let sId = sessions[sIdx].id
                sessions.removeAll(where: { $0.id == sId })
                saveSessions()
            }
        }
        plannedWorkouts.removeAll(where: { $0.id == id })
        savePlannedWorkouts()
        syncWorkoutScheduleToBridge()
        HapticFeedback.light()
    }

    public func togglePlannedWorkoutCompletion(id: UUID) {
        if let idx = plannedWorkouts.firstIndex(where: { $0.id == id }) {
            plannedWorkouts[idx].isCompleted.toggle()
            plannedWorkouts[idx].completedAt = plannedWorkouts[idx].isCompleted ? Date() : nil
            savePlannedWorkouts()
            HapticFeedback.success()
        }
    }

    public func addHistoricalOrPlannedWorkout(
        title: String,
        date: Date,
        isCompleted: Bool,
        templateId: UUID? = nil,
        notes: String = "",
        exerciseNames: [String] = []
    ) {
        let plannedId = UUID()
        var item = PlannedWorkoutItem(
            programId: UUID(),
            programName: "",
            sessionId: UUID(),
            dayNumber: 1,
            title: title,
            plannedDate: date,
            isCompleted: isCompleted,
            completedAt: isCompleted ? date : nil,
            modalityRaw: "kraft",
            templateId: templateId,
            notes: notes,
            exerciseNames: exerciseNames
        )
        item.id = plannedId
        if let tid = templateId, let tmpl = templates.first(where: { $0.id == tid }), exerciseNames.isEmpty {
            item.exerciseNames = tmpl.items.map { $0.exercise.name }
        }
        plannedWorkouts.append(item)
        savePlannedWorkouts()

        // Wenn als bereits absolviert markiert, auch eine entsprechende Session anlegen
        if isCompleted {
            var records: [WorkoutExerciseRecord] = []
            if let tid = templateId, let tmpl = templates.first(where: { $0.id == tid }) {
                records = tmpl.items.map { tItem in
                    let setCount = max(1, tItem.targetSets)
                    let sets = (1...setCount).map { sIdx in
                        WorkoutSetRecord(setNumber: sIdx, weightKg: tItem.targetWeightKg, reps: tItem.targetReps, isTimeBased: tItem.isTimeBased, isCompleted: true, rpe: 7.5)
                    }
                    return WorkoutExerciseRecord(exercise: tItem.exercise, sets: sets)
                }
            } else if !item.exerciseNames.isEmpty {
                records = item.exerciseNames.compactMap { name in
                    if let ex = exercises.first(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) {
                        let setCount = ex.isUnilateral ? 4 : 3
                        let sets = (1...setCount).map { idx in
                            WorkoutSetRecord(setNumber: idx, weightKg: 0, reps: 10, isTimeBased: ex.isTimeBased, isCompleted: true, rpe: 7.5)
                        }
                        return WorkoutExerciseRecord(exercise: ex, sets: sets)
                    }
                    return nil
                }
            }
            let session = WorkoutSession(
                templateId: templateId,
                plannedWorkoutId: plannedId,
                title: title,
                startTime: date.addingTimeInterval(-2700),
                endTime: date,
                exercises: records,
                perceivedExertionRPE: 7,
                somaticNotes: notes
            )
            sessions.insert(session, at: 0)
            saveSessions()
        }

        HapticFeedback.success()
    }

    /// Bricht ein Programm ab: Entfernt NUR die noch nicht absolvierten zukuenftigen Tage aus dem Tagesdetail!
    public func cancelProgram(programId: UUID) {
        if let idx = enrollments.firstIndex(where: { $0.programId == programId }) {
            enrollments[idx].isActive = false
            saveEnrollments()
        }
        // Nur nicht-absolvierte Einheiten entfernen; alle bereits absolvierten bleiben erhalten!
        plannedWorkouts.removeAll { $0.programId == programId && !$0.isCompleted }
        savePlannedWorkouts()
        HapticFeedback.soft()
    }

    public func pauseProgram(programId: UUID) {
        if let idx = enrollments.firstIndex(where: { $0.programId == programId }) {
            enrollments[idx].isActive = false
            saveEnrollments()
            HapticFeedback.soft()
        }
    }

    public func completeProgramSession(sessionId: UUID, in program: TrainingProgram) {
        if let idx = enrollments.firstIndex(where: { $0.programId == program.id }) {
            enrollments[idx].markSessionCompleted(sessionId: sessionId, program: program)
            saveEnrollments()
        }
        if let pIdx = plannedWorkouts.firstIndex(where: { $0.sessionId == sessionId }) {
            plannedWorkouts[pIdx].isCompleted = true
            plannedWorkouts[pIdx].completedAt = Date()
            savePlannedWorkouts()
        }
        HapticFeedback.success()
    }

    public func resetProgramProgress(programId: UUID) {
        if let idx = enrollments.firstIndex(where: { $0.programId == programId }) {
            enrollments[idx].currentCycle = 1
            enrollments[idx].currentWeek = 1
            enrollments[idx].currentSessionIndex = 0
            enrollments[idx].completedSessionIds = []
            enrollments[idx].lastCompletedAt = nil
            enrollments[idx].flowTuningOffsetPercent = 0.0
            saveEnrollments()
            HapticFeedback.soft()
        }
    }

    // MARK: - Flow-State & Benchmark Registry Integration
    public func submitFlowFeedback(_ feedback: FlowPostSessionFeedback) {
        flowFeedbacks.insert(feedback, at: 0)
        saveFlowFeedbacks()

        let tuning = FlowStateEngine.shared.evaluateSession(feedback: feedback)

        // Falls zu einem Programm gehoerend, offset anpassen (die 4 %-Kante)
        if let progId = feedback.programId, let idx = enrollments.firstIndex(where: { $0.programId == progId }) {
            enrollments[idx].flowTuningOffsetPercent += tuning.loadAdjustmentPercent
            // Drosselbereich beschraenken (-25 % bis +25 %)
            enrollments[idx].flowTuningOffsetPercent = max(-25.0, min(25.0, enrollments[idx].flowTuningOffsetPercent))
            saveEnrollments()
        }

        HapticFeedback.success()
    }

    public func recordBenchmark(
        metricType: BenchmarkMetricType,
        exerciseKey: String,
        value: Double,
        unit: String,
        sourceProgram: String = "Freies Training"
    ) {
        benchmarkRegistry.recordAchievement(
            metricType: metricType,
            exerciseKey: exerciseKey,
            value: value,
            unit: unit,
            sourceProgram: sourceProgram
        )
        saveBenchmarks()
    }

    public func effectiveBenchmark(for exerciseKey: String, metricType: BenchmarkMetricType) -> CrossProgramBenchmark? {
        benchmarkRegistry.getEffectiveStandard(exerciseKey: exerciseKey, metricType: metricType)
    }

    /// Konvertiert eine gefuehrte ProgramSession in eine ActiveWorkoutSession mit automatischer Lastanpassung
    public func startProgramSession(_ session: ProgramSession, in program: TrainingProgram, loadReductionPercent: Int = 0) {
        var records: [WorkoutExerciseRecord] = []

        let enr = enrollments.first(where: { $0.programId == program.id })
        let flowOffset = enr?.flowTuningOffsetPercent ?? 0.0

        let safeReturnMultiplier = max(0.4, 1.0 - (Double(loadReductionPercent) / 100.0))
        let flowMultiplier = max(0.75, min(1.25, 1.0 + (flowOffset / 100.0)))
        let combinedMultiplier = max(0.35, safeReturnMultiplier * flowMultiplier)

        for item in session.exercises {
            // Versuche Uebung im Katalog zu finden oder erstelle Ad-Hoc Uebung
            let matchedExercise = exercises.first(where: { $0.name.localizedCaseInsensitiveContains(item.name) || item.name.localizedCaseInsensitiveContains($0.name) })
                ?? Exercise(
                    name: item.name,
                    targetMuscle: .functionalCore,
                    equipment: .bodyweight,
                    isBWKRehaSafe: item.isBWKCoreRehaSafe,
                    executionNotes: item.techniqueNotes.isEmpty ? "Gefuehrte Ausfuehrung gemaess Programmvorgabe." : item.techniqueNotes,
                    defaultSets: item.targetSets,
                    defaultReps: 10,
                    defaultRestSeconds: item.restSeconds
                )

            // Pruefe uebertragenen Leistungsstandard aus Benchmark-Registry
            var baseWeight = item.targetWeightKg
            if let bm = benchmarkRegistry.getEffectiveStandard(exerciseKey: item.name, metricType: .estimated1RM), bm.currentEffectiveValue() > 0 {
                let effectiveStandard = bm.currentEffectiveValue()
                // Bei Kraftuebungen wird der Arbeitsgewicht-Satz auf ca. 70% des aktuellen effektiven 1RM normiert
                baseWeight = max(baseWeight, (effectiveStandard * 0.70))
            }

            let adjustedWeight = (baseWeight * combinedMultiplier * 2).rounded() / 2
            let targetRepsInt = Int(item.targetReps.components(separatedBy: CharacterSet.decimalDigits.inverted).filter { !$0.isEmpty }.last ?? "10") ?? 10

            let sets = (1...max(1, item.targetSets)).map { setIdx in
                WorkoutSetRecord(
                    setNumber: setIdx,
                    weightKg: max(0, adjustedWeight),
                    reps: targetRepsInt,
                    isCompleted: false
                )
            }

            records.append(WorkoutExerciseRecord(exercise: matchedExercise, sets: sets))
        }

        let cyclePrefix = enr.map { "Zyklus \($0.currentCycle) • " } ?? ""
        let workoutTitle = "\(cyclePrefix)\(program.name) • W\(session.dayNumber) \(session.title)"

        var notesList: [String] = []
        if loadReductionPercent > 0 {
            notesList.append("SafeReturn: -\(loadReductionPercent)% Last")
        }
        if abs(flowOffset) > 0.1 {
            let sign = flowOffset > 0 ? "+" : ""
            notesList.append("Flow 4%-Tuning: \(sign)\(Int(flowOffset))% Last")
        }
        let somaticNote = notesList.isEmpty ? "Regulaeres gefuehrtes Programm-Training." : notesList.joined(separator: " • ")

        let newActiveSession = WorkoutSession(
            title: workoutTitle,
            startTime: Date(),
            exercises: records,
            somaticNotes: somaticNote
        )

        self.activeSession = newActiveSession
        self.isPresentingActiveWorkout = true
        HapticFeedback.light()
    }
}

// MARK: - Boxing Bell Audio Service (Headphone-Optimized Playback)
public final class BoxingBellAudioService: NSObject, AVAudioPlayerDelegate {
    public static let shared = BoxingBellAudioService()

    private var audioPlayer: AVAudioPlayer?
    private var countdownPlayer: AVAudioPlayer?
    private var cachedWAVData: Data?
    private var cachedBeepData: Data?

    private override init() {
        super.init()
        configureAudioSession()
        self.cachedWAVData = generateBoxingBellWAVData()
        self.cachedBeepData = generateBeepWAVData(freq: 880.0, duration: 0.12)
    }

    public func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try session.setActive(true, options: [])
        } catch {
            print("[BoxingBellAudioService] AudioSession setup error: \(error.localizedDescription)")
        }
    }

    public func playBoxingBell() {
        configureAudioSession()

        let data = cachedWAVData ?? generateBoxingBellWAVData()
        do {
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.delegate = self
            audioPlayer?.volume = 1.0
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            print("[BoxingBellAudioService] AVAudioPlayer error: \(error.localizedDescription)")
        }
    }

    public func playCountdownBeep() {
        configureAudioSession()

        let data = cachedBeepData ?? generateBeepWAVData(freq: 880.0, duration: 0.12)
        do {
            countdownPlayer = try AVAudioPlayer(data: data)
            countdownPlayer?.delegate = self
            countdownPlayer?.volume = 0.85
            countdownPlayer?.prepareToPlay()
            countdownPlayer?.play()
        } catch {
            print("[BoxingBellAudioService] Countdown beep error: \(error.localizedDescription)")
        }
    }

    private func generateBeepWAVData(freq: Double, duration: Double) -> Data {
        let sampleRate: Int = 44100
        let totalSamples = Int(Double(sampleRate) * duration)
        var samples = [Int16](repeating: 0, count: totalSamples)

        for i in 0..<totalSamples {
            let t = Double(i) / Double(sampleRate)
            let attack = min(1.0, t / 0.01)
            let decay = exp(-10.0 * t)
            let env = attack * decay
            let value = sin(2.0 * .pi * freq * t) * env * 0.95
            let clamped = max(-1.0, min(1.0, value))
            samples[i] = Int16(clamped * 32767.0)
        }

        var data = Data()
        data.append(contentsOf: [0x52, 0x49, 0x46, 0x46]) // "RIFF"
        let subchunk2Size = totalSamples * 2
        let chunkSize = Int32(36 + subchunk2Size)
        withUnsafeBytes(of: chunkSize.littleEndian) { data.append(contentsOf: $0) }
        data.append(contentsOf: [0x57, 0x41, 0x56, 0x45]) // "WAVE"
        data.append(contentsOf: [0x66, 0x6D, 0x74, 0x20]) // "fmt "
        let subchunk1Size: Int32 = 16
        withUnsafeBytes(of: subchunk1Size.littleEndian) { data.append(contentsOf: $0) }
        let audioFormat: Int16 = 1 // PCM
        withUnsafeBytes(of: audioFormat.littleEndian) { data.append(contentsOf: $0) }
        let numChannels: Int16 = 1 // Mono
        withUnsafeBytes(of: numChannels.littleEndian) { data.append(contentsOf: $0) }
        let sRate: Int32 = Int32(sampleRate)
        withUnsafeBytes(of: sRate.littleEndian) { data.append(contentsOf: $0) }
        let byteRate: Int32 = Int32(sampleRate * 2)
        withUnsafeBytes(of: byteRate.littleEndian) { data.append(contentsOf: $0) }
        let blockAlign: Int16 = 2
        withUnsafeBytes(of: blockAlign.littleEndian) { data.append(contentsOf: $0) }
        let bitsPerSample: Int16 = 16
        withUnsafeBytes(of: bitsPerSample.littleEndian) { data.append(contentsOf: $0) }
        data.append(contentsOf: [0x64, 0x61, 0x74, 0x61]) // "data"
        let dSize: Int32 = Int32(subchunk2Size)
        withUnsafeBytes(of: dSize.littleEndian) { data.append(contentsOf: $0) }
        samples.withUnsafeBufferPointer { buffer in
            data.append(Data(buffer: buffer))
        }
        return data
    }

    // Synthesizes a realistic 3-strike brass boxing ring bell in-memory
    private func generateBoxingBellWAVData() -> Data {
        let sampleRate: Int = 44100
        let strikeTimes: [Double] = [0.0, 0.35, 0.70]
        let totalDuration: Double = 2.1
        let totalSamples = Int(Double(sampleRate) * totalDuration)

        var samples = [Int16](repeating: 0, count: totalSamples)

        // Boxing Bell Frequency Composition (C6 fundamental + metallic ring harmonics)
        let frequencies: [(freq: Double, weight: Double, decay: Double)] = [
            (1046.5, 0.45, 3.2),   // C6 fundamental
            (2093.0, 0.28, 4.5),   // 1st octave overtone
            (3139.5, 0.16, 6.0),   // High metallic resonance
            (4186.0, 0.11, 8.5)    // Transient hammer strike strike
        ]

        for strike in strikeTimes {
            let startIdx = Int(strike * Double(sampleRate))
            let strikeSamples = totalSamples - startIdx
            for i in 0..<strikeSamples {
                let t = Double(i) / Double(sampleRate)
                var value: Double = 0.0
                for comp in frequencies {
                    let env = exp(-comp.decay * t)
                    value += comp.weight * sin(2.0 * .pi * comp.freq * t) * env
                }
                let sampleIdx = startIdx + i
                if sampleIdx < totalSamples {
                    let currentVal = Double(samples[sampleIdx]) / 32767.0
                    let combined = currentVal + value * 0.95
                    let clamped = max(-1.0, min(1.0, combined))
                    samples[sampleIdx] = Int16(clamped * 32767.0)
                }
            }
        }

        // Build Standard 44-byte RIFF/WAVE header
        var data = Data()
        // "RIFF"
        data.append(contentsOf: [0x52, 0x49, 0x46, 0x46])
        let subchunk2Size = totalSamples * 2
        let chunkSize = Int32(36 + subchunk2Size)
        withUnsafeBytes(of: chunkSize.littleEndian) { data.append(contentsOf: $0) }
        // "WAVE"
        data.append(contentsOf: [0x57, 0x41, 0x56, 0x45])
        // "fmt "
        data.append(contentsOf: [0x66, 0x6D, 0x74, 0x20])
        let subchunk1Size: Int32 = 16
        withUnsafeBytes(of: subchunk1Size.littleEndian) { data.append(contentsOf: $0) }
        let audioFormat: Int16 = 1 // PCM
        withUnsafeBytes(of: audioFormat.littleEndian) { data.append(contentsOf: $0) }
        let numChannels: Int16 = 1 // Mono
        withUnsafeBytes(of: numChannels.littleEndian) { data.append(contentsOf: $0) }
        let sRate: Int32 = Int32(sampleRate)
        withUnsafeBytes(of: sRate.littleEndian) { data.append(contentsOf: $0) }
        let byteRate: Int32 = Int32(sampleRate * 2)
        withUnsafeBytes(of: byteRate.littleEndian) { data.append(contentsOf: $0) }
        let blockAlign: Int16 = 2
        withUnsafeBytes(of: blockAlign.littleEndian) { data.append(contentsOf: $0) }
        let bitsPerSample: Int16 = 16
        withUnsafeBytes(of: bitsPerSample.littleEndian) { data.append(contentsOf: $0) }
        // "data"
        data.append(contentsOf: [0x64, 0x61, 0x74, 0x61])
        let dSize: Int32 = Int32(subchunk2Size)
        withUnsafeBytes(of: dSize.littleEndian) { data.append(contentsOf: $0) }
        // Audio PCM payload
        samples.withUnsafeBufferPointer { buffer in
            data.append(Data(buffer: buffer))
        }
        return data
    }
}

