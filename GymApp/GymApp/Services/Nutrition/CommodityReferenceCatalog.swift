import Foundation

public struct CommodityReferenceCatalog {

    public struct CommodityDefinition {
        public let name: String
        public let keywords: [String]
        public let defaultStore: String
        public let profile: NutritionalProfile

        public init(name: String, keywords: [String], defaultStore: String = "PENNY", profile: NutritionalProfile) {
            self.name = name
            self.keywords = keywords
            self.defaultStore = defaultStore
            self.profile = profile
        }
    }

    public static func makeProfile(
        sugars: Double? = nil,
        addedSugars: Double? = nil,
        fiber: Double? = nil,
        saturatedFat: Double? = nil,
        monounsaturatedFat: Double? = nil,
        polyunsaturatedFat: Double? = nil,
        transFat: Double? = nil,
        alcohol: Double? = nil,
        cholesterol: Double? = nil,
        sodium: Double? = nil,
        salt: Double? = nil,
        water: Double? = nil,
        vitaminA: Double? = nil,
        vitaminB1: Double? = nil,
        vitaminB2: Double? = nil,
        vitaminB3: Double? = nil,
        vitaminB5: Double? = nil,
        vitaminB6: Double? = nil,
        vitaminB7: Double? = nil,
        vitaminB11: Double? = nil,
        vitaminB12: Double? = nil,
        vitaminC: Double? = nil,
        vitaminD: Double? = nil,
        vitaminE: Double? = nil,
        vitaminK: Double? = nil,
        choline: Double? = nil,
        chloride: Double? = nil,
        chromium: Double? = nil,
        iron: Double? = nil,
        fluoride: Double? = nil,
        iodine: Double? = nil,
        potassium: Double? = nil,
        calcium: Double? = nil,
        copper: Double? = nil,
        magnesium: Double? = nil,
        manganese: Double? = nil,
        molybdenum: Double? = nil,
        phosphorus: Double? = nil,
        selenium: Double? = nil,
        zinc: Double? = nil
    ) -> NutritionalProfile {
        var p = NutritionalProfile()
        p.sugars = sugars
        p.addedSugars = addedSugars
        p.fiber = fiber
        p.saturatedFat = saturatedFat
        p.monounsaturatedFat = monounsaturatedFat
        p.polyunsaturatedFat = polyunsaturatedFat
        p.transFat = transFat
        p.alcohol = alcohol
        p.cholesterol = cholesterol
        p.sodium = sodium
        p.salt = salt
        p.water = water
        p.vitaminA = vitaminA
        p.vitaminB1 = vitaminB1
        p.vitaminB2 = vitaminB2
        p.vitaminB3 = vitaminB3
        p.vitaminB5 = vitaminB5
        p.vitaminB6 = vitaminB6
        p.vitaminB7 = vitaminB7
        p.vitaminB11 = vitaminB11
        p.vitaminB12 = vitaminB12
        p.vitaminC = vitaminC
        p.vitaminD = vitaminD
        p.vitaminE = vitaminE
        p.vitaminK = vitaminK
        p.choline = choline
        p.chloride = chloride
        p.chromium = chromium
        p.iron = iron
        p.fluoride = fluoride
        p.iodine = iodine
        p.potassium = potassium
        p.calcium = calcium
        p.copper = copper
        p.magnesium = magnesium
        p.manganese = manganese
        p.molybdenum = molybdenum
        p.phosphorus = phosphorus
        p.selenium = selenium
        p.zinc = zinc
        return p
    }

