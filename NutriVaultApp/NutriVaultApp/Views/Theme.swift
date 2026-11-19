import SwiftUI
import UIKit

// MARK: - 1. DOMAIN IDENTIFIERS
public enum GrowDomain: String, CaseIterable, Identifiable {
    case nutrition = "nutrition"
    case gym = "gym"
    case care = "care"
    case study = "study"
    case finance = "finance"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .nutrition: return "NutriVault"
        case .gym: return "Gym & SOMA"
        case .care: return "GrowCare"
        case .study: return "GrowStudy"
        case .finance: return "GrowFinance"
        }
    }

    public var defaultIcon: String {
        switch self {
        case .nutrition: return "fork.knife"
        case .gym: return "flame.fill"
        case .care: return "sparkles"
        case .study: return "books.vertical.fill"
        case .finance: return "banknote.fill"
        }
    }

    public var tintColor: Color {
        switch self {
        case .nutrition: return GrowColor.sageGreen
        case .gym: return GrowColor.terracotta
        case .care: return GrowColor.careLilac
        case .study: return GrowColor.electricBlue
        case .finance: return GrowColor.mintAccent
        }
    }
}

// MARK: - 2. COLOR PALETTE & TOKENS
public struct GrowColor {
    // Pure OLED & Inset Grouped Palette
    public static let bg = Color.black // Pure OLED #000000
    public static let background = bg
    public static let surface = Color(red: 0.109, green: 0.109, blue: 0.118) // Apple secondarySystemGroupedBackground #1C1C1E
    public static let surfaceElevated = Color(red: 0.172, green: 0.172, blue: 0.180) // Apple tertiarySystemGroupedBackground #2C2C2E
    public static let surfaceSubtle = Color(red: 0.227, green: 0.227, blue: 0.235) // #3A3A3C
    
    // Hairline Specular Borders
    public static let border = Color.white.opacity(0.08)
    public static let borderHairline = border
    public static let borderSubtle = Color.white.opacity(0.04)
    public static let borderFocused = Color.white.opacity(0.20)

    // Typography Labels
    public static let textPrimary = Color(red: 0.95, green: 0.95, blue: 0.95) // #F2F2F7
    public static let textSecondary = Color(red: 0.556, green: 0.556, blue: 0.576) // Apple secondaryLabel #8E8E93
    public static let textMuted = Color(red: 0.388, green: 0.388, blue: 0.400) // Apple tertiaryLabel #636366

    // Functional Semantic System Accents (Apple HIG Dark Palette)
    public static let statusSuccess = Color(red: 0.188, green: 0.820, blue: 0.345) // Apple System Green #30D158
    public static let statusDanger = Color(red: 1.000, green: 0.271, blue: 0.227) // Apple System Red #FF453A
    public static let statusWarning = Color(red: 0.235, green: 0.827, blue: 0.996) // Apple System Cyan #3CD3FE
    public static let statusWarningAmber = Color(red: 1.000, green: 0.624, blue: 0.039) // Apple System Orange #FF9F0A
    public static let statusInteractive = Color(red: 0.039, green: 0.518, blue: 1.000) // Apple System Blue #0A84FF

    // Domain Specific Accents
    public static let sageGreen = statusSuccess
    public static let terracotta = statusDanger
    public static let electricBlue = statusInteractive
    public static let careLilac = Color(red: 0.65, green: 0.54, blue: 0.98) // #A68AFA
    public static let mintAccent = Color(red: 0.000, green: 0.855, blue: 0.765) // #00DAC3
    public static let cyanAccent = statusWarning
    public static let warmSand = statusWarning
    public static let alertRed = statusDanger
}

// MARK: - 3. BACKWARD COMPATIBLE THEME STRUCT
public struct Theme {
    // Apple HIG OLED & Inset Grouped Palette
    public static let bg = GrowColor.bg
    public static let surface = GrowColor.surface
    public static let surfaceElevated = GrowColor.surfaceElevated
    public static let surfaceSubtle = GrowColor.surfaceSubtle
    public static let border = GrowColor.border

    // Apple Standard Typography
    public typealias Typography = GrowTypography
    public static let textPrimary = GrowColor.textPrimary
    public static let textSecondary = GrowColor.textSecondary
    public static let textMuted = GrowColor.textMuted

    // Functional Semantic System Accents
    public static let primaryAccent = GrowColor.statusInteractive
    public static let primaryAccentLight = GrowColor.cyanAccent
    public static let sageGreen = GrowColor.sageGreen
    public static let sageLight = GrowColor.sageGreen
    public static let statusSuccess = GrowColor.statusSuccess
    public static let warmSand = GrowColor.warmSand
    public static let cyanAccent = GrowColor.cyanAccent
    public static let tealAccent = GrowColor.mintAccent
    public static let terracotta = GrowColor.terracotta
    public static let softRose = Color(red: 1.000, green: 0.216, blue: 0.373)
    public static let strongBlue = GrowColor.statusInteractive

    // Apple Fitness Activity Ring Gradients
    public static let ringProteinStart = Color(red: 1.000, green: 0.263, blue: 0.271)
    public static let ringProteinEnd = Color(red: 1.000, green: 0.216, blue: 0.373)
    public static let ringCarbsStart = Color(red: 0.188, green: 0.820, blue: 0.345)
    public static let ringCarbsEnd = Color(red: 0.000, green: 0.855, blue: 0.765)
    public static let ringFatStart = Color(red: 0.235, green: 0.827, blue: 0.996)
    public static let ringFatEnd = Color(red: 0.000, green: 0.569, blue: 1.000)
}

// MARK: - 4. GEOMETRY & CONCENTRIC RADII
public struct GrowGeometry {
    public static let cardCornerRadius: CGFloat = 18.0
    public static let subCardCornerRadius: CGFloat = 12.0
    public static let badgeCornerRadius: CGFloat = 8.0
    public static let pillHeight: CGFloat = 34.0
    public static let buttonHeight: CGFloat = 46.0

