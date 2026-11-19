import Foundation

public struct NutritionalProfile: Codable, Hashable {
    // Carbohydrates detailed (g / 100g)
    public var sugars: Double?
    public var addedSugars: Double?
    public var fiber: Double?

    // Fats detailed (g / 100g)
    public var saturatedFat: Double?
    public var monounsaturatedFat: Double?
    public var polyunsaturatedFat: Double?
    public var transFat: Double?

    // Other components (g or mg / 100g)
    public var alcohol: Double? // g
    public var cholesterol: Double? // mg
    public var sodium: Double? // mg
    public var salt: Double? // g
    public var water: Double? // g

    // Vitamins (mg or mcg / 100g)
    public var vitaminA: Double? // mcg
    public var vitaminB1: Double? // mg (Thiamin)
    public var vitaminB2: Double? // mg (Riboflavin)
    public var vitaminB3: Double? // mg (Niacin)
    public var vitaminB5: Double? // mg (Pantothensäure)
    public var vitaminB6: Double? // mg (Pyridoxin)
    public var vitaminB7: Double? // mcg (Biotin)
    public var vitaminB11: Double? // mcg (Folsäure / Folat)
    public var vitaminB12: Double? // mcg (Cobalamin)
    public var vitaminC: Double? // mg
    public var vitaminD: Double? // mcg
    public var vitaminE: Double? // mg
    public var vitaminK: Double? // mcg

    // Minerals & Trace Elements (mg or mcg / 100g)
    public var arsenic: Double? // mcg (Arsen)
    public var boron: Double? // mg (Bor)
    public var chloride: Double? // mg (Chlorid)
    public var choline: Double? // mg (Cholin)
    public var chromium: Double? // mcg (Chrom)
    public var iron: Double? // mg (Eisen)
    public var fluorine: Double? // mg (Fluor)
    public var fluoride: Double? // mg (Fluorid)
    public var iodine: Double? // mcg (Jod)
    public var potassium: Double? // mg (Kalium)
    public var calcium: Double? // mg (Kalzium)
    public var cobalt: Double? // mcg (Kobalt)
    public var copper: Double? // mg (Kupfer)
    public var magnesium: Double? // mg (Magnesium)
    public var manganese: Double? // mg (Mangan)
    public var molybdenum: Double? // mcg (Molybdän)
    public var phosphorus: Double? // mg (Phosphor)
    public var rubidium: Double? // mcg (Rubidium)
    public var sulfur: Double? // mg (Schwefel)
    public var selenium: Double? // mcg (Selen)
    public var silicon: Double? // mg (Silizium)
    public var vanadium: Double? // mcg (Vanadium)
    public var zinc: Double? // mg (Zink)
    public var tin: Double? // mcg (Zinn)

    public init(
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
        arsenic: Double? = nil,
        boron: Double? = nil,
        chloride: Double? = nil,
        choline: Double? = nil,
        chromium: Double? = nil,
        iron: Double? = nil,
        fluorine: Double? = nil,
        fluoride: Double? = nil,
        iodine: Double? = nil,
        potassium: Double? = nil,
        calcium: Double? = nil,
        cobalt: Double? = nil,
        copper: Double? = nil,
        magnesium: Double? = nil,
        manganese: Double? = nil,
        molybdenum: Double? = nil,
        phosphorus: Double? = nil,
        rubidium: Double? = nil,
        sulfur: Double? = nil,
        selenium: Double? = nil,
        silicon: Double? = nil,
        vanadium: Double? = nil,
        zinc: Double? = nil,
        tin: Double? = nil
    ) {
        self.sugars = sugars
        self.addedSugars = addedSugars
        self.fiber = fiber
        self.saturatedFat = saturatedFat
        self.monounsaturatedFat = monounsaturatedFat
        self.polyunsaturatedFat = polyunsaturatedFat
        self.transFat = transFat
        self.alcohol = alcohol
        self.cholesterol = cholesterol
        self.sodium = sodium
        self.salt = salt
        self.water = water
        self.vitaminA = vitaminA
        self.vitaminB1 = vitaminB1
        self.vitaminB2 = vitaminB2
        self.vitaminB3 = vitaminB3
        self.vitaminB5 = vitaminB5
        self.vitaminB6 = vitaminB6
        self.vitaminB7 = vitaminB7
        self.vitaminB11 = vitaminB11
        self.vitaminB12 = vitaminB12
        self.vitaminC = vitaminC
        self.vitaminD = vitaminD
        self.vitaminE = vitaminE
        self.vitaminK = vitaminK
        self.arsenic = arsenic
        self.boron = boron
        self.chloride = chloride
        self.choline = choline
        self.chromium = chromium
        self.iron = iron
        self.fluorine = fluorine
        self.fluoride = fluoride
        self.iodine = iodine
        self.potassium = potassium
        self.calcium = calcium
        self.cobalt = cobalt
        self.copper = copper
        self.magnesium = magnesium
        self.manganese = manganese
        self.molybdenum = molybdenum
        self.phosphorus = phosphorus
        self.rubidium = rubidium
        self.sulfur = sulfur
        self.selenium = selenium
        self.silicon = silicon
        self.vanadium = vanadium
        self.zinc = zinc
        self.tin = tin
    }

