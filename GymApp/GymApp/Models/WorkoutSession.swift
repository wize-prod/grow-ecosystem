import Foundation

public struct WorkoutSetRecord: Identifiable, Codable, Equatable, Hashable {
    public var id: UUID
    public var setNumber: Int
    public var weightKg: Double
    public var reps: Int
    public var durationSeconds: Int?
    public var isTimeBased: Bool
    public var isCompleted: Bool
    public var isPR: Bool
    public var isWarmup: Bool
    public var rpe: Double?
    public var side: String?
    public var timestamp: Date
    public var executionDurationSeconds: Int?

    public init(
        id: UUID = UUID(),
        setNumber: Int,
        weightKg: Double = 0.0,
        reps: Int = 10,
        durationSeconds: Int? = nil,
        isTimeBased: Bool = false,
        isCompleted: Bool = false,
        isPR: Bool = false,
        isWarmup: Bool = false,
        rpe: Double? = nil,
        side: String? = nil,
        timestamp: Date = Date(),
        executionDurationSeconds: Int? = nil
    ) {
        self.id = id
        self.setNumber = setNumber
        self.weightKg = weightKg
        self.reps = reps
        self.durationSeconds = durationSeconds
        self.isTimeBased = isTimeBased || (durationSeconds != nil)
        self.isCompleted = isCompleted
        self.isPR = isPR
        self.isWarmup = isWarmup
        self.rpe = rpe
        self.side = side
        self.timestamp = timestamp
        self.executionDurationSeconds = executionDurationSeconds
    }

    public var estimated1RM: Double {
        OneRepMaxFormula.calculateAccurate1RM(weightKg: weightKg, reps: reps, rpe: rpe)
    }

    enum CodingKeys: String, CodingKey {
        case id, setNumber, weightKg, reps, durationSeconds, isTimeBased, isCompleted, isPR, isWarmup, rpe, side, timestamp, executionDurationSeconds
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        setNumber = try container.decodeIfPresent(Int.self, forKey: .setNumber) ?? 1
        weightKg = try container.decodeIfPresent(Double.self, forKey: .weightKg) ?? 0.0
        reps = try container.decodeIfPresent(Int.self, forKey: .reps) ?? 10
        durationSeconds = try container.decodeIfPresent(Int.self, forKey: .durationSeconds)
        let decodedTimeBased = try container.decodeIfPresent(Bool.self, forKey: .isTimeBased)
        isTimeBased = decodedTimeBased ?? (durationSeconds != nil)
        isCompleted = try container.decodeIfPresent(Bool.self, forKey: .isCompleted) ?? false
        isPR = try container.decodeIfPresent(Bool.self, forKey: .isPR) ?? false
        isWarmup = try container.decodeIfPresent(Bool.self, forKey: .isWarmup) ?? false
        rpe = try container.decodeIfPresent(Double.self, forKey: .rpe)
        side = try container.decodeIfPresent(String.self, forKey: .side)
        timestamp = try container.decodeIfPresent(Date.self, forKey: .timestamp) ?? Date()
        executionDurationSeconds = try container.decodeIfPresent(Int.self, forKey: .executionDurationSeconds)
    }
}

public struct WorkoutExerciseRecord: Identifiable, Codable, Equatable, Hashable {
    public var id: UUID
    public var exercise: Exercise
    public var sets: [WorkoutSetRecord]
    public var notes: String
    public var supersetGroupId: String?

    public init(
        id: UUID = UUID(),
        exercise: Exercise,
        sets: [WorkoutSetRecord] = [],
        notes: String = "",
        supersetGroupId: String? = nil
    ) {
        self.id = id
        self.exercise = exercise
        self.sets = sets
        self.notes = notes
        self.supersetGroupId = supersetGroupId
    }

    public var totalTonnage: Double {
        sets.filter { $0.isCompleted }.reduce(0.0) { sum, set in
            sum + (set.weightKg * Double(set.reps))
        }
    }

