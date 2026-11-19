import Foundation

public struct CuisineRegion: Identifiable, Hashable {
    public var id: String { name }
    public let name: String
    public let subCuisines: [String]

    public init(name: String, subCuisines: [String]) {
        self.name = name
        self.subCuisines = subCuisines
    }
}

public struct CuisineTaxonomy {
    public static let regions: [CuisineRegion] = [
        CuisineRegion(
            name: "Afrikanisch",
            subCuisines: [
                "Zentralafrikanisch",
                "Ostafrikanisch",
                "Nordafrikanisch",
                "Südafrikanisch",
                "Westafrikanisch"
            ]
        ),
        CuisineRegion(
            name: "Asiatisch",
            subCuisines: [
                "Zentralasiatisch",
                "Ostasiatisch",
                "Südasiatisch",
                "Südostasiatisch",
                "Koreanisch",
                "Chinesisch",
                "Japanisch",
                "Thailändisch",
                "Vietnamesisch",
                "Indisch"
            ]
        ),
        CuisineRegion(
            name: "Karibisch",
            subCuisines: [
                "Kubanisch",
                "Guyanisch",
                "Jamaikanisch",
                "Puerto-Ricanisch"
            ]
        ),
        CuisineRegion(
            name: "Europäisch",
            subCuisines: [
                "Osteuropäisch",
                "Nordeuropäisch",
                "Südeuropäisch",
                "Westeuropäisch",
                "Französisch",
                "Deutsch",
                "Italienisch",
                "Griechisch",
                "Spanisch"
            ]
        ),
        CuisineRegion(
            name: "Mittelamerikanisch",
            subCuisines: [
                "Salvadorianisch",
                "Guatemaltekisch",
                "Costa-Ricanisch"
            ]
        ),
        CuisineRegion(
            name: "Nahöstlich",
            subCuisines: [
                "Armenisch",
                "Iranisch & Persisch",
                "Türkisch",
                "Libanesisch"
            ]
        ),
        CuisineRegion(
            name: "Nordamerikanisch",
            subCuisines: [
                "Kanadisch",
                "Indigen / Native American",
                "Mexikanisch",
                "US-Amerikanisch / Soul Food"
            ]
        ),
        CuisineRegion(
            name: "Ozeanisch",
            subCuisines: [
                "Australisch",
                "Neuseeländisch",
                "Polynesisch & Samoanisch"
            ]
        ),
        CuisineRegion(
            name: "Südamerikanisch",
            subCuisines: [
                "Brasilianisch",
                "Kolumbianisch",
                "Peruanisch",
                "Venezolanisch",
                "Argentinisch"
            ]
        )
    ]

    public static var allSubCuisines: [String] {
        return regions.flatMap { $0.subCuisines }
    }

    public static func matchRegion(for subCuisine: String) -> String? {
        for region in regions {
            if region.subCuisines.contains(where: { $0.caseInsensitiveCompare(subCuisine) == .orderedSame }) {
                return region.name
            }
        }
        return nil
    }

    private static var memoizedCuisine: [String: String] = [:]
    private static let lock = NSLock()

    /// Autodetects potential cuisine from recipe name and ingredients
    public static func inferCuisine(name: String, ingredients: [String]) -> String {
        lock.lock()
        if let cached = memoizedCuisine[name] {
            lock.unlock()
            return cached
        }
        lock.unlock()

        let text = (name + " " + ingredients.joined(separator: " ")).lowercased()
        let result: String

        if text.contains("teriyaki") || text.contains("mie") || text.contains("wok") || text.contains("ramen") || text.contains("soja") || text.contains("pak choi") {
            if text.contains("mie") || text.contains("peking") || text.contains("süß-sauer") { result = "Chinesisch" }
            else if text.contains("kimchi") || text.contains("bibimbap") || text.contains("bulgogi") { result = "Koreanisch" }
            else if text.contains("curry") || text.contains("dal") || text.contains("garam") || text.contains("tikka") { result = "Indisch" }
            else { result = "Ostasiatisch" }
        } else if text.contains("taco") || text.contains("burrito") || text.contains("quesadilla") || text.contains("jalapeno") || text.contains("guacamole") || text.contains("fajita") {
            result = "Mexikanisch"
        } else if text.contains("jerk") || text.contains("plantain") || text.contains("kochbanane") || text.contains("jamaic") {
            result = "Jamaikanisch"
        } else if text.contains("fufu") || text.contains("jollof") || text.contains("erdnusssuppe") || text.contains("egusi") {
            result = "Westafrikanisch"
        } else if text.contains("couscous") || text.contains("tagine") || text.contains("harissa") || text.contains("shakshuka") {
            result = "Nordafrikanisch"
        } else if text.contains("hummus") || text.contains("falafel") || text.contains("kebab") || text.contains("tahini") || text.contains("shawarma") {
            result = "Türkisch"
        } else if text.contains("gnocchi") || text.contains("pasta") || text.contains("spaghetti") || text.contains("risotto") || text.contains("pizza") || text.contains("parmesan") {
            result = "Italienisch"
        } else if text.contains("quiche") || text.contains("ratatouille") || text.contains("baguette") || text.contains("crepe") {
            result = "Französisch"
        } else if text.contains("sauerkraut") || text.contains("schnitzel") || text.contains("knödel") || text.contains("reibekuchen") || text.contains("kartoffelpuffer") || text.contains("spätzle") {
            result = "Deutsch"
        } else if text.contains("arepa") || text.contains("empanada") || text.contains("chimichurri") {
            result = "Südamerikanisch"
        } else {
            result = "Deutsch"
        }

        lock.lock()
        memoizedCuisine[name] = result
        lock.unlock()
        return result
    }
}
