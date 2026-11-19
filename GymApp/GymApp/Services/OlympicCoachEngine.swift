import Foundation
import SwiftUI

// MARK: - 1RM Formeln
public enum OneRepMaxFormula: String, CaseIterable, Identifiable, Codable {
    case brzycki = "Brzycki"
    case epley = "Epley"
    case lander = "Lander"
    case lombardi = "Lombardi"
    case oconner = "O'Conner"

    public var id: String { rawValue }

    public func calculate1RM(weightKg: Double, reps: Int) -> Double {
        guard reps > 0 && weightKg > 0 else { return 0 }
        if reps == 1 { return weightKg }

        switch self {
        case .brzycki:
            let denominator = 1.0278 - (0.0278 * Double(reps))
            return denominator > 0 ? weightKg / denominator : weightKg
        case .epley:
            return weightKg * (1.0 + 0.0333 * Double(reps))
        case .lander:
            let denominator = 101.3 - (2.67123 * Double(reps))
            return denominator > 0 ? (100.0 * weightKg) / denominator : weightKg
        case .lombardi:
            return weightKg * pow(Double(reps), 0.10)
        case .oconner:
            return weightKg * (1.0 + 0.025 * Double(reps))
        }
    }

    /// Wissenschaftlich hochpraezise, vollautonome 1RM-Formelselektion durch den Olympic Coach:
    /// - 1 Wdh: Tatsaechliches Arbeitsgewicht (1RM = Gewicht)
    /// - 2 bis 5 Wdh: Brzycki-Formel (Goldstandard fuer Maximalkraft im Niedrig-Wiederholungsbereich)
    /// - 6 bis 10 Wdh: Epley-Formel (Industrieller Praezisionsstandard fuer den Hypertrophiebereich)
    /// - 11 bis 15 Wdh: Lander-Formel (Robuste Stabilitaet fuer moderate Kraftausdauer)
    /// - 16 bis 20 Wdh: O'Conner-Formel (Konservativer linearer Anstieg fuer hoehere Wiederholungen)
    /// - > 20 Wdh: Lombardi-Formel (Exponentielle Skalierung daempft lineare Inflation ab)
    public static func autonomousFormula(for reps: Int) -> OneRepMaxFormula {
        switch reps {
        case ...5:
            return .brzycki
        case 6...10:
            return .epley
        case 11...15:
            return .lander
        case 16...20:
            return .oconner
        default:
            return .lombardi
        }
    }

    /// Autonome 1RM-Berechnung im Hintergrund ohne manuelle Intervention
    public static func autonomousCalculate1RM(weightKg: Double, reps: Int, rpe: Double? = nil) -> (value: Double, formula: OneRepMaxFormula) {
        guard reps > 0 && weightKg > 0 else { return (0.0, .epley) }

        let effectiveReps: Double
        if let rpe = rpe, rpe >= 5.0 && rpe <= 10.0 {
            let rir = 10.0 - rpe
            effectiveReps = max(1.0, Double(reps) + rir)
        } else {
            effectiveReps = Double(reps)
        }

        if effectiveReps <= 1.0 {
            return (weightKg, .brzycki)
        }

        let roundedReps = max(1, Int(effectiveReps.rounded()))
        let formula = autonomousFormula(for: roundedReps)
        let estimated = formula.calculate1RM(weightKg: weightKg, reps: roundedReps)
        return ((estimated * 10).rounded() / 10, formula)
    }

    /// Wissenschaftlich hochpraezise 1RM-Schaetzung mit autonomer Formelselektion
    public static func calculateAccurate1RM(weightKg: Double, reps: Int, rpe: Double? = nil) -> Double {
        return autonomousCalculate1RM(weightKg: weightKg, reps: reps, rpe: rpe).value
    }
}

// MARK: - Trainingszonen
public struct TrainingZoneBreakdown: Identifiable {
    public var id: String { name }
    public var name: String
    public var percentageMin: Double
    public var percentageMax: Double
    public var loadMinKg: Double
    public var loadMaxKg: Double
    public var targetRepsRange: String
    public var targetSets: Int
    public var color: Color
    public var isPeak: Bool
}

// MARK: - Trainings-Ort & Equipment Modus
public enum TrainingLocationMode: String, CaseIterable, Identifiable, Codable {
    case gymWithWeights = "Gym (Gewichte)"
    case gymBodyweight = "Gym (Bodyweight)"
    case roomBodyweight = "Stube (Ohne Gewichte)"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .gymWithWeights: return "dumbbell.fill"
        case .gymBodyweight: return "figure.gymnastics"
        case .roomBodyweight: return "bed.double.fill"
        }
    }

    public var subtitle: String {
        switch self {
        case .gymWithWeights: return "Hanteln, Kabelzug & Maschinen"
        case .gymBodyweight: return "Klimmzugstange & Calisthenics"
        case .roomBodyweight: return "Isometrische Reha, Planks & Matte"
        }
    }
}

// MARK: - Banister Impulse-Response Modell (ATL, CTL, TSB)
public struct BanisterTrainingStressMetrics {
    public var acuteTrainingLoadATL: Double   // 7-Tage akute Ermuedung
    public var chronicTrainingLoadCTL: Double // 28-Tage chronische Fitness
    public var trainingStressBalanceTSB: Double // TSB = CTL - ATL (Form / Frische)
    public var fatigueStateLabel: String
    public var fatigueStateColor: Color
    public var adaptationRecommendation: String
}

// MARK: - Israetel Volumen-Klassifikation (MEV, MAV, MRV)
public enum VolumeThresholdStatus: String, Codable {
    case belowMEV = "Unter MEV (Unterstimuliert)"
    case inMAV = "Im MAV (Optimale Hypertrophie)"
    case nearMRV = "Nahe MRV (Ermuedungslimit)"
    case overMRV = "Ueber MRV (Regenerationsdefizit)"

    public var color: Color {
        switch self {
        case .belowMEV: return Color(red: 0.96, green: 0.62, blue: 0.12)
        case .inMAV: return Color(red: 0.13, green: 0.77, blue: 0.36)
        case .nearMRV: return Color(red: 0.20, green: 0.60, blue: 0.95)
        case .overMRV: return Color(red: 0.94, green: 0.22, blue: 0.18)
        }
    }
}

public struct MuscleVolumeStatus: Identifiable {
    public var id: String { muscleName }
    public var muscleName: String
    public var currentWeeklySets: Int
    public var mevSets: Int // Minimum Effective Volume (~6)
    public var mavMinSets: Int // Maximum Adaptive Volume Min (~10)
    public var mavMaxSets: Int // Maximum Adaptive Volume Max (~18)
    public var mrvSets: Int // Maximum Recoverable Volume (~22)
    public var status: VolumeThresholdStatus
    public var daysSinceLastStimulus: Int
}

// MARK: - Biomechanische Symmetrie & Ratio (Push vs Pull)
public struct BiomechanicalBalanceRatio {
    public var pushSetsWeekly: Int
    public var pullSetsWeekly: Int
    public var pushToPullRatio: Double
    public var quadSetsWeekly: Int
    public var posteriorChainSetsWeekly: Int
    public var quadToPosteriorRatio: Double
    public var isPushDominantWarning: Bool
    public var balanceCorrectionAdvice: String
}

// MARK: - Fragebogen & Bereitschaft
public struct OlympicReadinessInput: Codable {
    public var mentalFocus: Int
    public var somaticRecovery: Int
    public var sleepQuality: Int
    public var dailyStress: Int

    public init(
        mentalFocus: Int = 4,
        somaticRecovery: Int = 4,
        sleepQuality: Int = 4,
        dailyStress: Int = 4
    ) {
        self.mentalFocus = mentalFocus
        self.somaticRecovery = somaticRecovery
        self.sleepQuality = sleepQuality
        self.dailyStress = dailyStress
    }

    public var normalizedScore: Double {
        let sum = (Double(mentalFocus) * 0.25) +
                  (Double(somaticRecovery) * 0.35) +
                  (Double(sleepQuality) * 0.25) +
                  (Double(dailyStress) * 0.15)
        return min(1.0, max(0.2, sum / 5.0))
    }

    public var statusDescription: (label: String, color: Color) {
        let s = normalizedScore
        if s >= 0.82 {
            return ("Optimal / Wettkampf-Tunnel", Color(red: 0.13, green: 0.77, blue: 0.36))
        } else if s >= 0.65 {
            return ("Solide / Leistungsfaehig", Color(red: 0.20, green: 0.60, blue: 0.95))
        } else if s >= 0.45 {
            return ("Gedaempft / Ermuedung", Color(red: 0.96, green: 0.62, blue: 0.12))
        } else {
            return ("Erschoepft / Deload indiziert", Color(red: 0.94, green: 0.22, blue: 0.18))
        }
    }
}

// MARK: - Coach Verordnung pro Uebung
public struct DynamicCoachPrescription {
    public var estimated1RM: Double
    public var estimated1RMRangeMin: Double
    public var estimated1RMRangeMax: Double
    public var formulaUsed: OneRepMaxFormula
    public var targetTrainingGoal: String
    public var prescribedWeightKg: Double
    public var prescribedReps: Int
    public var prescribedSets: Int
    public var targetRestSeconds: Int
    public var rirTarget: String
    public var coachRecommendation: String
    public var zones: [TrainingZoneBreakdown]
    public var historicalBasisSummary: String
    public var daysSinceLastTrained: Int
    public var isDeconditionedAdjustment: Bool
    public var detrainingDecayFactor: Double
    public var isBWKUlmRehaRestricted: Bool
    public var rehaSafetyDirective: String
}

// MARK: - BWK Ulm Viszeral- & Bauchwand-Reha Status
public struct BWKUlmVisceralSafetyReport {
    public var isPermitted: Bool
    public var riskLevel: String // "Sicher (Isometrisch)", "Veto (Spitzen-IAP / Flexion)"
    public var directive: String
    public var safeAlternative: String?
}

// MARK: - Supplement-Protokoll zum Training (Gemaess Rule 4)
public struct WorkoutSupplementItem: Identifiable, Codable, Equatable, Hashable {
    public var id: String { "\(timing)_\(name)" }
    public var timing: String // "Pre-Workout (16:00 Uhr)", "Post-Workout (16:45 Uhr)", "Abend / CPAP-Ruhe (21:00 Uhr)", "Morgenroutine (06:00 Uhr)"
    public var name: String
    public var dosage: String
    public var targetEffect: String
    public var isRequiredForSession: Bool
}

// MARK: - Spontane Abweichung & Praeferenz-Protokoll
public struct SpontaneousDivergenceRecord: Identifiable, Codable, Equatable {
    public var id: UUID
    public var timestamp: Date
    public var recommendedFocus: String
    public var chosenTemplateName: String
    public var chosenExerciseNames: [String]
    public var primaryTargetMuscles: [String]
    public var systemicReadinessAtStart: Double
    public var banisterTSBAtStart: Double
    public var adaptationAppliedSummary: String

    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        recommendedFocus: String,
        chosenTemplateName: String,
        chosenExerciseNames: [String] = [],
        primaryTargetMuscles: [String] = [],
        systemicReadinessAtStart: Double = 0.8,
        banisterTSBAtStart: Double = 0.0,
        adaptationAppliedSummary: String = ""
    ) {
        self.id = id
        self.timestamp = timestamp
        self.recommendedFocus = recommendedFocus
        self.chosenTemplateName = chosenTemplateName
        self.chosenExerciseNames = chosenExerciseNames
        self.primaryTargetMuscles = primaryTargetMuscles
        self.systemicReadinessAtStart = systemicReadinessAtStart
        self.banisterTSBAtStart = banisterTSBAtStart
        self.adaptationAppliedSummary = adaptationAppliedSummary
    }
}

public struct UserExercisePreferenceProfile: Codable, Equatable {
    public var exerciseSelectionFrequencies: [String: Int]
    public var muscleGroupAffinities: [String: Double]
    public var totalDeviationsCount: Int
    public var totalSessionsCount: Int
    public var preferredEquipmentStyle: String
    public var divergenceHistory: [SpontaneousDivergenceRecord]
    public var muscleDistressDampers: [String: Double]
    public var muscleDistressTimestamps: [String: Date]

