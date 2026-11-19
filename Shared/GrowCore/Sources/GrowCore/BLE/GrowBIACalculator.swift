import Foundation

/// Bioelectrical Impedance Analysis (BIA) Mathematical Engine
/// Exact formulas ported from qn_scale_ble (specific to Renpho ES-26M / FCC ID 2A26P-ESCS20M)
public struct GrowBodyCompositionMetrics: Codable, Sendable {
    public let weightKg: Double
    public let bmi: Double
    public let bodyFatPct: Double
    public let fatMassKg: Double
    public let fatFreeMassKg: Double
    public let muscleMassKg: Double
    public let musclePct: Double
    public let skeletalMuscleKg: Double
    public let skeletalMusclePct: Double
    public let boneMassKg: Double
    public let bonePct: Double
    public let bodyWaterKg: Double
    public let bodyWaterPct: Double
    public let proteinKg: Double
    public let proteinPct: Double
    public let subcutaneousFatPct: Double
    public let visceralFatIndex: Int
    public let bmrKcal: Double
    public let metabolicAgeYears: Int

    public init(
        weightKg: Double,
        bmi: Double,
        bodyFatPct: Double,
        fatMassKg: Double,
        fatFreeMassKg: Double,
        muscleMassKg: Double,
        musclePct: Double,
        skeletalMuscleKg: Double,
        skeletalMusclePct: Double,
        boneMassKg: Double,
        bonePct: Double,
        bodyWaterKg: Double,
        bodyWaterPct: Double,
        proteinKg: Double,
        proteinPct: Double,
        subcutaneousFatPct: Double,
        visceralFatIndex: Int,
        bmrKcal: Double,
        metabolicAgeYears: Int
    ) {
        self.weightKg = weightKg
        self.bmi = bmi
        self.bodyFatPct = bodyFatPct
        self.fatMassKg = fatMassKg
        self.fatFreeMassKg = fatFreeMassKg
        self.muscleMassKg = muscleMassKg
        self.musclePct = musclePct
        self.skeletalMuscleKg = skeletalMuscleKg
        self.skeletalMusclePct = skeletalMusclePct
        self.boneMassKg = boneMassKg
        self.bonePct = bonePct
        self.bodyWaterKg = bodyWaterKg
        self.bodyWaterPct = bodyWaterPct
        self.proteinKg = proteinKg
        self.proteinPct = proteinPct
        self.subcutaneousFatPct = subcutaneousFatPct
        self.visceralFatIndex = visceralFatIndex
        self.bmrKcal = bmrKcal
        self.metabolicAgeYears = metabolicAgeYears
    }
}

public enum GrowBIACalculator {