    public static let commodities: [CommodityDefinition] = [
        // Haferflocken / Oats / Granola
        CommodityDefinition(
            name: "Haferflocken",
            keywords: ["hafer", "oat", "flocken", "granola", "müsli", "muesli"],
            profile: makeProfile(
                sugars: 1.1,
                addedSugars: 0.0,
                fiber: 10.0,
                saturatedFat: 1.3,
                monounsaturatedFat: 2.5,
                polyunsaturatedFat: 2.8,
                transFat: 0.0,
                sodium: 6.0,
                salt: 0.02,
                water: 10.5,
                vitaminB1: 0.59,
                vitaminB2: 0.15,
                vitaminB3: 1.1,
                vitaminB5: 1.3,
                vitaminB6: 0.16,
                vitaminB7: 20.0,
                vitaminB11: 56.0,
                vitaminE: 1.5,
                iron: 4.6,
                iodine: 6.0,
                potassium: 379.0,
                calcium: 43.0,
                copper: 0.54,
                magnesium: 130.0,
                manganese: 3.6,
                phosphorus: 430.0,
                selenium: 7.0,
                zinc: 3.6
            )
        ),

        // Magerquark / Quark / Skyr
        CommodityDefinition(
            name: "Magerquark / Skyr",
            keywords: ["quark", "magerquark", "skyr", "speisequark"],
            profile: makeProfile(
                sugars: 4.0,
                addedSugars: 0.0,
                fiber: 0.0,
                saturatedFat: 0.1,
                monounsaturatedFat: 0.05,
                polyunsaturatedFat: 0.05,
                cholesterol: 7.0,
                sodium: 40.0,
                salt: 0.10,
                water: 82.0,
                vitaminA: 10.0,
                vitaminB1: 0.03,
                vitaminB2: 0.31,
                vitaminB3: 0.25,
                vitaminB5: 0.40,
                vitaminB6: 0.07,
                vitaminB7: 4.5,
                vitaminB11: 27.0,
                vitaminB12: 0.90,
                vitaminD: 0.10,
                iron: 0.15,
                iodine: 8.0,
                potassium: 150.0,
                calcium: 120.0,
                magnesium: 12.0,
                phosphorus: 170.0,
                selenium: 9.0,
                zinc: 0.55
            )
        ),

        // Hähnchenbrust / Pute / Geflügel
        CommodityDefinition(
            name: "Hähnchenbrust",
            keywords: ["hähnchen", "ha-brust", "hühnchen", "pute", "geflügel", "chicken", "brustfilet"],
            profile: makeProfile(
                sugars: 0.0,
                addedSugars: 0.0,
                fiber: 0.0,
                saturatedFat: 0.4,
                monounsaturatedFat: 0.5,
                polyunsaturatedFat: 0.4,
                cholesterol: 60.0,
                sodium: 65.0,
                salt: 0.16,
                water: 75.0,
                vitaminA: 6.0,
                vitaminB1: 0.08,
                vitaminB2: 0.12,
                vitaminB3: 11.2,
                vitaminB5: 1.0,
                vitaminB6: 0.81,
                vitaminB11: 10.0,
                vitaminB12: 0.45,
                iron: 0.9,
                potassium: 330.0,
                calcium: 12.0,
                copper: 0.05,
                magnesium: 29.0,
                phosphorus: 220.0,
                selenium: 24.5,
                zinc: 0.8
            )
        ),

        // Eier / Whole Eggs
        CommodityDefinition(
            name: "Frische Eier",
            keywords: ["ei", "eier", "hühnerei", "bodenhaltung"],
            profile: makeProfile(
                sugars: 0.7,
                addedSugars: 0.0,
                fiber: 0.0,
                saturatedFat: 3.1,
                monounsaturatedFat: 3.8,
                polyunsaturatedFat: 1.4,
                cholesterol: 396.0,
                sodium: 140.0,
                salt: 0.35,
                water: 74.5,
                vitaminA: 160.0,
                vitaminB1: 0.09,
                vitaminB2: 0.35,
                vitaminB3: 0.1,
                vitaminB5: 1.4,
                vitaminB6: 0.12,
                vitaminB7: 25.0,
                vitaminB11: 44.0,
                vitaminB12: 1.11,
                vitaminD: 2.5,
                vitaminE: 1.5,
                vitaminK: 8.9,
                choline: 250.0,
                iron: 1.8,
                iodine: 12.0,
                potassium: 147.0,
                calcium: 57.0,
                magnesium: 12.0,
                phosphorus: 200.0,
                selenium: 31.0,
                zinc: 1.3
            )
        ),

        // Thunfisch / Tuna
        CommodityDefinition(
            name: "Thunfisch",
            keywords: ["thunfisch", "tuna", "berida"],
            profile: makeProfile(
                sugars: 0.0,
                addedSugars: 0.0,
                fiber: 0.0,
                saturatedFat: 0.25,
                monounsaturatedFat: 0.2,
                polyunsaturatedFat: 0.35,
                cholesterol: 45.0,
                sodium: 350.0,
                salt: 0.88,
                water: 70.0,
                vitaminA: 15.0,
                vitaminB1: 0.05,
                vitaminB2: 0.10,
                vitaminB3: 13.5,
                vitaminB5: 0.8,
                vitaminB6: 0.65,
                vitaminB11: 15.0,
                vitaminB12: 3.5,
                vitaminD: 4.8,
                vitaminE: 0.8,
                iron: 1.3,
                iodine: 14.0,
                potassium: 350.0,
                calcium: 10.0,
                magnesium: 32.0,
                phosphorus: 250.0,
                selenium: 82.0,
                zinc: 0.8
            )
        ),

        // Rote Linsen / Linsen
        CommodityDefinition(
            name: "Linsen",
            keywords: ["linsen", "berglinsen", "tellerlinsen"],
            profile: makeProfile(
                sugars: 2.0,
                addedSugars: 0.0,
                fiber: 11.0,
                saturatedFat: 0.3,
                monounsaturatedFat: 0.3,
                polyunsaturatedFat: 0.8,
                sodium: 10.0,
                salt: 0.03,
                water: 11.0,
                vitaminB1: 0.45,
                vitaminB2: 0.15,
                vitaminB3: 2.2,
                vitaminB5: 1.3,
                vitaminB6: 0.55,
                vitaminB7: 13.0,
                vitaminB11: 430.0,
                vitaminE: 1.0,
                iron: 6.9,
                potassium: 810.0,
                calcium: 51.0,
                copper: 0.75,
                magnesium: 107.0,
                manganese: 1.3,
                phosphorus: 380.0,
                selenium: 3.0,
                zinc: 3.4
            )
        ),

        // Kichererbsen / Chickpeas
        CommodityDefinition(
            name: "Kichererbsen",
            keywords: ["kichererbse", "chickpea"],
            profile: makeProfile(
                sugars: 2.4,
                addedSugars: 0.0,
                fiber: 7.6,
                saturatedFat: 0.4,
                monounsaturatedFat: 0.7,
                polyunsaturatedFat: 1.2,
                sodium: 250.0,
                salt: 0.63,
                vitaminB1: 0.20,
                vitaminB2: 0.08,
                vitaminB3: 1.0,
                vitaminB5: 0.6,
                vitaminB6: 0.28,
                vitaminB11: 180.0,
                vitaminE: 0.8,
                iron: 2.9,
                potassium: 290.0,
                calcium: 50.0,
                copper: 0.35,
                magnesium: 48.0,
                manganese: 1.0,
                phosphorus: 160.0,
                selenium: 8.0,
                zinc: 1.5
            )
        ),

        // Kartoffeln / Wedges / Gnocchi
        CommodityDefinition(
            name: "Kartoffeln",
            keywords: ["kartoffel", "gnocchi", "frühkartoffel"],
            profile: makeProfile(
                sugars: 0.8,
                addedSugars: 0.0,
                fiber: 2.1,
                saturatedFat: 0.03,
                monounsaturatedFat: 0.01,
                polyunsaturatedFat: 0.05,
                sodium: 4.0,
                salt: 0.01,
                water: 78.0,
                vitaminB1: 0.11,
                vitaminB2: 0.05,
                vitaminB3: 1.3,
                vitaminB5: 0.38,
                vitaminB6: 0.30,
                vitaminB7: 0.4,
                vitaminB11: 22.0,
                vitaminC: 17.0,
                iron: 0.8,
                potassium: 420.0,
                calcium: 10.0,
                copper: 0.15,
                magnesium: 23.0,
                manganese: 0.15,
                phosphorus: 55.0,
                zinc: 0.3
            )
        ),

        // Spinat / Greens
        CommodityDefinition(
            name: "Spinat",
            keywords: ["spinat", "spinaci", "blattspinat"],
            profile: makeProfile(
                sugars: 0.4,
                addedSugars: 0.0,
                fiber: 2.6,
                saturatedFat: 0.06,
                monounsaturatedFat: 0.02,
                polyunsaturatedFat: 0.18,
                sodium: 65.0,
                salt: 0.16,
                water: 91.5,
                vitaminA: 795.0,
                vitaminB1: 0.08,
                vitaminB2: 0.20,
                vitaminB3: 0.72,
                vitaminB5: 0.25,
                vitaminB6: 0.20,
                vitaminB7: 7.0,
                vitaminB11: 145.0,
                vitaminC: 28.0,
                vitaminE: 1.4,
                vitaminK: 483.0,
                iron: 2.7,
                potassium: 558.0,
                calcium: 99.0,
                copper: 0.13,
                magnesium: 79.0,
                manganese: 0.90,
                phosphorus: 49.0,
                zinc: 0.53
            )
        ),

        // Brokkoli / Kaisergemüse
        CommodityDefinition(
            name: "Brokkoli / Kaisergemüse",
            keywords: ["brokkoli", "kaisergemüse", "kaiserg", "blumenkohl"],
            profile: makeProfile(
                sugars: 1.7,
                addedSugars: 0.0,
                fiber: 3.0,
                saturatedFat: 0.05,
                monounsaturatedFat: 0.02,
                polyunsaturatedFat: 0.15,
                sodium: 33.0,
                salt: 0.08,
                water: 89.0,
                vitaminA: 31.0,
                vitaminB1: 0.07,
                vitaminB2: 0.12,
                vitaminB3: 0.64,
                vitaminB5: 0.57,
                vitaminB6: 0.18,
                vitaminB11: 65.0,
                vitaminC: 65.0,
                vitaminE: 0.8,
                vitaminK: 102.0,
                iron: 0.73,
                potassium: 316.0,
                calcium: 47.0,
                magnesium: 21.0,
                manganese: 0.21,
                phosphorus: 66.0,
                zinc: 0.41
            )
        ),

        // Tomaten / Gehackte Tomaten / Passata
        CommodityDefinition(
            name: "Tomaten",
            keywords: ["tomate", "tomaten", "passierte", "pizzato"],
            profile: makeProfile(
                sugars: 2.6,
                addedSugars: 0.0,
                fiber: 1.2,
                saturatedFat: 0.03,
                monounsaturatedFat: 0.03,
                polyunsaturatedFat: 0.08,
                sodium: 10.0,
                salt: 0.03,
                water: 94.0,
                vitaminA: 42.0,
                vitaminB1: 0.04,
                vitaminB2: 0.02,
                vitaminB3: 0.60,
                vitaminB5: 0.25,
                vitaminB6: 0.08,
                vitaminB11: 15.0,
                vitaminC: 14.0,
                vitaminE: 0.54,
                vitaminK: 7.9,
                iron: 0.3,
                potassium: 237.0,
                calcium: 10.0,
                magnesium: 11.0,
                phosphorus: 24.0,
                zinc: 0.17
            )
        ),

        // Bananen
        CommodityDefinition(
            name: "Bananen",
            keywords: ["banane", "bananen"],
            profile: makeProfile(
                sugars: 12.2,
                addedSugars: 0.0,
                fiber: 2.6,
                saturatedFat: 0.11,
                monounsaturatedFat: 0.03,
                polyunsaturatedFat: 0.07,
                sodium: 1.0,
                salt: 0.01,
                water: 75.0,
                vitaminA: 3.0,
                vitaminB1: 0.03,
                vitaminB2: 0.07,
                vitaminB3: 0.67,
                vitaminB5: 0.33,
                vitaminB6: 0.37,
                vitaminB11: 20.0,
                vitaminC: 8.7,
                vitaminE: 0.10,
                vitaminK: 0.5,
                iron: 0.26,
                potassium: 358.0,
                calcium: 5.0,
                magnesium: 27.0,
                manganese: 0.27,
                phosphorus: 22.0,
                zinc: 0.15
            )
        ),

        // Äpfel
        CommodityDefinition(
            name: "Äpfel",
            keywords: ["apfel", "äpfel", "braeburn"],
            profile: makeProfile(
                sugars: 10.4,
                addedSugars: 0.0,
                fiber: 2.4,
                saturatedFat: 0.03,
                monounsaturatedFat: 0.01,
                polyunsaturatedFat: 0.05,
                sodium: 1.0,
                salt: 0.01,
                water: 85.5,
                vitaminA: 3.0,
                vitaminB1: 0.02,
                vitaminB2: 0.03,
                vitaminB3: 0.1,
                vitaminB6: 0.04,
                vitaminB11: 3.0,
                vitaminC: 4.6,
                vitaminE: 0.18,
                vitaminK: 2.2,
                iron: 0.12,
                potassium: 107.0,
                calcium: 6.0,
                magnesium: 5.0,
                phosphorus: 11.0
            )
        ),

        // Avocado
        CommodityDefinition(
            name: "Avocado",
            keywords: ["avocado"],
            profile: makeProfile(
                sugars: 0.7,
                addedSugars: 0.0,
                fiber: 6.7,
                saturatedFat: 2.1,
                monounsaturatedFat: 9.8,
                polyunsaturatedFat: 1.8,
                sodium: 7.0,
                salt: 0.02,
                water: 73.0,
                vitaminA: 7.0,
                vitaminB1: 0.07,
                vitaminB2: 0.13,
                vitaminB3: 1.74,
                vitaminB5: 1.39,
                vitaminB6: 0.26,
                vitaminB11: 81.0,
                vitaminC: 10.0,
                vitaminE: 2.07,
                vitaminK: 21.0,
                iron: 0.55,
                potassium: 485.0,
                calcium: 12.0,
                copper: 0.19,
                magnesium: 29.0,
                phosphorus: 52.0,
                zinc: 0.64
            )
        ),

        // Basmati / Parboiled Reis
        CommodityDefinition(
            name: "Reis",
            keywords: ["reis", "basmati", "parboiled"],
            profile: makeProfile(
                sugars: 0.1,
                addedSugars: 0.0,
                fiber: 1.3,
                saturatedFat: 0.2,
                monounsaturatedFat: 0.3,
                polyunsaturatedFat: 0.3,
                sodium: 5.0,
                salt: 0.01,
                water: 12.0,
                vitaminB1: 0.15,
                vitaminB2: 0.03,
                vitaminB3: 1.6,
                vitaminB5: 0.7,
                vitaminB6: 0.16,
                vitaminB11: 8.0,
                vitaminE: 0.1,
                iron: 0.8,
                potassium: 115.0,
                calcium: 10.0,
                magnesium: 25.0,
                manganese: 1.1,
                phosphorus: 115.0,
                selenium: 15.1,
                zinc: 1.1
            )
        ),

        // Feta / Hirtenkäse / Gouda
        CommodityDefinition(
            name: "Käse / Feta",
            keywords: ["feta", "gouda", "mozzarella", "hirtenkäse", "reibekäse"],
            profile: makeProfile(
                sugars: 0.5,
                addedSugars: 0.0,
                fiber: 0.0,
                saturatedFat: 9.0,
                monounsaturatedFat: 3.5,
                polyunsaturatedFat: 0.5,
                cholesterol: 68.0,
                sodium: 600.0,
                salt: 1.5,
                water: 55.0,
                vitaminA: 180.0,
                vitaminB1: 0.03,
                vitaminB2: 0.40,
                vitaminB3: 0.20,
                vitaminB5: 0.65,
                vitaminB6: 0.08,
                vitaminB11: 32.0,
                vitaminB12: 1.69,
                vitaminD: 0.4,
                vitaminK: 1.8,
                iron: 0.65,
                potassium: 62.0,
                calcium: 493.0,
                magnesium: 19.0,
                phosphorus: 337.0,
                selenium: 15.0,
                zinc: 2.88
            )
        ),

        // TK-Beeren / Beerenmischung
        CommodityDefinition(
            name: "Beeren",
            keywords: ["beere", "beeren", "tk-beeren", "heidelbeere", "himbeere"],
            profile: makeProfile(
                sugars: 5.5,
                addedSugars: 0.0,
                fiber: 4.5,
                saturatedFat: 0.02,
                monounsaturatedFat: 0.02,
                polyunsaturatedFat: 0.20,
                sodium: 2.0,
                salt: 0.01,
                water: 86.0,
                vitaminA: 4.0,
                vitaminB1: 0.03,
                vitaminB2: 0.04,
                vitaminB3: 0.4,
                vitaminB6: 0.06,
                vitaminB11: 25.0,
                vitaminC: 30.0,
                vitaminE: 0.7,
                vitaminK: 15.0,
                iron: 0.6,
                potassium: 160.0,
                calcium: 22.0,
                magnesium: 18.0,
                manganese: 0.67,
                phosphorus: 25.0,
                zinc: 0.35
            )
        ),

        // Erdnussbutter / Cashews / Nüsse
        CommodityDefinition(
            name: "Nüsse / Erdnussbutter",
            keywords: ["erdnuss", "peanut", "cashew", "mandel", "nuss", "leinsamen"],
            profile: makeProfile(
                sugars: 4.0,
                addedSugars: 0.0,
                fiber: 7.0,
                saturatedFat: 10.0,
                monounsaturatedFat: 24.0,
                polyunsaturatedFat: 14.0,
                sodium: 15.0,
                salt: 0.04,
                water: 2.0,
                vitaminB1: 0.42,
                vitaminB2: 0.10,
                vitaminB3: 13.0,
                vitaminB5: 2.1,
                vitaminB6: 0.50,
                vitaminB7: 34.0,
                vitaminB11: 110.0,
                vitaminE: 6.8,
                iron: 2.5,
                potassium: 650.0,
                calcium: 45.0,
                copper: 0.67,
                magnesium: 170.0,
                manganese: 1.5,
                phosphorus: 360.0,
                selenium: 7.5,
                zinc: 3.2
            )
        ),

        // Rote Bete / Rote-Bete-Saft (NO3 Nitrat Booster)
        CommodityDefinition(
            name: "Rote Bete",
            keywords: ["rote bete", "rote-bete", "beetroot"],
            profile: makeProfile(
                sugars: 7.0,
                addedSugars: 0.0,
                fiber: 2.8,
                saturatedFat: 0.03,
                monounsaturatedFat: 0.03,
                polyunsaturatedFat: 0.06,
                sodium: 78.0,
                salt: 0.20,
                water: 87.5,
                vitaminB1: 0.03,
                vitaminB2: 0.04,
                vitaminB3: 0.33,
                vitaminB5: 0.16,
                vitaminB6: 0.07,
                vitaminB11: 109.0,
                vitaminC: 4.9,
                iron: 0.80,
                potassium: 325.0,
                calcium: 16.0,
                copper: 0.08,
                magnesium: 23.0,
                manganese: 0.33,
                phosphorus: 40.0,
                zinc: 0.35
            )
        )
    ]

