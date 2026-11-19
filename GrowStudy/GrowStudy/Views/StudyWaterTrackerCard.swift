import SwiftUI

public struct StudyWaterTrackerCard: View {
    @ObservedObject private var store = StudyStore.shared

    public init() {}

    private var waterLiters: Double {
        store.todayWaterMl / 1000.0
    }

    private var targetLiters: Double {
        store.targetWaterMl / 1000.0
    }

    private var ratio: Double {
        min(max(store.todayWaterMl / max(1.0, store.targetWaterMl), 0.0), 1.0)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Image(systemName: "drop.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(StudyTheme.strongBlue)
                        Text("HYDRATION & FOKUS")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(StudyTheme.textSecondary)
                    }
                    Text("GrowSuite 3-App Sync (Grow • Growcery • GrowStudy)")
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(StudyTheme.textMuted)
                }
                Spacer()
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text(String(format: "%.2f", waterLiters))
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundColor(ratio >= 1.0 ? StudyTheme.sageGreen : StudyTheme.textPrimary)
                    Text(String(format: " / %.1fL", targetLiters))
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(StudyTheme.textSecondary)
                }
            }

            // Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(StudyTheme.surfaceElevated)
                        .frame(height: 8)
                    Capsule()
                        .fill(ratio >= 1.0 ? StudyTheme.sageGreen : StudyTheme.strongBlue)
                        .frame(width: max(8, geo.size.width * CGFloat(ratio)), height: 8)
                }
            }
            .frame(height: 8)

            // Quick Add Buttons
            HStack(spacing: 6) {
                quickAddButton(label: "+150ml", amount: 150)
                quickAddButton(label: "+250ml", amount: 250)
                quickAddButton(label: "+500ml", amount: 500)
                quickAddButton(label: "+750ml", amount: 750)
                quickAddButton(label: "+1.0L", amount: 1000)

                Button {
                    store.resetWater(sourceApp: "GrowStudy")
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(StudyTheme.textMuted)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 6)
                        .background(StudyTheme.surfaceElevated)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
        }
        .wellnessCard(borderColor: StudyTheme.border, cornerRadius: 18)
        .onAppear {
            store.syncWaterFromBridge()
        }
    }

    private func quickAddButton(label: String, amount: Double) -> some View {
        Button {
            store.logWater(amountMl: amount, sourceApp: "GrowStudy")
        } label: {
            Text(label)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(StudyTheme.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.06))
                )
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.10), lineWidth: 0.8)
                )
        }
        .buttonStyle(AppleTactileButtonStyle())
    }
}
