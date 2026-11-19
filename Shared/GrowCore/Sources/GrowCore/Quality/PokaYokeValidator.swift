import Foundation

public enum ValidationError: Error, LocalizedError, Equatable {
    case waterValueOutOfRange(value: Double, min: Double, max: Double)
    case weightDeltaUnrealistic(previous: Double, new: Double, delta: Double)
    case transactionAmountInvalid(amount: Double)
    case duplicateTransactionDetected(recipient: String, amount: Double)
    case calorieMacroDiscrepancy(calculatedKcal: Double, statedKcal: Double, delta: Double)

    public var errorDescription: String? {
        switch self {
        case .waterValueOutOfRange(let val, let min, let max):
            return "Wasseraufnahme von \(Int(val)) ml liegt außerhalb des zulässigen Bereichs (\(Int(min))–\(Int(max)) ml)."
        case .weightDeltaUnrealistic(let prev, let new, let delta):
            return "Körpergewichts-Abweichung von \(String(format: "%.1f", delta)) kg (\(prev) -> \(new) kg) ist physiologisch unplausibel."
        case .transactionAmountInvalid(let amount):
            return "Transaktionsbetrag (\(amount) EUR) muss größer als 0.00 EUR sein."
        case .duplicateTransactionDetected(let recipient, let amount):
            return "Mögliche Duplikat-Buchung: \(recipient) über \(String(format: "%.2f", amount)) EUR wurde soeben erfasst."
        case .calorieMacroDiscrepancy(let calc, let stated, let delta):
            return "Makro-Diskrepanz: Berechnete Kalorien (\(Int(calc)) kcal) weichen um \(Int(delta)) kcal von Angabe (\(Int(stated)) kcal) ab."
        }
    }
}

public struct PokaYokeValidator: Sendable {
    public static let minWaterMl: Double = 0.0
    public static let maxWaterMl: Double = 8000.0 // 8 Liters max safe single-day limit
    public static let maxRealisticWeightDelta24h: Double = 4.0 // Max 4kg fluctuation per day

    public static func validateWaterIntake(_ totalMl: Double) throws {
        if totalMl < minWaterMl || totalMl > maxWaterMl {
            throw ValidationError.waterValueOutOfRange(value: totalMl, min: minWaterMl, max: maxWaterMl)
        }
    }

    public static func validateWeightChange(previousKg: Double?, newKg: Double) throws {
        guard let prev = previousKg, prev > 20.0 else { return }
        let delta = abs(newKg - prev)
        if delta > maxRealisticWeightDelta24h {
            throw ValidationError.weightDeltaUnrealistic(previous: prev, new: newKg, delta: delta)
        }
    }

    public static func validateTransaction(amount: Double) throws {
        if amount <= 0.0 || amount.isNaN || amount.isInfinite {
            throw ValidationError.transactionAmountInvalid(amount: amount)
        }
    }

    public static func validateNutritionMacros(calories: Double, proteinG: Double, carbsG: Double, fatG: Double) throws {
        // Atwater general factors: 4 kcal/g protein, 4 kcal/g carb, 9 kcal/g fat
        let calculated = (proteinG * 4.0) + (carbsG * 4.0) + (fatG * 9.0)
        let delta = abs(calories - calculated)
        // Allow up to 25% discrepancy due to fiber, alcohol, or rounding
        if calories > 100 && delta > max(50.0, calories * 0.35) {
            throw ValidationError.calorieMacroDiscrepancy(calculatedKcal: calculated, statedKcal: calories, delta: delta)
        }
    }
}
