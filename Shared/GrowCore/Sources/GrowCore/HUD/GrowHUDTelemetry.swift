import Foundation
import SwiftUI

public struct EcosystemLiveHUDState: Equatable, Sendable {
    public var waterCurrentMl: Double
    public var waterTargetMl: Double
    public var proteinCurrentG: Double
    public var proteinTargetG: Double
    public var caloriesCurrentKcal: Double
    public var caloriesTargetKcal: Double
    public var liquidCashEur: Double
    public var leakFreeStreakDays: Int
    public var activeStudyTimerSeconds: Int
    public var isStudyTimerActive: Bool
    public var completedTasksCount: Int
    public var totalTasksCount: Int

    public init(
        waterCurrentMl: Double = 0.0,
        waterTargetMl: Double = 2500.0,
        proteinCurrentG: Double = 0.0,
        proteinTargetG: Double = 160.0,
        caloriesCurrentKcal: Double = 0.0,
        caloriesTargetKcal: Double = 1950.0,
        liquidCashEur: Double = 0.0,
        leakFreeStreakDays: Int = 0,
        activeStudyTimerSeconds: Int = 0,
        isStudyTimerActive: Bool = false,
        completedTasksCount: Int = 0,
        totalTasksCount: Int = 0
    ) {
        self.waterCurrentMl = waterCurrentMl
        self.waterTargetMl = waterTargetMl
        self.proteinCurrentG = proteinCurrentG
        self.proteinTargetG = proteinTargetG
        self.caloriesCurrentKcal = caloriesCurrentKcal
        self.caloriesTargetKcal = caloriesTargetKcal
        self.liquidCashEur = liquidCashEur
        self.leakFreeStreakDays = leakFreeStreakDays
        self.activeStudyTimerSeconds = activeStudyTimerSeconds
        self.isStudyTimerActive = isStudyTimerActive
        self.completedTasksCount = completedTasksCount
        self.totalTasksCount = totalTasksCount
    }
}

public struct CompactDenseHUDStrip: View {
    public let state: EcosystemLiveHUDState

    public init(state: EcosystemLiveHUDState) {
        self.state = state
    }

    public var body: some View {
        HStack(spacing: 8) {
            // 1. Hydration
            hudPill(
                title: "H2O",
                value: "\(Int(state.waterCurrentMl))/\(Int(state.waterTargetMl)) ml",
                ratio: state.waterTargetMl > 0 ? min(1.0, state.waterCurrentMl / state.waterTargetMl) : 0.0,
                color: Color.blue
            )

            // 2. Protein
            hudPill(
                title: "PROT",
                value: "\(Int(state.proteinCurrentG))/\(Int(state.proteinTargetG)) g",
                ratio: state.proteinTargetG > 0 ? min(1.0, state.proteinCurrentG / state.proteinTargetG) : 0.0,
                color: Color.green
            )

            // 3. Finance (Liquid Buffer)
            hudPill(
                title: "LIQ",
                value: "\(Int(state.liquidCashEur)) EUR",
                ratio: state.liquidCashEur > 0 ? 1.0 : 0.2,
                color: state.liquidCashEur >= 100 ? Color.orange : Color.red
            )

            // 4. Study Focus Timer
            if state.isStudyTimerActive {
                hudTimerPill(
                    title: "FOKUS",
                    seconds: state.activeStudyTimerSeconds,
                    color: Color.purple
                )
            } else {
                hudPill(
                    title: "TASKS",
                    value: "\(state.completedTasksCount)/\(state.totalTasksCount)",
                    ratio: state.totalTasksCount > 0 ? Double(state.completedTasksCount) / Double(state.totalTasksCount) : 0.0,
                    color: Color.purple
                )
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(hudBackground)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }

    private var hudBackground: Color {
        #if canImport(UIKit)
        return Color(uiColor: .secondarySystemBackground).opacity(0.95)
        #elseif canImport(AppKit)
        return Color(nsColor: .windowBackgroundColor).opacity(0.95)
        #else
        return Color.gray.opacity(0.15)
        #endif
    }

    private func hudPill(title: String, value: String, ratio: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(color)
                Spacer(minLength: 0)
                Text(value)
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(.primary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(color.opacity(0.2))
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(color)
                        .frame(width: geo.size.width * CGFloat(max(0.0, min(1.0, ratio))))
                }
            }
            .frame(height: 3)
        }
        .frame(maxWidth: .infinity)
    }

    private func hudTimerPill(title: String, seconds: Int, color: Color) -> some View {
        let m = seconds / 60
        let s = seconds % 60
        let formatted = String(format: "%02d:%02d", m, s)

        return VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(color)
                Spacer(minLength: 0)
                Text(formatted)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(color)
            }
            RoundedRectangle(cornerRadius: 1.5)
                .fill(color)
                .frame(height: 3)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - High-Density Batch Selection Manager
public final class BatchSelectionManager: ObservableObject {
    @Published public var isSelectionMode: Bool = false
    @Published public var selectedItemIds: Set<String> = []

    public init() {}

    public func toggleItem(_ id: String) {
        if selectedItemIds.contains(id) {
            selectedItemIds.remove(id)
        } else {
            selectedItemIds.insert(id)
        }
    }

    public func selectAll(_ ids: [String]) {
        selectedItemIds = Set(ids)
    }

    public func clear() {
        selectedItemIds.removeAll()
        isSelectionMode = false
    }
}
