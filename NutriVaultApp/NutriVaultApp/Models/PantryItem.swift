import Foundation

public enum StorageLocation: String, Codable, CaseIterable, Identifiable {
    case fridge = "Kühlschrank"
    case freezer = "Gefrierfach"
    case spind = "Spind"
    case cupboard = "Vorratsschrank"
    case pantry = "Trockenlager"
    case roomTemp = "Zimmertemperatur"

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .fridge: return "refrigerator"
        case .freezer: return "snowflake"
        case .spind: return "lock.rectangle"
        case .cupboard: return "door.left.hand.closed"
        case .pantry: return "shippingbox"
        case .roomTemp: return "thermometer.sun"
        }
    }

    public var shortLabel: String {
        switch self {
        case .fridge: return "Kühlschrank"
        case .freezer: return "Gefrierfach"
        case .spind: return "Spind"
        case .cupboard: return "Schrank"
        case .pantry: return "Vorratslager"
        case .roomTemp: return "Zimmertemp."
        }
    }

    public static func defaultLocation(forProductName name: String) -> StorageLocation {
        let n = name.lowercased()
        if n.contains("tk-") || n.contains("gefroren") || n.contains("eis ") || n.contains("tiefkühl") {
            return .freezer
        }
        if n.contains("quark") || n.contains("skyr") || n.contains("joghurt") || n.contains("milch") || n.contains("käse") || n.contains("hähnchen") || n.contains("fleisch") || n.contains("hack") || n.contains("eier") || n.contains("ei ") || n.hasPrefix("ei ") {
            return .fridge
        }
        if n.contains("whey") || n.contains("kapsel") || n.contains("creatin") || n.contains("omega") || n.contains("magnesium") || n.contains("vitamin") || n.contains("riegel") || n.contains("snack") {
            return .spind
        }
        if n.contains("reis") || n.contains("nudel") || n.contains("dose") || n.contains("bohne") || n.contains("linsen") || n.contains("kichererbse") || n.contains("öl") || n.contains("oil") || n.contains("hafer") {
            return .cupboard
        }
        return .cupboard
    }
}

public struct PantryItem: Identifiable, Codable, Hashable {
    public var id: String
    public var name: String
    public var brand: String
    public var barcode: String
    public var defaultPackQty: Double
    public var defaultPrice: Double
    public var currentStockQty: Double
    public var unit: String
    public var kcal100g: Double
    public var protein100g: Double
    public var carbs100g: Double
    public var fat100g: Double
    public var fiber100g: Double
    public var nutriscore: String
    public var store: String
    public var profile: NutritionalProfile?
    public var subUnitCount: Int?
    public var subUnitSize: Double?
    public var subUnitName: String?
    public var storageLocation: StorageLocation
    public var storageInstructions: String
    public var storePrices: [String: Double]?

    public init(
        id: String = UUID().uuidString,
        name: String,
        brand: String,
        barcode: String,
        defaultPackQty: Double,
        defaultPrice: Double,
        currentStockQty: Double,
        unit: String = "g",
        kcal100g: Double,
        protein100g: Double,
        carbs100g: Double,
        fat100g: Double,
        fiber100g: Double = 0.0,
        nutriscore: String = "a",
        store: String = "PENNY",
        profile: NutritionalProfile? = nil,
        subUnitCount: Int? = nil,
        subUnitSize: Double? = nil,
        subUnitName: String? = nil,
        storageLocation: StorageLocation? = nil,
        storageInstructions: String = "",
        storePrices: [String: Double]? = nil
    ) {
        self.id = id
        self.name = name
        self.brand = brand
        self.barcode = barcode
        self.defaultPackQty = defaultPackQty
        self.defaultPrice = defaultPrice
        self.currentStockQty = currentStockQty
        self.unit = unit
        self.kcal100g = kcal100g
        self.protein100g = protein100g
        self.carbs100g = carbs100g
        self.fat100g = fat100g
        self.fiber100g = fiber100g
        if kcal100g == 0 && protein100g == 0 && carbs100g == 0 && fat100g == 0 && profile == nil {
            self.nutriscore = "-"
        } else {
            self.nutriscore = nutriscore
        }
        self.store = store
        self.profile = profile
        self.subUnitCount = subUnitCount
        self.subUnitSize = subUnitSize
        self.subUnitName = subUnitName
        self.storageLocation = storageLocation ?? StorageLocation.defaultLocation(forProductName: name)
        self.storageInstructions = storageInstructions
        var initialPrices = storePrices ?? [:]
        if initialPrices.isEmpty && defaultPrice > 0 && !store.isEmpty {
            initialPrices[store.uppercased()] = defaultPrice
        }
        self.storePrices = initialPrices
    }

