import Foundation

// MARK: - ShoppingService (Domain Controller for Shopping List & Budgeting)
public final class ShoppingService {
    public static let shared = ShoppingService()

    private init() {}

    public func calculateTotalCost(for items: [ShoppingItem]) -> Double {
        items.reduce(0.0) { $0 + $1.totalCost }
    }

    public func calculateCheckedCost(for items: [ShoppingItem]) -> Double {
        items.filter { $0.isChecked }.reduce(0.0) { $0 + $1.totalCost }
    }

    public func filterShoppingList(_ items: [ShoppingItem], query: String) -> [ShoppingItem] {
        let clean = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !clean.isEmpty else { return items }

        return items.filter {
            $0.name.lowercased().contains(clean) ||
            $0.brand.lowercased().contains(clean) ||
            $0.store.lowercased().contains(clean)
        }
    }
}

