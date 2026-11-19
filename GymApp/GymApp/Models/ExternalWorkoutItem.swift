import Foundation

public struct ExternalWorkoutItem: Identifiable, Codable, Equatable, Hashable {
    public var id: UUID
    public var title: String
    public var activityType: String // "Lauf", "Radfahrt", "Gehen", "Ruderergometer"
    public var startDate: Date
    public var durationSeconds: TimeInterval
    public var distanceMeters: Double?
    public var caloriesBurned: Double
    public var sourceName: String // "Strava", "Apple Health", "Garmin"
    public var averageHeartRate: Int?
    public var maxHeartRate: Int?

    public init(
        id: UUID = UUID(),
        title: String,
        activityType: String = "Lauf",
        startDate: Date = Date(),
        durationSeconds: TimeInterval,
        distanceMeters: Double? = nil,
        caloriesBurned: Double = 0.0,
        sourceName: String = "Strava",
        averageHeartRate: Int? = nil,
        maxHeartRate: Int? = nil
    ) {
        self.id = id
        self.title = title
        self.activityType = activityType
        self.startDate = startDate
        self.durationSeconds = durationSeconds
        self.distanceMeters = distanceMeters
        self.caloriesBurned = caloriesBurned
        self.sourceName = sourceName
        self.averageHeartRate = averageHeartRate
        self.maxHeartRate = maxHeartRate
    }

    public var distanceKmFormatted: String {
        guard let d = distanceMeters, d > 0 else { return "-" }
        let km = d / 1000.0
        return String(format: "%.2f km", km)
    }

    public var durationFormatted: String {
        let totalSec = Int(durationSeconds)
        let hours = totalSec / 3600
        let minutes = (totalSec % 3600) / 60
        let seconds = totalSec % 60
        if hours > 0 {
            return String(format: "%dh %02dm %02ds", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d min", minutes, seconds)
        }
    }

    public var caloriesBurnedFormatted: String {
        return String(format: "%.1f kcal", caloriesBurned)
    }

    public var averagePaceFormatted: String {
        guard let d = distanceMeters, d > 100, durationSeconds > 0 else { return "-" }
        let km = d / 1000.0
        let paceSecondsPerKm = durationSeconds / km
        let paceMin = Int(paceSecondsPerKm) / 60
        let paceSec = Int(paceSecondsPerKm) % 60
        return String(format: "%d:%02d /km", paceMin, paceSec)
    }

    public func asWorkoutSession() -> WorkoutSession {
        let act = activityType.lowercased()
        let isStrength = act.contains("kraft") || act.contains("strength") || act.contains("weight") || title.lowercased().contains("kraft")
        let rpe = isStrength ? 8 : (act.contains("lauf") || act.contains("run") ? 7 : 6)

        return WorkoutSession(
            id: self.id,
            title: self.title,
            startTime: self.startDate,
            endTime: self.startDate.addingTimeInterval(max(60.0, self.durationSeconds)),
            exercises: [],
            perceivedExertionRPE: rpe,
            somaticNotes: "Synchronisiert aus \(self.sourceName)",
            estimatedCaloriesBurned: self.caloriesBurned,
            prCount: 0,
            isSyncedToCalendar: false,
            isSyncedToHealthKit: true
        )
    }
}
