import Foundation
import SwiftUI

// MARK: - Die 5 Stufen menschlicher Leistungsfaehigkeit (5 Athletic Capability Tiers)
public enum AthleticStandardTier: String, CaseIterable, Codable, Identifiable {
    case subFunctional = "Stufe 1: Unter Grundstandard (Sedentaer)"
    case basicFunctional = "Stufe 2: Normaler menschlicher Standard (Funktionell)"
    case advancedAmateur = "Stufe 3: Ambitionierter Amateur (Weekend Warrior)"
    case professionalElite = "Stufe 4: Profi-Standard (Elite-Wettkaempfer)"
    case generationalGodTier = "Stufe 5: Jahrhundert-Athlet (God-Tier)"

    public var id: String { rawValue }

    public var tierNumber: Int {
        switch self {
        case .subFunctional: return 1
        case .basicFunctional: return 2
        case .advancedAmateur: return 3
        case .professionalElite: return 4
        case .generationalGodTier: return 5
        }
    }

    public var shortTitle: String {
        switch self {
        case .subFunctional: return "Sub-Funktional"
        case .basicFunctional: return "Normal-Standard"
        case .advancedAmateur: return "Amateur"
        case .professionalElite: return "Profi-Elite"
        case .generationalGodTier: return "God-Tier"
        }
    }

    public var relativeMultiplier: Double {
        switch self {
        case .subFunctional: return 0.50
        case .basicFunctional: return 1.00 // Referenzlinie (Human Baseline)
        case .advancedAmateur: return 1.75
        case .professionalElite: return 2.75
        case .generationalGodTier: return 4.00
        }
    }

    public var tierColorHex: String {
        switch self {
        case .subFunctional: return "95A5A6"       // Neutralgrau
        case .basicFunctional: return "3498DB"     // Blau (Referenz-Standard)
        case .advancedAmateur: return "2ECC71"     // Gruen
        case .professionalElite: return "F39C12"   // Amber-Gold
        case .generationalGodTier: return "E74C3C" // Rubinrot
        }
    }

    public var description: String {
        switch self {
        case .subFunctional:
            return "Körperliche Leistungsfaehigkeit unterhalb des gesunden Basalniveaus (Bewegungsmangel, Rekonvaleszenz)."
        case .basicFunctional:
            return "Gesunder menschlicher Normalstandard: Schmerzfreie Alltagsfunktion, 1 Meile/2 km Dauerlauf, 1x Koerpergewicht Heben."
        case .advancedAmateur:
            return "Top 10 % der Bevoelkerung: Strukturierte Trainingsdisziplin, Halbmarathon/Marathon-Faehigkeit, signifikante relative Kraft."
        case .professionalElite:
            return "Nationale/internationale Spitzenathleten, optimierte Biomechanik, volle Trainingsmonetarisierung."
        case .generationalGodTier:
            return "Historische Ausnahmeathleten (Bolt, Phelps, Biles), genetische Anomalien und Rekorde ueber Jahrzehnte."
        }
    }
}

// MARK: - Ziel-Hierarchie (Saeule -> Programm -> Session)
public enum GoalHierarchyLevel: String, Codable {
    case pillar = "Saeulen-Ziel (Makro)"
    case program = "Programm-Ziel (Meso)"
    case session = "Einheits-Ziel (Mikro)"
}

public struct GoalItem: Identifiable, Codable, Equatable, Hashable {
    public var id: UUID
    public var level: GoalHierarchyLevel
    public var title: String
    public var targetMetricDescription: String
    public var targetValue: Double
    public var currentValue: Double
    public var unit: String
    public var tierRequired: AthleticStandardTier
    public var isCompleted: Bool
    public var clinicalSafetyNotes: String

    public init(
        id: UUID = UUID(),
        level: GoalHierarchyLevel,
        title: String,
        targetMetricDescription: String,
        targetValue: Double,
        currentValue: Double = 0.0,
        unit: String,
        tierRequired: AthleticStandardTier = .basicFunctional,
        isCompleted: Bool = false,
        clinicalSafetyNotes: String = ""
    ) {
        self.id = id
        self.level = level
        self.title = title
        self.targetMetricDescription = targetMetricDescription
        self.targetValue = targetValue
        self.currentValue = currentValue
        self.unit = unit
        self.tierRequired = tierRequired
        self.isCompleted = isCompleted
        self.clinicalSafetyNotes = clinicalSafetyNotes
    }

    public var progressRatio: Double {
        guard targetValue > 0 else { return isCompleted ? 1.0 : 0.0 }
        return min(1.0, max(0.0, currentValue / targetValue))
    }
}

// MARK: - Standard-Benchmark-Vergleich (User vs. Human Baseline)
public struct AthleticStandardMetric: Identifiable, Codable {
    public var id: String // z.B. "5km_run_pace"
    public var title: String
    public var pillar: ProgramBlock
    public var humanBaselineValue: Double // Stufe 2 (1.0x Normalwert)
    public var userCurrentValue: Double
    public var unit: String
    public var isHigherBetter: Bool // true fuer Gewicht/Wdh, false fuer Laufzeit

    public init(
        id: String,
        title: String,
        pillar: ProgramBlock,
        humanBaselineValue: Double,
        userCurrentValue: Double,
        unit: String,
        isHigherBetter: Bool = true
    ) {
        self.id = id
        self.title = title
        self.pillar = pillar
        self.humanBaselineValue = humanBaselineValue
        self.userCurrentValue = userCurrentValue
        self.unit = unit
        self.isHigherBetter = isHigherBetter
    }

    public var performanceMultiplier: Double {
        guard humanBaselineValue > 0 else { return 1.0 }
        if isHigherBetter {
            return userCurrentValue / humanBaselineValue
        } else {
            return humanBaselineValue / max(0.1, userCurrentValue)
        }
    }

    public var currentTier: AthleticStandardTier {
        let mult = performanceMultiplier
        if mult < 0.75 {
            return .subFunctional
        } else if mult <= 1.35 {
            return .basicFunctional
        } else if mult <= 2.20 {
            return .advancedAmateur
        } else if mult <= 3.30 {
            return .professionalElite
        } else {
            return .generationalGodTier
        }
    }

    public var deltaPercentageToHumanStandard: Int {
        let delta = (performanceMultiplier - 1.0) * 100.0
        return Int(delta)
    }
}
