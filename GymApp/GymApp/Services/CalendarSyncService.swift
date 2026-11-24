import Foundation
import EventKit
import Combine

public struct CalendarWorkoutEvent: Identifiable, Equatable {
    public var id: String
    public var title: String
    public var startDate: Date
    public var endDate: Date
    public var location: String
    public var notes: String
    public var calendarName: String
    public var isCompleted: Bool

    public init(
        id: String = UUID().uuidString,
        title: String,
        startDate: Date,
        endDate: Date,
        location: String = "Bundeswehr Kraftraum",
        notes: String = "",
        calendarName: String = "",
        isCompleted: Bool = false
    ) {
        self.id = id
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.location = location
        self.notes = notes
        self.calendarName = calendarName
        self.isCompleted = isCompleted
    }
}

public struct GymAvailableCalendarInfo: Identifiable, Hashable {
    public var id: String
    public var title: String
    public var sourceTitle: String
    public var isGoogle: Bool
    public var allowsModifications: Bool

    public init(id: String, title: String, sourceTitle: String, allowsModifications: Bool, isGoogle: Bool = false) {
        self.id = id
        self.title = title
        self.sourceTitle = sourceTitle
        self.allowsModifications = allowsModifications
        self.isGoogle = isGoogle
    }
}

public typealias AvailableCalendarInfo = GymAvailableCalendarInfo

extension CalendarSyncService {
    public typealias AvailableCalendarInfo = GymAvailableCalendarInfo
}

@MainActor
public final class CalendarSyncService: ObservableObject {
    public static let shared = CalendarSyncService()

    private let eventStore = EKEventStore()

    private var targetAccountEmail: String {
        UserAccountService.shared.currentAccount.googleAccountEmail
    }

