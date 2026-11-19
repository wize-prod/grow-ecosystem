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

    public static var daily: CustomRecurrenceRule {
        CustomRecurrenceRule(interval: 1, unit: .day, repeatDays: [])
    }

    public static var weekdays: CustomRecurrenceRule {
        CustomRecurrenceRule(interval: 1, unit: .week, repeatDays: [1, 2, 3, 4, 5])
    }

    public static func weekly(days: [Int] = [Calendar.current.component(.weekday, from: Date()) == 1 ? 7 : Calendar.current.component(.weekday, from: Date()) - 1]) -> CustomRecurrenceRule {
        CustomRecurrenceRule(interval: 1, unit: .week, repeatDays: days)
    }

    public static func biweekly(days: [Int] = [Calendar.current.component(.weekday, from: Date()) == 1 ? 7 : Calendar.current.component(.weekday, from: Date()) - 1]) -> CustomRecurrenceRule {
        CustomRecurrenceRule(interval: 2, unit: .week, repeatDays: days)
    }

    public static var monthly: CustomRecurrenceRule {
        CustomRecurrenceRule(interval: 1, unit: .month, repeatDays: [])
    }

    public func nextOccurrence(from date: Date) -> Date {
        let calendar = Calendar.current
        switch unit {
        case .day:
            return calendar.date(byAdding: .day, value: interval, to: date) ?? date.addingTimeInterval(Double(interval * 86400))
        case .week:
            if repeatDays.isEmpty {
                return calendar.date(byAdding: .weekOfYear, value: interval, to: date) ?? date.addingTimeInterval(Double(interval * 7 * 86400))
            }
            let currentWeekday = calendar.component(.weekday, from: date)
            let currentISOWeekday = currentWeekday == 1 ? 7 : currentWeekday - 1
            for day in repeatDays.sorted() {
                if day > currentISOWeekday {
                    let diff = day - currentISOWeekday
                    return calendar.date(byAdding: .day, value: diff, to: date) ?? date
                }
            }
            let firstDay = repeatDays.sorted().first ?? 1
            let daysToNext = (7 - currentISOWeekday) + (interval - 1) * 7 + firstDay
            return calendar.date(byAdding: .day, value: daysToNext, to: date) ?? date
        case .month:
            return calendar.date(byAdding: .month, value: interval, to: date) ?? date
        case .year:
            return calendar.date(byAdding: .year, value: interval, to: date) ?? date
        }
    }

    public func isScheduled(on targetDate: Date, startingFrom startDate: Date) -> Bool {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: startDate)
        let target = calendar.startOfDay(for: targetDate)
        if target < start { return false }
        if let end = endDate, target > calendar.startOfDay(for: end) { return false }

        switch unit {
        case .day:
            let days = calendar.dateComponents([.day], from: start, to: target).day ?? 0
            return days % interval == 0
        case .week:
            let weeks = calendar.dateComponents([.weekOfYear], from: start, to: target).weekOfYear ?? 0
            if interval > 1 && weeks % interval != 0 { return false }
            let weekday = calendar.component(.weekday, from: targetDate)
            let isoWeekday = weekday == 1 ? 7 : weekday - 1
            return repeatDays.isEmpty || repeatDays.contains(isoWeekday)
        case .month:
            let months = calendar.dateComponents([.month], from: start, to: target).month ?? 0
            let startDay = calendar.component(.day, from: startDate)
            let targetDay = calendar.component(.day, from: targetDate)
            return months % interval == 0 && startDay == targetDay
        case .year:
            let years = calendar.dateComponents([.year], from: start, to: target).year ?? 0
            let startDayOfYear = calendar.ordinality(of: .day, in: .year, for: startDate)
            let targetDayOfYear = calendar.ordinality(of: .day, in: .year, for: targetDate)
            return years % interval == 0 && startDayOfYear == targetDayOfYear
        }
    }
}