    enum CodingKeys: String, CodingKey {
        case id, name, brand, barcode, defaultPackQty, defaultPrice, currentStockQty, unit
        case kcal100g, protein100g, carbs100g, fat100g, fiber100g, nutriscore, store, profile
        case subUnitCount, subUnitSize, subUnitName
        case storageLocation, storageInstructions
        case storePrices
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedName = try container.decodeIfPresent(String.self, forKey: .name) ?? "Unbekannt"
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        name = decodedName
        brand = try container.decodeIfPresent(String.self, forKey: .brand) ?? "Pantry"
        barcode = try container.decodeIfPresent(String.self, forKey: .barcode) ?? ""
        defaultPackQty = try container.decodeIfPresent(Double.self, forKey: .defaultPackQty) ?? 500.0
        let decPrice = try container.decodeIfPresent(Double.self, forKey: .defaultPrice) ?? 0.0
        defaultPrice = decPrice
        currentStockQty = try container.decodeIfPresent(Double.self, forKey: .currentStockQty) ?? 0.0
        unit = try container.decodeIfPresent(String.self, forKey: .unit) ?? "g"
        kcal100g = try container.decodeIfPresent(Double.self, forKey: .kcal100g) ?? 0.0
        protein100g = try container.decodeIfPresent(Double.self, forKey: .protein100g) ?? 0.0
        carbs100g = try container.decodeIfPresent(Double.self, forKey: .carbs100g) ?? 0.0
        fat100g = try container.decodeIfPresent(Double.self, forKey: .fat100g) ?? 0.0
        fiber100g = try container.decodeIfPresent(Double.self, forKey: .fiber100g) ?? 0.0
        let rawNutri = try container.decodeIfPresent(String.self, forKey: .nutriscore) ?? "-"
        let decStore = try container.decodeIfPresent(String.self, forKey: .store) ?? "PENNY"
        store = decStore
        let loadedProfile = try container.decodeIfPresent(NutritionalProfile.self, forKey: .profile)
        profile = loadedProfile

        if kcal100g == 0 && protein100g == 0 && carbs100g == 0 && fat100g == 0 && (loadedProfile == nil || (loadedProfile?.fiber ?? 0) == 0) {
            nutriscore = "-"
        } else {
            nutriscore = rawNutri
        }
        subUnitCount = try container.decodeIfPresent(Int.self, forKey: .subUnitCount)
        subUnitSize = try container.decodeIfPresent(Double.self, forKey: .subUnitSize)
        subUnitName = try container.decodeIfPresent(String.self, forKey: .subUnitName)
        if let rawLoc = try? container.decodeIfPresent(String.self, forKey: .storageLocation),
           let loc = StorageLocation(rawValue: rawLoc) {
            storageLocation = loc
        } else if let rawLoc = try? container.decodeIfPresent(String.self, forKey: .storageLocation),
                  (rawLoc.lowercased().contains("tiefkühl") || rawLoc.lowercased().contains("tiefkuehl") || rawLoc.lowercased().contains("freezer")) {
            storageLocation = .freezer
        } else {
            storageLocation = StorageLocation.defaultLocation(forProductName: decodedName)
        }
        storageInstructions = try container.decodeIfPresent(String.self, forKey: .storageInstructions) ?? ""

        var loadedPrices = try container.decodeIfPresent([String: Double].self, forKey: .storePrices) ?? [:]
        if loadedPrices.isEmpty && decPrice > 0 && !decStore.isEmpty {
            loadedPrices[decStore.uppercased()] = decPrice
        }
        storePrices = loadedPrices
    }

    /// Store-specific price resolution
    public func price(for storeName: String?) -> Double {
        guard let s = storeName?.trimmingCharacters(in: .whitespaces).uppercased(), !s.isEmpty else {
            return defaultPrice
        }
        if let sp = storePrices {
            if let exact = sp[s] { return exact }
            for (key, val) in sp {
                if key.uppercased() == s || s.contains(key.uppercased()) || key.uppercased().contains(s) {
                    return val
                }
            }
        }
        return defaultPrice
    }

    public mutating func updatePrice(_ newPrice: Double, for storeName: String) {
        guard newPrice > 0 else { return }
        let cleanStore = storeName.trimmingCharacters(in: .whitespaces).uppercased()
        if storePrices == nil {
            storePrices = [:]
        }
        if !cleanStore.isEmpty {
            storePrices?[cleanStore] = newPrice
            self.store = storeName
        }
        self.defaultPrice = newPrice
    }

