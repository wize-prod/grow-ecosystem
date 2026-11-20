import Foundation
import UserNotifications

@MainActor
public final class FinanceNotificationService {
    public static let shared = FinanceNotificationService()
    
    private let center = UNUserNotificationCenter.current()
    
    private init() {}
    
    public func requestAuthorization() {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                Task { @MainActor in
                    self.scheduleDailyNotifications()
                }
            }
        }
    }
    
    public func scheduleDailyNotifications() {
        center.removeAllPendingNotificationRequests()
        
        let store = FinanceStore.shared
        let engine = SmartFinanceEngine.shared
        let allowance = engine.calculateDailyAllowance(
            plusKontoBalance: store.plusKontoBalance,
            pendingFixedCosts: store.totalRemainingFixedCosts
        )
        
        let safeStr = String(format: "%.2f", store.safeToSpend)
        let limitStr = String(format: "%.2f", allowance.dailyLimitEur)
        let savedStr = String(format: "%.2f", store.savedLeakCapitalTotal)
        let loanStr = String(format: "%.2f", store.totalLoanBalance)
        
        // 1. Morning Notification (07:30): Tageslimit & Dispo-Schutz
        let morningContent = UNMutableNotificationContent()
        morningContent.title = "GrowFinance: Tages-Fokus"
        morningContent.body = "Verfügbar: " + safeStr + " EUR. Tageslimit: " + limitStr + " EUR bis zum Sold. Dispo-Schutz aktiv."
        morningContent.sound = UNNotificationSound.default
        
        var morningDate = DateComponents()
        morningDate.hour = 7
        morningDate.minute = 30
        let morningTrigger = UNCalendarNotificationTrigger(dateMatching: morningDate, repeats: true)
        let morningRequest = UNNotificationRequest(identifier: "daily_morning_finance", content: morningContent, trigger: morningTrigger)
        center.add(morningRequest)
        
        // 2. Evening Notification (20:30): Avalanche-Status & Food-Leak Radar
        let eveningContent = UNMutableNotificationContent()
        eveningContent.title = "GrowFinance: Abend-Abschluss"
        eveningContent.body = "Streak: \(store.foodLeakFreeStreakDays) Tage lieferdienst-frei (" + savedStr + " EUR gerettet). Restschuld: " + loanStr + " EUR."
        eveningContent.sound = UNNotificationSound.default
        
        var eveningDate = DateComponents()
        eveningDate.hour = 20
        eveningDate.minute = 30
        let eveningTrigger = UNCalendarNotificationTrigger(dateMatching: eveningDate, repeats: true)
        let eveningRequest = UNNotificationRequest(identifier: "daily_evening_finance", content: eveningContent, trigger: eveningTrigger)
        center.add(eveningRequest)
    }
}
