import Foundation
import EventKit
import Combine
import UIKit

@MainActor
public final class CalendarSyncService: ObservableObject {
    public static let shared = CalendarSyncService()

    private let eventStore = EKEventStore()
    public var targetAccountEmail: String {
        let email = UserAccountService.shared.currentAccount.googleAccountEmail
        if !email.isEmpty { return email }
        return UIDevice.current.userInterfaceIdiom == .pad ? "" : "wize.prod6878@gmail.com"
    }

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
            print("CalendarSyncService requestAccess error: \(error)")
            self.isAuthorized = false
            self.lastSyncResult = "Fehler bei Berechtigung: \(error.localizedDescription)"
            return false
        }
    }

    // Synchronous dispatch helper for LocalStore caller convenience
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
                self.lastSyncResult = "Kalenderzugriff nicht gewährt"
                return (false, "Kalenderzugriff nicht gewährt")
            }
        }

        guard let calendar = resolveTargetCalendar() else {
            self.isSyncing = false
            self.lastSyncResult = "Keine beschreibbare Kalender-Instanz gefunden"
            return (false, "Kein Kalender gefunden")
        }

        let event = EKEvent(eventStore: eventStore)
        event.calendar = calendar
        event.title = "Mahlzeit: \(title) (\(Int(round(kcal))) kcal | \(Int(round(protein)))g P)"
        event.startDate = date
        event.endDate = date.addingTimeInterval(TimeInterval(durationMinutes * 60))

        var description = """
        Growcery Ernährungsprotokoll
        ----------------------------------------
        Mahlzeit: \(title)
        Konto: \(targetAccountEmail)
        Erfassungszeitpunkt: \(formatDate(date))

        Kern-Makronährstoffe:
        - Brennwert: \(String(format: "%.1f", kcal)) kcal
        - Protein: \(String(format: "%.1f", protein)) g
        - Kohlenhydrate: \(String(format: "%.1f", carbs)) g
        - Fett: \(String(format: "%.1f", fat)) g
        - Ballaststoffe: \(String(format: "%.1f", fiber)) g
        """

        if !details.isEmpty {
            description += "\n\nZusätzliche Nährwerte & Details:\n\(details)"
        }

        description += "\n----------------------------------------\nAutomatisch synchronisiert via Growcery iOS Client"
        event.notes = description

        do {
            try eventStore.save(event, span: .thisEvent, commit: true)
            let msg = "Ereignis '\(event.title ?? title)' in '\(calendar.title)' eingetragen."
            self.lastSyncDate = Date()
            self.lastSyncResult = msg
            self.activeCalendarTitle = "\(calendar.title) (\(calendar.source.title))"
            self.isSyncing = false
            return (true, msg)
        } catch {
            let errMsg = "Fehler beim Speichern: \(error.localizedDescription)"
            self.lastSyncResult = errMsg
            self.isSyncing = false
            return (false, errMsg)
        }
    }

    public func syncTestEvent() async -> (success: Bool, message: String) {
        self.isSyncing = true

        if !isAuthorized {
            let granted = await requestAccess()
            guard granted else {
                self.isSyncing = false
                self.lastSyncResult = "Kalenderzugriff abgelehnt"
                return (false, "Kalenderzugriff nicht gewährt")
            }
        }

        guard let calendar = resolveTargetCalendar() else {
            self.isSyncing = false
            self.lastSyncResult = "Kein Kalender verfügbar"
            return (false, "Kein Kalender verfügbar")
        }

        let now = Date()
        let event = EKEvent(eventStore: eventStore)
        event.calendar = calendar
        let userDesc = targetAccountEmail.isEmpty ? UserAccountService.shared.currentAccount.displayName : targetAccountEmail
        event.title = "Growcery Live-Sync Test (\(userDesc))"
        event.startDate = now
        event.endDate = now.addingTimeInterval(15 * 60)
        event.notes = """
        Growcery Kalender-Synchronisationstest
        ----------------------------------------
        Status: Erfolgreich verifiziert
        Zielkonto: \(targetAccountEmail)
        Kalender: \(calendar.title) (\(calendar.source.title))
        Zeitstempel: \(formatDate(now))
        ----------------------------------------
        Growcery iOS Client & Google Calendar Bridge
        """

        do {
            try eventStore.save(event, span: .thisEvent, commit: true)
            let msg = "Test-Eintrag erfolgreich erstellt in '\(calendar.title)'"
            self.lastSyncDate = Date()
            self.lastSyncResult = msg
            self.activeCalendarTitle = "\(calendar.title) (\(calendar.source.title))"
            self.isSyncing = false
            HapticFeedbackService.shared.commitSuccess()
            return (true, msg)
        } catch {
            let errMsg = "Test-Sync fehlgeschlagen: \(error.localizedDescription)"
            self.lastSyncResult = errMsg
            self.isSyncing = false
            return (false, errMsg)
        }
    }

    public func syncAllTodayMeals(store: LocalStore) async -> (success: Int, total: Int) {
        self.isSyncing = true

        if !isAuthorized {
            let granted = await requestAccess()
            guard granted else {
                self.isSyncing = false
                self.lastSyncResult = "Kalenderzugriff erforderlich"
                return (0, 0)
            }
        }

        guard let calendar = resolveTargetCalendar() else {
            self.isSyncing = false
            self.lastSyncResult = "Kein passender Kalender vorhanden"
            return (0, 0)
        }

        let todayLogs = store.todayLogs
        var successCount = 0

        if todayLogs.isEmpty {
            let event = EKEvent(eventStore: eventStore)
            event.calendar = calendar
            event.title = "Growcery Tagesbilanz: 0 kcal | 0g P (Erfassung aktiv)"
            event.startDate = Date()
            event.endDate = Date().addingTimeInterval(15 * 60)
            event.notes = "Growcery Tagesprotokoll für \(formatDate(Date()))\nBisher keine Mahlzeiten für diesen Tag verbucht.\nKonto: \(targetAccountEmail)"

            do {
                try eventStore.save(event, span: .thisEvent, commit: true)
                successCount = 1
            } catch {
                print("CalendarSyncService daily log save error: \(error)")
            }
        } else {
            for log in todayLogs {
                let event = EKEvent(eventStore: eventStore)
                event.calendar = calendar
                event.title = "Mahlzeit: \(log.foodName) (\(Int(log.kcal)) kcal | \(Int(log.protein))g P)"
                event.startDate = log.timestamp
                event.endDate = log.timestamp.addingTimeInterval(20 * 60)
                event.notes = """
                Growcery Mahlzeiten-Eintrag
                ----------------------------------------
                Produkt: \(log.foodName)
                Menge: \(Int(log.weightGrams)) g
                Brennwert: \(String(format: "%.1f", log.kcal)) kcal
                Protein: \(String(format: "%.1f", log.protein)) g
                Kohlenhydrate: \(String(format: "%.1f", log.carbs)) g
                Fett: \(String(format: "%.1f", log.fat)) g
                Ballaststoffe: \(String(format: "%.1f", log.fiber)) g
                Kosten: \(String(format: "%.2f", log.cost)) EUR
                Konto: \(targetAccountEmail)
                ----------------------------------------
                Growcery iOS Client
                """

                do {
                    try eventStore.save(event, span: .thisEvent, commit: true)
                    successCount += 1
                } catch {
                    print("CalendarSyncService error saving meal log \(log.id): \(error)")
                }
            }
        }

        let total = max(1, todayLogs.count)
        self.lastSyncDate = Date()
        self.lastSyncResult = "\(successCount) von \(total) Ereignissen in '\(calendar.title)' synchronisiert."
        self.activeCalendarTitle = "\(calendar.title) (\(calendar.source.title))"
        self.isSyncing = false
        HapticFeedbackService.shared.commitSuccess()

        return (successCount, total)
    }

    public func triggerTodaySync(store: LocalStore) {
        guard !isSyncing else { return }
        Task {
            _ = await syncAllTodayMeals(store: store)
        }
    }

    public struct AvailableCalendarInfo: Identifiable, Hashable {
        public var id: String
        public var title: String
        public var sourceTitle: String
        public var isGoogle: Bool
        public var allowsModifications: Bool
    }

    public func getAvailableCalendars() -> [AvailableCalendarInfo] {
        let cals = eventStore.calendars(for: .event)
        return cals.map { cal in
            let src = cal.source.title.lowercased()
            let title = cal.title.lowercased()
            let isGoogle = src.contains("google") || src.contains("gmail") || src.contains("@") || title.contains("@")
            return AvailableCalendarInfo(
                id: cal.calendarIdentifier,
                title: cal.title,
                sourceTitle: cal.source.title,
                isGoogle: isGoogle,
                allowsModifications: cal.allowsContentModifications
            )
        }
    }

    public func resolveTargetCalendar() -> EKCalendar? {
        let calendars = eventStore.calendars(for: .event)

        // 1. Explicitly selected calendar by ID in active profile
        if let selectedId = UserAccountService.shared.currentAccount.selectedCalendarIdentifier,
           let match = calendars.first(where: { $0.calendarIdentifier == selectedId && $0.allowsContentModifications }) {
            return match
        }

        let targetEmail = targetAccountEmail.lowercased()

        // 2. Direct match with targetAccountEmail in source title or calendar title
        if !targetEmail.isEmpty, let directMatch = calendars.first(where: {
            ($0.source.title.lowercased().contains(targetEmail) ||
             $0.title.lowercased().contains(targetEmail)) &&
            $0.allowsContentModifications
        }) {
            return directMatch
        }

        // 3. Google / Gmail account calendars with modification rights
        if let googleCalendar = calendars.first(where: {
            ($0.source.title.lowercased().contains("google") ||
             $0.source.title.lowercased().contains("gmail")) &&
            $0.allowsContentModifications
        }) {
            return googleCalendar
        }

        // 4. Default calendar for new events
        if let defaultCal = eventStore.defaultCalendarForNewEvents, defaultCal.allowsContentModifications {
            return defaultCal
        }

        // 5. Any writable calendar fallback
        return calendars.first(where: { $0.allowsContentModifications })
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "dd.MM.yyyy HH:mm 'Uhr'"
        return formatter.string(from: date)
    }
}
