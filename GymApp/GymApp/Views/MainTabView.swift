import SwiftUI

public struct MainTabView: View {
    @EnvironmentObject private var store: GymStore
    @ObservedObject private var userAccount = UserAccountService.shared
    @State private var selectedTab: Int = 0

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

            ExercisesView()
                .tabItem {
                    Image(systemName: "books.vertical.fill")
                    Text("Katalog")
                }
                .tag(2)

            ShoppingHubView()
                .tabItem {
                    Image(systemName: "cart.fill")
                    Text("Einkauf")
                }
                .tag(3)
        }
        .onAppear {
            selectedTab = 3
        }
        .accentColor(GymTheme.terracotta)
        .background(GymTheme.bg.ignoresSafeArea())
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

                ExercisesView()
                    .tabItem {
                        Image(systemName: "books.vertical.fill")
                        Text("Katalog")
                    }
                    .tag(2)

                ShoppingHubView()
                    .tabItem {
                        Image(systemName: "cart.fill")
                        Text("Einkauf")
                    }
                    .tag(3)
            }
            .accentColor(GymTheme.terracotta)
            .background(GymTheme.bg.ignoresSafeArea())
        }
        #endif
    }
}
