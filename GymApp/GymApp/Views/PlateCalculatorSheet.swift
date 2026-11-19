import SwiftUI

public struct PlateCalculatorSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var targetWeight: Double
    @State private var barbellWeight: Double = 20.0
    public var onApplyWeight: ((Double) -> Void)? = nil

    private let quickAdds: [Double] = [1.25, 2.5, 5.0, 10.0, 20.0]

    public init(initialWeightKg: Double = 60.0, onApplyWeight: ((Double) -> Void)? = nil) {
        _targetWeight = State(initialValue: max(0.0, initialWeightKg))
        self.onApplyWeight = onApplyWeight
    }

    private var breakdown: PlateBreakdown {
        PlateCalculatorEngine.calculate(
            targetWeightKg: targetWeight,
            barbellWeightKg: barbellWeight
        )
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                GymTheme.bg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // 1. Target Weight Display & Control Card
                        VStack(spacing: 12) {
                            Text("ZIELGEWICHT (GESAMT)")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(GymTheme.textMuted)
                                .tracking(1.0)

                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text(formatWeight(targetWeight))
                                    .font(.system(size: 42, weight: .black, design: .monospaced))
                                    .foregroundColor(GymTheme.textPrimary)
                                Text("kg")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(GymTheme.sageGreen)
                            }

                            // Quick adjustment buttons
                            HStack(spacing: 8) {
                                Button(action: {
                                    targetWeight = max(barbellWeight, targetWeight - 5.0)
                                    HapticFeedback.light()
                                }) {
                                    Text("-5 kg")
                                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(GymTheme.surfaceElevated)
                                        .foregroundColor(GymTheme.textSecondary)
                                        .cornerRadius(8)
                                }

                                Button(action: {
                                    targetWeight = max(barbellWeight, targetWeight - 2.5)
                                    HapticFeedback.light()
                                }) {
                                    Text("-2,5 kg")
                                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(GymTheme.surfaceElevated)
                                        .foregroundColor(GymTheme.textSecondary)
                                        .cornerRadius(8)
                                }

                                Button(action: {
                                    targetWeight += 2.5
                                    HapticFeedback.light()
                                }) {
                                    Text("+2,5 kg")
                                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(GymTheme.surfaceElevated)
                                        .foregroundColor(GymTheme.sageGreen)
                                        .cornerRadius(8)
                                }

                                Button(action: {
                                    targetWeight += 5.0
                                    HapticFeedback.light()
                                }) {
                                    Text("+5 kg")
                                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(GymTheme.surfaceElevated)
                                        .foregroundColor(GymTheme.sageGreen)
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .padding(16)
                        .wellnessCard(borderColor: GymTheme.border, cornerRadius: 18)

                        // 2. Barbell Specification Selector
                        VStack(alignment: .leading, spacing: 8) {
                            Text("HANTELSTANGE / EIGENGEWICHT")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(GymTheme.textMuted)

                            HStack(spacing: 8) {
                                barButton(name: "Olympia 20kg", weight: 20.0)
                                barButton(name: "Damen 15kg", weight: 15.0)
                                barButton(name: "EZ 10kg", weight: 10.0)
                                barButton(name: "Geraet 0kg", weight: 0.0)
                            }
                        }
                        .padding(14)
                        .wellnessCard(borderColor: GymTheme.border, cornerRadius: 16)

                        // 3. Visual Barbell Sleeve Representation
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("SCHEIBEN PRO SEITE")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(GymTheme.textMuted)
                                Spacer()
                                Text("\(formatWeight(breakdown.weightPerSideKg)) kg pro Seite")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(GymTheme.accentGold)
                            }

                            // Visual Bar Sleeve with Plates
                            ZStack(alignment: .leading) {
                                // Barbell bar line
                                Rectangle()
                                    .fill(Color(white: 0.35))
                                    .frame(height: 14)
                                    .cornerRadius(3)

                                // Bar collar / stop
                                Rectangle()
                                    .fill(Color(white: 0.55))
                                    .frame(width: 14, height: 50)
                                    .cornerRadius(2)
                                    .padding(.leading, 12)

                                // Stacking plates
                                HStack(spacing: 3) {
                                    Spacer().frame(width: 28)

                                    if breakdown.platesPerSide.isEmpty {
                                        Text("Keine Scheiben")
                                            .font(.caption2)
                                            .foregroundColor(GymTheme.textMuted)
                                            .padding(.leading, 8)
                                    } else {
                                        ForEach(breakdown.platesPerSide) { item in
                                            ForEach(0..<item.countPerSide, id: \.self) { _ in
                                                plateGraphic(item: item)
                                            }
                                        }
                                    }
                                }
                            }
                            .frame(height: 80)
                            .frame(maxWidth: .infinity)
                            .background(Color(red: 0.08, green: 0.09, blue: 0.11))
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(GymTheme.borderSubtle, lineWidth: 1))
                        }
                        .padding(14)
                        .wellnessCard(borderColor: GymTheme.border, cornerRadius: 16)

                        // 4. Detailed Plates Count Breakdown List
                        VStack(alignment: .leading, spacing: 10) {
                            Text("SCHEIBEN-AUFSTELLUNG")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(GymTheme.textMuted)

                            if breakdown.platesPerSide.isEmpty {
                                Text("Fuer dieses Gewicht werden keine zusaetzlichen Hantelscheiben benoetigt.")
                                    .font(.system(size: 12))
                                    .foregroundColor(GymTheme.textSecondary)
                                    .padding(.vertical, 8)
                            } else {
                                VStack(spacing: 8) {
                                    ForEach(breakdown.platesPerSide) { item in
                                        HStack {
                                            Circle()
                                                .fill(item.color)
                                                .frame(width: 12, height: 12)

                                            Text("\(formatWeight(item.weightKg)) kg Scheibe")
                                                .font(.system(size: 13, weight: .semibold))
                                                .foregroundColor(GymTheme.textPrimary)

                                            Spacer()

                                            Text("\(item.countPerSide)× pro Seite (\(item.countPerSide * 2) gesamt)")
                                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                                .foregroundColor(GymTheme.sageGreen)
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(GymTheme.surfaceElevated)
                                        .cornerRadius(8)
                                    }
                                }
                            }

                            if !breakdown.isExact {
                                Text("Hinweis: Geringe Rundungsdifferenz durch Standard-Scheibengroessen (Min. 1,25 kg).")
                                    .font(.system(size: 10.5))
                                    .foregroundColor(GymTheme.terracotta)
                            }
                        }
                        .padding(14)
                        .wellnessCard(borderColor: GymTheme.border, cornerRadius: 16)

                        // 5. Apply Button (if callback provided)
                        if let onApply = onApplyWeight {
                            Button(action: {
                                onApply(targetWeight)
                                dismiss()
                                HapticFeedback.medium()
                            }) {
                                Text("Gewicht uebernehmen (\(formatWeight(targetWeight)) kg)")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(GymTheme.bg)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Capsule().fill(GymTheme.strongBlue))
                            }
                            .buttonStyle(.plain)
                        }

                        Spacer(minLength: 30)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Plate Calculator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") { dismiss() }
                        .foregroundColor(GymTheme.strongBlue)
                }
            }
        }
    }

    private func barButton(name: String, weight: Double) -> some View {
        let isSelected = barbellWeight == weight
        return Button {
            barbellWeight = weight
            HapticFeedback.selection()
        } label: {
            Text(name)
                .font(.system(size: 10.5, weight: isSelected ? .bold : .medium))
                .foregroundColor(isSelected ? GymTheme.bg : GymTheme.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(isSelected ? GymTheme.sageGreen : GymTheme.surfaceElevated)
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }

    private func plateGraphic(item: PlateItem) -> some View {
        // Height proportional to weight
        let height: CGFloat = max(30, min(68, CGFloat(30.0 + (item.weightKg * 1.5))))
        let width: CGFloat = max(10, min(18, CGFloat(8.0 + (item.weightKg * 0.4))))

        return ZStack {
            RoundedRectangle(cornerRadius: 3)
                .fill(item.color)
                .frame(width: width, height: height)
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(Color.white.opacity(0.3), lineWidth: 0.8)
                )

            Text(formatShortWeight(item.weightKg))
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(item.labelColor)
                .rotationEffect(.degrees(-90))
        }
    }

    private func formatWeight(_ w: Double) -> String {
        w.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(w))" : String(format: "%.1f", w).replacingOccurrences(of: ".", with: ",")
    }

    private func formatShortWeight(_ w: Double) -> String {
        w.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(w))" : String(format: "%.1f", w)
    }
}
