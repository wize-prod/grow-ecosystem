import Foundation

public struct TemplateIngredient: Identifiable, Codable {
    public var id: String
    public var pantryItemId: String
    public var name: String
    public var grams: Double
    public var unit: String?
    public var rawAmount: Double?

    public init(id: String = UUID().uuidString, pantryItemId: String, name: String, grams: Double, unit: String? = nil, rawAmount: Double? = nil) {
        self.id = id
        self.pantryItemId = pantryItemId
        self.name = name
        self.grams = grams
        self.unit = unit
        self.rawAmount = rawAmount
    }

    public var displayUnit: String {
        return unit ?? "g"
    }

    public var displayAmount: Double {
        return rawAmount ?? grams
    }

    public static func toNormalizedGrams(amount: Double, unit: String) -> Double {
        switch unit.lowercased() {
        case "kg":
            return amount * 1000.0
        case "l":
            return amount * 1000.0
        case "mg":
            return amount / 1000.0
        case "ml", "g":
            return amount
        default:
            return amount
        }
    }
}

public struct MealTemplate: Identifiable, Codable {
    public var id: String
    public var name: String
    public var category: String
    public var ingredients: [TemplateIngredient]
    public var instructions: [String]
    public var imageFileName: String?
    public var prepTimeMinutes: Int
    public var cookTimeMinutes: Int
    public var servings: Int
    public var cuisineType: String?
    public var equipment: [String]
    public var longPreparationType: String?
    public var imageUrl: String?

    public var totalTimeMinutes: Int {
        return max(1, prepTimeMinutes + cookTimeMinutes)
    }

    public var cleanName: String {
        var slice = name[...]
        if let first = slice.first, first.isNumber {
            while let c = slice.first, c.isNumber {
                slice.removeFirst()
            }
            while let c = slice.first, c == "." || c == " " || c == "\t" || c == "-" {
                slice.removeFirst()
            }
            return String(slice)
        }
        return name
    }

    public var isLongPrep: Bool {
        if let longPrep = longPreparationType, !longPrep.trimmingCharacters(in: .whitespaces).isEmpty {
            return true
        }
        let lName = name.lowercased()
        if lName.contains("marinier") || lName.contains("marinate") || lName.contains("pökel") ||
           lName.contains("curing") || lName.contains("brining") || lName.contains("schmor") ||
           lName.contains("brais") || lName.contains("ferment") || lName.contains("slow cook") {
            return true
        }
        for inst in instructions {
            let lInst = inst.lowercased()
            if lInst.contains("marinier") ||
               lInst.contains("marinate") ||
               lInst.contains("pökel") ||
               lInst.contains("curing") ||
               lInst.contains("brining") ||
               lInst.contains("schmor") ||
               lInst.contains("brais") ||
               lInst.contains("ferment") ||
               lInst.contains("reifen") ||
               lInst.contains("gehen lassen") ||
               lInst.contains("proofing") ||
               lInst.contains("slow cook") {
                return true
            }
        }
        return false
    }

    public init(
        id: String = UUID().uuidString,
        name: String,
        category: String,
        ingredients: [TemplateIngredient],
        instructions: [String] = [],
        imageFileName: String? = nil,
        prepTimeMinutes: Int = 10,
        cookTimeMinutes: Int = 15,
        servings: Int = 1,
        cuisineType: String? = nil,
        equipment: [String] = [],
        longPreparationType: String? = nil,
        imageUrl: String? = nil
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.ingredients = ingredients
        self.instructions = instructions
        self.imageFileName = imageFileName
        self.prepTimeMinutes = prepTimeMinutes
        self.cookTimeMinutes = cookTimeMinutes
        self.servings = max(1, servings)
        self.cuisineType = cuisineType
        self.equipment = equipment
        self.longPreparationType = longPreparationType
        self.imageUrl = imageUrl
    }

    enum CodingKeys: String, CodingKey {
        case id, name, category, ingredients, instructions, imageFileName
        case prepTimeMinutes, cookTimeMinutes, servings
        case cuisineType, equipment, longPreparationType, imageUrl
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Rezept"
        category = try container.decodeIfPresent(String.self, forKey: .category) ?? "Mittagessen"
        ingredients = try container.decodeIfPresent([TemplateIngredient].self, forKey: .ingredients) ?? []
        instructions = try container.decodeIfPresent([String].self, forKey: .instructions) ?? []
        imageFileName = try container.decodeIfPresent(String.self, forKey: .imageFileName)
        prepTimeMinutes = try container.decodeIfPresent(Int.self, forKey: .prepTimeMinutes) ?? 10
        cookTimeMinutes = try container.decodeIfPresent(Int.self, forKey: .cookTimeMinutes) ?? 15
        servings = try container.decodeIfPresent(Int.self, forKey: .servings) ?? 1
        cuisineType = try container.decodeIfPresent(String.self, forKey: .cuisineType)
        equipment = try container.decodeIfPresent([String].self, forKey: .equipment) ?? []
        longPreparationType = try container.decodeIfPresent(String.self, forKey: .longPreparationType)
        imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
    }

    public var standardizedCategory: String {
        let lName = name.lowercased()
        let lCat = category.lowercased()

        if lCat.contains("frühstück") || lCat.contains("breakfast") || lName.contains("haferflocken") || lName.contains("berry fluff") || lName.contains("french toast") || lName.contains("frühstück") {
            return "Frühstück"
        } else if lCat.contains("snack") || lName.contains("shake") || lName.contains("riegel") || lName.contains("snack") {
            return "Snack"
        } else if lCat.contains("mittag") || lCat.contains("roast") || lName.contains("teriyaki") || lName.contains("rindfleisch") || lName.contains("pfanne") || lName.contains("mittag") {
            return "Mittagessen"
        } else if lCat.contains("abend") || lCat.contains("soup") || lCat.contains("stew") || lName.contains("dal") || lName.contains("suppe") || lName.contains("abend") {
            return "Abendessen"
        } else {
            return "Mittagessen"
        }
    }

    public var categoryIconName: String {
        switch standardizedCategory {
        case "Frühstück":
            return "cup.and.saucer.fill"
        case "Mittagessen":
            return "fork.knife"
        case "Abendessen":
            return "moon.stars.fill"
        case "Snack":
            return "takeoutbag.and.cup.and.straw.fill"
        default:
            return "leaf.fill"
        }
    }
}

