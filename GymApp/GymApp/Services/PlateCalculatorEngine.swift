import Foundation
import SwiftUI

public struct PlateItem: Identifiable, Equatable, Hashable {
    public var id: Double { weightKg }
    public let weightKg: Double
    public let countPerSide: Int
    public let color: Color
    public let labelColor: Color

    public init(weightKg: Double, countPerSide: Int) {
        self.weightKg = weightKg
        self.countPerSide = countPerSide

        // Standard Olympic Color Code (austere dark mode tailored)
        switch weightKg {
        case 25.0:
            self.color = Color(red: 0.82, green: 0.22, blue: 0.22) // Red
            self.labelColor = .white
        case 20.0:
            self.color = Color(red: 0.20, green: 0.45, blue: 0.85) // Blue
            self.labelColor = .white
        case 15.0:
            self.color = Color(red: 0.88, green: 0.72, blue: 0.20) // Yellow
            self.labelColor = .black
        case 10.0:
            self.color = Color(red: 0.22, green: 0.65, blue: 0.35) // Green
            self.labelColor = .white
        case 5.0:
            self.color = Color(red: 0.85, green: 0.88, blue: 0.92) // White
            self.labelColor = .black
        case 2.5:
            self.color = Color(red: 0.35, green: 0.38, blue: 0.42) // Dark Grey
            self.labelColor = .white
        case 1.25:
            self.color = Color(red: 0.65, green: 0.70, blue: 0.75) // Silver
            self.labelColor = .black
        default:
            self.color = Color(red: 0.30, green: 0.32, blue: 0.38)
            self.labelColor = .white
        }
    }
}

public struct PlateBreakdown: Equatable {
    public let targetWeightKg: Double
    public let barbellWeightKg: Double
    public let weightPerSideKg: Double
    public let achievedTotalWeightKg: Double
    public let platesPerSide: [PlateItem]
    public let isExact: Bool

    public var plateSummaryText: String {
        guard !platesPerSide.isEmpty else { return "Nur Hantelstange (\(Int(barbellWeightKg)) kg)" }
        return platesPerSide
            .map { "\($0.countPerSide)× \(formatWeight($0.weightKg)) kg" }
            .joined(separator: " • ")
    }

    private func formatWeight(_ w: Double) -> String {
        w.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(w))" : String(format: "%.2g", w).replacingOccurrences(of: ".", with: ",")
    }
}

public enum PlateCalculatorEngine {
    public static let standardPlates: [Double] = [25.0, 20.0, 15.0, 10.0, 5.0, 2.5, 1.25]
    public static let standardBarbellOptions: [Double] = [20.0, 15.0, 10.0, 0.0]

    public static func calculate(
        targetWeightKg: Double,
        barbellWeightKg: Double = 20.0,
        availablePlates: [Double] = standardPlates
    ) -> PlateBreakdown {
        let safeTarget = max(0.0, targetWeightKg)
        let safeBar = max(0.0, barbellWeightKg)

        guard safeTarget > safeBar else {
            return PlateBreakdown(
                targetWeightKg: safeTarget,
                barbellWeightKg: safeBar,
                weightPerSideKg: 0.0,
                achievedTotalWeightKg: safeBar,
                platesPerSide: [],
                isExact: safeTarget == safeBar
            )
        }

        let neededTotalPlates = safeTarget - safeBar
        var remainingPerSide = neededTotalPlates / 2.0
        let targetPerSide = remainingPerSide

        var result: [PlateItem] = []
        let sortedPlates = availablePlates.filter { $0 > 0 }.sorted(by: >)

        for plate in sortedPlates {
            if remainingPerSide >= plate {
                let count = Int(remainingPerSide / plate)
                if count > 0 {
                    result.append(PlateItem(weightKg: plate, countPerSide: count))
                    remainingPerSide -= Double(count) * plate
                }
            }
        }

        let achievedPlatesPerSide = result.reduce(0.0) { $0 + ($1.weightKg * Double($1.countPerSide)) }
        let achievedTotal = safeBar + (achievedPlatesPerSide * 2.0)
        let isExact = abs(achievedTotal - safeTarget) < 0.01

        return PlateBreakdown(
            targetWeightKg: safeTarget,
            barbellWeightKg: safeBar,
            weightPerSideKg: targetPerSide,
            achievedTotalWeightKg: achievedTotal,
            platesPerSide: result,
            isExact: isExact
        )
    }
}