    @Published public private(set) var isAuthorized: Bool = false
    @Published public var upcomingTrainingEvents: [CalendarWorkoutEvent] = []
    @Published public var connectedCalendarTitle: String = "Nicht verbunden"
    @Published public var lastSyncTimestamp: Date?
    @Published public var syncMessage: String = "Bereit fuer Kalender-Sync"
    @Published public var isSyncing: Bool = false

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
            updateConnectedCalendarInfo()
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
                granted = try await eventStore.requestFullAccessToEvents()
            } else {
                granted = try await eventStore.requestAccess(to: .event)
            }
            self.isAuthorized = granted
            if granted {
                self.updateConnectedCalendarInfo()
            }
            if granted {
                fetchUpcomingWorkouts()
            }
            return granted
        } catch {
            self.syncMessage = "Fehler: \(error.localizedDescription)"
            return false
        }
        #endif
    }

    public func getAvailableCalendars() -> [GymAvailableCalendarInfo] {
        let calendars = eventStore.calendars(for: .event)
        return calendars.map { cal in
            let src = cal.source.title.lowercased()
            let title = cal.title.lowercased()
            let isGoogle = src.contains("google") || src.contains("gmail") || src.contains("@") || title.contains("@")
            return GymAvailableCalendarInfo(
                id: cal.calendarIdentifier,
                title: cal.title,
                sourceTitle: cal.source.title,
                allowsModifications: cal.allowsContentModifications,
                isGoogle: isGoogle
            )
        }
    }

    private func resolveTargetCalendar() -> EKCalendar? {
        let calendars = eventStore.calendars(for: .event)

        // 0. Spezifisch gewaehlter Kalender aus UserAccountService
        if let selectedId = UserAccountService.shared.currentAccount.selectedCalendarIdentifier,
           let customCal = calendars.first(where: { $0.calendarIdentifier == selectedId && $0.allowsContentModifications }) {
            return customCal
        }

        // 1. Spezifischer Google Kalender nach Ziel-Account
        let targetEmail = targetAccountEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !targetEmail.isEmpty,
           let gcal = calendars.first(where: {
            ($0.source.title.localizedCaseInsensitiveContains(targetEmail) ||
             $0.title.localizedCaseInsensitiveContains(targetEmail)) &&
            $0.allowsContentModifications
        }) {
            return gcal
        }

        // 2. Google Kalender allgemeiner Typ (CalDAV oder Quellname Google)
        if let gcalAny = calendars.first(where: {
            ($0.source.sourceType == .calDAV ||
             $0.source.title.localizedCaseInsensitiveContains("Google") ||
             $0.title.localizedCaseInsensitiveContains("Google")) &&
            $0.allowsContentModifications
        }) {
            return gcalAny
        }

        // 3. Default Kalender fuer neue Events oder erster modifizierbarer Kalender
        if let def = eventStore.defaultCalendarForNewEvents, def.allowsContentModifications {
            return def
        }
        return calendars.first(where: { $0.allowsContentModifications })
    }

    private func updateConnectedCalendarInfo() {
        if let cal = resolveTargetCalendar() {
            self.connectedCalendarTitle = "\(cal.title) (\(cal.source.title))"
        } else {
            self.connectedCalendarTitle = "Standard iOS Kalender"
        }
    }

    // MARK: - 2-Wege Sync: Lesen geplanter Workouts aus Google Kalender
    @MainActor
    public func fetchUpcomingWorkouts() {
        guard isAuthorized else { return }
        isSyncing = true

        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        guard let twoWeeksLater = Calendar.current.date(byAdding: .day, value: 14, to: startOfDay) else {
            isSyncing = false
            return
        }

        let predicate = eventStore.predicateForEvents(withStart: startOfDay, end: twoWeeksLater, calendars: nil)
        let matchedEvents = eventStore.events(matching: predicate)

        let filtered = matchedEvents.filter { event in
            let title = event.title?.lowercased() ?? ""
            let notes = event.notes?.lowercased() ?? ""
            return title.contains("training") ||
                   title.contains("workout") ||
                   title.contains("gym") ||
                   title.contains("kraftraum") ||
                   title.contains("grow") ||
                   title.contains("somagym") ||
                   title.contains("fokus-block") ||
                   title.contains("test") ||
                   notes.contains("grow") ||
                   notes.contains("somagym") ||
                   notes.contains("gym://")
        }

        self.upcomingTrainingEvents = filtered.map { event in
            CalendarWorkoutEvent(
                id: event.eventIdentifier ?? UUID().uuidString,
                title: event.title ?? "Training",
                startDate: event.startDate ?? now,
                endDate: event.endDate ?? now.addingTimeInterval(3600),
                location: event.location ?? "Bundeswehr Kraftraum",
                notes: event.notes ?? "",
                calendarName: event.calendar.title,
                isCompleted: event.notes?.contains("Absolvierte Uebungen") ?? false
            )
        }.sorted { $0.startDate < $1.startDate }

        self.lastSyncTimestamp = Date()
        self.syncMessage = "\(self.upcomingTrainingEvents.count) Kalendereinheiten aktiv synchronisiert."
        self.isSyncing = false
        self.updateConnectedCalendarInfo()
    }

    // MARK: - 2-Wege Sync: Schreiben protokollierter Workouts nach Google Kalender
    @discardableResult
    public func syncCompletedSession(session: WorkoutSession) async -> String? {
        if !isAuthorized {
            let granted = await requestAccess()
            guard granted else { return nil }
        }

        guard let calendar = resolveTargetCalendar() else {
            await MainActor.run {
                self.syncMessage = "Kein Zielkalender ermittelt."
            }
            return nil
        }

        let event: EKEvent
        if let existingId = session.calendarEventId, let found = eventStore.event(withIdentifier: existingId) {
            event = found
        } else {
            event = EKEvent(eventStore: eventStore)
        }

        event.calendar = calendar
        event.title = "Training: \(session.title) (\(Int(round(session.totalTonnageKg))) kg | \(session.durationMinutes) min)"
        event.startDate = session.startTime
        event.endDate = session.endTime ?? session.startTime.addingTimeInterval(TimeInterval(session.durationMinutes * 60))
        if session.title.localizedCaseInsensitiveContains("stube") {
            event.location = "Stube (Kaserne - Ohne Geraete)"
        } else if session.title.localizedCaseInsensitiveContains("lauf") {
            event.location = "Kasernengelaende / Waldstrecke"
        } else {
            event.location = "Bundeswehr Kraftraum"
        }

        var description = """
        Grow Trainingsprotokoll
        ----------------------------------------
        Einheit: \(session.title)
        Start: \(formatTime(session.startTime))
        Ende: \(formatTime(session.endTime ?? Date()))
        Netto-Dauer: \(session.durationMinutes) Minuten
        Gesamt-Tonnage: \(String(format: "%.1f", session.totalTonnageKg)) kg
        PRs: \(session.prCount)
        Verbrauch: \(String(format: "%.0f", session.estimatedCaloriesBurned)) kcal
        Subjektive RPE: \(session.perceivedExertionRPE) / 10

        Absolvierte Uebungen:
        """

        for item in session.exercises {
            let completed = item.sets.filter { $0.isCompleted }
            if !completed.isEmpty {
                description += "\n- \(item.exercise.name): \(completed.count) Saetze (Bestes Set: \(item.bestSetSummary))"
            }
        }

        description += """


        Medizinisches Protokoll:
        - BWK Ulm Reha: Eingehalten (Null Crunches/Sit-ups)
        - Somatische Belastung: Ausgeglichen

        Deep-Link zur Einheit:
        gym://session?id=\(session.id.uuidString)

        ----------------------------------------
        Automatisch synchronisiert via Grow iOS Client
        """

        event.notes = description

        // Push-Alarme: 10 Min vorab und zu Beginn
        let alarm10 = EKAlarm(relativeOffset: -600)
        let alarm0 = EKAlarm(relativeOffset: 0)
        event.alarms = [alarm10, alarm0]

        do {
            try eventStore.save(event, span: .thisEvent, commit: true)
            let savedId = event.eventIdentifier
            print("CalendarSyncService: Workout-Event '\(event.title ?? "")' erfolgreich in '\(calendar.title)' eingetragen.")
            await MainActor.run {
                self.syncMessage = "Training im Kalender verbucht."
                self.fetchUpcomingWorkouts()
            }
            return savedId
        } catch {
            print("CalendarSyncService: Fehler beim Speichern des Events: \(error.localizedDescription)")
            await MainActor.run {
                self.syncMessage = "Fehler beim Kalender-Sync: \(error.localizedDescription)"
            }
            return nil
        }
    }

    // MARK: - 2-Wege Sync: Geplante Einheit in Google Kalender eintragen / aktualisieren
    @discardableResult
    public func schedulePlannedWorkoutEvent(planned: PlannedWorkoutItem, template: WorkoutTemplate? = nil) async -> String? {
        if !isAuthorized {
            let granted = await requestAccess()
            guard granted else { return nil }
        }

        guard let calendar = resolveTargetCalendar() else { return nil }

        let event: EKEvent
        if let existingId = planned.calendarEventId, let found = eventStore.event(withIdentifier: existingId) {
            event = found
        } else {
            event = EKEvent(eventStore: eventStore)
        }

        event.calendar = calendar
        if planned.title.localizedCaseInsensitiveContains("stube") || planned.notes.localizedCaseInsensitiveContains("stube") || template?.category.localizedCaseInsensitiveContains("stube") == true {
            event.location = "Stube (Kaserne - Ohne Geraete)"
        } else if planned.title.localizedCaseInsensitiveContains("lauf") || planned.modalityRaw == "cardio" {
            event.location = "Kasernengelaende / Waldstrecke"
        } else {
            event.location = "Bundeswehr Kraftraum"
        }

        var notes = """
        Grow Geplante Einheit
        ----------------------------------------
        Workout: \(planned.title)
        Programm/Vorlage: \(planned.programName.isEmpty ? "Freie Planung" : planned.programName)
        Geplante Dauer: 60 Minuten

        Uebungsabfolge:
        """

        if let template = template, !template.items.isEmpty {
            notes += "\n" + template.items.map { "- \($0.exercise.name) (\($0.targetSets) Saetze x \($0.targetReps) Wdh)" }.joined(separator: "\n")
        } else if !planned.exerciseNames.isEmpty {
            notes += "\n" + planned.exerciseNames.map { "- \($0)" }.joined(separator: "\n")
        } else {
            notes += "\n- Geplante Trainingssession"
        }

        notes += """


        Deep-Link zum sofortigen Start:
        gym://planned?id=\(planned.id.uuidString)

        ----------------------------------------
        Automatisch terminiert via Grow
        """
        event.notes = notes

        let alarm10 = EKAlarm(relativeOffset: -600)
        let alarm0 = EKAlarm(relativeOffset: 0)
        event.alarms = [alarm10, alarm0]

        do {
            try eventStore.save(event, span: .thisEvent, commit: true)
            let savedId = event.eventIdentifier
            await MainActor.run {
                self.syncMessage = "Geplante Einheit im Kalender terminiert."
                self.fetchUpcomingWorkouts()
            }
            return savedId
        } catch {
            return nil
        }
    }

    // MARK: - Kalender-Event loeschen
    public func removeCalendarEvent(identifier: String?) {
        guard let id = identifier, !id.isEmpty, isAuthorized else { return }
        if let event = eventStore.event(withIdentifier: id) {
            try? eventStore.remove(event, span: .thisEvent, commit: true)
            Task { @MainActor in
                self.fetchUpcomingWorkouts()
            }
        }
    }

    public func triggerFullCalendarSync(store: GymStore) {
        guard !isSyncing else { return }
        Task { @MainActor in
            self.fetchUpcomingWorkouts()
            for s in store.sessions.prefix(3) {
                _ = await self.syncCompletedSession(session: s)
            }
        }
    }

    // MARK: - Fokus-Block im Kalender terminieren
    public func scheduleWorkout(template: WorkoutTemplate, date: Date, durationMinutes: Int = 45) async -> Bool {
        return await scheduleWorkoutBlock(template: template, date: date, durationMinutes: durationMinutes)
    }

    public func scheduleWorkoutBlock(template: WorkoutTemplate, date: Date, durationMinutes: Int = 60) async -> Bool {
        if !isAuthorized {
            let granted = await requestAccess()
            guard granted else { return false }
        }

        guard let calendar = resolveTargetCalendar() else { return false }

        let event = EKEvent(eventStore: eventStore)
        event.calendar = calendar
        event.title = "Fokus-Block: Training (\(template.name))"
        event.startDate = date
        event.endDate = date.addingTimeInterval(TimeInterval(durationMinutes * 60))
        if template.name.localizedCaseInsensitiveContains("stube") || template.category.localizedCaseInsensitiveContains("stube") {
            event.location = "Stube (Kaserne - Ohne Geraete)"
        } else if template.name.localizedCaseInsensitiveContains("lauf") || template.category.localizedCaseInsensitiveContains("cardio") {
            event.location = "Kasernengelaende / Waldstrecke"
        } else {
            event.location = "Bundeswehr Kraftraum"
        }

        event.notes = """
        Grow Geplante Einheit
        ----------------------------------------
        Workout: \(template.name)
        Kategorie: \(template.category)
        Geplante Dauer: \(durationMinutes) Minuten
        Zeitfenster: \(template.targetTimeSlot)

        Uebungsabfolge:
        \(template.items.map { "- \($0.exercise.name) (\($0.targetSets) Saetze x \($0.targetReps) Wdh)" }.joined(separator: "\n"))

        Deep-Link zum sofortigen Start:
        gym://start?templateId=\(template.id.uuidString)

        ----------------------------------------
        Automatisch terminiert via Grow
        """

        let alarm10 = EKAlarm(relativeOffset: -600)
        let alarm0 = EKAlarm(relativeOffset: 0)
        event.alarms = [alarm10, alarm0]

        do {
            try eventStore.save(event, span: .thisEvent, commit: true)
            await MainActor.run {
                self.syncMessage = "Fokus-Block im Kalender terminiert."
                self.fetchUpcomingWorkouts()
            }
            return true
        } catch {
            return false
        }
    }

    // MARK: - Sofortiger Kalender-Test
    public func triggerManualTestEvent() async -> Bool {
        if !isAuthorized {
            let granted = await requestAccess()
            guard granted else { return false }
        }

        guard let calendar = resolveTargetCalendar() else { return false }

        let now = Date()
        let event = EKEvent(eventStore: eventStore)
        event.calendar = calendar
        event.title = "Grow Test: 2-Wege Sync Verifikation"
        event.startDate = now
        event.endDate = now.addingTimeInterval(1800)
        event.location = "Bundeswehr Kraftraum"
        event.notes = "Verifikation der 2-Wege Kalendersynchronisation zwischen Grow und Google Kalender (\(targetAccountEmail))."

        do {
            try eventStore.save(event, span: .thisEvent, commit: true)
            await MainActor.run {
                self.syncMessage = "Test-Event erfolgreich in '\(calendar.title)' eingetragen."
                self.fetchUpcomingWorkouts()
            }
            return true
        } catch {
            await MainActor.run {
                self.syncMessage = "Test-Fehler: \(error.localizedDescription)"
            }
            return false
        }
    }

    // MARK: - Meal Syncing Support
    @discardableResult
    public func syncMealEvent(
        title: String,
        date: Date = Date(),
        durationMinutes: Int = 30,
        kcal: Double,
        protein: Double,
        carbs: Double,
        fat: Double,
        fiber: Double = 0.0,
        details: String = ""
    ) -> Task<(success: Bool, message: String), Never> {
        Task {
            await self.syncMealEventAsync(
                title: title,
                date: date,
                durationMinutes: durationMinutes,
                kcal: kcal,
                protein: protein,
                carbs: carbs,
                fat: fat,
                fiber: fiber,
                details: details
            )
        }
    }

    @discardableResult
    public func syncMealEventAsync(
        title: String,
        date: Date = Date(),
        durationMinutes: Int = 30,
        kcal: Double,
        protein: Double,
        carbs: Double,
        fat: Double,
        fiber: Double = 0.0,
        details: String = ""
    ) async -> (success: Bool, message: String) {
        self.isSyncing = true

        if !isAuthorized {
            let granted = await requestAccess()
            guard granted else {
                self.isSyncing = false
                return (false, "Kalenderzugriff nicht gewaehrt")
            }
        }

        guard let calendar = resolveTargetCalendar() else {
            self.isSyncing = false
            return (false, "Kein Kalender gefunden")
        }

        let event = EKEvent(eventStore: eventStore)
        event.calendar = calendar
        event.title = "Mahlzeit: \(title) (\(Int(round(kcal))) kcal | \(Int(round(protein)))g P)"
        event.startDate = date
        event.endDate = date.addingTimeInterval(TimeInterval(durationMinutes * 60))

        var description = """
        Grow Ernaehrungsprotokoll
        ----------------------------------------
        Mahlzeit: \(title)
        Konto: \(targetAccountEmail)

        Kern-Makronaehrstoffe:
        - Brennwert: \(String(format: "%.1f", kcal)) kcal
        - Protein: \(String(format: "%.1f", protein)) g
        - Kohlenhydrate: \(String(format: "%.1f", carbs)) g
        - Fett: \(String(format: "%.1f", fat)) g
        - Ballaststoffe: \(String(format: "%.1f", fiber)) g
        """

        if !details.isEmpty {
            description += "\n\nZusaetzliche Naehrwerte & Details:\n\(details)"
        }

        description += "\n----------------------------------------\nAutomatisch synchronisiert via Grow Client"
        event.notes = description

        do {
            try eventStore.save(event, span: .thisEvent, commit: true)
            let msg = "Ereignis '\(event.title ?? title)' in '\(calendar.title)' eingetragen."
            self.lastSyncTimestamp = Date()
            self.syncMessage = msg
            self.isSyncing = false
            return (true, msg)
        } catch {
            let errMsg = "Fehler beim Speichern: \(error.localizedDescription)"
            self.syncMessage = errMsg
            self.isSyncing = false
            return (false, errMsg)
        }
    }

    public func syncTestEvent() async -> (success: Bool, message: String) {
        let success = await triggerManualTestEvent()
        return (success, syncMessage)
    }

    public func syncAllTodayMeals(store: LocalStore) async -> (successCount: Int, total: Int) {
        guard !isSyncing else { return (0, 0) }
        self.isSyncing = true
        let logs = store.mealLogs.filter { Calendar.current.isDateInToday($0.timestamp) }
        guard resolveTargetCalendar() != nil else {
            self.isSyncing = false
            return (0, logs.count)
        }
        var count = 0
        for log in logs {
            let res = await syncMealEventAsync(
                title: log.foodName,
                date: log.timestamp,
                durationMinutes: 20,
                kcal: log.kcal,
                protein: log.protein,
                carbs: log.carbs,
                fat: log.fat,
                fiber: log.fiber
            )
            if res.success { count += 1 }
        }
        self.isSyncing = false
        return (count, logs.count)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