    /// Enriches a given NutritionalProfile with laboratory-verified commodity data
    /// whenever the manufacturer label / API returned zero or nil for micronutrients.
    public static func enrich(
        profile: NutritionalProfile?,
        forProductName name: String,
        brand: String? = nil
    ) -> NutritionalProfile {
        var result = profile ?? NutritionalProfile()
        let searchString = "\(name) \(brand ?? "")".lowercased()

        // Find best matching commodity definition
        guard let matched = commodities.first(where: { def in
            def.keywords.contains(where: { searchString.contains($0) })
        }) else {
            return result
        }

        let ref = matched.profile

        // Detailed Carbs & Fats
        if (result.sugars == nil || result.sugars == 0) { result.sugars = ref.sugars }
        if (result.addedSugars == nil) { result.addedSugars = ref.addedSugars }
        if (result.fiber == nil || result.fiber == 0) { result.fiber = ref.fiber }
        if (result.saturatedFat == nil || result.saturatedFat == 0) { result.saturatedFat = ref.saturatedFat }
        if (result.monounsaturatedFat == nil || result.monounsaturatedFat == 0) { result.monounsaturatedFat = ref.monounsaturatedFat }
        if (result.polyunsaturatedFat == nil || result.polyunsaturatedFat == 0) { result.polyunsaturatedFat = ref.polyunsaturatedFat }
        if (result.transFat == nil) { result.transFat = ref.transFat }

        // Components
        if (result.cholesterol == nil || result.cholesterol == 0) { result.cholesterol = ref.cholesterol }
        if (result.sodium == nil || result.sodium == 0) { result.sodium = ref.sodium }
        if (result.salt == nil || result.salt == 0) { result.salt = ref.salt }
        if (result.water == nil || result.water == 0) { result.water = ref.water }

        // Vitamins
        if (result.vitaminA == nil || result.vitaminA == 0) { result.vitaminA = ref.vitaminA }
        if (result.vitaminB1 == nil || result.vitaminB1 == 0) { result.vitaminB1 = ref.vitaminB1 }
        if (result.vitaminB2 == nil || result.vitaminB2 == 0) { result.vitaminB2 = ref.vitaminB2 }
        if (result.vitaminB3 == nil || result.vitaminB3 == 0) { result.vitaminB3 = ref.vitaminB3 }
        if (result.vitaminB5 == nil || result.vitaminB5 == 0) { result.vitaminB5 = ref.vitaminB5 }
        if (result.vitaminB6 == nil || result.vitaminB6 == 0) { result.vitaminB6 = ref.vitaminB6 }
        if (result.vitaminB7 == nil || result.vitaminB7 == 0) { result.vitaminB7 = ref.vitaminB7 }
        if (result.vitaminB11 == nil || result.vitaminB11 == 0) { result.vitaminB11 = ref.vitaminB11 }
        if (result.vitaminB12 == nil || result.vitaminB12 == 0) { result.vitaminB12 = ref.vitaminB12 }
        if (result.vitaminC == nil || result.vitaminC == 0) { result.vitaminC = ref.vitaminC }
        if (result.vitaminD == nil || result.vitaminD == 0) { result.vitaminD = ref.vitaminD }
        if (result.vitaminE == nil || result.vitaminE == 0) { result.vitaminE = ref.vitaminE }
        if (result.vitaminK == nil || result.vitaminK == 0) { result.vitaminK = ref.vitaminK }

        // Minerals & Trace Elements
        if (result.calcium == nil || result.calcium == 0) { result.calcium = ref.calcium }
        if (result.magnesium == nil || result.magnesium == 0) { result.magnesium = ref.magnesium }
        if (result.iron == nil || result.iron == 0) { result.iron = ref.iron }
        if (result.zinc == nil || result.zinc == 0) { result.zinc = ref.zinc }
        if (result.potassium == nil || result.potassium == 0) { result.potassium = ref.potassium }
        if (result.phosphorus == nil || result.phosphorus == 0) { result.phosphorus = ref.phosphorus }
        if (result.copper == nil || result.copper == 0) { result.copper = ref.copper }
        if (result.manganese == nil || result.manganese == 0) { result.manganese = ref.manganese }
        if (result.iodine == nil || result.iodine == 0) { result.iodine = ref.iodine }
        if (result.selenium == nil || result.selenium == 0) { result.selenium = ref.selenium }
        if (result.chloride == nil || result.chloride == 0) { result.chloride = ref.chloride }
        if (result.chromium == nil || result.chromium == 0) { result.chromium = ref.chromium }
        if (result.molybdenum == nil || result.molybdenum == 0) { result.molybdenum = ref.molybdenum }
        if (result.fluoride == nil || result.fluoride == 0) { result.fluoride = ref.fluoride }
        if (result.choline == nil || result.choline == 0) { result.choline = ref.choline }

        return result
    }