    public var completedSetsCount: Int {
        sets.filter { $0.isCompleted }.count
    }

    public var bestSetSummary: String {
        let completed = sets.filter { $0.isCompleted }
        guard let best = completed.max(by: { ($0.weightKg * Double($0.reps)) < ($1.weightKg * Double($1.reps)) }) else {
            return "-"
        }
        if best.isTimeBased || (best.durationSeconds ?? 0) > 0 {
            let secs = best.durationSeconds ?? best.reps
            let mins = secs / 60
            let remSecs = secs % 60
            let timeStr = mins > 0 ? "\(mins):\(String(format: "%02d", remSecs)) min" : "\(secs)s"
            if best.weightKg > 0 {
                let weightStr = best.weightKg.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(best.weightKg))" : String(format: "%.1f", best.weightKg).replacingOccurrences(of: ".", with: ",")
                return "\(weightStr) kg × \(timeStr)"
            } else {
                return timeStr
            }
        }
        let weightStr = best.weightKg.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(best.weightKg))" : String(format: "%.1f", best.weightKg).replacingOccurrences(of: ".", with: ",")
        return "\(weightStr) kg × \(best.reps)"
    }
}

public struct WorkoutSession: Identifiable, Codable, Equatable, Hashable {
    public var id: UUID
    public var templateId: UUID?
    public var plannedWorkoutId: UUID?
    public var title: String
    public var startTime: Date
    public var endTime: Date?
    public var exercises: [WorkoutExerciseRecord]
    public var perceivedExertionRPE: Int
    public var somaticNotes: String
    public var estimatedCaloriesBurned: Double
    public var prCount: Int
    public var isSyncedToCalendar: Bool
    public var isSyncedToHealthKit: Bool
    public var isEarlyTermination: Bool
    public var terminationReason: String?
    public var debriefRecord: WorkoutDebriefRecord?
    public var calendarEventId: String?
    public var isPaused: Bool
    public var pausedIntervals: TimeInterval
    public var lastPauseTime: Date?

    public init(
        id: UUID = UUID(),
        templateId: UUID? = nil,
        plannedWorkoutId: UUID? = nil,
        title: String,
        startTime: Date = Date(),
        endTime: Date? = nil,
        exercises: [WorkoutExerciseRecord] = [],
        perceivedExertionRPE: Int = 6,
        somaticNotes: String = "",
        estimatedCaloriesBurned: Double = 0.0,
        prCount: Int = 0,
        isSyncedToCalendar: Bool = false,
        isSyncedToHealthKit: Bool = false,
        isEarlyTermination: Bool = false,
        terminationReason: String? = nil,
        debriefRecord: WorkoutDebriefRecord? = nil,
        calendarEventId: String? = nil,
        isPaused: Bool = false,
        pausedIntervals: TimeInterval = 0.0,
        lastPauseTime: Date? = nil
    ) {
        self.id = id
        self.templateId = templateId
        self.plannedWorkoutId = plannedWorkoutId
        self.title = title
        self.startTime = startTime
        self.endTime = endTime
        self.exercises = exercises
        self.perceivedExertionRPE = perceivedExertionRPE
        self.somaticNotes = somaticNotes
        self.estimatedCaloriesBurned = estimatedCaloriesBurned
        self.prCount = prCount
        self.isSyncedToCalendar = isSyncedToCalendar
        self.isSyncedToHealthKit = isSyncedToHealthKit
        self.isEarlyTermination = isEarlyTermination
        self.terminationReason = terminationReason
        self.debriefRecord = debriefRecord
        self.calendarEventId = calendarEventId
        self.isPaused = isPaused
        self.pausedIntervals = pausedIntervals
        self.lastPauseTime = lastPauseTime
    }

