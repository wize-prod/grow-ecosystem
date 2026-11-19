import Foundation

public struct MatchResult {
    public let item: PantryItem?
    public let confidence: Double
    public let alternatives: [PantryItem]
}

public final class ReceiptMatchingEngine {
    public static let shared = ReceiptMatchingEngine()

    private let userDefaultsKey = "receipt_learned_aliases"
    private var aliasMap: [String: String] = [:] // Normalized Raw Line -> Pantry Item ID

    // MARK: - Generic Noise & Store-Brand Stop Words
    private let stopWords: Set<String> = [
        "BIO", "NATUR", "FRISCH", "PREMIUM", "FEIN", "MINI", "XXL", "XL",
        "STK", "STUECK", "PACK", "PACKUNG", "TAFEL", "DOSE", "GLAS", "BEUTEL",
        "ORIGINAL", "KLASSIK", "CLASSIC", "LIGHT", "PRO", "MAX", "GUT", "GUENSTIG",
        "LEICHT", "GERIEBEN", "JUNG", "HALB", "1/2", "SPITZENQUALITAET", "DELIKATESS",
        // Multi-Store Chain Private Labels (Strip so they don't block matching)
        "JA", "REWE", "PENNY", "ALDI", "LIDL", "EDEKA", "KAUFLAND", "HOFER", "SPAR",
        "SBUDGET", "BUDGET", "CLEVER", "MILBONA", "CROWNFIELD", "ALESTO", "CHEFSELECT",
        "MILSANI", "CUCINA", "NATURGUT", "SANFABIO", "BERIDA", "LANDFREUND", "MARKTLIEBE",
        "BESTMOMENTS", "MOMENTS", "FRESHONA", "KCLASSIC", "SOLEVITA", "COMBINO"
    ]