    // MARK: - Standard Macronutrient Imputation (BLS & USDA Foundation Standards)
    public static func standardMacros(forProductName name: String) -> (kcal: Double, protein: Double, carbs: Double, fat: Double, fiber: Double)? {
        let n = name.lowercased()
        if n.contains("hafer") || n.contains("oat") || n.contains("flocken") || n.contains("granola") || n.contains("müsli") {
            return (kcal: 370.0, protein: 13.5, carbs: 58.7, fat: 7.0, fiber: 10.0)
        }
        if n.contains("quark") || n.contains("skyr") || n.contains("speisequark") {
            return (kcal: 68.0, protein: 12.0, carbs: 4.0, fat: 0.3, fiber: 0.0)
        }
        if n.contains("hähnchen") || n.contains("ha-brust") || n.contains("hühnchen") || n.contains("pute") || n.contains("geflügel") || n.contains("chicken") || n.contains("brustfilet") {
            return (kcal: 105.0, protein: 23.0, carbs: 0.0, fat: 1.5, fiber: 0.0)
        }
        if (n.contains("eier") || n.contains("ei ") || n.hasPrefix("ei ") || n.contains("hühnerei") || n.contains("bodenhaltung")) && !n.contains("fleisch") && !n.contains("reis") && !n.contains("nudel") && !n.contains("teig") {
            return (kcal: 140.0, protein: 12.5, carbs: 0.7, fat: 9.5, fiber: 0.0)
        }
        if n.contains("thunf") || n.contains("tuna") {
            return (kcal: 110.0, protein: 25.5, carbs: 0.0, fat: 0.8, fiber: 0.0)
        }
        if n.contains("linse") {
            return (kcal: 334.0, protein: 19.0, carbs: 54.0, fat: 2.1, fiber: 11.0)
        }
        if n.contains("kicher") {
            return (kcal: 120.0, protein: 7.0, carbs: 17.0, fat: 2.0, fiber: 5.0)
        }
        if n.contains("bohne") || n.contains("kidney") {
            return (kcal: 110.0, protein: 8.5, carbs: 15.0, fat: 0.6, fiber: 6.5)
        }
        if n.contains("kartoffel") || n.contains("gnocchi") {
            return (kcal: 75.0, protein: 2.0, carbs: 16.0, fat: 0.1, fiber: 2.1)
        }
        if n.contains("spinat") {
            return (kcal: 23.0, protein: 2.8, carbs: 0.8, fat: 0.4, fiber: 2.2)
        }
        if n.contains("brokkoli") || n.contains("kaiserg") {
            return (kcal: 34.0, protein: 2.8, carbs: 4.0, fat: 0.4, fiber: 3.0)
        }
        if n.contains("tomate") || n.contains("passata") || n.contains("pizzato") {
            return (kcal: 22.0, protein: 1.2, carbs: 3.5, fat: 0.2, fiber: 1.2)
        }
        if n.contains("kraut") || n.contains("sauerkraut") {
            return (kcal: 19.0, protein: 1.1, carbs: 1.5, fat: 0.2, fiber: 2.5)
        }
        if n.contains("reis") || n.contains("basmati") {
            return (kcal: 350.0, protein: 8.0, carbs: 77.0, fat: 1.0, fiber: 1.5)
        }
        if n.contains("nudel") || n.contains("pasta") || n.contains("fusilli") || n.contains("penne") || n.contains("spaghetti") {
            return (kcal: 350.0, protein: 13.0, carbs: 65.0, fat: 2.0, fiber: 3.5)
        }
        if n.contains("brot") || n.contains("toast") || n.contains("sandwich") || n.contains("wrap") {
            return (kcal: 220.0, protein: 8.5, carbs: 42.0, fat: 1.5, fiber: 6.0)
        }
        if n.contains("käse") || n.contains("gouda") || n.contains("feta") || n.contains("mozzarella") {
            return (kcal: 260.0, protein: 25.0, carbs: 1.0, fat: 17.0, fiber: 0.0)
        }
        if n.contains("erdnuss") || n.contains("peanut") || n.contains("mandel") || n.contains("cashew") || n.contains("nuss") {
            return (kcal: 600.0, protein: 26.0, carbs: 15.0, fat: 49.0, fiber: 7.5)
        }
        if n.contains("butter") && !n.contains("erdnuss") {
            return (kcal: 740.0, protein: 0.7, carbs: 0.7, fat: 82.0, fiber: 0.0)
        }
        if n.contains("apfel") || n.contains("äpfel") {
            return (kcal: 52.0, protein: 0.3, carbs: 11.5, fat: 0.2, fiber: 2.4)
        }
        if n.contains("banan") {
            return (kcal: 89.0, protein: 1.1, carbs: 20.0, fat: 0.3, fiber: 2.6)
        }
        if n.contains("beere") {
            return (kcal: 45.0, protein: 1.0, carbs: 8.5, fat: 0.5, fiber: 4.5)
        }
        if n.contains("honig") {
            return (kcal: 320.0, protein: 0.5, carbs: 80.0, fat: 0.0, fiber: 0.0)
        }
        if n.contains("rote bete") || n.contains("beetroot") {
            return (kcal: 43.0, protein: 1.6, carbs: 9.6, fat: 0.2, fiber: 2.8)
        }
        return nil
    }
}