    public var effectiveStorageInstructions: String {
        if !storageInstructions.trimmingCharacters(in: .whitespaces).isEmpty {
            return storageInstructions
        }
        switch storageLocation {
        case .fridge:
            return "Kühl bei 4–7 °C lagern. Nach dem Öffnen binnen 3 Tagen verbrauchen."
        case .freezer:
            return "Tiefgefroren bei -18 °C lagern. Nicht wieder einfrieren."
        case .spind:
            return "Trocken, dunkel und verschlossen im Kasernenspind aufbewahren."
        case .cupboard:
            return "Kühl, trocken und vor direkter Sonneneinstrahlung geschützt lagern."
        case .pantry:
            return "Trocken und gut belüftet im Vorratsraum aufbewahren."
        case .roomTemp:
            return "Bei Raumtemperatur trocken und verschlossen lagern."
        }
    }


    public var hasSubUnits: Bool {
        if let count = subUnitCount, count > 1, let size = subUnitSize, size > 0 {
            return true
        }
        let n = name.lowercased()
        if n.contains("scheibe") || n.contains("toast") || n.contains("schnitt") || (n.contains("ananas") && (n.contains("dose") || defaultPackQty >= 200)) {
            return true
        }
        return false
    }

    public var hasNutritionalData: Bool {
        let hasMacros = kcal100g > 0 || protein100g > 0 || carbs100g > 0 || fat100g > 0
        let hasFiber = fiber100g > 0 || (profile?.fiber ?? 0) > 0
        let hasMicros = (profile?.vitaminA != nil) || (profile?.vitaminC != nil) || (profile?.calcium != nil) || (profile?.magnesium != nil)
        return hasMacros || hasFiber || hasMicros
    }

    public var effectiveNutriScore: String {
        guard hasNutritionalData else { return "-" }
        return nutriscore.isEmpty ? "-" : nutriscore.uppercased()
    }

    public var effectiveSubUnitCount: Int {
        if let c = subUnitCount, c > 0 { return c }
        if effectiveSubUnitSize > 0 && defaultPackQty > 0 {
            return max(1, Int((defaultPackQty / effectiveSubUnitSize).rounded()))
        }
        return 1
    }

    public var effectiveSubUnitSize: Double {
        if let s = subUnitSize, s > 0 { return s }
        let n = name.lowercased()
        if n.contains("scheibenkäse") || n.contains("gouda") || n.contains("edamer") || n.contains("emmentaler") || n.contains("tilsiter") {
            return 25.0
        }
        if n.contains("toast") || n.contains("vollkorntoast") || n.contains("sandwich") {
            return 25.0
        }
        if n.contains("ananas") {
            return 40.0
        }
        if n.contains("schinken") || n.contains("wurst") || n.contains("salami") {
            return 20.0
        }
        if n.contains("brot") && n.contains("scheibe") {
            return 45.0
        }
        return (subUnitSize != nil && subUnitSize! > 0) ? subUnitSize! : defaultPackQty
    }

    public var effectiveSubUnitName: String {
        if let s = subUnitName, !s.trimmingCharacters(in: .whitespaces).isEmpty {
            return s
        }
        let n = name.lowercased()
        if n.contains("scheibe") || n.contains("toast") || n.contains("schnitt") || n.contains("ananas") {
            return "Scheiben"
        }
        if n.contains("bohne") || n.contains("mais") || n.contains("thunfisch") || n.contains("tomate") || n.contains("kichererbse") {
            return "Dosen"
        }
        if n.contains("riegel") { return "Riegel" }
        if n.contains("becher") || n.contains("joghurt") || n.contains("skyr") || n.contains("quark") { return "Becher" }
        if n.contains("kapsel") { return "Kapseln" }
        if isPieceBased { return "Stück" }
        return "Portionen"
    }

    public var subUnitsRemaining: Double {
        guard effectiveSubUnitSize > 0 else { return 0.0 }
        return currentStockQty / effectiveSubUnitSize
    }

    public var formattedStockWithSubUnits: String {
        let stockStr = "\(Int(currentStockQty)) \(unit)"
        if hasSubUnits {
            let cans = subUnitsRemaining
            let cansStr: String
            if cans.truncatingRemainder(dividingBy: 1) == 0 {
                cansStr = "\(Int(cans))"
            } else {
                cansStr = String(format: "%.1f", cans)
            }
            return "\(stockStr) (\(cansStr) \(effectiveSubUnitName))"
        }
        return stockStr
    }

    public var subUnitDescription: String? {
        guard hasSubUnits else { return nil }
        let sizeStr: String
        if effectiveSubUnitSize.truncatingRemainder(dividingBy: 1) == 0 {
            sizeStr = "\(Int(effectiveSubUnitSize))"
        } else {
            sizeStr = String(format: "%.1f", effectiveSubUnitSize)
        }
        return "\(effectiveSubUnitCount)x\(sizeStr)\(unit) \(effectiveSubUnitName)"
    }

    public var isLowStock: Bool {
        return currentStockQty <= (defaultPackQty * 0.20)
    }

    public var isDepleted: Bool {
        return currentStockQty <= 0.0
    }

