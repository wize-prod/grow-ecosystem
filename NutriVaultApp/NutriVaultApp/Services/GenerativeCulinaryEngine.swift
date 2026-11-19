import Foundation

@MainActor
public final class GenerativeCulinaryEngine {
    public static let shared = GenerativeCulinaryEngine()

    private init() {}

    public func scale(
        template: MealTemplate,
        targetProtein: Double? = nil,
        targetKcal: Double,
        store: LocalStore
    ) -> MealTemplate {
        let currentKcal = store.templateKcal(for: template)
        guard currentKcal > 0 else { return template }
        let factor = max(0.5, min(2.5, targetKcal / currentKcal))

        var scaled = template
        scaled.ingredients = template.ingredients.map { ing in
            var updated = ing
            updated.grams = (ing.grams * factor).rounded()
            return updated
        }
        return scaled
    }
}
