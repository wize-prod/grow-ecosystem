import Foundation

public struct AutoProgressionRecommendation: Identifiable, Equatable {
    public var id: UUID = UUID()
    public var exerciseId: UUID
    public var exerciseName: String
    public var currentWeightKg: Double
    public var recommendedWeightKg: Double
    public var deltaKg: Double
    public var averageRPE: Double
    public var rationale: String
    public var actionBadge: String
    public var isProgressionAvailable: Bool

    public init(
        id: UUID = UUID(),
        exerciseId: UUID,
        exerciseName: String,
        currentWeightKg: Double,
        recommendedWeightKg: Double,
        deltaKg: Double,
        averageRPE: Double,
        rationale: String,
        actionBadge: String,
        isProgressionAvailable: Bool
    ) {
        self.id = id
        self.exerciseId = exerciseId
        self.exerciseName = exerciseName
        self.currentWeightKg = currentWeightKg
        self.recommendedWeightKg = recommendedWeightKg
        self.deltaKg = deltaKg
        self.averageRPE = averageRPE
        self.rationale = rationale
        self.actionBadge = actionBadge
        self.isProgressionAvailable = isProgressionAvailable
    }
}

public enum AutoProgressionEngine {
    public static func evaluateProgression(
        exerciseId: UUID,
        exerciseName: String,
        sets: [WorkoutSetRecord],
        targetReps: Int = 10
    ) -> AutoProgressionRecommendation? {
        let completed = sets.filter { $0.isCompleted && !$0.isWarmup }
        guard !completed.isEmpty else { return nil }

        let currentWeight = completed.last?.weightKg ?? 0.0
        let rpeValues = completed.compactMap { $0.rpe }
        let avgRPE = rpeValues.isEmpty ? 8.0 : (rpeValues.reduce(0, +) / Double(rpeValues.count))
        let isTimeBased = completed.contains { $0.isTimeBased }

        // 1. Bodyweight & Eigengewicht / Isometrie Progression (Weight == 0)
        if currentWeight == 0 {
            let norm = exerciseName.lowercased()
            let nextLevel: String
            if norm.contains("mcgill") && norm.contains("curl") {
                nextLevel = "Hollow Body Hold Progression"
            } else if norm.contains("side plank") {
                nextLevel = "Star Plank (Bein angehoben auf Fuessen)"
            } else if norm.contains("plank") || norm.contains("unterarmstuetz") {
                nextLevel = "RKC Plank (Maximale Ganzkoerperspannung)"
            } else if norm.contains("deadbug") {
                nextLevel = "Deadbug mit Druck & gestreckten Beinen"
            } else if norm.contains("liegestuetz") || norm.contains("push") {
                nextLevel = "Diamant-Liegestuetze / Defizit-Push-ups"
            } else if norm.contains("klimmzug") || norm.contains("pull") {
                nextLevel = "L-Sit Chin-ups / Brust-Klimmzuege"
            } else {
                nextLevel = isTimeBased ? "+15s Haltedauer" : "+3 Wiederholungen"
            }

            if avgRPE <= 6.5 {
                return AutoProgressionRecommendation(
                    exerciseId: exerciseId,
                    exerciseName: exerciseName,
                    currentWeightKg: 0.0,
                    recommendedWeightKg: 0.0,
                    deltaKg: 0.0,
                    averageRPE: avgRPE,
                    rationale: "RPE @\(String(format: "%.1f", avgRPE)) signalisiert deutliche Unterforderung (>= 3 RIR). Biomechanische Steigerung auf '\(nextLevel)' empfohlen, um echten Hypertrophiereiz zu setzen.",
                    actionBadge: "Progression: \(nextLevel)",
                    isProgressionAvailable: true
                )
            } else if avgRPE >= 9.5 {
                return AutoProgressionRecommendation(
                    exerciseId: exerciseId,
                    exerciseName: exerciseName,
                    currentWeightKg: 0.0,
                    recommendedWeightKg: 0.0,
                    deltaKg: 0.0,
                    averageRPE: avgRPE,
                    rationale: "Maximale Rumpf-Ermuedung bei RPE @\(String(format: "%.1f", avgRPE)). Haltedauer / Ausfuehrung konsolidieren.",
                    actionBadge: "Level konsolidieren",
                    isProgressionAvailable: false
                )
            } else {
                return AutoProgressionRecommendation(
                    exerciseId: exerciseId,
                    exerciseName: exerciseName,
                    currentWeightKg: 0.0,
                    recommendedWeightKg: 0.0,
                    deltaKg: 0.0,
                    averageRPE: avgRPE,
                    rationale: "Optimaler Reizbereich RPE @\(String(format: "%.1f", avgRPE)). Ausfuehrungsqualitaet stabilisieren.",
                    actionBadge: "Reiz stabil",
                    isProgressionAvailable: false
                )
            }
        }

        // 2. Progression mit Zusatzgewicht / Hanteln (Weight > 0)
        let allMetReps = completed.allSatisfy { $0.reps >= targetReps }

        if allMetReps && avgRPE <= 8.0 {
            return AutoProgressionRecommendation(
                exerciseId: exerciseId,
                exerciseName: exerciseName,
                currentWeightKg: currentWeight,
                recommendedWeightKg: currentWeight + 2.5,
                deltaKg: 2.5,
                averageRPE: avgRPE,
                rationale: "Ziel-Wiederholungen bei RPE <= 8 erreicht. Reiz vollstaendig adaptiert; +2,5 kg Steigerung fuer die Folgewoche empfohlen.",
                actionBadge: "+2,5 kg Vorschlag",
                isProgressionAvailable: true
            )
        } else if avgRPE >= 10.0 || !allMetReps {
            return AutoProgressionRecommendation(
                exerciseId: exerciseId,
                exerciseName: exerciseName,
                currentWeightKg: currentWeight,
                recommendedWeightKg: currentWeight,
                deltaKg: 0.0,
                averageRPE: avgRPE,
                rationale: "Maximale Ausbelastung bei RPE 10. Gewicht fuer die Folgewoche beibehalten zur Konsolidierung.",
                actionBadge: "Gewicht beibehalten",
                isProgressionAvailable: false
            )
        } else {
            return AutoProgressionRecommendation(
                exerciseId: exerciseId,
                exerciseName: exerciseName,
                currentWeightKg: currentWeight,
                recommendedWeightKg: currentWeight,
                deltaKg: 0.0,
                averageRPE: avgRPE,
                rationale: "Schwellenbereich RPE 8.5–9. Gewicht beibehalten, bis alle Saetze mit RPE <= 8 absolviert werden.",
                actionBadge: "Gewicht beibehalten",
                isProgressionAvailable: false
            )
        }
    }
}