    public init(
        exerciseSelectionFrequencies: [String: Int] = [:],
        muscleGroupAffinities: [String: Double] = [:],
        totalDeviationsCount: Int = 0,
        totalSessionsCount: Int = 0,
        preferredEquipmentStyle: String = "Hybrid",
        divergenceHistory: [SpontaneousDivergenceRecord] = [],
        muscleDistressDampers: [String: Double] = [:],
        muscleDistressTimestamps: [String: Date] = [:]
    ) {
        self.exerciseSelectionFrequencies = exerciseSelectionFrequencies
        self.muscleGroupAffinities = muscleGroupAffinities
        self.totalDeviationsCount = totalDeviationsCount
        self.totalSessionsCount = totalSessionsCount
        self.preferredEquipmentStyle = preferredEquipmentStyle
        self.divergenceHistory = divergenceHistory
        self.muscleDistressDampers = muscleDistressDampers
        self.muscleDistressTimestamps = muscleDistressTimestamps
    }
}

// MARK: - Ganzkoerper-Skelett- & Muskelketten-Symmetrie
public struct SkeletalMusculatureSymmetryReport: Identifiable, Codable, Equatable {
    public var id: UUID
    public var evaluatedAt: Date
    public var upperBodyWeeklySets: Int
    public var lowerBodyWeeklySets: Int
    public var upperToLowerRatio: Double
    public var pushSetsWeekly: Int
    public var pullSetsWeekly: Int
    public var pushToPullRatio: Double
    public var anteriorChainSets: Int
    public var posteriorChainSets: Int
    public var anteriorToPosteriorRatio: Double
    public var structuralFrictionIndex: Double
    public var isUpperDominantFrictionDetected: Bool
    public var dominantChainsSummary: String
    public var laggingChainsSummary: String
    public var kineticBottlenecks: [String]
    public var biomechanicalCorrectionDirective: String

    public init(
        id: UUID = UUID(),
        evaluatedAt: Date = Date(),
        upperBodyWeeklySets: Int = 0,
        lowerBodyWeeklySets: Int = 0,
        upperToLowerRatio: Double = 1.0,
        pushSetsWeekly: Int = 0,
        pullSetsWeekly: Int = 0,
        pushToPullRatio: Double = 1.0,
        anteriorChainSets: Int = 0,
        posteriorChainSets: Int = 0,
        anteriorToPosteriorRatio: Double = 1.0,
        structuralFrictionIndex: Double = 0.0,
        isUpperDominantFrictionDetected: Bool = false,
        dominantChainsSummary: String = "Ausgeglichen",
        laggingChainsSummary: String = "Keine",
        kineticBottlenecks: [String] = [],
        biomechanicalCorrectionDirective: String = "Symmetrie im Normbereich"
    ) {
        self.id = id
        self.evaluatedAt = evaluatedAt
        self.upperBodyWeeklySets = upperBodyWeeklySets
        self.lowerBodyWeeklySets = lowerBodyWeeklySets
        self.upperToLowerRatio = upperToLowerRatio
        self.pushSetsWeekly = pushSetsWeekly
        self.pullSetsWeekly = pullSetsWeekly
        self.pushToPullRatio = pushToPullRatio
        self.anteriorChainSets = anteriorChainSets
        self.posteriorChainSets = posteriorChainSets
        self.anteriorToPosteriorRatio = anteriorToPosteriorRatio
        self.structuralFrictionIndex = structuralFrictionIndex
        self.isUpperDominantFrictionDetected = isUpperDominantFrictionDetected
        self.dominantChainsSummary = dominantChainsSummary
        self.laggingChainsSummary = laggingChainsSummary
        self.kineticBottlenecks = kineticBottlenecks
        self.biomechanicalCorrectionDirective = biomechanicalCorrectionDirective
    }
}

// MARK: - Autoregulierte Spontan-Anpassung (JARVIS Engine)
public struct AdaptedWorkoutPrescription: Identifiable, Equatable {
    public var id: UUID
    public var originalTemplateId: UUID?
    public var sessionTitle: String
    public var isSpontaneousDivergence: Bool
    public var targetVolumeSets: Int
    public var volumeModifierPercent: Double
    public var targetRIRRange: String
    public var adaptedExercises: [AdaptedExerciseItem]
    public var correctivePrimingExercises: [AdaptedExerciseItem]
    public var coachDirectiveBadge: String
    public var coachDirectiveExplanation: String

    public init(
        id: UUID = UUID(),
        originalTemplateId: UUID? = nil,
        sessionTitle: String,
        isSpontaneousDivergence: Bool = false,
        targetVolumeSets: Int = 0,
        volumeModifierPercent: Double = 0.0,
        targetRIRRange: String = "RIR 1-2",
        adaptedExercises: [AdaptedExerciseItem] = [],
        correctivePrimingExercises: [AdaptedExerciseItem] = [],
        coachDirectiveBadge: String = "Standard",
        coachDirectiveExplanation: String = ""
    ) {
        self.id = id
        self.originalTemplateId = originalTemplateId
        self.sessionTitle = sessionTitle
        self.isSpontaneousDivergence = isSpontaneousDivergence
        self.targetVolumeSets = targetVolumeSets
        self.volumeModifierPercent = volumeModifierPercent
        self.targetRIRRange = targetRIRRange
        self.adaptedExercises = adaptedExercises
        self.correctivePrimingExercises = correctivePrimingExercises
        self.coachDirectiveBadge = coachDirectiveBadge
        self.coachDirectiveExplanation = coachDirectiveExplanation
    }

    public struct AdaptedExerciseItem: Identifiable, Equatable {
        public var id: UUID
        public var exercise: Exercise
        public var prescribedSets: Int
        public var prescribedReps: Int
        public var prescribedWeightKg: Double
        public var targetRIR: String
        public var restSeconds: Int
        public var adaptationReason: String
        public var isCorrectivePrimer: Bool

        public init(
            id: UUID = UUID(),
            exercise: Exercise,
            prescribedSets: Int = 3,
            prescribedReps: Int = 10,
            prescribedWeightKg: Double = 0.0,
            targetRIR: String = "RIR 1-2",
            restSeconds: Int = 90,
            adaptationReason: String = "",
            isCorrectivePrimer: Bool = false
        ) {
            self.id = id
            self.exercise = exercise
            self.prescribedSets = prescribedSets
            self.prescribedReps = prescribedReps
            self.prescribedWeightKg = prescribedWeightKg
            self.targetRIR = targetRIR
            self.restSeconds = restSeconds
            self.adaptationReason = adaptationReason
            self.isCorrectivePrimer = isCorrectivePrimer
        }
    }
}

// MARK: - Tages-Verordnung & Autonome Planung
public struct DailyWorkoutRecommendation: Identifiable {
    public var id: String { templateId ?? "daily_recommendation" }
    public var isAlreadyCompletedToday: Bool
    public var completedWorkoutTitle: String?
    public var recommendedFocus: String
    public var rationale: String
    public var templateId: String?
    public var templateName: String?
    public var targetVolumeSets: Int
    public var readinessScore: Double
    public var readinessLabel: String
    public var preWorkoutNutritionalCheck: String
    public var laggingMuscles: [String]
    public var recoveryStateSummary: String
    public var banisterMetrics: BanisterTrainingStressMetrics
    public var pushPullBalance: BiomechanicalBalanceRatio
    public var supplementProtocol: [WorkoutSupplementItem]
    public var skeletalSymmetry: SkeletalMusculatureSymmetryReport?
    public var learnedPreferencesSummary: String?

    public init(
        isAlreadyCompletedToday: Bool,
        completedWorkoutTitle: String? = nil,
        recommendedFocus: String,
        rationale: String,
        templateId: String? = nil,
        templateName: String? = nil,
        targetVolumeSets: Int,
        readinessScore: Double,
        readinessLabel: String,
        preWorkoutNutritionalCheck: String,
        laggingMuscles: [String] = [],
        recoveryStateSummary: String,
        banisterMetrics: BanisterTrainingStressMetrics,
        pushPullBalance: BiomechanicalBalanceRatio,
        supplementProtocol: [WorkoutSupplementItem],
        skeletalSymmetry: SkeletalMusculatureSymmetryReport? = nil,
        learnedPreferencesSummary: String? = nil
    ) {
        self.isAlreadyCompletedToday = isAlreadyCompletedToday
        self.completedWorkoutTitle = completedWorkoutTitle
        self.recommendedFocus = recommendedFocus
        self.rationale = rationale
        self.templateId = templateId
        self.templateName = templateName
        self.targetVolumeSets = targetVolumeSets
        self.readinessScore = readinessScore
        self.readinessLabel = readinessLabel
        self.preWorkoutNutritionalCheck = preWorkoutNutritionalCheck
        self.laggingMuscles = laggingMuscles
        self.recoveryStateSummary = recoveryStateSummary
        self.banisterMetrics = banisterMetrics
        self.pushPullBalance = pushPullBalance
        self.supplementProtocol = supplementProtocol
        self.skeletalSymmetry = skeletalSymmetry
        self.learnedPreferencesSummary = learnedPreferencesSummary
    }
}

// MARK: - Olympic Coach Engine Singleton
@MainActor
public final class OlympicCoachEngine {
    public static let shared = OlympicCoachEngine()

    public var tuningMatrix: CoachTuningMatrix = CoachTuningMatrix()

    private init() {}

    // MARK: - 1. Banister Impulse-Response Modell (ATL / CTL / TSB)
    public func calculateBanisterMetrics(sessionsHistory: [WorkoutSession]) -> BanisterTrainingStressMetrics {
        let calendar = Calendar.current
        let today = Date()

        let atlDecayDays = max(1.0, tuningMatrix.banister.atl_decay_days)
        let ctlDecayDays = max(1.0, tuningMatrix.banister.ctl_decay_days)

        var atlSum = 0.0
        var ctlSum = 0.0

        for session in sessionsHistory {
            let days = Double(max(0, calendar.dateComponents([.day], from: session.startTime, to: today).day ?? 0))
            if days > 42 { continue }

            // Session TRIMP Stress Score: Tonnage (kg) * (RPE / 10.0) * (duration / 60)
            let sessionTonnage = session.totalTonnageKg
            let rpeFactor = Double(max(4, min(10, session.perceivedExertionRPE))) / 10.0
            let durationFactor = Double(max(20, min(120, session.durationMinutes))) / 60.0
            let sessionStress = (sessionTonnage / 100.0) * rpeFactor * durationFactor

            // Exponential Decay mit entkoppelten Hyperparametern
            let atlDecay = exp(-days / atlDecayDays)
            atlSum += sessionStress * atlDecay

            let ctlDecay = exp(-days / ctlDecayDays)
            ctlSum += sessionStress * ctlDecay
        }

        // Feld-Dienst Imputation (Bundeswehr-Feld-Resilienz):
        // Wenn Schritte > 12.000 (Marsch / Truppenuebungsplatz) an trainingsfreien Tagen vorliegen,
        // wird ein TRIMP_Dienst eingepreist, damit CTL nicht kuenstlich einbricht.
        let todaySteps = HealthKitService.shared.todaySteps
        if todaySteps >= tuningMatrix.field_duty.duty_step_threshold {
            let hasSessionToday = sessionsHistory.contains { calendar.isDate($0.startTime, inSameDayAs: today) }
            if !hasSessionToday {
                let stepDelta = Double(todaySteps - 8000) / 1000.0
                let dutyStress = max(10.0, stepDelta * tuningMatrix.field_duty.trimp_multiplier)
                atlSum += dutyStress
                ctlSum += dutyStress
            }
        }

        let atl = atlSum / atlDecayDays
        let ctl = ctlSum / ctlDecayDays
        let tsb = ctl - atl

        let label: String
        let color: Color
        let note: String

        let deloadThreshold = tuningMatrix.banister.tsb_deload_threshold

        if tsb >= 5.0 {
            label = "Superkompensation / Peak"
            color = Color(red: 0.13, green: 0.77, blue: 0.36)
            note = "Hohe Frische & ZNS-Erholung. Progressives Ueberlastungsfenster aktiv (+2.5 kg Last oder Zusatzsatz)."
        } else if tsb >= -15.0 {
            label = "Optimaler Trainingsbereich"
            color = Color(red: 0.20, green: 0.60, blue: 0.95)
            note = "Ausgeglichenes Verhaeltnis zwischen Reiz und Ermuedung. Standard-Arbeitsvolumen beibehalten."
        } else if tsb >= deloadThreshold {
            label = "Akute Ermuedungs-Akkumulation"
            color = Color(red: 0.96, green: 0.62, blue: 0.12)
            note = "ZNS-Belastung akkumuliert. Saetze auf RIR 2-3 begrenzen, keine Versagenssaetze."
        } else {
            label = "Kritisches Ueberreizen (Deload)"
            color = Color(red: 0.94, green: 0.22, blue: 0.18)
            note = "Systemische Erschoepfung detektiert. Proaktiver Deload indiziert: Volumen um 40% reduzieren."
        }

        return BanisterTrainingStressMetrics(
            acuteTrainingLoadATL: atl,
            chronicTrainingLoadCTL: ctl,
            trainingStressBalanceTSB: tsb,
            fatigueStateLabel: label,
            fatigueStateColor: color,
            adaptationRecommendation: note
        )
    }