    public static let horizontalPadding: CGFloat = 16.0
    public static let cardInnerPadding: CGFloat = 16.0
    public static let subCardInnerPadding: CGFloat = 12.0
    public static let elementSpacing: CGFloat = 12.0
    public static let sectionSpacing: CGFloat = 20.0
    public static let bottomContentInset: CGFloat = 88.0

    public static func concentricRadius(outerRadius: CGFloat, padding: CGFloat) -> CGFloat {
        max(4.0, outerRadius - padding)
    }
}

// MARK: - 5. TACTILE HAPTIC ENGINE
public enum GrowHaptics {
    public static func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }

    public static func medium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }

    public static func heavy() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.prepare()
        generator.impactOccurred()
    }

    public static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }

    public static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }

    public static func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.warning)
    }

    public static func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.error)
    }
}

// MARK: - 6. VIEW MODIFIERS & CARD ARCHITECTURE
public struct GrowCardModifier: ViewModifier {
    public var cornerRadius: CGFloat
    public var backgroundColor: Color
    public var borderColor: Color
    public var padding: CGFloat
    public var hasSpecularGradient: Bool

    public init(
        cornerRadius: CGFloat = GrowGeometry.cardCornerRadius,
        backgroundColor: Color = GrowColor.surface,
        borderColor: Color = GrowColor.border,
        padding: CGFloat = GrowGeometry.cardInnerPadding,
        hasSpecularGradient: Bool = true
    ) {
        self.cornerRadius = cornerRadius
        self.backgroundColor = backgroundColor
        self.borderColor = borderColor
        self.padding = padding
        self.hasSpecularGradient = hasSpecularGradient
    }

    public func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        hasSpecularGradient ?
                        AnyShapeStyle(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.14),
                                    Color.white.opacity(0.04)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        ) : AnyShapeStyle(borderColor),
                        lineWidth: 0.8
                    )
            )
            .shadow(color: Color.black.opacity(0.22), radius: 8, x: 0, y: 4)
    }
}

public struct GrowSubCardModifier: ViewModifier {
    public var cornerRadius: CGFloat
    public var padding: CGFloat

    public init(
        cornerRadius: CGFloat = GrowGeometry.subCardCornerRadius,
        padding: CGFloat = GrowGeometry.subCardInnerPadding
    ) {
        self.cornerRadius = cornerRadius
        self.padding = padding
    }

    public func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(GrowColor.surfaceElevated)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(GrowColor.borderSubtle, lineWidth: 0.6)
            )
    }
}

public struct GrowLiquidGlassModifier: ViewModifier {
    public var cornerRadius: CGFloat
    public var material: Material

    public init(
        cornerRadius: CGFloat = GrowGeometry.cardCornerRadius,
        material: Material = .ultraThinMaterial
    ) {
        self.cornerRadius = cornerRadius
        self.material = material
    }

    public func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(material)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.18),
                                Color.white.opacity(0.06),
                                Color.white.opacity(0.02)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.8
                    )
            )
            .shadow(color: Color.black.opacity(0.28), radius: 10, x: 0, y: 5)
    }
}

public struct GrowTactileButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.88 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.75), value: configuration.isPressed)
    }
}

public struct WellnessCardModifier: ViewModifier {
    var borderColor: Color = Theme.border
    var cornerRadius: CGFloat = 18

    public func body(content: Content) -> some View {
        content
            .modifier(GrowCardModifier(cornerRadius: cornerRadius, backgroundColor: Theme.surface, borderColor: borderColor))
    }
}

public struct AppleLiquidGlassModifier: ViewModifier {
    var cornerRadius: CGFloat = 16
    var material: Material = .ultraThinMaterial

    public func body(content: Content) -> some View {
        content
            .modifier(GrowLiquidGlassModifier(cornerRadius: cornerRadius, material: material))
    }
}

public struct AppleTactileButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.88 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.75), value: configuration.isPressed)
    }
}

public struct AppleCapsuleButtonStyle: ButtonStyle {
    var isSelected: Bool
    var activeTint: Color

    public init(isSelected: Bool = false, activeTint: Color = Theme.sageGreen) {
        self.isSelected = isSelected
        self.activeTint = activeTint
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: isSelected ? .bold : .medium))
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(isSelected ? activeTint : Color.white.opacity(0.06))
            )
            .foregroundColor(isSelected ? Color.white : Theme.textSecondary)
            .overlay(
                Capsule()
                    .stroke(
                        isSelected ? activeTint : Color.white.opacity(0.10),
                        lineWidth: 0.8
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.22, dampingFraction: 0.75), value: configuration.isPressed)
    }
}

public extension View {
    func wellnessCard(borderColor: Color = Theme.border, cornerRadius: CGFloat = 18) -> some View {
        self.modifier(WellnessCardModifier(borderColor: borderColor, cornerRadius: cornerRadius))
    }

    func liquidGlass(cornerRadius: CGFloat = 18, material: Material = .ultraThinMaterial) -> some View {
        self.modifier(AppleLiquidGlassModifier(cornerRadius: cornerRadius, material: material))
    }

    func growCard(
        cornerRadius: CGFloat = GrowGeometry.cardCornerRadius,
        backgroundColor: Color = GrowColor.surface,
        borderColor: Color = GrowColor.border,
        padding: CGFloat = GrowGeometry.cardInnerPadding,
        hasSpecularGradient: Bool = true
    ) -> some View {
        self.modifier(GrowCardModifier(
            cornerRadius: cornerRadius,
            backgroundColor: backgroundColor,
            borderColor: borderColor,
            padding: padding,
            hasSpecularGradient: hasSpecularGradient
        ))
    }

