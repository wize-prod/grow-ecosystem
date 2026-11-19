import Foundation

public enum RecurrenceUnit: String, CaseIterable, Codable, Identifiable {
    case day = "day"
    case week = "week"
    case month = "month"
    case year = "year"

    public var id: String { rawValue }

    public var localizedSingular: String {
        switch self {
        case .day: return "Tag"
        case .week: return "Woche"
        case .month: return "Monat"
        case .year: return "Jahr"
        }
    }

    public var localizedPlural: String {
        switch self {
        case .day: return "Tage"
        case .week: return "Wochen"
        case .month: return "Monate"
        case .year: return "Jahre"
        }
    }
}

public enum RecurrenceEndType: String, Codable {
    case never = "never"
    case onDate = "onDate"
    case afterOccurrences = "afterOccurrences"
}

public struct CustomRecurrenceRule: Codable, Equatable, Hashable {
    public var interval: Int
    public var unit: RecurrenceUnit
    public var repeatDays: [Int] // 1 = Monday, 2 = Tuesday, ..., 7 = Sunday
    public var endType: RecurrenceEndType
    public var endDate: Date?
    public var maxOccurrences: Int?
    public var completedOccurrences: Int

    public init(
        interval: Int = 1,
        unit: RecurrenceUnit = .week,
        repeatDays: [Int] = [Calendar.current.component(.weekday, from: Date()) == 1 ? 7 : Calendar.current.component(.weekday, from: Date()) - 1],
        endType: RecurrenceEndType = .never,
        endDate: Date? = nil,
        maxOccurrences: Int? = 13,
        completedOccurrences: Int = 0
    ) {
        self.interval = max(1, interval)
        self.unit = unit
        self.repeatDays = repeatDays.sorted()
        self.endType = endType
        self.endDate = endDate
        self.maxOccurrences = maxOccurrences
        self.completedOccurrences = completedOccurrences
    }

    public var summaryText: String {
        let unitText = interval == 1 ? unit.localizedSingular : "\(interval) \(unit.localizedPlural)"
        var text = "Alle \(unitText)"

        if unit == .week && !repeatDays.isEmpty {
            let dayNames = ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"]
            let selectedNames = repeatDays.compactMap { dayIndex -> String? in
                guard dayIndex >= 1 && dayIndex <= 7 else { return nil }
                return dayNames[dayIndex - 1]
            }
            if !selectedNames.isEmpty {
                text += " (\(selectedNames.joined(separator: ", ")))"
            }
        }

        switch endType {
        case .never:
            break
        case .onDate:
            if let date = endDate {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .none
                text += ", bis \(formatter.string(from: date))"
            }
        case .afterOccurrences:
            if let max = maxOccurrences {
                text += ", \(max)x"
            }
        }

        return text
    }

    public var isExpired: Bool {
        switch endType {
        case .never:
            return false
        case .onDate:
            if let endDate = endDate {
                return Date() > endDate
            }
            return false
        case .afterOccurrences:
            if let max = maxOccurrences {
                return completedOccurrences >= max
            }
            return false
        }
    }
}
