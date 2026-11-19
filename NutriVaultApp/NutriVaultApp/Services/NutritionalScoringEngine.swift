import Foundation

public enum TrafficLightColor: String, Codable, Hashable {
    case green = "GRÜN"
    case amber = "GELB"
    case red = "ROT"

    public var systemColorName: String {
        switch self {
        case .green: return "checkmark.circle.fill"
        case .amber: return "exclamationmark.triangle.fill"
        case .red: return "xmark.octagon.fill"
        }
    }
}

public struct ComprehensiveNutritionScore: Codable, Hashable {
    // 0. Data Validity
    public let hasSufficientData: Bool

    // Unified NutriVault Composite Index (Synthesis of all 7 pillars)
    public let compositeHealthIndex: Int        // 0 - 100 (Phi Metric)
    public let compositeGrade: String           // A+, A, B, C, D
    public let compositeVerdict: String         // e.g. "Exzellente Nährstoffdichte & Reha-Konvergenz"

    // Clinical & Reha Pillars
    public let bwkVisceralRehaScore: Int        // 0 - 100 (BWK Ulm Pelvic & Mucosa Standard)
    public let bwkVisceralGrade: String         // Zielerfüllung, Ausreichend, Ausbaufähig
    public let lprSafetyScore: Int              // 0 - 100 (Reflux & Sphinkter-Schutz)
    public let lprSafetyCategory: String        // Reflux-Sicher, Moderat, Sphinkter-Relaxans
    public let novaClass: Int                   // 1, 2, 3, 4 (Processing Level)
    public let novaCategory: String             // NOVA 1-4 Description

    // 1. Advanced Nutrient-Density Metrics (The Gold Standard)
    public let tyBealScore: Double          // 0 - 100
    public let tyBealRating: String
    public let potassiumSodiumRatio: Double  // K:Na Quotient (> 2.0 = minimal verarbeitet, < 1.0 = industriell verarbeitet)
    public let foodCompassScore: Int        // 1 - 100 (Tufts University)
    public let foodCompassCategory: String  // Bevorzugen (>=70), In Maßen (31-69), Minimieren (<=30)

    // 2. Front-of-Pack Graded Systems (Most Actionable)
    public let nutriScoreGrade: String      // A, B, C, D, E, -
    public let healthStarRating: Double     // 0.5 - 5.0 Sterne
    public let guidingStars: Int            // 0, 1, 2, 3 Sterne

    // 3. Summary Indicator & Specific Metrics
    public let trafficLightFat: TrafficLightColor
    public let trafficLightSatFat: TrafficLightColor
    public let trafficLightSugar: TrafficLightColor
    public let trafficLightSalt: TrafficLightColor

    public let glycemicIndex: Int           // 0 - 100
    public let glycemicCategory: String     // Niedrig (<=55), Moderat (56-69), Hoch (>=70)

    public let bpiProteinIndex: Double      // Protein density: g Protein / 100 kcal
    public let bpiCategory: String          // Exzellente Proteinquelle, Gute Proteinquelle, Moderat, Gering

    // Source Classifications & Highlights
    public let sourceHighlights: [String]   // Badges: "Top-Proteinquelle", "Hoher Ballaststoffgehalt", etc.

    public static func unscored(productName: String) -> ComprehensiveNutritionScore {
        return ComprehensiveNutritionScore(
            hasSufficientData: false,
            compositeHealthIndex: 0,
            compositeGrade: "-",
            compositeVerdict: "Unbewertet (Keine Nährwertdaten)",
            bwkVisceralRehaScore: 0,
            bwkVisceralGrade: "Nicht erfasst",
            lprSafetyScore: 0,
            lprSafetyCategory: "Nicht erfasst",
            novaClass: 0,
            novaCategory: "Nicht erfasst",
            tyBealScore: 0.0,
            tyBealRating: "Unbewertet (Keine Nährwertdaten)",
            potassiumSodiumRatio: 0.0,
            foodCompassScore: 0,
            foodCompassCategory: "Unbewertet",
            nutriScoreGrade: "-",
            healthStarRating: 0.0,
            guidingStars: 0,
            trafficLightFat: .amber,
            trafficLightSatFat: .amber,
            trafficLightSugar: .amber,
            trafficLightSalt: .amber,
            glycemicIndex: 0,
            glycemicCategory: "Nicht erfasst",
            bpiProteinIndex: 0.0,
            bpiCategory: "Nicht erfasst",
            sourceHighlights: ["Keine Nährwerte erfasst"]
        )
    }
}

