import Foundation

// MARK: - Care Activity Type
public enum CareActivityType: String, Codable, CaseIterable {
    case skincare = "Skincare"
    case beard = "Bartpflege"
    case hair = "Haarpflege"
    case oral = "Zahnhygiene"
    case groin = "Leiste & Intim"
    case nails = "Nagel- & Fusspflege"
    case body = "Koerper & Rumpf"
    case hygiene = "Hygiene"
    case chore = "Kasernendienst"
    case laundry = "Waesche"
    case inspection = "Spind & Stube"

    public var iconName: String {
        switch self {
        case .skincare: return "sparkles"
        case .beard: return "scissors"
        case .hair: return "comb.fill"
        case .oral: return "mouth"
        case .groin: return "shield.lefthalf.filled"
        case .nails: return "hand.raised.fill"
        case .body: return "figure.stand"
        case .hygiene: return "drop.fill"
        case .chore: return "checkmark.shield.fill"
        case .laundry: return "washer.fill"
        case .inspection: return "checklist"
        }
    }
}

// MARK: - Care Log Entry
public struct CareLogEntry: Identifiable, Codable, Equatable {
    public var id: String
    public var routineId: String
    public var title: String
    public var activityType: CareActivityType
    public var timestamp: Date
    public var durationMinutes: Int
    public var note: String
    public var keyProductsUsed: [String]

    public init(
        id: String = UUID().uuidString,
        routineId: String,
        title: String,
        activityType: CareActivityType,
        timestamp: Date = Date(),
        durationMinutes: Int = 10,
        note: String = "",
        keyProductsUsed: [String] = []
    ) {
        self.id = id
        self.routineId = routineId
        self.title = title
        self.activityType = activityType
        self.timestamp = timestamp
        self.durationMinutes = durationMinutes
        self.note = note
        self.keyProductsUsed = keyProductsUsed
    }

    public var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: timestamp)
    }

    public var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: timestamp)
    }
}