    // MARK: - 2. Israetel MEV / MAV / MRV Volumen-Engine (Anatomische Vektor-Wahrheit)
    public func calculateMuscleVolumeStatuses(sessionsHistory: [WorkoutSession]) -> [MuscleVolumeStatus] {
        let calendar = Calendar.current
        let today = Date()

        let weekSessions = sessionsHistory.filter { s in
            let days = calendar.dateComponents([.day], from: s.startTime, to: today).day ?? 0
            return days <= 7
        }

        // 1. Berechne kumulative Reize via MuscleStimulusEngine
        let stimulusMap = MuscleStimulusEngine.shared.calculateCumulativeStimulus(for: weekSessions)

        // 2. Ermittle das letzte Reizdatum für jede Zone über die gesamte Historie
        var lastStimulusDates: [AnatomicalZone: Date] = [:]
        for s in sessionsHistory.sorted(by: { $0.startTime > $1.startTime }) {
            for ex in s.exercises where ex.sets.contains(where: { $0.isCompleted }) {
                let (prim, sec) = MuscleStimulusEngine.shared.resolveZones(for: ex.exercise)
                for z in prim + sec {
                    if lastStimulusDates[z] == nil {
                        lastStimulusDates[z] = s.startTime
                    }
                }
            }
        }

        // 3. Fasse die 16 anatomischen Zonen in die 8 biomechanischen Hauptgruppen für MEV/MAV/MRV zusammen
        struct GroupDef {
            let name: String
            let zones: [AnatomicalZone]
            let mev: Int
            let mavMin: Int
            let mavMax: Int
            let mrv: Int
        }

        let groups: [GroupDef] = [
            GroupDef(name: "Brust", zones: [.chest], mev: 6, mavMin: 10, mavMax: 16, mrv: 20),
            GroupDef(name: "Latissimus & Oberer Ruecken", zones: [.lats], mev: 8, mavMin: 12, mavMax: 18, mrv: 22),
            GroupDef(name: "Schultern & Nacken", zones: [.frontDelts, .rearDelts, .traps], mev: 6, mavMin: 10, mavMax: 18, mrv: 22),
            GroupDef(name: "Quadrizeps", zones: [.quads], mev: 6, mavMin: 10, mavMax: 16, mrv: 20),
            GroupDef(name: "Beinbeuger & Gluteus", zones: [.hamstrings, .glutes], mev: 6, mavMin: 10, mavMax: 16, mrv: 20),
            GroupDef(name: "Waden", zones: [.calvesAnterior, .calvesPosterior], mev: 6, mavMin: 8, mavMax: 14, mrv: 18),
            GroupDef(name: "Rumpf & Core (BWK Reha)", zones: [.abdominals, .obliques, .lowerBack], mev: 6, mavMin: 10, mavMax: 16, mrv: 20),
            GroupDef(name: "Arme (Bizeps & Trizeps)", zones: [.biceps, .triceps, .forearms], mev: 6, mavMin: 10, mavMax: 16, mrv: 20)
        ]

        return groups.map { grp in
            let totalSets = grp.zones.reduce(0) { $0 + (stimulusMap[$1]?.totalSets ?? 0) }

            // Finde das kürzeste Intervall seit letztem Reiz innerhalb der Zonen
            let daysSince: Int = grp.zones.compactMap { z -> Int? in
                guard let d = lastStimulusDates[z] else { return nil }
                return max(0, calendar.dateComponents([.day], from: d, to: today).day ?? 0)
            }.min() ?? 999

            let status: VolumeThresholdStatus
            if totalSets < grp.mev {
                status = .belowMEV
            } else if totalSets <= grp.mavMax {
                status = .inMAV
            } else if totalSets <= grp.mrv {
                status = .nearMRV
            } else {
                status = .overMRV
            }

            return MuscleVolumeStatus(
                muscleName: grp.name,
                currentWeeklySets: totalSets,
                mevSets: grp.mev,
                mavMinSets: grp.mavMin,
                mavMaxSets: grp.mavMax,
                mrvSets: grp.mrv,
                status: status,
                daysSinceLastStimulus: daysSince
            )
        }.sorted { $0.currentWeeklySets < $1.currentWeeklySets }
    }

    // MARK: - 3. Biomechanische Symmetrie & Push/Pull Balance (Anatomische Vektor-Wahrheit)
    public func calculateBiomechanicalBalance(sessionsHistory: [WorkoutSession]) -> BiomechanicalBalanceRatio {
        let calendar = Calendar.current
        let today = Date()
        let weekSessions = sessionsHistory.filter { s in
            let days = calendar.dateComponents([.day], from: s.startTime, to: today).day ?? 0
            return days <= 7
        }

        let stimulusMap = MuscleStimulusEngine.shared.calculateCumulativeStimulus(for: weekSessions)

        // Push: Brust, Vordere Schultern, Trizeps
        let pushSets = (stimulusMap[.chest]?.totalSets ?? 0) +
                       (stimulusMap[.frontDelts]?.totalSets ?? 0) +
                       (stimulusMap[.triceps]?.totalSets ?? 0)

        // Pull: Latissimus, Hintere Schultern, Trapez/Nacken, Bizeps
        let pullSets = (stimulusMap[.lats]?.totalSets ?? 0) +
                       (stimulusMap[.rearDelts]?.totalSets ?? 0) +
                       (stimulusMap[.traps]?.totalSets ?? 0) +
                       (stimulusMap[.biceps]?.totalSets ?? 0)

        // Quads: Vorderseite Oberschenkel
        let quadSets = stimulusMap[.quads]?.totalSets ?? 0

        // Posterior Chain: Beinbeuger, Gluteus, Unterer Ruecken
        let posteriorSets = (stimulusMap[.hamstrings]?.totalSets ?? 0) +
                            (stimulusMap[.glutes]?.totalSets ?? 0) +
                            (stimulusMap[.lowerBack]?.totalSets ?? 0)

        let pushPullRatio = pullSets > 0 ? Double(pushSets) / Double(pullSets) : (pushSets > 0 ? 2.0 : 1.0)
        let quadPostRatio = posteriorSets > 0 ? Double(quadSets) / Double(posteriorSets) : (quadSets > 0 ? 2.0 : 1.0)
        let isPushDominant = pushPullRatio > 1.30

        let advice: String
        if isPushDominant {
            advice = "Push-Ueberhang (\(String(format: "%.1f", pushPullRatio)):1) detektiert. Erhoehung der Zug- und Ruderuebungen zur Vermeidung von Schulter-Impingement empfohlen."
        } else if quadPostRatio > 1.40 {
            advice = "Quadrizeps-Dominanz (\(String(format: "%.1f", quadPostRatio)):1). Priorisiere hintere Kette (Gluteus & Ischios) zur Knie- und Beckenstabilisation."
        } else {
            advice = "Biomechanische Push/Pull- und Beuger/Strecker-Symmetrie im optimalen Bereich."
        }

        return BiomechanicalBalanceRatio(
            pushSetsWeekly: pushSets,
            pullSetsWeekly: pullSets,
            pushToPullRatio: pushPullRatio,
            quadSetsWeekly: quadSets,
            posteriorChainSetsWeekly: posteriorSets,
            quadToPosteriorRatio: quadPostRatio,
            isPushDominantWarning: isPushDominant,
            balanceCorrectionAdvice: advice
        )
    }

    // MARK: - 4. Mujika & Padilla Nicht-lineare Detraining-Kurve
    public func calculateDetrainingDecay(daysSinceLastTrained: Int) -> (decayFactor: Double, setsModifier: Int, note: String, isDeconditioned: Bool) {
        if daysSinceLastTrained <= 5 {
            // Tag 0-5: 100% neuronale Rekrutierung, Superkompensation
            return (1.00, 0, "Optimale neuronale Frische. Volles Lastpotenzial.", false)
        } else if daysSinceLastTrained <= 10 {
            // Tag 6-10: Geringer Abfall (-3%), Last bleibt stabil
            return (0.97, 0, "6-10 Tage Trainingsabstand. Gewicht stabil halten, saubere Form forcieren.", false)
        } else if daysSinceLastTrained <= 20 {
            // Tag 11-20: Milder zellulaerer Wasser- & Glykogenabfall (-10%)
            return (0.90, -1, "11-20 Tage Trainingspause. Re-Kalibrierung auf 90% Baseline (-1 Satz) zur Vermeidung von Muskelkater-Spitzen.", true)
        } else {
            // Tag 21+: Strukturelles Re-Entry-Protokoll (72% Last, 2 Saetze)
            return (0.72, -2, "Inaktivitaet > 21 Tage. Re-Entry-Baseline aktiv (72% Last, maximal 2 Arbeitssaetze, RIR 3-4).", true)
        }
    }

    // MARK: - 5. Multi-Sensor-Readiness Synthese (ZNS, Banister TSB, MPS-Refill)
    public func calculateBackgroundReadiness(
        sessionsHistory: [WorkoutSession],
        growcerySync: GrowcerySyncState? = nil
    ) -> (score: Double, label: String, summary: String) {
        var baseScore = 0.82

        let syncState = growcerySync ?? GrowcerySyncService.shared.syncState

        // A. Banister TSB Integration
        let banister = calculateBanisterMetrics(sessionsHistory: sessionsHistory)
        if banister.trainingStressBalanceTSB >= 5.0 {
            baseScore += 0.08
        } else if banister.trainingStressBalanceTSB < -25.0 {
            baseScore -= 0.18
        }

        // B. Growcery & HealthKit Protein- & Kaloriensaettigung
        let proteinConsumed = max(syncState.proteinConsumedGrams, HealthKitService.shared.todayProteinGrams)
        let proteinTarget = max(syncState.proteinTargetGrams, 160.0)
        let proteinRatio = proteinConsumed / proteinTarget
        if proteinRatio < 0.60 {
            baseScore -= 0.10 // Mangelnde Aminosaeurenverfuegbarkeit hemmt MPS
        } else if proteinRatio >= 0.90 {
            baseScore += 0.05
        }

        // C. Live Kardiologie & HealthKit Vitaldaten
        let rhr = HealthKitService.shared.restingHeartRate
        if rhr > 65 {
            baseScore -= 0.12 // Erhoehter Ruhepuls: Parasympathikus-Daempfung / autonome Ermuedung
        } else if rhr > 0 && rhr <= 50 {
            baseScore += 0.05 // Tiefer Ruhepuls: Hohe kardiovaskulaere Erholung
        }

        let burnKcal = HealthKitService.shared.activeEnergyBurnedToday
        if burnKcal > 750.0 {
            baseScore -= 0.08 // Hohe metabolische Vorbelastung am heutigen Tag
        }

        let finalScore = min(1.0, max(0.20, baseScore))
        let label: String
        let summary: String

        if finalScore >= 0.85 {
            label = "Optimal / Superkompensation"
            summary = "ZNS im Bestbereich (\(banister.fatigueStateLabel)). Volle Freigabe fuer progressive Ueberlastung (+2.5 kg)."
        } else if finalScore >= 0.68 {
            label = "Solide / Leistungsfaehig"
            summary = "Stabile Belastungsverarbeitung (\(banister.fatigueStateLabel)). Geplantes Arbeitsvolumen beibehalten."
        } else if finalScore >= 0.45 {
            label = "Gedaempft / Ermuedungs-Akkumulation"
            summary = "ZNS-Ermuedung detektiert. Autoregulierte Lastreduktion (-5% bis -10%). Saetze auf RIR 2-3 begrenzen."
        } else {
            label = "Erschoepft / Proaktiver Deload"
            summary = "Systemisches Regenerationsdefizit (\(banister.fatigueStateLabel)). Deload aktiv: Volumen um 40% reduzieren."
        }

        return (finalScore, label, summary)
    }

