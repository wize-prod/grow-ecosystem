import SwiftUI
import GrowCore

public struct MainTabView: View {
    @EnvironmentObject private var store: GymStore
    @ObservedObject private var userAccount = UserAccountService.shared
    @AppStorage("main_selected_tab") private var selectedTab: Int = 0

    public var body: some View {
        #if targetEnvironment(simulator)
        TabView(selection: $selectedTab) {
            TodayUnifiedView()
                .tabItem {
                    Image(systemName: "flame.fill")
                    Text("Heute")
                }
                .tag(0)

            InventoryView()
                .tabItem {
                    Image(systemName: "archivebox.fill")
                    Text("Vorrat")
                }
                .tag(1)

            ShoppingHubView()
                .tabItem {
                    Image(systemName: "cart.fill")
                    Text("Einkauf")
                }
                .tag(2)

            TransactionsListView(embedInNavigationStack: true, showSubPicker: true, showToolbarActions: true)
                .tabItem {
                    Image(systemName: "creditcard.fill")
                    Text("Buchungen")
                }
                .tag(3)
        }
        .accentColor(GymTheme.sageGreen)
        .background(GymTheme.bg.ignoresSafeArea())
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SwitchMainTab"))) { notif in
            if let tab = notif.object as? Int {
                selectedTab = tab
            }
        }
        #else
        if !userAccount.isLoggedIn {
            GymLoginView()
        } else {
            TabView(selection: $selectedTab) {
                TodayUnifiedView()
                    .tabItem {
                        Image(systemName: "flame.fill")
                        Text("Heute")
                    }
                    .tag(0)

                InventoryView()
                    .tabItem {
                        Image(systemName: "archivebox.fill")
                        Text("Vorrat")
                    }
                    .tag(1)

                ShoppingHubView()
                    .tabItem {
                        Image(systemName: "cart.fill")
                        Text("Einkauf")
                    }
                    .tag(2)

                TransactionsListView(embedInNavigationStack: true, showSubPicker: true, showToolbarActions: true)
                    .tabItem {
                        Image(systemName: "creditcard.fill")
                        Text("Buchungen")
                    }
                    .tag(3)
            }
            .accentColor(GymTheme.sageGreen)
            .background(GymTheme.bg.ignoresSafeArea())
        }
        #endif
    }
}
