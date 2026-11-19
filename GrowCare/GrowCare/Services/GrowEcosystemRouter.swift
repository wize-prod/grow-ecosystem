import SwiftUI
import UIKit

// MARK: - Grow Ecosystem App Definition
public enum GrowAppTarget: String, CaseIterable, Identifiable, Sendable {
    case grow = "grow"
    case growcery = "growcery"
    case growcare = "growcare"
    case growstudy = "growstudy"
    case growfinance = "growfinance"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .grow: return "Grow"
        case .growcery: return "Growcery"
        case .growcare: return "GrowCare"
        case .growstudy: return "GrowStudy"
        case .growfinance: return "GrowFinance"
        }
    }

    public var roleDescription: String {
        switch self {
        case .grow: return "Training & Reha"
        case .growcery: return "Ernaehrung & Makros"
        case .growcare: return "4C Pflege & Stube"
        case .growstudy: return "Matura & Zertifikate"
        case .growfinance: return "Finanzen & 5-Gate"
        }
    }

    public var primaryScheme: String {
        switch self {
        case .grow: return "grow"
        case .growcery: return "growcery"
        case .growcare: return "growcare"
        case .growstudy: return "growstudy"
        case .growfinance: return "growfinance"
        }
    }

    public var fallbackScheme: String {
        switch self {
        case .grow: return "gym"
        case .growcery: return "nutrivault"
        case .growcare: return "care"
        case .growstudy: return "study"
        case .growfinance: return "finance"
        }
    }

    public var iconName: String {
        switch self {
        case .grow: return "figure.run"
        case .growcery: return "fork.knife"
        case .growcare: return "sparkles"
        case .growstudy: return "book.closed.fill"
        case .growfinance: return "creditcard.fill"
        }
    }

    public var accentColor: Color {
        switch self {
        case .grow: return Color(red: 0.85, green: 0.40, blue: 0.20) // Orange
        case .growcery: return Color(red: 0.43, green: 0.54, blue: 0.45) // Sage Green
        case .growcare: return Color(red: 0.65, green: 0.54, blue: 0.98) // Lilac / Iris
        case .growstudy: return Color(red: 0.70, green: 0.60, blue: 0.35) // Amber
        case .growfinance: return Color(red: 0.40, green: 0.60, blue: 0.85) // Blue
        }
    }

    public var isMacOnly: Bool {
        return self == .growfinance && UIDevice.current.userInterfaceIdiom == .phone
    }
}

// MARK: - Centralized Ecosystem Router
@MainActor
public final class GrowEcosystemRouter: ObservableObject {
    public static let shared = GrowEcosystemRouter()

    private init() {}

    public func canOpen(_ target: GrowAppTarget) -> Bool {
        if target.isMacOnly { return false }
        if let url = URL(string: "\(target.primaryScheme)://"), UIApplication.shared.canOpenURL(url) {
            return true
        }
        if let url = URL(string: "\(target.fallbackScheme)://"), UIApplication.shared.canOpenURL(url) {
            return true
        }
        return false
    }

    public func openApp(
        _ target: GrowAppTarget,
        path: String = "",
        params: [String: String] = [:]
    ) {
        let haptic = UIImpactFeedbackGenerator(style: .medium)
        haptic.prepare()
        haptic.impactOccurred()

        var components = URLComponents()
        components.scheme = target.primaryScheme
        components.host = path.isEmpty ? "open" : path
        if !params.isEmpty {
            components.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
        }

        guard let targetURL = components.url else { return }

        UIApplication.shared.open(targetURL, options: [:]) { success in
            if !success {
                var fallbackComponents = URLComponents()
                fallbackComponents.scheme = target.fallbackScheme
                fallbackComponents.host = path.isEmpty ? "open" : path
                if !params.isEmpty {
                    fallbackComponents.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
                }
                if let fallbackURL = fallbackComponents.url {
                    UIApplication.shared.open(fallbackURL, options: [:], completionHandler: nil)
                }
            }
        }
    }
}

// MARK: - Reusable Ecosystem Switcher Jump Bar
public struct EcosystemJumpBar: View {
    public let currentApp: GrowAppTarget
    @ObservedObject private var router = GrowEcosystemRouter.shared

    public init(currentApp: GrowAppTarget) {
        self.currentApp = currentApp
    }

    public var body: some View {
        HStack(spacing: 6) {
            ForEach(GrowAppTarget.allCases) { target in
                if target == currentApp {
                    // Current Active App Indicator
                    HStack(spacing: 5) {
                        Image(systemName: target.iconName)
                            .font(.system(size: 11, weight: .bold))
                        Text(target.displayName)
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(target.accentColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(target.accentColor.opacity(0.16))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(target.accentColor.opacity(0.4), lineWidth: 1)
                    )
                } else {
                    // Sister App Jump Target
                    Button {
                        router.openApp(target)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: target.iconName)
                                .font(.system(size: 11, weight: .medium))
                            Text(target.displayName)
                                .font(.system(size: 11, weight: .medium))

                            if target.isMacOnly {
                                Text("MAC")
                                    .font(.system(size: 8, weight: .bold))
                                    .padding(.horizontal, 3)
                                    .padding(.vertical, 1)
                                    .background(Color.white.opacity(0.12))
                                    .clipShape(RoundedRectangle(cornerRadius: 3))
                            }
                        }
                        .foregroundColor(target.isMacOnly ? Color.gray : Color.white.opacity(0.75))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(Color(white: 0.12))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(white: 0.08).opacity(0.95))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.10), lineWidth: 0.8)
        )
    }
}

