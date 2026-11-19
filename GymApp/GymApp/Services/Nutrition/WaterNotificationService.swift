import Foundation
import UserNotifications
import Combine

public struct WaterMilestone {
    public let identifier: String
    public let hour: Int
    public let minute: Int
    public let targetRatio: Double
    public let title: String
    public let subtitle: String
    public let isCriticalLateCheck: Bool

    public init(
        identifier: String,
        hour: Int,
        minute: Int,
        targetRatio: Double,
        title: String,
        subtitle: String,
        isCriticalLateCheck: Bool
    ) {
        self.identifier = identifier
        self.hour = hour
        self.minute = minute
        self.targetRatio = targetRatio
        self.title = title
        self.subtitle = subtitle
        self.isCriticalLateCheck = isCriticalLateCheck
    }
}

@MainActor
public final class WaterNotificationService: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    public static let shared = WaterNotificationService()

    @Published public var isNotificationsEnabled: Bool = true
    @Published public var authorizationStatus: UNAuthorizationStatus = .notDetermined

    public let categoryIdentifier = "CIRCADIAN_WATER_TRACKER_CATEGORY"
    public let action433Ml = "ACTION_LOG_WATER_433"
    public let action600Ml = "ACTION_LOG_WATER_600"

    // Circadian milestones: Highest intake during midday focus; tapering late afternoon; critical deficit check
    public let milestones: [WaterMilestone] = [
        WaterMilestone(
            identifier: "circadian_water_1030",
            hour: 10,
            minute: 30,
            targetRatio: 0.25,
            title: "Hydratation: Vormittags-Check",
            subtitle: "Fokusblock-Trinkzufuhr",
            isCriticalLateCheck: false
        ),
        WaterMilestone(
            identifier: "circadian_water_1430",
            hour: 14,
            minute: 30,
            targetRatio: 0.55,
            title: "Hydratation: Nachmittags-Peak",
            subtitle: "Haupttrinkphase vor Dienstende",
            isCriticalLateCheck: false
        ),
        WaterMilestone(
            identifier: "circadian_water_1700",
            hour: 17,
            minute: 0,
            targetRatio: 0.80,
            title: "Zirkadiane Hydratation: Tapering-Phase",
            subtitle: "Schrittweise Reduktion fuer Reflux- & CPAP-Schutz",
            isCriticalLateCheck: false
        ),
        WaterMilestone(
            identifier: "circadian_water_1915",
            hour: 19,
            minute: 15,
            targetRatio: 0.50,
            title: "Kritisches Fluessigkeitsdefizit (Spaet-Check)",
            subtitle: "Fluessigkeitscheck am Abend",
            isCriticalLateCheck: true
        )
    ]

    override private init() {
        super.init()
        registerCategories()
        checkAuthorization()
    }

    private func registerCategories() {
        let action433 = UNNotificationAction(
            identifier: action433Ml,
            title: "+433 ml eintragen",
            options: []
        )
        let action600 = UNNotificationAction(
            identifier: action600Ml,
            title: "+600 ml eintragen",
            options: []
        )
        let category = UNNotificationCategory(
            identifier: categoryIdentifier,
            actions: [action433, action600],
            intentIdentifiers: [],
            options: []
        )
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    public func checkAuthorization() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            Task { @MainActor in
                self.authorizationStatus = settings.authorizationStatus
                if settings.authorizationStatus == .authorized {
                    self.updateNotificationsForCurrentIntake()
                }
            }
        }
    }

    public func requestAuthorizationAndSchedule() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            Task { @MainActor in
                self.checkAuthorization()
            }
        }
    }

    public func updateNotificationsForCurrentIntake() {
        let center = UNUserNotificationCenter.current()
        let currentWater = LocalStore.shared.todayWater()
        let targetWater = LocalStore.shared.targetWaterMl
        let now = Date()
        let cal = Calendar.current
        let nowHour = cal.component(.hour, from: now)
        let nowMin = cal.component(.minute, from: now)
        let nowTotalMinutes = nowHour * 60 + nowMin

        for milestone in milestones {
            let milestoneMinutes = milestone.hour * 60 + milestone.minute
            let targetMlForMilestone = targetWater * milestone.targetRatio

            if milestone.isCriticalLateCheck {
                // Kritisches Spaet-Defizit:
                // Wenn der Nutzer bereits >= 50 % getrunken hat, gibt es kein Defizit -> Notification loeschen
                if currentWater >= targetMlForMilestone {
                    center.removePendingNotificationRequests(withIdentifiers: [milestone.identifier])
                } else if milestoneMinutes > nowTotalMinutes {
                    // Es ist vor 19:15 und Zufuhr liegt unter 50 % -> Dringende Warnung fuer 19:15 heute planen
                    scheduleNotification(
                        for: milestone,
                        currentWater: currentWater,
                        targetWater: targetWater,
                        expectedMl: targetMlForMilestone,
                        bodyText: "Es ist 19:15 Uhr und es wurden erst \(Int(currentWater)) ml von \(Int(targetWater)) ml getrunken. Bitte ausreichend Wasser trinken."
                    )
                }
            } else {
                // Regulaere Zirkadiane Meilensteine (10:30, 14:30, 17:00)
                if currentWater >= targetMlForMilestone {
                    // Soll fuer diesen Checkpoint ist bereits erfuellt -> Nutzer nicht stoeren
                    center.removePendingNotificationRequests(withIdentifiers: [milestone.identifier])
                } else if milestoneMinutes > nowTotalMinutes {
                    // Liegt heute noch in der Zukunft und ist noch nicht erreicht
                    let bodyText: String
                    if milestone.hour == 17 {
                        bodyText = "Aktueller Stand: \(Int(currentWater)) ml (\(Int(currentWater / targetWater * 100)) %). Bis 19:30 Uhr moderat trinken, danach Tapering zum Schutz vor naechtlichem LPR-Reflux."
                    } else if milestone.hour == 14 {
                        bodyText = "Bislang \(Int(currentWater)) ml von \(Int(targetWater)) ml getrunken (Soll: \(Int(targetMlForMilestone)) ml). Der Grossteil der Fluessigkeitszufuhr sollte vor 17:00 Uhr erfolgen."
                    } else {
                        bodyText = "Bislang erst \(Int(currentWater)) ml getrunken (Soll: \(Int(targetMlForMilestone)) ml). Nutze den Vormittag fuer die primaere Hydratation waehrend des Fokusblocks."
                    }

                    scheduleNotification(
                        for: milestone,
                        currentWater: currentWater,
                        targetWater: targetWater,
                        expectedMl: targetMlForMilestone,
                        bodyText: bodyText
                    )
                } else {
                    // Meilensteinzeit fuer heute vergangen -> Fuer morgen als Sicherheitsnetz terminieren
                    scheduleRecurringTomorrow(for: milestone, targetWater: targetWater)
                }
            }
        }
    }

    private func scheduleNotification(
        for milestone: WaterMilestone,
        currentWater: Double,
        targetWater: Double,
        expectedMl: Double,
        bodyText: String
    ) {
        let content = UNMutableNotificationContent()
        content.title = milestone.title
        content.subtitle = milestone.subtitle
        content.body = bodyText
        content.sound = .default
        content.categoryIdentifier = categoryIdentifier

        var dateComponents = DateComponents()
        dateComponents.hour = milestone.hour
        dateComponents.minute = milestone.minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: milestone.identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { _ in }
    }

    private func scheduleRecurringTomorrow(for milestone: WaterMilestone, targetWater: Double) {
        let content = UNMutableNotificationContent()
        content.title = milestone.title
        content.subtitle = milestone.subtitle

        let expectedMl = targetWater * milestone.targetRatio
        if milestone.isCriticalLateCheck {
            content.body = "Spaetabend-Check: Liegt die Wasserzufuhr unter 50 % (\(Int(expectedMl)) ml), jetzt am Abend noch moderat trinken."
        } else if milestone.hour == 17 {
            content.body = "Tapering-Phase: Wasserzufuhr ab 17:00 Uhr schrittweise drosseln, um die CPAP-Nachtruhe zu sichern."
        } else if milestone.hour == 14 {
            content.body = "Nachmittags-Peak: Mindestens \(Int(expectedMl)) ml sollten vor dem Dienstende erreicht sein."
        } else {
            content.body = "Vormittags-Check: Mindestens \(Int(expectedMl)) ml waehrend des Fokusblocks trinken."
        }
        content.sound = .default
        content.categoryIdentifier = categoryIdentifier

        var dateComponents = DateComponents()
        dateComponents.hour = milestone.hour
        dateComponents.minute = milestone.minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: milestone.identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { _ in }
    }

    // MARK: - UNUserNotificationCenterDelegate
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let actionId = response.actionIdentifier
        if actionId == action433Ml {
            LocalStore.shared.logWater(ml: 433, sourceApp: "NotificationAction")
        } else if actionId == action600Ml {
            LocalStore.shared.logWater(ml: 600, sourceApp: "NotificationAction")
        }
        completionHandler()
    }

    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }
}