    // MARK: - 6. BWK Ulm Viszeral- & Bauchwand-Reha Validierung
    public func validateBWKUlmRehaSafety(exercise: Exercise) -> BWKUlmVisceralSafetyReport {
        let name = exercise.name.lowercased()
        let notes = exercise.executionNotes.lowercased()

        // Absolute Kontraindikation gemaess BWK Ulm Reha: Crunches & Sit-ups
        if name.contains("crunch") || name.contains("sit-up") || name.contains("situp") || name.contains("ab wheel") || notes.contains("crunch") {
            return BWKUlmVisceralSafetyReport(
                isPermitted: false,
                riskLevel: "Veto (Kritischer IAP-Peak / LWS-Flexion)",
                directive: "BWK Ulm Reha Veto: Crunches & Sit-ups sind postoperativ strikt verboten zur Vermeidung intraabdominalen Drucks. Rumpfstabilisation ausschliesslich isometrisch ausfuehren.",
                safeAlternative: "Plank / Pallof Press / Bird-Dog"
            )
        }

        // Erlaubte funktionelle Rumpfstabilisation
        if name.contains("plank") || name.contains("pallof") || name.contains("bird") || name.contains("deadbug") || name.contains("bridge") {
            return BWKUlmVisceralSafetyReport(
                isPermitted: true,
                riskLevel: "Sicher (Isometrische Rumpfstabilisation)",
                directive: "BWK Ulm Reha konform: Isometrische Bauchwand- & Beckenbodenentlastung.",
                safeAlternative: nil
            )
        }

        return BWKUlmVisceralSafetyReport(
            isPermitted: true,
            riskLevel: "Sicher (Standard Hypertrophie)",
            directive: "Standard-Biomechanik aktiv. Auf neutrale LWS und gleichmaessige Atmung achten.",
            safeAlternative: nil
        )
    }

    // MARK: - 7. Dynamic Olympic Coach Algorithm (Prescription per Exercise)
    public func prescribeWorkout(
        exercise: Exercise,
        sessionsHistory: [WorkoutSession],
        readiness: OlympicReadinessInput? = nil,
        formula: OneRepMaxFormula = .brzycki,
        preferredGoal: String = "Volume"
    ) -> DynamicCoachPrescription {
        let pastSetsWithDates = extractPastSetsWithDates(for: exercise, in: sessionsHistory)
        let backgroundReadiness = calculateBackgroundReadiness(sessionsHistory: sessionsHistory)
        let readinessScore = readiness?.normalizedScore ?? backgroundReadiness.score
        let daysSinceLastTrained = calculateDaysSinceLastTrained(for: exercise, in: sessionsHistory)
        let rehaReport = validateBWKUlmRehaSafety(exercise: exercise)

        let bestHistoricalSet = pastSetsWithDates.map { $0.set }.max(by: {
            formula.calculate1RM(weightKg: $0.weightKg, reps: $0.reps) <
            formula.calculate1RM(weightKg: $1.weightKg, reps: $1.reps)
        })

        let baselineWeight: Double
        let baselineReps: Int
        let historicalBasis: String

        if let best = bestHistoricalSet, best.weightKg > 0 {
            baselineWeight = best.weightKg
            baselineReps = max(1, best.reps)
            historicalBasis = "Historischer Bestwert: \(String(format: "%.1f", baselineWeight)) kg x \(baselineReps) Reps"
        } else {
            baselineWeight = defaultWeight(for: exercise)
            baselineReps = max(1, exercise.defaultReps)
            historicalBasis = "Katalog-Initialwert: \(String(format: "%.0f", baselineWeight)) kg (Erster Durchlauf)"
        }

        let raw1RM = formula.calculate1RM(weightKg: baselineWeight, reps: baselineReps)
        let decay = calculateDetrainingDecay(daysSinceLastTrained: daysSinceLastTrained)
        var rounded1RM = roundToPlate(raw1RM * decay.decayFactor)

        let rangeMin = roundToPlate(rounded1RM * 0.97)
        let rangeMax = roundToPlate(rounded1RM * 1.03)
        let zones = calculateZones(oneRepMax: rounded1RM)

        // Autoregulierte Parameter
        var targetWeight: Double
        var targetReps: Int
        var targetSets: Int = max(2, exercise.defaultSets + decay.setsModifier)
        var targetRest: Int = exercise.defaultRestSeconds
        var rir = "RIR 1-2"
        var coachNote = ""

        if !rehaReport.isPermitted {
            targetWeight = 0.0
            targetReps = 0
            targetSets = 0
            rir = "VETO"
            coachNote = rehaReport.directive
        } else if decay.isDeconditioned {
            targetWeight = roundToPlate(rounded1RM * 0.65)
            targetReps = 10
            targetSets = 2
            targetRest = 100
            rir = "RIR 3-4"
            coachNote = decay.note
        } else if readinessScore >= 0.82 {
            if preferredGoal == "Strength" {
                targetWeight = roundToPlate(rounded1RM * 0.85)
                targetReps = 5
                targetSets = 4
                targetRest = 150
                rir = "RIR 1"
                coachNote = "Superkompensation aktiv. Progressives Ueberlastungsfenster (+2.5 kg). Volle explosive Kraftentfaltung."
            } else {
                targetWeight = roundToPlate(rounded1RM * 0.725)
                targetReps = 10
                targetSets = 4
                targetRest = 90
                rir = "RIR 2"
                coachNote = "Hohe metabolische Kapazitaet. Arbeitsvolumen auf 4 Saetze erhoeht. Fokus auf exzentrische Phase (3 Sek.)."
            }
        } else if readinessScore >= 0.65 {
            if preferredGoal == "Strength" {
                targetWeight = roundToPlate(rounded1RM * 0.825)
                targetReps = 5
                targetSets = 3
                targetRest = 120
                rir = "RIR 2"
                coachNote = "Solide Tagesform. Geplantes Arbeitsgewicht beibehalten. Keine erzwungenen Wiederholungen bis zum Versagen."
            } else {
                targetWeight = roundToPlate(rounded1RM * 0.70)
                targetReps = 10
                targetSets = 3
                targetRest = 90
                rir = "RIR 2"
                coachNote = "Standard-Arbeitsbereich aktiv. Kontrolliertes Tempo, Fokus auf Zielmuskelkontraktion."
            }
        } else if readinessScore >= 0.45 {
            targetWeight = roundToPlate(rounded1RM * 0.65)
            targetReps = 8
            targetSets = 3
            targetRest = 100
            rir = "RIR 3"
            coachNote = "Autoregulierte Lastreduktion (-5% Last). Geringere Gelenk- und ZNS-Belastung."
        } else {
            targetWeight = roundToPlate(rounded1RM * 0.55)
            targetReps = 12
            targetSets = 2
            targetRest = 90
            rir = "RIR 4"
            coachNote = "Proaktiver Deload: Geringe Last, Mobilitaet und BWK-Ulm konforme Stabilisation."
        }

        return DynamicCoachPrescription(
            estimated1RM: rounded1RM,
            estimated1RMRangeMin: rangeMin,
            estimated1RMRangeMax: rangeMax,
            formulaUsed: formula,
            targetTrainingGoal: preferredGoal,
            prescribedWeightKg: max(0.0, targetWeight),
            prescribedReps: targetReps,
            prescribedSets: targetSets,
            targetRestSeconds: targetRest,
            rirTarget: rir,
            coachRecommendation: coachNote,
            zones: zones,
            historicalBasisSummary: historicalBasis,
            daysSinceLastTrained: daysSinceLastTrained,
            isDeconditionedAdjustment: decay.isDeconditioned,
            detrainingDecayFactor: decay.decayFactor,
            isBWKUlmRehaRestricted: !rehaReport.isPermitted,
            rehaSafetyDirective: rehaReport.directive
        )
    }