    func growSubCard(
        cornerRadius: CGFloat = GrowGeometry.subCardCornerRadius,
        padding: CGFloat = GrowGeometry.subCardInnerPadding
    ) -> some View {
        self.modifier(GrowSubCardModifier(cornerRadius: cornerRadius, padding: padding))
    }

    func growLiquidGlass(
        cornerRadius: CGFloat = GrowGeometry.cardCornerRadius,
        material: Material = .ultraThinMaterial
    ) -> some View {
        self.modifier(GrowLiquidGlassModifier(cornerRadius: cornerRadius, material: material))
    }

    func growTactile() -> some View {
        self.buttonStyle(GrowTactileButtonStyle())
    }
}

// MARK: - 7. UNIFIED ECOSYSTEM TYPOGRAPHY
public struct GrowTypography {
    public static let largeTitle = Font.system(size: 32, weight: .bold, design: .default)
    public static let title1 = Font.system(size: 24, weight: .bold, design: .default)
    public static let title2 = Font.system(size: 20, weight: .bold, design: .default)
    public static let title3 = Font.system(size: 17, weight: .semibold, design: .default)
    public static let headline = Font.system(size: 15, weight: .semibold, design: .default)
    public static let body = Font.system(size: 14, weight: .regular, design: .default)
    public static let bodyMedium = Font.system(size: 14, weight: .medium, design: .default)
    public static let bodyBold = Font.system(size: 14, weight: .bold, design: .default)
    public static let callout = Font.system(size: 13, weight: .medium, design: .default)
    public static let subheadline = Font.system(size: 12, weight: .medium, design: .default)
    public static let caption = Font.system(size: 11, weight: .regular, design: .default)
    public static let captionBold = Font.system(size: 11, weight: .bold, design: .default)
    public static let micro = Font.system(size: 10, weight: .medium, design: .default)
    public static let microBold = Font.system(size: 10, weight: .bold, design: .default)

    public static let metricHero = Font.system(size: 38, weight: .bold, design: .monospaced)
    public static let metricLarge = Font.system(size: 28, weight: .bold, design: .monospaced)
    public static let metricMedium = Font.system(size: 20, weight: .bold, design: .monospaced)
    public static let metricSmall = Font.system(size: 14, weight: .bold, design: .monospaced)
    public static let metricMicro = Font.system(size: 11, weight: .bold, design: .monospaced)
    public static let badgeMono = Font.system(size: 9.5, weight: .bold, design: .monospaced)
    public static let tagMono = Font.system(size: 8.5, weight: .bold, design: .monospaced)
}

public extension Font {
    static let growLargeTitle = GrowTypography.largeTitle
    static let growTitle1 = GrowTypography.title1
    static let growTitle2 = GrowTypography.title2
    static let growTitle3 = GrowTypography.title3
    static let growHeadline = GrowTypography.headline
    static let growBody = GrowTypography.body
    static let growBodyMedium = GrowTypography.bodyMedium
    static let growBodyBold = GrowTypography.bodyBold
    static let growCallout = GrowTypography.callout
    static let growSubheadline = GrowTypography.subheadline
    static let growCaption = GrowTypography.caption
    static let growCaptionBold = GrowTypography.captionBold
    static let growMicro = GrowTypography.micro
    static let growMicroBold = GrowTypography.microBold

    static let growMetricHero = GrowTypography.metricHero
    static let growMetricLarge = GrowTypography.metricLarge
    static let growMetricMedium = GrowTypography.metricMedium
    static let growMetricSmall = GrowTypography.metricSmall
    static let growMetricMicro = GrowTypography.metricMicro
    static let growBadgeMono = GrowTypography.badgeMono
    static let growTagMono = GrowTypography.tagMono
}

// MARK: - 8. REUSABLE COMMON LAYOUT & SCAFFOLD COMPONENTS
public struct GrowScreenScaffold<Content: View, HeaderTrailing: View, HeaderLeading: View>: View {
    public let title: String
    public let eyebrow: String?
    public let subtitle: String?
    public let domain: GrowDomain?
    public let statusBadge: String?
    public let statusBadgeTint: Color
    public let refreshAction: (() async -> Void)?
    public let headerLeading: HeaderLeading
    public let headerTrailing: HeaderTrailing
    public let content: Content

    public init(
        title: String,
        eyebrow: String? = nil,
        subtitle: String? = nil,
        domain: GrowDomain? = nil,
        statusBadge: String? = nil,
        statusBadgeTint: Color = GrowColor.statusSuccess,
        refreshAction: (() async -> Void)? = nil,
        @ViewBuilder headerLeading: () -> HeaderLeading = { EmptyView() },
        @ViewBuilder headerTrailing: () -> HeaderTrailing = { EmptyView() },
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.eyebrow = eyebrow
        self.subtitle = subtitle
        self.domain = domain
        self.statusBadge = statusBadge
        self.statusBadgeTint = statusBadgeTint
        self.refreshAction = refreshAction
        self.headerLeading = headerLeading()
        self.headerTrailing = headerTrailing()
        self.content = content()
    }

    public var body: some View {
        ZStack(alignment: .top) {
            GrowColor.bg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: GrowGeometry.sectionSpacing) {
                    screenHeaderBlock

                    content

                    Spacer(minLength: GrowGeometry.bottomContentInset)
                }
                .padding(.horizontal, GrowGeometry.horizontalPadding)
                .padding(.top, 8)
                .frame(maxWidth: 760)
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
            .ifLet(refreshAction) { view, action in
                view.refreshable {
                    GrowHaptics.light()
                    await action()
                }
            }
        }
    }

    private var screenHeaderBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                if let domain = domain {
                    HStack(spacing: 4) {
                        Image(systemName: domain.defaultIcon)
                            .font(.system(size: 10, weight: .bold))
                        Text(domain.displayName.uppercased())
                            .font(.growTagMono)
                            .tracking(1.0)
                    }
                    .foregroundColor(domain.tintColor)
                }

                if let eyebrow = eyebrow {
                    Text(eyebrow.uppercased())
                        .font(.growTagMono)
                        .tracking(1.0)
                        .foregroundColor(GrowColor.textMuted)
                }

                Spacer()

                if let statusBadge = statusBadge {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(statusBadgeTint)
                            .frame(width: 6, height: 6)
                        Text(statusBadge.uppercased())
                            .font(.growTagMono)
                            .foregroundColor(statusBadgeTint)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(statusBadgeTint.opacity(0.12))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(statusBadgeTint.opacity(0.3), lineWidth: 0.6))
                }
            }

            HStack(alignment: .firstTextBaseline) {
                headerLeading

                Text(title)
                    .font(.growLargeTitle)
                    .foregroundColor(GrowColor.textPrimary)

                Spacer()

                headerTrailing
            }

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.growSubheadline)
                    .foregroundColor(GrowColor.textSecondary)
            }
        }
        .padding(.vertical, 4)
    }
}

