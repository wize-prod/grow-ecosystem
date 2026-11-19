import Foundation

public struct ReceiptLineItem: Identifiable, Codable, Hashable {
    public var id: String
    public var rawText: String
    public var parsedPrice: Double // Einzelpreis / single pack price
    public var quantity: Int // Stueckzahl / pack count
    public var quantityNote: String?
    public var matchedPantryItemId: String?
    public var matchedPantryItemName: String?
    public var previousPrice: Double?
    public var confidenceScore: Double
    public var isConfirmed: Bool
    public var isNonFood: Bool

    enum CodingKeys: String, CodingKey {
        case id, rawText, parsedPrice, quantity, quantityNote, matchedPantryItemId, matchedPantryItemName, previousPrice, confidenceScore, isConfirmed, isNonFood
    }

    public init(
        id: String = UUID().uuidString,
        rawText: String,
        parsedPrice: Double,
        quantity: Int = 1,
        quantityNote: String? = nil,
        matchedPantryItemId: String? = nil,
        matchedPantryItemName: String? = nil,
        previousPrice: Double? = nil,
        confidenceScore: Double = 0.0,
        isConfirmed: Bool = true,
        isNonFood: Bool = false
    ) {
        self.id = id
        self.rawText = rawText
        self.parsedPrice = parsedPrice
        self.quantity = max(1, quantity)
        self.quantityNote = quantityNote
        self.matchedPantryItemId = matchedPantryItemId
        self.matchedPantryItemName = matchedPantryItemName
        self.previousPrice = previousPrice
        self.confidenceScore = confidenceScore
        self.isConfirmed = isConfirmed
        self.isNonFood = isNonFood
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        rawText = try container.decode(String.self, forKey: .rawText)
        parsedPrice = try container.decode(Double.self, forKey: .parsedPrice)
        quantity = try container.decodeIfPresent(Int.self, forKey: .quantity) ?? 1
        quantityNote = try container.decodeIfPresent(String.self, forKey: .quantityNote)
        matchedPantryItemId = try container.decodeIfPresent(String.self, forKey: .matchedPantryItemId)
        matchedPantryItemName = try container.decodeIfPresent(String.self, forKey: .matchedPantryItemName)
        previousPrice = try container.decodeIfPresent(Double.self, forKey: .previousPrice)
        confidenceScore = try container.decodeIfPresent(Double.self, forKey: .confidenceScore) ?? 0.0
        isConfirmed = try container.decodeIfPresent(Bool.self, forKey: .isConfirmed) ?? true
        isNonFood = try container.decodeIfPresent(Bool.self, forKey: .isNonFood) ?? false
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(rawText, forKey: .rawText)
        try container.encode(parsedPrice, forKey: .parsedPrice)
        try container.encode(quantity, forKey: .quantity)
        try container.encodeIfPresent(quantityNote, forKey: .quantityNote)
        try container.encodeIfPresent(matchedPantryItemId, forKey: .matchedPantryItemId)
        try container.encodeIfPresent(matchedPantryItemName, forKey: .matchedPantryItemName)
        try container.encodeIfPresent(previousPrice, forKey: .previousPrice)
        try container.encode(confidenceScore, forKey: .confidenceScore)
        try container.encode(isConfirmed, forKey: .isConfirmed)
        try container.encode(isNonFood, forKey: .isNonFood)
    }

    public var singlePackPrice: Double {
        return parsedPrice
    }

    public var lineTotalPrice: Double {
        return Double(max(1, quantity)) * parsedPrice
    }

    public var hasPriceDifference: Bool {
        guard let prev = previousPrice, prev > 0 else { return false }
        return abs(prev - parsedPrice) >= 0.01
    }

    public var priceDifference: Double {
        guard let prev = previousPrice else { return 0.0 }
        return parsedPrice - prev
    }
}

public struct ReceiptRecord: Identifiable, Codable, Hashable {
    public var id: String
    public var date: Date
    public var storeName: String
    public var totalAmount: Double
    public var imageFilename: String?
    public var items: [ReceiptLineItem]
    public var notes: String

    public init(
        id: String = UUID().uuidString,
        date: Date = Date(),
        storeName: String = "PENNY",
        totalAmount: Double = 0.0,
        imageFilename: String? = nil,
        items: [ReceiptLineItem] = [],
        notes: String = ""
    ) {
        self.id = id
        self.date = date
        self.storeName = storeName
        self.totalAmount = totalAmount
        self.imageFilename = imageFilename
        self.items = items
        self.notes = notes
    }

    public var priceChangeCount: Int {
        return items.filter { $0.hasPriceDifference }.count
    }

    public var foodTotal: Double {
        return items.filter { !$0.isNonFood }.reduce(0.0) { $0 + $1.lineTotalPrice }
    }

    public var nonFoodTotal: Double {
        return items.filter { $0.isNonFood }.reduce(0.0) { $0 + $1.lineTotalPrice }
    }

    public var foodItemsCount: Int {
        return items.filter { !$0.isNonFood }.count
    }

    public var nonFoodItemsCount: Int {
        return items.filter { $0.isNonFood }.count
    }
}

public enum ReceiptSortOption: String, CaseIterable, Codable {
    case newestFirst = "Neueste zuerst"
    case oldestFirst = "Älteste zuerst"
    case priceDesc = "Betrag (höchste zuerst)"
    case priceAsc = "Betrag (niedrigste zuerst)"
}