    // MARK: - 7. Autonome Tages-Planung & Empfehlung
    public func generateDailyRecommendation(
        sessionsHistory: [WorkoutSession],
        templates: [WorkoutTemplate],
        growcerySync: GrowcerySyncState? = nil,
        locationMode: TrainingLocationMode = .gymWithWeights,
        userPreferences: UserExercisePreferenceProfile? = nil
    ) -> DailyWorkoutRecommendation {
        let calendar = Calendar.current
        let today = Date()
        let syncState = growcerySync ?? GrowcerySyncService.shared.syncState

        let completedToday = sessionsHistory.first { session in
            calendar.isDate(session.startTime, inSameDayAs: today)
        }

        let readiness = calculateBackgroundReadiness(sessionsHistory: sessionsHistory, growcerySync: syncState)
        let banister = calculateBanisterMetrics(sessionsHistory: sessionsHistory)
        let volumeStatuses = calculateMuscleVolumeStatuses(sessionsHistory: sessionsHistory)
        let pushPull = calculateBiomechanicalBalance(sessionsHistory: sessionsHistory)
        let symmetry = calculateSkeletalSymmetry(sessionsHistory: sessionsHistory)

        let understimulatedMuscles = volumeStatuses.filter { $0.status == .belowMEV }.map { $0.muscleName }

        // Nutrition context check
        let preWorkoutNote: String
        if syncState.carbsConsumedGrams < 50.0 {
            preWorkoutNote = "Pre-Workout: 30-40 g leicht verdauliche Kohlenhydrate + 500 ml Wasser + 500 mg Rote Bete / Nitrat zufuehren."
        } else {
            preWorkoutNote = "Pre-Workout: Ausreichend Glykogen & Fluessigkeit verfuegbar. Training kann starten."
        }

        let supplements = standardWorkoutSupplementProtocol()
        let prefSummary = userPreferences != nil
            ? "Stil: \(userPreferences!.preferredEquipmentStyle) • Spontan-Abweichungen: \(userPreferences!.totalDeviationsCount)"
            : nil

        if let completed = completedToday {
            return DailyWorkoutRecommendation(
                isAlreadyCompletedToday: true,
                completedWorkoutTitle: completed.title,
                recommendedFocus: "Regeneration & Anaboler Refill",
                rationale: "Heutige Einheit '\(completed.title)' erfolgreich absolviert. Zirkadianer Fokus: Post-Workout Proteinzufuhr (~40 g) & Nachtruhe/CPAP.",
                templateId: nil,
                templateName: nil,
                targetVolumeSets: completed.exercises.reduce(0) { $0 + $1.sets.filter({ $0.isCompleted }).count },
                readinessScore: readiness.score,
                readinessLabel: readiness.label,
                preWorkoutNutritionalCheck: "Post-Workout Refill abgeschlossen.",
                laggingMuscles: understimulatedMuscles,
                recoveryStateSummary: "Muskelproteinsynthese aktiv. Naechster Reiz morgen empfohlen.",
                banisterMetrics: banister,
                pushPullBalance: pushPull,
                supplementProtocol: supplements,
                skeletalSymmetry: symmetry,
                learnedPreferencesSummary: prefSummary
            )
        }

        // Zirkadiane Schutz-Verankerung (LPR & CPAP Schlaf-Sicherheit)
        let hour = calendar.component(.hour, from: today)
        let minute = calendar.component(.minute, from: today)
        let isCircadianCutoff = (hour > tuningMatrix.circadian.cutoff_hour) || (hour == tuningMatrix.circadian.cutoff_hour && minute >= tuningMatrix.circadian.cutoff_minute) || (hour < 5)

        if isCircadianCutoff {
            let rehaTemplate = templates.first(where: { $0.isBWKRehaFocused || $0.name.localizedCaseInsensitiveContains("reha") || $0.name.localizedCaseInsensitiveContains("stube") })
            return DailyWorkoutRecommendation(
                isAlreadyCompletedToday: false,
                completedWorkoutTitle: nil,
                recommendedFocus: "Parasympathische Rumpf- & Mobilitaets-Dekompression",
                rationale: "Trainingszeit nach \(tuningMatrix.circadian.cutoff_hour):\(tuningMatrix.circadian.cutoff_minute) Uhr. Zirkadianer Schutz aktiv (LPR-Refluxpraevention vor dem 3-Stunden-Fastenfenster und CPAP-Schlafsicherheit um 22:00 Uhr). Schwere Maximalkraft- und Hypertrophiebelastungen gesperrt. Umschaltung auf parasympathische Rumpf- und Mobilitaets-Dekompression (RIR \(tuningMatrix.circadian.safe_rir), Atempausen, Dehnung).",
                templateId: rehaTemplate?.id.uuidString,
                templateName: rehaTemplate?.name ?? "Parasympathische Dekompression",
                targetVolumeSets: 6,
                readinessScore: readiness.score,
                readinessLabel: "ZIRKADIANER SCHUTZ (LPR/CPAP)",
                preWorkoutNutritionalCheck: "Strikte Nahrungskarenz (LPR Fastenfenster ab 19:30). Nur stilles Wasser.",
                laggingMuscles: understimulatedMuscles,
                recoveryStateSummary: "Sympathikus-Daempfung zur Sicherung der zirkadianen Orexin/Adenosin-Dynamik.",
                banisterMetrics: banister,
                pushPullBalance: pushPull,
                supplementProtocol: [],
                skeletalSymmetry: symmetry,
                learnedPreferencesSummary: prefSummary
            )
        }

        // Intelligente Vorlagen- & Fokus-Auswahl basierend auf Modus, Volumen-Luecken & Biomechanik
        var bestTemplate: WorkoutTemplate?
        var focusTitle = ""
        var rationaleText = ""

        switch locationMode {
        case .gymWithWeights:
            if pushPull.isPushDominantWarning {
                bestTemplate = templates.first(where: { $0.name.localizedCaseInsensitiveContains("pull") || $0.name.localizedCaseInsensitiveContains("ruecken") })
                focusTitle = bestTemplate?.name ?? "Gym: Ruecken & Pull Fokus"
                rationaleText = "Kompensation von Push-Ueberhang (\(String(format: "%.1f", pushPull.pushToPullRatio)):1). Fokus auf oberen Ruecken und Schulterblatt-Retraktoren mit Hanteln/Kabelzug."
            } else if symmetry.isUpperDominantFrictionDetected {
                // If Upper Body is heavily dominant, recommend lower chain to fix the kinetic bottleneck
                bestTemplate = templates.first(where: {
                    let n = $0.name.lowercased()
                    return (n.contains("leg") || n.contains("bein") || n.contains("squat") || n.contains("unterkoerper")) && !$0.isBWKRehaFocused
                }) ?? templates.first(where: { !$0.isBWKRehaFocused })
                focusTitle = bestTemplate?.name ?? "Gym: Unterkoerper & Kinetischer Ausgleich"
                rationaleText = "Skelett-Symmetrie zeigt Oberkoerper-Ueberhang (\(String(format: "%.1f", symmetry.upperToLowerRatio)):1). Kinetischer Fortschritts-Flaschenhals liegt in den Beinen. Autoregulierte Einheit zur Beseitigung der Asymmetrie."
            } else if !understimulatedMuscles.isEmpty {
                for t in templates where !t.isBWKRehaFocused {
                    let stimulusMap = MuscleStimulusEngine.shared.calculateStimulus(for: t)
                    let hitsUnderstimulated = stimulusMap.keys.contains { understimulatedMuscles.contains($0.displayName) }
                    if hitsUnderstimulated {
                        bestTemplate = t
                        break
                    }
                }
                focusTitle = bestTemplate?.name ?? "Gym: Hypertrophie Fokus"
                rationaleText = "Fokus auf unterstimulierte Zonen (\(understimulatedMuscles.prefix(2).joined(separator: ", "))). Autoreguliertes Krafttraining im Gym."
            } else {
                bestTemplate = templates.first(where: { !$0.isBWKRehaFocused }) ?? templates.first
                focusTitle = bestTemplate?.name ?? "Gym: Ganzkoerper Grunduebungen"
                rationaleText = "Ausgeglichenes Hypertrophietraining (\(banister.fatigueStateLabel)). Volle mechanische Spannung mit Freihanteln."
            }

        case .gymBodyweight:
            bestTemplate = templates.first(where: { $0.category.localizedCaseInsensitiveContains("einsatz") || $0.name.localizedCaseInsensitiveContains("bodyweight") || $0.name.localizedCaseInsensitiveContains("calisthenics") }) ?? templates.first(where: { $0.isBWKRehaFocused })
            focusTitle = bestTemplate?.name ?? "Gym: Calisthenics & Bodyweight"
            rationaleText = "Geraete-freies Gym-Training: Klimmzuege, Dips, Koerpergewichts-Kniebeugen und funktionelle Rumpfstabilisation."

        case .roomBodyweight:
            bestTemplate = templates.first(where: { $0.isBWKRehaFocused || $0.name.localizedCaseInsensitiveContains("reha") || $0.name.localizedCaseInsensitiveContains("stube") }) ?? templates.first
            focusTitle = bestTemplate?.name ?? "Stube: Isometrische Rumpf- & BWK-Ulm Reha"
            rationaleText = "Stuben-Training ohne Gewichte: Postoperativ sichere Rumpf- & Bauchwandstabilisation (Planks, Bird-Dog, Glute Bridges, Liegestuetze)."
        }

        if HealthKitService.shared.todaySteps >= tuningMatrix.field_duty.duty_step_threshold {
            rationaleText += "\n• Bundeswehr-Felddienst aktiv (\(HealthKitService.shared.todaySteps) Schritte). Periphere Ermuedung autonom eingepreist: Submaximales RIR 2-3 zur ZNS-Schonung."
        }

        let templateName = bestTemplate?.name ?? focusTitle
        let templateId = bestTemplate?.id.uuidString

        return DailyWorkoutRecommendation(
            isAlreadyCompletedToday: false,
            completedWorkoutTitle: nil,
            recommendedFocus: focusTitle,
            rationale: rationaleText,
            templateId: templateId,
            templateName: templateName,
            targetVolumeSets: bestTemplate?.items.count ?? 4 * 3,
            readinessScore: readiness.score,
            readinessLabel: readiness.label,
            preWorkoutNutritionalCheck: preWorkoutNote,
            laggingMuscles: understimulatedMuscles,
            recoveryStateSummary: readiness.summary,
            banisterMetrics: banister,
            pushPullBalance: pushPull,
            supplementProtocol: supplements,
            skeletalSymmetry: symmetry,
            learnedPreferencesSummary: prefSummary
        )
    }

    // MARK: - Supplement-Protokoll Generator (Rule 4 Compliance)
    public func standardWorkoutSupplementProtocol() -> [WorkoutSupplementItem] {
        return [
            WorkoutSupplementItem(
                timing: "Pre-Workout (16:00 Uhr)",
                name: "Rote Bete / Nitrat-Extrakt",
                dosage: "500 mg",
                targetEffect: "NO-Vasodilatation, gesteigerter Blutfluss & Sauerstofftransport",
                isRequiredForSession: true
            ),
            WorkoutSupplementItem(
                timing: "Pre-Workout (16:00 Uhr)",
                name: "Glykogen & Hydration",
                dosage: "30-40 g Carbs + 500 ml Wasser",
                targetEffect: "Blutzucker-Stabilitaet & sofort verfuegbare ATP-Synthese",
                isRequiredForSession: true
            ),
            WorkoutSupplementItem(
                timing: "Post-Workout (16:45 Uhr)",
                name: "Omega-3 Fettsaeuren (EPA/DHA)",
                dosage: "2.000 mg",
                targetEffect: "Muskelproteinsynthese-Aktivierung & zellulaere Entzuendungshemmung",
                isRequiredForSession: true
            ),
            WorkoutSupplementItem(
                timing: "Abend / Nachtruhe (21:00 Uhr)",
                name: "Magnesium-Bisglycinat",
                dosage: "1.500 mg (200 mg elementar)",
                targetEffect: "ZNS-Dampfung, GABA-Aktivierung & CPAP-Tiefschlafqualitaet",
                isRequiredForSession: true
            ),
            WorkoutSupplementItem(
                timing: "Morgenroutine (06:00/06:30 Uhr)",
                name: "Rhodiola Rosea + Magnesium-Malat",
                dosage: "500 mg + 1.000 mg",
                targetEffect: "Dopamin-Sensibilisierung & zirkadiane Aktivierung",
                isRequiredForSession: false
            )
        ]
    }

    // MARK: - Helper Methods
    private func calculateDaysSinceLastTrained(for exercise: Exercise, in sessions: [WorkoutSession]) -> Int {
        let calendar = Calendar.current
        let today = Date()
        let exerciseNameLower = exercise.name.lowercased()

        let matchingSessions = sessions.filter { session in
            session.exercises.contains {
                $0.exercise.name.lowercased() == exerciseNameLower || $0.exercise.id == exercise.id
            }
        }.sorted(by: { $0.startTime > $1.startTime })

        guard let latest = matchingSessions.first else {
            return 999
        }

        return max(0, calendar.dateComponents([.day], from: latest.startTime, to: today).day ?? 0)
    }

    private func extractPastSetsWithDates(for exercise: Exercise, in sessions: [WorkoutSession]) -> [(set: WorkoutSetRecord, date: Date)] {
        var results: [(set: WorkoutSetRecord, date: Date)] = []
        let exerciseNameLower = exercise.name.lowercased()

        for session in sessions {
            for item in session.exercises {
                if item.exercise.name.lowercased() == exerciseNameLower ||
                   item.exercise.id == exercise.id {
                    let completed = item.sets.filter { $0.isCompleted && $0.weightKg > 0 }
                    for c in completed {
                        results.append((set: c, date: session.startTime))
                    }
                }
            }
        }
        return results
    }

    private func defaultWeight(for exercise: Exercise) -> Double {
        let name = exercise.name.lowercased()
        if name.contains("deadlift") || name.contains("kreuzheben") {
            return 80.0
        } else if name.contains("bankdruecken") || name.contains("bench") {
            return 60.0
        } else if name.contains("kniebeuge") || name.contains("squat") {
            return 70.0
        } else if name.contains("beinpresse") {
            return 120.0
        } else if name.contains("schulterdruecken") {
            return 35.0
        } else if name.contains("latzug") || name.contains("rudern") {
            return 50.0
        } else if name.contains("curl") || name.contains("seitheben") {
            return 12.5
        } else {
            return 30.0
        }
    }

    private func roundToPlate(_ val: Double) -> Double {
        return (val * 2.0).rounded() / 2.0
    }

    // MARK: - Trainingszonen-Berechnung
    public func calculateZones(oneRepMax: Double) -> [TrainingZoneBreakdown] {
        let warmUpMin = oneRepMax * 0.50
        let warmUpMax = oneRepMax * 0.60

        let volumeMin = oneRepMax * 0.65
        let volumeMax = oneRepMax * 0.75

        let strengthMin = oneRepMax * 0.80
        let strengthMax = oneRepMax * 0.90

        let peakMin = oneRepMax * 0.95
        let peakMax = oneRepMax * 1.00

        return [
            TrainingZoneBreakdown(
                name: "Warm-up",
                percentageMin: 50,
                percentageMax: 60,
                loadMinKg: warmUpMin,
                loadMaxKg: warmUpMax,
                targetRepsRange: "12-15 Reps",
                targetSets: 2,
                color: Color(red: 0.20, green: 0.60, blue: 0.95),
                isPeak: false
            ),
            TrainingZoneBreakdown(
                name: "Volume",
                percentageMin: 65,
                percentageMax: 75,
                loadMinKg: volumeMin,
                loadMaxKg: volumeMax,
                targetRepsRange: "8-12 Reps",
                targetSets: 3,
                color: Color(red: 0.15, green: 0.45, blue: 0.85),
                isPeak: false
            ),
            TrainingZoneBreakdown(
                name: "Strength",
                percentageMin: 80,
                percentageMax: 90,
                loadMinKg: strengthMin,
                loadMaxKg: strengthMax,
                targetRepsRange: "4-6 Reps",
                targetSets: 4,
                color: Color(red: 0.10, green: 0.30, blue: 0.75),
                isPeak: false
            ),
            TrainingZoneBreakdown(
                name: "Peak",
                percentageMin: 95,
                percentageMax: 100,
                loadMinKg: peakMin,
                loadMaxKg: peakMax,
                targetRepsRange: "1-3 Reps",
                targetSets: 3,
                color: Color(red: 0.94, green: 0.22, blue: 0.18),
                isPeak: true
            )
        ]
    }