    // MARK: - Multi-Store Comprehensive Synonym & Abbreviation Matrix
    private let abbreviationMap: [String: [String]] = [
        // 1. Dairy, Curd, Cheese & Plant-Based (Penny, Aldi, Lidl, Rewe, Spar, Hofer)
        "MAGERQ": ["MAGERQUARK", "SPEISEQUARK", "QUARK"],
        "MAGERQ.": ["MAGERQUARK", "SPEISEQUARK", "QUARK"],
        "SPEISEQ": ["SPEISEQUARK", "MAGERQUARK", "QUARK"],
        "SPEISEQ.": ["SPEISEQUARK", "MAGERQUARK", "QUARK"],
        "QUARK": ["SPEISEQUARK", "MAGERQUARK"],
        "TOPFEN": ["SPEISEQUARK", "MAGERQUARK", "QUARK", "MAGERTOPFEN"],
        "MAGERTOPFEN": ["SPEISEQUARK", "MAGERQUARK", "QUARK"],
        "SKYR": ["SKYR", "QUARK", "SPEISEQUARK"],
        "HMILCH": ["MILCH", "HALTBAR", "VOLLMILCH"],
        "H-MILCH": ["MILCH", "HALTBAR", "VOLLMILCH"],
        "FRISCHMILCH": ["MILCH", "VOLLMILCH"],
        "VOLLMILCH": ["MILCH"],
        "GOUDA": ["GOUDA", "KAESE", "GERIEBEN"],
        "REIBEKAESE": ["GOUDA", "KAESE", "GERIEBEN"],
        "KAESEAUFSC": ["KAESEAUFSCHNITT", "KAESE", "GOUDA", "TILSITER"],
        "MOZZARELLA": ["MOZZARELLA", "MINI"],
        "FETA": ["FETA", "HIRTENKAESE", "SCHAFSKAESE"],
        "HIRTENKAESE": ["FETA", "HIRTENKAESE"],
        "ZIEGENK": ["ZIEGENKAESE", "ZIEGENKAESEROLLE"],
        "ZIEGENKAESE": ["ZIEGENKAESE", "ZIEGENKAESEROLLE"],

        // 2. Eggs (Bodenhaltung, Freiland, Bio)
        "EIER": ["EI", "FRISCHEIER", "BH", "BODENHALTUNG", "FREILAND"],
        "FRISCHEIER": ["EIER", "EI"],
        "BODENHALT": ["EIER", "EI", "BODENHALTUNG", "BH"],
        "BODENHALT.": ["EIER", "EI", "BODENHALTUNG", "BH"],
        "FREILAND": ["EIER", "EI"],

        // 3. Poultry, Meat, Fish & Seafood
        "HÄ-BRUST": ["HAEHNCHENBRUSTFILET", "HAEHNCHENBRUST", "HAEHNCHEN", "BRUSTFILET", "HUHN"],
        "HAE-BRUST": ["HAEHNCHENBRUSTFILET", "HAEHNCHENBRUST", "HAEHNCHEN", "BRUSTFILET", "HUHN"],
        "HA-BRUST": ["HAEHNCHENBRUSTFILET", "HAEHNCHENBRUST", "HAEHNCHEN", "BRUSTFILET", "HUHN"],
        "HAEHNCHEN": ["HAEHNCHENBRUST", "FILET", "HUHN", "BRUSTFILET"],
        "HAEHNCHENBRUST": ["HAEHNCHENBRUSTFILET", "HAEHNCHEN", "HUHN"],
        "PUTEN": ["PUTENBRUST", "PUTE", "PUTENFILET"],
        "PUTENBRUST": ["PUTENBRUST", "PUTE", "PUTENFILET"],
        "SCHINKEN": ["SCHINKENWUERFEL", "SCHINKEN"],
        "SCHINKENW": ["SCHINKENWUERFEL", "SCHINKEN"],
        "SCHINKENWUERFEL": ["SCHINKENWUERFEL", "SCHINKEN"],
        "THUNF": ["THUNFISCH", "FILET", "THUNFISCHFILET"],
        "THUNF.": ["THUNFISCH", "FILET", "THUNFISCHFILET"],
        "THUN": ["THUNFISCH", "FILET"],
        "BERIDA": ["THUNFISCH", "BERIDA"],
        "MATJES": ["MATJES", "MATJESFILET", "HERING"],
        "MATJESFILET": ["MATJES", "MATJESFILETS", "HERINGSFILETS"],
        "SALZHERING": ["HERING", "MATJES"],
        "LACHS": ["LACHS", "LACHSFILET"],

        // 4. Legumes, Carbs, Grains & Pasta
        "LINSEN": ["TELLERLINSEN", "BERGLINSEN", "ROTE LINSEN", "LINSEN"],
        "ROTE LINSEN": ["ROTE LINSEN", "LINSEN"],
        "KICHERERBSEN": ["KICHERERBSEN", "KICHERERBSENWAF"],
        "KICHERERBS": ["KICHERERBSEN"],
        "KIDNEY": ["KIDNEYBOHNEN", "BOHNEN"],
        "BOHNEN": ["KIDNEYBOHNEN", "WEISSE BOHNEN", "BOHNEN"],
        "REIS": ["BASMATI", "JASMIN", "PARBOILED", "MILCHREIS", "REIS"],
        "BASMATIREIS": ["BASMATI", "REIS"],
        "BASMATI": ["BASMATI", "REIS"],
        "MILCHREIS": ["MILCHREIS", "REIS"],
        "GNOCCHI": ["GNOCCHI", "PATATE"],
        "NUDELN": ["HOHLNUDELN", "NUDELN", "PENNE", "PASTA", "SPAGHETTI"],
        "HOHLNUDELN": ["NUDELN", "PENNE", "PASTA"],
        "PENNE": ["PENNE", "NUDELN", "PASTA"],
        "ROLLINI": ["ROLLINI", "PASTA", "LINSEN", "NUDELN"],
        "TORTELLONI": ["TORTELLONI", "TORTELLINI", "PASTA"],
        "COUSCOUS": ["COUSCOUS", "HARTWEIZEN"],
        "HAFERFL": ["HAFERFLOCKEN", "HAFER", "GRANOLA"],
        "HAFERFL.": ["HAFERFLOCKEN", "HAFER", "GRANOLA"],
        "HAFERFLOCKEN": ["HAFERFLOCKEN", "HAFER"],
        "GRANOLA": ["HAFERFLOCKEN", "GRANOLA", "MUESLI"],
        "TOAST": ["SANDWICHTOAST", "VOLLKORNTOAST", "TOAST", "BROT"],
        "SANDWICHTOAST": ["SANDWICHTOAST", "TOAST", "BROT"],
        "VOLLKORNBROT": ["VOLLKORNBROT", "BROT", "ROGGEN"],
        "BROT": ["VOLLKORNBROT", "BROT"],
        "WRAP": ["WRAPS", "TORTILLAS", "WEIZEN"],
        "TORTILLAS": ["WRAPS", "TORTILLAS", "WEIZEN"],

        // 5. Produce (Vegetables & Fruits)
        "KARTOFFELN": ["FRUEHKARTOFFELN", "SPEISEKARTOFFELN", "KARTOFFELN"],
        "FRUEHKARTOFFELN": ["FRUEHKARTOFFELN", "KARTOFFELN"],
        "KUMPIR": ["FRUEHKARTOFFELN", "KARTOFFELN"],
        "MOEHREN": ["MOEHREN", "KAROTTEN"],
        "KAROTTEN": ["MOEHREN", "KAROTTEN"],
        "ZWIEBELN": ["ZWIEBELN", "BIO ZWIEBELN"],
        "SPINAT": ["BLATTSPINAT", "RAHMSPINAT", "SPINAT"],
        "GURKE": ["SALATGURKE", "GURKE"],
        "SALATGURKE": ["SALATGURKE", "GURKE"],
        "MAIS": ["ZUCKERMAIS", "MAIS", "BONDUELLE"],
        "ZUCKERMAIS": ["ZUCKERMAIS", "MAIS"],
        "TOMATEN": ["RISPENTOMATEN", "PIZZATOMATEN", "CHERRY", "TOMATEN"],
        "PIZZATO": ["PIZZATOMATEN", "TOMATEN", "GEHACKTE TOMATEN"],
        "PIZZATOMATEN": ["PIZZATOMATEN", "TOMATEN", "GEHACKTE TOMATEN"],
        "RISPENTOMATEN": ["RISPENTOMATEN", "TOMATEN"],
        "AVOCADOS": ["AVOCADO"],
        "AVOCADO": ["AVOCADO"],
        "BANANEN": ["BANANE", "BANANEN"],
        "AEPFEL": ["APFEL", "AEPFEL", "BRAEBURN"],
        "APFEL": ["APFEL", "AEPFEL"],
        "BEEREN": ["BEERENMIX", "TK-BEEREN", "HEIDELBEEREN", "HIMBEEREN"],
        "INGW": ["INGWER"],
        "ZITR": ["ZITRONE"],

        // 6. Condiments, Oils, Spices & Nuts
        "ERDNUSSBUTTER": ["ERDNUSSBUTTER", "PEANUT", "BUTTER"],
        "PEANUT": ["ERDNUSSBUTTER", "PEANUT"],
        "KOKOSMILCH": ["KOKOSMILCH", "LIGHT"],
        "KOKUSSMIL": ["KOKOSMILCH", "LIGHT"],
        "OLIVENOEL": ["OLIVENOEL", "EXTRA"],
        "CASHEW": ["CASHEWKERNE", "CASHEWS"],
        "MANDELN": ["MANDELKERNE", "MANDEL"],
        "LEINSAMEN": ["LEINSAMEN", "BIO"],
        "BLUETENHONIG": ["BLUETENHONIG", "HONIG"],
        "WHEY": ["WHEY", "PROTEIN", "ISOLAT"],
        "ISOCLEAR": ["ISOCLEAR", "WHEY", "PROTEIN"]
    ]

