import Foundation

public struct ShoppingItem: Identifiable, Codable, Hashable {
    public var id: String
    public var pantryItemId: String
    public var name: String
    public var brand: String
    public var barcode: String
    public var packQty: Double
    public var price: Double
    public var store: String
    public var quantity: Int
    public var isChecked: Bool
    public var unit: String
    public var category: String
    public var webUrl: String?

    public init(
        id: String = UUID().uuidString,
        item: PantryItem,
        quantity: Int = 1,
        isChecked: Bool = false,
        category: String = "Lebensmittel",
        webUrl: String? = nil
    ) {
        self.id = id
        self.pantryItemId = item.id
        self.name = item.name
        self.brand = item.brand
        self.barcode = item.barcode
        self.packQty = item.defaultPackQty
        self.price = item.defaultPrice
        self.store = item.store
        self.unit = item.unit
        self.quantity = quantity
        self.isChecked = isChecked
        self.category = category
        self.webUrl = webUrl
    }

    public init(
        id: String = UUID().uuidString,
        pantryItemId: String = "",
        name: String,
        brand: String = "",
        barcode: String = "",
        packQty: Double = 1.0,
        price: Double = 0.0,
        store: String = "AMAZON",
        quantity: Int = 1,
        isChecked: Bool = false,
        unit: String = "Stk",
        category: String = "Pflege & Hygiene",
        webUrl: String? = nil
    ) {
        self.id = id
        self.pantryItemId = pantryItemId
        self.name = name
        self.brand = brand
        self.barcode = barcode
        self.packQty = packQty
        self.price = price
        self.store = store
        self.quantity = quantity
        self.isChecked = isChecked
        self.unit = unit
        self.category = category
        self.webUrl = webUrl
    }

