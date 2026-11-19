import Foundation

public struct GrowcerySyncState: Codable, Equatable {
    public var proteinConsumedGrams: Double
    public var proteinTargetGrams: Double
    public var carbsConsumedGrams: Double
    public var carbsTargetGrams: Double
    public var fatConsumedGrams: Double
    public var fatTargetGrams: Double
    public var caloriesConsumed: Double
    public var caloriesBudget: Double
    public var activeCaloriesBurnedToday: Double
    public var lastSyncTimestamp: Date?
    public var restingHeartRateBpm: Int

    public init(
        proteinConsumedGrams: Double = 0.0,
        proteinTargetGrams: Double = 160.0,
        carbsConsumedGrams: Double = 0.0,
        carbsTargetGrams: Double = 200.0,
        fatConsumedGrams: Double = 0.0,
        fatTargetGrams: Double = 65.0,
        caloriesConsumed: Double = 0.0,
        caloriesBudget: Double = 1900.0,
        activeCaloriesBurnedToday: Double = 0.0,
        lastSyncTimestamp: Date? = nil,
        restingHeartRateBpm: Int = 38
    ) {
        self.proteinConsumedGrams = proteinConsumedGrams
        self.proteinTargetGrams = proteinTargetGrams
        self.carbsConsumedGrams = carbsConsumedGrams
        self.carbsTargetGrams = carbsTargetGrams
        self.fatConsumedGrams = fatConsumedGrams
        self.fatTargetGrams = fatTargetGrams
        self.caloriesConsumed = caloriesConsumed
        self.caloriesBudget = caloriesBudget
        self.activeCaloriesBurnedToday = activeCaloriesBurnedToday
        self.lastSyncTimestamp = lastSyncTimestamp
        self.restingHeartRateBpm = restingHeartRateBpm
    }

    public var proteinProgressRatio: Double {
        guard proteinTargetGrams > 0 else { return 0.0 }
        return min(max(proteinConsumedGrams / proteinTargetGrams, 0.0), 1.0)
    }

    public var remainingProteinGrams: Double {
        max(0.0, proteinTargetGrams - proteinConsumedGrams)
    }

    public var recoveryStatusText: String {
        if proteinConsumedGrams >= proteinTargetGrams {
            return "Proteinzufuhr gesichert (\(Int(proteinConsumedGrams))g). Optimale anabole Signalgebung."
        } else if proteinConsumedGrams >= (proteinTargetGrams * 0.6) {
            return "Basis-Proteinzufuhr vorhanden (\(Int(proteinConsumedGrams))g / \(Int(proteinTargetGrams))g). Post-Workout Zufuhr einplanen."
        } else {
            return "Proteindefizit (\(Int(proteinConsumedGrams))g / \(Int(proteinTargetGrams))g). Vor/nach Training in Growcery erfassen."
        }
    }
}
