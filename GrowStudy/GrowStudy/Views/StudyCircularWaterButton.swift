import SwiftUI

public struct StudyCircularWaterButton: View {
    @ObservedObject private var store = StudyStore.shared

    public init() {}

    private var waterLiters: Double {
        store.todayWaterMl / 1000.0
    }

    private var targetLiters: Double {
        store.targetWaterMl / 1000.0
    }

    private var isGoalReached: Bool {
        store.todayWaterMl >= store.targetWaterMl
    }

    private var percent: Int {
        Int(min(100.0, (store.todayWaterMl / max(1.0, store.targetWaterMl)) * 100.0))
    }

    public var body: some View {
        Menu {
            Section("Schnelle Erfassung") {
                Button(action: {
                    store.logWater(amountMl: 150, sourceApp: "GrowStudy")
                }) {
                    Label("+150 ml (Kleines Glas)", systemImage: "drop")
                }
                Button(action: {
                    store.logWater(amountMl: 250, sourceApp: "GrowStudy")
                }) {
                    Label("+250 ml (Standard Becher)", systemImage: "drop.fill")
                }
                Button(action: {
                    store.logWater(amountMl: 500, sourceApp: "GrowStudy")
                }) {
                    Label("+500 ml (Flasche / Shaker)", systemImage: "waterbottle.fill")
                }
                Button(action: {
                    store.logWater(amountMl: 750, sourceApp: "GrowStudy")
                }) {
                    Label("+750 ml (Grosse Flasche)", systemImage: "waterbottle")
                }
                Button(action: {
                    store.logWater(amountMl: 1000, sourceApp: "GrowStudy")
                }) {
                    Label("+1.000 ml (1 Liter)", systemImage: "mug.fill")
                }
            }
            Section("Hydration: \(String(format: "%.2fL / %.1fL", waterLiters, targetLiters)) (\(percent)%)") {
                Button(role: .destructive, action: {
                    store.resetWater(sourceApp: "GrowStudy")
                }) {
                    Label("Wasserstand zuruecksetzen (0 ml)", systemImage: "arrow.counterclockwise")
                }
            }
        } label: {
            ZStack {
                Circle()
                    .fill(StudyTheme.surfaceElevated)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Circle()
                            .stroke(isGoalReached ? StudyTheme.sageGreen : StudyTheme.strongBlue, lineWidth: 2)
                    )
                    .shadow(color: Color.black.opacity(0.4), radius: 6, x: 0, y: 3)

                VStack(spacing: 1) {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(isGoalReached ? StudyTheme.sageGreen : StudyTheme.strongBlue)
                    Text(String(format: "%.1fL", waterLiters))
                        .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                        .foregroundColor(StudyTheme.textPrimary)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            store.syncWaterFromBridge()
        }
    }
}