    private init() {
        loadAliases()
    }

    // MARK: - Learned Alias Subsystem
    private func loadAliases() {
        if let saved = UserDefaults.standard.dictionary(forKey: userDefaultsKey) as? [String: String] {
            self.aliasMap = saved
        }
    }

    private func saveAliases() {
        UserDefaults.standard.set(aliasMap, forKey: userDefaultsKey)
    }

    public func learnAlias(rawReceiptLine: String, targetItem: PantryItem) {
        learnAlias(rawReceiptLine: rawReceiptLine, targetItemId: targetItem.id, targetItemName: targetItem.name)
    }

    public func learnAlias(rawReceiptLine: String, targetItemId: String, targetItemName: String) {
        let cleanKey = normalize(rawReceiptLine)
        guard !cleanKey.isEmpty else { return }
        aliasMap[cleanKey] = targetItemId
        saveAliases()
    }

    public func clearAliases() {
        aliasMap.removeAll()
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }

    // MARK: - Multi-Store Matching Core
    public func match(
        rawReceiptLine: String,
        in catalog: [PantryItem],
        storeContext: String? = nil,
        linePrice: Double? = nil
    ) -> MatchResult {
        let cleanRaw = normalize(rawReceiptLine)

        // Never match Pfand, Leergut or Non-Food items to food catalog
        if cleanRaw.contains("PFAND") || cleanRaw.contains("LEERGUT") || NonFoodClassifier.isNonFood(name: rawReceiptLine) {
            return MatchResult(item: nil, confidence: 0.0, alternatives: [])
        }

        // 1. Check Learned User Aliases First (Confidence 1.0)
        if let learnedId = aliasMap[cleanRaw], let found = catalog.first(where: { $0.id == learnedId }) {
            return MatchResult(item: found, confidence: 1.0, alternatives: [])
        }

        let rawTokens = Set(tokenize(cleanRaw))
        guard !rawTokens.isEmpty else {
            return MatchResult(item: nil, confidence: 0.0, alternatives: [])
        }

        let coreRawTokens = rawTokens.subtracting(stopWords)
        var scoredItems: [(item: PantryItem, score: Double)] = []

        // 2. Score against existing Pantry Catalog
        for item in catalog {
            let itemClean = normalize(item.name)
            let itemTokens = Set(tokenize(itemClean))
            let coreItemTokens = itemTokens.subtracting(stopWords)

            var score = 0.0
            var coreNounMatched = false

            // A. Exact / Substring Token Overlap
            let coreIntersection = coreRawTokens.intersection(coreItemTokens)
            if !coreIntersection.isEmpty {
                coreNounMatched = true
                let ratio = Double(coreIntersection.count) / Double(max(1, coreRawTokens.count))
                score += ratio * 65.0
            }

            // B. Multi-Store Synonym and Abbreviation Expansion
            for rTok in coreRawTokens {
                if let expansions = abbreviationMap[rTok] {
                    for exp in expansions {
                        let normExp = normalize(exp)
                        if itemClean.contains(normExp) || itemTokens.contains(normExp) {
                            coreNounMatched = true
                            score += 40.0
                            break
                        }
                    }
                }
            }

            // C. Compound Word / Substring matching (>= 4 chars)
            if !coreNounMatched {
                for rTok in coreRawTokens where rTok.count >= 4 {
                    for iTok in coreItemTokens where iTok.count >= 4 {
                        if iTok.contains(rTok) || rTok.contains(iTok) {
                            coreNounMatched = true
                            score += 32.0
                            break
                        }
                    }
                }
            }

            // D. Only award context and price bonuses if core noun was matched
            if coreNounMatched {
                // Brand match bonus
                let itemBrand = normalize(item.brand)
                if !itemBrand.isEmpty && (rawTokens.contains(itemBrand) || cleanRaw.contains(itemBrand)) {
                    score += 15.0
                }

                // Store context bonus
                if let ctx = storeContext, !ctx.isEmpty {
                    let normCtx = normalize(ctx)
                    if normalize(item.store) == normCtx || (item.storePrices?.keys.contains(where: { self.normalize($0) == normCtx }) ?? false) {
                        score += 15.0
                    }
                }

                // Store-Specific Price Proximity Bonus
                if let lp = linePrice, lp > 0 {
                    let storePrice = item.price(for: storeContext)
                    if storePrice > 0 {
                        let diff = abs(storePrice - lp)
                        if diff < 0.15 {
                            score += 25.0
                        } else if diff < 0.50 {
                            score += 15.0
                        } else if diff < 1.00 {
                            score += 8.0
                        }
                    }
                }

                // Levenshtein word similarity for OCR noise
                for rTok in coreRawTokens where rTok.count >= 4 {
                    for iTok in coreItemTokens where iTok.count >= 4 {
                        let dist = levenshtein(rTok, iTok)
                        if dist <= 1 {
                            score += 12.0
                        }
                    }
                }

                scoredItems.append((item, score))
            }
        }

        scoredItems.sort { $0.score > $1.score }

        // 3. Substantive Score Threshold Check (>= 40.0)
        if let best = scoredItems.first, best.score >= 40.0 {
            let normalizedConfidence = min(1.0, best.score / 100.0)
            let alternatives = scoredItems.dropFirst().prefix(4).map { $0.item }
            return MatchResult(item: best.item, confidence: normalizedConfidence, alternatives: alternatives)
        }

        // 4. CommodityReferenceCatalog Fallback if Item is Not in Pantry Catalog
        if let std = CommodityReferenceCatalog.standardMacros(forProductName: rawReceiptLine) {
            let synthesized = PantryItem(
                name: rawReceiptLine.capitalized,
                brand: storeContext ?? "Supermarkt",
                barcode: "",
                defaultPackQty: 500.0,
                defaultPrice: linePrice ?? 1.49,
                currentStockQty: 0.0,
                unit: "g",
                kcal100g: std.kcal,
                protein100g: std.protein,
                carbs100g: std.carbs,
                fat100g: std.fat,
                fiber100g: 2.0,
                store: storeContext ?? "PENNY"
            )
            return MatchResult(item: synthesized, confidence: 0.70, alternatives: scoredItems.prefix(4).map { $0.item })
        }

        let fallbackAlternatives = scoredItems.prefix(5).map { $0.item }
        return MatchResult(item: nil, confidence: 0.0, alternatives: fallbackAlternatives)
    }