    // MARK: - Export / Clipboard Formatter
    public func formattedLoadChartText(prescription: DynamicCoachPrescription) -> String {
        var text = "ESTIMATED ONE-REP MAX: \(Int(prescription.estimated1RM)) kg (Range: \(Int(prescription.estimated1RMRangeMin))-\(Int(prescription.estimated1RMRangeMax)) kg)\n"
        text += "FORMULA: \(prescription.formulaUsed.rawValue)\n"
        text += "---------------------------------------------------\n"
        text += "TRAINING ZONES:\n"
        for zone in prescription.zones {
            text += String(format: "%-10s %2.0f-%2.0f%% : %3.0f-%3.0f kg (%s)\n",
                           zone.name, zone.percentageMin, zone.percentageMax,
                           zone.loadMinKg, zone.loadMaxKg, zone.targetRepsRange)
        }
        text += "---------------------------------------------------\n"
        text += "PERCENTAGE BREAKDOWN:\n"
        let percentages: [Double] = [50, 60, 70, 80, 90, 100]
        let pLine = percentages.map { "\(Int($0))%: \(Int(prescription.estimated1RM * ($0 / 100.0))) kg" }.joined(separator: " | ")
        text += pLine + "\n"
        text += "---------------------------------------------------\n"
        text += "OLYMPIC COACH PRESCRIPTION:\n"
        text += "Last: \(String(format: "%.1f", prescription.prescribedWeightKg)) kg x \(prescription.prescribedReps) Reps (\(prescription.prescribedSets) Saetze, \(prescription.rirTarget))\n"
        text += "Pause: \(prescription.targetRestSeconds)s\n"
        text += "Guidance: \(prescription.coachRecommendation)\n"
        return text
    }

    // MARK: - Multi-Program & SafeReturn Status Synthesis
    public struct MultiProgramSystemHealthSummary {
        public var activeProgramsCount: Int
        public var overallReadinessLabel: String
        public var safeReturnAlerts: [String]
        public var combinedStrainTSB: Double
        public var systemicFatigueState: String
        public var isCollisionDetected: Bool
        public var collisionMitigationAdvice: String?

        public init(
            activeProgramsCount: Int,
            overallReadinessLabel: String,
            safeReturnAlerts: [String],
            combinedStrainTSB: Double,
            systemicFatigueState: String,
            isCollisionDetected: Bool,
            collisionMitigationAdvice: String?
        ) {
            self.activeProgramsCount = activeProgramsCount
            self.overallReadinessLabel = overallReadinessLabel
            self.safeReturnAlerts = safeReturnAlerts
            self.combinedStrainTSB = combinedStrainTSB
            self.systemicFatigueState = systemicFatigueState
            self.isCollisionDetected = isCollisionDetected
            self.collisionMitigationAdvice = collisionMitigationAdvice
        }
    }

    public func evaluateMultiProgramStatus(
        enrollments: [ProgramEnrollment],
        programs: [TrainingProgram],
        sessionsHistory: [WorkoutSession]
    ) -> MultiProgramSystemHealthSummary {
        let activeEnrs = enrollments.filter { $0.isActive }
        var alerts: [String] = []
        var activeProgs: [TrainingProgram] = []

        for enr in activeEnrs {
            if let prog = programs.first(where: { $0.id == enr.programId }) {
                activeProgs.append(prog)
                let eval = enr.evaluateSafeReturn(program: prog)
                if eval.loadReductionPercent > 0 || eval.action != .normalProgression {
                    alerts.append("\(prog.name) (Zyklus \(enr.currentCycle)): \(eval.statusTitle) - \(eval.volumeAdjustmentNotes)")
                }
            }
        }

        let banister = OlympicCoachEngine.shared.calculateBanisterMetrics(sessionsHistory: sessionsHistory)

        // Kollisionserkennung: Parallele fordernde Einheiten
        let hasStrength = activeProgs.contains(where: { $0.block == .kraftHypertrophie || $0.block == .aesthetikSymmetrie })
        let hasRunning = activeProgs.contains(where: { $0.block == .ausdauerRunning || $0.block == .bundeswehrMilFit })
        let isCollision = hasStrength && hasRunning && banister.trainingStressBalanceTSB < -15.0

        let advice: String? = isCollision
            ? "Kombinierte Belastung aus Kraft & Laufen bei negativem TSB (\(Int(banister.trainingStressBalanceTSB))). Priorisiere heute Zone-1 Ausdauer oder aktives Reha-Prehab zur ZNS-Entlastung."
            : nil

        let readiness: String
        if banister.trainingStressBalanceTSB > 5.0 {
            readiness = "PEAK PERFORMANCE (Hohe Frische)"
        } else if banister.trainingStressBalanceTSB >= -15.0 {
            readiness = "OPTIMALE ANPASSUNG (Flow-Korridor)"
        } else {
            readiness = "AKUTE ERMUEDUNG (Erholungsbedarf)"
        }

        return MultiProgramSystemHealthSummary(
            activeProgramsCount: activeEnrs.count,
            overallReadinessLabel: readiness,
            safeReturnAlerts: alerts,
            combinedStrainTSB: banister.trainingStressBalanceTSB,
            systemicFatigueState: banister.fatigueStateLabel,
            isCollisionDetected: isCollision,
            collisionMitigationAdvice: advice
        )
    }

    // MARK: - Habit- & Partial-Session Learning Engine (Abbruch- & Gewohnheits-Muster)
    public enum DropoutReason: String, Codable, CaseIterable {
        case acuteExhaustion = "Akute Erschoepfung / Laktat-Kollaps"
        case timeConstraint = "Zeitnot / Dienstliche Unterbrechung"
        case programSwitch = "Programmwechsel / Strategische Umorientierung"
        case orthopedicVisceral = "Orthopaedische oder viszerale Warnung (BWK)"
        case voluntaryRest = "Freiwilliger Teillast-Abbruch"
    }

    public struct PartialSessionRecord: Identifiable, Codable {
        public var id: UUID
        public var date: Date
        public var programId: UUID?
        public var plannedVolumeOrDistance: String
        public var achievedVolumeOrDistance: String
        public var completionPercentage: Double // z.B. 50.0%
        public var achievedPaceOrLoad: String
        public var dropoutReason: DropoutReason
        public var perceivedExertionRPE: Int
        public var daysSinceLastSession: Int

        public init(
            id: UUID = UUID(),
            date: Date = Date(),
            programId: UUID? = nil,
            plannedVolumeOrDistance: String,
            achievedVolumeOrDistance: String,
            completionPercentage: Double,
            achievedPaceOrLoad: String,
            dropoutReason: DropoutReason = .acuteExhaustion,
            perceivedExertionRPE: Int = 9,
            daysSinceLastSession: Int = 0
        ) {
            self.id = id
            self.date = date
            self.programId = programId
            self.plannedVolumeOrDistance = plannedVolumeOrDistance
            self.achievedVolumeOrDistance = achievedVolumeOrDistance
            self.completionPercentage = completionPercentage
            self.achievedPaceOrLoad = achievedPaceOrLoad
            self.dropoutReason = dropoutReason
            self.perceivedExertionRPE = perceivedExertionRPE
            self.daysSinceLastSession = daysSinceLastSession
        }
    }

    public struct HabitLearningDiagnostics {
        public var isAcuteDetrainingShockDetected: Bool
        public var habitPatternDescription: String
        public var physiologicalRootCause: String
        public var adaptiveInterventionPrescription: String
        public var recommendedPaceOrLoadCap: String
        public var suggestedBridgeWorkout: String

        public init(
            isAcuteDetrainingShockDetected: Bool,
            habitPatternDescription: String,
            physiologicalRootCause: String,
            adaptiveInterventionPrescription: String,
            recommendedPaceOrLoadCap: String,
            suggestedBridgeWorkout: String
        ) {
            self.isAcuteDetrainingShockDetected = isAcuteDetrainingShockDetected
            self.habitPatternDescription = habitPatternDescription
            self.physiologicalRootCause = physiologicalRootCause
            self.adaptiveInterventionPrescription = adaptiveInterventionPrescription
            self.recommendedPaceOrLoadCap = recommendedPaceOrLoadCap
            self.suggestedBridgeWorkout = suggestedBridgeWorkout
        }
    }

    public func analyzeHabitsAndPartialSessions(
        sessions: [WorkoutSession],
        partialRecords: [PartialSessionRecord]
    ) -> HabitLearningDiagnostics {
        // Pruefe auf Detraining-Rebound-Muster:
        // Beispiel: Tägliche 5km-Bestzeiten -> 7 Tage Pause -> Abbruch bei 2.5km mit hohem RPE
        let recentDropouts = partialRecords.sorted(by: { $0.date > $1.date })
        if let lastDropout = recentDropouts.first, lastDropout.daysSinceLastSession >= 5 && lastDropout.completionPercentage <= 60.0 {
            return HabitLearningDiagnostics(
                isAcuteDetrainingShockDetected: true,
                habitPatternDescription: "Detraining-Rebound-Schock detektiert: Nach \(lastDropout.daysSinceLastSession) Tagen Unterbrechung erfolgte ein vorzeitiger Abbruch bei \(Int(lastDropout.completionPercentage)) % der Zieldistanz (\(lastDropout.achievedVolumeOrDistance) statt \(lastDropout.plannedVolumeOrDistance)) bei RPE \(lastDropout.perceivedExertionRPE).",
                physiologicalRootCause: "Akuter Abfall des kardialen Schlagvolumens (~8 %) und Verlust der enzymatischen Laktatpufferung nach mehrtägiger Pause. Der Versuch, sofort an vorherige Spitzenzeiten anzuknuepfen, fuehrte zu fruehzeitigem metabolischem Erliegen.",
                adaptiveInterventionPrescription: "Kappung der Ziel-Pace um 15-20 %. Umstellung auf 2-stufige Re-Akkumulation mit aerober Zone-2 Stabilisierung. Keine weiteren Maximalversuche in den naechsten 48 Stunden.",
                recommendedPaceOrLoadCap: "Zone 2 (6:15 - 6:45 min/km) oder -20 % Arbeitsgewicht",
                suggestedBridgeWorkout: "Bruecken-Einheit: 3,0 km kontrollierter Dauerlauf (Zone 2) mit 4x 50m Gehpausen zur Wiederherstellung der aeroben Enzymaktivitaet."
            )
        }

        // Standard-Habit-Diagnose
        let totalDropouts = partialRecords.count
        if totalDropouts > 0 {
            return HabitLearningDiagnostics(
                isAcuteDetrainingShockDetected: false,
                habitPatternDescription: "\(totalDropouts) vorzeitige Einheitsabbrueche oder Programmwechsel registriert. Alle Teildaten fliessen kontinuierlich in den Tiefenmuskel-Index und das Banister-Ermuedungsmodell ein.",
                physiologicalRootCause: "Normale adaptive Schwankungen der vegetativen Belastbarkeit.",
                adaptiveInterventionPrescription: "Regulaere progressive Lastanpassung mit Flow-State Monitoring (+4 % bei Unterforderung, -4 % bis -8 % bei Ueberforderung).",
                recommendedPaceOrLoadCap: "Keine akute Drosselung erforderlich",
                suggestedBridgeWorkout: "Planmaessige Fortfuehrung des aktiven Programmzyklus."
            )
        }

        return HabitLearningDiagnostics(
            isAcuteDetrainingShockDetected: false,
            habitPatternDescription: "Hervorragende Trainingskonsistenz. Bisher keine ungeplanten Abbrueche oder Belastungseinbrueche registriert.",
            physiologicalRootCause: "Stabiles kardiopulmonales und neuromuskulaeres Gleichgewicht.",
            adaptiveInterventionPrescription: "Fortfuehrung der progressiven Mesozyklus-Periodisierung.",
            recommendedPaceOrLoadCap: "Standard-Vorgaben gemaess Periodisierung",
            suggestedBridgeWorkout: "Naechste regulaere Programmeinheit starten."
        )
    }