private extension View {
    @ViewBuilder
    func ifLet<T>(_ value: T?, transform: (Self, T) -> some View) -> some View {
        if let value = value {
            transform(self, value)
        } else {
            self
        }
    }
}

// MARK: - 9. STANDARDIZED SECTION CONTAINER
public struct GrowSection<Content: View, Action: View>: View {
    public let title: String
    public let counter: String?
    public let action: Action
    public let content: Content

    public init(
        title: String,
        counter: String? = nil,
        @ViewBuilder action: () -> Action = { EmptyView() },
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.counter = counter
        self.action = action()
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: GrowGeometry.elementSpacing) {
            HStack(alignment: .firstTextBaseline) {
                Text(title.uppercased())
                    .font(.growCaptionBold)
                    .tracking(0.8)
                    .foregroundColor(GrowColor.textMuted)

                if let counter = counter {
                    Text(counter)
                        .font(.growBadgeMono)
                        .foregroundColor(GrowColor.textSecondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(GrowColor.surfaceElevated)
                        .clipShape(Capsule())
                }

                Spacer()

                action
            }

            content
        }
    }
}

// MARK: - 10. STANDARDIZED METRIC KPI CARD
public struct GrowMetricCard: View {
    public let title: String
    public let value: String
    public let unit: String?
    public let target: String?
    public let progress: Double?
    public let icon: String
    public let tint: Color
    public let trend: String?
    public let isPositiveTrend: Bool?

    public init(
        title: String,
        value: String,
        unit: String? = nil,
        target: String? = nil,
        progress: Double? = nil,
        icon: String,
        tint: Color = GrowColor.statusInteractive,
        trend: String? = nil,
        isPositiveTrend: Bool? = nil
    ) {
        self.title = title
        self.value = value
        self.unit = unit
        self.target = target
        self.progress = progress
        self.icon = icon
        self.tint = tint
        self.trend = trend
        self.isPositiveTrend = isPositiveTrend
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(tint)

                Text(title.uppercased())
                    .font(.growTagMono)
                    .tracking(0.6)
                    .foregroundColor(GrowColor.textSecondary)

                Spacer()

                if let trend = trend {
                    HStack(spacing: 2) {
                        Image(systemName: (isPositiveTrend ?? true) ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 9, weight: .bold))
                        Text(trend)
                            .font(.growTagMono)
                    }
                    .foregroundColor((isPositiveTrend ?? true) ? GrowColor.statusSuccess : GrowColor.statusDanger)
                }
            }

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.growMetricLarge)
                    .foregroundColor(GrowColor.textPrimary)
                    .monospacedDigit()

                if let unit = unit {
                    Text(unit)
                        .font(.growCallout)
                        .foregroundColor(GrowColor.textSecondary)
                }

                Spacer()

                if let target = target {
                    Text("/ \(target)")
                        .font(.growCaption)
                        .foregroundColor(GrowColor.textMuted)
                        .monospacedDigit()
                }
            }

            if let progress = progress {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(GrowColor.surfaceSubtle)
                            .frame(height: 4)

                        Capsule()
                            .fill(tint)
                            .frame(width: max(0, min(geo.size.width, geo.size.width * CGFloat(progress))), height: 4)
                    }
                }
                .frame(height: 4)
            }
        }
        .growCard()
    }
}

// MARK: - 11. METRIC ROW GRID (2-4 COLUMNS)
public struct GrowMetricRow<Content: View>: View {
    public let columns: Int
    public let content: Content

    public init(columns: Int = 2, @ViewBuilder content: () -> Content) {
        self.columns = columns
        self.content = content()
    }

    public var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: GrowGeometry.elementSpacing), count: columns),
            spacing: GrowGeometry.elementSpacing
        ) {
            content
        }
    }
}

// MARK: - 12. DUAL-ENCODED ACCESSIBLE STATUS BADGE
public struct GrowStatusBadge: View {
    public let text: String
    public let icon: String
    public let tint: Color
    public let isOutlined: Bool

    public init(
        text: String,
        icon: String,
        tint: Color = GrowColor.statusInteractive,
        isOutlined: Bool = false
    ) {
        self.text = text
        self.icon = icon
        self.tint = tint
        self.isOutlined = isOutlined
    }

    public var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .bold))

            Text(text.uppercased())
                .font(.growTagMono)
                .tracking(0.6)
        }
        .foregroundColor(tint)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(isOutlined ? Color.clear : tint.opacity(0.12))
        )
        .overlay(
            Capsule()
                .stroke(tint.opacity(isOutlined ? 0.8 : 0.25), lineWidth: 0.8)
        )
    }
}

// MARK: - 13. HIGH-TACTILITY CAPSULE BUTTON
public struct GrowCapsuleButton: View {
    public enum Variant {
        case primary
        case secondary
        case glass
        case destructive
    }

    public let title: String
    public let icon: String?
    public let variant: Variant
    public let tint: Color?
    public let action: () -> Void

