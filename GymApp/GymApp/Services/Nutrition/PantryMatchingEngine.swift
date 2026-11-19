import Foundation

public struct RecipeMatchResult: Identifiable, Hashable {
    public var id: String { template.id }
    public let template: MealTemplate
    public let matchScore: Double                 // 0.0 to 1.0 (portion of non-trivial ingredients present in stock)
    public let matchedIngredients: [TemplateIngredient]
    public let missingIngredients: [TemplateIngredient]
    public let isFullyInStock: Bool
    public let canCookNow: Bool                  // matchScore >= 0.75 or missingIngredients.isEmpty
    public let missingCount: Int

    public var matchPercentageInt: Int {
        Int((matchScore * 100.0).rounded())
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(template.id)
        hasher.combine(matchScore)
    }

    public static func == (lhs: RecipeMatchResult, rhs: RecipeMatchResult) -> Bool {
        lhs.template.id == rhs.template.id && lhs.matchScore == rhs.matchScore
    }
}

public enum PantryMatchFilter: String, CaseIterable, Identifiable {
    case all = "ALLE"
    case canCook = "SOFORT KOCHBAR"
    case almostComplete = "FAST KOMPLETT"
    case missingMore = "FEHLENDE ZUTATEN"
    case missingInDb = "FEHLT IN DATENBANK"

    public var id: String { rawValue }
}

public final class PantryMatchingEngine {
    public static let shared = PantryMatchingEngine()

    private init() {}

    private let trivialTokens: Set<String> = [
        "salz", "pfeffer", "jodsalz", "meersalz", "wasser", "backpapier"
    ]

    private let stopWords: Set<String> = [
        "penny", "naturgut", "bio", "frisch", "frische", "delikatess",
        "spitzenqualitaet", "prinzessin", "spreewald", "eigenem", "saft",
        "aufguss", "200g", "zart", "magerstufe", "butcher", "fabio", "moments",
        "gut", "günstig", "marktliebe"
    ]

    private let synonymGroups: [[String]] = [
        ["quark", "speisequark", "magerquark", "skyr"],
        ["haferflocken", "hafer", "granola", "oats"],
        ["thunfisch", "thunfischfilet", "berida"],
        ["linsen", "rollini"],
        ["sauerkraut", "weinkraut"],
        ["matjes", "matjesfilet", "matjesfilets", "hering"],
        ["honig", "blütenhonig"],
        ["erdnussbutter", "erdnussmus", "erdnuss"],
        ["kidney", "kidneybohnen", "bohnen"],
        ["schwarze", "bohnen"],
        ["käse", "scheibenkäse", "gouda", "ziegenkäse", "kaese"],
        ["eier", "ei", "frischeier", "bodenhaltung"],
        ["kartoffeln", "frühkartoffeln"],
        ["hähnchen", "hähnchenbrust", "huhn"],
        ["reis", "basmati"]
    ]

    private var lastPantryItemsHash: Int = 0
    private var cachedInStockTokens: Set<String> = []
    private var cachedInStockIds: Set<String> = []
    private let cacheLock = NSLock()

    public func inStockData(for pantryItems: [PantryItem]) -> (tokens: Set<String>, ids: Set<String>) {
        cacheLock.lock()
        defer { cacheLock.unlock() }

        var hasher = Hasher()
        for item in pantryItems where item.currentStockQty > 0 {
            hasher.combine(item.id)
            hasher.combine(item.currentStockQty)
        }
        let currentHash = hasher.finalize()

        if currentHash == lastPantryItemsHash && !cachedInStockTokens.isEmpty {
            return (cachedInStockTokens, cachedInStockIds)
        }

        let inStock = pantryItems.filter { $0.currentStockQty > 0 }
        var tokens = Set<String>()
        var ids = Set<String>()

        for item in inStock {
            ids.insert(item.id)
            tokens.formUnion(tokenize(item.name))
        }

        lastPantryItemsHash = currentHash
        cachedInStockTokens = tokens
        cachedInStockIds = ids
        return (tokens, ids)
    }

    private func tokenize(_ string: String) -> Set<String> {
        let lower = string.lowercased()
        let words = lower.components(separatedBy: CharacterSet.alphanumerics.inverted)
        var result = Set<String>()
        for w in words {
            let clean = w.trimmingCharacters(in: .whitespacesAndNewlines)
            if clean.count >= 3 && !stopWords.contains(clean) {
                result.insert(clean)
                for (gIdx, group) in synonymGroups.enumerated() {
                    if group.contains(where: { clean.contains($0) || $0.contains(clean) }) {
                        result.insert("syn_\(gIdx)")
                    }
                }
            }
        }
        return result
    }

    public func match(template: MealTemplate, pantryItems: [PantryItem]) -> RecipeMatchResult {
        let (inStockTokens, inStockIds) = inStockData(for: pantryItems)
        return match(template: template, inStockTokens: inStockTokens, inStockIds: inStockIds)
    }

    public func match(template: MealTemplate, inStockTokens: Set<String>, inStockIds: Set<String>) -> RecipeMatchResult {
        var matchedIngs: [TemplateIngredient] = []
        var missingIngs: [TemplateIngredient] = []

        for ing in template.ingredients {
            let iLower = ing.name.lowercased()
            if trivialTokens.contains(where: { iLower.contains($0) }) {
                matchedIngs.append(ing)
                continue
            }

            if inStockIds.contains(ing.pantryItemId) {
                matchedIngs.append(ing)
                continue
            }

            let iToks = tokenize(ing.name)
            if !iToks.isDisjoint(with: inStockTokens) {
                matchedIngs.append(ing)
            } else {
                missingIngs.append(ing)
            }
        }

        let total = max(1, template.ingredients.count)
        let score = Double(matchedIngs.count) / Double(total)
        let isFull = missingIngs.isEmpty
        let canCook = isFull || (score >= 0.75) || (total <= 3 && missingIngs.count <= 1)

        return RecipeMatchResult(
            template: template,
            matchScore: score,
            matchedIngredients: matchedIngs,
            missingIngredients: missingIngs,
            isFullyInStock: isFull,
            canCookNow: canCook,
            missingCount: missingIngs.count
        )
    }

    public func rank(templates: [MealTemplate], pantryItems: [PantryItem]) -> [RecipeMatchResult] {
        let (inStockTokens, inStockIds) = inStockData(for: pantryItems)

        var results: [RecipeMatchResult] = []
        results.reserveCapacity(templates.count)

        for template in templates {
            results.append(match(template: template, inStockTokens: inStockTokens, inStockIds: inStockIds))
        }

        return results.sorted { a, b in
            if a.isFullyInStock != b.isFullyInStock {
                return a.isFullyInStock && !b.isFullyInStock
            }
            if a.matchScore != b.matchScore {
                return a.matchScore > b.matchScore
            }
            return a.missingCount < b.missingCount
        }
    }
}
