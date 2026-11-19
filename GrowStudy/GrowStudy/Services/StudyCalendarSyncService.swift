import Foundation
import EventKit
import Combine

@MainActor
public final class StudyCalendarSyncService: ObservableObject {
    public static let shared = StudyCalendarSyncService()

    private let eventStore = EKEventStore()
    public let targetAccountEmail = "wize.prod6878@gmail.com"

    @Published public private(set) var isAuthorized: Bool = false
    @Published public private(set) var activeCalendarTitle: String = "Nicht verbunden"
    @Published public private(set) var lastSyncDate: Date? = nil
    @Published public private(set) var lastSyncResult: String = ""
    @Published public private(set) var isSyncing: Bool = false

    private init() {
        checkAuthorization()
    }

    public func checkAuthorization() {
        let status = EKEventStore.authorizationStatus(for: .event)
        if #available(iOS 17.0, *) {
            isAuthorized = (status == .fullAccess || status == .writeOnly)
        } else {
            isAuthorized = (status == .authorized)
        }

        if isAuthorized {
            if let cal = resolveTargetCalendar() {
                activeCalendarTitle = "\(cal.title) (\(cal.source.title))"
            } else {
                activeCalendarTitle = "Standard-Kalender"
            }
        } else {
            activeCalendarTitle = "Nicht autorisiert"
        }
    }

    @discardableResult
    public func requestAccess() async -> Bool {
        do {
            let granted: Bool
            if #available(iOS 17.0, *) {
                granted = try await eventStore.requestFullAccessToEvents()
            } else {
                granted = try await eventStore.requestAccess(to: .event)
            }

            if granted {
                eventStore.reset()
            }

            self.isAuthorized = granted
            if granted, let cal = self.resolveTargetCalendar() {
                self.activeCalendarTitle = "\(cal.title) (\(cal.source.title))"
                self.lastSyncResult = "Berechtigung erteilt: \(self.activeCalendarTitle)"
            }

            return granted
        } catch {
            print("StudyCalendarSyncService requestAccess error: \(error)")
            self.isAuthorized = false
            self.lastSyncResult = "Fehler bei Berechtigung: \(error.localizedDescription)"
            return false
        }
    }

    public func resolveTargetCalendar() -> EKCalendar? {
        let calendars = eventStore.calendars(for: .event)

        // 1. Check account email match in calendar title or source title
        if let match = calendars.first(where: {
            $0.title.lowercased().contains(targetAccountEmail.lowercased()) ||
            $0.source.title.lowercased().contains(targetAccountEmail.lowercased())
        }) {
            return match
        }

        // 2. Check CalDAV / Google source
        if let googleCal = calendars.first(where: {
            $0.source.sourceType == .calDAV &&
            ($0.source.title.lowercased().contains("google") || $0.source.title.lowercased().contains("gmail"))
        }) {
            return googleCal
        }

        // 3. Fallback to default calendar for new events
        return eventStore.defaultCalendarForNewEvents
    }

    @discardableResult
    public func syncPlannedStudyEvent(
        title: String,
        track: StudyTrack,
        date: Date,
        durationMinutes: Int = 45,
        notes: String = "",
        existingEventId: String? = nil
    ) async -> (success: Bool, eventId: String?, message: String) {
        if !isAuthorized {
            let granted = await requestAccess()
            if !granted {
                return (false, nil, "Kein Kalender-Zugriff erteilt.")
            }
        }

        guard let targetCal = resolveTargetCalendar() else {
            return (false, nil, "Kein passender Google-Kalender gefunden.")
        }

        isSyncing = true
        defer { isSyncing = false }

        do {
            let event: EKEvent
            if let existingId = existingEventId, let found = eventStore.event(withIdentifier: existingId) {
                event = found
            } else {
                event = EKEvent(eventStore: eventStore)
            }

            event.calendar = targetCal
            event.title = "[\(track.shortTitle)] \(title)"
            event.startDate = date
            event.endDate = date.addingTimeInterval(Double(durationMinutes * 60))
            
            var desc = "Lerneinheit: \(track.rawValue)\nGeplante Dauer: \(durationMinutes) Minuten\n"
            if !notes.isEmpty {
                desc += "\nDetails:\n\(notes)"
            }
            desc += "\n\nAutomatisch synchronisiert von GrowStudy."
            event.notes = desc

            // Push notification 10 minutes prior and at event start
            event.alarms = [
                EKAlarm(relativeOffset: -600), // 10 minutes before
                EKAlarm(relativeOffset: 0)     // On time
            ]

            try eventStore.save(event, span: .thisEvent, commit: true)
            self.lastSyncDate = Date()
            self.lastSyncResult = "Erfolgreich in Kalender synchronisiert."
            return (true, event.eventIdentifier, "Synchronisiert mit \(targetCal.title)")
        } catch {
            print("StudyCalendarSyncService sync error: \(error)")
            self.lastSyncResult = "Fehler beim Sync: \(error.localizedDescription)"
            return (false, nil, error.localizedDescription)
        }
    }

    public func removeEvent(withIdentifier identifier: String) {
        guard isAuthorized else { return }
        if let event = eventStore.event(withIdentifier: identifier) {
            try? eventStore.remove(event, span: .thisEvent, commit: true)
        }
    }
}
