import SwiftUI

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
                    store.logWater(ml: 600, sourceApp: "Grow")
                }) {
                    Label("+600 ml", systemImage: "waterbottle.fill")
                }
                Button(action: {
                    HapticFeedbackService.shared.lightDetent()
                    store.logWater(ml: 433, sourceApp: "Grow")
                }) {
                    Label("+433 ml", systemImage: "drop.fill")
                }
                Button(action: {
                    HapticFeedbackService.shared.lightDetent()
                    store.logWater(ml: 1000, sourceApp: "Grow")
                }) {
                    Label("+1.000 ml (1,0 L)", systemImage: "waterbottle")
                }
                Button(action: {
                    HapticFeedbackService.shared.lightDetent()
                    store.logWater(ml: 1500, sourceApp: "Grow")
                }) {
                    Label("+1.500 ml (1,5 L)", systemImage: "mug.fill")
                }
            }
            Section("Hydration: \(String(format: "%.2fL / %.1fL", waterLiters, targetLiters)) (\(percent)%)") {
                Button(role: .destructive, action: {
                    HapticFeedbackService.shared.mechanicalClick()
                    store.resetWater(sourceApp: "Grow")
                }) {
                    Label("Wasserstand zuruecksetzen (0 ml)", systemImage: "arrow.counterclockwise")
                }
            }
        } label: {
            ZStack {
                // Background disc
                Circle()
                    .fill(GrowColor.surfaceElevated)
                    .frame(width: 44, height: 44)

                // Track ring (subtle border)
                Circle()
                    .stroke(GrowColor.border.opacity(0.6), lineWidth: 2.5)
                    .frame(width: 44, height: 44)

                // Percentage Border: Closes into a full ring as intake approaches goal
                if progressRatio > 0 {
                    Circle()
                        .trim(from: 0.0, to: CGFloat(progressRatio))
                        .stroke(
                            isGoalReached ? GrowColor.statusSuccess : GrowColor.warmSand,
                            style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                        )
                        .frame(width: 44, height: 44)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.35), value: progressRatio)
                }

                VStack(spacing: 1) {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(isGoalReached ? GrowColor.statusSuccess : GrowColor.warmSand)
                    Text(String(format: "%.1fL", waterLiters))
                        .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                        .foregroundColor(GrowColor.textPrimary)
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
