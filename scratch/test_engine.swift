import Foundation

// Let's test with mock pantry items
struct PantryItem {
    var id: String
    var name: String
    var protein100g: Double
    var carbs100g: Double
    var fat100g: Double
    var fiber100g: Double
    var kcal100g: Double
    var currentStockQty: Double
}

let items: [PantryItem] = [
    PantryItem(id: "1", name: "Schwarze Bohnen", protein100g: 21.0, carbs100g: 62.0, fat100g: 1.4, fiber100g: 15.0, kcal100g: 340.0, currentStockQty: 500.0),
    PantryItem(id: "2", name: "Blütenhonig", protein100g: 0.3, carbs100g: 82.0, fat100g: 0.0, fiber100g: 0.0, kcal100g: 304.0, currentStockQty: 500.0),
    PantryItem(id: "3", name: "Delikatess Sauerkraut Von Spreewald Prinzessin", protein100g: 1.1, carbs100g: 0.7, fat100g: 0.2, fiber100g: 2.1, kcal100g: 17.0, currentStockQty: 500.0),
    PantryItem(id: "4", name: "Deutsche Markenbutter mildgesäuert", protein100g: 0.7, carbs100g: 0.7, fat100g: 82.0, fiber100g: 0.0, kcal100g: 743.0, currentStockQty: 250.0),
    PantryItem(id: "5", name: "Zarte Haferflocken", protein100g: 13.5, carbs100g: 58.7, fat100g: 7.0, fiber100g: 10.0, kcal100g: 370.0, currentStockQty: 0.0),
    PantryItem(id: "6", name: "Magerquark", protein100g: 12.0, carbs100g: 4.0, fat100g: 0.2, fiber100g: 0.0, kcal100g: 68.0, currentStockQty: 0.0),
    PantryItem(id: "7", name: "Thunfisch", protein100g: 25.0, carbs100g: 0.0, fat100g: 1.0, fiber100g: 0.0, kcal100g: 110.0, currentStockQty: 0.0),
    PantryItem(id: "8", name: "Hähnchenbrust", protein100g: 23.0, carbs100g: 0.0, fat100g: 1.5, fiber100g: 0.0, kcal100g: 105.0, currentStockQty: 0.0)
]

let foodOnlyItems = items
let inStock = foodOnlyItems.filter { $0.currentStockQty > 0 }
print("inStock count:", inStock.count)
let hasDiverseStock = inStock.count >= 8 &&
    inStock.contains(where: { $0.protein100g >= 10.0 }) &&
    inStock.contains(where: { $0.carbs100g >= 15.0 })
print("hasDiverseStock:", hasDiverseStock)
let pool = hasDiverseStock ? inStock : foodOnlyItems
print("pool count:", pool.count)

let proteins = pool.filter { item in
    item.protein100g >= 7.0 || n_contains(item.name, ["quark", "skyr", "thunf", "linsen", "huhn", "hähnchen", "fleisch", "fisch", "ei", "whey", "protein", "tofu", "bohn", "kichererbse"])
}

func n_contains(_ s: String, _ arr: [String]) -> Bool {
    let lower = s.lowercased()
    return arr.contains { lower.contains($0) }
}

print("Proteins found:", proteins.map { $0.name })
