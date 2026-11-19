import Foundation
import UserNotifications
import Combine

@MainActor
public final class ChoreNotificationService: NSObject, ObservableObject {
    public static let shared = ChoreNotificationService()

    @Published public var isAuthorized: Bool = false
    @Published public var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published public var pendingChoreRemindersCount: Int = 0

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
            let choreCount = requests.filter { $0.identifier.hasPrefix("chore_reminder_") }.count
            Task { @MainActor in
                self.pendingChoreRemindersCount = choreCount
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

    public func scheduleAllChoreReminders(chores: [ChoreRoutineItem]) {
        guard isAuthorized else {
            requestAuthorization { [weak self] granted in
                if granted {
                    self?.scheduleAllChoreReminders(chores: chores)
                }
            }
            return
        }

        for chore in chores {
            scheduleChoreReminder(chore: chore)
        }
        refreshPendingCount()
    }

    public func scheduleChoreReminder(chore: ChoreRoutineItem) {
        let center = UNUserNotificationCenter.current()
        let baseIdentifier = "chore_reminder_\(chore.id)"

        // Clean existing notifications for this chore
        var cleanIds = [baseIdentifier]
        for i in 0...6 {
            cleanIds.append("\(baseIdentifier)_\(i)")
        }
        center.removePendingNotificationRequests(withIdentifiers: cleanIds)

        guard chore.isNotificationEnabled else {
            refreshPendingCount()
            return
        }

        guard isAuthorized else {
            requestAuthorization { [weak self] granted in
                if granted {
                    self?.scheduleChoreReminder(chore: chore)
                }
            }
            return
        }

        let content = UNMutableNotificationContent()
        content.title = chore.title
        content.body = notificationBody(for: chore)
        content.sound = .default
        content.userInfo = [
            "type": "chore",
            "chore_id": chore.id
        ]

        let hour = chore.reminderHour
        let minute = chore.reminderMinute

        // Specific schedule matching ChoreCatalogData
        if chore.id == "chore_room_airing" || chore.id == "chore_mittag_lueften_klarschiff" || chore.id == "chore_muell_hygiene" {
            // Daily chores
            var dc = DateComponents()
            dc.hour = hour
            dc.minute = minute
            let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)
            let req = UNNotificationRequest(identifier: baseIdentifier, content: content, trigger: trigger)
            center.add(req)
        } else if chore.id == "chore_laundry_wash" || chore.id == "chore_laundry_dry" {
            // Laundry cycle: Di (3), Fr (6), So (1)
            for (index, weekday) in [3, 6, 1].enumerated() {
                var dc = DateComponents()
                dc.weekday = weekday
                dc.hour = hour
                dc.minute = minute
                let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)
                let req = UNNotificationRequest(identifier: "\(baseIdentifier)_\(index)", content: content, trigger: trigger)
                center.add(req)
            }
        } else if chore.id == "chore_stube_clean" {
            // Weekend cleaning: Sa (7), So (1)
            for (index, weekday) in [7, 1].enumerated() {
                var dc = DateComponents()
                dc.weekday = weekday
                dc.hour = hour
                dc.minute = minute
                let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)
                let req = UNNotificationRequest(identifier: "\(baseIdentifier)_\(index)", content: content, trigger: trigger)
                center.add(req)
            }
        } else if chore.id == "chore_kueche_clean" {
            // Kitchen: Di (3), Fr (6)
            for (index, weekday) in [3, 6].enumerated() {
                var dc = DateComponents()
                dc.weekday = weekday
                dc.hour = hour
                dc.minute = minute
                let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)
                let req = UNNotificationRequest(identifier: "\(baseIdentifier)_\(index)", content: content, trigger: trigger)
                center.add(req)
            }
        } else if chore.id == "chore_military_equipment" || chore.id == "chore_bed_sheet_change" {
            // Weekly Sunday chores
            var dc = DateComponents()
            dc.weekday = chore.id == "chore_military_equipment" ? 6 : 1 // Freitag oder Sonntag
            dc.hour = hour
            dc.minute = minute
            let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)
            let req = UNNotificationRequest(identifier: baseIdentifier, content: content, trigger: trigger)
            center.add(req)
        } else {
            // Frequency fallbacks
            switch chore.defaultFrequency {
            case .daily:
                var dc = DateComponents()
                dc.hour = hour
                dc.minute = minute
                let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)
                let req = UNNotificationRequest(identifier: baseIdentifier, content: content, trigger: trigger)
                center.add(req)

            case .everyTwoDays, .everyThreeDays, .twiceAWeek:
                for (index, weekday) in [3, 6].enumerated() {
                    var dc = DateComponents()
                    dc.weekday = weekday
                    dc.hour = hour
                    dc.minute = minute
                    let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)
                    let req = UNNotificationRequest(identifier: "\(baseIdentifier)_\(index)", content: content, trigger: trigger)
                    center.add(req)
                }

            case .weekly, .biweekly:
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

    private func notificationBody(for chore: ChoreRoutineItem) -> String {
        switch chore.id {
        case "chore_room_airing":
            return "06:45 Uhr: Stube 10-15 Min stosslueften fuer frische Raumluft und CO2-Senkung."
        case "chore_laundry_wash":
            return "17:00 Uhr: Sportzeug & Dienstkleidung trennen und Waschgang starten."
        case "chore_laundry_dry":
            return "19:00 Uhr: Waesche aufhaengen und Spindordnung nach Kantenmass herstellen."
        case "chore_stube_clean":
            return "10:00 Uhr: Oberflaechen abwischen, Boden saugen/wischen & desinfizieren."
        case "chore_kueche_clean":
            return "18:30 Uhr: Arbeitsflaechen reinigen, Spuele entkalken & Kuehlschrank checken."
        case "chore_military_equipment":
            return "16:45 Uhr: Kampfstiefel putzen, Koppel/Tragesatz pruefen & Rucksack ordnen."
        case "chore_bed_sheet_change":
            return "09:30 Uhr: Bettwaesche abziehen, Lueften & frische Bezuege kantenrein aufschlagen."
        case "chore_mittag_lueften_klarschiff":
            return "13:00 Uhr: Mittags-Stosslueften & Schreibtisch-Klarschiff."
        case "chore_muell_hygiene":
            return "18:15 Uhr: Muellbeutel entsorgen & neuen Beutel einsetzen."
        default:
            let timeStr = String(format: "%02d:%02d Uhr", chore.reminderHour, chore.reminderMinute)
            if let firstStep = chore.steps.first {
                return "\(timeStr): \(firstStep.title) - \(firstStep.instruction)"
            }
            return "\(timeStr): Hausarbeit faellig (\(chore.defaultFrequency.rawValue)). Kasernenordnung herstellen."
        }
    }

    public func removeChoreReminder(choreId: String) {
        let center = UNUserNotificationCenter.current()
        var identifiers = ["chore_reminder_\(choreId)"]
        for i in 0...6 {
            identifiers.append("chore_reminder_\(choreId)_\(i)")
        }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        refreshPendingCount()
    }
}
