import SwiftUI

public struct ConcentricNutritionRingsView: View {
    public let proteinGrams: Double
    public let targetProtein: Double
    public let carbsGrams: Double
    public let targetCarbs: Double
    public let fatGrams: Double
    public let targetFat: Double
    public let caloriesConsumed: Double
    public let caloriesBudget: Double
    public let activeCaloriesBurned: Double
    public let onOpenGrowcery: () -> Void
    public let onShowInfo: (() -> Void)?

    public init(
        proteinGrams: Double,
        targetProtein: Double = 160.0,
        carbsGrams: Double,
        targetCarbs: Double = 390.0,
        fatGrams: Double,
        targetFat: Double = 75.0,
        caloriesConsumed: Double,
        caloriesBudget: Double = 2000.0,
        activeCaloriesBurned: Double,
        onOpenGrowcery: @escaping () -> Void,
        onShowInfo: (() -> Void)? = nil
    ) {
        self.proteinGrams = proteinGrams
        self.targetProtein = max(1.0, targetProtein)
        self.carbsGrams = carbsGrams
        self.targetCarbs = max(1.0, targetCarbs)
        self.fatGrams = fatGrams
        self.targetFat = max(1.0, targetFat)
        self.caloriesConsumed = caloriesConsumed
        self.caloriesBudget = max(1.0, caloriesBudget)
        self.activeCaloriesBurned = activeCaloriesBurned
        self.onOpenGrowcery = onOpenGrowcery
        self.onShowInfo = onShowInfo
    }

    private var proteinRatio: Double {
        min(1.0, max(0.0, proteinGrams / targetProtein))
    }

    private var carbsRatio: Double {
        min(1.0, max(0.0, carbsGrams / targetCarbs))
    }

    private var fatRatio: Double {
        min(1.0, max(0.0, fatGrams / targetFat))
    }

    private let proteinColor = Color(red: 0.96, green: 0.25, blue: 0.37)
    private let carbsColor = Color(red: 0.58, green: 0.88, blue: 0.28)
    private let fatColor = Color(red: 0.0, green: 0.82, blue: 0.92)

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header with info button
            HStack {
                Text("MAKRONAEHRSTOFF-RINGE")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(GymTheme.textMuted)
                    .tracking(1.0)
                Spacer()
                if let info = onShowInfo {
                    Button(action: info) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(GymTheme.warmSand)
                    }
                }
            }

            Button(action: {
                HapticFeedback.light()
                onOpenGrowcery()
            }) {
                VStack(spacing: 12) {
                    HStack(spacing: 16) {
                        // Concentric Rings
                        ZStack {
                            // Outer: Protein
                            Circle()
                                .stroke(proteinColor.opacity(0.18), lineWidth: 9)
                                .frame(width: 98, height: 98)
                            Circle()
                                .trim(from: 0, to: CGFloat(proteinRatio))
                                .stroke(proteinColor, style: StrokeStyle(lineWidth: 9, lineCap: .round))
                                .frame(width: 98, height: 98)
                                .rotationEffect(.degrees(-90))

                            // Middle: Carbs
                            Circle()
                                .stroke(carbsColor.opacity(0.18), lineWidth: 9)
                                .frame(width: 76, height: 76)
                            Circle()
                                .trim(from: 0, to: CGFloat(carbsRatio))
                                .stroke(carbsColor, style: StrokeStyle(lineWidth: 9, lineCap: .round))
                                .frame(width: 76, height: 76)
                                .rotationEffect(.degrees(-90))

                            // Inner: Fat
                            Circle()
                                .stroke(fatColor.opacity(0.18), lineWidth: 9)
                                .frame(width: 54, height: 54)
                            Circle()
                                .trim(from: 0, to: CGFloat(fatRatio))
                                .stroke(fatColor, style: StrokeStyle(lineWidth: 9, lineCap: .round))
                                .frame(width: 54, height: 54)
                                .rotationEffect(.degrees(-90))
                        }
                        .frame(width: 104, height: 104)

                        // Macro Values Stack
                        VStack(alignment: .leading, spacing: 8) {
                            // Protein
                            VStack(alignment: .leading, spacing: 1) {
                                Text("Protein")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(GymTheme.textPrimary)
                                HStack(alignment: .firstTextBaseline, spacing: 2) {
                                    Text(String(format: "%.1f", proteinGrams))
                                        .font(.system(size: 15, weight: .bold, design: .monospaced))
                                        .foregroundColor(proteinColor)
                                    Text("/ \(Int(targetProtein)) g")
                                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                                        .foregroundColor(proteinColor.opacity(0.85))
                                }
                            }

                            // Carbs
                            VStack(alignment: .leading, spacing: 1) {
                                Text("Kohlenhydrate")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(GymTheme.textPrimary)
                                HStack(alignment: .firstTextBaseline, spacing: 2) {
                                    Text("\(Int(carbsGrams))")
                                        .font(.system(size: 15, weight: .bold, design: .monospaced))
                                        .foregroundColor(carbsColor)
                                    Text("/ \(Int(targetCarbs)) g")
                                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                                        .foregroundColor(carbsColor.opacity(0.85))
                                }
                            }

                            // Fat
                            VStack(alignment: .leading, spacing: 1) {
                                Text("Fette")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(GymTheme.textPrimary)
                                HStack(alignment: .firstTextBaseline, spacing: 2) {
                                    Text("\(Int(fatGrams))")
                                        .font(.system(size: 15, weight: .bold, design: .monospaced))
                                        .foregroundColor(fatColor)
                                    Text("/ \(Int(targetFat)) g")
                                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                                        .foregroundColor(fatColor.opacity(0.85))
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // Energy & Burn Status Sub-bar
                    HStack(spacing: 8) {
                        HStack(alignment: .firstTextBaseline, spacing: 3) {
                            Text("\(Int(caloriesConsumed))")
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundColor(GymTheme.textPrimary)
                            Text("kcal gegessen")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(GymTheme.textMuted)
                        }

                        Spacer()

                        HStack(alignment: .firstTextBaseline, spacing: 3) {
                            Text("+\(Int(activeCaloriesBurned))")
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundColor(GymTheme.sageGreen)
                            Text("kcal aktiv")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(GymTheme.textMuted)
                        }

                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(GymTheme.sageGreen)
                            .padding(.leading, 2)
                    }
                    .padding(.top, 4)
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(14)
        .somaCard(borderColor: GymTheme.border, background: GymTheme.surfaceElevated)
    }
}
