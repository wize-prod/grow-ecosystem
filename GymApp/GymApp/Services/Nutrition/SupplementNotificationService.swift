import Foundation
import UserNotifications
import Combine

@MainActor
public final class SupplementNotificationService: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    public static let shared = SupplementNotificationService()

    @Published public var isNotificationsEnabled: Bool = false
    @Published public var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published public var activeSupplementExplanation: InfoExplanationItem? = nil
    @Published public var deepLinkTargetTab: Int? = nil
    @Published public var highlightedDoseId: String? = nil
    @Published public var deepLinkRecipeName: String? = nil

    private let userDefaultsKey = "circadian_supplement_notifications_enabled"
    public let categoryIdentifier = "CIRCADIAN_SUPPLEMENT_CATEGORY"
    public let markTakenActionIdentifier = "MARK_SUPPLEMENT_TAKEN"

    override private init() {
        super.init()
        self.isNotificationsEnabled = UserDefaults.standard.bool(forKey: userDefaultsKey)
        UNUserNotificationCenter.current().delegate = self
        registerNotificationCategories()
        checkAuthorization()
    }

    private func registerNotificationCategories() {
        let markTakenAction = UNNotificationAction(
            identifier: markTakenActionIdentifier,
            title: "Eingenommen",
            options: [.authenticationRequired]
        )
        let category = UNNotificationCategory(
            identifier: categoryIdentifier,
            actions: [markTakenAction],
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
                    if self.isNotificationsEnabled {
                        self.scheduleAllSupplementReminders()
                    }
                } else if settings.authorizationStatus == .denied {
                    self.isNotificationsEnabled = false
                    UserDefaults.standard.set(false, forKey: self.userDefaultsKey)
                }
            }
        }
    }

    public func requestAuthorizationAndEnable() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            Task { @MainActor in
                if granted {
                    self.isNotificationsEnabled = true
                    UserDefaults.standard.set(true, forKey: self.userDefaultsKey)
                    self.authorizationStatus = .authorized
                    self.scheduleAllSupplementReminders()
                } else {
                    self.isNotificationsEnabled = false
                    UserDefaults.standard.set(false, forKey: self.userDefaultsKey)
                    self.authorizationStatus = .denied
                }
            }
        }
    }

    public func disableNotifications() {
        self.isNotificationsEnabled = false
        UserDefaults.standard.set(false, forKey: self.userDefaultsKey)
        removeSupplementNotifications()
    }

    public func toggleNotifications() {
        if isNotificationsEnabled {
            disableNotifications()
        } else {
            requestAuthorizationAndEnable()
        }
    }

    private func removeSupplementNotifications() {
        let center = UNUserNotificationCenter.current()
        let suppIds = LocalStore.shared.allSupplements.map { "circadian_supp_\($0.id)" }
        center.removePendingNotificationRequests(withIdentifiers: suppIds)
    }

    public func cancelTodayNotification(for supplementId: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["circadian_supp_\(supplementId)"])
    }

    // MARK: - Schedule Reminders (Name & Dose Only)
    public func scheduleAllSupplementReminders() {
        guard isNotificationsEnabled else { return }

        let center = UNUserNotificationCenter.current()
        // Only remove supplement reminders, preserving care routines and chores
        removeSupplementNotifications()

        let todayKey = LocalStore.shared.dateKey(for: Date())
        let takenToday = LocalStore.shared.supplementLogs[todayKey] ?? []

        for dose in LocalStore.shared.allSupplements {
            // If already taken today through the app, suppress today's alarm
            if takenToday.contains(dose.id) {
                continue
            }

            let parts = dose.scheduledTime.split(separator: ":")
            guard parts.count == 2,
                  let hour = Int(parts[0]),
                  let minute = Int(parts[1]) else { continue }

            let content = UNMutableNotificationContent()
            content.title = dose.name
            content.body = dose.dosage
            content.sound = .default
            content.categoryIdentifier = categoryIdentifier
            content.userInfo = [
                "supplement_id": dose.id,
                "action": "open_supplement_info"
            ]

            var dateComponents = DateComponents()
            dateComponents.hour = hour
            dateComponents.minute = minute

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(
                identifier: "circadian_supp_\(dose.id)",
                content: content,
                trigger: trigger
            )

            center.add(request) { error in
                if let error = error {
                    print("[SupplementNotificationService] Fehler beim Planen von \(dose.id): \(error)")
                }
            }
        }
    }

    // MARK: - UNUserNotificationCenterDelegate (Tapping Handler & Action Handler)
    public nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        let suppId = userInfo["supplement_id"] as? String

        if response.actionIdentifier == "MARK_SUPPLEMENT_TAKEN" {
            if let suppId = suppId {
                Task { @MainActor in
                    LocalStore.shared.toggleSupplement(doseId: suppId, date: Date())
                    HapticFeedbackService.shared.commitSuccess()
                }
            }
        } else if let suppId = suppId {
            Task { @MainActor in
                self.handleNotificationTap(supplementId: suppId)
            }
        }
        completionHandler()
    }

    public nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo
        if let suppId = userInfo["supplement_id"] as? String {
            Task { @MainActor in
                let todayKey = LocalStore.shared.dateKey(for: Date())
                let isTaken = LocalStore.shared.supplementLogs[todayKey]?.contains(suppId) ?? false
                if isTaken {
                    completionHandler([])
                } else {
                    completionHandler([.banner, .sound, .badge])
                }
            }
            return
        }
        completionHandler([.banner, .sound, .badge])
    }

    // MARK: - Direct Deep Link Handler into Supplement Section & Info Sheet
    public func handleNotificationTap(supplementId: String) {
        guard let dose = LocalStore.shared.allSupplements.first(where: { $0.id == supplementId }) else {
            return
        }

        let explanation = InfoExplanationItem(
            title: dose.name,
            category: "Zirkadianes Supplement (\(dose.scheduledTime) Uhr)",
            summary: "\(dose.mechanism). \(dose.benefit)",
            details: [
                ExplanationDetail(label: "Dosierung", text: dose.dosage),
                ExplanationDetail(label: "Fokus / Zielbereich", text: dose.targetArea),
                ExplanationDetail(label: "Einnahmehinweis", text: dose.instructions),
                ExplanationDetail(label: "Physiologischer Mechanismus", text: dose.mechanism),
                ExplanationDetail(label: "Sicherheitsstandard (Rule 4)", text: "Strikte Anti-Doppelgabe-Regel: Verpasste Dosen nicht nachholen.")
            ]
        )

        self.highlightedDoseId = dose.id
        self.deepLinkTargetTab = 0
        self.activeSupplementExplanation = explanation
        HapticFeedbackService.shared.lightDetent()
    }
}
