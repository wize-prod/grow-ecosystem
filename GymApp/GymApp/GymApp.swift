import SwiftUI
import GrowCore

@main
struct GymApp: App {
    @StateObject private var store = GymStore.shared
    @StateObject private var calService = CalendarSyncService.shared
    @StateObject private var healthService = HealthKitService.shared
    @StateObject private var growceryService = GrowcerySyncService.shared

    init() {
        GrowPeerSyncService.shared.start()

        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = UIColor(red: 0.109, green: 0.109, blue: 0.118, alpha: 0.95) // #1C1C1E
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().unselectedItemTintColor = UIColor(red: 0.556, green: 0.556, blue: 0.576, alpha: 1.0) // #8E8E93
    }

    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .preferredColorScheme(.dark)
                .background(GymTheme.bg.ignoresSafeArea())
                .environmentObject(store)
                .onAppear {
                    healthService.checkAndRequestAuthorization()
                    calService.fetchUpcomingWorkouts()
                    healthService.fetchAllHealthData()
                    growceryService.refreshData()

                    GrowBLEPeripheralManager.shared.onMeasurementReceived = { m in
                        Task { @MainActor in
                            GymStore.shared.addMeasurement(type: .weight, value: m.weightKg, note: "Renpho BLE Direkt")
                            if let fat = m.bodyFatPct {
                                GymStore.shared.addMeasurement(type: .bodyFat, value: fat, note: "Renpho BLE Direkt")
                            }
                        }
                    }
                    GrowBLEPeripheralManager.shared.startActiveScan()
                }
                .onChange(of: scenePhase) { newPhase in
                    if newPhase == .active {
                        growceryService.refreshData()
                        healthService.fetchAllHealthData()
                        GrowBLEPeripheralManager.shared.startActiveScan()
                    }
                }
                .onOpenURL { url in
                    if let templateId = growceryService.handleIncomingURL(url) {
                        if let template = store.templates.first(where: { $0.id == templateId }) {
                            store.startWorkout(from: template)
                        }
                    }
                }
        }
    }
}
