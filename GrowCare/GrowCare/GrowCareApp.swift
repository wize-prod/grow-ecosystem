import SwiftUI

@main
struct GrowCareApp: App {
    @StateObject private var store = GrowCareStore.shared

    init() {
        CareNotificationService.shared.requestAuthorization { _ in
            CareNotificationService.shared.scheduleAllCareReminders(routines: CareCatalogData.allRoutines)
        }
        ChoreNotificationService.shared.requestAuthorization { _ in
            ChoreNotificationService.shared.scheduleAllChoreReminders(chores: ChoreCatalogData.allChores)
        }
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .preferredColorScheme(.dark)
                .onOpenURL { url in
                    handleIncomingURL(url)
                }
        }
    }

    private func handleIncomingURL(_ url: URL) {
        // Support URL scheme deep linking: growcare:// or care://
        if url.host == "open" || url.host == "today" {
            store.selectedDate = Date()
        }
    }
}

