import Foundation
import GrowCoreCPP

// MARK: - Universal User Profile Contract (2026 Architectural Standard)
public struct UserProfileContract: Codable, Equatable, Sendable {
    public static let currentVersion = "2026.1"

    public var contractVersion: String
    public var identity: ContractIdentity
    public var clinicalSafetyGates: ClinicalSafetyGates
    public var nutritionTargets: NutritionTargets
    public var circadianSupplementSchedule: [CircadianSupplementSlot]
    public var trainingCadence: TrainingCadence

    public init(
        contractVersion: String = UserProfileContract.currentVersion,
        identity: ContractIdentity,
        clinicalSafetyGates: ClinicalSafetyGates,
        nutritionTargets: NutritionTargets,
        circadianSupplementSchedule: [CircadianSupplementSlot] = [],
        trainingCadence: TrainingCadence
    ) {
        self.contractVersion = contractVersion
        self.identity = identity
        self.clinicalSafetyGates = clinicalSafetyGates
        self.nutritionTargets = nutritionTargets
        self.circadianSupplementSchedule = circadianSupplementSchedule
        self.trainingCadence = trainingCadence
    }

    // MARK: - Sub-Entities
    public struct ContractIdentity: Codable, Equatable, Sendable {
        public var userId: String
        public var displayName: String
        public var biologicalSex: BiologicalSex
        public var age: Int
        public var heightCm: Double
        public var weightKg: Double
        public var bodyFatPct: Double?

        public init(
            userId: String,
            displayName: String,
            biologicalSex: BiologicalSex,
            age: Int,
            heightCm: Double,
            weightKg: Double,
            bodyFatPct: Double? = nil
        ) {
            self.userId = userId
            self.displayName = displayName
            self.biologicalSex = biologicalSex
            self.age = age
            self.heightCm = heightCm
            self.weightKg = weightKg
            self.bodyFatPct = bodyFatPct
        }
    }

    public enum BiologicalSex: String, Codable, Sendable {
        case male = "MALE"
        case female = "FEMALE"

        public var cAbiSexCode: Int32 {
            switch self {
            case .male: return 0
            case .female: return 1
            }
        }
    }

    public struct ClinicalSafetyGates: Codable, Equatable, Sendable {
        public var chronicConditions: [String]
        public var activeMedications: [String]
        public var biomechanicalBlacklists: [String]

        public init(
            chronicConditions: [String] = [],
            activeMedications: [String] = [],
            biomechanicalBlacklists: [String] = []
        ) {
            self.chronicConditions = chronicConditions
            self.activeMedications = activeMedications
            self.biomechanicalBlacklists = biomechanicalBlacklists
        }
    }

    public struct NutritionTargets: Codable, Equatable, Sendable {
        public var dailyCaloriesKcal: Int
        public var dailyProteinG: Int
        public var dailyHydrationMl: Int

        public init(dailyCaloriesKcal: Int, dailyProteinG: Int, dailyHydrationMl: Int) {
            self.dailyCaloriesKcal = dailyCaloriesKcal
            self.dailyProteinG = dailyProteinG
            self.dailyHydrationMl = dailyHydrationMl
        }
    }

    public struct CircadianSupplementSlot: Codable, Equatable, Sendable {
        public var timeSlot: String // e.g. "08:00", "21:00"
        public var substance: String
        public var dosage: String
        public var clinicalReason: String

        public init(timeSlot: String, substance: String, dosage: String, clinicalReason: String) {
            self.timeSlot = timeSlot
            self.substance = substance
            self.dosage = dosage
            self.clinicalReason = clinicalReason
        }
    }

    public struct TrainingCadence: Codable, Equatable, Sendable {
        public var programName: String
        public var sessionsPerWeek: Int
        public var allowedModalities: [String]
        public var rpeCeiling: Double

        public init(
            programName: String,
            sessionsPerWeek: Int,
            allowedModalities: [String],
            rpeCeiling: Double = 7.0
        ) {
            self.programName = programName
            self.sessionsPerWeek = sessionsPerWeek
            self.allowedModalities = allowedModalities
            self.rpeCeiling = rpeCeiling
        }
    }
}