    /// Berechnet die biometrischen Werte nach dem qn_scale_ble / ES-26M Modell.
    public static func calculate(
        weightKg: Double,
        impedanceOhms: Double?,
        heightCm: Double = 175.0,
        ageYears: Int = 26,
        isMale: Bool = true
    ) -> GrowBodyCompositionMetrics {
        let heightM = max(1.0, heightCm / 100.0)
        let bmi = (weightKg / (heightM * heightM) * 100.0).rounded() / 100.0

        let ffm: Double
        let bfp: Double

        if let imp = impedanceOhms, imp >= 150.0 && imp <= 1500.0 {
            // qn_scale_ble BFP Gleichung
            let ageFactor = isMale ? 0.103 : 0.097
            let bmiFactor = isMale ? 1.524 : 1.545
            let constant = isMale ? 22.0 : 12.7
            let rawBfp = (ageFactor * Double(ageYears)) + (bmiFactor * bmi) - (500.0 / imp) - constant
            bfp = max(5.0, min(75.0, (rawBfp * 10.0).rounded() / 10.0))
            ffm = weightKg * (1.0 - (bfp / 100.0))
        } else {
            let sexCoeff = isMale ? 1.0 : 0.0
            let estBfp = (1.20 * bmi) + (0.23 * Double(ageYears)) - (10.8 * sexCoeff) - 5.4
            bfp = max(5.0, min(50.0, (estBfp * 10.0).rounded() / 10.0))
            ffm = weightKg * (1.0 - (bfp / 100.0))
        }

        let fatFreeMassKg = (ffm * 100.0).rounded() / 100.0
        let fatMassKg = max(0.0, (weightKg - fatFreeMassKg) * 100.0).rounded() / 100.0

        // Viszeralfett (1 - 30)
        let vfvConst = isMale ? 14.2692 : 16.215
        let vfvBmi = isMale ? 0.8666 : 0.8895
        let vfvBfp = isMale ? 0.0082 : 0.0943
        let vfvFat = isMale ? 0.026 : -0.0534
        let rawVfv = (vfvBmi * bmi) + (vfvBfp * bfp) + (vfvFat * (weightKg - fatFreeMassKg)) - vfvConst
        let visceralIndex = max(1, min(30, Int(rawVfv.rounded())))

        // Subkutanes Fett (%)
        let subBfp = isMale ? 0.965 : 0.983
        let subVfv = isMale ? 0.22 : 0.303
        let subPct = max(3.0, (((subBfp * bfp) - (subVfv * Double(visceralIndex))) * 10.0).rounded() / 10.0)

        // Muskelmasse & Skelettmuskel
        let ff1Factor = isMale ? 0.05 : 0.06
        let ff1 = max(1.0, ff1Factor * fatFreeMassKg)
        let smpFactor = isMale ? 0.68 : 0.62
        let skelPct = ((smpFactor * (fatFreeMassKg - ff1) / weightKg * 100.0) * 10.0).rounded() / 10.0
        let skelKg = ((weightKg * (skelPct / 100.0)) * 100.0).rounded() / 100.0
        let muscleKg = max(0.0, ((fatFreeMassKg - ff1) * 100.0).rounded() / 100.0)
        let musclePct = ((muscleKg / weightKg) * 1000.0).rounded() / 10.0

        // Koerperwasser
        let bwpFactor = isMale ? 0.76 : 0.73
        let waterPct = ((bwpFactor * (fatFreeMassKg - ff1) / weightKg * 100.0) * 10.0).rounded() / 10.0
        let waterKg = ((weightKg * (waterPct / 100.0)) * 100.0).rounded() / 100.0

        // Knochenmasse
        let boneKg = max(1.0, (ff1Factor * fatFreeMassKg * 100.0).rounded() / 100.0)
        let bonePct = ((boneKg / weightKg) * 1000.0).rounded() / 10.0

        // Protein
        let protPct = max(5.0, ((100.0 - bfp - (boneKg / weightKg * 100.0) - waterPct) * 10.0).rounded() / 10.0)
        let proteinKg = ((weightKg * (protPct / 100.0)) * 100.0).rounded() / 100.0

        // Grundumsatz (BMR) = FFM * 21.6 + 370
        let bmrKcal = (fatFreeMassKg * 21.6 + 370.0).rounded()

        // Stoffwechselalter
        let expectedBmr = isMale ? (88.362 + (13.397 * weightKg) + (4.799 * heightCm) - (5.677 * Double(ageYears)))
                                 : (447.593 + (9.247 * weightKg) + (3.098 * heightCm) - (4.330 * Double(ageYears)))
        let bmrDelta = expectedBmr - bmrKcal
        let metabolicAge = max(18, min(80, ageYears + Int((bmrDelta / 30.0).rounded())))

        return GrowBodyCompositionMetrics(
            weightKg: weightKg,
            bmi: (bmi * 10.0).rounded() / 10.0,
            bodyFatPct: bfp,
            fatMassKg: fatMassKg,
            fatFreeMassKg: fatFreeMassKg,
            muscleMassKg: muscleKg,
            musclePct: musclePct,
            skeletalMuscleKg: skelKg,
            skeletalMusclePct: skelPct,
            boneMassKg: boneKg,
            bonePct: bonePct,
            bodyWaterKg: waterKg,
            bodyWaterPct: waterPct,
            proteinKg: proteinKg,
            proteinPct: protPct,
            subcutaneousFatPct: subPct,
            visceralFatIndex: visceralIndex,
            bmrKcal: bmrKcal,
            metabolicAgeYears: metabolicAge
        )
    }
}
