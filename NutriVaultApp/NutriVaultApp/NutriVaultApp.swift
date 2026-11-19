import SwiftUI

@main
struct NutriVaultApp: App {
    @StateObject private var store = LocalStore.shared

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = UIColor(red: 0.110, green: 0.102, blue: 0.094, alpha: 0.95)
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().unselectedItemTintColor = UIColor(red: 0.52, green: 0.50, blue: 0.47, alpha: 1.0)
    }

    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .background(Theme.bg.ignoresSafeArea())
                .environmentObject(store)
                .onChange(of: scenePhase) { phase in
                    store.syncTagesbilanzToBridge()
                    if phase == .active {
                        SupplementNotificationService.shared.checkAuthorization()
                    }
                }
                .onOpenURL { url in
                    handleIncomingURL(url)
                }
        }
    }

    private func handleIncomingURL(_ url: URL) {
        guard url.scheme == "growcery" || url.scheme == "nutrivault" else { return }
        let host = url.host?.lowercased() ?? ""
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems ?? []

        if host == "tab" {
            if let idxStr = queryItems.first(where: { $0.name == "index" || $0.name == "id" })?.value,
               let idx = Int(idxStr) {
                SupplementNotificationService.shared.deepLinkTargetTab = idx
            }
        } else if host == "vorrat" || host == "pantry" || host == "inventory" || host == "recipe" || host == "recipes" || host == "rezepte" || host == "inspect-recipe" {
            SupplementNotificationService.shared.deepLinkTargetTab = 1
        } else if host == "einkauf" || host == "shopping" || host == "quittung" || host == "receipt" {
            SupplementNotificationService.shared.deepLinkTargetTab = 2
            if host == "quittung" || host == "receipt" {
                store.targetedDepotSegment = "Quittungen"
            }
        } else if host == "health" || host == "profile" || host == "mahlzeiten" || host == "heute" {
            SupplementNotificationService.shared.deepLinkTargetTab = 0
        } else if host == "water" || host == "quick-water" {
            let amountStr = queryItems.first(where: { $0.name == "amount" || $0.name == "ml" })?.value ?? "250"
            if let amount = Double(amountStr) {
                store.logWater(ml: amount)
            }
        }

        if let uParam = queryItems.first(where: { $0.name == "utensil" })?.value {
            if let matched = CookingUtensil.allCases.first(where: { $0.rawValue.lowercased().contains(uParam.lowercased()) || $0.shortLabel.lowercased().contains(uParam.lowercased()) }) {
                store.selectUtensil(matched)
            }
        }
    }
}

struct ContentView: View {
    @ObservedObject private var userAccount = UserAccountService.shared
    @EnvironmentObject private var store: LocalStore
    @ObservedObject private var notifications = SupplementNotificationService.shared
    @State private var selectedTab: Int = 0