public final class NutritionalScoringEngine {
    public static let shared = NutritionalScoringEngine()

    private init() {}

    private var templateScoreCache: [String: ComprehensiveNutritionScore] = [:]
    private var itemScoreCache: [String: ComprehensiveNutritionScore] = [:]
    private let cacheLock = NSLock()

    public func clearCache() {
        cacheLock.lock()
        templateScoreCache.removeAll()
        itemScoreCache.removeAll()
        cacheLock.unlock()
    }

    // MARK: - Evaluate PantryItem
    public func evaluate(item: PantryItem) -> ComprehensiveNutritionScore {
        guard item.hasNutritionalData else {
            return ComprehensiveNutritionScore.unscored(productName: item.name)
        }
        cacheLock.lock()
        if let cached = itemScoreCache[item.id] {
            cacheLock.unlock()
            return cached
        }
        cacheLock.unlock()

        let prof = item.effectiveProfile()
        let score = calculateScore(
            kcal100g: item.kcal100g,
            protein100g: item.protein100g,
            carbs100g: item.carbs100g,
            fat100g: item.fat100g,
            fiber100g: item.fiber100g > 0 ? item.fiber100g : (prof.fiber ?? 0.0),
            sugars100g: prof.sugars ?? 0.0,
            satFat100g: prof.saturatedFat ?? 0.0,
            sodiumMg100g: prof.sodium ?? ((prof.salt ?? 0.0) * 400.0), // 1g Salz ~ 400mg Natrium
            salt100g: prof.salt ?? ((prof.sodium ?? 0.0) / 400.0),
            potassiumMg100g: prof.potassium ?? 0.0,
            polyFat100g: prof.polyunsaturatedFat ?? 0.0,
            profile: prof,
            productName: item.name
        )

        cacheLock.lock()
        itemScoreCache[item.id] = score
        cacheLock.unlock()
        return score
    }

    // MARK: - Evaluate Recipe (MealTemplate)
    @MainActor
    public func evaluate(template: MealTemplate, store: LocalStore) -> ComprehensiveNutritionScore {
        cacheLock.lock()
        if let cached = templateScoreCache[template.id] {
            cacheLock.unlock()
            return cached
        }
        cacheLock.unlock()

        let macros = store.templateMacros(for: template)
        let profile = store.templateProfile(for: template)
        let totalGrams = template.ingredients.reduce(0.0) { acc, ing in
            if let p = store.pantryItems.first(where: { $0.id == ing.pantryItemId || $0.name.lowercased() == ing.name.lowercased() }) {
                return acc + store.effectiveGrams(for: ing, item: p)
            }
            return acc + ing.grams
        }

        let refGrams = max(100.0, totalGrams)
        let factor = 100.0 / refGrams

        let score = calculateScore(
            kcal100g: macros.kcal * factor,
            protein100g: macros.protein * factor,
            carbs100g: macros.carbs * factor,
            fat100g: macros.fat * factor,
            fiber100g: macros.fiber * factor,
            sugars100g: (profile.sugars ?? 0.0) * factor,
            satFat100g: (profile.saturatedFat ?? 0.0) * factor,
            sodiumMg100g: (profile.sodium ?? ((profile.salt ?? 0.0) * 400.0)) * factor,
            salt100g: (profile.salt ?? ((profile.sodium ?? 0.0) / 400.0)) * factor,
            potassiumMg100g: (profile.potassium ?? 0.0) * factor,
            polyFat100g: (profile.polyunsaturatedFat ?? 0.0) * factor,
            profile: profile,
            productName: template.name
        )

        cacheLock.lock()
        templateScoreCache[template.id] = score
        cacheLock.unlock()
        return score
    }

