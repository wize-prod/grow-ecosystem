import Foundation

public final class OpenFoodFactsService {
    public static let shared = OpenFoodFactsService()

    private let session: URLSession

    private init() {
        let configuration = URLSessionConfiguration.default
        // 2.5-second strict timeout for instant offline resilience
        configuration.timeoutIntervalForRequest = 2.5
        configuration.timeoutIntervalForResource = 3.5
        configuration.waitsForConnectivity = false
        self.session = URLSession(configuration: configuration)
    }

    public func fetchProduct(barcode: String) async -> PantryItem? {
        let cleanBarcode = barcode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanBarcode.isEmpty else { return nil }

        // Tier 1: Open Food Facts (DE + World)
        let endpoints = [
            "https://de.openfoodfacts.org/api/v2/product/\(cleanBarcode).json",
            "https://world.openfoodfacts.org/api/v2/product/\(cleanBarcode).json"
        ]

        for urlString in endpoints {
            if let item = await queryEndpoint(urlString, barcode: cleanBarcode) {
                return postProcessAndImpute(item: item)
            }
        }

        // Tier 2: Open Products Facts (Non-Food, Household, Drogerie)
        if let item = await queryOpenProductsFacts(barcode: cleanBarcode) {
            return postProcessAndImpute(item: item)
        }

        // Tier 3: USDA FoodData Central (350.000+ Branded & Foundation Foods mit GTIN/UPC)
        if let item = await queryUSDAFoodData(barcode: cleanBarcode) {
            return postProcessAndImpute(item: item)
        }

        // Tier 4: UPCitemdb (400M+ globale EAN-Metadaten für Name, Marke & Packungsgröße)
        if let item = await queryUPCitemdb(barcode: cleanBarcode) {
            return postProcessAndImpute(item: item)
        }

        return nil
    }

    // MARK: - Post-Processing & Automated Laboratory Standard Imputation
    private func postProcessAndImpute(item: PantryItem) -> PantryItem {
        var mod = item
        if mod.kcal100g <= 0 && mod.protein100g <= 0 && mod.carbs100g <= 0 && mod.fat100g <= 0 {
            if let std = CommodityReferenceCatalog.standardMacros(forProductName: mod.name) {
                mod.kcal100g = std.kcal
                mod.protein100g = std.protein
                mod.carbs100g = std.carbs
                mod.fat100g = std.fat
                mod.fiber100g = std.fiber
            }
        }
        mod.profile = CommodityReferenceCatalog.enrich(
            profile: mod.profile,
            forProductName: mod.name,
            brand: mod.brand
        )
        return mod
    }