    public init(
        title: String,
        icon: String? = nil,
        variant: Variant = .primary,
        tint: Color? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.variant = variant
        self.tint = tint
        self.action = action
    }

    public var body: some View {
        Button(action: {
            GrowHaptics.medium()
            action()
        }) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .semibold))
                }
                Text(title)
                    .font(.growHeadline)
            }
            .frame(maxWidth: .infinity)
            .frame(height: GrowGeometry.buttonHeight)
            .background(backgroundView)
            .foregroundColor(foregroundColor)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(borderColor, lineWidth: 0.8)
            )
        }
        .growTactile()
    }

    @ViewBuilder
    private var backgroundView: some View {
        switch variant {
        case .primary:
            (tint ?? GrowColor.statusInteractive)
        case .secondary:
            GrowColor.surfaceElevated
        case .glass:
            Color.white.opacity(0.08)
        case .destructive:
            GrowColor.statusDanger
        }
    }

    private var foregroundColor: Color {
        switch variant {
        case .primary, .destructive:
            return .white
        case .secondary, .glass:
            return GrowColor.textPrimary
        }
    }

    private var borderColor: Color {
        switch variant {
        case .primary, .destructive:
            return Color.white.opacity(0.15)
        case .secondary:
            return GrowColor.borderSubtle
        case .glass:
            return Color.white.opacity(0.12)
        }
    }
}

// MARK: - 14. SOBER MILITARY-TECHNICAL EMPTY STATE
public struct GrowEmptyState: View {
    public let icon: String
    public let title: String
    public let message: String
    public let actionTitle: String?
    public let action: (() -> Void)?

    public init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    public var body: some View {
        VStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 36, weight: .light))
                .foregroundColor(GrowColor.textMuted)

            Text(title)
                .font(.growHeadline)
                .foregroundColor(GrowColor.textPrimary)

            Text(message)
                .font(.growSubheadline)
                .foregroundColor(GrowColor.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 280)

            if let actionTitle = actionTitle, let action = action {
                Button(action: {
                    GrowHaptics.light()
                    action()
                }) {
                    Text(actionTitle)
                        .font(.growSubheadline)
                        .foregroundColor(GrowColor.statusInteractive)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(GrowColor.surfaceElevated)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(GrowColor.borderSubtle, lineWidth: 0.8))
                }
                .growTactile()
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 36)
        .frame(maxWidth: .infinity)
        .growCard(backgroundColor: Color.white.opacity(0.02), hasSpecularGradient: false)
    }
}

// MARK: - 15. STANDARDIZED LIST ROW ITEM
public struct GrowListItem: View {
    public let icon: String?
    public let iconTint: Color
    public let title: String
    public let subtitle: String?
    public let detail: String?
    public let showChevron: Bool
    public let action: (() -> Void)?

    public init(
        icon: String? = nil,
        iconTint: Color = GrowColor.statusInteractive,
        title: String,
        subtitle: String? = nil,
        detail: String? = nil,
        showChevron: Bool = false,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.iconTint = iconTint
        self.title = title
        self.subtitle = subtitle
        self.detail = detail
        self.showChevron = showChevron
        self.action = action
    }

    public var body: some View {
        Group {
            if let action = action {
                Button(action: {
                    GrowHaptics.light()
                    action()
                }) {
                    rowContent
                }
                .growTactile()
            } else {
                rowContent
            }
        }
    }

    private var rowContent: some View {
        HStack(spacing: 12) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(iconTint)
                    .frame(width: 24)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.growBodyMedium)
                    .foregroundColor(GrowColor.textPrimary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.growCaption)
                        .foregroundColor(GrowColor.textSecondary)
                }
            }

            Spacer()

            if let detail = detail {
                Text(detail)
                    .font(.growCallout)
                    .foregroundColor(GrowColor.textMuted)
                    .monospacedDigit()
            }

            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(GrowColor.textMuted)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: GrowGeometry.subCardCornerRadius, style: .continuous)
                .fill(GrowColor.surfaceElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: GrowGeometry.subCardCornerRadius, style: .continuous)
                .stroke(GrowColor.borderSubtle, lineWidth: 0.6)
        )
    }
}

// MARK: - 16. SOBER SEARCH FIELD
public struct GrowSearchField: View {
    @Binding public var text: String
    public let placeholder: String

    public init(text: Binding<String>, placeholder: String = "Suchen...") {
        self._text = text
        self.placeholder = placeholder
    }

    public var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(GrowColor.textMuted)

            TextField(placeholder, text: $text)
                .font(.growBody)
                .foregroundColor(GrowColor.textPrimary)
                .autocorrectionDisabled()