    // MARK: - Core Multi-Scoring Algorithm
    public func calculateScore(
        kcal100g: Double,
        protein100g: Double,
        carbs100g: Double,
        fat100g: Double,
        fiber100g: Double,
        sugars100g: Double,
        satFat100g: Double,
        sodiumMg100g: Double,
        salt100g: Double,
        potassiumMg100g: Double,
        polyFat100g: Double,
        profile: NutritionalProfile,
        productName: String
    ) -> ComprehensiveNutritionScore {
        let totalMacros = protein100g + carbs100g + fat100g
        let hasMacros = (kcal100g > 0 || totalMacros > 0)
        let hasFiber = fiber100g > 0 || (profile.fiber ?? 0) > 0
        let hasMicros = (profile.vitaminA != nil) || (profile.vitaminC != nil) || (profile.calcium != nil) || (profile.magnesium != nil)

        guard hasMacros || hasFiber || hasMicros else {
            return ComprehensiveNutritionScore.unscored(productName: productName)
        }

        let safeKcal = max(1.0, kcal100g)

        // 1. Ty Beal Nutritional Value Score & Potassium:Sodium Ratio
        let kNaRatio: Double = {
            if sodiumMg100g <= 5.0 {
                return potassiumMg100g > 0 ? 10.0 : 2.5
            }
            return potassiumMg100g / max(1.0, sodiumMg100g)
        }()

        // Beal Score components:
        // - Protein quality & density: up to 25 pts
        let proteinDensity = (protein100g * 4.0) / safeKcal // % calories from protein
        let proteinScore = min(25.0, proteinDensity * 60.0)

        // - Fiber density: up to 15 pts
        let fiberScore = min(15.0, (fiber100g / safeKcal) * 300.0)

        // - Essential micronutrient coverage (11 vitamins + 5 minerals): up to 35 pts
        var microCount = 0
        if (profile.vitaminA ?? 0) > 20 { microCount += 1 }
        if (profile.vitaminB1 ?? 0) > 0.05 { microCount += 1 }
        if (profile.vitaminB2 ?? 0) > 0.05 { microCount += 1 }
        if (profile.vitaminB3 ?? 0) > 0.5 { microCount += 1 }
        if (profile.vitaminB6 ?? 0) > 0.05 { microCount += 1 }
        if (profile.vitaminB11 ?? 0) > 10 { microCount += 1 }
        if (profile.vitaminB12 ?? 0) > 0.1 { microCount += 1 }
        if (profile.vitaminC ?? 0) > 3.0 { microCount += 1 }
        if (profile.vitaminD ?? 0) > 0.2 { microCount += 1 }
        if (profile.vitaminE ?? 0) > 0.5 { microCount += 1 }
        if (profile.vitaminK ?? 0) > 5.0 { microCount += 1 }
        if (profile.calcium ?? 0) > 20 { microCount += 1 }
        if (profile.iron ?? 0) > 0.4 { microCount += 1 }
        if (profile.zinc ?? 0) > 0.3 { microCount += 1 }
        if (profile.magnesium ?? 0) > 15 { microCount += 1 }
        if potassiumMg100g > 100 { microCount += 1 }
        let microScore = min(35.0, (Double(microCount) / 16.0) * 35.0)

        // - Processing Penalty / Bonus based on K:Na: up to 25 pts
        let processingScore: Double
        if kNaRatio >= 3.0 {
            processingScore = 25.0
        } else if kNaRatio >= 2.0 {
            processingScore = 20.0
        } else if kNaRatio >= 1.0 {
            processingScore = 12.0
        } else if kNaRatio >= 0.5 {
            processingScore = 5.0
        } else {
            processingScore = 0.0
        }

        let rawBeal = proteinScore + fiberScore + microScore + processingScore
        let tyBealScore = min(100.0, max(5.0, rawBeal))
        let tyBealRating: String = {
            if tyBealScore >= 80 { return "Exzellent (Gering verarbeitet, hochdicht)" }
            if tyBealScore >= 60 { return "Gut (Ausgewogene Nährstoffmatrix)" }
            if tyBealScore >= 40 { return "Moderat (Teilverarbeitet)" }
            return "Niedrig (Industriell verarbeitet / Natriumdominant)"
        }()

        // 2. Food Compass (Tufts University 1 - 100)
        let foodCompassRaw: Double = {
            var score = 50.0
            // Healthy fats vs Saturated fat
            if satFat100g > 5.0 { score -= 15.0 }
            else if satFat100g <= 1.5 { score += 8.0 }
            if polyFat100g > 1.5 { score += 7.0 }

            // Sugar penalty
            if sugars100g > 15.0 { score -= 20.0 }
            else if sugars100g > 8.0 { score -= 10.0 }
            else if sugars100g <= 3.0 { score += 5.0 }

            // Fiber bonus
            if fiber100g >= 6.0 { score += 15.0 }
            else if fiber100g >= 3.0 { score += 8.0 }

            // Sodium penalty
            if sodiumMg100g > 600 { score -= 18.0 }
            else if sodiumMg100g < 150 { score += 8.0 }

            // Micronutrient density
            score += (Double(microCount) / 16.0) * 18.0

            // High Protein bonus
            if (protein100g * 4.0 / safeKcal) >= 0.25 { score += 10.0 }

            return min(100.0, max(1.0, score))
        }()
        let foodCompassScore = Int(foodCompassRaw.rounded())
        let foodCompassCategory: String = {
            if foodCompassScore >= 70 { return "Bevorzugen" }
            if foodCompassScore >= 31 { return "In Maßen" }
            return "Minimieren"
        }()

        // 3. Nutri-Score (European Standard A to E)
        let nutriScoreGrade: String = {
            // Energy points (kJ = kcal * 4.184)
            let energyKj = safeKcal * 4.184
            var nPoints = 0
            if energyKj > 3350 { nPoints += 10 }
            else if energyKj > 3015 { nPoints += 9 }
            else if energyKj > 2680 { nPoints += 8 }
            else if energyKj > 2345 { nPoints += 7 }
            else if energyKj > 2010 { nPoints += 6 }
            else if energyKj > 1675 { nPoints += 5 }
            else if energyKj > 1340 { nPoints += 4 }
            else if energyKj > 1005 { nPoints += 3 }
            else if energyKj > 670 { nPoints += 2 }
            else if energyKj > 335 { nPoints += 1 }

            // Sugar points
            if sugars100g > 45 { nPoints += 10 }
            else if sugars100g > 40 { nPoints += 9 }
            else if sugars100g > 36 { nPoints += 8 }
            else if sugars100g > 31 { nPoints += 7 }
            else if sugars100g > 27 { nPoints += 6 }
            else if sugars100g > 22.5 { nPoints += 5 }
            else if sugars100g > 18 { nPoints += 4 }
            else if sugars100g > 13.5 { nPoints += 3 }
            else if sugars100g > 9 { nPoints += 2 }
            else if sugars100g > 4.5 { nPoints += 1 }

            // Sat fat points
            if satFat100g > 10 { nPoints += 10 }
            else if satFat100g > 9 { nPoints += 9 }
            else if satFat100g > 8 { nPoints += 8 }
            else if satFat100g > 7 { nPoints += 7 }
            else if satFat100g > 6 { nPoints += 6 }
            else if satFat100g > 5 { nPoints += 5 }
            else if satFat100g > 4 { nPoints += 4 }
            else if satFat100g > 3 { nPoints += 3 }
            else if satFat100g > 2 { nPoints += 2 }
            else if satFat100g > 1 { nPoints += 1 }

            // Sodium points
            if sodiumMg100g > 900 { nPoints += 10 }
            else if sodiumMg100g > 810 { nPoints += 9 }
            else if sodiumMg100g > 720 { nPoints += 8 }
            else if sodiumMg100g > 630 { nPoints += 7 }
            else if sodiumMg100g > 540 { nPoints += 6 }
            else if sodiumMg100g > 450 { nPoints += 5 }
            else if sodiumMg100g > 360 { nPoints += 4 }
            else if sodiumMg100g > 270 { nPoints += 3 }
            else if sodiumMg100g > 180 { nPoints += 2 }
            else if sodiumMg100g > 90 { nPoints += 1 }

            // Positive points: Fiber
            var pPoints = 0
            if fiber100g > 4.7 { pPoints += 5 }
            else if fiber100g > 3.7 { pPoints += 4 }
            else if fiber100g > 2.8 { pPoints += 3 }
            else if fiber100g > 1.9 { pPoints += 2 }
            else if fiber100g > 0.9 { pPoints += 1 }

            // Positive points: Protein
            var protPoints = 0
            if protein100g > 8.0 { protPoints = 5 }
            else if protein100g > 6.4 { protPoints = 4 }
            else if protein100g > 4.8 { protPoints = 3 }
            else if protein100g > 3.2 { protPoints = 2 }
            else if protein100g > 1.6 { protPoints = 1 }

            let totalPositive = pPoints + (nPoints >= 11 ? 0 : protPoints)
            let finalNutriScore = nPoints - totalPositive

            if finalNutriScore <= -1 { return "A" }
            if finalNutriScore <= 2 { return "B" }
            if finalNutriScore <= 10 { return "C" }
            if finalNutriScore <= 18 { return "D" }
            return "E"
        }()

        // 4. Health Star Rating (0.5 to 5.0)
        let healthStarRating: Double = {
            switch nutriScoreGrade {
            case "A": return 5.0
            case "B": return 4.0
            case "C": return 3.0
            case "D": return 2.0
            default:  return 1.0
            }
        }()

        // 5. Guiding Stars (0 to 3)
        let guidingStars: Int = {
            if tyBealScore >= 75 && sugars100g < 8.0 && satFat100g < 3.0 { return 3 }
            if tyBealScore >= 55 && sugars100g < 15.0 { return 2 }
            if tyBealScore >= 40 { return 1 }
            return 0
        }()

        // 6. Traffic Light System (UK FSA Standard)
        let trafficLightFat: TrafficLightColor = {
            if fat100g <= 3.0 { return .green }
            if fat100g <= 17.5 { return .amber }
            return .red
        }()

        let trafficLightSatFat: TrafficLightColor = {
            if satFat100g <= 1.5 { return .green }
            if satFat100g <= 5.0 { return .amber }
            return .red
        }()

        let trafficLightSugar: TrafficLightColor = {
            if sugars100g <= 5.0 { return .green }
            if sugars100g <= 22.5 { return .amber }
            return .red
        }()

        let trafficLightSalt: TrafficLightColor = {
            if salt100g <= 0.3 { return .green }
            if salt100g <= 1.5 { return .amber }
            return .red
        }()

        // 7. Glycemic Index Estimation (0 - 100)
        let (glycemicIndex, glycemicCategory): (Int, String) = {
            if carbs100g < 3.0 {
                return (15, "Sehr Niedrig (Minimalste Blutzuckerwirkung)")
            }
            // Baseline estimated GI
            var gi = 50.0
            let sugarFraction = sugars100g / max(1.0, carbs100g)
            gi += sugarFraction * 35.0 // High simple sugars spike GI

            // Fiber blunts GI
            let fiberFraction = fiber100g / max(1.0, carbs100g)
            gi -= fiberFraction * 30.0

            // Protein & Fat buffer GI
            if protein100g > 10.0 { gi -= 10.0 }
            if fat100g > 10.0 { gi -= 8.0 }

            let clampedGi = min(95, max(15, Int(gi.rounded())))
            if clampedGi <= 55 {
                return (clampedGi, "Niedrig (Stabile Glykämie & langanhaltende Sättigung)")
            } else if clampedGi <= 69 {
                return (clampedGi, "Moderat (Gleichmäßige Insulinausschüttung)")
            } else {
                return (clampedGi, "Hoch (Schneller Blutzuckeranstieg)")
            }
        }()

        // 8. BPI Protein Density Index (g Protein / 100 kcal)
        let bpiProteinIndex = (protein100g / safeKcal) * 100.0
        let bpiCategory: String = {
            if bpiProteinIndex >= 12.0 { return "Exzellente Proteinquelle (> 12 g / 100 kcal)" }
            if bpiProteinIndex >= 7.0 { return "Gute Proteinquelle (7–12 g / 100 kcal)" }
            if bpiProteinIndex >= 3.5 { return "Moderate Proteinquelle" }
            return "Geringer Proteinanteil"
        }()

        // 9. Qualitative Source Highlights & Badges
        var highlights: [String] = []

        if bpiProteinIndex >= 8.0 || protein100g >= 15.0 {
            highlights.append("Top-Proteinquelle")
        }
        if fiber100g >= 6.0 {
            highlights.append("Hoher Ballaststoffgehalt (Darm- & Viszeral-Reha)")
        } else if fiber100g >= 3.0 {
            highlights.append("Gute Ballaststoffquelle")
        }
        if polyFat100g >= 2.0 || (profile.polyunsaturatedFat ?? 0) >= 1.5 {
            highlights.append("Gesunde Fettquelle (Ungesättigte Fettsäuren)")
        }
        if kNaRatio >= 2.5 {
            highlights.append("Minimal verarbeitet (K:Na > 2.5)")
        } else if kNaRatio < 0.8 && sodiumMg100g > 400 {
            highlights.append("Hoher Natriumanteil (Industriell verarbeitet)")
        }
        if carbs100g > 15.0 && sugars100g <= 4.0 && fiber100g >= 3.0 {
            highlights.append("Komplexe Kohlenhydratquelle")
        }
        if (profile.magnesium ?? 0) >= 50.0 {
            highlights.append("Reich an Magnesium")
        }
        if (profile.potassium ?? 0) >= 300.0 {
            highlights.append("Reich an Kalium")
        }
        if (profile.iron ?? 0) >= 2.0 {
            highlights.append("Reich an Eisen")
        }
        if (profile.zinc ?? 0) >= 1.5 {
            highlights.append("Reich an Zink")
        }
        if (profile.vitaminC ?? 0) >= 20.0 {
            highlights.append("Reich an Vitamin C")
        }
        if (profile.vitaminB12 ?? 0) >= 1.0 {
            highlights.append("Reich an Vitamin B12")
        }

        // 10. NOVA Processing Level (1 to 4)
        let (novaClass, novaCategory): (Int, String) = {
            let n = productName.lowercased()
            if n.contains("cola") || n.contains("energy") || n.contains("chips") || n.contains("wurst") ||
               n.contains("salami") || n.contains("fertiggericht") || n.contains("nugget") || n.contains("softdrink") ||
               (sugars100g > 30.0 && fiber100g < 1.0) {
                return (4, "NOVA 4 (Ultra-verarbeitet)")
            }
            if n.contains("öl") || n.contains("butter") || n.contains("salz") || n.contains("honig") || n.contains("essig") || n.contains("zucker") {
                return (2, "NOVA 2 (Kulinarische Zutat)")
            }
            if n.contains("käse") || n.contains("thunfisch") || n.contains("brot") || n.contains("konserve") ||
               (salt100g > 1.2 && sodiumMg100g > 500) {
                return (3, "NOVA 3 (Verarbeitetes Lebensmittel)")
            }
            // Natural whole foods
            return (1, "NOVA 1 (Unverarbeitet / Minimal verarbeitet)")
        }()

        // 11. BWK Ulm Visceral- & Rumpf-Reha Score (0 - 100)
        // Focus: Pelvic floor relief, Bristol Type 4, 25-35g daily fiber threshold
        let bwkVisceralRehaScore: Int = {
            var bScore = 30.0
            // Fiber density (Fiber per 1000 kcal or per 100g)
            let fiberDensity1000 = (fiber100g / safeKcal) * 1000.0
            if fiberDensity1000 >= 14.0 || fiber100g >= 6.0 {
                bScore += 40.0
            } else if fiberDensity1000 >= 9.0 || fiber100g >= 3.0 {
                bScore += 25.0
            } else if fiber100g >= 1.5 {
                bScore += 10.0
            }

            // Soluble / Mucilage bonus for visceral pressure relief
            let n = productName.lowercased()
            if n.contains("hafer") || n.contains("kraut") || n.contains("apfel") || n.contains("beere") ||
               n.contains("bohne") || n.contains("linse") || n.contains("leinsamen") || n.contains("flohsamen") {
                bScore += 15.0
            }

            // Low irritation (moderate sodium, moderate saturated fat)
            if sodiumMg100g <= 300.0 && satFat100g <= 3.0 {
                bScore += 15.0
            } else if sodiumMg100g > 700.0 || satFat100g > 8.0 {
                bScore -= 15.0
            }

            return min(100, max(10, Int(bScore.rounded())))
        }()

        let bwkVisceralGrade: String = {
            if bwkVisceralRehaScore >= 80 { return "Zielerfüllung (Bristol Typ 4)" }
            if bwkVisceralRehaScore >= 55 { return "Ausreichend (Moderate Rumpfentlastung)" }
            return "Ausbaufähig (Geringe Ballaststoffdichte)"
        }()

        // 12. LPR Gastric Safety Score (0 - 100)
        // Focus: Lower esophageal sphincter protection, reflux suppression
        let (lprSafetyScore, lprSafetyCategory): (Int, String) = {
            var lpr = 80.0
            // Fat lowers lower esophageal sphincter pressure
            if fat100g > 20.0 { lpr -= 30.0 }
            else if fat100g > 10.0 { lpr -= 15.0 }
            if satFat100g > 6.0 { lpr -= 15.0 }

            let n = productName.lowercased()
            if n.contains("kaffee") || n.contains("minze") || n.contains("schokolade") || n.contains("chili") || n.contains("cola") {
                lpr -= 40.0
            }
            if n.contains("quark") || n.contains("skyr") || n.contains("hafer") || n.contains("banan") || n.contains("reis") {
                lpr += 15.0
            }

            let finalLpr = min(100, max(10, Int(lpr.rounded())))
            let cat: String
            if finalLpr >= 75 { cat = "Reflux-Sicher (Sphinkterschonend)" }
            else if finalLpr >= 50 { cat = "Moderat (Vor 18:30 Uhr)" }
            else { cat = "Sphinkter-Relaxans (Abends meiden)" }
            return (finalLpr, cat)
        }()

        // 13. NutriVault Composite Health Index Phi (0 - 100)
        // Synthesis of Food Compass, Ty Beal, BWK Ulm Reha, AMDR balance, LPR, NOVA
        let compositeHealthIndex: Int = {
            let novaPoints: Double = {
                switch novaClass {
                case 1: return 100.0
                case 2: return 80.0
                case 3: return 55.0
                default: return 20.0
                }
            }()

            let amdrScore: Double = {
                let pCal = (protein100g * 4.0 / safeKcal) * 100.0
                if pCal >= 15.0 && pCal <= 40.0 { return 95.0 }
                if pCal >= 10.0 { return 75.0 }
                return 50.0
            }()

            let weightedPhi = (Double(foodCompassScore) * 0.25) +
                              (tyBealScore * 0.20) +
                              (Double(bwkVisceralRehaScore) * 0.20) +
                              (amdrScore * 0.15) +
                              (Double(lprSafetyScore) * 0.10) +
                              (novaPoints * 0.10)

            return min(100, max(5, Int(weightedPhi.rounded())))
        }()

        let (compositeGrade, compositeVerdict): (String, String) = {
            if compositeHealthIndex >= 90 {
                return ("A+", "Exzellente Nährstoffdichte & Reha-Konvergenz")
            } else if compositeHealthIndex >= 80 {
                return ("A", "Optimales Nährstoffprofil (Klinischer Standard)")
            } else if compositeHealthIndex >= 70 {
                return ("B", "Ausgewogene Nährstoffmatrix")
            } else if compositeHealthIndex >= 50 {
                return ("C", "Moderat (Ergänzung durch Ballaststoffe empfohlen)")
            } else {
                return ("D", "Niedrige Dichte / Industriell verarbeitet")
            }
        }()

        return ComprehensiveNutritionScore(
            hasSufficientData: true,
            compositeHealthIndex: compositeHealthIndex,
            compositeGrade: compositeGrade,
            compositeVerdict: compositeVerdict,
            bwkVisceralRehaScore: bwkVisceralRehaScore,
            bwkVisceralGrade: bwkVisceralGrade,
            lprSafetyScore: lprSafetyScore,
            lprSafetyCategory: lprSafetyCategory,
            novaClass: novaClass,
            novaCategory: novaCategory,
            tyBealScore: tyBealScore,
            tyBealRating: tyBealRating,
            potassiumSodiumRatio: kNaRatio,
            foodCompassScore: foodCompassScore,
            foodCompassCategory: foodCompassCategory,
            nutriScoreGrade: nutriScoreGrade,
            healthStarRating: healthStarRating,
            guidingStars: guidingStars,
            trafficLightFat: trafficLightFat,
            trafficLightSatFat: trafficLightSatFat,
            trafficLightSugar: trafficLightSugar,
            trafficLightSalt: trafficLightSalt,
            glycemicIndex: glycemicIndex,
            glycemicCategory: glycemicCategory,
            bpiProteinIndex: bpiProteinIndex,
            bpiCategory: bpiCategory,
            sourceHighlights: highlights
        )
    }
}
