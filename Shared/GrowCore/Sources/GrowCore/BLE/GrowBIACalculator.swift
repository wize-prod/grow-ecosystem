import Foundation

/// Bioelectrical Impedance Analysis (BIA) Mathematical Engine
/// Reverse-engineered from open-source references (openScale, ble-scale-sync, qn_scale_ble)
/// Converts raw Weight (kg) and Dual/Single Electrical Impedance (Ohms)
/// alongside biometric demographics (Height, Age, Biological Sex) into full clinical metrics.
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

    /// Berechnet die 14 biometrischen Standard-Werte nach dem Trisa / Yolanda BIA-Modell.
    /// - Parameters:
    ///   - weightKg: Stabilisiertes Endgewicht in kg (z.B. 80.15)
    ///   - impedanceOhms: Gemessener Wechselstrom-Widerstand der Dehnungsmessstreifen in Ohm (z.B. 480)
    ///   - heightCm: Koerpergroesse in Zentimeter (Standard: 177.0 oder Profilwert)
    ///   - ageYears: Chronologisches Alter in Jahren (Standard: 26)
    ///   - isMale: Biologisches Geschlecht (true = maennlich, false = weiblich)
    public static func calculate(
        weightKg: Double,
        impedanceOhms: Double?,
        heightCm: Double = 177.0,
        ageYears: Int = 26,
        isMale: Bool = true
    ) -> GrowBodyCompositionMetrics {
        let heightM = max(1.0, heightCm / 100.0)
        let bmi = (weightKg / (heightM * heightM) * 10.0).rounded() / 10.0

        let ffm: Double
        let bfp: Double

        if let imp = impedanceOhms, imp >= 200.0 && imp <= 1500.0 {
            // Impedanz-basierte Fettfreie Masse (FFM)
            // BIA-Index S = (Height_cm^2) / Impedance
            let biaIndex = (heightCm * heightCm) / imp
            if isMale {
                ffm = (0.396 * biaIndex) + (0.490 * weightKg) + (0.158 * heightCm) - 10.5
            } else {
                ffm = (0.370 * biaIndex) + (0.450 * weightKg) + (0.140 * heightCm) - 8.2
            }
            let calculatedBfp = max(5.0, min(50.0, ((weightKg - ffm) / weightKg) * 100.0))
            bfp = (calculatedBfp * 10.0).rounded() / 10.0
        } else {
            // Deurenberg / Gallagher Schaetzung bei fehlendem Impedanz-Signal
            let sexCoeff = isMale ? 1.0 : 0.0
            let estBfp = (1.20 * bmi) + (0.23 * Double(ageYears)) - (10.8 * sexCoeff) - 5.4
            bfp = max(5.0, min(50.0, (estBfp * 10.0).rounded() / 10.0))
            ffm = weightKg * (1.0 - (bfp / 100.0))
        }

        let fatFreeMassKg = (ffm * 100.0).rounded() / 100.0
        let fatMassKg = max(0.0, (weightKg - fatFreeMassKg) * 100.0).rounded() / 100.0

        // 1. Koerperwasser (TBW): ca. 72 - 73.2% der fettfreien Masse
        let waterKg = (fatFreeMassKg * 0.7214 * 100.0).rounded() / 100.0
        let waterPct = ((waterKg / weightKg) * 1000.0).rounded() / 10.0

        // 2. Knochenmasse: Mineralanteil ca. 4.9 - 5.0% der FFM
        let boneKg = ((1.80 + (0.0195 * fatFreeMassKg)) * 100.0).rounded() / 100.0
        let bonePct = ((boneKg / weightKg) * 1000.0).rounded() / 10.0

        // 3. Muskelmasse gesamt (Skelettmuskeln + glatte Muskeln + Organe)
        let muscleKg = max(0.0, (fatFreeMassKg - boneKg) * 100.0).rounded() / 100.0
        let musclePct = ((muscleKg / weightKg) * 1000.0).rounded() / 10.0

        // 4. Skelettmuskelmasse: ca. 67.8% der gesamten Muskelmasse
        let skelKg = (muscleKg * 0.6784 * 100.0).rounded() / 100.0
        let skelPct = ((skelKg / weightKg) * 1000.0).rounded() / 10.0

        // 5. Proteinanteil: Proteinmasse = FFM - Wasser - Knochen
        let proteinKg = max(0.0, (fatFreeMassKg - waterKg - boneKg) * 100.0).rounded() / 100.0
        let proteinPct = ((proteinKg / weightKg) * 1000.0).rounded() / 10.0

        // 6. Viszeralfett-Index (1 - 50 Skala, Renpho Standard)
        let rawVisceral = (0.15 * Double(ageYears)) + (0.50 * bmi) - 9.0
        let visceralIndex = max(1, min(50, Int(rawVisceral.rounded())))

        // 7. Subkutanes Fett (%)
        let subPct = max(3.0, (bfp - (Double(visceralIndex) / 2.8) * 10.0).rounded() / 10.0)

        // 8. Grundumsatz (BMR, Katch-McArdle Formula): BMR = 370 + (21.6 * FFM)
        let bmrKcal = (370.0 + (21.6 * fatFreeMassKg)).rounded()

        // 9. Stoffwechselalter: BMR-Abweichung vom Normalwert fuer Alterskohorte
        let expectedBmr = isMale ? (88.362 + (13.397 * weightKg) + (4.799 * heightCm) - (5.677 * Double(ageYears)))
                                 : (447.593 + (9.247 * weightKg) + (3.098 * heightCm) - (4.330 * Double(ageYears)))
        let bmrDelta = expectedBmr - bmrKcal
        let metabolicAge = max(18, min(80, ageYears + Int((bmrDelta / 30.0).rounded())))

        return GrowBodyCompositionMetrics(
            weightKg: weightKg,
            bmi: bmi,
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
            proteinPct: proteinPct,
            subcutaneousFatPct: subPct,
            visceralFatIndex: visceralIndex,
            bmrKcal: bmrKcal,
            metabolicAgeYears: metabolicAge
        )
    }
}
