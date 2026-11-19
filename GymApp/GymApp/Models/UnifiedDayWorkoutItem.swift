import Foundation

// MARK: - Unified Day Workout Item
// Vereint geplante Einheiten (PlannedWorkoutItem) und absolvierte Einheiten (WorkoutSession & ExternalWorkoutItem)
// in einer konsistenten Datenstruktur fuer Vergangenheit, Gegenwart und Zukunft.
public struct UnifiedDayWorkoutItem: Identifiable, Sendable {
    public enum Source: Sendable {
        case planned(PlannedWorkoutItem)
        case completedGrow(WorkoutSession)
        case completedExternal(ExternalWorkoutItem)
    }

    public let id: String
    public let title: String
    public let subtitle: String
    public let isCompleted: Bool
    public let date: Date
    public let source: Source

    public init(
        id: String,
        title: String,
        subtitle: String,
        isCompleted: Bool,
        date: Date = Date(),
        source: Source
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.isCompleted = isCompleted
        self.date = date
        self.source = source
    }
}
