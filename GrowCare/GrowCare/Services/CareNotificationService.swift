import Foundation
import UserNotifications
import Combine

@MainActor
public final class CareNotificationService: NSObject, ObservableObject {
    public static let shared = CareNotificationService()

    @Published public var isAuthorized: Bool = false
    @Published public var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published public var pendingCareRemindersCount: Int = 0

    override private init() {
        super.init()
        checkAuthorization()
    }

    public func checkAuthorization() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            Task { @MainActor in
                self.authorizationStatus = settings.authorizationStatus
                self.isAuthorized = settings.authorizationStatus == .authorized
                self.refreshPendingCount()
            }
        }
    }

    public func refreshPendingCount() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let careCount = requests.filter { $0.identifier.hasPrefix("care_reminder_") }.count
            Task { @MainActor in
                self.pendingCareRemindersCount = careCount
            }
        }
    }

    public func requestAuthorization(completion: ((Bool) -> Void)? = nil) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            Task { @MainActor in
                self.isAuthorized = granted
                self.authorizationStatus = granted ? .authorized : .denied
                self.refreshPendingCount()
                completion?(granted)
            }
        }
    }

    public func scheduleAllCareReminders(routines: [CareRoutineItem]) {
        guard isAuthorized else {
            requestAuthorization { [weak self] granted in
                if granted {
                    self?.scheduleAllCareReminders(routines: routines)
                }
            }
            return
        }

        for routine in routines {
            scheduleCareRoutineReminder(routine: routine)
        }
        refreshPendingCount()
    }

    public func scheduleCareRoutineReminder(routine: CareRoutineItem) {
        let center = UNUserNotificationCenter.current()
        let baseIdentifier = "care_reminder_\(routine.id)"

        // Remove any existing notifications for this routine
        var cleanIds = [baseIdentifier]
        for i in 0...6 {
            cleanIds.append("\(baseIdentifier)_\(i)")
        }
        center.removePendingNotificationRequests(withIdentifiers: cleanIds)

        guard routine.isNotificationEnabled else {
            refreshPendingCount()
            return
        }

        guard isAuthorized else {
            requestAuthorization { [weak self] granted in
                if granted {
                    self?.scheduleCareRoutineReminder(routine: routine)
                }
            }
            return
        }

        let content = UNMutableNotificationContent()
        content.title = routine.title
        content.body = notificationBody(for: routine)
        content.sound = .default
        content.userInfo = [
            "type": "care",
            "routine_id": routine.id
        ]

        let hour = routine.defaultHour
        let minute = routine.defaultMinute

        // Specific schedule day rules matching CareCatalogData.isRoutineScheduled
        if routine.id == "routine_abend_trimmtag" {
            // Trimmtag Evening Routine: Mi (4), Fr (6), So (1)
            for (idx, weekday) in [4, 6, 1].enumerated() {
                var dc = DateComponents()
                dc.weekday = weekday
                dc.hour = hour
                dc.minute = minute
                let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)
                let req = UNNotificationRequest(identifier: "\(baseIdentifier)_\(idx)", content: content, trigger: trigger)
                center.add(req)
            }
        } else if routine.id == "routine_abend_rasurfrei" {
            // Rasurfrei Evening Routine: Mo (2), Di (3), Do (5), Sa (7)
            for (idx, weekday) in [2, 3, 5, 7].enumerated() {
                var dc = DateComponents()
                dc.weekday = weekday
                dc.hour = hour
                dc.minute = minute
                let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)
                let req = UNNotificationRequest(identifier: "\(baseIdentifier)_\(idx)", content: content, trigger: trigger)
                center.add(req)
            }
        } else if routine.id == "routine_bart_pseudofolliculitis" || routine.id.contains("bart") {
            // Beard Trimming & PFB Antiseptik: Mi (4), Fr (6), So (1)
            for (idx, weekday) in [4, 6, 1].enumerated() {
                var dc = DateComponents()
                dc.weekday = weekday
                dc.hour = hour
                dc.minute = minute
                let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)
                let req = UNNotificationRequest(identifier: "\(baseIdentifier)_\(idx)", content: content, trigger: trigger)
                center.add(req)
            }
        } else if routine.id == "routine_haare_4c" || routine.id.contains("haare") {
            // 4C Hair Hydration: Di (3), Do (5), So (1)
            for (idx, weekday) in [3, 5, 1].enumerated() {
                var dc = DateComponents()
                dc.weekday = weekday
                dc.hour = hour
                dc.minute = minute
                let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)
                let req = UNNotificationRequest(identifier: "\(baseIdentifier)_\(idx)", content: content, trigger: trigger)
                center.add(req)
            }
        } else if routine.id.contains("wochenende") || routine.id.contains("kulturbeutel") {
            // Sunday audit
            var dc = DateComponents()
            dc.weekday = 1 // Sunday
            dc.hour = hour
            dc.minute = minute
            let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)
            let req = UNNotificationRequest(identifier: baseIdentifier, content: content, trigger: trigger)
            center.add(req)
        } else {
            // Frequency fallbacks
            switch routine.defaultFrequency {
            case .daily, .twiceDaily:
                var dc = DateComponents()
                dc.hour = hour
                dc.minute = minute
                let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)
                let req = UNNotificationRequest(identifier: baseIdentifier, content: content, trigger: trigger)
                center.add(req)

            case .threeTimesAWeek:
                // Standard 3x per week: Mi (4), Fr (6), So (1)
                for (idx, weekday) in [4, 6, 1].enumerated() {
                    var dc = DateComponents()
                    dc.weekday = weekday
                    dc.hour = hour
                    dc.minute = minute
                    let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)
                    let req = UNNotificationRequest(identifier: "\(baseIdentifier)_\(idx)", content: content, trigger: trigger)
                    center.add(req)
                }

            case .weekly:
                var dc = DateComponents()
                dc.weekday = 1 // Sunday
                dc.hour = hour
                dc.minute = minute
                let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)
                let req = UNNotificationRequest(identifier: baseIdentifier, content: content, trigger: trigger)
                center.add(req)

            case .monthly:
                var dc = DateComponents()
                dc.day = 1
                dc.hour = hour
                dc.minute = minute
                let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)
                let req = UNNotificationRequest(identifier: baseIdentifier, content: content, trigger: trigger)
                center.add(req)
            }
        }

        refreshPendingCount()
    }

    private func notificationBody(for routine: CareRoutineItem) -> String {
        switch routine.id {
        case "routine_morgen":
            return "06:15 Uhr: CeraVe Cleanser, Feuchtigkeitscreme und LRP SPF 50+ vor Dienstantritt auftragen."
        case "routine_mittag_uv_frische":
            return "12:45 Uhr: 20-Sekunden Direktauftrag LRP Anthelios SPF 50+ auf Hals & Unterkiefer (Spind-Depot)."
        case "routine_post_dienst_reset":
            return "16:30 Uhr: Post-Dienst Somatischer Reset: Stube lueften, Dienstkleidung ablegen, Sportkleidung anlegen."
        case "routine_post_shower_hydration":
            return "17:45 Uhr: Post-Workout Reinigung & Barriere-Repair: CeraVe Cleanser + Feuchtigkeitscreme auf leicht feuchte Haut."
        case "routine_bart_pseudofolliculitis":
            return "18:00 Uhr: 4C Trockenschnitt mit JRL Trimmer (0.5 mm) & Tend Skin punktuell auftragen (nicht reiben!)."
        case "routine_haare_4c":
            return "20:00 Uhr: Afro 4C Feuchtigkeit & LOC-Methode (Mielle Rosmarinoel & Cantu Leave-in)."
        case "routine_abend_trimmtag":
            return "21:30 Uhr: Post-Rasur Regeneration. BHA weglassen! Azelainsaeure 10% & CeraVe Creme."
        case "routine_abend_rasurfrei":
            return "21:30 Uhr: Follikel-Tiefenreinigung: 2% BHA Peeling (10 Min) & Azelainsaeure 10% zur PIH-Reduktion."
        case "routine_kulturbeutel":
            return "19:00 Uhr: Dienst- & Reise-Kulturbeutel pruefen (Silikonflaschen & LRP Spind-Depot sichern)."
        case "routine_wochenende_tiefenreinigung":
            return "10:00 Uhr: Wochenend-Tiefenreinigung & Skalp-Detox (Mielle Oel & Tiefenpflege)."
        default:
            let timeStr = String(format: "%02d:%02d Uhr", routine.defaultHour, routine.defaultMinute)
            if let firstStep = routine.steps.first {
                return "\(timeStr): \(firstStep.title) - \(firstStep.instruction)"
            }
            return "\(timeStr): Routine faellig (\(routine.defaultFrequency.rawValue)). Follikel- und Barriereschutz ausfuehren."
        }
    }

    public func cancelCareReminder(routineId: String) {
        let center = UNUserNotificationCenter.current()
        var identifiers = ["care_reminder_\(routineId)"]
        for i in 0...6 {
            identifiers.append("care_reminder_\(routineId)_\(i)")
        }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        refreshPendingCount()
    }

    // Legacy fallback method for sheets passing Date
    public func scheduleReminder(routineId: String, title: String, targetTime: Date, frequency: RoutineFrequency) {
        let cal = Calendar.current
        let hour = cal.component(.hour, from: targetTime)
        let minute = cal.component(.minute, from: targetTime)

        let mock = CareRoutineItem(
            id: routineId,
            title: title,
            category: "Pflege",
            defaultFrequency: frequency,
            defaultHour: hour,
            defaultMinute: minute,
            estimatedMinutes: 10,
            clinicalRationale: "",
            steps: [],
            products: [],
            isNotificationEnabled: true
        )
        scheduleCareRoutineReminder(routine: mock)
    }

    public func cancelReminder(routineId: String) {
        cancelCareReminder(routineId: routineId)
    }
}
