import SwiftUI
import UserNotifications

#if targetEnvironment(macCatalyst)
import UIKit

final class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        configuration.delegateClass = SceneDelegate.self
        return configuration
    }
}

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        if let windowScene = scene as? UIWindowScene {
            windowScene.sizeRestrictions?.minimumSize = CGSize(width: 480, height: 400)
            windowScene.sizeRestrictions?.maximumSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
            windowScene.sizeRestrictions?.allowsFullScreen = true
        }
    }
}
#endif

@main
struct GrowStudyApp: App {
#if targetEnvironment(macCatalyst)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
#endif

    @StateObject private var store = StudyStore.shared
    @Environment(\.scenePhase) private var scenePhase

    init() {
        GrowPeerSyncService.shared.start()

        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = UIColor(red: 0.110, green: 0.110, blue: 0.118, alpha: 0.95)
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().unselectedItemTintColor = UIColor(red: 0.557, green: 0.557, blue: 0.576, alpha: 1.0)

        // Sämtliche Benachrichtigungen radikal und dauerhaft aus dem macOS/iOS Notification Center löschen
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                Color.black.ignoresSafeArea()
                MainTabView()
                    .environmentObject(store)
                    .preferredColorScheme(.dark)
            }
            .onAppear {
                let center = UNUserNotificationCenter.current()
                center.removeAllPendingNotificationRequests()
                center.removeAllDeliveredNotifications()
                store.syncEcosystemScheduleFromBridge()
            }
            .onChange(of: scenePhase) { newPhase in
                if newPhase == .active {
                    store.syncEcosystemScheduleFromBridge()
                }
            }
            .onOpenURL { url in
                handleIncomingURL(url)
            }
        }
    }

    private func handleIncomingURL(_ url: URL) {
        guard url.scheme == "growtasks" || url.scheme == "tasks" || url.scheme == "growstudy" || url.scheme == "study" else { return }
        let host = url.host?.lowercased() ?? ""
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems ?? []

        if host == "water" || host == "quick-water" {
            let amountStr = queryItems.first(where: { $0.name == "amount" || $0.name == "ml" })?.value ?? "250"
            if let amount = Double(amountStr) {
                store.logWater(amountMl: amount, sourceApp: "Ecosystem")
            }
        } else if host == "timer" || host == "focus" {
            let stepId = queryItems.first(where: { $0.name == "id" || $0.name == "stepId" })?.value ?? ""
            let mins = Int(queryItems.first(where: { $0.name == "mins" || $0.name == "minutes" })?.value ?? "25") ?? 25
            store.startFocusTimer(for: stepId, minutes: mins)
        }
    }
}