    var body: some View {
        if !userAccount.isLoggedIn {
            NutriLoginView()
        } else {
            TabView(selection: $selectedTab) {
                HealthProfileSheet(isSheet: false)
                    .environment(\.horizontalSizeClass, .regular)
                    .tabItem {
                        Image(systemName: "flame.fill")
                        Text("Heute")
                    }
                    .tag(0)

                InventoryView()
                    .environment(\.horizontalSizeClass, .regular)
                    .tabItem {
                        Image(systemName: "archivebox.fill")
                        Text("Vorrat")
                    }
                    .tag(1)

                ShoppingHubView()
                    .environment(\.horizontalSizeClass, .regular)
                    .tabItem {
                        Image(systemName: "cart.fill")
                        Text("Einkauf")
                    }
                    .tag(2)
            }
            .environment(\.horizontalSizeClass, .compact)
            .accentColor(Theme.sageGreen)
            .background(Theme.bg.ignoresSafeArea())
            .onChange(of: notifications.deepLinkTargetTab) { target in
                if let target = target {
                    selectedTab = target
                    notifications.deepLinkTargetTab = nil
                }
            }
            .onAppear {
                WaterNotificationService.shared.requestAuthorizationAndSchedule()
            }
            .onOpenURL { url in
                if url.scheme == "growcery" || url.scheme == "nutrivault" {
                    let host = url.host?.lowercased() ?? ""
                    if host == "heute" || url.path.contains("heute") || url.absoluteString.contains("heute") {
                        selectedTab = 0
                    } else if host == "vorrat" || host == "inventory" || host == "pantry" || host == "rezepte" || host == "recipe" || host == "recipes" || url.path.contains("vorrat") || url.path.contains("rezepte") {
                        selectedTab = 1
                    } else if host == "einkauf" || host == "shopping" || host == "quittung" || host == "receipt" || url.path.contains("einkauf") {
                        selectedTab = 2
                        if host == "quittung" || host == "receipt" {
                            store.targetedDepotSegment = "Quittungen"
                        }
                    }
                    if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                       let queryItems = components.queryItems {
                        if let uParam = queryItems.first(where: { $0.name == "utensil" })?.value {
                            if let matched = CookingUtensil.allCases.first(where: { $0.id.lowercased().contains(uParam.lowercased()) || $0.shortLabel.lowercased().contains(uParam.lowercased()) }) {
                                store.selectUtensil(matched)
                            }
                        }
                        if let sParam = queryItems.first(where: { $0.name == "segment" })?.value {
                            store.selectedDepotSegment = sParam
                            store.targetedDepotSegment = sParam
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Circular Water Tracker Button
public struct NutriCircularWaterButton: View {
    @ObservedObject private var store = LocalStore.shared

    public init() {}

    private var todayWater: Double {
        store.todayWater()
    }

    private var waterLiters: Double {
        todayWater / 1000.0
    }

    private var targetLiters: Double {
        store.targetWaterMl / 1000.0
    }

    private var isGoalReached: Bool {
        todayWater >= store.targetWaterMl
    }

    private var percent: Int {
        Int(min(100.0, (todayWater / max(1.0, store.targetWaterMl)) * 100.0))
    }

    private var progressRatio: Double {
        min(1.0, max(0.0, todayWater / max(1.0, store.targetWaterMl)))
    }

    public var body: some View {
        Menu {
            Section("Schnelle Erfassung") {
                Button(action: {
                    HapticFeedbackService.shared.lightDetent()
                    store.logWater(ml: 600, sourceApp: "Growcery")
                }) {
                    Label("+600 ml", systemImage: "waterbottle.fill")
                }
                Button(action: {
                    HapticFeedbackService.shared.lightDetent()
                    store.logWater(ml: 433, sourceApp: "Growcery")
                }) {
                    Label("+433 ml", systemImage: "drop.fill")
                }
                Button(action: {
                    HapticFeedbackService.shared.lightDetent()
                    store.logWater(ml: 1000, sourceApp: "Growcery")
                }) {
                    Label("+1.000 ml (1,0 L)", systemImage: "waterbottle")
                }
                Button(action: {
                    HapticFeedbackService.shared.lightDetent()
                    store.logWater(ml: 1500, sourceApp: "Growcery")
                }) {
                    Label("+1.500 ml (1,5 L)", systemImage: "mug.fill")
                }
            }
            Section("Hydration: \(String(format: "%.2fL / %.1fL", waterLiters, targetLiters)) (\(percent)%)") {
                Button(role: .destructive, action: {
                    HapticFeedbackService.shared.mechanicalClick()
                    store.resetWater(sourceApp: "Growcery")
                }) {
                    Label("Wasserstand zuruecksetzen (0 ml)", systemImage: "arrow.counterclockwise")
                }
            }
        } label: {
            ZStack {
                // Background disc
                Circle()
                    .fill(Theme.surfaceElevated)
                    .frame(width: 44, height: 44)

                // Track ring (subtle border)
                Circle()
                    .stroke(Theme.border.opacity(0.6), lineWidth: 2.5)
                    .frame(width: 44, height: 44)

                // Percentage Border: Closes into a full ring as intake approaches goal
                if progressRatio > 0 {
                    Circle()
                        .trim(from: 0.0, to: CGFloat(progressRatio))
                        .stroke(
                            isGoalReached ? Theme.sageGreen : Theme.warmSand,
                            style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                        )
                        .frame(width: 44, height: 44)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.35), value: progressRatio)
                }

                VStack(spacing: 1) {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(isGoalReached ? Theme.sageGreen : Theme.warmSand)
                    Text(String(format: "%.1fL", waterLiters))
                        .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                        .foregroundColor(Theme.textPrimary)
                }
            }
            .shadow(color: Color.black.opacity(0.4), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            store.refreshWaterFromBridge()
        }
    }
}

// MARK: - Concentric Nutrition Rings Renderer for Tab Bar
struct NutritionRingsIconRenderer {
    private static var cachedImage: UIImage? = nil
    private static var lastP: Int = -1
    private static var lastC: Int = -1
    private static var lastF: Int = -1

    static func generate(pRatio: Double, cRatio: Double, fRatio: Double) -> UIImage {
        let p = Int(min(max(pRatio, 0.0), 1.0) * 100)
        let c = Int(min(max(cRatio, 0.0), 1.0) * 100)
        let f = Int(min(max(fRatio, 0.0), 1.0) * 100)

        if let cached = cachedImage, p == lastP, c == lastC, f == lastF {
            return cached
        }

        let size = CGSize(width: 30, height: 30)
        let format = UIGraphicsImageRendererFormat()
        format.scale = UIScreen.main.scale
        format.opaque = false

        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let rendered = renderer.image { ctx in
            let cgContext = ctx.cgContext
            let center = CGPoint(x: size.width / 2.0, y: size.height / 2.0)
            let lineWidth: CGFloat = 2.2

            let rings: [(radius: CGFloat, ratio: Double, color: UIColor, trackColor: UIColor)] = [
                (
                    radius: 12.5,
                    ratio: min(max(pRatio, 0.0), 1.0),
                    color: UIColor(red: 0.96, green: 0.25, blue: 0.37, alpha: 1.0),
                    trackColor: UIColor(red: 0.96, green: 0.25, blue: 0.37, alpha: 0.22)
                ),
                (
                    radius: 9.2,
                    ratio: min(max(cRatio, 0.0), 1.0),
                    color: UIColor(red: 0.58, green: 0.88, blue: 0.28, alpha: 1.0),
                    trackColor: UIColor(red: 0.58, green: 0.88, blue: 0.28, alpha: 0.22)
                ),
                (
                    radius: 5.9,
                    ratio: min(max(fRatio, 0.0), 1.0),
                    color: UIColor(red: 0.0, green: 0.82, blue: 0.92, alpha: 1.0),
                    trackColor: UIColor(red: 0.0, green: 0.82, blue: 0.92, alpha: 0.22)
                )
            ]

            cgContext.setLineWidth(lineWidth)
            cgContext.setLineCap(.round)

            for ring in rings {
                // Background Track
                cgContext.setStrokeColor(ring.trackColor.cgColor)
                cgContext.addArc(center: center, radius: ring.radius, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: false)
                cgContext.strokePath()

                // Active Arc
                if ring.ratio > 0.02 {
                    let startAngle = -CGFloat.pi / 2.0
                    let endAngle = startAngle + (CGFloat.pi * 2 * CGFloat(ring.ratio))
                    cgContext.setStrokeColor(ring.color.cgColor)
                    cgContext.addArc(center: center, radius: ring.radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
                    cgContext.strokePath()
                }
            }
        }.withRenderingMode(.alwaysOriginal)

        cachedImage = rendered
        lastP = p
        lastC = c
        lastF = f
        return rendered
    }
}

extension View {
    public func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