            if !text.isEmpty {
                Button(action: {
                    text = ""
                    GrowHaptics.light()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundColor(GrowColor.textMuted)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(GrowColor.surfaceElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(GrowColor.borderSubtle, lineWidth: 0.8)
        )
    }
}

// MARK: - 17. STANDARDIZED MODAL SHEET HEADER
public struct GrowModalHeader: View {
    public let title: String
    public let subtitle: String?
    public let onDismiss: () -> Void
    public let onSave: (() -> Void)?
    public let saveTitle: String

    public init(
        title: String,
        subtitle: String? = nil,
        onDismiss: @escaping () -> Void,
        onSave: (() -> Void)? = nil,
        saveTitle: String = "Fertig"
    ) {
        self.title = title
        self.subtitle = subtitle
        self.onDismiss = onDismiss
        self.onSave = onSave
        self.saveTitle = saveTitle
    }

    public var body: some View {
        VStack(spacing: 4) {
            HStack {
                Button("Abbrechen") {
                    GrowHaptics.light()
                    onDismiss()
                }
                .font(.growBody)
                .foregroundColor(GrowColor.textSecondary)

                Spacer()

                Text(title)
                    .font(.growHeadline)
                    .foregroundColor(GrowColor.textPrimary)

                Spacer()

                if let onSave = onSave {
                    Button(saveTitle) {
                        GrowHaptics.success()
                        onSave()
                    }
                    .font(.growHeadline)
                    .foregroundColor(GrowColor.statusInteractive)
                } else {
                    Button("Schließen") {
                        GrowHaptics.light()
                        onDismiss()
                    }
                    .font(.growBody)
                    .foregroundColor(GrowColor.textSecondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 6)

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.growCaption)
                    .foregroundColor(GrowColor.textMuted)
                    .padding(.bottom, 4)
            }

            Divider()
                .background(GrowColor.borderSubtle)
        }
        .background(GrowColor.surface)
    }
}

// MARK: - 18. SIGNATURE GROWCERY REUSABLE COMPONENTS

/// Growcery's high-contrast segment switcher with rounded rectangle styling and fluid transitions.
public struct GrowSegmentPicker<T: Hashable & CustomStringConvertible>: View {
    public let items: [T]
    @Binding public var selection: T
    public var tint: Color

    public init(items: [T], selection: Binding<T>, tint: Color = GrowColor.sageGreen) {
        self.items = items
        self._selection = selection
        self.tint = tint
    }

    public var body: some View {
        HStack(spacing: 6) {
            ForEach(items, id: \.self) { item in
                Button(action: {
                    GrowHaptics.light()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selection = item
                    }
                }) {
                    Text(item.description)
                        .font(.system(size: 13, weight: selection == item ? .bold : .medium))
                        .foregroundColor(selection == item ? GrowColor.textPrimary : GrowColor.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(selection == item ? GrowColor.surfaceElevated : Color.clear)
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(GrowColor.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(GrowColor.borderSubtle, lineWidth: 0.6)
        )
    }
}

/// Growcery's signature 14-day horizontal calendar strip with circular day badges, today ring, completion dots, and historical return button.
public struct GrowCalendarStrip: View {
    @Binding public var selectedDate: Date
    public var dayCount: Int
    public var hasLogs: ((Date) -> Bool)?
    public var isFulfilled: ((Date) -> Bool)?
    public var onDateSelected: ((Date) -> Void)?

    private let calendar = Calendar.current

    public init(
        selectedDate: Binding<Date>,
        dayCount: Int = 14,
        hasLogs: ((Date) -> Bool)? = nil,
        isFulfilled: ((Date) -> Bool)? = nil,
        onDateSelected: ((Date) -> Void)? = nil
    ) {
        self._selectedDate = selectedDate
        self.dayCount = dayCount
        self.hasLogs = hasLogs
        self.isFulfilled = isFulfilled
        self.onDateSelected = onDateSelected
    }

    private var pastDays: [Date] {
        let today = calendar.startOfDay(for: Date())
        var days: [Date] = []
        for i in (0..<dayCount).reversed() {
            if let d = calendar.date(byAdding: .day, value: -i, to: today) {
                days.append(d)
            }
        }
        return days
    }

    public var body: some View {
        VStack(spacing: 8) {
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(pastDays, id: \.self) { date in
                            dayPill(for: date)
                                .id(calendar.startOfDay(for: date))
                        }
                    }
                    .padding(.horizontal, 2)
                }
                .onAppear {
                    let todayStart = calendar.startOfDay(for: Date())
                    proxy.scrollTo(todayStart, anchor: .trailing)
                }
            }

            if !calendar.isDateInToday(selectedDate) {
                HStack {
                    Text("Historische Ansicht: \(formattedHeader(selectedDate))")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(GrowColor.warmSand)
                    Spacer()
                    Button(action: {
                        GrowHaptics.light()
                        selectedDate = Date()
                        onDateSelected?(Date())
                    }) {
                        Text("Heute anzeigen")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(GrowColor.sageGreen)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.white.opacity(0.06)))
                            .overlay(Capsule().stroke(Color.white.opacity(0.10), lineWidth: 0.8))
                    }
                    .buttonStyle(AppleTactileButtonStyle())
                }
                .padding(.top, 2)
            }
        }
    }

    private func dayPill(for date: Date) -> some View {
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let isToday = calendar.isDateInToday(date)
        let completed = isFulfilled?(date) ?? false
        let logsPresent = hasLogs?(date) ?? false

        return Button(action: {
            GrowHaptics.light()
            withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                selectedDate = date
                onDateSelected?(date)
            }
        }) {
            VStack(spacing: 6) {
                Text(weekdayAbbreviation(date))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(isSelected ? GrowColor.textPrimary : GrowColor.textSecondary)

                ZStack {
                    Circle()
                        .fill(isSelected ? GrowColor.sageGreen : (isToday ? Color.white.opacity(0.12) : Color.clear))
                        .frame(width: 36, height: 36)
                        .shadow(color: isSelected ? GrowColor.sageGreen.opacity(0.35) : Color.clear, radius: 6, x: 0, y: 3)

                    Text("\(calendar.component(.day, from: date))")
                        .font(.system(size: 16, weight: isSelected || isToday ? .bold : .medium))
                        .foregroundColor(isSelected ? Color.black : (isToday ? GrowColor.sageGreen : GrowColor.textPrimary))
                }

                // Completion dot indicator
                Circle()
                    .fill(completed ? GrowColor.sageGreen : (logsPresent ? GrowColor.warmSand : Color.clear))
                    .frame(width: 5, height: 5)
            }
            .frame(width: 44, height: 72)
            .contentShape(Rectangle())
        }
        .buttonStyle(AppleTactileButtonStyle())
    }

    private static let weekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "EE"
        return formatter
    }()

    private static let headerFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "d. MMMM yyyy"
        return formatter
    }()

    private func weekdayAbbreviation(_ date: Date) -> String {
        Self.weekdayFormatter.string(from: date).replacingOccurrences(of: ".", with: "").uppercased()
    }

    private func formattedHeader(_ date: Date) -> String {
        Self.headerFormatter.string(from: date)
    }
}

