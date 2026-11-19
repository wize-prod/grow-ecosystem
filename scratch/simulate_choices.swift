import Foundation

// Read MasterDataSeed to get items
let jsonPath = "NutriVaultApp/NutriVaultApp/Services/MasterDataSeed.swift"
let content = try! String(contentsOfFile: jsonPath)

if let rangeStart = content.range(of: "private static let rawCatalogJSON = \""),
   let rangeEnd = content.range(of: "\"\n\n    private static let _cachedMasterCatalog") {
    let jsonStr = String(content[rangeStart.upperBound..<rangeEnd.lowerBound])
        .replacingOccurrences(of: "\\\"", with: "\"")
        .replacingOccurrences(of: "\\\\", with: "\\")
    
    struct RawItem: Codable {
        var id: String
        var name: String
        var protein100g: Double
        var carbs100g: Double
        var fat100g: Double
        var fiber100g: Double
        var kcal100g: Double
        var currentStockQty: Double
    }
    
    if let data = jsonStr.data(using: .utf8), let rawItems = try? JSONDecoder().decode([RawItem].self, from: data) {
        print("Total items decoded:", rawItems.count)
        let proteins = rawItems.filter { $0.protein100g >= 7.0 }
        print("Proteins count:", proteins.count)
        for p in proteins.prefix(10) {
            print("  Protein:", p.name, "\(p.protein100g)g P")
        }
        let carbs = rawItems.filter { $0.carbs100g >= 14.0 }
        print("Carbs count:", carbs.count)
        for c in carbs.prefix(5) {
            print("  Carb:", c.name, "\(c.carbs100g)g C")
        }
        let produce = rawItems.filter { $0.fiber100g >= 1.5 || $0.name.lowercased().contains("spinat") || $0.name.lowercased().contains("tomat") }
        print("Produce count:", produce.count)
        for pr in produce.prefix(5) {
            print("  Produce:", pr.name)
        }
    } else {
        print("Failed to decode JSON")
    }
} else {
    print("Could not find rawCatalogJSON in MasterDataSeed")
}