    public var isRecurring: Bool = false
    public var recurrenceRule: CustomRecurrenceRule? = nil
    public var isSaved: Bool = false

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.pantryItemId = try container.decodeIfPresent(String.self, forKey: .pantryItemId) ?? ""
        self.name = try container.decode(String.self, forKey: .name)
        self.brand = try container.decodeIfPresent(String.self, forKey: .brand) ?? ""
        self.barcode = try container.decodeIfPresent(String.self, forKey: .barcode) ?? ""
        self.packQty = try container.decodeIfPresent(Double.self, forKey: .packQty) ?? 1.0
        self.price = try container.decodeIfPresent(Double.self, forKey: .price) ?? 0.0
        self.store = try container.decodeIfPresent(String.self, forKey: .store) ?? "PENNY"
        self.quantity = try container.decodeIfPresent(Int.self, forKey: .quantity) ?? 1
        self.isChecked = try container.decodeIfPresent(Bool.self, forKey: .isChecked) ?? false
        self.unit = try container.decodeIfPresent(String.self, forKey: .unit) ?? "g"
        self.category = try container.decodeIfPresent(String.self, forKey: .category) ?? "Lebensmittel"
        self.webUrl = try container.decodeIfPresent(String.self, forKey: .webUrl)
        self.isRecurring = try container.decodeIfPresent(Bool.self, forKey: .isRecurring) ?? false
        self.recurrenceRule = try container.decodeIfPresent(CustomRecurrenceRule.self, forKey: .recurrenceRule)
        self.isSaved = try container.decodeIfPresent(Bool.self, forKey: .isSaved) ?? false
    }

    public var totalCost: Double {
        return Double(quantity) * price
    }

    public var unitsToBuyFormatted: String {
        if packQty > 1.0 {
            let qtyDisplay = packQty.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(packQty))" : String(format: "%.1f", packQty)
            return "\(quantity)x \(qtyDisplay) \(unit)"
        } else if !unit.isEmpty && unit.lowercased() != "stk" && unit.lowercased() != "stueck" {
            return "\(quantity) \(unit)"
        } else {
            return "\(quantity) Stk"
        }
    }

    public var inStoreLocation: InStoreLocation {
        let storeUpper = store.uppercased()
        if storeUpper.contains("AMAZON") || storeUpper.contains("ONLINE") {
            return .online
        }
        let lower = (name + " " + category + " " + brand).lowercased()

        // Supplements & Performance (Whey, Creatin, Elektrolyte, Vitamine)
        if lower.contains("whey") || lower.contains("creatin") || lower.contains("kreatin") ||
           lower.contains("isoclear") || lower.contains("magnesium") || lower.contains("omega") ||
           lower.contains("rhodiola") || lower.contains("zink") || lower.contains("vitamin") ||
           lower.contains("eaa") || lower.contains("bcaa") || lower.contains("citrullin") ||
           lower.contains("booster") || lower.contains("elektrolyt") || lower.contains("protein pulver") {
            return .supplements
        }

        // Training & Gym Gear (Zughilfen, Bänder, Gürtel, Chalk, Shaker)
        if lower.contains("zughilfe") || lower.contains("gürtel") || lower.contains("chalk") ||
           lower.contains("widerstandsband") || lower.contains("fitnessband") || lower.contains("bänder") ||
           lower.contains("foam roller") || lower.contains("shaker") || lower.contains("knieschoner") ||
           lower.contains("springseil") || lower.contains("trinkflasche") {
            return .trainingEquipment
        }

        // Drogerie & Körperpflege
        if lower.contains("pflege") || lower.contains("hygiene") || lower.contains("creme") ||
           lower.contains("bha") || lower.contains("shampoo") || lower.contains("seife") ||
           lower.contains("zahnpasta") || lower.contains("deo") || lower.contains("rasur") ||
           lower.contains("trimmer") || lower.contains("lotion") || lower.contains("cleanser") ||
           storeUpper == "DM" || storeUpper == "ROSSMANN" {
            return .drugstore
        }

        // Tiefkühl
        if lower.contains("tiefkühl") || lower.contains("tk-") || lower.contains("tk ") ||
           lower.contains("gefroren") || lower.contains("frozen") || lower.contains("eis ") ||
           lower.contains("beeren tk") || lower.contains("lachs tk") {
            return .frozen
        }

        // Kühlregal & Milchprodukte
        if lower.contains("milch") || lower.contains("quark") || lower.contains("joghurt") ||
           lower.contains("käse") || lower.contains("cheese") || lower.contains("skyr") ||
           lower.contains("butter") || lower.contains("sahne") || lower.contains("eier") ||
           lower.contains("kühlregal") || lower.contains("frischkäse") || lower.contains("tofu") {
            return .dairy
        }

        // Fleisch & Fisch
        if lower.contains("hähnchen") || lower.contains("rind") || lower.contains("pute") ||
           lower.contains("fleisch") || lower.contains("hack") || lower.contains("lachs") ||
           lower.contains("thunfisch") || lower.contains("wurst") || lower.contains("schinken") {
            return .meatFish
        }

        // Obst & Gemüse
        if lower.contains("gemüse") || lower.contains("obst") || lower.contains("apfel") ||
           lower.contains("banane") || lower.contains("beeren") || lower.contains("kartoffel") ||
           lower.contains("tomate") || lower.contains("gurke") || lower.contains("spinat") ||
           lower.contains("salat") || lower.contains("zwiebel") || lower.contains("knoblauch") ||
           lower.contains("paprika") || lower.contains("avocado") || lower.contains("brokkoli") ||
           lower.contains("möhre") || lower.contains("karotte") || lower.contains("zitrone") {
            return .produce
        }

        // Backwaren
        if lower.contains("brot") || lower.contains("brötchen") || lower.contains("toast") ||
           lower.contains("bagel") || lower.contains("croissant") || lower.contains("vollkornbrot") ||
           lower.contains("wrap") || lower.contains("tortilla") {
            return .bakery
        }

        // Getränke
        if lower.contains("wasser") || lower.contains("saft") || lower.contains("tea") ||
           lower.contains("tee") || lower.contains("kaffee") || lower.contains("coffee") ||
           lower.contains("drink") || lower.contains("getränk") {
            return .beverages
        }

        // Vorrat & Teigwaren
        if lower.contains("reis") || lower.contains("nudel") || lower.contains("pasta") ||
           lower.contains("haferflocken") || lower.contains("mehl") || lower.contains("öl") ||
           lower.contains("olivenöl") || lower.contains("dose") || lower.contains("konserve") ||
           lower.contains("sauce") || lower.contains("passata") || lower.contains("gewürz") ||
           lower.contains("salz") || lower.contains("pfeffer") || lower.contains("whey") ||
           lower.contains("protein pulver") || lower.contains("vorrat") {
            return .pantry
        }

        return .other
    }
}

// MARK: - In-Store Location Enum
public enum InStoreLocation: String, CaseIterable, Comparable {
    case supplements = "Supplements & Performance"
    case trainingEquipment = "Training & Gym Gear"
    case produce = "Obst & Gemüse"
    case bakery = "Backwaren"
    case dairy = "Kühlregal & Milchprodukte"
    case meatFish = "Fleisch & Fisch"
    case pantry = "Vorrat & Teigwaren"
    case frozen = "Tiefkühl"
    case beverages = "Getränke"
    case drugstore = "Drogerie & Körperpflege"
    case online = "Online-Bestellung"
    case other = "Sonstiges"

    public var sortOrder: Int {
        switch self {
        case .supplements: return 0
        case .trainingEquipment: return 1
        case .produce: return 2
        case .bakery: return 3
        case .dairy: return 4
        case .meatFish: return 5
        case .pantry: return 6
        case .frozen: return 7
        case .beverages: return 8
        case .drugstore: return 9
        case .online: return 10
        case .other: return 11
        }
    }

    public static func < (lhs: InStoreLocation, rhs: InStoreLocation) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }
}
