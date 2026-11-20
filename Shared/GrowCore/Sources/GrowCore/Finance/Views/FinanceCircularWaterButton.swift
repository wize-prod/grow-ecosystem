import SwiftUI

public struct FinanceCircularWaterButton: View {
    @ObservedObject private var store = FinanceStore.shared
    @State private var showingQuickLog: Bool = false
    
    public init() {}
    
    private var progress: Double {
        guard store.targetWaterMl > 0 else { return 0 }
        return min(1.0, store.currentWaterMl / store.targetWaterMl)
    }
    
    public var body: some View {
        Menu {
            Section("Wasser protokollieren") {
                Button {
                    addWater(600)
                } label: {
                    Label("+600 ml", systemImage: "waterbottle.fill")
                }

                Button {
                    addWater(433)
                } label: {
                    Label("+433 ml", systemImage: "drop.fill")
                }

                Button {
                    addWater(1000)
                } label: {
                    Label("+1.000 ml (1,0 L)", systemImage: "waterbottle")
                }

                Button {
                    addWater(1500)
                } label: {
                    Label("+1.500 ml (1,5 L)", systemImage: "mug.fill")
                }
            }
            
            Section("Status: \(Int(store.currentWaterMl)) / \(Int(store.targetWaterMl)) ml") {
                Button(role: .destructive) {
                    store.resetWater()
                } label: {
                    Label("Zuruecksetzen", systemImage: "arrow.counterclockwise")
                }
            }
        } label: {
            ZStack {
                Circle()
                    .fill(FinanceTheme.surfaceRaised)
                    .frame(width: 32, height: 32)
                
                // Track
                Circle()
                    .stroke(FinanceTheme.surfaceBorder, lineWidth: 2)
                    .frame(width: 28, height: 28)
                
                // Progress
                Circle()
                    .trim(from: 0, to: CGFloat(progress))
                    .stroke(
                        FinanceTheme.accent,
                        style: StrokeStyle(lineWidth: 2, lineCap: .round)
                    )
                    .frame(width: 28, height: 28)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: progress)
                
                // Icon + Percentage
                VStack(spacing: 0.5) {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(FinanceTheme.accent)
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 7, weight: .bold, design: .monospaced))
                        .foregroundColor(FinanceTheme.textPrimary)
                }
            }
        }
        .simultaneousGesture(
            TapGesture(count: 2).onEnded {
                addWater(250)
            }
        )
    }
    
    private func addWater(_ ml: Double) {
        GrowHaptics.medium()
        store.addWater(amountMl: ml)
    }
}