    // MARK: - 9. Ganzkoerper-Skelett- & Muskelketten-Symmetrie
    public func calculateSkeletalSymmetry(sessionsHistory: [WorkoutSession]) -> SkeletalMusculatureSymmetryReport {
        let calendar = Calendar.current
        let today = Date()
        let recentSessions = sessionsHistory.filter { s in
            let days = calendar.dateComponents([.day], from: s.startTime, to: today).day ?? 0
            return days <= 21
        }

        var upperSets = 0
        var lowerSets = 0
        var pushSets = 0
        var pullSets = 0
        var anteriorSets = 0
        var posteriorSets = 0
        var quadSets = 0
        var posteriorLegSets = 0

        for session in recentSessions {
            for item in session.exercises {
                let completedCount = item.sets.filter { $0.isCompleted }.count
                guard completedCount > 0 else { continue }
                let name = item.exercise.name.lowercased()
                let muscle = item.exercise.targetMuscle

                // Upper vs Lower
                switch muscle {
                case .chest, .back, .shoulders, .arms:
                    upperSets += completedCount
                case .legs, .glutesPosterior:
                    lowerSets += completedCount
                case .functionalCore, .lowerBack:
                    break
                default:
                    if name.contains("bench") || name.contains("pull") || name.contains("rudern") || name.contains("curl") || name.contains("lat") {
                        upperSets += completedCount
                    } else if name.contains("squat") || name.contains("leg") || name.contains("deadlift") || name.contains("bein") {
                        lowerSets += completedCount
                    }
                }

                // Push vs Pull
                if name.contains("bench") || name.contains("bankdruecken") || name.contains("brust") || name.contains("push") || name.contains("dip") || name.contains("schulterdruecken") || name.contains("press") {
                    pushSets += completedCount
                    anteriorSets += completedCount
                } else if name.contains("lat") || name.contains("rudern") || name.contains("klimmzug") || name.contains("pull") || name.contains("face pull") || name.contains("row") {
                    pullSets += completedCount
                    posteriorSets += completedCount
                }

                // Quad vs Posterior Leg
                if name.contains("squat") || name.contains("kniebeuge") || name.contains("beinpresse") || name.contains("strecker") {
                    quadSets += completedCount
                    anteriorSets += completedCount
                } else if name.contains("deadlift") || name.contains("kreuzheben") || name.contains("glute") || name.contains("beuger") || name.contains("bridge") || name.contains("hip thrust") {
                    posteriorLegSets += completedCount
                    posteriorSets += completedCount
                }
            }
        }

        let upperToLowerRatio = lowerSets > 0 ? Double(upperSets) / Double(lowerSets) : (upperSets > 0 ? 3.0 : 1.0)
        let pushToPullRatio = pullSets > 0 ? Double(pushSets) / Double(pullSets) : (pushSets > 0 ? 2.0 : 1.0)
        let anteriorToPosteriorRatio = posteriorSets > 0 ? Double(anteriorSets) / Double(posteriorSets) : 1.0

        let isUpperDominant = upperToLowerRatio > 1.60
        var bottlenecks: [String] = []

        if lowerSets < max(6, upperSets / 2) {
            bottlenecks.append("Unterkoerper (Quadrizeps & Gluteus)")
        }
        if pushToPullRatio > 1.35 {
            bottlenecks.append("Oberer Ruecken / Lat-Zug (Schulter-Impingement-Schutz)")
        } else if pushToPullRatio < 0.65 {
            bottlenecks.append("Horizontale Druckkraft (Brust)")
        }
        if posteriorLegSets < quadSets / 2 {
            bottlenecks.append("Hintere Kette (Gluteus & Ischiocrurale Muskulatur)")
        }

        let ratioDiff = max(0.0, upperToLowerRatio - 1.15)
        let pushPullDiff = abs(pushToPullRatio - 1.0)
        let rawFriction = (ratioDiff * 35.0) + (pushPullDiff * 25.0) + (bottlenecks.count > 0 ? Double(bottlenecks.count) * 15.0 : 0.0)
        let frictionIndex = min(100.0, max(0.0, rawFriction))

        let dominantSummary: String
        let laggingSummary: String
        let directive: String

        if isUpperDominant {
            dominantSummary = "Oberkoerper-Dominanz (\(upperSets) Saetze vs \(lowerSets) Saetze Beine)"
            laggingSummary = bottlenecks.joined(separator: ", ")
            directive = "Oberkoerper-Ueberhang (\(String(format: "%.1f", upperToLowerRatio)):1) detektiert. Kinetischer Fortschritts-Flaschenhals liegt in der Bein- und Beckenstabilisation. JARVIS autoreguliert kuenftige Oberkoerper-Einheiten auf RIR 2-3 und micro-dosed Kinetik-Primer fuer die Beine."
        } else if upperToLowerRatio < 0.70 {
            dominantSummary = "Unterkoerper-Dominanz (\(lowerSets) Saetze vs \(upperSets) Saetze Oberkoerper)"
            laggingSummary = "Oberkoerper (Zug & Druck)"
            directive = "Unterkoerper-Ueberhang detektiert. Priorisiere Oberkoerper-Volumen."
        } else {
            dominantSummary = "Symmetrisch (\(upperSets) Saetze Oberkoerper, \(lowerSets) Saetze Unterkoerper)"
            laggingSummary = bottlenecks.isEmpty ? "Keine signifikanten Defizite" : bottlenecks.joined(separator: ", ")
            directive = "Ganzkoerper-Skelett- und Muskelketten-Symmetrie im optimalen Bereich."
        }

        return SkeletalMusculatureSymmetryReport(
            upperBodyWeeklySets: upperSets,
            lowerBodyWeeklySets: lowerSets,
            upperToLowerRatio: upperToLowerRatio,
            pushSetsWeekly: pushSets,
            pullSetsWeekly: pullSets,
            pushToPullRatio: pushToPullRatio,
            anteriorChainSets: anteriorSets,
            posteriorChainSets: posteriorSets,
            anteriorToPosteriorRatio: anteriorToPosteriorRatio,
            structuralFrictionIndex: frictionIndex,
            isUpperDominantFrictionDetected: isUpperDominant,
            dominantChainsSummary: dominantSummary,
            laggingChainsSummary: laggingSummary,
            kineticBottlenecks: bottlenecks,
            biomechanicalCorrectionDirective: directive
        )
    }

    // MARK: - 10. Spontane Session-Adaption (JARVIS Override Engine)
    public func adaptSpontaneousSession(
        chosenTemplate: WorkoutTemplate,
        recommendation: DailyWorkoutRecommendation,
        sessionsHistory: [WorkoutSession],
        userPreferences: UserExercisePreferenceProfile,
        exercisesCatalog: [Exercise] = []
    ) -> AdaptedWorkoutPrescription {
        let isDivergence: Bool
        if let recId = recommendation.templateId, let recUUID = UUID(uuidString: recId) {
            isDivergence = (recUUID != chosenTemplate.id)
        } else {
            isDivergence = true
        }

        let symmetry = calculateSkeletalSymmetry(sessionsHistory: sessionsHistory)
        let banister = calculateBanisterMetrics(sessionsHistory: sessionsHistory)
        let backgroundReadiness = calculateBackgroundReadiness(sessionsHistory: sessionsHistory)

        var targetsDominantUpper = false
        for item in chosenTemplate.items {
            let m = item.exercise.targetMuscle
            if m == .chest || m == .back || m == .shoulders || m == .arms {
                targetsDominantUpper = true
                break
            }
        }

        var adaptedItems: [AdaptedWorkoutPrescription.AdaptedExerciseItem] = []
        var primingItems: [AdaptedWorkoutPrescription.AdaptedExerciseItem] = []
        var badge = "JARVIS Standard"
        var explanation = ""
        var targetRIR = "RIR 1-2"
        var volumeModifier = 0.0

        let now = Date()
        var hasLowerDistress = false
        for (muscle, damper) in userPreferences.muscleDistressDampers {
            if let t = userPreferences.muscleDistressTimestamps[muscle], now.timeIntervalSince(t) <= 72.0 * 3600.0 {
                let mLower = muscle.lowercased()
                if damper <= 0.60 && (mLower.contains("bein") || mLower.contains("glute") || mLower.contains("hamstring") || mLower.contains("quad")) {
                    hasLowerDistress = true
                }
            }
        }

        if hasLowerDistress {
            let mobilityPrimer = Exercise(
                name: "Becken- & Oberschenkel-Kinetik Primer (Stretching & Isometrie)",
                targetMuscle: .glutesPosterior,
                equipment: .bodyweight,
                defaultSets: 2,
                defaultReps: 12
            )
            primingItems.append(
                AdaptedWorkoutPrescription.AdaptedExerciseItem(
                    exercise: mobilityPrimer,
                    prescribedSets: 2,
                    prescribedReps: 12,
                    prescribedWeightKg: 0.0,
                    targetRIR: "RIR 4 (Sanfte Mobilisation)",
                    restSeconds: 30,
                    adaptationReason: "Autoregulierter Reha-Primer: Schmerz- und Spannungsabbau vor Belastung",
                    isCorrectivePrimer: true
                )
            )
        }

        if isDivergence && targetsDominantUpper && symmetry.isUpperDominantFrictionDetected {
            badge = "JARVIS Kinetik-Adaption: Autoreguliert"
            targetRIR = "RIR 2-3 (Submaximal)"
            volumeModifier = -0.25
            explanation = "Spontane Oberkoerper-Wahl detektiert. Da der Oberkoerper bereits dominiert (\(String(format: "%.1f", symmetry.upperToLowerRatio)):1), hat JARVIS das Volumen auf RIR 2-3 autoreguliert (-1 Satz pro Uebung), um Sehnenuenerlastung zu vermeiden, und Kinetik-Primer fuer Becken/Beine vorgeschaltet."

            let primerExercise = exercisesCatalog.first(where: {
                let n = $0.name.lowercased()
                return n.contains("glute bridge") || n.contains("pallof") || n.contains("plank")
            }) ?? Exercise(
                name: "Glute Bridge (Isometrisch)",
                targetMuscle: .glutesPosterior,
                equipment: .bodyweight,
                defaultSets: 2,
                defaultReps: 15
            )

            if !primingItems.contains(where: { $0.exercise.name == primerExercise.name }) {
                primingItems.append(
                    AdaptedWorkoutPrescription.AdaptedExerciseItem(
                        exercise: primerExercise,
                        prescribedSets: 2,
                        prescribedReps: 15,
                        prescribedWeightKg: 0.0,
                        targetRIR: "RIR 3 (Aktivierung)",
                        restSeconds: 45,
                        adaptationReason: "Kinetischer Primer: Gluteus- und Beckenaktivierung vor Zuguebungen",
                        isCorrectivePrimer: true
                    )
                )
            }

            for item in chosenTemplate.items {
                let reha = validateBWKUlmRehaSafety(exercise: item.exercise)
                let muscleKey = item.exercise.targetMuscle.rawValue
                let damper: Double
                if let t = userPreferences.muscleDistressTimestamps[muscleKey], now.timeIntervalSince(t) <= 72.0 * 3600.0 {
                    damper = userPreferences.muscleDistressDampers[muscleKey] ?? 1.0
                } else {
                    damper = 1.0
                }

                let baseSets = max(2, item.targetSets - 1)
                let pSets = damper < 1.0 ? max(1, Int((Double(baseSets) * damper).rounded())) : baseSets
                let pReps = item.targetReps
                let pWeight = damper < 1.0 ? (item.targetWeightKg * damper * 2.0).rounded() / 2.0 : item.targetWeightKg

                adaptedItems.append(
                    AdaptedWorkoutPrescription.AdaptedExerciseItem(
                        exercise: item.exercise,
                        prescribedSets: reha.isPermitted ? pSets : 0,
                        prescribedReps: pReps,
                        prescribedWeightKg: pWeight,
                        targetRIR: damper < 1.0 ? "RIR 3-4 (Regeneration)" : "RIR 2-3",
                        restSeconds: item.restSeconds + 15,
                        adaptationReason: reha.isPermitted ? (damper < 1.0 ? "Autoregulierter Reha-Schutz (-50% Last)" : "Autoreguliert: RIR 2-3 zum ZNS-Schutz") : reha.directive,
                        isCorrectivePrimer: false
                    )
                )
            }
        } else if banister.trainingStressBalanceTSB < -20.0 || backgroundReadiness.score < 0.50 {
            badge = "JARVIS Deload-Schutz"
            targetRIR = "RIR 3-4"
            volumeModifier = -0.40
            explanation = "Akute Ermuedung detektiert (TSB: \(Int(banister.trainingStressBalanceTSB))). JARVIS hat Saetze und Lasten proaktiv gedrosselt, damit der Reiz anabol bleibt und keine Ueberlastung entsteht."

            for item in chosenTemplate.items {
                let reha = validateBWKUlmRehaSafety(exercise: item.exercise)
                let muscleKey = item.exercise.targetMuscle.rawValue
                let damper: Double
                if let t = userPreferences.muscleDistressTimestamps[muscleKey], now.timeIntervalSince(t) <= 72.0 * 3600.0 {
                    damper = userPreferences.muscleDistressDampers[muscleKey] ?? 1.0
                } else {
                    damper = 1.0
                }

                let baseSets = max(2, item.targetSets - 1)
                let pSets = damper < 1.0 ? max(1, Int((Double(baseSets) * damper).rounded())) : baseSets
                let baseWeight = (item.targetWeightKg * 0.85 * 2.0).rounded() / 2.0
                let pWeight = damper < 1.0 ? (baseWeight * damper * 2.0).rounded() / 2.0 : baseWeight

                adaptedItems.append(
                    AdaptedWorkoutPrescription.AdaptedExerciseItem(
                        exercise: item.exercise,
                        prescribedSets: reha.isPermitted ? pSets : 0,
                        prescribedReps: item.targetReps,
                        prescribedWeightKg: pWeight,
                        targetRIR: "RIR 3-4",
                        restSeconds: item.restSeconds + 30,
                        adaptationReason: damper < 1.0 ? "Autoregulierter Reha-Schutz (Schmerz-Prophylaxe)" : "Autoregulierter Deload-Schutz (-15% Last)",
                        isCorrectivePrimer: false
                    )
                )
            }
        } else {
            badge = isDivergence ? "JARVIS Spontan-Freigabe" : "JARVIS Planmaessig"
            targetRIR = "RIR 1-2"
            volumeModifier = 0.0
            explanation = isDivergence
                ? "Spontanes Workout gewaehlt. Ausreichende Regenerationskapazitaet verfuegbar. Standard-Lasten freigegeben."
                : "Planmaessige Einheit gestartet. Optimale Superkompensation."

            for item in chosenTemplate.items {
                let reha = validateBWKUlmRehaSafety(exercise: item.exercise)
                let muscleKey = item.exercise.targetMuscle.rawValue
                let damper: Double
                if let t = userPreferences.muscleDistressTimestamps[muscleKey], now.timeIntervalSince(t) <= 72.0 * 3600.0 {
                    damper = userPreferences.muscleDistressDampers[muscleKey] ?? 1.0
                } else {
                    damper = 1.0
                }

                let pSets = damper < 1.0 ? max(1, Int((Double(item.targetSets) * damper).rounded())) : item.targetSets
                let pWeight = damper < 1.0 ? (item.targetWeightKg * damper * 2.0).rounded() / 2.0 : item.targetWeightKg

                adaptedItems.append(
                    AdaptedWorkoutPrescription.AdaptedExerciseItem(
                        exercise: item.exercise,
                        prescribedSets: reha.isPermitted ? pSets : 0,
                        prescribedReps: item.targetReps,
                        prescribedWeightKg: pWeight,
                        targetRIR: damper < 1.0 ? "RIR 3-4 (Regeneration)" : "RIR 1-2",
                        restSeconds: item.restSeconds,
                        adaptationReason: reha.isPermitted ? (damper < 1.0 ? "Autoregulierter Reha-Schutz (-50% Last)" : "Standard Progressive Overload") : reha.directive,
                        isCorrectivePrimer: false
                    )
                )
            }
        }

        let allItems = primingItems + adaptedItems
        let totalSets = allItems.reduce(0) { $0 + $1.prescribedSets }

        return AdaptedWorkoutPrescription(
            originalTemplateId: chosenTemplate.id,
            sessionTitle: chosenTemplate.name,
            isSpontaneousDivergence: isDivergence,
            targetVolumeSets: totalSets,
            volumeModifierPercent: volumeModifier,
            targetRIRRange: targetRIR,
            adaptedExercises: allItems,
            correctivePrimingExercises: primingItems,
            coachDirectiveBadge: badge,
            coachDirectiveExplanation: explanation
        )
    }