    // MARK: - Tier 2: Open Products Facts
    private func queryOpenProductsFacts(barcode: String) async -> PantryItem? {
        guard let url = URL(string: "https://world.openproductsfacts.org/api/v2/product/\(barcode).json") else { return nil }
        var request = URLRequest(url: url)
        request.setValue("NutriVault-iOS/1.0 (Nourishment-Pantry-App)", forHTTPHeaderField: "User-Agent")
        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { return nil }
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let status = json["status"] as? Int, status == 1,
                  let product = json["product"] as? [String: Any] else { return nil }

            let productName = (product["product_name_de"] as? String)
                ?? (product["product_name"] as? String)
                ?? "Produkt"
            let brand = (product["brands"] as? String)?.components(separatedBy: ",").first?.trimmingCharacters(in: .whitespaces) ?? "Drogerie"
            return PantryItem(
                id: "food_\(barcode)_\(Int(Date().timeIntervalSince1970))",
                name: productName,
                brand: brand,
                barcode: barcode,
                defaultPackQty: 1.0,
                defaultPrice: 0.0,
                currentStockQty: 1.0,
                unit: "Stück",
                kcal100g: 0.0,
                protein100g: 0.0,
                carbs100g: 0.0,
                fat100g: 0.0,
                fiber100g: 0.0,
                nutriscore: "unknown",
                store: "DM",
                profile: nil
            )
        } catch {
            return nil
        }
    }

    // MARK: - Tier 3: USDA FoodData Central
    private func queryUSDAFoodData(barcode: String) async -> PantryItem? {
        guard let url = URL(string: "https://api.nal.usda.gov/fdc/v1/foods/search?query=\(barcode)&pageSize=1&api_key=DEMO_KEY") else { return nil }
        var request = URLRequest(url: url)
        request.setValue("NutriVault-iOS/1.0", forHTTPHeaderField: "User-Agent")
        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { return nil }
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let foods = json["foods"] as? [[String: Any]],
                  let firstFood = foods.first else { return nil }

            let desc = (firstFood["description"] as? String) ?? "Lebensmittel (USDA)"
            let brand = (firstFood["brandOwner"] as? String) ?? (firstFood["brandName"] as? String) ?? "Supermarkt"
            let nutrients = firstFood["foodNutrients"] as? [[String: Any]] ?? []

            var kcal: Double = 0
            var protein: Double = 0
            var carbs: Double = 0
            var fat: Double = 0
            var fiber: Double = 0

            for n in nutrients {
                let name = (n["nutrientName"] as? String)?.lowercased() ?? ""
                let val = n["value"] as? Double ?? Double(n["value"] as? Int ?? 0)
                if name.contains("energy") || name.contains("calorie") {
                    if val > 0 && kcal == 0 { kcal = val }
                } else if name.contains("protein") {
                    protein = val
                } else if name.contains("carbohydrate") {
                    carbs = val
                } else if name.contains("lipid") || name.contains("fat, total") {
                    fat = val
                } else if name.contains("fiber") {
                    fiber = val
                }
            }

            return PantryItem(
                id: "food_\(barcode)_\(Int(Date().timeIntervalSince1970))",
                name: desc,
                brand: brand,
                barcode: barcode,
                defaultPackQty: 500.0,
                defaultPrice: 0.0,
                currentStockQty: 500.0,
                unit: "g",
                kcal100g: kcal,
                protein100g: protein,
                carbs100g: carbs,
                fat100g: fat,
                fiber100g: fiber,
                nutriscore: "a",
                store: "Supermarkt",
                profile: nil
            )
        } catch {
            return nil
        }
    }

    // MARK: - Tier 4: UPCitemdb
    private func queryUPCitemdb(barcode: String) async -> PantryItem? {
        guard let url = URL(string: "https://api.upcitemdb.com/prod/trial/lookup?upc=\(barcode)") else { return nil }
        var request = URLRequest(url: url)
        request.setValue("NutriVault-iOS/1.0", forHTTPHeaderField: "User-Agent")
        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { return nil }
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let items = json["items"] as? [[String: Any]],
                  let first = items.first else { return nil }

            let title = (first["title"] as? String) ?? "Produkt"
            let brand = (first["brand"] as? String) ?? "Supermarkt"
            return PantryItem(
                id: "food_\(barcode)_\(Int(Date().timeIntervalSince1970))",
                name: title,
                brand: brand,
                barcode: barcode,
                defaultPackQty: 500.0,
                defaultPrice: 0.0,
                currentStockQty: 500.0,
                unit: "g",
                kcal100g: 0.0,
                protein100g: 0.0,
                carbs100g: 0.0,
                fat100g: 0.0,
                fiber100g: 0.0,
                nutriscore: "unknown",
                store: "Supermarkt",
                profile: nil
            )
        } catch {
            return nil
        }
    }

    private func queryEndpoint(_ urlString: String, barcode: String) async -> PantryItem? {
        guard let url = URL(string: urlString) else { return nil }

        var request = URLRequest(url: url)
        request.setValue("NutriVault-iOS/1.0 (Nourishment-Pantry-App)", forHTTPHeaderField: "User-Agent")

        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return nil
            }

            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let status = json["status"] as? Int, status == 1,
                  let product = json["product"] as? [String: Any] else {
                return nil
            }

            let productName = (product["product_name_de"] as? String)
                ?? (product["product_name"] as? String)
                ?? "Unbekanntes Lebensmittel"

            let brand = (product["brands"] as? String)?.components(separatedBy: ",").first?.trimmingCharacters(in: .whitespaces)
                ?? "Pantry"

            let nutriments = product["nutriments"] as? [String: Any] ?? [:]

            // Big 7 Macronutrients
            let kcal100g = extractNumber(from: nutriments, keys: ["energy-kcal_100g", "energy-kcal", "energy_100g"])
            let protein100g = extractNumber(from: nutriments, keys: ["proteins_100g", "proteins"])
            let carbs100g = extractNumber(from: nutriments, keys: ["carbohydrates_100g", "carbohydrates"])
            let fat100g = extractNumber(from: nutriments, keys: ["fat_100g", "fat"])
            let fiber100g = extractNumber(from: nutriments, keys: ["fiber_100g", "fiber"])
            let nutriscore = (product["nutriscore_grade"] as? String)?.lowercased() ?? "a"

            let rawQuantity = (product["quantity"] as? String) ?? ""
            let categories = (product["categories"] as? String) ?? ""
            let servingSize = (product["serving_size"] as? String) ?? ""
            let rawProductQty = extractNumber(from: product, keys: ["product_quantity"])

            let (detectedUnit, packQty) = determineUnitAndPackSize(
                productName: productName,
                categories: categories,
                rawQuantity: rawQuantity,
                servingSize: servingSize,
                rawProductQuantity: rawProductQty
            )

            // Stage 1: Exhaustive Deep-Extraction of Micro & Macro Nutrients
            var parsedProfile = NutritionalProfile(
                // Detailed Carbs & Fats
                sugars: extractNutrient(from: nutriments, baseKeys: ["sugars"], target: .g),
                addedSugars: extractNutrient(from: nutriments, baseKeys: ["added-sugars", "sugars-added"], target: .g),
                fiber: fiber100g > 0 ? fiber100g : extractNutrient(from: nutriments, baseKeys: ["fiber"], target: .g),
                saturatedFat: extractNutrient(from: nutriments, baseKeys: ["saturated-fat"], target: .g),
                monounsaturatedFat: extractNutrient(from: nutriments, baseKeys: ["monounsaturated-fat"], target: .g),
                polyunsaturatedFat: extractNutrient(from: nutriments, baseKeys: ["polyunsaturated-fat"], target: .g),
                transFat: extractNutrient(from: nutriments, baseKeys: ["trans-fat"], target: .g),

                // Components
                alcohol: extractNutrient(from: nutriments, baseKeys: ["alcohol"], target: .g),
                cholesterol: extractNutrient(from: nutriments, baseKeys: ["cholesterol"], target: .mg),
                sodium: extractNutrient(from: nutriments, baseKeys: ["sodium"], target: .mg),
                salt: extractNutrient(from: nutriments, baseKeys: ["salt"], target: .g),
                water: extractNutrient(from: nutriments, baseKeys: ["water"], target: .g),

                // Vitamins
                vitaminA: extractNutrient(from: nutriments, baseKeys: ["vitamin-a"], target: .mcg),
                vitaminB1: extractNutrient(from: nutriments, baseKeys: ["vitamin-b1", "thiamin"], target: .mg),
                vitaminB2: extractNutrient(from: nutriments, baseKeys: ["vitamin-b2", "riboflavin"], target: .mg),
                vitaminB3: extractNutrient(from: nutriments, baseKeys: ["vitamin-b3", "vitamin-pp", "niacin"], target: .mg),
                vitaminB5: extractNutrient(from: nutriments, baseKeys: ["pantothenic-acid", "vitamin-b5"], target: .mg),
                vitaminB6: extractNutrient(from: nutriments, baseKeys: ["vitamin-b6"], target: .mg),
                vitaminB7: extractNutrient(from: nutriments, baseKeys: ["biotin", "vitamin-b7", "vitamin-b8"], target: .mcg),
                vitaminB11: extractNutrient(from: nutriments, baseKeys: ["folates", "folic-acid", "vitamin-b9", "vitamin-b11"], target: .mcg),
                vitaminB12: extractNutrient(from: nutriments, baseKeys: ["vitamin-b12"], target: .mcg),
                vitaminC: extractNutrient(from: nutriments, baseKeys: ["vitamin-c"], target: .mg),
                vitaminD: extractNutrient(from: nutriments, baseKeys: ["vitamin-d"], target: .mcg),
                vitaminE: extractNutrient(from: nutriments, baseKeys: ["vitamin-e"], target: .mg),
                vitaminK: extractNutrient(from: nutriments, baseKeys: ["vitamin-k"], target: .mcg),

                // Minerals
                chloride: extractNutrient(from: nutriments, baseKeys: ["chloride"], target: .mg),
                chromium: extractNutrient(from: nutriments, baseKeys: ["chromium"], target: .mcg),
                iron: extractNutrient(from: nutriments, baseKeys: ["iron"], target: .mg),
                fluorine: nil,
                fluoride: extractNutrient(from: nutriments, baseKeys: ["fluoride", "fluorine"], target: .mg),
                iodine: extractNutrient(from: nutriments, baseKeys: ["iodine"], target: .mcg),
                potassium: extractNutrient(from: nutriments, baseKeys: ["potassium"], target: .mg),
                calcium: extractNutrient(from: nutriments, baseKeys: ["calcium"], target: .mg),
                copper: extractNutrient(from: nutriments, baseKeys: ["copper"], target: .mg),
                magnesium: extractNutrient(from: nutriments, baseKeys: ["magnesium"], target: .mg),
                manganese: extractNutrient(from: nutriments, baseKeys: ["manganese"], target: .mg),
                molybdenum: extractNutrient(from: nutriments, baseKeys: ["molybdenum"], target: .mcg),
                phosphorus: extractNutrient(from: nutriments, baseKeys: ["phosphorus"], target: .mg),
                selenium: extractNutrient(from: nutriments, baseKeys: ["selenium"], target: .mcg),
                zinc: extractNutrient(from: nutriments, baseKeys: ["zinc"], target: .mg)
            )

            // Stage 2: Commodity MasterData Fallback / Blending Engine
            // Fills missing micronutrients from verified laboratory commodity standards
            parsedProfile = CommodityReferenceCatalog.enrich(
                profile: parsedProfile,
                forProductName: productName,
                brand: brand
            )

            return PantryItem(
                id: "food_\(barcode)_\(Int(Date().timeIntervalSince1970))",
                name: productName,
                brand: brand,
                barcode: barcode,
                defaultPackQty: packQty,
                defaultPrice: 0.0,
                currentStockQty: packQty,
                unit: detectedUnit,
                kcal100g: kcal100g,
                protein100g: protein100g,
                carbs100g: carbs100g,
                fat100g: fat100g,
                fiber100g: fiber100g,
                nutriscore: nutriscore,
                store: "PENNY",
                profile: parsedProfile
            )
        } catch {
            GrowTelemetryService.shared.logTaskFailure(
                appName: "Growcery",
                category: .network,
                title: "OpenFoodFacts Barcode Lookup fehlgeschlagen",
                error: error,
                metadata: ["barcode": barcode]
            )
            return nil
        }
    }

    private func extractNumber(from dict: [String: Any], keys: [String]) -> Double {
        for key in keys {
            if let val = dict[key] as? Double {
                return val
            } else if let val = dict[key] as? Int {
                return Double(val)
            } else if let str = dict[key] as? String, let val = Double(str) {
                return val
            }
        }
        return 0.0
    }

    private enum TargetUnit {
        case g
        case mg
        case mcg
    }

    private func extractNutrient(
        from dict: [String: Any],
        baseKeys: [String],
        target: TargetUnit
    ) -> Double? {
        for base in baseKeys {
            var rawVal: Double? = nil
            var unitStr: String? = nil

            if let val = dict["\(base)_100g"] as? Double {
                rawVal = val
            } else if let val = dict["\(base)_100g"] as? Int {
                rawVal = Double(val)
            } else if let str = dict["\(base)_100g"] as? String, let val = Double(str) {
                rawVal = val
            } else if let val = dict["\(base)_value"] as? Double {
                rawVal = val
            } else if let val = dict["\(base)_value"] as? Int {
                rawVal = Double(val)
            } else if let str = dict["\(base)_value"] as? String, let val = Double(str) {
                rawVal = val
            } else if let val = dict[base] as? Double {
                rawVal = val
            }

            if let u = dict["\(base)_unit"] as? String {
                unitStr = u.lowercased().trimmingCharacters(in: .whitespaces)
            }

            guard let value = rawVal, value > 0 else { continue }

            // Unit conversion matching target specification
            if let unit = unitStr {
                switch (unit, target) {
                case ("g", .g): return value
                case ("g", .mg): return value * 1000.0
                case ("g", .mcg): return value * 1_000_000.0

                case ("mg", .g): return value / 1000.0
                case ("mg", .mg): return value
                case ("mg", .mcg): return value * 1000.0

                case ("µg", .g), ("mcg", .g), ("ug", .g): return value / 1_000_000.0
                case ("µg", .mg), ("mcg", .mg), ("ug", .mg): return value / 1000.0
                case ("µg", .mcg), ("mcg", .mcg), ("ug", .mcg): return value
                default: break
                }
            }

            // Fallback when unit string is not declared: Open Food Facts default for _100g is grams
            switch target {
            case .g:
                return value
            case .mg:
                if value < 5.0 {
                    return value * 1000.0 // converted from grams
                } else {
                    return value // already in mg
                }
            case .mcg:
                if value < 0.01 {
                    return value * 1_000_000.0 // converted from grams
                } else if value < 5.0 {
                    return value * 1000.0 // converted from mg
                } else {
                    return value // already in mcg
                }
            }
        }
        return nil
    }

    private func determineUnitAndPackSize(
        productName: String,
        categories: String,
        rawQuantity: String,
        servingSize: String,
        rawProductQuantity: Double
    ) -> (unit: String, packQty: Double) {
        let combined = "\(productName) \(categories) \(rawQuantity) \(servingSize)".lowercased()

        // 1. Eggs / Hühnereier / Bodenhaltung
        let isEgg = (combined.contains("eier") || combined.contains("ei ") || combined.hasPrefix("ei ") || combined.contains("frischeier") || combined.contains("hühnerei") || combined.contains("eggs") || combined.contains("bodenhaltung") || combined.contains("freilandhaltung")) && !combined.contains("fleisch") && !combined.contains("reis") && !combined.contains("nudel") && !combined.contains("teig") && !combined.contains("eiweiß") && !combined.contains("salat")

        if isEgg {
            if let count = extractCount(from: combined, patterns: [
                #"(\d+)\s*(?:eier|ei\b|stk|stück)"#,
                #"(\d+)\s*er\s*pack"#,
                #"(\d+)\s*er\b"#
            ]), count >= 4 && count <= 30 {
                return ("Stück", count)
            }
            return ("Stück", 10.0) // Standard 10er Eier-Karton
        }

        // 2. Supplements (Kapseln / Tabletten / Softgels)
        if combined.contains("kapsel") || combined.contains("tablette") || combined.contains("capsule") || combined.contains("softgel") {
            if let count = extractCount(from: combined, patterns: [
                #"(\d+)\s*(?:kapseln|kapsel|tabletten|caps|capsules|stk|stück)"#
            ]), count >= 10 {
                return ("Kapseln", count)
            }
            return ("Kapseln", 60.0)
        }

        // 3. Multi-Pack Bars (Riegel, Eisriegel)
        if combined.contains("riegel") || combined.contains("snickers") || combined.contains("corny") {
            if let count = extractCount(from: combined, patterns: [
                #"(\d+)\s*(?:riegel|stk|stück|er\s*pack|er\b)"#,
                #"(\d+)\s*x"#
            ]), count >= 2 && count <= 24 {
                return ("Stück", count)
            }
            return ("Stück", 1.0)
        }

        // 4. Wraps / Tortillas
        if combined.contains("wrap") || combined.contains("tortilla") {
            if let count = extractCount(from: combined, patterns: [
                #"(\d+)\s*(?:wraps|tortillas|stk|stück)"#
            ]), count >= 2 && count <= 20 {
                return ("Stück", count)
            }
            return ("Stück", 6.0)
        }

        // 5. Produce single units (Avocado, Gurke, Salat, Banane)
        if combined.contains("avocado") || combined.contains("salatgurke") || combined.contains("eisbergsalat") || combined.contains("salatherzen") {
            if let count = extractCount(from: combined, patterns: [
                #"(\d+)\s*(?:stk|stück|er\s*pack|er\b)"#
            ]), count >= 1 && count <= 6 {
                return ("Stück", count)
            }
            return ("Stück", 1.0)
        }

        // 6. Generic Piece / Stück detection in quantity string (e.g. "4 Stück", "8 Stk")
        if let count = extractCount(from: rawQuantity.lowercased(), patterns: [
            #"(\d+)\s*(?:stück|stk|pcs|pieces)"#
        ]), count >= 1 && count <= 50 {
            return ("Stück", count)
        }

        // 7. Liquids (ml / Liter)
        if combined.contains("milch") || combined.contains("saft") || combined.contains("öl") || combined.contains("drink") || combined.contains("sirup") || combined.contains("wasser") || combined.contains("getränk") || rawQuantity.lowercased().contains("ml") || rawQuantity.lowercased().contains(" l") {
            var ml = rawProductQuantity
            if rawQuantity.lowercased().contains("1 l") || rawQuantity.lowercased().contains("1l") {
                ml = 1000.0
            } else if rawQuantity.lowercased().contains("500 ml") {
                ml = 500.0
            } else if rawQuantity.lowercased().contains("750 ml") {
                ml = 750.0
            } else if rawQuantity.lowercased().contains("250 ml") {
                ml = 250.0
            } else if rawQuantity.lowercased().contains("330 ml") {
                ml = 330.0
            }
            return ("ml", ml > 0 ? ml : 500.0)
        }

        // 8. Grams Default
        return ("g", rawProductQuantity > 0 ? rawProductQuantity : 500.0)
    }

    private func extractCount(from text: String, patterns: [String]) -> Double? {
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                let nsText = text as NSString
                if let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: nsText.length)),
                   match.numberOfRanges > 1 {
                    let numStr = nsText.substring(with: match.range(at: 1))
                    if let d = Double(numStr), d > 0 {
                        return d
                    }
                }
            }
        }
        return nil
    }
}