    public mutating func add(scaledFrom other: NutritionalProfile, ratio: Double) {
        guard ratio > 0 else { return }

        if let v = other.sugars { self.sugars = (self.sugars ?? 0.0) + (v * ratio) }
        if let v = other.addedSugars { self.addedSugars = (self.addedSugars ?? 0.0) + (v * ratio) }
        if let v = other.fiber { self.fiber = (self.fiber ?? 0.0) + (v * ratio) }

        if let v = other.saturatedFat { self.saturatedFat = (self.saturatedFat ?? 0.0) + (v * ratio) }
        if let v = other.monounsaturatedFat { self.monounsaturatedFat = (self.monounsaturatedFat ?? 0.0) + (v * ratio) }
        if let v = other.polyunsaturatedFat { self.polyunsaturatedFat = (self.polyunsaturatedFat ?? 0.0) + (v * ratio) }
        if let v = other.transFat { self.transFat = (self.transFat ?? 0.0) + (v * ratio) }

        if let v = other.alcohol { self.alcohol = (self.alcohol ?? 0.0) + (v * ratio) }
        if let v = other.cholesterol { self.cholesterol = (self.cholesterol ?? 0.0) + (v * ratio) }
        if let v = other.sodium { self.sodium = (self.sodium ?? 0.0) + (v * ratio) }
        if let v = other.salt { self.salt = (self.salt ?? 0.0) + (v * ratio) }
        if let v = other.water { self.water = (self.water ?? 0.0) + (v * ratio) }

        if let v = other.vitaminA { self.vitaminA = (self.vitaminA ?? 0.0) + (v * ratio) }
        if let v = other.vitaminB1 { self.vitaminB1 = (self.vitaminB1 ?? 0.0) + (v * ratio) }
        if let v = other.vitaminB2 { self.vitaminB2 = (self.vitaminB2 ?? 0.0) + (v * ratio) }
        if let v = other.vitaminB3 { self.vitaminB3 = (self.vitaminB3 ?? 0.0) + (v * ratio) }
        if let v = other.vitaminB5 { self.vitaminB5 = (self.vitaminB5 ?? 0.0) + (v * ratio) }
        if let v = other.vitaminB6 { self.vitaminB6 = (self.vitaminB6 ?? 0.0) + (v * ratio) }
        if let v = other.vitaminB7 { self.vitaminB7 = (self.vitaminB7 ?? 0.0) + (v * ratio) }
        if let v = other.vitaminB11 { self.vitaminB11 = (self.vitaminB11 ?? 0.0) + (v * ratio) }
        if let v = other.vitaminB12 { self.vitaminB12 = (self.vitaminB12 ?? 0.0) + (v * ratio) }
        if let v = other.vitaminC { self.vitaminC = (self.vitaminC ?? 0.0) + (v * ratio) }
        if let v = other.vitaminD { self.vitaminD = (self.vitaminD ?? 0.0) + (v * ratio) }
        if let v = other.vitaminE { self.vitaminE = (self.vitaminE ?? 0.0) + (v * ratio) }
        if let v = other.vitaminK { self.vitaminK = (self.vitaminK ?? 0.0) + (v * ratio) }

        if let v = other.arsenic { self.arsenic = (self.arsenic ?? 0.0) + (v * ratio) }
        if let v = other.boron { self.boron = (self.boron ?? 0.0) + (v * ratio) }
        if let v = other.chloride { self.chloride = (self.chloride ?? 0.0) + (v * ratio) }
        if let v = other.choline { self.choline = (self.choline ?? 0.0) + (v * ratio) }
        if let v = other.chromium { self.chromium = (self.chromium ?? 0.0) + (v * ratio) }
        if let v = other.iron { self.iron = (self.iron ?? 0.0) + (v * ratio) }
        if let v = other.fluorine { self.fluorine = (self.fluorine ?? 0.0) + (v * ratio) }
        if let v = other.fluoride { self.fluoride = (self.fluoride ?? 0.0) + (v * ratio) }
        if let v = other.iodine { self.iodine = (self.iodine ?? 0.0) + (v * ratio) }
        if let v = other.potassium { self.potassium = (self.potassium ?? 0.0) + (v * ratio) }
        if let v = other.calcium { self.calcium = (self.calcium ?? 0.0) + (v * ratio) }
        if let v = other.cobalt { self.cobalt = (self.cobalt ?? 0.0) + (v * ratio) }
        if let v = other.copper { self.copper = (self.copper ?? 0.0) + (v * ratio) }
        if let v = other.magnesium { self.magnesium = (self.magnesium ?? 0.0) + (v * ratio) }
        if let v = other.manganese { self.manganese = (self.manganese ?? 0.0) + (v * ratio) }
        if let v = other.molybdenum { self.molybdenum = (self.molybdenum ?? 0.0) + (v * ratio) }
        if let v = other.phosphorus { self.phosphorus = (self.phosphorus ?? 0.0) + (v * ratio) }
        if let v = other.rubidium { self.rubidium = (self.rubidium ?? 0.0) + (v * ratio) }
        if let v = other.sulfur { self.sulfur = (self.sulfur ?? 0.0) + (v * ratio) }
        if let v = other.selenium { self.selenium = (self.selenium ?? 0.0) + (v * ratio) }
        if let v = other.silicon { self.silicon = (self.silicon ?? 0.0) + (v * ratio) }
        if let v = other.vanadium { self.vanadium = (self.vanadium ?? 0.0) + (v * ratio) }
        if let v = other.zinc { self.zinc = (self.zinc ?? 0.0) + (v * ratio) }
        if let v = other.tin { self.tin = (self.tin ?? 0.0) + (v * ratio) }
    }
}