    // MARK: - 11. Praeferenz-Lern-Engine
    public func recordSpontaneousDivergence(
        chosenTemplate: WorkoutTemplate,
        recommendation: DailyWorkoutRecommendation,
        sessionsHistory: [WorkoutSession],
        currentProfile: UserExercisePreferenceProfile
    ) -> UserExercisePreferenceProfile {
        var profile = currentProfile
        profile.totalDeviationsCount += 1

        let exNames = chosenTemplate.items.map { $0.exercise.name }
        let muscles = Array(Set(chosenTemplate.items.map { $0.exercise.targetMuscle.rawValue }))
        let banister = calculateBanisterMetrics(sessionsHistory: sessionsHistory)
        let readiness = calculateBackgroundReadiness(sessionsHistory: sessionsHistory)

        let record = SpontaneousDivergenceRecord(
            recommendedFocus: recommendation.recommendedFocus,
            chosenTemplateName: chosenTemplate.name,
            chosenExerciseNames: exNames,
            primaryTargetMuscles: muscles,
            systemicReadinessAtStart: readiness.score,
            banisterTSBAtStart: banister.trainingStressBalanceTSB,
            adaptationAppliedSummary: "Spontane Wahl: \(chosenTemplate.name) (\(muscles.joined(separator: ", ")))"
        )

        profile.divergenceHistory.insert(record, at: 0)
        if profile.divergenceHistory.count > 50 {
            profile.divergenceHistory.removeLast()
        }

        for name in exNames {
            profile.exerciseSelectionFrequencies[name, default: 0] += 1
        }
        for m in muscles {
            let current = profile.muscleGroupAffinities[m, default: 0.5]
            profile.muscleGroupAffinities[m] = min(1.0, current + 0.05)
        }

        return profile
    }

    public func recordCompletedSession(
        session: WorkoutSession,
        currentProfile: UserExercisePreferenceProfile
    ) -> UserExercisePreferenceProfile {
        var profile = currentProfile
        profile.totalSessionsCount += 1

        let now = Date()
        let decayHours = tuningMatrix.dampers.decay_duration_hours
        let omissionMult = tuningMatrix.dampers.omission_damper_multiplier
        let highRpeMult = tuningMatrix.dampers.high_rpe_damper_multiplier

        // 1. Zirkadianer Verfall von Daempfungen aelter als Konfiguration (Standard 72 Stunden)
        var updatedDampers: [String: Double] = [:]
        var updatedTimestamps: [String: Date] = [:]
        for (muscle, t) in profile.muscleDistressTimestamps {
            if now.timeIntervalSince(t) < decayHours * 3600.0 {
                updatedDampers[muscle] = profile.muscleDistressDampers[muscle] ?? 1.0
                updatedTimestamps[muscle] = t
            }
        }
        profile.muscleDistressDampers = updatedDampers
        profile.muscleDistressTimestamps = updatedTimestamps

        var bodyweightCount = 0
        var totalSets = 0

        // 2. Mathematische Auswertung der Uebungen (Erledigt vs. Ausgelassen / Schmerz / Abbruch)
        for item in session.exercises {
            let plannedCount = item.sets.count
            let completed = item.sets.filter { $0.isCompleted }
            let muscleStr = item.exercise.targetMuscle.rawValue

            if plannedCount > 0 && completed.isEmpty {
                // Vollstaendige Auslassung einer geplanten Uebung (z.B. Beine schmerzen oder Zeitmangel)
                profile.muscleDistressDampers[muscleStr] = omissionMult
                profile.muscleDistressTimestamps[muscleStr] = session.endTime ?? now
            } else if plannedCount > 0 && Double(completed.count) / Double(plannedCount) <= 0.50 {
                // Vorzeitiger Abbruch mitten in der Uebung (weniger als die Haelfte der Saetze absolviert)
                profile.muscleDistressDampers[muscleStr] = highRpeMult
                profile.muscleDistressTimestamps[muscleStr] = session.endTime ?? now
            } else if completed.contains(where: { ($0.rpe ?? 0) >= 10.0 }) {
                // Maximale muszulaere Grenzbelastung / RPE 10
                profile.muscleDistressDampers[muscleStr] = 0.80
                profile.muscleDistressTimestamps[muscleStr] = session.endTime ?? now
            }

            guard !completed.isEmpty else { continue }
            let name = item.exercise.name
            profile.exerciseSelectionFrequencies[name, default: 0] += completed.count

            let curAff = profile.muscleGroupAffinities[muscleStr, default: 0.5]
            profile.muscleGroupAffinities[muscleStr] = min(1.0, curAff + 0.02)

            if item.exercise.equipment == .bodyweight || item.exercise.equipment == .pullUpBar || item.exercise.equipment == .dipStation {
                bodyweightCount += completed.count
            }
            totalSets += completed.count
        }

        if totalSets > 0 {
            let bwRatio = Double(bodyweightCount) / Double(totalSets)
            if bwRatio > 0.60 {
                profile.preferredEquipmentStyle = "Bodyweight / Calisthenics"
            } else if bwRatio < 0.20 {
                profile.preferredEquipmentStyle = "Freihanteln & Maschinen"
            } else {
                profile.preferredEquipmentStyle = "Hybrid"
            }
        }

        return profile
    }

    // MARK: - 1-Tap Exit-Skalar Auswertung (Verbesserung 2)
    public func evaluateExitScalar(
        exitCode: Int,
        session: WorkoutSession,
        currentProfile: UserExercisePreferenceProfile
    ) -> (updatedProfile: UserExercisePreferenceProfile, atlBoost: Double, note: String) {
        var profile = currentProfile
        let now = session.endTime ?? Date()

        switch exitCode {
        case 0:
            // [0] Planmaessig beendet (Standard / Gruen)
            profile = recordCompletedSession(session: session, currentProfile: profile)
            return (profile, 0.0, "Planmaessig vollstaendig abgeschlossen")

        case 1:
            // [1] Dienstlicher Abbruch / Zeitnot (Neutral / Gelb)
            // Nur absolvierte Saetze verbuchen, KEINE Daempfung ausloesen
            profile.totalSessionsCount += 1
            for item in session.exercises {
                let completed = item.sets.filter { $0.isCompleted }
                guard !completed.isEmpty else { continue }
                let name = item.exercise.name
                profile.exerciseSelectionFrequencies[name, default: 0] += completed.count
            }
            return (profile, 0.0, "Dienstlicher Abbruch / Zeitnot (Keine Daempfung)")

        case 2:
            // [2] Systemische Erschoepfung (Orange)
            // Fuehrt zu Banister-ATL Anstieg (+25 TRIMP), ZNS-Deload
            profile = recordCompletedSession(session: session, currentProfile: profile)
            return (profile, 25.0, "Systemische Erschoepfung detektiert (ZNS-Deload aktiviert)")

        case 3:
            // [3] Lokaler Schmerz / Gelenk (Rot)
            // 72h-Daempfung auf omission_damper_multiplier fuer alle betroffenen Muskelgruppen
            profile = recordCompletedSession(session: session, currentProfile: profile)
            let omissionMult = tuningMatrix.dampers.omission_damper_multiplier
            for item in session.exercises {
                let muscle = item.exercise.targetMuscle.rawValue
                profile.muscleDistressDampers[muscle] = omissionMult
                profile.muscleDistressTimestamps[muscle] = now
            }
            return (profile, 0.0, "Lokaler Schmerz / Gelenkbeschwerde (72h Schutz-Daempfung aktiviert)")

        default:
            profile = recordCompletedSession(session: session, currentProfile: profile)
            return (profile, 0.0, "Abgeschlossen")
        }
    }
}
