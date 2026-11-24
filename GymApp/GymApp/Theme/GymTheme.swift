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
    public static let borderSubtle = Color.white.opacity(0.05)
    public static let borderFocused = Color.white.opacity(0.20)

    // Typography Labels
    public static let textPrimary = Color.white // #FFFFFF
    public static let textSecondary = Color(red: 0.556, green: 0.556, blue: 0.576) // Apple secondaryLabel #8E8E93
    public static let textMuted = Color(red: 0.388, green: 0.388, blue: 0.400) // Apple tertiaryLabel #636366

    // Functional Semantic System Accents (Apple HIG Dark Palette)
    public static let statusSuccess = Color(red: 0.188, green: 0.820, blue: 0.345) // Apple System Green #30D158 (Sage Green)
    public static let statusDanger = Color(red: 1.000, green: 0.271, blue: 0.227) // Apple System Red #FF453A (Terracotta)
    public static let statusWarning = Color(red: 0.235, green: 0.827, blue: 0.996) // Apple System Cyan #3CD3FE (Warm Sand / Cyan)
    public static let statusWarningAmber = Color(red: 1.000, green: 0.624, blue: 0.039) // Apple System Orange #FF9F0A
    public static let statusInteractive = Color(red: 0.039, green: 0.518, blue: 1.000) // Apple System Blue #0A84FF

    // Domain Specific Accents (Growcery Signature Palette)
    public static let sageGreen = statusSuccess
    public static let terracotta = statusDanger
    public static let electricBlue = statusInteractive
    public static let careLilac = Color(red: 0.65, green: 0.54, blue: 0.98) // #A68AFA
    public static let mintAccent = Color(red: 0.000, green: 0.855, blue: 0.765) // #00DAC3
    public static let cyanAccent = statusWarning
    public static let warmSand = statusWarning // #3CD3FE (Cyan in Growcery!)
    public static let softRose = Color(red: 1.000, green: 0.216, blue: 0.373)
    public static let alertRed = statusDanger
}

// MARK: - 3. BACKWARD COMPATIBLE GYM THEME STRUCT (GROWCERY PARITY)
public struct GymTheme {
    // Apple HIG OLED & Inset Grouped Palette
    public static let bg = GrowColor.bg
    public static let surface = GrowColor.surface
    public static let surfaceElevated = GrowColor.surfaceElevated
    public static let surfaceSubtle = GrowColor.surfaceSubtle
    public static let border = GrowColor.border
    public static let borderSubtle = GrowColor.borderSubtle
    public static let borderFocused = GrowColor.borderFocused

    // Typography
    public typealias Typography = GrowTypography
    public static let textPrimary = GrowColor.textPrimary
    public static let textSecondary = GrowColor.textSecondary
    public static let textMuted = GrowColor.textMuted

    // Functional Semantic System Accents
    public static let sageGreen = GrowColor.statusSuccess
    public static let sageLight = GrowColor.statusSuccess
    public static let warmSand = GrowColor.warmSand // #3CD3FE Cyan!
    public static let cyanAccent = GrowColor.cyanAccent
    public static let terracotta = GrowColor.terracotta
    public static let softRose = GrowColor.softRose
    public static let strongBlue = GrowColor.statusInteractive
    public static let warmAmber = GrowColor.statusWarningAmber
    public static let warningAmber = GrowColor.statusWarningAmber
    public static let mintAccent = GrowColor.mintAccent
    public static let tealAccent = GrowColor.mintAccent

    // Action Pills & Buttons matching Growcery
    public static let actionPill = sageGreen // Primary action is Growcery Sage Green!
    public static let secondaryPill = warmSand // Cyan accent!
    public static let bluePill = surfaceElevated
    public static let finishGreen = sageGreen
    public static let cancelRed = terracotta
    public static let cancelRedBg = Color(red: 0.25, green: 0.08, blue: 0.08)
    public static let cardDark = surface
    public static let inputBg = surfaceElevated
    public static let stravaOrange = Color(red: 0.98, green: 0.34, blue: 0.11)
    public static let appleHealthPink = softRose

    // Anatomical & Scientific Palette
    public static let accentOrange = warmSand
    public static let accentGold = warmSand
    public static let accentRed = terracotta
    public static let accentGreen = sageGreen

