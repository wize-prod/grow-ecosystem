import Foundation
import EventKit
import Combine

public struct CalendarFinanceEvent: Identifiable, Equatable {
    public let id: String
    public let title: String
    public let startDate: Date
    public let amount: Double
    public let isIncome: Bool
    public let notes: String
    public let calendarName: String

    public init(
        id: String = UUID().uuidString,
        title: String,
        startDate: Date,
        amount: Double,
        isIncome: Bool,
        notes: String = "",
        calendarName: String = "Google Kalender"
    ) {
        self.id = id
        self.title = title
        self.startDate = startDate
        self.amount = amount
        self.isIncome = isIncome
        self.notes = notes
        self.calendarName = calendarName
    }
}

public final class CalendarSyncService: ObservableObject {
    public static let shared = CalendarSyncService()

    private let eventStore = EKEventStore()
    private let targetAccountEmail = "wize.prod6878@gmail.com"

    @Published public private(set) var isAuthorized: Bool = false
    @Published public var upcomingEvents: [CalendarFinanceEvent] = []
    @Published public var connectedCalendarTitle: String = "Nicht verbunden"
    @Published public var lastSyncTimestamp: Date?
    @Published public var syncMessage: String = "Bereit für Kalender-Sync"
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
        do {
            let granted: Bool
            if #available(iOS 17.0, *) {
                granted = try await eventStore.requestFullAccessToEvents()
            } else {
                granted = try await eventStore.requestAccess(to: .event)
            }
            await MainActor.run {
                self.isAuthorized = granted
                if granted {
                    self.updateConnectedCalendarInfo()
                }
            }
            if granted {
                await fetchUpcomingEvents()
            }
            return granted
        } catch {
            await MainActor.run {
                self.syncMessage = "Fehler: \(error.localizedDescription)"
            }
            return false
        }
    }

    private func resolveTargetCalendar() -> EKCalendar? {
        let calendars = eventStore.calendars(for: .event)
        // 1. Google Kalender nach Ziel-Account
        if let gcal = calendars.first(where: {
            ($0.source.title.localizedCaseInsensitiveContains(targetAccountEmail) ||
             $0.title.localizedCaseInsensitiveContains(targetAccountEmail)) &&
            $0.allowsContentModifications
        }) {
            return gcal
        }
        // 2. Primärer Default-Kalender
        if let defCal = eventStore.defaultCalendarForNewEvents, defCal.allowsContentModifications {
            return defCal
        }
        // 3. Beliebiger modifizierbarer Kalender
        return calendars.first(where: { $0.allowsContentModifications })
    }

    private func updateConnectedCalendarInfo() {
        if let cal = resolveTargetCalendar() {
            self.connectedCalendarTitle = "\(cal.title) (\(cal.source.title))"
        } else {
            self.connectedCalendarTitle = "Standard-Kalender"
        }
    }

    @MainActor
    public func fetchUpcomingEvents() async {
        guard isAuthorized else { return }
        self.isSyncing = true
        self.syncMessage = "Synchronisiere mit Google Kalender..."

        let now = Date()
        let start = Calendar.current.date(byAdding: .day, value: -14, to: now) ?? now
        let end = Calendar.current.date(byAdding: .day, value: 30, to: now) ?? now

        let targetCal = resolveTargetCalendar()
        let cals = targetCal != nil ? [targetCal!] : nil
        let predicate = eventStore.predicateForEvents(withStart: start, end: end, calendars: cals)
        let events = eventStore.events(matching: predicate)

        var result: [CalendarFinanceEvent] = []
        for ev in events {
            let title = ev.title ?? "Finanztermin"
            var amount = 0.0
            var isIncome = false

            // Parse optional amount and type from notes or title
            if let notes = ev.notes, let match = notes.range(of: #"([-+]?\d+[.,]?\d*)\s*€?"#, options: .regularExpression) {
                let numStr = String(notes[match]).replacingOccurrences(of: "€", with: "").trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")
                if let parsed = Double(numStr) {
                    amount = abs(parsed)
                    isIncome = parsed > 0 || notes.contains("+")
                }
            }

            result.append(CalendarFinanceEvent(
                id: ev.eventIdentifier,
                title: title,
                startDate: ev.startDate,
                amount: amount,
                isIncome: isIncome,
                notes: ev.notes ?? "",
                calendarName: ev.calendar.title
            ))
        }

        self.upcomingEvents = result.sorted { $0.startDate < $1.startDate }
        self.lastSyncTimestamp = Date()
        self.isSyncing = false
        self.syncMessage = "\(result.count) Termine geladen"
    }

    public func scheduleFinanceEvent(title: String, date: Date, amount: Double, isIncome: Bool, notes: String) async -> Bool {
        if !isAuthorized {
            let ok = await requestAccess()
            guard ok else { return false }
        }
        guard let cal = resolveTargetCalendar() else { return false }

        let event = EKEvent(eventStore: eventStore)
        event.title = "GrowFinance • \(title)"
        event.calendar = cal
        event.startDate = date
        event.endDate = Calendar.current.date(byAdding: .hour, value: 1, to: date) ?? date
        event.notes = "\(notes)\nBetrag: \(String(format: "%.2f €", amount))\nKategorie: \(isIncome ? "Einnahme" : "Fixkosten")"

        let alarm = EKAlarm(relativeOffset: -86400) // 1 day before
        event.addAlarm(alarm)

        do {
            try eventStore.save(event, span: .thisEvent)
            await fetchUpcomingEvents()
            return true
        } catch {
            print("Fehler beim Kalendereintrag: \(error.localizedDescription)")
            return false
        }
    }
}
