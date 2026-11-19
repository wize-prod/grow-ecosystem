import Foundation

public struct WorkoutTemplateItem: Identifiable, Codable, Equatable, Hashable {
    public var id: UUID
    public var exercise: Exercise
    public var targetSets: Int
    public var targetReps: Int
    public var targetSeconds: Int?
    public var isTimeBased: Bool
    public var targetWeightKg: Double
    public var restSeconds: Int

    public init(
        id: UUID = UUID(),
        exercise: Exercise,
        targetSets: Int = 3,
        targetReps: Int = 10,
        targetSeconds: Int? = nil,
        isTimeBased: Bool = false,
        targetWeightKg: Double = 0.0,
        restSeconds: Int = 90
    ) {
        self.id = id
        self.exercise = exercise
        self.targetSets = targetSets
        self.targetReps = targetReps
        self.targetSeconds = targetSeconds
        self.isTimeBased = isTimeBased || (targetSeconds != nil) || exercise.isTimeBased
        self.targetWeightKg = targetWeightKg
        self.restSeconds = restSeconds
    }

    enum CodingKeys: String, CodingKey {
        case id, exercise, targetSets, targetReps, targetSeconds, isTimeBased, targetWeightKg, restSeconds
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        exercise = try container.decode(Exercise.self, forKey: .exercise)
        targetSets = try container.decodeIfPresent(Int.self, forKey: .targetSets) ?? 3
        targetReps = try container.decodeIfPresent(Int.self, forKey: .targetReps) ?? 10
        targetSeconds = try container.decodeIfPresent(Int.self, forKey: .targetSeconds)
        let decodedTimeBased = try container.decodeIfPresent(Bool.self, forKey: .isTimeBased)
        isTimeBased = decodedTimeBased ?? (targetSeconds != nil || exercise.isTimeBased)
        targetWeightKg = try container.decodeIfPresent(Double.self, forKey: .targetWeightKg) ?? 0.0
        restSeconds = try container.decodeIfPresent(Int.self, forKey: .restSeconds) ?? 90
    }
}

public struct WorkoutTemplate: Identifiable, Codable, Equatable, Hashable {
    public var id: UUID
    public var name: String
    public var folderName: String
    public var category: String
    public var summary: String
    public var items: [WorkoutTemplateItem]
    public var estimatedMinutes: Int
    public var targetTimeSlot: String
    public var isBWKRehaFocused: Bool

    public init(
        id: UUID = UUID(),
        name: String,
        folderName: String = "Fixed Schedule",
        category: String = "Krafttraining",
        summary: String = "",
        items: [WorkoutTemplateItem] = [],
        estimatedMinutes: Int = 45,
        targetTimeSlot: String = "17:00 - 18:30",
        isBWKRehaFocused: Bool = false
    ) {
        self.id = id
        self.name = name
        self.folderName = folderName
        self.category = category
        self.summary = summary
        self.items = items
        self.estimatedMinutes = estimatedMinutes
        self.targetTimeSlot = targetTimeSlot
        self.isBWKRehaFocused = isBWKRehaFocused
    }

    public var matchingBlock: ProgramBlock {
        let text = "\(folderName) \(category) \(name)".lowercased()
        if text.contains("calisthenics") || text.contains("stuben") || text.contains("hotel") || (text.contains("bodyweight") && !text.contains("feld")) {
            return .calisthenicsGoetter
        } else if text.contains("milfit") || text.contains("kaserne") || text.contains("feld") || text.contains("truppen") {
            return .bundeswehrMilFit
        } else if text.contains("mobilitaet") || text.contains("reha") || text.contains("dehnung") || text.contains("lws") || text.contains("reset") || text.contains("vagus") {
            return .mobilitaetReha
        } else if text.contains("ausdauer") || text.contains("lauf") || text.contains("running") {
            return .ausdauerRunning
        } else if text.contains("aesthetik") || text.contains("v-taper") || text.contains("symmetrie") {
            return .aesthetikSymmetrie
        } else {
            return .kraftHypertrophie
        }
    }
}