    public var stockRatio: Double {
        guard defaultPackQty > 0 else { return 0.0 }
        return max(0.0, min(currentStockQty / defaultPackQty, 1.0))
    }

    public var proteinPerEuro: Double {
        let totalProtein = (defaultPackQty / 100.0) * protein100g
        guard defaultPrice > 0 else { return 0.0 }
        return totalProtein / defaultPrice
    }

    public func effectiveProfile() -> NutritionalProfile {
        let base = profile ?? NutritionalProfile(fiber: fiber100g)
        return CommodityReferenceCatalog.enrich(profile: base, forProductName: name, brand: brand)
    }

    public var isPieceBased: Bool {
        let u = unit.lowercased().trimmingCharacters(in: .whitespaces)
        if u == "stück" || u == "kapseln" || u == "kapsel" || u == "stk" || u == "tabletten" || u == "dosen" || u == "dose" || u == "packung" || u == "packungen" || u == "riegel" || u == "flasche" || u == "flaschen" {
            return true
        }
        let n = name.lowercased()
        if n.contains("eier") || (n.contains("ei") && !n.contains("fleisch") && !n.contains("reis") && !n.contains("nudel") && !n.contains("teig") && !n.contains("weiß") && !n.contains("eiweiß")) {
            return true
        }
        if n.contains("avocado") || n.contains("banan") || n.contains("riegel") || n.contains("kapsel") || n.contains("tablette") {
            return true
        }
        return false
    }

    public var isVolumeBased: Bool {
        let u = unit.lowercased().trimmingCharacters(in: .whitespaces)
        if u == "l" || u == "ml" || u == "liter" || u == "milliliter" {
            return true
        }
        let n = name.lowercased()
        if n.contains("öl") || n.contains("oil") || n.contains("milch") || n.contains("saft") || n.contains("drink") || n.contains("kefir") || n.contains("wasser") || n.contains("sauce") || n.contains("essig") {
            return true
        }
        return false
    }

    public var isLiterUnit: Bool {
        let u = unit.lowercased().trimmingCharacters(in: .whitespaces)
        return u == "l" || u == "liter"
    }

    public var isMilliliterUnit: Bool {
        let u = unit.lowercased().trimmingCharacters(in: .whitespaces)
        return u == "ml" || u == "milliliter"
    }

    public var unitWeightGrams: Double {
        if isPieceBased {
            let n = name.lowercased()
            if n.contains("eier") || n.contains("ei ") || n.hasPrefix("ei ") || n.contains("hühnerei") || n.contains("bodenhaltung") {
                return 55.0 // 1 Ei (Klasse M) ca. 55g
            }
            if n.contains("avocado") { return 150.0 }
            if n.contains("banan") { return 120.0 }
            if n.contains("wrap") || n.contains("tortilla") { return 62.0 }
            if n.contains("snickers") || n.contains("riegel") { return 50.0 }
            if n.contains("kapsel") || n.contains("tablette") { return 1.0 }
            if n.contains("salat") || n.contains("gurke") { return 250.0 }
            if defaultPackQty > 0 && defaultPackQty <= 30 {
                return 55.0
            }
            return 50.0
        }
        return 1.0
    }

    public var priceFormatted: String {
        return String(format: "%.2f €", defaultPrice)
    }

    public var unitPriceFormatted: String {
        guard defaultPackQty > 0, defaultPrice > 0 else { return "0.00 €" }
        if isPieceBased {
            let perPiece = defaultPrice / defaultPackQty
            return String(format: "%.2f €/Stk", perPiece)
        }
        if isVolumeBased || isLiterUnit || isMilliliterUnit {
            let totalMl = isLiterUnit ? defaultPackQty * 1000.0 : defaultPackQty
            let per100ml = (defaultPrice / max(1.0, totalMl)) * 100.0
            return String(format: "%.2f €/100ml", per100ml)
        }
        // Grams based
        let per100g = (defaultPrice / defaultPackQty) * 100.0
        return String(format: "%.2f €/100g", per100g)
    }

    public var pricePerUnitDescription: String {
        guard defaultPrice > 0 else { return "0.00 €" }
        return "\(priceFormatted) (\(unitPriceFormatted))"
    }

    public func priceFor(quantity: Double) -> Double {
        guard defaultPackQty > 0, defaultPrice > 0, quantity > 0 else { return 0.0 }
        return (quantity / defaultPackQty) * defaultPrice
    }

    public func matches(query: String) -> Bool {
        if query.isEmpty { return true }
        if name.localizedCaseInsensitiveContains(query) { return true }
        if brand.localizedCaseInsensitiveContains(query) { return true }
        if !barcode.isEmpty && barcode.contains(query) { return true }
        if store.localizedCaseInsensitiveContains(query) { return true }
        return false
    }
}