/// Growcery's signature bottom commit bar with sageGreen fill, black text, and green glow.
public struct GrowCommitBar: View {
    public let title: String
    public var icon: String
    public var tint: Color
    public var textColor: Color
    public let action: () -> Void

    public init(
        title: String,
        icon: String = "checkmark.circle.fill",
        tint: Color = GrowColor.sageGreen,
        textColor: Color = GrowColor.bg,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.tint = tint
        self.textColor = textColor
        self.action = action
    }

    public var body: some View {
        Button(action: {
            GrowHaptics.success()
            action()
        }) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .bold))
                Text(title)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
            }
            .foregroundColor(textColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(tint)
            )
            .shadow(color: tint.opacity(0.35), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(AppleTactileButtonStyle())
    }
}

/// Growcery's 28x28 circular action button.
public struct GrowCircularButton: View {
    public let icon: String
    public var tint: Color
    public var foreground: Color
    public var size: CGFloat
    public var iconSize: CGFloat
    public let action: () -> Void

    public init(
        icon: String,
        tint: Color = GrowColor.sageGreen,
        foreground: Color = GrowColor.bg,
        size: CGFloat = 28,
        iconSize: CGFloat = 13,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.tint = tint
        self.foreground = foreground
        self.size = size
        self.iconSize = iconSize
        self.action = action
    }

    public var body: some View {
        Button(action: {
            GrowHaptics.light()
            action()
        }) {
            Image(systemName: icon)
                .font(.system(size: iconSize, weight: .bold))
                .foregroundColor(foreground)
                .frame(width: size, height: size)
                .background(Circle().fill(tint))
        }
        .buttonStyle(AppleTactileButtonStyle())
    }
}

/// Growcery's progress & budget bar card with monospaced values and 6pt capsule meter.
public struct GrowBudgetCard: View {
    public let title: String
    public let currentAmount: Double
    public let maxAmount: Double
    public let remainingAmount: Double
    public var currencySymbol: String
    public var remainingLabel: String
    public var criticalThreshold: Double

    public init(
        title: String,
        currentAmount: Double,
        maxAmount: Double,
        remainingAmount: Double,
        currencySymbol: String = "€",
        remainingLabel: String = "Restrahmen lfd. Monat:",
        criticalThreshold: Double = 25.0
    ) {
        self.title = title
        self.currentAmount = currentAmount
        self.maxAmount = maxAmount
        self.remainingAmount = remainingAmount
        self.currencySymbol = currencySymbol
        self.remainingLabel = remainingLabel
        self.criticalThreshold = criticalThreshold
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title.uppercased())
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(GrowColor.textMuted)
                Spacer()
                Text(String(format: "%.2f %@", currentAmount, currencySymbol) + " / " + String(format: "%.2f %@", maxAmount, currencySymbol))
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(GrowColor.textSecondary)
            }

            let pct = min(1.0, max(0.0, currentAmount / max(1.0, maxAmount)))
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(GrowColor.surfaceElevated)
                    .frame(height: 6)
                Capsule()
                    .fill(pct > 0.9 ? GrowColor.terracotta : GrowColor.sageGreen)
                    .frame(height: 6)
                    .scaleEffect(x: CGFloat(max(0.01, pct)), y: 1.0, anchor: .leading)
            }
            .frame(height: 6)

            HStack {
                Text(remainingLabel)
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(GrowColor.textMuted)
                Text(String(format: "%.2f %@", remainingAmount, currencySymbol))
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(remainingAmount < criticalThreshold ? GrowColor.terracotta : GrowColor.sageGreen)
                Spacer()
            }
        }
        .wellnessCard()
    }
}

// MARK: - STANDARDIZED COLLAPSIBLE SECTION ACCORDION
public struct GrowCollapsibleSection<Content: View>: View {
    public let title: String
    public let counter: String?
    public let infoAction: (() -> Void)?
    @Binding public var isExpanded: Bool
    @ViewBuilder public let content: () -> Content

    public init(
        title: String,
        counter: String? = nil,
        isExpanded: Binding<Bool>,
        infoAction: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.counter = counter
        self._isExpanded = isExpanded
        self.infoAction = infoAction
        self.content = content
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Button(action: {
                    GrowHaptics.light()
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                        isExpanded.toggle()
                    }
                }) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.growHeadline)
                            .foregroundColor(GrowColor.textPrimary)

                        if let counter = counter, !counter.isEmpty {
                            Text(counter)
                                .font(.growBadgeMono)
                                .foregroundColor(GrowColor.textSecondary)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2.5)
                                .background(Capsule().fill(GrowColor.surfaceElevated))
                        }
                    }
                }
                .buttonStyle(AppleTactileButtonStyle())

                Spacer()

                if let infoAction = infoAction {
                    Button(action: {
                        GrowHaptics.light()
                        infoAction()
                    }) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(GrowColor.warmSand)
                            .padding(6)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(AppleTactileButtonStyle())
                }

                Button(action: {
                    GrowHaptics.light()
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(GrowColor.textMuted)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .padding(6)
                        .contentShape(Rectangle())
                }
                .buttonStyle(AppleTactileButtonStyle())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            if isExpanded {
                Divider()
                    .background(GrowColor.borderSubtle)

                VStack(alignment: .leading, spacing: GrowGeometry.elementSpacing) {
                    content()
                }
                .padding(16)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: GrowGeometry.cardCornerRadius, style: .continuous)
                .fill(GrowColor.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: GrowGeometry.cardCornerRadius, style: .continuous)
                .stroke(GrowColor.border, lineWidth: 0.8)
        )
    }
}

// MARK: - STANDARDIZED HORIZONTAL FILTER STRIP
public struct GrowFilterStrip<T: Hashable & CustomStringConvertible>: View {
    public let items: [T]
    @Binding public var selectedItem: T
    public var activeTint: Color

