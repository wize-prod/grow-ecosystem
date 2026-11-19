import Foundation
import Combine

// MARK: - Dynamic Body Composition & Fitness Calculator Model
public struct BodyCompositionReport: Codable, Equatable, Sendable {
    public let timestamp: Date
    public let weightKg: Double
    public let bodyFatPercentage: Double
    public let leanBodyMassKg: Double
    public let fatMassKg: Double
    public let ffmi: Double
    public let normalizedFFMI: Double
    public let bmrKcal: Double
    public let tdeeKcal: Double
    public let maxMuscularPotentialKg: Double
    public let ffmiTier: String

    public init(
        timestamp: Date = Date(),
        weightKg: Double = 78.5,
        bodyFatPercentage: Double = 13.8,
        leanBodyMassKg: Double = 67.6,
        fatMassKg: Double = 10.9,
        ffmi: Double = 21.5,
        normalizedFFMI: Double = 21.2,
        bmrKcal: Double = 1830.0,
        tdeeKcal: Double = 2750.0,
        maxMuscularPotentialKg: Double = 84.0,
        ffmiTier: String = "Solide athletische Basis"
    ) {
        self.timestamp = timestamp
        self.weightKg = weightKg
        self.bodyFatPercentage = bodyFatPercentage
        self.leanBodyMassKg = leanBodyMassKg
        self.fatMassKg = fatMassKg
        self.ffmi = ffmi
        self.normalizedFFMI = normalizedFFMI
        self.bmrKcal = bmrKcal
        self.tdeeKcal = tdeeKcal
        self.maxMuscularPotentialKg = maxMuscularPotentialKg
        self.ffmiTier = ffmiTier
    }
}

// MARK: - Dynamic Fitness Engine (Background Evaluation Process)
@MainActor
public final class DynamicFitnessEngine: ObservableObject {
    public static let shared = DynamicFitnessEngine()

    @Published public private(set) var latestReport: BodyCompositionReport = BodyCompositionReport()
    @Published public private(set) var isCalculating: Bool = false

    private var cancellables = Set<AnyCancellable>()

    private init() {
        // Initial computation
        recalculate()
    }

    /// Triggers dynamic background recalculation based on updated measurements and personal biometrics
    public func recalculate(heightCm: Double = 177.0, customWeightKg: Double? = nil, customFatPct: Double? = nil) {
        isCalculating = true

        Task { [weak self] in
            let weight = customWeightKg ?? 78.5
            let bf = customFatPct ?? 13.8

            let fatMass = (weight * (bf / 100.0) * 10.0).rounded() / 10.0
            let lbm = max(1.0, weight - fatMass)

            let heightM = max(1.0, heightCm / 100.0)
            let rawFfmi = lbm / (heightM * heightM)
            let normFfmi = rawFfmi + (6.1 * (1.8 - heightM))

            // Katch-McArdle Formula: BMR = 370 + (21.6 * LBM)
            let bmr = 370.0 + (21.6 * lbm)
            let tdee = bmr * 1.55 // Standard moderate activity factor (Dienstbetrieb + Kraftsport)

            // Martin Berkhan Maximum Muscular Potential at 5-6% BF: (Height in cm - 100)
            let maxLeanPotential = max(lbm, (heightCm - 100.0) * 1.05)

            let tier: String
            if normFfmi >= 25.0 {
                tier = "Genetisches Oberlimit (Elite)"
            } else if normFfmi >= 23.0 {
                tier = "Exzellente Muskelhypertrophie"
            } else if normFfmi >= 21.0 {
                tier = "Fortgeschritten athletisch"
            } else if normFfmi >= 19.0 {
                tier = "Solide Trainingsbasis"
            } else {
                tier = "Einsteiger / Recomp-Phase"
            }

            let report = BodyCompositionReport(
                timestamp: Date(),
                weightKg: weight,
                bodyFatPercentage: bf,
                leanBodyMassKg: (lbm * 10.0).rounded() / 10.0,
                fatMassKg: fatMass,
                ffmi: (rawFfmi * 10.0).rounded() / 10.0,
                normalizedFFMI: (normFfmi * 10.0).rounded() / 10.0,
                bmrKcal: bmr.rounded(),
                tdeeKcal: tdee.rounded(),
                maxMuscularPotentialKg: maxLeanPotential.rounded(),
                ffmiTier: tier
            )

            await MainActor.run {
                guard let self = self else { return }
                self.latestReport = report
                self.isCalculating = false
            }
        }
    }
}
