import SwiftUI

#if targetEnvironment(macCatalyst)
import UIKit

final class MacWindowConfigurator: NSObject, UIWindowSceneDelegate {
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        
        // HIG Mac Window Standards: Min 960x640, Default 1140x780
        windowScene.sizeRestrictions?.minimumSize = CGSize(width: 960, height: 640)
        windowScene.sizeRestrictions?.maximumSize = CGSize(width: 2560, height: 1600)
        
        if let titlebar = windowScene.titlebar {
            titlebar.titleVisibility = .visible
            titlebar.toolbar = nil // Use SwiftUI integrated native navigation toolbar
        }
    }
}
#endif

@main
struct GrowFinanceApp: App {
    @StateObject private var store = FinanceStore.shared
    
    init() {
        GrowPeerSyncService.shared.start()
    }
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .preferredColorScheme(.dark)
                .environmentObject(store)
#if targetEnvironment(macCatalyst)
                .frame(minWidth: 960, minHeight: 640)
#endif
                .onOpenURL { url in
                    handleIncomingURL(url)
                }
        }
    }

    private func handleIncomingURL(_ url: URL) {
        guard url.scheme == "growfinance" || url.scheme == "finance" else { return }
        let host = url.host?.lowercased() ?? ""
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems ?? []

        if host == "expense" || host == "receipt-expense" {
            let amountStr = queryItems.first(where: { $0.name == "amount" })?.value ?? "0"
            let vendor = queryItems.first(where: { $0.name == "vendor" })?.value ?? "Lebensmitteleinkauf"
            if let amount = Double(amountStr), amount > 0 {
                let tx = BankTransaction(
                    id: UUID().uuidString,
                    date: Date(),
                    recipientOrPurpose: "Growcery Quittung: \(vendor)",
                    amount: -amount,
                    category: .groceries,
                    accountIBAN: "",
                    rawBookingText: "Growcery Quittungseinkauf",
                    isManual: true,
                    partnerName: vendor,
                    accountId: nil
                )
                store.addTransaction(tx)
            }
        }
    }
}
