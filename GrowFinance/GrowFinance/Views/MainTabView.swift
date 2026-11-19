import SwiftUI
import UIKit

// MARK: - Enforce Classic Bottom TabBar on iPadOS 18+
private struct BottomTabBarControllerConfigurator: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        let vc = UIViewController()
        vc.view.backgroundColor = .clear
        DispatchQueue.main.async {
            configure(for: vc)
        }
        return vc
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        DispatchQueue.main.async {
            configure(for: uiViewController)
        }
    }

    private func configure(for vc: UIViewController) {
        if let tbc = vc.tabBarController {
            #if targetEnvironment(macCatalyst)
            // On macOS Catalyst, let the system use the top toolbar tab bar for genuine Mac feel
            #else
            if #available(iOS 18.0, *) {
                tbc.mode = .tabBar
            }
            #endif
        }
    }
}

public struct MainTabView: View {
    @State private var selectedTab: Int = 0
    
    public init() {
        // Style TabBar for austere obsidian look
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(FinanceTheme.surface)
        
        let itemAppearance = UITabBarItemAppearance()
        itemAppearance.normal.iconColor = UIColor(FinanceTheme.textTertiary)
        itemAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(FinanceTheme.textTertiary),
            .font: UIFont.systemFont(ofSize: 10, weight: .medium)
        ]
        
        itemAppearance.selected.iconColor = UIColor(FinanceTheme.accent)
        itemAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(FinanceTheme.accent),
            .font: UIFont.systemFont(ofSize: 10, weight: .bold)
        ]
        
        appearance.stackedLayoutAppearance = itemAppearance
        appearance.inlineLayoutAppearance = itemAppearance
        appearance.compactInlineLayoutAppearance = itemAppearance
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    public var body: some View {
        TabView(selection: $selectedTab) {
            FinanceDashboardView()
                .environment(\.horizontalSizeClass, .regular)
                .tabItem {
                    Label("Übersicht", systemImage: "gauge.with.dots.needle")
                }
                .tag(0)

            TransactionsListView()
                .environment(\.horizontalSizeClass, .regular)
                .tabItem {
                    Label("Buchungen", systemImage: "list.bullet.rectangle.portrait.fill")
                }
                .tag(1)
            
            ShoppingRegistryView()
                .environment(\.horizontalSizeClass, .regular)
                .tabItem {
                    Label("Einkauf", systemImage: "cart.badge.plus")
                }
                .tag(2)
        }
        .background(BottomTabBarControllerConfigurator())
        .environment(\.horizontalSizeClass, .compact)
        .tint(FinanceTheme.accent)
    }
}

