import Foundation
import SwiftUI

// MARK: - Griechische Goetter-Archetypen fuer Calisthenics
public enum CalisthenicArchetype: String, CaseIterable, Codable, Identifiable {
    case zeus = "Zeus"
    case apollo = "Apollo"
    case ares = "Ares"
    case prometheus = "Prometheus"
    case hermes = "Hermes"
    case poseidon = "Poseidon"
    case hercules = "Hercules"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .zeus: return "Zeus • Maximalkraft & Hebelwirkung"
        case .apollo: return "Apollo • Symmetrie, Rumpf & V-Taper"
        case .ares: return "Ares • Konditionelle Dichte & Kampf-Ausdauer"
        case .prometheus: return "Prometheus • Post-OP Reha, Prehab & Statik"
        case .hermes: return "Hermes • Agilitaet, Tempo & Reaktionskraft"
        case .poseidon: return "Poseidon • Zugvolumen & Rueckenbreite"
        case .hercules: return "Hercules • Masse & Ganzkoerper-Staerke"
        }
    }

    public var mythosFocus: String {
        switch self {
        case .zeus:
            return "Muscle-ups, Handstand-Push-ups, Barren-Dips und explosive Hebelkraft. Koenigsklasse der Koerperbeherrschung."
        case .apollo:
            return "Front Lever Progressions, Scapular-Retraktion, L-Sit, schlanke Taille. Strikt BWK-konforme Rumpfkontrolle ohne Crunches."
        case .ares:
            return "Erbarmungslose Push-Pull-Dichte, Pyramiden-Workouts und metabolische Laktattoleranz ohne Leistungsabfall."
        case .prometheus:
            return "Isometrische Stabilisation, Sehnen- und Gelenk-Prehab, Bird-Dog, Glute Bridges. Maximaler Schutz vor intraabdominalem Druck."
        case .hermes:
            return "Reaktive Beinkraft, plyometrische Koordination und anaerobes Schnellkrafttraining ohne Geraete."
        case .poseidon:
            return "Massives vertikales und horizontales Zugvolumen an Stange und Ringen fuer unnachgiebige Rueckenbreite."
        case .hercules:
            return "Kombiniertes Bodyweight-Volumentraining zur Ausreizung der mechanischen Myofibrillen-Spannung."
        }
    }

    public var equipmentRequirement: EquipmentRequirement {
        switch self {
        case .zeus: return .ringsAndBar
        case .apollo: return .ringsAndBar
        case .ares: return .pullUpBarOnly
        case .prometheus: return .pureFloorNoGear
        case .hermes: return .pureFloorNoGear
        case .poseidon: return .pullUpBarOnly
        case .hercules: return .fullCalisthenicsPark
        }
    }

    public var isBWKCoreSafe: Bool {
        switch self {
        case .prometheus, .apollo, .hermes, .poseidon, .hercules, .zeus, .ares:
            return true
        }
    }

    public var accentColorHex: String {
        switch self {
        case .zeus: return "F1C40F"        // Blitz-Gold
        case .apollo: return "00B4D8"      // Aesthetik-Cyan
        case .ares: return "E74C3C"        // Krieger-Rot
        case .prometheus: return "2ECC71"  // Reha-Smaragdgruen
        case .hermes: return "9B59B6"      // Tempo-Violett
        case .poseidon: return "2980B9"    // Tiefsee-Blau
        case .hercules: return "E67E22"    // Titanen-Bronze
        }
    }
}

// MARK: - Geraeteanforderung fuer Bodyweight-Programme
public enum EquipmentRequirement: String, CaseIterable, Codable, Identifiable {
    case pureFloorNoGear = "Ohne Geraete (Reiner Boden)"
    case pullUpBarOnly = "Nur Klimmzugstange (oder Tuerrahmen)"
    case parallettesAndFloor = "Parallettes & Matte"
    case ringsAndBar = "Turnringe & Stange"
    case fullCalisthenicsPark = "Vollstaendiger Calisthenics-Park"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .pureFloorNoGear: return "figure.walk"
        case .pullUpBarOnly: return "figure.pull.up"
        case .parallettesAndFloor: return "figure.core.training"
        case .ringsAndBar: return "circle.circle"
        case .fullCalisthenicsPark: return "building.columns.fill"
        }
    }
}

// MARK: - Profil eines Calisthenics-Archetyps
public struct ArchetypeProfile: Identifiable, Codable, Equatable {
    public var id: String { archetype.rawValue }
    public var archetype: CalisthenicArchetype
    public var equipment: EquipmentRequirement
    public var movementPatterns: [String]
    public var isBWKCompliant: Bool

    public init(
        archetype: CalisthenicArchetype,
        equipment: EquipmentRequirement,
        movementPatterns: [String],
        isBWKCompliant: Bool = true
    ) {
        self.archetype = archetype
        self.equipment = equipment
        self.movementPatterns = movementPatterns
        self.isBWKCompliant = isBWKCompliant
    }
}