    enum CodingKeys: String, CodingKey {
        case id, templateId, plannedWorkoutId, title, startTime, endTime, exercises, perceivedExertionRPE, somaticNotes
        case estimatedCaloriesBurned, prCount, isSyncedToCalendar, isSyncedToHealthKit, isEarlyTermination
        case terminationReason, debriefRecord, calendarEventId, isPaused, pausedIntervals, lastPauseTime
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        templateId = try container.decodeIfPresent(UUID.self, forKey: .templateId)
        plannedWorkoutId = try container.decodeIfPresent(UUID.self, forKey: .plannedWorkoutId)
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? "Training"
        startTime = try container.decodeIfPresent(Date.self, forKey: .startTime) ?? Date()
        endTime = try container.decodeIfPresent(Date.self, forKey: .endTime)
        exercises = try container.decodeIfPresent([WorkoutExerciseRecord].self, forKey: .exercises) ?? []
        perceivedExertionRPE = try container.decodeIfPresent(Int.self, forKey: .perceivedExertionRPE) ?? 6
        somaticNotes = try container.decodeIfPresent(String.self, forKey: .somaticNotes) ?? ""
        estimatedCaloriesBurned = try container.decodeIfPresent(Double.self, forKey: .estimatedCaloriesBurned) ?? 0.0
        prCount = try container.decodeIfPresent(Int.self, forKey: .prCount) ?? 0
        isSyncedToCalendar = try container.decodeIfPresent(Bool.self, forKey: .isSyncedToCalendar) ?? false
        isSyncedToHealthKit = try container.decodeIfPresent(Bool.self, forKey: .isSyncedToHealthKit) ?? false
        isEarlyTermination = try container.decodeIfPresent(Bool.self, forKey: .isEarlyTermination) ?? false
        terminationReason = try container.decodeIfPresent(String.self, forKey: .terminationReason)
        debriefRecord = try container.decodeIfPresent(WorkoutDebriefRecord.self, forKey: .debriefRecord)
        calendarEventId = try container.decodeIfPresent(String.self, forKey: .calendarEventId)
        isPaused = try container.decodeIfPresent(Bool.self, forKey: .isPaused) ?? false
        pausedIntervals = try container.decodeIfPresent(TimeInterval.self, forKey: .pausedIntervals) ?? 0.0
        lastPauseTime = try container.decodeIfPresent(Date.self, forKey: .lastPauseTime)
    }

    public var durationMinutes: Int {
        guard let end = endTime else {
            var diff = Date().timeIntervalSince(startTime) - pausedIntervals
            if isPaused, let lastPause = lastPauseTime {
                diff -= Date().timeIntervalSince(lastPause)
            }
            return max(0, Int(max(0, diff) / 60.0))
        }
        var diff = end.timeIntervalSince(startTime) - pausedIntervals
        if isPaused, let lastPause = lastPauseTime {
            diff -= end.timeIntervalSince(lastPause)
        }
        return max(1, Int(max(0, diff) / 60.0))
    }

    public var currentElapsedSeconds: Int {
        if let end = endTime {
            var diff = end.timeIntervalSince(startTime) - pausedIntervals
            if isPaused, let lastPause = lastPauseTime {
                diff -= end.timeIntervalSince(lastPause)
            }
            return max(0, Int(diff))
        } else {
            var diff = Date().timeIntervalSince(startTime) - pausedIntervals
            if isPaused, let lastPause = lastPauseTime {
                diff -= Date().timeIntervalSince(lastPause)
            }
            return max(0, Int(diff))
        }
    }

    public var durationFormatted: String {
        let mins = durationMinutes
        if mins >= 60 {
            let h = mins / 60
            let m = mins % 60
            return "\(h)h \(m)min"
        } else {
            return "\(mins)min"
        }
    }

    public var totalTonnageKg: Double {
        exercises.reduce(0.0) { $0 + $1.totalTonnage }
    }

    public var totalCompletedSets: Int {
        exercises.reduce(0) { $0 + $1.completedSetsCount }
    }
}
