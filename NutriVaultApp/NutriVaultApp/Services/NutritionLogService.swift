import Foundation

// MARK: - NutritionLogService (Domain Controller for Daily Intake, Macros & Reha)
public final class NutritionLogService {
    public static let shared = NutritionLogService()

    private init() {}

    public func dailyEntries(for date: Date, in mealLogs: [MealLogEntry]) -> [MealLogEntry] {
        let cal = Calendar.current
        return mealLogs.filter { cal.isDate($0.timestamp, inSameDayAs: date) }
    }

    public func calculateDailyMacros(for date: Date, in mealLogs: [MealLogEntry]) -> (kcal: Double, protein: Double, carbs: Double, fat: Double, fiber: Double) {
        let entries = dailyEntries(for: date, in: mealLogs)
        var totalKcal = 0.0
        var totalP = 0.0
        var totalC = 0.0
        var totalF = 0.0
        var totalFiber = 0.0

        for entry in entries {
            totalKcal += entry.kcal
            totalP += entry.protein
            totalC += entry.carbs
            totalF += entry.fat
            totalFiber += entry.fiber
        }
        return (totalKcal, totalP, totalC, totalF, totalFiber)
    }

    public func isSupplementAlreadyLoggedToday(name: String, todayEntries: [MealLogEntry]) -> Bool {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return todayEntries.contains(where: { entry in
            entry.foodName.lowercased().contains(cleanName)
        })
    }
}
