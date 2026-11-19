import Foundation

// MARK: - PantryRepository (Domain Controller for Inventory & Expiry)
public final class PantryRepository {
    public static let shared = PantryRepository()

    private init() {}

    public func findItem(id: String, in items: [PantryItem]) -> PantryItem? {
        items.first(where: { $0.id == id })
    }

    public func findItem(barcode: String, in items: [PantryItem]) -> PantryItem? {
        items.first(where: { $0.barcode == barcode })
    }

    public func filterItems(_ items: [PantryItem], store: String, query: String) -> [PantryItem] {
        let cleanQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let isFilteredStore = store != "ALLE"
        let upperStore = store.uppercased()

        return items.filter { item in
            if isFilteredStore && item.store.uppercased() != upperStore {
                return false
            }
            if cleanQuery.isEmpty {
                return true
            }
            return item.matches(query: cleanQuery)
        }
    }

    public func lowStockItems(in items: [PantryItem]) -> [PantryItem] {
        items.filter { $0.currentStockQty <= 0.0 && !NonFoodClassifier.isNonFood(item: $0) }
    }

    public func totalEstimatedPantryValue(in items: [PantryItem]) -> Double {
        items.reduce(0.0) { sum, item in
            let packs = item.defaultPackQty > 0 ? (item.currentStockQty / item.defaultPackQty) : 0
            return sum + (packs * item.defaultPrice)
        }
    }
}