    // MARK: - Normalization & String Algorithms
    public func normalize(_ text: String) -> String {
        var str = text.uppercased()
        str = str.replacingOccurrences(of: "Ä", with: "AE")
        str = str.replacingOccurrences(of: "Ö", with: "OE")
        str = str.replacingOccurrences(of: "Ü", with: "UE")
        str = str.replacingOccurrences(of: "ß", with: "SS")

        let noise = [".", ",", ";", ":", "!", "EUR", "EURO", "€", "KG", " G ", "STK", "ST ", " A ", " B ", "*", "#", "=", "/", "\\", "-", "(", ")"]
        for n in noise {
            str = str.replacingOccurrences(of: n, with: " ")
        }

        let allowed = CharacterSet.alphanumerics.union(.whitespaces)
        let filtered = str.unicodeScalars.filter { allowed.contains($0) }
        return String(String.UnicodeScalarView(filtered)).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public func tokenize(_ text: String) -> [String] {
        return text.split(separator: " ")
            .map { String($0) }
            .filter { $0.count >= 2 }
    }

    public func levenshtein(_ s1: String, _ s2: String) -> Int {
        let a = Array(s1)
        let b = Array(s2)
        guard !a.isEmpty else { return b.count }
        guard !b.isEmpty else { return a.count }

        var previousRow = Array(0...b.count)
        var currentRow = [Int](repeating: 0, count: b.count + 1)

        for i in 1...a.count {
            currentRow[0] = i
            for j in 1...b.count {
                if a[i - 1] == b[j - 1] {
                    currentRow[j] = previousRow[j - 1]
                } else {
                    currentRow[j] = min(previousRow[j] + 1, currentRow[j - 1] + 1, previousRow[j - 1] + 1)
                }
            }
            previousRow = currentRow
        }
        return previousRow[b.count]
    }
}

// MARK: - Centralized Non-Food & Non-Dietary Consumables Classifier
public enum NonFoodClassifier {
    public static let nonFoodKeywords: Set<String> = [
        // Household, Storage, Kitchenware, Hardware & Packaging
        "SCHÜSSEL", "SCHUESSEL", "MESSER", "KUCHENGABEL", "GABEL", "LÖFFEL", "LOEFFEL",
        "FRISCHHALTEDOSE", "FRISCHHALTEDOSEN", "TASCHE", "MEHRWEGTASCHE", "TRAGETASCHE",
        "BEUTEL", "BROTDOSE", "FRÜHSTÜCKSBOX", "FRUEHSTUECKSBOX", "LUNCHBOX", "BATTERIE",
        "BATTERIEN", "SCHWAMM", "ALUFOLIE", "BACKPAPIER", "FOIL", "FRISCHHALTEFOLIE",
        "KERZE", "KERZEN", "PFANNE", "TOPF", "SCHERE", "SERVIETTE", "SERVIETTEN",
        "BECHER", "TELLER", "KOSMETIK", "MÜLLSACK", "MUELLSACK", "MÜLLBEUTEL", "MUELLBEUTEL",
        // Body Care, Hygiene & Cleaning Chemicals
        "ZAHNPASTA", "ZAHNBÜRSTE", "ZAHNBUERSTE", "DEO", "DUSCHGEL", "SHAMPOO", "SEIFE",
        "SPÜLMITTEL", "SPUELMITTEL", "KLOPAPIER", "TOILETTENPAPIER", "KÜCHENTÜCHER",
        "KUECHENTUECHER", "TASCHENTÜCHER", "TASCHENTUECHER", "FEUCHTTÜCHER", "FEUCHTTUECHER",
        "WATTEPADS", "REINIGER", "WASCHMITTEL", "WEICHSPÜLER", "GLASREINIGER", "WC-REINIGER",
        // Edible Non-Nutritional Consumables (Chewing Gum, Breath Mints, Lozenges & Drops)
        "WRIGLEY", "EXTRA", "AIRWAVES", "HUBBA BUBBA", "MENTOS", "TIC TAC", "HALLS",
        "FISHERMAN", "RICOLA", "KAUGUMMI", "CHEWING GUM", "GUM", "PASTILLEN", "BONBON", "BONBONS",
        "HALSPASTILLEN", "HUSTENBONBONS", "DROPS", "LOLLIS", "SCHLECKER", "DRASTIK"
    ]

    public static let nonFoodCategories: Set<String> = [
        "chewing-gums", "chewing gum", "breath-mints", "pastilles", "candies", "bonbons",
        "hygiene", "cosmetics", "cleaning-products", "pet-food", "shampoos", "soaps",
        "household", "kitchenware", "cutlery", "storage"
    ]

    public static func isNonFood(name: String, categories: String = "", taxCode: String? = nil) -> Bool {
        let upperName = name.uppercased()
        if nonFoodKeywords.contains(where: { upperName.contains($0) }) {
            return true
        }
        if !categories.isEmpty {
            let lowerCategories = categories.lowercased()
            if nonFoodCategories.contains(where: { lowerCategories.contains($0) }) {
                return true
            }
        }
        return false
    }

    public static func isNonFood(item: PantryItem) -> Bool {
        return isNonFood(name: item.name)
    }
}
