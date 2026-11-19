 import Foundation

// MARK: - ReceiptRepository (Domain Controller for Receipts & Price Intelligence)
public final class ReceiptRepository {
    public static let shared = ReceiptRepository()

    private init() {}

    public func filterReceipts(_ receipts: [ReceiptRecord], storeFilter: String, query: String, sort: ReceiptSortOption) -> [ReceiptRecord] {
        var list = receipts
        if storeFilter != "ALLE" {
            list = list.filter { $0.storeName.uppercased() == storeFilter }
        }
        let clean = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !clean.isEmpty {
            list = list.filter { receipt in
                receipt.storeName.lowercased().contains(clean) ||
                receipt.items.contains(where: {
                    $0.rawText.lowercased().contains(clean) ||
                    ($0.matchedPantryItemName?.lowercased().contains(clean) ?? false)
                })
            }
        }
        switch sort {
        case .newestFirst:
            list.sort(by: { $0.date > $1.date })
        case .oldestFirst:
            list.sort(by: { $0.date < $1.date })
        case .priceDesc:
            list.sort(by: { $0.totalAmount > $1.totalAmount })
        case .priceAsc:
            list.sort(by: { $0.totalAmount < $1.totalAmount })
        }
        return list
    }

    public func totalArchivedSpend(in receipts: [ReceiptRecord]) -> Double {
        receipts.reduce(0.0) { $0 + $1.totalAmount }
    }
}