    public init(items: [T], selectedItem: Binding<T>, activeTint: Color = GrowColor.sageGreen) {
        self.items = items
        self._selectedItem = selectedItem
        self.activeTint = activeTint
    }

    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(items, id: \.self) { item in
                    let isSelected = selectedItem == item
                    Button(action: {
                        GrowHaptics.selection()
                        withAnimation(.spring(response: 0.22, dampingFraction: 0.75)) {
                            selectedItem = item
                        }
                    }) {
                        Text(item.description)
                            .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(
                                Capsule()
                                    .fill(isSelected ? activeTint : Color.white.opacity(0.06))
                            )
                            .foregroundColor(isSelected ? Color.white : GrowColor.textSecondary)
                            .overlay(
                                Capsule()
                                    .stroke(isSelected ? activeTint : Color.white.opacity(0.10), lineWidth: 0.8)
                            )
                    }
                    .buttonStyle(AppleTactileButtonStyle())
                }
            }
            .padding(.horizontal, GrowGeometry.horizontalPadding)
            .padding(.vertical, 4)
        }
    }
}

// MARK: - FIRST-PRINCIPLES KNOWLEDGE & EXPLANATION SHEET
public struct GrowExplanationDetail: Identifiable, Equatable {
    public let id: UUID
    public let label: String
    public let text: String

    public init(id: UUID = UUID(), label: String, text: String) {
        self.id = id
        self.label = label
        self.text = text
    }
}

public struct GrowInfoExplanationSheet: View {
    @Environment(\.dismiss) private var dismiss
    public let category: String
    public let title: String
    public let summary: String
    public let details: [GrowExplanationDetail]
    public var actionProtocol: String?

    public init(
        category: String,
        title: String,
        summary: String,
        details: [GrowExplanationDetail] = [],
        actionProtocol: String? = nil
    ) {
        self.category = category
        self.title = title
        self.summary = summary
        self.details = details
        self.actionProtocol = actionProtocol
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(category.uppercased())
                            .font(.growTagMono)
                            .foregroundColor(GrowColor.warmSand)
                            .tracking(1.0)
                        Text(title)
                            .font(.growTitle2)
                            .foregroundColor(GrowColor.textPrimary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .wellnessCard()

                    VStack(alignment: .leading, spacing: 6) {
                        Text("FUNKTION & ZWECK (WARUM EXISTIERT DAS?)")
                            .font(.growTagMono)
                            .foregroundColor(GrowColor.textMuted)
                            .tracking(0.6)

                        Text(summary)
                            .font(.growBody)
                            .foregroundColor(GrowColor.textPrimary)
                            .lineSpacing(3)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .wellnessCard()

                    if !details.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("TECHNISCHE PARAMETER & METRIKEN")
                                .font(.growTagMono)
                                .foregroundColor(GrowColor.textMuted)
                                .tracking(0.6)

                            VStack(spacing: 8) {
                                ForEach(details) { detail in
                                    HStack(alignment: .top, spacing: 10) {
                                        Circle()
                                            .fill(GrowColor.sageGreen)
                                            .frame(width: 6, height: 6)
                                            .padding(.top, 6)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(detail.label.uppercased())
                                                .font(.growTagMono)
                                                .foregroundColor(GrowColor.warmSand)
                                            Text(detail.text)
                                                .font(.growBody)
                                                .foregroundColor(GrowColor.textSecondary)
                                                .fixedSize(horizontal: false, vertical: true)
                                        }
                                        Spacer()
                                    }
                                    .padding(10)
                                    .background(
                                        RoundedRectangle(cornerRadius: GrowGeometry.subCardCornerRadius, style: .continuous)
                                            .fill(GrowColor.surfaceElevated)
                                    )
                                }
                            }
                        }
                        .wellnessCard()
                    }

                    if let actionProtocol = actionProtocol {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("HANDLUNGSANWEISUNG (WENN-DANN PROTOKOLL)")
                                .font(.growTagMono)
                                .foregroundColor(GrowColor.textMuted)
                                .tracking(0.6)

                            Text(actionProtocol)
                                .font(.growCallout)
                                .foregroundColor(GrowColor.sageGreen)
                                .padding(10)
                                .background(GrowColor.surfaceElevated)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .wellnessCard()
                    }
                }
                .padding(.horizontal, GrowGeometry.horizontalPadding)
                .padding(.vertical, 16)
            }
            .background(GrowColor.bg.ignoresSafeArea())
            .navigationTitle("Information")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Schließen") {
                        GrowHaptics.light()
                        dismiss()
                    }
                    .font(.growHeadline)
                    .foregroundColor(GrowColor.sageGreen)
                }
            }
        }
    }
}

// MARK: - KEYBOARD & GESTURE DISMISSAL EXTENSIONS
extension View {
    public func growKeyboardDismissable() -> some View {
        self.scrollDismissesKeyboard(.interactively)
    }
}

// MARK: - HIGH-PERFORMANCE STATIC FORMATTER POOL
public enum GrowFormatters {
    public static let dayOfWeek: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "de_DE")
        f.dateFormat = "EEE"
        return f
    }()

    public static let dayNumber: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "de_DE")
        f.dateFormat = "d"
        return f
    }()

    public static let shortTime: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "de_DE")
        f.dateFormat = "HH:mm 'Uhr'"
        return f
    }()

    public static let fullDate: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "de_DE")
        f.dateFormat = "dd.MM.yyyy"
        return f
    }()

    public static let dayMonth: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "de_DE")
        f.dateFormat = "dd.MM."
        return f
    }()

    public static func currency(_ value: Double, symbol: String = "EUR") -> String {
        return String(format: "%.2f %@", value, symbol)
    }

    public static func grams(_ value: Double) -> String {
        return String(format: "%.0f g", value)
    }

    public static func kcal(_ value: Double) -> String {
        return String(format: "%.0f kcal", value)
    }
}


