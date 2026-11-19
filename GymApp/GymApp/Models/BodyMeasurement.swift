import Foundation

public enum MeasurementCategory: String, Codable, CaseIterable {
    case core = "CORE"
    case bodyPart = "KÖRPERTEIL"
}

public enum MeasurementType: String, Codable, CaseIterable, Identifiable {
    // Core
    case weight = "Gewicht"
    case bodyFat = "Körperfett"
    case caloricIntake = "Kalorieneinnahme"
    case waterIntake = "Wasserzufuhr"

    // Körperteil
    case neck = "Nacken"
    case shoulders = "Schultern"
    case chest = "Brust"
    case leftBicep = "Linker Bizeps"
    case rightBicep = "Rechter Bizeps"
    case leftForearm = "Linker Unterarm"
    case rightForearm = "Rechter Unterarm"
    case upperAbs = "Obere Bauchmuskeln"
    case waist = "Taille"
    case lowerAbs = "Untere Bauchmuskeln"
    case hips = "Hüften"
    case leftThigh = "Linker Oberschenkel"
    case rightThigh = "Rechter Oberschenkel"
    case leftCalf = "Linke Wade"
    case rightCalf = "Rechte Wade"

    public var id: String { rawValue }

    public var category: MeasurementCategory {
        switch self {
        case .weight, .bodyFat, .caloricIntake, .waterIntake:
            return .core
        default:
            return .bodyPart
        }
    }

    public var unit: String {
        switch self {
        case .weight:
            return "kg"
        case .bodyFat:
            return "%"
        case .caloricIntake:
            return "kcal"
        case .waterIntake:
            return "ml"
        default:
            return "cm"
        }
    }
}

public struct BodyMeasurementEntry: Identifiable, Codable, Equatable {
    public var id: UUID
    public var type: MeasurementType
    public var value: Double
    public var date: Date
    public var note: String

    public init(
        id: UUID = UUID(),
        type: MeasurementType,
        value: Double,
        date: Date = Date(),
        note: String = ""
    ) {
        self.id = id
        self.type = type
        self.value = value
        self.date = date
        self.note = note
    }
}