    // Apple Fitness Activity Ring Gradients (Exact Growcery values)
    public static let ringProteinStart = Color(red: 1.000, green: 0.263, blue: 0.271)
    public static let ringProteinEnd = Color(red: 1.000, green: 0.216, blue: 0.373)
    public static let ringCarbsStart = Color(red: 0.188, green: 0.820, blue: 0.345)
    public static let ringCarbsEnd = Color(red: 0.000, green: 0.855, blue: 0.765)
    public static let ringFatStart = Color(red: 0.235, green: 0.827, blue: 0.996)
    public static let ringFatEnd = Color(red: 0.000, green: 0.569, blue: 1.000)

    // Standard Semantic Aliases
    public static let primary = sageGreen
    public static let accent = warmSand
    public static let background = bg
}

public typealias Theme = GymTheme

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
    private static var suppressedUntil: Date = Date().addingTimeInterval(1.5)

    public static func suppressForAppOpen(duration: TimeInterval = 1.5) {
        suppressedUntil = Date().addingTimeInterval(duration)
    }

    private static var isSuppressed: Bool {
        Date() < suppressedUntil
    }

    public static func soft() {
        guard !isSuppressed else { return }
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.prepare()
        generator.impactOccurred()
    }

    public static func light() {
        guard !isSuppressed else { return }
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }

    public static func medium() {
        guard !isSuppressed else { return }
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }

    public static func heavy() {
        guard !isSuppressed else { return }
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.prepare()
        generator.impactOccurred()
    }

    public static func selection() {
        guard !isSuppressed else { return }
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }

    public static func success() {
        guard !isSuppressed else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }

    public static func warning() {
        guard !isSuppressed else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.warning)
    }

    public static func error() {
        guard !isSuppressed else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.error)
    }
}

public struct HapticFeedback {
    public static func soft() { GrowHaptics.soft() }
    public static func light() { GrowHaptics.light() }
    public static func medium() { GrowHaptics.medium() }
    public static func mechanicalClick() { GrowHaptics.medium() }
    public static func success() { GrowHaptics.success() }
    public static func warning() { GrowHaptics.warning() }
    public static func error() { GrowHaptics.error() }
    public static func selection() { GrowHaptics.selection() }
}

// MARK: - 6. CARD MODIFIERS & STYLES
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
    var borderColor: Color = GymTheme.border
    var cornerRadius: CGFloat = 18

    public func body(content: Content) -> some View {
        content
            .modifier(GrowCardModifier(cornerRadius: cornerRadius, backgroundColor: GymTheme.surface, borderColor: borderColor, hasSpecularGradient: false))
    }
}

public struct SomaCardModifier: ViewModifier {
    var borderColor: Color = GymTheme.border
    var cornerRadius: CGFloat = 18
    var background: Color = GymTheme.surface

    public func body(content: Content) -> some View {
        content
            .modifier(GrowCardModifier(cornerRadius: cornerRadius, backgroundColor: background, borderColor: borderColor, hasSpecularGradient: true))
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

    public init(isSelected: Bool = false, activeTint: Color = GymTheme.sageGreen) {
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
            .foregroundColor(isSelected ? Color.white : GymTheme.textSecondary)
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
    func wellnessCard(borderColor: Color = GymTheme.border, cornerRadius: CGFloat = 18) -> some View {
        self.modifier(WellnessCardModifier(borderColor: borderColor, cornerRadius: cornerRadius))
    }

    func somaCard(borderColor: Color = GymTheme.border, cornerRadius: CGFloat = 18, background: Color = GymTheme.surface) -> some View {
        self.modifier(SomaCardModifier(borderColor: borderColor, cornerRadius: cornerRadius, background: background))
    }

    func liquidGlass(cornerRadius: CGFloat = 16, material: Material = .ultraThinMaterial) -> some View {
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

// MARK: - Color Hex Initializer
public extension Color {
    init(hex: String) {
        let hexClean = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hexClean).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hexClean.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Keyboard Dismiss Extensions
public extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    func dismissKeyboardOnTap() -> some View {
        self.onTapGesture {
            self.hideKeyboard()
        }
    }

    func dismissKeyboardOnSwipeDown() -> some View {
        self.gesture(
            DragGesture().onChanged { value in
                if value.translation.height > 20 {
                    self.hideKeyboard()
                }
            }
        )
    }
}

// MARK: - GrowFormatters
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
