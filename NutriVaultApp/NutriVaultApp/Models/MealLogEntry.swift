import Foundation

public struct MealLogEntry: Identifiable, Codable, Hashable {
    public var id: String
    public var timestamp: Date
    public var pantryItemId: String
    public var foodName: String
    public var brand: String
    public var weightGrams: Double
    public var kcal: Double
    public var protein: Double
    public var carbs: Double
    public var fat: Double
    public var fiber: Double
    public var cost: Double
    public var mealType: String
    public var recipeId: String?
    public var recipeName: String?
    public var recipeBatchId: String?

    public init(
        id: String = UUID().uuidString,
        timestamp: Date = Date(),
        item: PantryItem,
        weightGrams: Double,
        mealType: String = "Mahlzeit",
        recipeId: String? = nil,
        recipeName: String? = nil,
        recipeBatchId: String? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.pantryItemId = item.id
        self.foodName = item.name
        self.brand = item.brand
        self.weightGrams = weightGrams
        self.mealType = mealType
        self.recipeId = recipeId
        self.recipeName = recipeName
        self.recipeBatchId = recipeBatchId

        let factor = weightGrams / 100.0
        self.kcal = (item.kcal100g * factor).rounded()
        self.protein = ((item.protein100g * factor) * 10).rounded() / 10
        self.carbs = ((item.carbs100g * factor) * 10).rounded() / 10
        self.fat = ((item.fat100g * factor) * 10).rounded() / 10
        self.fiber = ((item.fiber100g * factor) * 10).rounded() / 10

        // Proportional cost calculation based on unit semantics
        if item.defaultPrice > 0, item.defaultPackQty > 0 {
            if item.isPieceBased {
                let unitWeight = max(1.0, item.unitWeightGrams)
                let piecesLogged = weightGrams / unitWeight
                let costPerPiece = item.defaultPrice / item.defaultPackQty
                self.cost = max(0.01, ((piecesLogged * costPerPiece) * 100).rounded() / 100)
            } else if item.isLiterUnit {
                let packVolumeMl = item.defaultPackQty * 1000.0
                let costPerMl = item.defaultPrice / packVolumeMl
                self.cost = max(0.01, ((weightGrams * costPerMl) * 100).rounded() / 100)
            } else {
                let costPerUnit = item.defaultPrice / item.defaultPackQty
                self.cost = max(0.01, ((weightGrams * costPerUnit) * 100).rounded() / 100)
            }
        } else {
            self.cost = 0.0
        }
    }

    // MARK: - LPR (Laryngopharyngealer Reflux) Sicherheits-Klassifikation
    public var isLateLPRWarning: Bool {
        let cal = Calendar.current
        let hour = cal.component(.hour, from: timestamp)
        let minute = cal.component(.minute, from: timestamp)
        return hour > 19 || (hour == 19 && minute >= 30)
    }

    public var isLPRSphincterRisk: Bool {
        lprRiskReason != nil
    }

    public var lprRiskReason: String? {
        let text = (foodName + " " + brand).lowercased()
        if text.contains("tomate") || text.contains("tomato") || text.contains("passata") || text.contains("bolognese") {
            return "Tomatenbasis (Saeure & Pepsin-Trigger)"
        }
        if text.contains("knoblauch") || text.contains("garlic") || text.contains("zwiebel") || text.contains("onion") {
            return "Knoblauch / Zwiebel (LES-Relaxans)"
        }
        if text.contains("minze") || text.contains("mint") || text.contains("pfefferminz") {
            return "Minze (Starke Sphinkter-Relaxation)"
        }
        if text.contains("schokolade") || text.contains("chocolate") || text.contains("kakao") {
            return "Schokolade (Methylxanthine)"
        }
        if text.contains("kaffee") || text.contains("coffee") || text.contains("espresso") {
            return "Kaffee / Koffein"
        }
        if fat >= 22.0 {
            return "Hoher Fettgehalt (> 20g verzoegert Magenentleerung)"
        }
        return nil
    }
}
