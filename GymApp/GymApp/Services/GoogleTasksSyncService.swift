import Foundation
import EventKit
import Combine

@MainActor
public final class GoogleTasksSyncService: ObservableObject {
    public static let shared = GoogleTasksSyncService()

    private let eventStore = EKEventStore()

    @Published public private(set) var isAuthorized: Bool = false
    @Published public var lastCheckedOffTaskTitle: String? = nil
    @Published public var lastCheckOffDate: Date? = nil

    private init() {
        checkAuthorization()
    }

    public func checkAuthorization() {
        let status = EKEventStore.authorizationStatus(for: .reminder)
        if #available(iOS 17.0, *) {
            isAuthorized = (status == .fullAccess)
        } else {
            isAuthorized = (status == .authorized)
        }
    }

    public func requestAccess() async -> Bool {
        #if targetEnvironment(simulator)
        self.isAuthorized = true
        return true
        #else
        do {
            let granted: Bool
            if #available(iOS 17.0, *) {
                granted = try await eventStore.requestFullAccessToReminders()
            } else {
                granted = try await eventStore.requestAccess(to: .reminder)
            }
            self.isAuthorized = granted
            return granted
        } catch {
            return false
        }
        #endif
    }

    /// Autonomes Abhaken der verknuepften Google Tasks Aufgabe in der Liste "Gesundheit"
    @discardableResult
    public func checkOffWorkoutTask(sessionTitle: String) async -> Bool {
        if !isAuthorized {
            let granted = await requestAccess()
            guard granted else { return false }
        }

        // Finde Erinnerungs-Listen mit Namen "Gesundheit" (oder aehnlich)
        let reminderCalendars = eventStore.calendars(for: .reminder)
        let targetCalendars = reminderCalendars.filter { cal in
            let title = cal.title.lowercased()
            return title.contains("gesundheit") || title.contains("health") || title.contains("training")
        }

        let calendarsToSearch = targetCalendars.isEmpty ? reminderCalendars : targetCalendars

        // Erstelle Praedikat fuer unvollstaendige Aufgaben
        let predicate = eventStore.predicateForIncompleteReminders(
            withDueDateStarting: Calendar.current.startOfDay(for: Date()),
            ending: Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date())),
            calendars: calendarsToSearch
        )

        return await withCheckedContinuation { continuation in
            eventStore.fetchReminders(matching: predicate) { [weak self] reminders in
                guard let self = self, let reminders = reminders, !reminders.isEmpty else {
                    continuation.resume(returning: false)
                    return
                }

                // Suche nach passender Aufgabe: Titel matching Session-Titel, "training", "workout", "kraft", "mvpa", "sport"
                let lowerSession = sessionTitle.lowercased()
                let candidate = reminders.first { reminder in
                    let t = reminder.title.lowercased()
                    return t.contains(lowerSession) ||
                           lowerSession.contains(t) ||
                           t.contains("training") ||
                           t.contains("workout") ||
                           t.contains("kraft") ||
                           t.contains("mvpa") ||
                           t.contains("sport")
                } ?? reminders.first

                guard let taskToComplete = candidate else {
                    continuation.resume(returning: false)
                    return
                }

                taskToComplete.isCompleted = true
                taskToComplete.completionDate = Date()

                do {
                    try self.eventStore.save(taskToComplete, commit: true)
                    Task { @MainActor in
                        self.lastCheckedOffTaskTitle = taskToComplete.title
                        self.lastCheckOffDate = Date()
                    }
                    continuation.resume(returning: true)
                } catch {
                    continuation.resume(returning: false)
                }
            }
        }
    }
}