// MARK: - C++20 CoreEngine Bridge for Poka-Yoke Clinical Assembly
public enum UserProfileContractAssembler {

    /// Deterministic Poka-Yoke assembly calling C++20 CoreEngine
    public static func assembleProfile(
        identity: UserProfileContract.ContractIdentity,
        conditions: [String],
        medications: [String],
        candidateSupplements: [(timeSlot: String, substance: String, dosage: String, reason: String)],
        candidateExercises: [String],
        activityMultiplier: Double = 1.35
    ) -> UserProfileContract {
        // 1. Calculate Mifflin-St Jeor TDEE deterministically in C++
        let tdee = grow_core_calculate_tdee(
            identity.biologicalSex.cAbiSexCode,
            Int32(identity.age),
            identity.weightKg,
            identity.heightCm,
            activityMultiplier
        )

        // 2. Calculate clinical protein target (Sarcopenia / Osteopenia / Age-adjusted)
        let hasBoneOrMuscleImpairment = conditions.contains { cond in
            let c = cond.uppercased()
            return c.contains("OSTEOPENIA") || c.contains("OSTEOPOROSIS") || c.contains("SARCOPENIA")
        }
        let proteinG = grow_core_calculate_target_protein(
            Int32(identity.age),
            identity.weightKg,
            hasBoneOrMuscleImpairment
        )

        // 3. Calculate baseline hydration
        let hydrationMl = grow_core_calculate_target_hydration(identity.weightKg, 0)

        // 4. Poka-Yoke Clinical Contraindication Filtering
        var safeSupplements: [UserProfileContract.CircadianSupplementSlot] = []
        for cand in candidateSupplements {
            var isBlocked = false
            for med in medications {
                let code = grow_core_screen_contraindication(med, cand.substance)
                if code != GROW_STATUS_CLEARED {
                    isBlocked = true
                    break
                }
            }
            if !isBlocked {
                safeSupplements.append(UserProfileContract.CircadianSupplementSlot(
                    timeSlot: cand.timeSlot,
                    substance: cand.substance,
                    dosage: cand.dosage,
                    clinicalReason: cand.reason
                ))
            }
        }

        // 5. Biomechanical Exercise Filtering
        var safeExercises: [String] = []
        var detectedBlacklists: [String] = []

        // Infer limitations from conditions
        var limitations = conditions
        if hasBoneOrMuscleImpairment {
            limitations.append("NO_AXIAL_SPINAL_LOADING")
            limitations.append("NO_HIGH_IMPACT_JUMPS")
            detectedBlacklists.append("NO_AXIAL_SPINAL_LOADING")
            detectedBlacklists.append("NO_HIGH_IMPACT_JUMPS")
        }

        for ex in candidateExercises {
            var exerciseSafe = true
            for lim in limitations {
                if !grow_core_is_exercise_safe(lim, ex) {
                    exerciseSafe = false
                    break
                }
            }
            if exerciseSafe {
                safeExercises.append(ex)
            }
        }

        let programTitle = hasBoneOrMuscleImpairment ? "Gelenkschonung & Knochendichte" : "Vitalitaet & Allgemeine Fitness"
        let rpeLimit = hasBoneOrMuscleImpairment ? 6.5 : 8.0

        return UserProfileContract(
            identity: identity,
            clinicalSafetyGates: UserProfileContract.ClinicalSafetyGates(
                chronicConditions: conditions,
                activeMedications: medications,
                biomechanicalBlacklists: detectedBlacklists
            ),
            nutritionTargets: UserProfileContract.NutritionTargets(
                dailyCaloriesKcal: Int(tdee),
                dailyProteinG: Int(proteinG),
                dailyHydrationMl: Int(hydrationMl)
            ),
            circadianSupplementSchedule: safeSupplements,
            trainingCadence: UserProfileContract.TrainingCadence(
                programName: programTitle,
                sessionsPerWeek: 3,
                allowedModalities: safeExercises,
                rpeCeiling: rpeLimit
            )
        )
    }
}
