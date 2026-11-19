import Foundation

public enum CookingUtensil: String, CaseIterable, Identifiable, Codable {
    case none = "Keine Geräte (Kaltansatz)"
    case airfryer = "AirFryer"
    case skillet = "Pfanne / Herd"
    case pot = "Kochtopf"
    case microwave = "Mikrowelle"
    case oven = "Backofen"
    case blender = "Mixer / Shaker"

    public var id: String { rawValue }

    public var shortLabel: String {
        switch self {
        case .none: return "Kaltansatz"
        case .airfryer: return "AirFryer"
        case .skillet: return "Pfanne"
        case .pot: return "Topf"
        case .microwave: return "Mikrowelle"
        case .oven: return "Backofen"
        case .blender: return "Mixer/Shaker"
        }
    }
}

public struct EquipmentTaxonomy {
    public static let commonEquipment: [String] = [
        "Pfanne",
        "Beschichtete Pfanne",
        "Gusseisenpfanne",
        "Wok",
        "Kochtopf klein",
        "Kochtopf groß",
        "Schmortopf / Bräter",
        "Auflaufform",
        "Backblech & Backpapier",
        "Backofen",
        "AirFryer / Heißluftfritteuse",
        "Schneidebrett & Kochmesser",
        "Küchenreibe / Hobel",
        "Pürierstab / Standmixer",
        "Küchenwaage",
        "Rührschüssel",
        "Sieb / Nudelsieb",
        "Pfannenwender / Spatel",
        "Schneebesen",
        "Knoblauchpresse"
    ]

    public static func inferEquipment(instructions: [String], name: String) -> [String] {
        let text = (name + " " + instructions.joined(separator: " ")).lowercased()
        var detected: [String] = []

        if text.contains("airfryer") || text.contains("heißluftfritteuse") {
            detected.append("AirFryer / Heißluftfritteuse")
        }
        if text.contains("backofen") || text.contains("backen") || text.contains("ober-/unterhitze") || text.contains("umluft") {
            detected.append("Backofen")
        }
        if text.contains("auflaufform") || text.contains("gratinform") {
            detected.append("Auflaufform")
        }
        if text.contains("backblech") || text.contains("backpapier") {
            detected.append("Backblech & Backpapier")
        }
        if text.contains("wok") {
            detected.append("Wok")
        } else if text.contains("pfanne") || text.contains("anbraten") || text.contains("braten") {
            detected.append("Pfanne")
        }
        if text.contains("schmortopf") || text.contains("bräter") || text.contains("schmoren") {
            detected.append("Schmortopf / Bräter")
        }
        if text.contains("topf") || text.contains("kochen") || text.contains("wasser kochen") || text.contains("nudeln kochen") {
            detected.append("Kochtopf")
        }
        if text.contains("pürier") || text.contains("mixen") || text.contains("blender") || text.contains("smoothie") {
            detected.append("Pürierstab / Standmixer")
        }
        if text.contains("reibe") || text.contains("hobeln") || text.contains("gerieben") {
            detected.append("Küchenreibe / Hobel")
        }
        if text.contains("schneiden") || text.contains("würfeln") || text.contains("hacken") || text.contains("messer") {
            detected.append("Schneidebrett & Kochmesser")
        }
        if text.contains("schüssel") || text.contains("mischen") || text.contains("unterheben") {
            detected.append("Rührschüssel")
        }
        if text.contains("sieb") || text.contains("abgießen") {
            detected.append("Sieb / Nudelsieb")
        }

        if detected.isEmpty {
            detected = ["Schneidebrett & Kochmesser", "Pfanne", "Kochtopf"]
        }

        return Array(NSOrderedSet(array: detected)).compactMap { $0 as? String }
    }
}
