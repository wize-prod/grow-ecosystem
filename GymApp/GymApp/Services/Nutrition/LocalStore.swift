import Foundation
import UIKit
import Combine
import Network
import CoreTransferable
import UniformTypeIdentifiers
import GrowCore
import SQLite3

@MainActor
public final class LocalStore: ObservableObject {
    public static let shared = LocalStore()
    public static private(set) var isSharedInitialized: Bool = false

    public struct RecipeMacros: Equatable {
        public let protein: Double
        public let kcal: Double
        public let carbs: Double
        public let fat: Double
        public let fiber: Double
        public let price: Double?

        public init(protein: Double = 0, kcal: Double = 0, carbs: Double = 0, fat: Double = 0, fiber: Double = 0, price: Double? = nil) {
            self.protein = protein
            self.kcal = kcal
            self.carbs = carbs
            self.fat = fat
            self.fiber = fiber
            self.price = price
        }
    }

    @Published public var pantryItems: [PantryItem] = [] {
        didSet {
            rebuildPantryIndex()
            rebuildKnownStoresIndex()
        }
    }
    @Published public var mealLogs: [MealLogEntry] = [] {
        didSet {
            rebuildLogsIndex()
        }
    }
    private var logsByDate: [String: [MealLogEntry]] = [:]
    @Published public var shoppingList: [ShoppingItem] = []
    @Published public var mealTemplates: [MealTemplate] = [] {
        didSet {
            recipeMacrosCache.removeAll(keepingCapacity: true)
        }
    }
    public var isPadInstance: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    @Published public var availableUtensils: Set<CookingUtensil> = {
        if let saved = UserDefaults.standard.array(forKey: "availableUtensils") as? [String] {
            let set = Set(saved.compactMap { CookingUtensil(rawValue: $0) })
            return set.isEmpty ? [.none] : set
        }
        return [.none]
    }() {
        didSet {
            let arr = availableUtensils.map { $0.rawValue }
            UserDefaults.standard.set(arr, forKey: "availableUtensils")
        }
    }

    private var lastUtensilSelectTime: Date = .distantPast
    private var lastSelectedUtensil: CookingUtensil? = nil

    public func selectUtensil(_ utensil: CookingUtensil) {
        let now = Date()
        if lastSelectedUtensil == utensil && now.timeIntervalSince(lastUtensilSelectTime) < 0.35 {
            return
        }
        lastUtensilSelectTime = now
        lastSelectedUtensil = utensil

        objectWillChange.send()
        if availableUtensils.contains(utensil) && availableUtensils.count == 1 && utensil != .none {
            availableUtensils = [.none]
        } else {
            availableUtensils = [utensil]
        }
    }

    public func toggleUtensil(_ utensil: CookingUtensil) {
        selectUtensil(utensil)
    }

    @Published public var cachedRankedTemplates: [MealTemplate] = []
    @Published public var cachedMatchResults: [String: RecipeMatchResult] = [:]
    @Published public var pantryMatchCounts: [PantryMatchFilter: Int] = [.all: 0, .canCook: 0, .almostComplete: 0, .missingMore: 0]
    @Published public var selectedDepotSegment: String = "Vorratskammer"
    @Published public var cachedRecipeScores: [String: ComprehensiveNutritionScore] = [:]
    @Published public var cachedMissingDbCount: [String: Int] = [:]

    public var activeMealTemplates: [MealTemplate] {
        if !cachedRankedTemplates.isEmpty {
            return cachedRankedTemplates
        }
        return mealTemplates
    }

    public func matchResult(for template: MealTemplate) -> RecipeMatchResult {
        if let res = cachedMatchResults[template.id] {
            return res
        }
        return PantryMatchingEngine.shared.match(template: template, pantryItems: pantryItems)
    }

    public func templateScore(for template: MealTemplate) -> ComprehensiveNutritionScore {
        if let cached = cachedRecipeScores[template.id] {
            return cached
        }
        return NutritionalScoringEngine.shared.evaluate(template: template, store: self)
    }

    public func missingDbCount(for template: MealTemplate) -> Int {
        if let cached = cachedMissingDbCount[template.id] {
            return cached
        }
        return template.ingredients.filter { findPantryItem(for: $0) == nil }.count
    }

    public func recomputeRankedTemplates() {
        let templates = self.mealTemplates
        let items = self.pantryItems
        guard !templates.isEmpty else { return }
        Task.detached(priority: .userInitiated) {
            let rankedResults = PantryMatchingEngine.shared.rank(templates: templates, pantryItems: items)
            let ranked = rankedResults.map { $0.template }
            var resultMap: [String: RecipeMatchResult] = [:]
            resultMap.reserveCapacity(rankedResults.count)

            var canCook = 0
            var almostComplete = 0
            var missingMore = 0
            var missingInDb = 0

            for r in rankedResults {
                resultMap[r.template.id] = r
                if r.canCookNow {
                    canCook += 1
                } else if r.matchScore >= 0.50 {
                    almostComplete += 1
                } else {
                    missingMore += 1
                }
            }

            // Fast pre-calculation of macros, scores, and missing DB ingredients in the background pass
            let pantryMap = Dictionary(items.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
            let pantryNormMap = Dictionary(items.map { ($0.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(), $0) }, uniquingKeysWith: { first, _ in first })
            var macroMap: [String: RecipeMacros] = [:]
            var scoreMap: [String: ComprehensiveNutritionScore] = [:]
            var missingDbMap: [String: Int] = [:]
            macroMap.reserveCapacity(templates.count)
            scoreMap.reserveCapacity(templates.count)
            missingDbMap.reserveCapacity(templates.count)

            for t in templates {
                var totalP = 0.0
                var totalK = 0.0
                var totalC = 0.0
                var totalF = 0.0
                var totalFib = 0.0
                var totalPrice: Double? = 0.0
                var missingCount = 0
                var totalGrams = 0.0
                var accProfile = NutritionalProfile()

                for ing in t.ingredients {
                    let item = (!ing.pantryItemId.isEmpty ? pantryMap[ing.pantryItemId] : nil)
                        ?? pantryNormMap[ing.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()]
                    guard let item = item else {
                        missingCount += 1
                        totalPrice = nil
                        continue
                    }
                    let g = (ing.grams > 0 ? ing.grams : (ing.rawAmount ?? 100.0))
                    let factor = g / 100.0
                    totalGrams += g
                    totalP += factor * item.protein100g
                    totalK += factor * item.kcal100g
                    totalC += factor * item.carbs100g
                    totalF += factor * item.fat100g
                    totalFib += factor * item.fiber100g

                    accProfile.add(scaledFrom: item.effectiveProfile(), ratio: factor)

                    if let cur = totalPrice {
                        if item.defaultPrice > 0.005 && item.defaultPackQty > 0 {
                            totalPrice = cur + (g / item.defaultPackQty) * item.defaultPrice
                        } else {
                            totalPrice = nil
                        }
                    }
                }

                if missingCount > 0 {
                    missingInDb += 1
                }
                missingDbMap[t.id] = missingCount
                macroMap[t.id] = RecipeMacros(protein: totalP, kcal: totalK, carbs: totalC, fat: totalF, fiber: totalFib, price: totalPrice)

                let refGrams = max(100.0, totalGrams)
                let factor = 100.0 / refGrams
                let score = NutritionalScoringEngine.shared.calculateScore(
                    kcal100g: totalK * factor,
                    protein100g: totalP * factor,
                    carbs100g: totalC * factor,
                    fat100g: totalF * factor,
                    fiber100g: totalFib * factor,
                    sugars100g: (accProfile.sugars ?? 0.0) * factor,
                    satFat100g: (accProfile.saturatedFat ?? 0.0) * factor,
                    sodiumMg100g: (accProfile.sodium ?? ((accProfile.salt ?? 0.0) * 400.0)) * factor,
                    salt100g: (accProfile.salt ?? ((accProfile.sodium ?? 0.0) / 400.0)) * factor,
                    potassiumMg100g: (accProfile.potassium ?? 0.0) * factor,
                    polyFat100g: (accProfile.polyunsaturatedFat ?? 0.0) * factor,
                    profile: accProfile,
                    productName: t.name
                )
                scoreMap[t.id] = score
            }

            let counts: [PantryMatchFilter: Int] = [
                .all: templates.count,
                .canCook: canCook,
                .almostComplete: almostComplete,
                .missingMore: missingMore,
                .missingInDb: missingInDb
            ]

            await MainActor.run {
                self.cachedRankedTemplates = ranked
                self.cachedMatchResults = resultMap
                self.pantryMatchCounts = counts
                self.recipeMacrosCache = macroMap
                self.cachedRecipeScores = scoreMap
                self.cachedMissingDbCount = missingDbMap
            }
        }
    }

    public func addMissingIngredientsToShoppingList(for template: MealTemplate) {
        let matchResult = PantryMatchingEngine.shared.match(template: template, pantryItems: pantryItems)
        for missing in matchResult.missingIngredients {
            let itemName = missing.name
            if !shoppingList.contains(where: { $0.name.lowercased() == itemName.lowercased() }) {
                let newItem = ShoppingItem(
                    pantryItemId: missing.pantryItemId,
                    name: itemName,
                    store: "PENNY",
                    quantity: max(1, Int((missing.grams / 100.0).rounded())),
                    unit: missing.unit ?? "g",
                    category: template.category
                )
                shoppingList.append(newItem)
            }
        }
        saveShopping()
        HapticFeedbackService.shared.commitSuccess()
    }

    public func applyAutonomousShoppingPlan(items: [ShoppingItem]) {
        self.shoppingList = items
        saveShopping()
        HapticFeedbackService.shared.commitSuccess()
    }
    @Published public var receipts: [ReceiptRecord] = [] {
        didSet {
            rebuildKnownStoresIndex()
        }
    }
    @Published public var lastGrowcerySyncDate: Date? = nil
    @Published public var isGrowcerySyncing: Bool = false
    @Published public var growcerySyncMessage: String = ""
    @Published public var supplementLogs: [String: Set<String>] = [:]
    @Published public var customSupplements: [CircadianSupplementDose] = []
    @Published public var waterLogs: [String: Double] = [:]
    @Published public var skippedSupplements: [String: Set<String>] = [:]
    @Published public var dailyNotes: [String: String] = [:]
    @Published public var activeDraftReceipt: ParsedReceiptDraft? = nil
    @Published public var latestSharedWorkout: SharedWorkoutPayload? = nil
    @Published public var sharedFinance: SharedFinancePayload = GrowSuiteBridge.shared.loadFinance(for: Date())
    @Published public var bristolLogs: [String: Int] = [:]
    @Published public var customStores: [String] = [] {
        didSet {
            rebuildKnownStoresIndex()
        }
    }

    // MARK: - Dynamic Store Registry
    public static let defaultStoreList: [String] = [
        "PENNY", "REWE", "ALDI", "SPAR", "LIDL", "EDEKA", "DM", "KAUFLAND", "NETTO", "NORMA", "HOFER", "BILLA", "BIPA", "MÜLLER", "AMAZON", "APOTHEKE", "ESN"
    ]

    @Published public private(set) var allKnownStores: [String] = []

    public func rebuildKnownStoresIndex() {
        var set = Set<String>()
        var list: [String] = []

        let addStore: (String) -> Void = { raw in
            let canonical = StoreCanonicalizer.canonicalize(raw, existingStores: list)
            guard !canonical.isEmpty, canonical != "ALLE", canonical != "SONSTIGE" else { return }
            let up = canonical.uppercased()
            if !set.contains(up) {
                set.insert(up)
                list.append(canonical)
            }
        }

        for s in Self.defaultStoreList {
            addStore(s)
        }

        for s in customStores {
            addStore(s)
        }

        for p in pantryItems {
            addStore(p.store)
        }

        for r in receipts {
            addStore(r.storeName)
        }

        self.allKnownStores = list
    }

    public func canonicalStoreName(for rawName: String) -> String {
        StoreCanonicalizer.canonicalize(rawName, existingStores: allKnownStores)
    }

    public func registerStoreIfNeeded(_ storeName: String) {
        let canonical = StoreCanonicalizer.canonicalize(storeName, existingStores: allKnownStores)
        guard !canonical.isEmpty, canonical != "ALLE", canonical != "SONSTIGE" else { return }
        let up = canonical.uppercased()

        let existingUpper = Set(allKnownStores.map { $0.uppercased() })
        if !existingUpper.contains(up) {
            customStores.append(canonical)
            saveCustomStores()
        }
    }

    // MARK: - Navigation & Deep Linking to Vorratskammer
    @Published public var targetedPantryItemForInspection: PantryItem? = nil
    @Published public var targetedDepotSegment: String? = nil
    @Published public var targetedPantrySearchText: String? = nil

    public func navigateToPantryItemInVorratskammer(_ item: PantryItem) {
        self.targetedPantrySearchText = item.name
        self.targetedDepotSegment = "Vorratskammer"
        self.targetedPantryItemForInspection = item
        SupplementNotificationService.shared.deepLinkTargetTab = 1 // Tab 1: Vorrat Tab
    }

    public func navigateToPantrySearchInVorratskammer(_ query: String) {
        self.targetedPantrySearchText = query
        self.targetedDepotSegment = "Vorratskammer"
        SupplementNotificationService.shared.deepLinkTargetTab = 1
    }

    // High-Performance Caches & Indexing
    private var pantryById: [String: PantryItem] = [:]
    private var pantryByNormalizedName: [String: PantryItem] = [:]
    private var recipeMacrosCache: [String: RecipeMacros] = [:]
    private let recipeImageCache: NSCache<NSString, UIImage> = {
        let c = NSCache<NSString, UIImage>()
        c.countLimit = 300
        return c
    }()

    // MARK: - Proportionale Cross-App Trainings-Kompensation (Reines mathematisches Modell)
    public var workoutKcalCompensation: Double {
        guard let workout = latestSharedWorkout else { return 0.0 }
        // Ergaenzung von 60% der verifizierten Trainingskalorien zur metabolischen Sicherung
        let fromCalories = workout.caloriesBurned * 0.60
        // Tonnage-Validierung: ~15 kcal pro 1.000 kg bewegte Gesamtlast
        let fromTonnage = (workout.totalTonnageKg / 1000.0) * 15.0
        let combined = max(fromCalories, fromTonnage)
        return min(500.0, max(0.0, combined))
    }

    public var workoutCarbCompensation: Double {
        guard let workout = latestSharedWorkout else { return 0.0 }
        // Glykogen-Resynthese skaliert linear mit Tonnage (3,0 g pro 1.000 kg) und Dauer (15 g pro Stunde)
        let tonnageCarbs = (workout.totalTonnageKg / 1000.0) * 3.0
        let durationCarbs = (Double(workout.durationMinutes) / 60.0) * 15.0
        return min(75.0, max(0.0, tonnageCarbs + durationCarbs))
    }

    public var workoutWaterCompensation: Double {
        guard let workout = latestSharedWorkout else { return 0.0 }
        // Hydratations-Ausgleich fuer Schweissverlust und metabolische Rate:
        // 10 ml pro Minute Belastung + 25 ml pro 1.000 kg bewegte Gesamtlast
        let durationWater = Double(workout.durationMinutes) * 10.0
        let tonnageWater = (workout.totalTonnageKg / 1000.0) * 25.0
        return min(1200.0, max(0.0, durationWater + tonnageWater))
    }

    public var workoutProteinCompensation: Double {
        guard let workout = latestSharedWorkout else { return 0.0 }
        // Bei hohem Reizvolumen (> 8.000 kg Tonnage oder > 45 min) +10 g Protein
        if workout.totalTonnageKg >= 8000.0 || workout.durationMinutes >= 45 {
            return 10.0
        }
        return 0.0
    }

    public var hasHeavyLegDayStimulus: Bool {
        guard let workout = latestSharedWorkout else { return false }
        let isLegDay = workout.muscleGroupsHit.contains { group in
            let g = group.lowercased()
            return g.contains("bein") || g.contains("quad") || g.contains("leg") || g.contains("hamstring") || g.contains("glute")
        } || workout.title.lowercased().contains("bein") || workout.title.lowercased().contains("leg") || workout.title.lowercased().contains("quad")
        return isLegDay && workout.totalTonnageKg >= 10000.0
    }

    public var targetProtein: Double {
        let base = UserAccountService.shared.currentAccount.targetProtein
        // Zielkorridor: 145 bis 170 g (Standard ~160 g)
        return min(170.0, base + workoutProteinCompensation)
    }
    public var targetKcal: Double {
        let base = UserAccountService.shared.currentAccount.targetKcal
        return base + workoutKcalCompensation
    }
    public var targetCarbs: Double {
        let base = UserAccountService.shared.currentAccount.targetCarbs
        return base + workoutCarbCompensation
    }
    public var targetFat: Double {
        UserAccountService.shared.currentAccount.targetFat
    }
    public var targetWaterMl: Double {
        let base = UserAccountService.shared.currentAccount.targetWaterMl
        return base + workoutWaterCompensation
    }

    // MARK: - Dateipfade & Multi-User Partitioning
    private var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    public var currentUserStorageDirectory: URL {
        let key = UserAccountService.shared.currentAccount.userKey
        let dir = documentsDirectory
            .appendingPathComponent("userData", isDirectory: true)
            .appendingPathComponent(key, isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            if key == "primary_wize_prod" {
                migrateLegacyFilesIfNeeded(to: dir)
            }
        }
        return dir
    }

    private func migrateLegacyFilesIfNeeded(to targetDir: URL) {
        let fileNames = [
            "pantry_catalog.json", "meal_logs.json", "shopping_list.json", "meal_templates.json",
            "receipts.json", "supplement_logs.json", "custom_supplements.json", "water_logs.json",
            "care_products.json", "care_routines.json", "chores_routines.json", "chore_completions.json",
            "care_completions.json", "skipped_supplements.json", "skipped_care.json", "skipped_chores.json",
            "daily_notes.json"
        ]
        for name in fileNames {
            let src = documentsDirectory.appendingPathComponent(name)
            let dst = targetDir.appendingPathComponent(name)
            if FileManager.default.fileExists(atPath: src.path) && !FileManager.default.fileExists(atPath: dst.path) {
                try? FileManager.default.copyItem(at: src, to: dst)
            }
        }
    }

    private var pantryURL: URL { currentUserStorageDirectory.appendingPathComponent("pantry_catalog.json") }
    private var logsURL: URL { currentUserStorageDirectory.appendingPathComponent("meal_logs.json") }
    private var shoppingURL: URL { currentUserStorageDirectory.appendingPathComponent("shopping_list.json") }
    private var templatesURL: URL { currentUserStorageDirectory.appendingPathComponent("meal_templates.json") }
    private var receiptsURL: URL { currentUserStorageDirectory.appendingPathComponent("receipts.json") }
    private var supplementURL: URL { currentUserStorageDirectory.appendingPathComponent("supplement_logs.json") }
    private var customSupplementsURL: URL { currentUserStorageDirectory.appendingPathComponent("custom_supplements.json") }
    private var waterURL: URL { currentUserStorageDirectory.appendingPathComponent("water_logs.json") }
    private var skippedSupplementsURL: URL { currentUserStorageDirectory.appendingPathComponent("skipped_supplements.json") }
    private var dailyNotesURL: URL { currentUserStorageDirectory.appendingPathComponent("daily_notes.json") }
    private var bristolURL: URL { currentUserStorageDirectory.appendingPathComponent("bristol_logs.json") }
    private var customStoresURL: URL { currentUserStorageDirectory.appendingPathComponent("custom_stores.json") }
    private let storageQueue = DispatchQueue(label: "com.grow.nutrivault.storage", qos: .utility)
    private var pendingSaveWorkItems: [URL: DispatchWorkItem] = [:]
    private let pendingWorkItemsLock = NSLock()

    // MARK: - Autonomous Catalog Self-Healing Engine
    private let networkMonitor = NWPathMonitor()
    private let networkQueue = DispatchQueue(label: "com.grow.nutrivault.networkMonitor", qos: .background)
    @Published public private(set) var isNetworkAvailable: Bool = true
    private var isHealingActive: Bool = false
    private var isInitializing: Bool = true
    private var failedLookupBarcodes: Set<String> = []

    private init() {
        loadAllData()
        setupAutonomousCatalogHealer()
        Self.isSharedInitialized = true
    }

    public func loadAllData() {
        loadCustomStores()
        loadPantry()
        loadLogs()
        loadShopping()
        loadTemplates()
        loadReceipts()
        loadSupplements()
        loadSupplementsList()
        loadWater()
        loadSkippedData()
        loadDailyNotes()
        loadBristol()
        rebuildKnownStoresIndex()
        isInitializing = false

        let initialSeedKey = "hasInitialPantryMasterSeed_v1"
        if !UserDefaults.standard.bool(forKey: initialSeedKey) {
            seedFromMasterData()
            UserDefaults.standard.set(true, forKey: initialSeedKey)
        }

        syncTagesbilanzToBridge()
        Task.detached(priority: .background) {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            await MainActor.run {
                self.generateVaultExportDocument()
            }
        }
    }

    public func seedFromMasterData() {
        let masterItems = MasterDataSeed.getMasterCatalog().map { item -> PantryItem in
            var mod = item
            mod.profile = CommodityReferenceCatalog.enrich(
                profile: item.profile,
                forProductName: item.name,
                brand: item.brand
            )
            return mod
        }
        if !masterItems.isEmpty {
            self.pantryItems = masterItems
            savePantry()
        }
        let masterTemplates = MasterDataSeed.getMasterTemplates()
        if !masterTemplates.isEmpty {
            self.mealTemplates = masterTemplates
            saveTemplates()
        }
        self.shoppingList = []
        saveShopping()
        let masterReceipts = MasterDataSeed.getMasterReceipts()
        if !masterReceipts.isEmpty {
            self.receipts = masterReceipts
            saveReceipts()
        }
    }

    // MARK: - Pantry Operations

    public func resetAllPantryStockToZero() {
        for idx in 0..<pantryItems.count {
            pantryItems[idx].currentStockQty = 0.0
        }
        savePantry()
        HapticFeedbackService.shared.commitSuccess()
    }

    public func savePantry() {
        save(items: pantryItems, to: pantryURL)
        NutritionalScoringEngine.shared.clearCache()
        recomputeRankedTemplates()
    }

    private func loadPantry() {
        if let items: [PantryItem] = load(from: pantryURL) {
            self.pantryItems = items.map { item in
                var mod = item
                let n = item.name.lowercased()
                let isEgg = (n.contains("eier") || n.contains("ei ") || n.hasPrefix("ei ") || n.contains("hühnerei") || n.contains("bodenhaltung")) && !n.contains("fleisch") && !n.contains("reis") && !n.contains("nudel") && !n.contains("teig") && !n.contains("eiweiß") && !n.contains("salat")
                if isEgg && (mod.unit.lowercased() == "g" || mod.unit.isEmpty) {
                    mod.unit = "Stück"
                    if mod.defaultPackQty > 30 {
                        mod.defaultPackQty = 10.0
                    }
                    if mod.currentStockQty > 30 {
                        mod.currentStockQty = max(1.0, (mod.currentStockQty / 55.0).rounded())
                    }
                }
                let isKidney = n.contains("kidney") || n.contains("kidneyb")
                if isKidney && mod.subUnitCount == nil {
                    mod.subUnitCount = 3
                    mod.subUnitSize = 200.0
                    mod.subUnitName = "Dosen"
                    if mod.defaultPackQty <= 200.0 {
                        mod.defaultPackQty = 600.0
                    }
                }
                let isScheiben = n.contains("scheibenkäse") || n.contains("scheibenkaese") || (n.contains("käse") && n.contains("scheibe"))
                if isScheiben {
                    if mod.unit.lowercased() == "ml" || mod.unit.isEmpty {
                        mod.unit = "g"
                    }
                    if mod.subUnitName == nil {
                        mod.subUnitName = "Scheiben"
                        mod.subUnitSize = 25.0
                        mod.subUnitCount = max(2, Int((mod.defaultPackQty / 25.0).rounded()))
                    }
                }
                let isAnanas = n.contains("ananas") && (n.contains("scheibe") || n.contains("dose") || mod.defaultPackQty >= 200)
                if isAnanas && mod.subUnitName == nil {
                    mod.subUnitName = "Scheiben"
                    mod.subUnitSize = 40.0
                    mod.subUnitCount = max(2, Int((mod.defaultPackQty / 40.0).rounded()))
                }
                let isToast = (n.contains("toast") || (n.contains("brot") && n.contains("scheibe")))
                if isToast && mod.subUnitName == nil {
                    mod.subUnitName = "Scheiben"
                    mod.subUnitSize = 25.0
                    mod.subUnitCount = max(2, Int((mod.defaultPackQty / 25.0).rounded()))
                }
                mod.profile = CommodityReferenceCatalog.enrich(
                    profile: item.profile,
                    forProductName: item.name,
                    brand: item.brand
                )
                return mod
            }

            // Sanitize orphaned/bogus placeholders
            var sanitized: [PantryItem] = []
            var hadPruning = false
            for item in self.pantryItems {
                let isPlaceholder = item.name.hasPrefix("Neues Produkt") || item.name.hasPrefix("Produkt (EAN")
                if isPlaceholder {
                    let isUrl = item.barcode.contains("://") || item.barcode.contains("http") || item.barcode.contains("www")
                    let isNF = NonFoodClassifier.isNonFood(item: item)
                    if isUrl || isNF || (!item.hasNutritionalData && item.currentStockQty <= 0) {
                        hadPruning = true
                        continue
                    }
                }
                sanitized.append(item)
            }
            if hadPruning {
                self.pantryItems = sanitized
                savePantry()
            }
        }
        rebuildPantryIndex()
    }

    // MARK: - Autonomous Catalog Self-Healing Engine
    private func setupAutonomousCatalogHealer() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            let available = (path.status == .satisfied)
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.isNetworkAvailable = available
                if available {
                    Task.detached(priority: .background) { [weak self] in
                        await self?.performCatalogSelfHealing()
                    }
                }
            }
        }
        networkMonitor.start(queue: networkQueue)

        // Single delayed background self-heal run after startup (no repetitive 25s polling loop)
        Task.detached(priority: .background) { [weak self] in
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            await self?.performCatalogSelfHealing()
        }
    }

    public func performCatalogSelfHealing() async {
        guard !isHealingActive else { return }
        isHealingActive = true
        defer { isHealingActive = false }

        var didModify = false
        var currentItems = await MainActor.run { self.pantryItems }

        // 1. Silent automatic pruning of invalid/malformed artifacts
        let cleaned = currentItems.filter { item in
            let isPlaceholder = item.name.hasPrefix("Neues Produkt") || item.name.hasPrefix("Produkt (EAN")
            let isUrl = item.barcode.contains("://") || item.barcode.contains("http") || item.barcode.contains("www")
            let isNF = NonFoodClassifier.isNonFood(item: item)
            if isUrl || isNF {
                didModify = true
                return false
            }
            if isPlaceholder && !item.hasNutritionalData && (item.barcode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || item.currentStockQty <= 0) {
                didModify = true
                return false
            }
            return true
        }

        if cleaned.count != currentItems.count {
            currentItems = cleaned
            didModify = true
        }

        // 2. Identify remaining items needing nutritional data or proper product names
        let candidates = currentItems.enumerated().filter { _, it in
            let cleanBc = it.barcode.trimmingCharacters(in: .whitespacesAndNewlines)
            if !cleanBc.isEmpty && self.failedLookupBarcodes.contains(cleanBc) {
                return false
            }
            let isPlaceholder = it.name.hasPrefix("Neues Produkt") || it.name.hasPrefix("Produkt (EAN")
            return isPlaceholder || !it.hasNutritionalData
        }

        guard !candidates.isEmpty else {
            if didModify {
                await MainActor.run {
                    self.pantryItems = currentItems
                    self.savePantry()
                }
            }
            return
        }

        for (_, currentItem) in candidates {
            let cleanBarcode = currentItem.barcode.trimmingCharacters(in: .whitespacesAndNewlines)

            // 2a. Query Cloud DB (Supabase) + Open Food Facts API if barcode is present, valid, and not previously failed
            if !cleanBarcode.isEmpty && !cleanBarcode.contains("://") && !self.failedLookupBarcodes.contains(cleanBarcode) {
                if let fetched = await CloudProductCatalogService.shared.lookupProduct(barcode: cleanBarcode) {
                    if NonFoodClassifier.isNonFood(item: fetched) {
                        currentItems.removeAll(where: { $0.id == currentItem.id })
                        didModify = true
                        continue
                    }

                    var updated = fetched
                    updated.id = currentItem.id
                    updated.currentStockQty = currentItem.currentStockQty
                    updated.storageLocation = currentItem.storageLocation
                    updated.store = currentItem.store.isEmpty ? fetched.store : currentItem.store
                    if let targetIdx = currentItems.firstIndex(where: { $0.id == currentItem.id }) {
                        currentItems[targetIdx] = updated
                        didModify = true
                    }
                    continue
                } else {
                    self.failedLookupBarcodes.insert(cleanBarcode)
                }
            }

            // 2b. Commodity reference catalog blending
            let enrichedProfile = CommodityReferenceCatalog.enrich(
                profile: currentItem.profile,
                forProductName: currentItem.name,
                brand: currentItem.brand
            )
            if enrichedProfile != currentItem.profile {
                if let targetIdx = currentItems.firstIndex(where: { $0.id == currentItem.id }) {
                    currentItems[targetIdx].profile = enrichedProfile
                    didModify = true
                }
            }

            // 2c. Placeholder prune if empty
            if (currentItem.name.hasPrefix("Neues Produkt") || currentItem.name.hasPrefix("Produkt (EAN")) && !currentItem.hasNutritionalData {
                if currentItem.currentStockQty <= 0 {
                    currentItems.removeAll(where: { $0.id == currentItem.id })
                    didModify = true
                }
            }
        }

        // Apply mutations AT MOST ONCE at the end of the entire batch
        if didModify {
            await MainActor.run {
                self.pantryItems = currentItems
                self.savePantry()
            }
        }
    }

    public func rebuildPantryIndex() {
        var byId: [String: PantryItem] = [:]
        byId.reserveCapacity(pantryItems.count)
        var byName: [String: PantryItem] = [:]
        byName.reserveCapacity(pantryItems.count)
        for item in pantryItems {
            byId[item.id] = item
            let norm = item.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if byName[norm] == nil {
                byName[norm] = item
            }
        }
        self.pantryById = byId
        self.pantryByNormalizedName = byName
        self.recipeMacrosCache.removeAll(keepingCapacity: true)
    }

    public func rebuildLogsIndex() {
        var dict: [String: [MealLogEntry]] = [:]
        for entry in mealLogs {
            let key = dateKey(for: entry.timestamp)
            dict[key, default: []].append(entry)
        }
        self.logsByDate = dict
        invalidateDailyMacrosCache()
    }

    public func findPantryItem(for ing: TemplateIngredient) -> PantryItem? {
        if !ing.pantryItemId.isEmpty, let item = pantryById[ing.pantryItemId] {
            return item
        }
        let norm = ing.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if let match = pantryByNormalizedName[norm] {
            return match
        }
        return pantryItems.first(where: {
            let pNorm = $0.name.lowercased()
            return pNorm == norm || pNorm.contains(norm) || norm.contains(pNorm)
        })
    }

    public func addOrUpdatePantryItem(_ item: PantryItem) {
        if !item.store.isEmpty {
            registerStoreIfNeeded(item.store)
        }
        var enriched = item
        enriched.profile = CommodityReferenceCatalog.enrich(
            profile: item.profile,
            forProductName: item.name,
            brand: item.brand
        )
        if let idx = pantryItems.firstIndex(where: { $0.id == enriched.id || (!$0.barcode.isEmpty && $0.barcode == enriched.barcode) }) {
            pantryItems[idx] = enriched
        } else {
            pantryItems.insert(enriched, at: 0)
        }
        savePantry()
        checkAutoRestock(for: enriched)
    }

    public func registerCustomProduct(
        name: String,
        brand: String,
        barcode: String,
        packGrams: Double,
        price: Double,
        unit: String = "g",
        kcal100g: Double,
        protein100g: Double,
        carbs100g: Double,
        fat100g: Double,
        fiber100g: Double,
        store: String
    ) -> PantryItem {
        let enrichedProfile = CommodityReferenceCatalog.enrich(
            profile: NutritionalProfile(fiber: fiber100g),
            forProductName: name,
            brand: brand
        )
        let newItem = PantryItem(
            id: "custom_\(UUID().uuidString.prefix(8))",
            name: name,
            brand: brand.isEmpty ? "Pantry" : brand,
            barcode: barcode,
            defaultPackQty: packGrams > 0 ? packGrams : (unit == "Stück" ? 10.0 : 500.0),
            defaultPrice: price > 0 ? price : 0.0,
            currentStockQty: packGrams > 0 ? packGrams : (unit == "Stück" ? 10.0 : 500.0),
            unit: unit,
            kcal100g: kcal100g,
            protein100g: protein100g,
            carbs100g: carbs100g,
            fat100g: fat100g,
            fiber100g: fiber100g,
            nutriscore: "a",
            store: store.isEmpty ? "PENNY" : store,
            profile: enrichedProfile
        )
        addOrUpdatePantryItem(newItem)
        HapticFeedbackService.shared.commitSuccess()
        return newItem
    }

    public func restockItem(id: String, addQuantity: Double) {
        if let idx = pantryItems.firstIndex(where: { $0.id == id }) {
            pantryItems[idx].currentStockQty += addQuantity
            savePantry()
            HapticFeedbackService.shared.commitSuccess()
        }
    }

    public func updateStock(id: String, newQuantity: Double) {
        if let idx = pantryItems.firstIndex(where: { $0.id == id }) {
            pantryItems[idx].currentStockQty = max(0.0, newQuantity)
            savePantry()
            checkAutoRestock(for: pantryItems[idx])
            HapticFeedbackService.shared.commitSuccess()
        }
    }

    public func updateStockAndUnit(
        id: String,
        newQuantity: Double,
        unit: String? = nil,
        defaultPackQty: Double? = nil,
        newName: String? = nil,
        newBrand: String? = nil,
        subUnitCount: Int? = nil,
        subUnitSize: Double? = nil,
        subUnitName: String? = nil,
        storageLocation: StorageLocation? = nil,
        storageInstructions: String? = nil
    ) {
        objectWillChange.send()
        let cleanName = newName?.trimmingCharacters(in: .whitespaces) ?? ""
        let cleanBrand = newBrand?.trimmingCharacters(in: .whitespaces) ?? ""
        let cleanUnit = unit?.trimmingCharacters(in: .whitespaces) ?? ""

        if let idx = pantryItems.firstIndex(where: { $0.id == id }) {
            pantryItems[idx].currentStockQty = max(0.0, newQuantity)
            if !cleanUnit.isEmpty {
                pantryItems[idx].unit = cleanUnit
            }
            if let p = defaultPackQty, p > 0 {
                pantryItems[idx].defaultPackQty = p
            }
            if !cleanName.isEmpty {
                pantryItems[idx].name = cleanName
            }
            if !cleanBrand.isEmpty {
                pantryItems[idx].brand = cleanBrand
            }
            pantryItems[idx].subUnitCount = subUnitCount
            pantryItems[idx].subUnitSize = subUnitSize
            pantryItems[idx].subUnitName = subUnitName
            if let loc = storageLocation {
                pantryItems[idx].storageLocation = loc
            }
            if let inst = storageInstructions {
                pantryItems[idx].storageInstructions = inst
            }
            savePantry()
            propagateProductMatch(pantryItem: pantryItems[idx])
            checkAutoRestock(for: pantryItems[idx])
            HapticFeedbackService.shared.commitSuccess()
        } else if let barcodeIdx = pantryItems.firstIndex(where: { !$0.barcode.isEmpty && $0.barcode == id }) {
            pantryItems[barcodeIdx].currentStockQty = max(0.0, newQuantity)
            if !cleanUnit.isEmpty {
                pantryItems[barcodeIdx].unit = cleanUnit
            }
            if let p = defaultPackQty, p > 0 {
                pantryItems[barcodeIdx].defaultPackQty = p
            }
            if !cleanName.isEmpty {
                pantryItems[barcodeIdx].name = cleanName
            }
            if !cleanBrand.isEmpty {
                pantryItems[barcodeIdx].brand = cleanBrand
            }
            pantryItems[barcodeIdx].subUnitCount = subUnitCount
            pantryItems[barcodeIdx].subUnitSize = subUnitSize
            pantryItems[barcodeIdx].subUnitName = subUnitName
            if let loc = storageLocation {
                pantryItems[barcodeIdx].storageLocation = loc
            }
            if let inst = storageInstructions {
                pantryItems[barcodeIdx].storageInstructions = inst
            }
            savePantry()
            propagateProductMatch(pantryItem: pantryItems[barcodeIdx])
            checkAutoRestock(for: pantryItems[barcodeIdx])
            HapticFeedbackService.shared.commitSuccess()
        } else if !cleanName.isEmpty, let nameIdx = pantryItems.firstIndex(where: { $0.name.lowercased() == cleanName.lowercased() }) {
            pantryItems[nameIdx].currentStockQty = max(0.0, newQuantity)
            if !cleanUnit.isEmpty {
                pantryItems[nameIdx].unit = cleanUnit
            }
            if let p = defaultPackQty, p > 0 {
                pantryItems[nameIdx].defaultPackQty = p
            }
            if !cleanBrand.isEmpty {
                pantryItems[nameIdx].brand = cleanBrand
            }
            pantryItems[nameIdx].subUnitCount = subUnitCount
            pantryItems[nameIdx].subUnitSize = subUnitSize
            pantryItems[nameIdx].subUnitName = subUnitName
            if let loc = storageLocation {
                pantryItems[nameIdx].storageLocation = loc
            }
            if let inst = storageInstructions {
                pantryItems[nameIdx].storageInstructions = inst
            }
            savePantry()
            propagateProductMatch(pantryItem: pantryItems[nameIdx])
            checkAutoRestock(for: pantryItems[nameIdx])
            HapticFeedbackService.shared.commitSuccess()
        } else {
            // New pantry item inserted
            let newItem = PantryItem(
                id: id.isEmpty ? UUID().uuidString : id,
                name: cleanName.isEmpty ? "Neuer Artikel" : cleanName,
                brand: cleanBrand.isEmpty ? "Pantry" : cleanBrand,
                barcode: "",
                defaultPackQty: (defaultPackQty ?? 0) > 0 ? defaultPackQty! : (cleanUnit == "Stück" ? 10.0 : 500.0),
                defaultPrice: 0.0,
                currentStockQty: max(0.0, newQuantity),
                unit: cleanUnit.isEmpty ? "g" : cleanUnit,
                kcal100g: 0.0,
                protein100g: 0.0,
                carbs100g: 0.0,
                fat100g: 0.0,
                fiber100g: 0.0,
                nutriscore: "a",
                store: "PENNY",
                subUnitCount: subUnitCount,
                subUnitSize: subUnitSize,
                subUnitName: subUnitName,
                storageLocation: storageLocation,
                storageInstructions: storageInstructions ?? ""
            )
            pantryItems.insert(newItem, at: 0)
            savePantry()
            checkAutoRestock(for: newItem)
            HapticFeedbackService.shared.commitSuccess()
        }
    }

    public func updateProductMetadata(id: String, name: String, brand: String? = nil) {
        if let idx = pantryItems.firstIndex(where: { $0.id == id }) {
            let cleanName = name.trimmingCharacters(in: .whitespaces)
            if !cleanName.isEmpty {
                pantryItems[idx].name = cleanName
            }
            if let b = brand {
                pantryItems[idx].brand = b.trimmingCharacters(in: .whitespaces)
            }
            savePantry()
            propagateProductMatch(pantryItem: pantryItems[idx])
            HapticFeedbackService.shared.commitSuccess()
        }
    }

    public func updatePantryItemFull(
        id: String,
        name: String,
        brand: String,
        barcode: String,
        store: String,
        unit: String,
        currentStockQty: Double,
        defaultPackQty: Double,
        defaultPrice: Double,
        kcal100g: Double,
        protein100g: Double,
        carbs100g: Double,
        fat100g: Double,
        fiber100g: Double,
        storageLocation: StorageLocation,
        storageInstructions: String,
        subUnitCount: Int?,
        subUnitSize: Double?,
        subUnitName: String?
    ) {
        objectWillChange.send()

        if let idx = pantryItems.firstIndex(where: { $0.id == id }) {
            pantryItems[idx].name = name.trimmingCharacters(in: .whitespaces)
            pantryItems[idx].brand = brand.trimmingCharacters(in: .whitespaces)
            pantryItems[idx].barcode = barcode.trimmingCharacters(in: .whitespaces)
            pantryItems[idx].store = store.trimmingCharacters(in: .whitespaces)
            pantryItems[idx].unit = unit.trimmingCharacters(in: .whitespaces)
            pantryItems[idx].currentStockQty = max(0.0, currentStockQty)
            pantryItems[idx].defaultPackQty = max(0.001, defaultPackQty)
            pantryItems[idx].defaultPrice = max(0.0, defaultPrice)
            pantryItems[idx].kcal100g = max(0.0, kcal100g)
            pantryItems[idx].protein100g = max(0.0, protein100g)
            pantryItems[idx].carbs100g = max(0.0, carbs100g)
            pantryItems[idx].fat100g = max(0.0, fat100g)
            pantryItems[idx].fiber100g = max(0.0, fiber100g)
            pantryItems[idx].storageLocation = storageLocation
            pantryItems[idx].storageInstructions = storageInstructions
            pantryItems[idx].subUnitCount = subUnitCount
            pantryItems[idx].subUnitSize = subUnitSize
            pantryItems[idx].subUnitName = subUnitName

            savePantry()
            propagateProductMatch(pantryItem: pantryItems[idx])
            checkAutoRestock(for: pantryItems[idx])
            HapticFeedbackService.shared.commitSuccess()
        } else {
            let newItem = PantryItem(
                id: id,
                name: name.trimmingCharacters(in: .whitespaces),
                brand: brand.trimmingCharacters(in: .whitespaces),
                barcode: barcode.trimmingCharacters(in: .whitespaces),
                defaultPackQty: max(0.001, defaultPackQty),
                defaultPrice: max(0.0, defaultPrice),
                currentStockQty: max(0.0, currentStockQty),
                unit: unit.trimmingCharacters(in: .whitespaces),
                kcal100g: max(0.0, kcal100g),
                protein100g: max(0.0, protein100g),
                carbs100g: max(0.0, carbs100g),
                fat100g: max(0.0, fat100g),
                fiber100g: max(0.0, fiber100g),
                store: store.trimmingCharacters(in: .whitespaces),
                subUnitCount: subUnitCount,
                subUnitSize: subUnitSize,
                subUnitName: subUnitName,
                storageLocation: storageLocation,
                storageInstructions: storageInstructions
            )
            pantryItems.append(newItem)
            savePantry()
            propagateProductMatch(pantryItem: newItem)
            checkAutoRestock(for: newItem)
            HapticFeedbackService.shared.commitSuccess()
        }
    }

    @discardableResult
    public func enrichMissingNutrition() async -> Int {
        var enrichedCount = 0
        let itemsToEnrich = pantryItems.filter { !$0.hasNutritionalData }
        guard !itemsToEnrich.isEmpty else { return 0 }

        for item in itemsToEnrich {
            var updatedKcal = item.kcal100g
            var updatedP = item.protein100g
            var updatedC = item.carbs100g
            var updatedF = item.fat100g
            var updatedFib = item.fiber100g
            var didEnrich = false

            // 1. Live lookup via Cloud DB + OpenFoodFacts
            if !item.barcode.isEmpty {
                if let offItem = await CloudProductCatalogService.shared.lookupProduct(barcode: item.barcode) {
                    if offItem.kcal100g > 0 || offItem.protein100g > 0 {
                        updatedKcal = offItem.kcal100g
                        updatedP = offItem.protein100g
                        updatedC = offItem.carbs100g
                        updatedF = offItem.fat100g
                        updatedFib = offItem.fiber100g
                        didEnrich = true
                    }
                }
            }

            // 2. Standard Commodity / BLS Reference Table Fallback
            if !didEnrich {
                let n = item.name.lowercased()
                if n.contains("skyr") {
                    updatedKcal = 65; updatedP = 11.0; updatedC = 4.0; updatedF = 0.2; updatedFib = 0.0; didEnrich = true
                } else if n.contains("quark") {
                    updatedKcal = 68; updatedP = 12.0; updatedC = 4.1; updatedF = 0.2; updatedFib = 0.0; didEnrich = true
                } else if n.contains("thunf") {
                    updatedKcal = 112; updatedP = 26.0; updatedC = 0.0; updatedF = 0.8; updatedFib = 0.0; didEnrich = true
                } else if n.contains("hafer") {
                    updatedKcal = 370; updatedP = 13.5; updatedC = 58.7; updatedF = 7.0; updatedFib = 10.0; didEnrich = true
                } else if n.contains("kartoffel") {
                    updatedKcal = 77; updatedP = 2.0; updatedC = 17.0; updatedF = 0.1; updatedFib = 2.1; didEnrich = true
                } else if n.contains("reis") {
                    updatedKcal = 360; updatedP = 7.0; updatedC = 78.0; updatedF = 0.7; updatedFib = 1.4; didEnrich = true
                } else if n.contains("hähnchen") || n.contains("huhn") {
                    updatedKcal = 106; updatedP = 23.0; updatedC = 0.0; updatedF = 1.2; updatedFib = 0.0; didEnrich = true
                } else if n.contains("ei") || n.contains("eier") {
                    updatedKcal = 143; updatedP = 12.8; updatedC = 0.7; updatedF = 9.9; updatedFib = 0.0; didEnrich = true
                } else if n.contains("bohne") || n.contains("kidney") {
                    updatedKcal = 110; updatedP = 8.4; updatedC = 15.0; updatedF = 0.5; updatedFib = 6.5; didEnrich = true
                } else if n.contains("kichererbse") {
                    updatedKcal = 120; updatedP = 7.0; updatedC = 17.0; updatedF = 2.5; updatedFib = 5.0; didEnrich = true
                } else if n.contains("apfel") {
                    updatedKcal = 52; updatedP = 0.3; updatedC = 13.8; updatedF = 0.2; updatedFib = 2.4; didEnrich = true
                } else if n.contains("beere") {
                    updatedKcal = 45; updatedP = 1.0; updatedC = 7.5; updatedF = 0.5; updatedFib = 4.5; didEnrich = true
                } else if n.contains("banan") {
                    updatedKcal = 89; updatedP = 1.1; updatedC = 22.8; updatedF = 0.3; updatedFib = 2.6; didEnrich = true
                } else if n.contains("whey") || n.contains("protein") {
                    updatedKcal = 390; updatedP = 75.0; updatedC = 6.0; updatedF = 5.5; updatedFib = 1.0; didEnrich = true
                } else if n.contains("toast") || n.contains("brot") {
                    updatedKcal = 225; updatedP = 8.0; updatedC = 42.0; updatedF = 1.5; updatedFib = 6.0; didEnrich = true
                }
            }

            if didEnrich {
                await MainActor.run {
                    if let idx = self.pantryItems.firstIndex(where: { $0.id == item.id }) {
                        self.pantryItems[idx].kcal100g = updatedKcal
                        self.pantryItems[idx].protein100g = updatedP
                        self.pantryItems[idx].carbs100g = updatedC
                        self.pantryItems[idx].fat100g = updatedF
                        self.pantryItems[idx].fiber100g = updatedFib
                        enrichedCount += 1
                    }
                }
            }
        }

        if enrichedCount > 0 {
            await MainActor.run {
                self.savePantry()
            }
        }
        return enrichedCount
    }

    // MARK: - Subtractive Depletion & Logging

    public func depleteAndLog(
        item: PantryItem,
        amount: Double,
        isPieceCount: Bool = false,
        inputUnit: String? = nil,
        mealType: String = "Mahlzeit",
        syncCalendar: Bool = true,
        recipeId: String? = nil,
        recipeName: String? = nil,
        recipeBatchId: String? = nil,
        targetDate: Date? = nil
    ) {
        guard amount > 0 else { return }

        let calculatedGrams: Double
        let stockDeduction: Double

        if item.hasSubUnits && isPieceCount {
            // Deduct in sub-units (e.g. 2 Riegel of 45g = 90g)
            let subSize = item.effectiveSubUnitSize
            calculatedGrams = amount * subSize
            stockDeduction = (item.unit.lowercased() == "stück" || item.unit.lowercased() == "stk") ? amount : (amount * subSize)
        } else if item.isPieceBased {
            if isPieceCount {
                // Direct piece entry e.g. 4 Stück
                stockDeduction = amount
                calculatedGrams = amount * item.unitWeightGrams
            } else {
                // Mass in grams e.g. 220g eggs
                calculatedGrams = amount
                stockDeduction = max(1.0, (amount / item.unitWeightGrams).rounded())
            }
        } else if item.isLiterUnit {
            let u = inputUnit?.lowercased().trimmingCharacters(in: .whitespaces) ?? ""
            if u == "ml" || u == "g" || (u.isEmpty && amount >= 10.0) {
                // Milliliter entry e.g. 15 ml or 250 ml from a 0.5L / 1.0L bottle
                stockDeduction = amount / 1000.0
                calculatedGrams = amount
            } else {
                // Liter entry e.g. 0.25 L
                stockDeduction = amount
                calculatedGrams = amount * 1000.0
            }
        } else {
            // Mass in grams or ml
            let u = inputUnit?.lowercased().trimmingCharacters(in: .whitespaces) ?? ""
            if u == "l" {
                stockDeduction = amount * 1000.0
                calculatedGrams = amount * 1000.0
            } else {
                calculatedGrams = amount
                stockDeduction = amount
            }
        }

        // 1. Deduct stock
        var remainingStock: Double = 0.0
        if let idx = pantryItems.firstIndex(where: { $0.id == item.id }) {
            let newQty = max(0.0, pantryItems[idx].currentStockQty - stockDeduction)
            pantryItems[idx].currentStockQty = newQty
            remainingStock = newQty
            savePantry()

            // Check auto restock
            checkAutoRestock(for: pantryItems[idx])
        }

        // 2. Append meal log entry
        let entry = MealLogEntry(
            timestamp: targetDate ?? Date(),
            item: item,
            weightGrams: calculatedGrams,
            mealType: mealType,
            recipeId: recipeId,
            recipeName: recipeName,
            recipeBatchId: recipeBatchId
        )
        mealLogs.insert(entry, at: 0)
        saveLogs()

        // 3. Compute macros
        let k = (calculatedGrams / 100.0) * item.kcal100g
        let p = (calculatedGrams / 100.0) * item.protein100g
        let c = (calculatedGrams / 100.0) * item.carbs100g
        let f = (calculatedGrams / 100.0) * item.fat100g
        let fib = (calculatedGrams / 100.0) * item.fiber100g

        // 3.0 C++ Single Source of Truth Validation (GrowCoreEngine C ABI)
        var atwaterCalories: Double = 0.0
        _ = grow_core_validate_macros(k, p, c, f, fib, &atwaterCalories)

        // 3.0.1 Append-Only SQLite WAL Persistence (Eliminating Disk-Muda)
        let mealDateKey = dateKey(for: targetDate ?? Date())
        GrowDatabase.shared.performAsync { db in
            guard let db = db else { return }
            var stmt: OpaquePointer?
            let sql = "INSERT OR REPLACE INTO meals (id, date_key, timestamp, name, calories, protein_g, carbs_g, fat_g, meal_type) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);"
            if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
                sqlite3_bind_text(stmt, 1, (entry.id as NSString).utf8String, -1, nil)
                sqlite3_bind_text(stmt, 2, (mealDateKey as NSString).utf8String, -1, nil)
                sqlite3_bind_double(stmt, 3, (targetDate ?? Date()).timeIntervalSince1970)
                sqlite3_bind_text(stmt, 4, (item.name as NSString).utf8String, -1, nil)
                sqlite3_bind_double(stmt, 5, k)
                sqlite3_bind_double(stmt, 6, p)
                sqlite3_bind_double(stmt, 7, c)
                sqlite3_bind_double(stmt, 8, f)
                sqlite3_bind_text(stmt, 9, (mealType as NSString).utf8String, -1, nil)
                sqlite3_step(stmt)
            }
            sqlite3_finalize(stmt)
        }

        // 3.1 Telemetry Logic Violation Radar
        if k > 1200 {
            GrowTelemetryService.shared.logLogicViolation(
                appName: "Growcery",
                category: .nutritionExcess,
                title: "Hyper-kalorische Einzelmahlzeit",
                detail: "Mahlzeit \(item.name) enthaelt \(Int(k)) kcal (Grenzwert: 1.200 kcal). Erhoehtes Risiko fuer Magenwandspannung und Reflux.",
                metadata: ["item": item.name, "kcal": "\(Int(k))"]
            )
        }
        if todayKcal > 2500 {
            GrowTelemetryService.shared.logLogicViolation(
                appName: "Growcery",
                category: .nutritionExcess,
                title: "Tages-Kalorienbudget ueberschritten",
                detail: "Tagesaufnahme betraegt \(Int(todayKcal)) kcal (Budget: 1.850 - 2.000 kcal).",
                metadata: ["todayKcal": "\(Int(todayKcal))"]
            )
        }

        // 4. Trigger calendar sync if enabled
        if syncCalendar {
            let unitDesc = item.isPieceBased && isPieceCount ? "\(Int(amount)) \(item.unit)" : "\(Int(calculatedGrams))g"
            var extra = "Verzehrte Menge: \(unitDesc)\nRestbestand Vorrat: \(Int(remainingStock)) \(item.unit)\nMarke: \(item.brand)\nGeschäft: \(item.store)"
            let prof = item.effectiveProfile()
            var micros: [String] = []
            if let val = prof.calcium { micros.append("Kalzium: \(String(format: "%.1f", val * calculatedGrams / 100.0)) mg") }
            if let val = prof.magnesium { micros.append("Magnesium: \(String(format: "%.1f", val * calculatedGrams / 100.0)) mg") }
            if let val = prof.iron { micros.append("Eisen: \(String(format: "%.1f", val * calculatedGrams / 100.0)) mg") }
            if let val = prof.zinc { micros.append("Zink: \(String(format: "%.1f", val * calculatedGrams / 100.0)) mg") }
            if let val = prof.potassium { micros.append("Kalium: \(String(format: "%.1f", val * calculatedGrams / 100.0)) mg") }
            if let val = prof.vitaminC { micros.append("Vitamin C: \(String(format: "%.1f", val * calculatedGrams / 100.0)) mg") }
            if let val = prof.vitaminD { micros.append("Vitamin D: \(String(format: "%.1f", val * calculatedGrams / 100.0)) ug") }
            if !micros.isEmpty {
                extra += "\n\nErfasste Mikronährstoffe:\n" + micros.joined(separator: "\n")
            }

            CalendarSyncService.shared.syncMealEvent(
                title: item.name,
                kcal: k,
                protein: p,
                carbs: c,
                fat: f,
                fiber: fib,
                details: extra
            )
        }

        // 5. 2-Way Health Synchronization (Push to HealthKit / Google Health)
        HealthKitService.shared.writeMealNutrients(protein: p, carbs: c, fat: f, calories: Double(k), date: Date())

        // 6. Trigger haptic feedback
        HapticFeedbackService.shared.latchEngaged()
    }

    public func depleteAndLog(item: PantryItem, weightGrams: Double, mealType: String = "Mahlzeit", syncCalendar: Bool = true) {
        depleteAndLog(item: item, amount: weightGrams, isPieceCount: false, mealType: mealType, syncCalendar: syncCalendar)
    }

    public func quickLogProteinSnack(name: String, proteinGrams: Double, kcal: Double, carbs: Double = 0.0, fat: Double = 0.0, fiber: Double = 0.0, targetDate: Date? = nil) {
        let dummyItem = PantryItem(
            name: name,
            brand: "QuickLog",
            barcode: "",
            defaultPackQty: 100,
            defaultPrice: 0.0,
            currentStockQty: 1000,
            unit: "g",
            kcal100g: kcal,
            protein100g: proteinGrams,
            carbs100g: carbs,
            fat100g: fat,
            fiber100g: fiber
        )
        let entry = MealLogEntry(
            timestamp: targetDate ?? Date(),
            item: dummyItem,
            weightGrams: 100.0,
            mealType: "Snack"
        )
        mealLogs.insert(entry, at: 0)
        saveLogs()
        syncTagesbilanzToBridge()
        HealthKitService.shared.writeMealNutrients(protein: proteinGrams, carbs: carbs, fat: fat, calories: kcal, date: targetDate ?? Date())
        HapticFeedbackService.shared.commitSuccess()
    }

    public func depleteAndLogCustomizedTemplate(
        templateName: String,
        category: String,
        ingredients: [(item: PantryItem, grams: Double, pieceCount: Double?)]
    ) {
        var totalKcal: Double = 0.0
        var totalProtein: Double = 0.0
        var totalCarbs: Double = 0.0
        var totalFat: Double = 0.0
        var totalFiber: Double = 0.0
        var ingSummary: [String] = []
        let batchId = UUID().uuidString

        for ing in ingredients {
            let item = ing.item
            let isPiece = item.isPieceBased && ing.pieceCount != nil
            let amount = isPiece ? (ing.pieceCount ?? 1.0) : ing.grams

            depleteAndLog(
                item: item,
                amount: amount,
                isPieceCount: isPiece,
                mealType: templateName,
                syncCalendar: false,
                recipeName: templateName,
                recipeBatchId: batchId
            )

            let g = isPiece ? ((ing.pieceCount ?? 1.0) * item.unitWeightGrams) : ing.grams
            totalKcal += (g / 100.0) * item.kcal100g
            totalProtein += (g / 100.0) * item.protein100g
            totalCarbs += (g / 100.0) * item.carbs100g
            totalFat += (g / 100.0) * item.fat100g
            totalFiber += (g / 100.0) * item.fiber100g

            if isPiece {
                ingSummary.append("- \(item.name): \(Int(ing.pieceCount ?? 1.0)) \(item.unit) (ca. \(Int(g))g)")
            } else {
                ingSummary.append("- \(item.name): \(Int(g))g")
            }
        }

        CalendarSyncService.shared.syncMealEvent(
            title: templateName,
            kcal: totalKcal,
            protein: totalProtein,
            carbs: totalCarbs,
            fat: totalFat,
            fiber: totalFiber,
            details: "Angepasste Rezeptur:\n" + ingSummary.joined(separator: "\n")
        )

        HapticFeedbackService.shared.commitSuccess()
    }

    public func updateMealLog(id: String, newWeightGrams: Double, newMealType: String? = nil, newTimestamp: Date? = nil) {
        guard let idx = mealLogs.firstIndex(where: { $0.id == id }), newWeightGrams > 0 else { return }
        let oldLog = mealLogs[idx]
        let oldGrams = oldLog.weightGrams
        let deltaGrams = newWeightGrams - oldGrams
        let mealType = newMealType ?? oldLog.mealType
        let timestamp = newTimestamp ?? oldLog.timestamp

        if let pIdx = pantryItems.firstIndex(where: { $0.id == oldLog.pantryItemId }) {
            let item = pantryItems[pIdx]

            // Adjust pantry stock
            if item.isPieceBased {
                let unitWeight = max(1.0, item.unitWeightGrams)
                let deltaPieces = deltaGrams / unitWeight
                pantryItems[pIdx].currentStockQty = max(0.0, pantryItems[pIdx].currentStockQty - deltaPieces)
            } else if item.isLiterUnit {
                pantryItems[pIdx].currentStockQty = max(0.0, pantryItems[pIdx].currentStockQty - (deltaGrams / 1000.0))
            } else {
                pantryItems[pIdx].currentStockQty = max(0.0, pantryItems[pIdx].currentStockQty - deltaGrams)
            }
            savePantry()

            let updated = MealLogEntry(
                id: oldLog.id,
                timestamp: timestamp,
                item: item,
                weightGrams: newWeightGrams,
                mealType: mealType,
                recipeId: oldLog.recipeId,
                recipeName: oldLog.recipeName,
                recipeBatchId: oldLog.recipeBatchId
            )
            mealLogs[idx] = updated
        } else {
            let ratio = newWeightGrams / max(1.0, oldGrams)
            mealLogs[idx].timestamp = timestamp
            mealLogs[idx].weightGrams = newWeightGrams
            mealLogs[idx].mealType = mealType
            mealLogs[idx].kcal = (oldLog.kcal * ratio).rounded()
            mealLogs[idx].protein = ((oldLog.protein * ratio) * 10).rounded() / 10
            mealLogs[idx].carbs = ((oldLog.carbs * ratio) * 10).rounded() / 10
            mealLogs[idx].fat = ((oldLog.fat * ratio) * 10).rounded() / 10
            mealLogs[idx].fiber = ((oldLog.fiber * ratio) * 10).rounded() / 10
            mealLogs[idx].cost = ((oldLog.cost * ratio) * 100).rounded() / 100
        }

        saveLogs()
        syncTagesbilanzToBridge()
        HapticFeedbackService.shared.commitSuccess()
    }

    public func deleteMealLog(id: String) {
        if let idx = mealLogs.firstIndex(where: { $0.id == id }) {
            let log = mealLogs[idx]
            // Restore stock if pantry item exists
            if let pIdx = pantryItems.firstIndex(where: { $0.id == log.pantryItemId }) {
                let item = pantryItems[pIdx]
                if item.isPieceBased {
                    let unitWeight = max(1.0, item.unitWeightGrams)
                    let pieces = log.weightGrams / unitWeight
                    pantryItems[pIdx].currentStockQty += pieces
                } else if item.isLiterUnit {
                    pantryItems[pIdx].currentStockQty += (log.weightGrams / 1000.0)
                } else {
                    pantryItems[pIdx].currentStockQty += log.weightGrams
                }
                savePantry()
            }
            mealLogs.remove(at: idx)
            saveLogs()
            syncTagesbilanzToBridge()
            syncMealsLedgerToBridge()
            HapticFeedbackService.shared.lightDetent()
        }
    }

    public func deleteRecipeBatch(batchId: String) {
        let logsToDelete = mealLogs.filter { $0.recipeBatchId == batchId }
        for log in logsToDelete {
            deleteMealLog(id: log.id)
        }
    }

    // MARK: - Shopping & Restock Engine

    private func checkAutoRestock(for item: PantryItem) {
        if item.isLowStock {
            if !shoppingList.contains(where: { $0.pantryItemId == item.id }) {
                let shopItem = ShoppingItem(item: item, quantity: 1)
                shoppingList.append(shopItem)
                saveShopping()
            }
        }
    }

    public func toggleShoppingItem(id: String) {
        if let idx = shoppingList.firstIndex(where: { $0.id == id }) {
            shoppingList[idx].isChecked.toggle()
            saveShopping()
            HapticFeedbackService.shared.mechanicalClick()
        }
    }

    // MARK: - Dynamic Food Budgeting & GrowFinance Proration Engine
    public var monthlyFinanceFoodBudget: Double {
        get {
            if sharedFinance.dynamicFoodBudgetMonthly > 0 {
                return sharedFinance.dynamicFoodBudgetMonthly
            }
            let val = UserDefaults.standard.double(forKey: "growcery_monthly_finance_budget")
            return val > 0 ? val : 350.0
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "growcery_monthly_finance_budget")
            objectWillChange.send()
        }
    }

    public var foodPurchasedThisMonth: Double {
        let cal = Calendar.current
        let now = Date()
        let curMonth = cal.component(.month, from: now)
        let curYear = cal.component(.year, from: now)
        return receipts.filter {
            cal.component(.month, from: $0.date) == curMonth &&
            cal.component(.year, from: $0.date) == curYear
        }.reduce(0.0) { $0 + $1.totalAmount }
    }

    public var remainingCurrentMonthBudget: Double {
        if sharedFinance.dynamicFoodBudgetRemaining > 0 {
            return sharedFinance.dynamicFoodBudgetRemaining
        }
        return max(0.0, monthlyFinanceFoodBudget - foodPurchasedThisMonth)
    }

    public struct HorizonBudgetBreakdown: Equatable {
        public let horizonDays: Int
        public let daysInCurrentMonth: Int
        public let daysInNextMonth: Int
        public let currentMonthRemaining: Double
        public let nextMonthProrated: Double
        public let totalAvailableBudget: Double
        public let isCrossMonth: Bool
        public let dailyAllocatedBudget: Double

        public init(
            horizonDays: Int,
            daysInCurrentMonth: Int,
            daysInNextMonth: Int,
            currentMonthRemaining: Double,
            nextMonthProrated: Double,
            totalAvailableBudget: Double,
            isCrossMonth: Bool,
            dailyAllocatedBudget: Double
        ) {
            self.horizonDays = horizonDays
            self.daysInCurrentMonth = daysInCurrentMonth
            self.daysInNextMonth = daysInNextMonth
            self.currentMonthRemaining = currentMonthRemaining
            self.nextMonthProrated = nextMonthProrated
            self.totalAvailableBudget = totalAvailableBudget
            self.isCrossMonth = isCrossMonth
            self.dailyAllocatedBudget = dailyAllocatedBudget
        }
    }

    public func calculateCrossMonthBudget(horizonDays: Int, fromDate: Date = Date()) -> HorizonBudgetBreakdown {
        let cal = Calendar.current
        let daysInMonth = cal.range(of: .day, in: .month, for: fromDate)?.count ?? 30
        let currentDay = cal.component(.day, from: fromDate)

        let remainingDaysCurMonth = max(1, daysInMonth - currentDay + 1)
        let daysInCur = min(horizonDays, remainingDaysCurMonth)
        let daysInNext = max(0, horizonDays - daysInCur)

        let curRem = remainingCurrentMonthBudget

        if daysInNext > 0 {
            let nextMonthDaily = sharedFinance.dailyFoodRate > 0 ? sharedFinance.dailyFoodRate : (monthlyFinanceFoodBudget / 30.0)
            let nextProrated = Double(daysInNext) * nextMonthDaily
            let total = curRem + nextProrated
            let daily = horizonDays > 0 ? (total / Double(horizonDays)) : 0.0
            return HorizonBudgetBreakdown(
                horizonDays: horizonDays,
                daysInCurrentMonth: daysInCur,
                daysInNextMonth: daysInNext,
                currentMonthRemaining: (curRem * 100).rounded() / 100,
                nextMonthProrated: (nextProrated * 100).rounded() / 100,
                totalAvailableBudget: (total * 100).rounded() / 100,
                isCrossMonth: true,
                dailyAllocatedBudget: (daily * 100).rounded() / 100
            )
        } else {
            let total = curRem
            let daily = horizonDays > 0 ? (total / Double(horizonDays)) : 0.0
            return HorizonBudgetBreakdown(
                horizonDays: horizonDays,
                daysInCurrentMonth: daysInCur,
                daysInNextMonth: 0,
                currentMonthRemaining: (curRem * 100).rounded() / 100,
                nextMonthProrated: 0.0,
                totalAvailableBudget: (total * 100).rounded() / 100,
                isCrossMonth: false,
                dailyAllocatedBudget: (daily * 100).rounded() / 100
            )
        }
    }

    public func checkInPurchasedItems(customStoreName: String = "PENNY") {
        var completedItems: [ShoppingItem] = []
        for item in shoppingList where item.isChecked {
            if let pIdx = pantryItems.firstIndex(where: { $0.id == item.pantryItemId }) {
                let addedGrams = Double(item.quantity) * pantryItems[pIdx].defaultPackQty
                pantryItems[pIdx].currentStockQty += addedGrams
            }
            completedItems.append(item)
        }
        guard !completedItems.isEmpty else { return }

        // Poka-Yoke: Reiner physischer Bestandswechsel.
        // Keine automatische Phantom-Finanzquittung hier, um Doppelbuchungen mit
        // dem anschließenden Kassenbon-Scan via ReceiptScannerView auszuschließen.
        let completedIds = Set(completedItems.map { $0.id })
        shoppingList.removeAll(where: { completedIds.contains($0.id) })

        savePantry()
        saveShopping(deletedIds: Array(completedIds))
        HapticFeedbackService.shared.commitSuccess()
    }

    public func purchaseSingleShoppingItem(_ item: ShoppingItem) {
        if let pIdx = pantryItems.firstIndex(where: { $0.id == item.pantryItemId }) {
            let addedGrams = Double(item.quantity) * pantryItems[pIdx].defaultPackQty
            pantryItems[pIdx].currentStockQty += addedGrams
        }
        let lineItem = ReceiptLineItem(
            rawText: item.name,
            parsedPrice: item.price,
            quantity: item.quantity,
            quantityNote: "\(item.quantity) Stk x \(String(format: "%.2f €", item.price))",
            matchedPantryItemId: item.pantryItemId,
            matchedPantryItemName: item.name,
            previousPrice: nil,
            confidenceScore: 1.0,
            isConfirmed: true,
            isNonFood: false
        )
        let receipt = ReceiptRecord(
            date: Date(),
            storeName: item.store.isEmpty ? "PENNY" : item.store,
            totalAmount: item.totalCost,
            items: [lineItem],
            notes: "1-Tap Einkauf: \(item.name)"
        )
        receipts.insert(receipt, at: 0)
        saveReceipts()

        shoppingList.removeAll(where: { $0.id == item.id })
        savePantry()
        saveShopping(deletedId: item.id)
        HapticFeedbackService.shared.commitSuccess()
    }

    public func addManualShoppingItem(pantryItem: PantryItem, packs: Int = 1) {
        let cleanName = pantryItem.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if let idx = shoppingList.firstIndex(where: { 
            $0.pantryItemId == pantryItem.id || 
            $0.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == cleanName 
        }) {
            shoppingList[idx].quantity += packs
        } else {
            shoppingList.append(ShoppingItem(item: pantryItem, quantity: packs))
        }
        saveShopping()
        HapticFeedbackService.shared.mechanicalClick()
    }

    public func addMealTemplateToShoppingList(_ template: MealTemplate) {
        for ingredient in template.ingredients {
            if let matched = pantryItems.first(where: { 
                $0.id == ingredient.pantryItemId || 
                $0.name.lowercased() == ingredient.name.lowercased() 
            }) {
                addManualShoppingItem(pantryItem: matched, packs: 1)
            } else {
                addCustomShoppingItem(
                    name: ingredient.name,
                    brand: "Zutat",
                    price: 0.0,
                    store: "PENNY",
                    quantity: 1,
                    category: "Nahrungsmittel"
                )
            }
        }
        HapticFeedbackService.shared.commitSuccess()
    }

    public func addCustomShoppingItem(name: String, brand: String, price: Double, store: String = "AMAZON", quantity: Int = 1, category: String = "Pflege & Hygiene", webUrl: String? = nil) {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if let idx = shoppingList.firstIndex(where: { 
            $0.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == cleanName 
        }) {
            shoppingList[idx].quantity += quantity
            if let webUrl = webUrl, shoppingList[idx].webUrl == nil {
                shoppingList[idx].webUrl = webUrl
            }
        } else {
            let item = ShoppingItem(
                name: name,
                brand: brand,
                price: price,
                store: store,
                quantity: quantity,
                category: category,
                webUrl: webUrl
            )
            shoppingList.append(item)
        }
        saveShopping()
        HapticFeedbackService.shared.commitSuccess()
    }

    public func addRecipeToShoppingList(template: MealTemplate) {
        for ingredient in template.ingredients {
            let cleanIngName = ingredient.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if let pantryItem = pantryItems.first(where: { 
                $0.id == ingredient.pantryItemId || 
                $0.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == cleanIngName 
            }) {
                addManualShoppingItem(pantryItem: pantryItem, packs: 1)
            } else {
                let syntheticItem = PantryItem(
                    name: ingredient.name,
                    brand: "Vorrat",
                    barcode: "",
                    defaultPackQty: max(100.0, ingredient.grams),
                    defaultPrice: 0.0,
                    currentStockQty: 0,
                    unit: "g",
                    kcal100g: 0,
                    protein100g: 0,
                    carbs100g: 0,
                    fat100g: 0,
                    fiber100g: 0,
                    nutriscore: "a",
                    store: "PENNY"
                )
                addManualShoppingItem(pantryItem: syntheticItem, packs: 1)
            }
        }
        HapticFeedbackService.shared.commitSuccess()
    }

    public func removeShoppingItem(id: String) {
        shoppingList.removeAll(where: { $0.id == id })
        saveShopping(deletedId: id)
    }

    public func saveShopping(deletedId: String? = nil, deletedIds: [String] = []) {
        save(items: shoppingList, to: shoppingURL)
        let existingBridge = GrowSuiteBridge.shared.loadShopping()
        var updatedDeleted = existingBridge.deletedIds
        var allNewDeleted = deletedIds
        if let dId = deletedId {
            allNewDeleted.append(dId)
        }
        for dId in allNewDeleted {
            if !updatedDeleted.contains(dId) {
                updatedDeleted.append(dId)
            }
        }
        if updatedDeleted.count > 200 {
            updatedDeleted.removeFirst(updatedDeleted.count - 200)
        }
        let deletedSet = Set(updatedDeleted)
        let bridgeItems = shoppingList
            .filter { !deletedSet.contains($0.id) }
            .map { item in
                SharedShoppingItem(
                    id: item.id,
                    name: item.name,
                    price: item.price,
                    store: item.store,
                    quantity: item.quantity,
                    category: item.category,
                    webUrl: item.webUrl,
                    isBought: item.isChecked,
                    isSaved: item.isSaved,
                    recurrenceRule: item.recurrenceRule,
                    lastUpdated: Date()
                )
            }
        GrowSuiteBridge.shared.saveShopping(SharedShoppingPayload(items: bridgeItems, deletedIds: updatedDeleted))
        DarwinNotificationCenter.post(DarwinNotificationCenter.shoppingUpdated)
    }

    private func loadShopping() {
        if let items: [ShoppingItem] = load(from: shoppingURL) {
            let mockPrefixes = ["shop_1", "shop_2", "shop_3", "shop_4", "shop_5", "shop_6", "shop_7", "shop_8", "shop_9", "shop_10", "shop_11", "shop_12", "shop_13", "shop_14", "shop_15", "shop_16", "shop-1788799469281-"]
            self.shoppingList = items.filter { item in
                !mockPrefixes.contains(where: { item.id.hasPrefix($0) })
            }
            if self.shoppingList.count != items.count {
                saveShopping()
            }
        }
    }

    // MARK: - Daily Totals & Computed Metrics

    public struct CachedDailyMacros {
        public var kcal: Double
        public var protein: Double
        public var carbs: Double
        public var fat: Double
        public var fiber: Double
        public var cost: Double
    }

    private var dailyMacrosCache: [String: CachedDailyMacros] = [:]

    public func invalidateDailyMacrosCache(for key: String? = nil) {
        if let key = key {
            dailyMacrosCache.removeValue(forKey: key)
        } else {
            dailyMacrosCache.removeAll(keepingCapacity: true)
        }
    }

    public var todayLogs: [MealLogEntry] {
        return logs(for: Date())
    }

    public func logs(for date: Date) -> [MealLogEntry] {
        let key = dateKey(for: date)
        return logsByDate[key] ?? []
    }

    public func supplementNutrition(for date: Date) -> (kcal: Double, protein: Double, carbs: Double, fat: Double, fiber: Double) {
        let key = dateKey(for: date)
        guard let taken = supplementLogs[key], !taken.isEmpty else {
            return (0.0, 0.0, 0.0, 0.0, 0.0)
        }
        var totalKcal: Double = 0.0
        var totalProtein: Double = 0.0
        var totalCarbs: Double = 0.0
        var totalFat: Double = 0.0
        var totalFiber: Double = 0.0

        for dose in allSupplements {
            if taken.contains(dose.id) {
                totalKcal += dose.kcal
                totalProtein += dose.protein
                totalCarbs += dose.carbs
                totalFat += dose.fat
                totalFiber += dose.fiber
            }
        }
        return (totalKcal, totalProtein, totalCarbs, totalFat, totalFiber)
    }

    public func getDailyMacros(for date: Date) -> CachedDailyMacros {
        let key = dateKey(for: date)
        if let cached = dailyMacrosCache[key] {
            return cached
        }
        let dayMealLogs = logs(for: date)
        var totalKcal = 0.0
        var totalProtein = 0.0
        var totalCarbs = 0.0
        var totalFat = 0.0
        var totalFiber = 0.0
        var totalCost = 0.0
        for log in dayMealLogs {
            totalKcal += log.kcal
            totalProtein += log.protein
            totalCarbs += log.carbs
            totalFat += log.fat
            totalFiber += log.fiber
            totalCost += log.cost
        }
        let supp = supplementNutrition(for: date)
        totalKcal += supp.kcal
        totalProtein += supp.protein
        totalCarbs += supp.carbs
        totalFat += supp.fat
        totalFiber += supp.fiber

        let computed = CachedDailyMacros(
            kcal: totalKcal,
            protein: totalProtein,
            carbs: totalCarbs,
            fat: totalFat,
            fiber: totalFiber,
            cost: totalCost
        )
        dailyMacrosCache[key] = computed
        return computed
    }

    public func protein(for date: Date) -> Double {
        return getDailyMacros(for: date).protein
    }

    public func kcal(for date: Date) -> Double {
        return getDailyMacros(for: date).kcal
    }

    public func carbs(for date: Date) -> Double {
        return getDailyMacros(for: date).carbs
    }

    public func fat(for date: Date) -> Double {
        return getDailyMacros(for: date).fat
    }

    public func fiber(for date: Date) -> Double {
        return getDailyMacros(for: date).fiber
    }

    public func cost(for date: Date) -> Double {
        return getDailyMacros(for: date).cost
    }

    public var todayProtein: Double {
        return protein(for: Date())
    }

    public var todayKcal: Double {
        return kcal(for: Date())
    }

    public var todayCarbs: Double {
        return carbs(for: Date())
    }

    public var todayFat: Double {
        return fat(for: Date())
    }

    public var todayFiber: Double {
        return fiber(for: Date())
    }

    public var todayCost: Double {
        return cost(for: Date())
    }

    public var proteinRatio: Double {
        return min(max(todayProtein / targetProtein, 0.0), 1.0)
    }

    public var remainingProtein: Double {
        return max(0.0, targetProtein - todayProtein)
    }

    public var remainingKcal: Double {
        return targetKcal - todayKcal
    }

    public var lowStockItems: [PantryItem] {
        return pantryItems.filter { $0.isLowStock }
    }

    public var shoppingTotalCost: Double {
        return shoppingList.reduce(0.0) { $0 + $1.totalCost }
    }

    public var shoppingTotalProtein: Double {
        var total: Double = 0.0
        for s in shoppingList {
            if let p = pantryItems.first(where: { $0.id == s.pantryItemId }) {
                total += (Double(s.quantity) * p.defaultPackQty / 100.0) * p.protein100g
            }
        }
        return total
    }

    // MARK: - Generic Persistence Helpers

    private func save<T: Encodable>(items: [T], to url: URL) {
        saveObject(items, to: url)
    }

    private func load<T: Decodable>(from url: URL) -> [T]? {
        return loadObject(from: url)
    }

    private func saveObject<T: Encodable>(_ object: T, to url: URL) {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(object)
            try data.write(to: url, options: [.atomicWrite])
        } catch {
            print("LocalStore immediate save error for \(url.lastPathComponent): \(error)")
        }
    }

    public func deletePantryItem(id: String) {
        objectWillChange.send()
        pantryItems.removeAll(where: { $0.id == id })
        savePantry()
        rebuildKnownStoresIndex()
        HapticFeedbackService.shared.commitSuccess()
    }

    private func loadObject<T: Decodable>(from url: URL) -> T? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(T.self, from: data)
        } catch {
            print("LocalStore load error for \(url.lastPathComponent): \(error)")
            return nil
        }
    }

    public func flushAllSync() {
        pendingWorkItemsLock.lock()
        for item in pendingSaveWorkItems.values {
            item.cancel()
        }
        pendingSaveWorkItems.removeAll()
        pendingWorkItemsLock.unlock()

        storageQueue.sync {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            if let d = try? encoder.encode(self.pantryItems) { try? d.write(to: self.pantryURL, options: [.atomicWrite]) }
            if let d = try? encoder.encode(self.mealLogs) { try? d.write(to: self.logsURL, options: [.atomicWrite]) }
            if let d = try? encoder.encode(self.shoppingList) { try? d.write(to: self.shoppingURL, options: [.atomicWrite]) }
            if let d = try? encoder.encode(self.mealTemplates) { try? d.write(to: self.templatesURL, options: [.atomicWrite]) }
            if let d = try? encoder.encode(self.receipts) { try? d.write(to: self.receiptsURL, options: [.atomicWrite]) }
            let suppDict = self.supplementLogs.mapValues { Array($0) }
            if let d = try? encoder.encode(suppDict) { try? d.write(to: self.supplementURL, options: [.atomicWrite]) }
            if let d = try? encoder.encode(self.customSupplements) { try? d.write(to: self.customSupplementsURL, options: [.atomicWrite]) }
            if let d = try? encoder.encode(self.waterLogs) { try? d.write(to: self.waterURL, options: [.atomicWrite]) }
            let skipSuppDict = self.skippedSupplements.mapValues { Array($0) }
            if let d = try? encoder.encode(skipSuppDict) { try? d.write(to: self.skippedSupplementsURL, options: [.atomicWrite]) }
            if let d = try? encoder.encode(self.dailyNotes) { try? d.write(to: self.dailyNotesURL, options: [.atomicWrite]) }
            if let d = try? encoder.encode(self.customStores) { try? d.write(to: self.customStoresURL, options: [.atomicWrite]) }
        }
    }

    public func saveCustomStores() {
        save(items: customStores, to: customStoresURL)
    }

    private func loadCustomStores() {
        if let items: [String] = load(from: customStoresURL) {
            self.customStores = items
        }
    }

    public func switchUserContext() {
        _ = currentUserStorageDirectory
        self.pantryItems = []
        self.mealLogs = []
        self.shoppingList = []
        self.mealTemplates = []
        self.receipts = []
        self.customStores = []
        self.supplementLogs = [:]
        self.customSupplements = []
        self.waterLogs = [:]
        self.skippedSupplements = [:]
        self.dailyNotes = [:]
        self.pantryById = [:]
        self.pantryByNormalizedName = [:]
        self.logsByDate = [:]
        self.dailyMacrosCache = [:]
        self.recipeMacrosCache = [:]

        loadAllData()
        objectWillChange.send()
    }

    public func syncTagesbilanzToBridge() {
        let currentWater = todayWater()
        let payload = SharedMacroPayload(
            protein: todayProtein,
            carbs: todayCarbs,
            fat: todayFat,
            calories: todayKcal,
            proteinTarget: targetProtein,
            caloriesTarget: targetKcal,
            fiber: todayFiber,
            hydrationLiters: currentWater / 1000.0
        )
        GrowSuiteBridge.shared.saveMacros(payload)

        // 1. Importiere abgeschlossenes Workout aus Grow (GymApp)
        if let workout = GrowSuiteBridge.shared.loadLatestWorkout() {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let todayStr = formatter.string(from: Date())
            if workout.dateString == todayStr {
                self.latestSharedWorkout = workout
            }
        }

        // 2. Abgleich der zirkadianen Supplemente (Single Source of Truth)
        let bridgeSupps = GrowSuiteBridge.shared.loadSupplements(for: Date())
        let todayKey = dateKey(for: Date())
        var currentSet = supplementLogs[todayKey] ?? Set<String>()
        var didChange = false
        for (doseId, _) in bridgeSupps.takenDoseIds {
            if !currentSet.contains(doseId) {
                currentSet.insert(doseId)
                didChange = true
            }
        }
        if didChange {
            self.supplementLogs[todayKey] = currentSet
        }

        // 3. Abgleich der Wasserzufuhr mit GrowSuiteBridge
        let bridgeWater = GrowSuiteBridge.shared.loadWater(for: Date())
        if bridgeWater.totalWaterMl > currentWater {
            self.waterLogs[todayKey] = bridgeWater.totalWaterMl
            saveWater()
            HealthKitService.shared.waterIntakeMl = bridgeWater.totalWaterMl
        } else if currentWater > 0 && bridgeWater.totalWaterMl == 0 {
            GrowSuiteBridge.shared.setTotalWater(totalMl: currentWater, sourceApp: "Growcery")
        }

    }

    public func exportMacrosToGymApp() {
        syncTagesbilanzToBridge()
        let p = String(format: "%.1f", todayProtein)
        let k = String(format: "%.0f", todayKcal)
        let c = String(format: "%.1f", todayCarbs)
        let f = String(format: "%.1f", todayFat)
        if let url = URL(string: "gym://syncMacros?protein=\(p)&calories=\(k)&carbs=\(c)&fat=\(f)") {
            UIApplication.shared.open(url)
        }
    }

    private func saveLogs() {
        save(items: mealLogs, to: logsURL)
        syncTagesbilanzToBridge()
        syncMealsLedgerToBridge()
    }

    private func loadLogs() {
        if let items: [MealLogEntry] = load(from: logsURL) {
            self.mealLogs = items
        }
        syncTagesbilanzToBridge()
        syncMealsLedgerToBridge()
    }

    public func syncMealsLedgerToBridge() {
        let mappedMeals: [SharedLoggedMeal] = mealLogs.map { log in
            SharedLoggedMeal(
                id: log.id,
                foodName: log.foodName,
                mealType: log.mealType,
                recipeName: log.recipeName,
                weightGrams: log.weightGrams,
                kcal: log.kcal,
                protein: log.protein,
                carbs: log.carbs,
                fat: log.fat,
                fiber: log.fiber,
                timestamp: log.timestamp
            )
        }
        let ledger = SharedMealsLedger(meals: mappedMeals, lastUpdated: Date())
        GrowSuiteBridge.shared.saveMealsLedger(ledger)
        syncSupplementScheduleToBridge()
    }

    public func syncSupplementScheduleToBridge() {
        let defaultTimes = [
            ("Rhodiola Rosea (500mg)", "06:00", "500mg (3% Salidrosid)", "Kortisol-Modulation & Fokus"),
            ("Magnesium-Malat (1000mg)", "06:30", "1000mg / 150mg elementar", "Mitochondriale ATP-Synthese"),
            ("Vitamin D3 + K2 MK-7", "11:45", "5000 IE D3 + 200mcg K2", "Knochen, Immunsystem & Gefäße"),
            ("Omega-3 EPA/DHA (2000mg)", "16:45", "2000mg Reines Fischöl", "Entzündungshemmung & Kardioprotektion"),
            ("Magnesium-Bisglycinat (1500mg)", "21:00", "1500mg / 200mg elementar", "GABAerge Schlafförderung & Reha")
        ]
        var items: [SharedSupplementScheduleItem] = []
        let cal = Calendar.current
        let today = Date()

        for dayOffset in -14...14 {
            guard let date = cal.date(byAdding: .day, value: dayOffset, to: today) else { continue }
            let key = dateKey(for: date)
            let takenSet = supplementLogs[key] ?? []

            for (title, time, dose, effect) in defaultTimes {
                let id = "\(key)_\(time)"
                let isTaken = takenSet.contains(where: { $0.contains(time) || title.lowercased().contains($0.lowercased()) })
                items.append(SharedSupplementScheduleItem(
                    id: id,
                    title: title,
                    timeString: time,
                    dosage: dose,
                    targetEffect: effect,
                    isTaken: isTaken,
                    takenAt: isTaken ? date : nil,
                    date: date
                ))
            }
        }
        GrowSuiteBridge.shared.saveSupplementScheduleLedger(SharedSupplementScheduleLedger(items: items, lastUpdated: Date()))
    }

    // MARK: - Initial Pantry Seeding (Standard Barracks Staples)

    private func seedDefaultPantry() {
        pantryItems = [
            PantryItem(
                id: "seed_1",
                name: "Vollkornbrot (Kasten)",
                brand: "Penny Ready",
                barcode: "4337185854201",
                defaultPackQty: 500,
                defaultPrice: 0.99,
                currentStockQty: 380,
                kcal100g: 234,
                protein100g: 7.8,
                carbs100g: 43.2,
                fat100g: 1.8,
                fiber100g: 7.5,
                nutriscore: "a",
                store: "PENNY"
            ),
            PantryItem(
                id: "seed_2",
                name: "Thunfisch im eigenen Saft",
                brand: "Berida",
                barcode: "4337185854202",
                defaultPackQty: 150,
                defaultPrice: 1.19,
                currentStockQty: 300,
                kcal100g: 110,
                protein100g: 25.5,
                carbs100g: 0.0,
                fat100g: 0.8,
                fiber100g: 0.0,
                nutriscore: "a",
                store: "PENNY"
            ),
            PantryItem(
                id: "seed_3",
                name: "Gnocchi (Kühlregal)",
                brand: "Penny Ready",
                barcode: "4337185854210",
                defaultPackQty: 500,
                defaultPrice: 0.99,
                currentStockQty: 500,
                kcal100g: 160,
                protein100g: 3.5,
                carbs100g: 34.0,
                fat100g: 0.8,
                fiber100g: 2.1,
                nutriscore: "a",
                store: "PENNY"
            ),
            PantryItem(
                id: "seed_4",
                name: "Gouda gerieben light",
                brand: "Penny",
                barcode: "4337185854204",
                defaultPackQty: 200,
                defaultPrice: 1.49,
                currentStockQty: 170,
                kcal100g: 260,
                protein100g: 30.0,
                carbs100g: 0.5,
                fat100g: 15.0,
                fiber100g: 0.0,
                nutriscore: "b",
                store: "PENNY"
            ),
            PantryItem(
                id: "seed_5",
                name: "Skyr Natur",
                brand: "REWE Bio",
                barcode: "4337185854205",
                defaultPackQty: 500,
                defaultPrice: 1.39,
                currentStockQty: 1000,
                kcal100g: 62,
                protein100g: 11.0,
                carbs100g: 4.0,
                fat100g: 0.2,
                fiber100g: 0.0,
                nutriscore: "a",
                store: "REWE"
            ),
            PantryItem(
                id: "seed_6",
                name: "Designer Whey Protein",
                brand: "ESN",
                barcode: "4250249400010",
                defaultPackQty: 1000,
                defaultPrice: 29.90,
                currentStockQty: 650,
                kcal100g: 380,
                protein100g: 78.0,
                carbs100g: 5.5,
                fat100g: 4.5,
                fiber100g: 1.2,
                nutriscore: "a",
                store: "ONLINE"
            ),
            PantryItem(
                id: "seed_7",
                name: "Haferflocken zart",
                brand: "PENNY",
                barcode: "4337185854207",
                defaultPackQty: 500,
                defaultPrice: 0.69,
                currentStockQty: 850,
                kcal100g: 370,
                protein100g: 13.5,
                carbs100g: 58.7,
                fat100g: 7.0,
                fiber100g: 10.0,
                nutriscore: "a",
                store: "PENNY"
            ),
            PantryItem(
                id: "seed_8",
                name: "Harzer Käse",
                brand: "PENNY",
                barcode: "4337185854208",
                defaultPackQty: 200,
                defaultPrice: 1.29,
                currentStockQty: 40,
                kcal100g: 125,
                protein100g: 30.0,
                carbs100g: 0.1,
                fat100g: 0.5,
                fiber100g: 0.0,
                nutriscore: "a",
                store: "PENNY"
            )
        ]
        savePantry()
    }

    // MARK: - Meal Templates & 1-Tap Depletion

    public func saveTemplates() {
        save(items: mealTemplates, to: templatesURL)
        NutritionalScoringEngine.shared.clearCache()
        recomputeRankedTemplates()
    }

    nonisolated public static func loadBundledPennyRecipes() -> [MealTemplate] {
        if let url = Bundle.main.url(forResource: "penny_recipes", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let recipes = try? JSONDecoder().decode([MealTemplate].self, from: data) {
            return recipes
        }
        let altPath = Bundle.main.bundleURL.appendingPathComponent("penny_recipes.json")
        if let data = try? Data(contentsOf: altPath),
           let recipes = try? JSONDecoder().decode([MealTemplate].self, from: data) {
            return recipes
        }
        return []
    }

    public func loadBundledPennyRecipes() -> [MealTemplate] {
        return Self.loadBundledPennyRecipes()
    }

    private func loadTemplates() {
        self.mealTemplates = []
        save(items: [MealTemplate](), to: templatesURL)
        recomputeRankedTemplates()
    }

    // MARK: - Daily Notes Persistence
    public func saveDailyNotes() {
        if let data = try? JSONEncoder().encode(dailyNotes) {
            try? data.write(to: dailyNotesURL, options: .atomic)
        }
    }

    private func loadDailyNotes() {
        if let data = try? Data(contentsOf: dailyNotesURL),
           let loaded = try? JSONDecoder().decode([String: String].self, from: data) {
            self.dailyNotes = loaded
        }
    }

    public func note(for date: Date) -> String {
        let key = dateKey(for: date)
        return dailyNotes[key] ?? ""
    }

    public func setNote(_ text: String, for date: Date) {
        let key = dateKey(for: date)
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            dailyNotes.removeValue(forKey: key)
        } else {
            dailyNotes[key] = trimmed
        }
        saveDailyNotes()
    }

    public func seedDefaultTemplates() {
        let masterTemplates = MasterDataSeed.getMasterTemplates()
        self.mealTemplates = masterTemplates
        saveTemplates()
    }

    public func effectiveGrams(for ing: TemplateIngredient, item: PantryItem) -> Double {
        if item.isPieceBased && ing.grams <= 20 {
            return ing.grams * item.unitWeightGrams
        }
        return ing.grams
    }

    public func depleteAndLogTemplate(_ template: MealTemplate, targetDate: Date? = nil) {
        let batchId = UUID().uuidString
        for ingredient in template.ingredients {
            if let item = pantryItems.first(where: { $0.id == ingredient.pantryItemId || $0.name.lowercased() == ingredient.name.lowercased() }) {
                let unit = ingredient.unit?.lowercased() ?? (item.isLiterUnit ? "ml" : "g")
                let amountToDeplete = ingredient.rawAmount ?? ingredient.grams
                if item.isPieceBased {
                    let isPCount = unit == "stk" || unit == "stück" || unit == "stueck" || ingredient.grams <= 20
                    depleteAndLog(item: item, amount: amountToDeplete, isPieceCount: isPCount, mealType: template.name, syncCalendar: false, recipeId: template.id, recipeName: template.name, recipeBatchId: batchId, targetDate: targetDate)
                } else if item.isLiterUnit {
                    depleteAndLog(item: item, amount: amountToDeplete, isPieceCount: false, inputUnit: unit, mealType: template.name, syncCalendar: false, recipeId: template.id, recipeName: template.name, recipeBatchId: batchId, targetDate: targetDate)
                } else {
                    depleteAndLog(item: item, amount: amountToDeplete, isPieceCount: false, inputUnit: unit, mealType: template.name, syncCalendar: false, recipeId: template.id, recipeName: template.name, recipeBatchId: batchId, targetDate: targetDate)
                }
            }
        }

        // Sync consolidated meal event to Google Calendar
        let tKcal = templateKcal(for: template)
        let tProtein = templateProtein(for: template)
        let tCarbs = templateCarbs(for: template)
        let tFat = templateFat(for: template)
        let tFiber = templateFiber(for: template)
        let ingDetails = template.ingredients.map { "- \($0.name): \(Int($0.displayAmount))\($0.displayUnit)" }.joined(separator: "\n")

        CalendarSyncService.shared.syncMealEvent(
            title: template.name,
            kcal: tKcal,
            protein: tProtein,
            carbs: tCarbs,
            fat: tFat,
            fiber: tFiber,
            details: "Zutaten & Rezeptur:\n\(ingDetails)"
        )

        HapticFeedbackService.shared.commitSuccess()
    }

    public func updateMealTemplate(_ updated: MealTemplate) {
        if let idx = mealTemplates.firstIndex(where: { $0.id == updated.id }) {
            mealTemplates[idx] = updated
        } else {
            mealTemplates.append(updated)
        }
        saveTemplates()
        HapticFeedbackService.shared.commitSuccess()
    }

    public func deleteMealTemplate(id: String) {
        mealTemplates.removeAll(where: { $0.id == id })
        saveTemplates()
    }

    public func saveRecipeImage(_ image: UIImage, templateId: String) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let filename = "recipe_\(templateId)_\(Int(Date().timeIntervalSince1970)).jpg"
        let url = docs.appendingPathComponent(filename)
        recipeImageCache.setObject(image, forKey: filename as NSString)
        storageQueue.async {
            do {
                try data.write(to: url, options: [.atomicWrite])
            } catch {
                print("Error saving recipe image: \(error)")
            }
        }
        return filename
    }

    public func getRecipeImage(filename: String?) -> UIImage? {
        guard let fn = filename, !fn.isEmpty else { return nil }
        let key = fn as NSString
        if let cached = recipeImageCache.object(forKey: key) {
            return cached
        }
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = docs.appendingPathComponent(fn)
        if let img = UIImage(contentsOfFile: url.path) {
            recipeImageCache.setObject(img, forKey: key)
            return img
        }
        return nil
    }

    public func templateMacros(for template: MealTemplate) -> RecipeMacros {
        if let cached = recipeMacrosCache[template.id] {
            return cached
        }
        var totalP = 0.0
        var totalK = 0.0
        var totalC = 0.0
        var totalF = 0.0
        var totalFib = 0.0
        var totalPrice: Double? = 0.0

        for ing in template.ingredients {
            guard let item = findPantryItem(for: ing) else {
                totalPrice = nil
                continue
            }
            let g = effectiveGrams(for: ing, item: item)
            let factor = g / 100.0
            totalP += factor * item.protein100g
            totalK += factor * item.kcal100g
            totalC += factor * item.carbs100g
            totalF += factor * item.fat100g
            totalFib += factor * item.fiber100g

            if let cur = totalPrice {
                if item.defaultPrice > 0.005 && item.defaultPackQty > 0 {
                    if item.isPieceBased {
                        let pieces = (ing.grams > 20) ? (ing.grams / item.unitWeightGrams) : ing.grams
                        let costPerPiece = item.defaultPrice / item.defaultPackQty
                        totalPrice = cur + (pieces * costPerPiece)
                    } else if item.isLiterUnit {
                        let packVolumeMl = item.defaultPackQty * 1000.0
                        let costPerMl = item.defaultPrice / packVolumeMl
                        totalPrice = cur + (ing.grams * costPerMl)
                    } else {
                        let costPerGram = item.defaultPrice / item.defaultPackQty
                        totalPrice = cur + (g * costPerGram)
                    }
                } else {
                    totalPrice = nil
                }
            }
        }

        let result = RecipeMacros(
            protein: totalP,
            kcal: totalK,
            carbs: totalC,
            fat: totalF,
            fiber: totalFib,
            price: totalPrice
        )
        recipeMacrosCache[template.id] = result
        return result
    }

    public func templateProtein(for template: MealTemplate) -> Double {
        return templateMacros(for: template).protein
    }

    public func templateKcal(for template: MealTemplate) -> Double {
        return templateMacros(for: template).kcal
    }

    public func templateFiber(for template: MealTemplate) -> Double {
        return templateMacros(for: template).fiber
    }

    public func templateCarbs(for template: MealTemplate) -> Double {
        return templateMacros(for: template).carbs
    }

    public func templateFat(for template: MealTemplate) -> Double {
        return templateMacros(for: template).fat
    }

    public func templatePrice(for template: MealTemplate) -> Double? {
        return templateMacros(for: template).price
    }

    public func templateProfile(for template: MealTemplate) -> NutritionalProfile {
        var profile = NutritionalProfile()
        for ing in template.ingredients {
            if let p = pantryItems.first(where: { $0.id == ing.pantryItemId || $0.name.lowercased() == ing.name.lowercased() }) {
                let g = effectiveGrams(for: ing, item: p)
                let ratio = g / 100.0
                profile.add(scaledFrom: p.effectiveProfile(), ratio: ratio)
            }
        }
        return profile
    }

    public func mealLogProfile(for log: MealLogEntry) -> NutritionalProfile {
        var profile = NutritionalProfile()
        if let item = pantryItems.first(where: { $0.id == log.pantryItemId || $0.name.lowercased() == log.foodName.lowercased() }) {
            let ratio = log.weightGrams / 100.0
            profile.add(scaledFrom: item.effectiveProfile(), ratio: ratio)
        } else {
            profile = NutritionalProfile(fiber: log.fiber)
        }
        return profile
    }

    public func dailyProfile(for date: Date) -> NutritionalProfile {
        var profile = NutritionalProfile()
        let dayLogs = logs(for: date)
        for log in dayLogs {
            if let item = pantryItems.first(where: { $0.id == log.pantryItemId || $0.name.lowercased() == log.foodName.lowercased() }) {
                let ratio = log.weightGrams / 100.0
                profile.add(scaledFrom: item.effectiveProfile(), ratio: ratio)
            }
        }
        return profile
    }

    // MARK: - Receipt Archiving & Price Update Engine
    public func saveReceipts() {
        save(items: receipts, to: receiptsURL)
    }

    private func loadReceipts() {
        if let items: [ReceiptRecord] = load(from: receiptsURL), !items.isEmpty {
            self.receipts = items
            let masterReceipts = MasterDataSeed.getMasterReceipts()
            for m in masterReceipts {
                if !self.receipts.contains(where: { $0.id == m.id }) {
                    self.receipts.append(m)
                }
            }
        } else {
            self.receipts = MasterDataSeed.getMasterReceipts()
            saveReceipts()
        }
    }

    public func archiveReceipt(_ receipt: ReceiptRecord, updatePantryPrices: Bool) {
        var canonicalReceipt = receipt
        canonicalReceipt.storeName = canonicalStoreName(for: receipt.storeName)
        registerStoreIfNeeded(canonicalReceipt.storeName)
        if updatePantryPrices {
            for item in canonicalReceipt.items where item.isConfirmed && item.matchedPantryItemId != nil && !item.isNonFood {
                if let pId = item.matchedPantryItemId, let idx = pantryItems.firstIndex(where: { $0.id == pId }) {
                    pantryItems[idx].updatePrice(item.parsedPrice, for: canonicalReceipt.storeName)
                }
            }
            savePantry()
        }

        receipts.insert(canonicalReceipt, at: 0)
        saveReceipts()

        // Broadcast Quittung across ecosystem to GrowFinance (Cross-Device & Local)
        let nonFoodSummaries = canonicalReceipt.items.filter { $0.isNonFood }.map {
            "\($0.quantity)x \($0.rawText) (\(String(format: "%.2f €", $0.lineTotalPrice)))"
        }
        let receiptPayload = SharedGroceryReceiptPayload(
            id: canonicalReceipt.id,
            date: canonicalReceipt.date,
            storeName: canonicalReceipt.storeName,
            totalAmount: canonicalReceipt.totalAmount,
            foodAmount: canonicalReceipt.foodTotal,
            nonFoodAmount: canonicalReceipt.nonFoodTotal,
            itemCount: canonicalReceipt.items.count,
            lineItemSummaries: canonicalReceipt.items.map { "\($0.quantity)x \($0.rawText) (\(String(format: "%.2f", $0.parsedPrice)) €)" },
            nonFoodSummaries: nonFoodSummaries,
            lastUpdated: Date()
        )
        GrowSuiteBridge.shared.appendGroceryReceipt(receiptPayload)

        HapticFeedbackService.shared.commitSuccess()
    }

    public func deleteReceipt(id: String) {
        receipts.removeAll(where: { $0.id == id })
        saveReceipts()
        HapticFeedbackService.shared.lightDetent()
    }

    public func linkReceiptItem(receiptId: String, lineItemId: String, to pantryItem: PantryItem, updatePrice: Bool = true) {
        guard let rIdx = receipts.firstIndex(where: { $0.id == receiptId }) else { return }
        guard let iIdx = receipts[rIdx].items.firstIndex(where: { $0.id == lineItemId }) else { return }
        registerStoreIfNeeded(receipts[rIdx].storeName)

        receipts[rIdx].items[iIdx].matchedPantryItemId = pantryItem.id
        receipts[rIdx].items[iIdx].matchedPantryItemName = pantryItem.name

        ReceiptMatchingEngine.shared.learnAlias(rawReceiptLine: receipts[rIdx].items[iIdx].rawText, targetItem: pantryItem)

        if updatePrice {
            if let pIdx = pantryItems.firstIndex(where: { $0.id == pantryItem.id }) {
                pantryItems[pIdx].defaultPrice = receipts[rIdx].items[iIdx].parsedPrice
                pantryItems[pIdx].store = receipts[rIdx].storeName
                savePantry()
            }
        }

        saveReceipts()
        propagateProductMatch(pantryItem: pantryItem)
        HapticFeedbackService.shared.lightDetent()
    }

    public func unlinkReceiptItem(receiptId: String, lineItemId: String) {
        guard let rIdx = receipts.firstIndex(where: { $0.id == receiptId }) else { return }
        guard let iIdx = receipts[rIdx].items.firstIndex(where: { $0.id == lineItemId }) else { return }

        receipts[rIdx].items[iIdx].matchedPantryItemId = nil
        receipts[rIdx].items[iIdx].matchedPantryItemName = nil

        saveReceipts()
        HapticFeedbackService.shared.lightDetent()
    }

    public func updateReceiptLineItem(
        receiptId: String,
        lineItemId: String,
        newName: String? = nil,
        newUnitPrice: Double,
        newQuantity: Int = 1,
        updatePantryPrice: Bool = true
    ) {
        guard let rIdx = receipts.firstIndex(where: { $0.id == receiptId }) else { return }
        guard let iIdx = receipts[rIdx].items.firstIndex(where: { $0.id == lineItemId }) else { return }

        let cleanQty = max(1, newQuantity)
        receipts[rIdx].items[iIdx].parsedPrice = newUnitPrice
        receipts[rIdx].items[iIdx].quantity = cleanQty

        if let name = newName?.trimmingCharacters(in: .whitespaces), !name.isEmpty {
            receipts[rIdx].items[iIdx].rawText = name
        }

        if cleanQty > 1 {
            receipts[rIdx].items[iIdx].quantityNote = "\(cleanQty) Stk x \(String(format: "%.2f €", newUnitPrice)) (Gesamt: \(String(format: "%.2f €", Double(cleanQty) * newUnitPrice)))"
        }

        // Recalculate receipt total
        receipts[rIdx].totalAmount = (receipts[rIdx].items.reduce(0.0) { $0 + $1.lineTotalPrice } * 100).rounded() / 100

        // If matched to a pantry item, synchronize its defaultPrice and name
        if updatePantryPrice, let pId = receipts[rIdx].items[iIdx].matchedPantryItemId,
           let pIdx = pantryItems.firstIndex(where: { $0.id == pId }) {
            pantryItems[pIdx].defaultPrice = newUnitPrice
            pantryItems[pIdx].store = receipts[rIdx].storeName
            savePantry()
        }

        saveReceipts()
        HapticFeedbackService.shared.commitSuccess()
    }

    public func deleteReceiptLineItem(receiptId: String, lineItemId: String) {
        guard let rIdx = receipts.firstIndex(where: { $0.id == receiptId }) else { return }
        receipts[rIdx].items.removeAll(where: { $0.id == lineItemId })
        receipts[rIdx].totalAmount = (receipts[rIdx].items.reduce(0.0) { $0 + $1.lineTotalPrice } * 100).rounded() / 100
        saveReceipts()
        HapticFeedbackService.shared.lightDetent()
    }

    public func createAndLinkProduct(receiptId: String, lineItemId: String, item: PantryItem) {
        addOrUpdatePantryItem(item)
        linkReceiptItem(receiptId: receiptId, lineItemId: lineItemId, to: item, updatePrice: false)
        propagateProductMatch(pantryItem: item)
    }

    public func updatePantryItemEAN(itemId: String, newBarcode: String) {
        guard let idx = pantryItems.firstIndex(where: { $0.id == itemId }) else { return }
        pantryItems[idx].barcode = newBarcode
        pantryItems[idx].profile = CommodityReferenceCatalog.enrich(
            profile: pantryItems[idx].profile,
            forProductName: pantryItems[idx].name,
            brand: pantryItems[idx].brand
        )
        savePantry()
        propagateProductMatch(pantryItem: pantryItems[idx])
        HapticFeedbackService.shared.lightDetent()
    }

    public func propagateProductMatch(pantryItem: PantryItem) {
        var receiptChanged = false
        let pName = pantryItem.name.lowercased().trimmingCharacters(in: .whitespaces)

        for rIdx in 0..<receipts.count {
            for iIdx in 0..<receipts[rIdx].items.count {
                let rItem = receipts[rIdx].items[iIdx]
                if rItem.matchedPantryItemId == pantryItem.id {
                    receipts[rIdx].items[iIdx].matchedPantryItemName = pantryItem.name
                    receiptChanged = true
                } else if rItem.matchedPantryItemId == nil && !pName.isEmpty {
                    let raw = rItem.rawText.lowercased().trimmingCharacters(in: .whitespaces)
                    if raw == pName || raw.contains(pName) || pName.contains(raw) {
                        receipts[rIdx].items[iIdx].matchedPantryItemId = pantryItem.id
                        receipts[rIdx].items[iIdx].matchedPantryItemName = pantryItem.name
                        receiptChanged = true
                    }
                }
            }
        }
        if receiptChanged {
            saveReceipts()
        }
    }

    // MARK: - Growcery Master Synchronization Engine
    @discardableResult
    public func performFullGrowcerySync(force: Bool = false) async -> (success: Bool, message: String) {
        if !force, let last = lastGrowcerySyncDate, Date().timeIntervalSince(last) < 3600 * 12, !pantryItems.isEmpty {
            return (true, "Bereits aktuell")
        }
        self.isGrowcerySyncing = true
        self.growcerySyncMessage = "Growcery Master Sync wird ausgeführt..."

        // 1. Synchronize Pantry Catalog with Master Data (All 116 Items)
        let masterCatalog = MasterDataSeed.getMasterCatalog()
        for mItem in masterCatalog {
            if let idx = self.pantryItems.firstIndex(where: { $0.id == mItem.id || $0.name.lowercased() == mItem.name.lowercased() }) {
                self.pantryItems[idx].profile = CommodityReferenceCatalog.enrich(
                    profile: self.pantryItems[idx].profile,
                    forProductName: self.pantryItems[idx].name,
                    brand: self.pantryItems[idx].brand
                )
                if self.pantryItems[idx].store.isEmpty {
                    self.pantryItems[idx].store = mItem.store
                }
            } else {
                var newItem = mItem
                newItem.profile = CommodityReferenceCatalog.enrich(
                    profile: mItem.profile,
                    forProductName: mItem.name,
                    brand: mItem.brand
                )
                self.pantryItems.append(newItem)
            }
        }
        savePantry()

        // 2. Synchronize Meal Templates (All 16 Recipes)
        let masterTemplates = MasterDataSeed.getMasterTemplates()
        for mTmpl in masterTemplates {
            if let idx = self.mealTemplates.firstIndex(where: { $0.id == mTmpl.id || $0.name.lowercased() == mTmpl.name.lowercased() }) {
                if self.mealTemplates[idx].instructions.isEmpty || self.mealTemplates[idx].instructions.count < mTmpl.instructions.count {
                    self.mealTemplates[idx].instructions = mTmpl.instructions
                }
            } else {
                self.mealTemplates.append(mTmpl)
            }
        }
        saveTemplates()

        // 3. Synchronize Master Receipts
        let masterReceipts = MasterDataSeed.getMasterReceipts()
        for mRec in masterReceipts {
            if !self.receipts.contains(where: { $0.id == mRec.id }) {
                self.receipts.insert(mRec, at: 0)
            }
        }
        saveReceipts()

        // 4. Save Shopping List
        saveShopping()

        // 5. HealthKit Data Sync
        HealthKitService.shared.fetchTodayHealthData()

        // 6. Synchronize with Google Calendar
        let calSync = await CalendarSyncService.shared.syncAllTodayMeals(store: self)

        // 7. Generate Live Markdown Export Document
        generateVaultExportDocument()

        self.lastGrowcerySyncDate = Date()
        self.isGrowcerySyncing = false
        let msg = "Growcery Sync aktiv: \(self.pantryItems.count) Artikel, \(self.mealTemplates.count) Rezepte, \(self.receipts.count) Belege. Kalender: \(calSync.successCount)/\(calSync.total) Einträge."
        self.growcerySyncMessage = msg
        HapticFeedbackService.shared.commitSuccess()
        return (true, msg)
    }

    public func generateAIRecipeMasterExportContent() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "dd.MM.yyyy HH:mm 'Uhr'"
        let dateStr = formatter.string(from: Date())

        var md = """
        # Growcery Master Context & Datenbank für Externe KI (ChatGPT / Claude / Gemini)

        > [!NOTE] SYSTEM DIRECTIVE FOR EXTERNAL LLM (CHATGPT / CLAUDE / GEMINI)
        > Diese Datei dient als vollständiger Kontext- und Datenbank-Export des NutriVault / Growcery Ökosystems. Verwende die darin definierten physiologischen Zielkorridore, das mathematische Gesundheitsscoring-System und die hinterlegte Rohstoff-Datenbank, um evidenzbasierte, klinisch konforme und direkt umsetzbare Rezepte für den Nutzer zu generieren.

        ---

        ## 1. Nutzer-Profil & Verbindliche Physiologische Constraints

        | Parameter | Zielkorridor / Vorschrift | Klinische / Operative Begründung |
        | :--- | :--- | :--- |
        | **Nutzer-Status** | Soldat der Bundeswehr & Student Wirtschaftsinformatik | Hohe kognitive Last, Krafttraining (Hypertrophie), militärischer Dienstbetrieb. |
        | **Tägliches Protein-Ziel** | 145 bis 170 g (Standard: 160 g) | Sicherung der Muskelproteinsynthese, Erhalt fettfreier Masse und Sättigung. |
        | **Tägliches Kalorien-Budget**| 1.850 bis 2.000 kcal | Isokalorischer Erhalt / Recomposition. |
        | **BWK Ulm Viszeral-Reha** | 25 bis 35 g Ballaststoffe täglich | Post-Analprolaps-Operation (11/2024). Strikte Vermeidung von intraabdominalem Pressdruck; Bristol-Stuhlform Typ 4 erzwingen. Hohe Dichte an löslichen Schleimstoffen. |
        | **Stiller Reflux (LPR) Schutz** | Strikte Nahrungskarenz 3h vor Nachtruhe | Abends (> 18:30 Uhr) keine Sphinkter-Relaxantien: Kein Kaffee, keine Minze, keine Schokolade, keine rohen Zwiebeln/Knoblauch, Fettgehalt < 15 g/Mahlzeit. |
        | **AuDHD Blutzucker-Stabilität** | Niedrige/Moderate Glykämie (GI <= 55) | Kohlenhydrate müssen ausnahmslos an Protein und Ballaststoffe gekoppelt werden (keine isolierten GI-Peaks). |
        | **Stuben-Küchen-Infrastruktur** | AirFryer, Mikrowelle, 1-Feld Induktion | Keine Backöfen mit langen Vorheizzeiten. Maximale Zubereitungszeit: 10 bis 15 Minuten. |

        ---

        ## 2. Das NutriVault Gesundheitsscoring-System (Die 7 Säulen & Phi-Index)

        Die Qualität jeder Zutat und jedes Rezepts wird über den **NutriVault Composite Health Index $\\Phi$** (0 bis 100 Punkte) quantifiziert:

        $$\\Phi = 0{,}25 \\cdot \\text{FoodCompass} + 0{,}20 \\cdot \\text{TyBeal} + 0{,}20 \\cdot \\text{BWK\\_Visceral} + 0{,}15 \\cdot \\text{AMDR} + 0{,}10 \\cdot \\text{LPR} + 0{,}10 \\cdot \\text{NOVA}$$

        ### 2.1 Die 7 Säulen im Detail:
        1. **BWK Ulm Visceral-Reha Score (0 - 100):**
           - Bewertet Ballaststoffdichte ($\\ge 14\\text{ g} / 1.000\\text{ kcal}$ oder $\\ge 6\\text{ g} / 100\\text{ g}$).
           - Bonus für lösliche Schleimstoffe (Haferflocken, Leinsamen, Hülsenfrüchte, Beeren).
           - Abzug für Natrium $> 700\\text{ mg}$ und gesättigte Fette $> 8\\text{ g}$.
           - Ziel: Wert $\\ge 75$ (Kategorie: *Zielerfüllung Bristol Typ 4*).
        2. **LPR Gastric Safety Score (0 - 100):**
           - Schutz des unteren Ösophagussphinkters vor Säurereflux.
           - Abzug bei Fettgehalt $> 10\\text{ g}$ bzw. $> 20\\text{ g}$.
           - Malus (-40 Pkt) für Sphinkter-Relaxantien (Koffein, Minze, Schokolade, Chili, Zwiebel/Knoblauch).
           - Ziel für Abendmahlzeiten: Wert $\\ge 75$ (*Reflux-Sicher*).
        3. **Ty Beal Nutrient-Density Score (0 - 100):**
           - Proteinqualität (bis 25 Pkt), Ballaststoffdichte (bis 15 Pkt), 16 Mikronährstoffe (bis 35 Pkt) und $K:\\!Na \\ge 2{,}0$ (bis 25 Pkt).
        4. **Tufts Food Compass (1 - 100):**
           - Bevorzugt unverarbeitete Vollwertkost, bestraft Zucker- und Natriumzusatz. $\\ge 70 = \\text{Bevorzugen}$.
        5. **NOVA-Verarbeitungsklasse (1 bis 4):**
           - NOVA 1: Unverarbeitet (100 Pkt) | NOVA 2: Kulinarisch (80 Pkt) | NOVA 3: Verarbeitet (55 Pkt) | NOVA 4: Ultra-verarbeitet (20 Pkt).
        6. **AMDR Protein-Dichte:**
           - Proteinanteil 25–40 % der Kalorien = Optimum für Sättigung und Muskelproteinsynthese.
        7. **Glykämischer Index (GI <= 55) & BPI Proteindichte (g Protein / 100 kcal).**

        ---

        ## 3. Vollständige Rohstoff- & Vorrats-Datenbank (\\(pantryItems.count) Positionen)
        Export-Datum: \\(dateStr)

        | ID | Produkt | Marke | Store | Preis | Packung | Bestand | Ort | kcal | Prot | KH | Fett | Ball | Score $\\Phi$ | BWK | LPR | NOVA |
        | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
        """

        let scoring = NutritionalScoringEngine.shared
        for item in pantryItems.sorted(by: { $0.name.localizedCompare($1.name) == .orderedAscending }) {
            let sc = scoring.evaluate(item: item)
            let fiberVal = item.fiber100g > 0 ? item.fiber100g : (item.effectiveProfile().fiber ?? 0.0)
            let priceStr = String(format: "%.2f €", item.defaultPrice)
            let packStr = "\(Int(item.defaultPackQty)) \(item.unit)"
            let stockStr = "\(Int(item.currentStockQty)) \(item.unit)"
            let phiStr = "\(sc.compositeHealthIndex) (\(sc.compositeGrade))"
            let protStr = String(format: "%.1f", item.protein100g)
            let carbsStr = String(format: "%.1f", item.carbs100g)
            let fatStr = String(format: "%.1f", item.fat100g)
            let fiberStr = String(format: "%.1f", fiberVal)

            md += "\n| `\(item.id)` | \(item.name) | \(item.brand) | \(item.store) | \(priceStr) | \(packStr) | \(stockStr) | \(item.storageLocation.rawValue) | \(Int(item.kcal100g)) | \(protStr)g | \(carbsStr)g | \(fatStr)g | \(fiberStr)g | \(phiStr) | \(sc.bwkVisceralRehaScore) | \(sc.lprSafetyScore) | NOVA \(sc.novaClass) |"
        }
        md += "\n\n---\n\n## 4. Bestehende Rezepturen & Baukästen (\\(mealTemplates.count) Templates)\n\n"
        for tmpl in mealTemplates {
            md += "### \\(tmpl.name) (`\\(tmpl.id)`)\n"
            md += "- **Kategorie:** \\(tmpl.category)\n"
            md += "- **Makronährstoffe:** \\(Int(templateKcal(for: tmpl))) kcal | \\(Int(templateProtein(for: tmpl)))g Protein\n"
            md += "- **Zutatenliste:**\n"
            for ing in tmpl.ingredients {
                md += "  - `\\(ing.pantryItemId)`: \\(ing.name) (\\(Int(ing.grams))g)\n"
            }
            md += "\n"
        }

        md += """
        ---

        ## 5. Ausgabeformat für KI-Rezeptgenerierungen

        Wenn du (externe KI) Rezepte generierst, halte dich strikt an diese Struktur:

        ```markdown
        ### [Nummer]. [Rezept-Name]
        - **Kategorie:** [Warm Roast / Soups & Stews / Sandwiches & Wraps / High-Fiber Bowl / Sweet Breakfast]
        - **Equipment:** [AirFryer / 1-Feld Induktion / Mikrowelle]
        - **Zubereitungszeit:** [Max. 15 Minuten]
        - **Zutatenliste:**
          - [ID aus Datenbank]: [Produktname] - [Grammangabe]g
        - **Zubereitungsschritte:**
          1. [Schritt 1]
          2. [Schritt 2]
        - **Nährwertbilanz:**
          - Brennwert: [X] kcal | Protein: [X] g (35–50g) | KH: [X] g | Fett: [X] g (< 15g abends) | Ballaststoffe: [X] g (>= 8g)
        - **Klinische NutriVault-Bewertung:**
          - Composite Index $\\Phi$: [0-100] (Ziel: >= 80, Note A/A+)
          - BWK Visceral-Score: [0-100] (Bristol Typ 4 Entlastung)
          - LPR Reflux-Sicherheit: [0-100] (Sphinkterschonung)
        ```
        """
        return md
    }

    // MARK: - Master Context Exports (PDF & Markdown)
    private var _cachedMasterPDFData: Data? = nil

    public func generateAIRecipeMasterPDFData(forceRefresh: Bool = false) -> Data {
        if !forceRefresh, let cached = _cachedMasterPDFData {
            return cached
        }
        let data = PDFExportService.renderMasterContextPDF(store: self)
        _cachedMasterPDFData = data
        return data
    }

    public func getAIRecipeMasterPDFURL() -> URL {
        let data = generateAIRecipeMasterPDFData()
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("Growcery_AI_Recipe_Master_Context.pdf")
        try? data.write(to: tempURL, options: .atomic)

        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let docsURL = docs.appendingPathComponent("Growcery_AI_Recipe_Master_Context.pdf")
        try? data.write(to: docsURL, options: .atomic)
        return tempURL
    }

    public func getAIRecipeMasterExportURL() -> URL {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("Growcery_AI_Recipe_Master_Context.md")
        let content = generateAIRecipeMasterExportContent()
        try? content.write(to: tempURL, atomically: true, encoding: .utf8)

        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let docsURL = docs.appendingPathComponent("Growcery_AI_Recipe_Master_Context.md")
        try? content.write(to: docsURL, atomically: true, encoding: .utf8)
        return tempURL
    }

    public func generateVaultExportDocument() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let exportURL = docs.appendingPathComponent("Growcery_Live_Export.md")
        let aiExportURL = docs.appendingPathComponent("Growcery_AI_Recipe_Master_Context.md")

        let fullContent = generateAIRecipeMasterExportContent()
        try? fullContent.write(to: aiExportURL, atomically: true, encoding: .utf8)
        try? fullContent.write(to: exportURL, atomically: true, encoding: .utf8)
        print("Growcery exports successfully written to \\(docs.path)")
    }

    // MARK: - Circadian Supplement Tracking

    private static let sharedDateKeyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = Calendar.current.timeZone
        return formatter
    }()

    public func dateKey(for date: Date) -> String {
        return Self.sharedDateKeyFormatter.string(from: date)
    }

    public func loadSupplementsList() {
        if let list: [CircadianSupplementDose] = loadObject(from: customSupplementsURL), !list.isEmpty {
            self.customSupplements = list
        } else {
            self.customSupplements = CircadianSupplementProtocol.dailySchedule
            saveSupplementsList()
        }
    }

    public func saveSupplementsList() {
        saveObject(customSupplements, to: customSupplementsURL)
    }

    public var allSupplements: [CircadianSupplementDose] {
        return customSupplements.isEmpty ? CircadianSupplementProtocol.dailySchedule : customSupplements
    }

    public func saveSupplementDose(_ dose: CircadianSupplementDose) {
        if let idx = customSupplements.firstIndex(where: { $0.id == dose.id }) {
            customSupplements[idx] = dose
        } else {
            customSupplements.append(dose)
        }
        customSupplements.sort { $0.scheduledTime < $1.scheduledTime }
        saveSupplementsList()
        invalidateDailyMacrosCache()
        SupplementNotificationService.shared.scheduleAllSupplementReminders()
        HapticFeedbackService.shared.commitSuccess()
    }

    public func deleteSupplementDose(id: String) {
        customSupplements.removeAll { $0.id == id }
        saveSupplementsList()
        invalidateDailyMacrosCache()
        SupplementNotificationService.shared.cancelTodayNotification(for: id)
        SupplementNotificationService.shared.scheduleAllSupplementReminders()
        HapticFeedbackService.shared.commitSuccess()
    }

    public func resetSupplementsToDefault() {
        self.customSupplements = CircadianSupplementProtocol.dailySchedule
        saveSupplementsList()
        invalidateDailyMacrosCache()
        SupplementNotificationService.shared.scheduleAllSupplementReminders()
        HapticFeedbackService.shared.commitSuccess()
    }

    public func saveSupplements() {
        invalidateDailyMacrosCache()
        let codableDict = supplementLogs.mapValues { Array($0) }
        saveObject(codableDict, to: supplementURL)

        // Sync to GrowSuiteBridge
        let todayKey = dateKey(for: Date())
        if let todayTaken = supplementLogs[todayKey] {
            var map: [String: Date] = [:]
            for d in todayTaken {
                map[d] = Date()
            }
            let payload = SharedSupplementPayload(date: Date(), takenDoseIds: map)
            GrowSuiteBridge.shared.saveSupplements(payload)
        }
        syncSupplementScheduleToBridge()
    }

    private func loadSupplements() {
        if let loaded: [String: [String]] = loadObject(from: supplementURL) {
            self.supplementLogs = loaded.mapValues { Set($0) }
        }

        // Bridge Sync
        let bridgeSupps = GrowSuiteBridge.shared.loadSupplements(for: Date())
        let todayKey = dateKey(for: Date())
        var currentSet = supplementLogs[todayKey] ?? Set<String>()
        for (doseId, _) in bridgeSupps.takenDoseIds {
            currentSet.insert(doseId)
        }
        self.supplementLogs[todayKey] = currentSet
    }

    // MARK: - Anti-Doppelgabe-Sperre & Einnahme-Sicherheit (UL-Schutz)
    public func isSupplementLocked(doseId: String, date: Date = Date()) -> Bool {
        return isSupplementTaken(doseId: doseId, date: date)
    }

    public func toggleSupplement(doseId: String, date: Date = Date(), forceUnlock: Bool = false) {
        let key = dateKey(for: date)
        var currentSet = supplementLogs[key] ?? Set<String>()
        if currentSet.contains(doseId) {
            if !forceUnlock {
                // Strikte Anti-Doppelgabe-Sperre: Verhindert versehentliche Ueberdosierungen (z. B. D3/K2 oder Magnesium).
                // Ist ein Supplement fuer das jeweilige Zeitfenster abgehakt, wird die Checkbox bis zum naechsten Tag gesperrt.
                HapticFeedbackService.shared.lightDetent()
                return
            }
            currentSet.remove(doseId)
            HapticFeedbackService.shared.lightDetent()
            SupplementNotificationService.shared.scheduleAllSupplementReminders()
        } else {
            currentSet.insert(doseId)
            HapticFeedbackService.shared.commitSuccess()
            if Calendar.current.isDateInToday(date) {
                SupplementNotificationService.shared.cancelTodayNotification(for: doseId)
            }
        }
        supplementLogs[key] = currentSet
        saveSupplements()
        syncTagesbilanzToBridge()
    }

    public func isSupplementTaken(doseId: String, date: Date = Date()) -> Bool {
        let key = dateKey(for: date)
        return supplementLogs[key]?.contains(doseId) ?? false
    }

    public func completedSupplementsCount(date: Date = Date()) -> Int {
        let key = dateKey(for: date)
        return supplementLogs[key]?.count ?? 0
    }

    // MARK: - Bristol-Stuhlform-Tracker (BWK Ulm Viszeral-Reha)
    public func bristolScore(for date: Date = Date()) -> Int? {
        let key = dateKey(for: date)
        return bristolLogs[key]
    }

    public func setBristolScore(_ score: Int, for date: Date = Date()) {
        let key = dateKey(for: date)
        bristolLogs[key] = max(1, min(7, score))
        saveBristol()
        HapticFeedbackService.shared.commitSuccess()
    }

    public func saveBristol() {
        saveObject(bristolLogs, to: bristolURL)
    }

    private func loadBristol() {
        if let loaded: [String: Int] = loadObject(from: bristolURL) {
            self.bristolLogs = loaded
        }
    }

    // MARK: - Water & Hydration Tracking (Realtime Bridge Sync)

    public func saveWater() {
        let todayKey = dateKey(for: Date())
        let todayVal = waterLogs[todayKey] ?? 0.0

        // 1. Zero-Copy In-Place Memory Map Update (Tencent MMKV)
        GrowMMKV.shared.set(todayVal, forKey: "grow_water_\(todayKey)")

        // 2. High-Throughput Write-Ahead-Log (SQLite WAL)
        GrowDatabase.shared.performAsync { db in
            guard let db = db else { return }
            var stmt: OpaquePointer?
            let sql = "INSERT OR REPLACE INTO hydration (date_key, total_ml, target_ml, last_updated) VALUES (?, ?, ?, ?);"
            if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
                sqlite3_bind_text(stmt, 1, (todayKey as NSString).utf8String, -1, nil)
                sqlite3_bind_double(stmt, 2, todayVal)
                sqlite3_bind_double(stmt, 3, 2500.0)
                sqlite3_bind_double(stmt, 4, Date().timeIntervalSince1970)
                sqlite3_step(stmt)
            }
            sqlite3_finalize(stmt)
        }

        // 3. Fallback File Persistence
        saveObject(waterLogs, to: waterURL)

        GrowSuiteBridge.shared.setTotalWater(totalMl: todayVal, sourceApp: "Growcery")
    }

    private func loadWater() {
        if let loaded: [String: Double] = loadObject(from: waterURL) {
            self.waterLogs = loaded
        }

        let todayKey = dateKey(for: Date())
        let bridgeWater = GrowSuiteBridge.shared.loadWater(for: Date())

        if bridgeWater.totalWaterMl > 0 {
            self.waterLogs[todayKey] = bridgeWater.totalWaterMl
            HealthKitService.shared.waterIntakeMl = bridgeWater.totalWaterMl
        } else if let current = self.waterLogs[todayKey], current > 0 {
            HealthKitService.shared.waterIntakeMl = current
            GrowSuiteBridge.shared.setTotalWater(totalMl: current, sourceApp: "Growcery")
        } else {
            HealthKitService.shared.waterIntakeMl = 0.0
        }

        NotificationCenter.default.addObserver(forName: UIApplication.significantTimeChangeNotification, object: nil, queue: .main) { [weak self] _ in
            self?.handleMidnightReset()
        }

        DarwinNotificationCenter.observe(DarwinNotificationCenter.waterUpdated) { [weak self] in
            Task { @MainActor in
                self?.refreshWaterFromBridge()
            }
        }

        DarwinNotificationCenter.observe(DarwinNotificationCenter.financeUpdated) { [weak self] in
            Task { @MainActor in
                self?.refreshFinanceFromBridge()
            }
        }

        DarwinNotificationCenter.observe(DarwinNotificationCenter.shoppingUpdated) { [weak self] in
            Task { @MainActor in
                self?.refreshShoppingFromBridge()
            }
        }

        DarwinNotificationCenter.observe(DarwinNotificationCenter.supplementScheduleLedgerUpdated) { [weak self] in
            Task { @MainActor in
                self?.refreshSupplementsFromBridge()
            }
        }
    }

    public func refreshSupplementsFromBridge() {
        let bridgeSupps = GrowSuiteBridge.shared.loadSupplements(for: Date())
        let todayKey = dateKey(for: Date())
        var currentSet = supplementLogs[todayKey] ?? Set<String>()
        var changed = false
        for (doseId, _) in bridgeSupps.takenDoseIds {
            if !currentSet.contains(doseId) {
                currentSet.insert(doseId)
                changed = true
            }
        }
        if changed {
            self.supplementLogs[todayKey] = currentSet
            saveSupplements()
        }
    }

    public func refreshShoppingFromBridge() {
        let shared = GrowSuiteBridge.shared.loadShopping()
        let sharedIds = Set(shared.items.map { $0.id })
        let deletedIds = Set(shared.deletedIds)
        let mockPrefixes = ["shop_1", "shop_2", "shop_3", "shop_4", "shop_5", "shop_6", "shop_7", "shop_8", "shop_9", "shop_10", "shop_11", "shop_12", "shop_13", "shop_14", "shop_15", "shop_16", "shop-1788799469281-"]

        // 1. Remove mock items unconditionally
        self.shoppingList.removeAll { item in
            mockPrefixes.contains(where: { item.id.hasPrefix($0) })
        }

        // 2. Remove items explicitly deleted
        if !deletedIds.isEmpty {
            self.shoppingList.removeAll { deletedIds.contains($0.id) }
        }

        // 3. Remove items missing from bridge unless locally saved
        if !shared.items.isEmpty {
            self.shoppingList.removeAll { localItem in
                !sharedIds.contains(localItem.id) && !localItem.isSaved
            }
        }

        for sItem in shared.items {
            if mockPrefixes.contains(where: { sItem.id.hasPrefix($0) }) || deletedIds.contains(sItem.id) {
                continue
            }
            if let idx = self.shoppingList.firstIndex(where: { $0.id == sItem.id }) {
                self.shoppingList[idx].isChecked = sItem.isBought
                self.shoppingList[idx].isSaved = sItem.isSaved
                self.shoppingList[idx].price = sItem.price
                self.shoppingList[idx].name = sItem.name
                self.shoppingList[idx].recurrenceRule = sItem.recurrenceRule
                self.shoppingList[idx].isRecurring = sItem.recurrenceRule != nil
            } else if !sItem.isBought || sItem.recurrenceRule != nil {
                var newItem = ShoppingItem(
                    id: sItem.id,
                    name: sItem.name,
                    price: sItem.price,
                    store: sItem.store,
                    quantity: sItem.quantity,
                    isChecked: sItem.isBought,
                    category: sItem.category,
                    webUrl: sItem.webUrl
                )
                newItem.isSaved = sItem.isSaved
                newItem.recurrenceRule = sItem.recurrenceRule
                newItem.isRecurring = sItem.recurrenceRule != nil
                self.shoppingList.append(newItem)
            }
        }
        save(items: shoppingList, to: shoppingURL)
    }

    public func refreshFinanceFromBridge() {
        self.sharedFinance = GrowSuiteBridge.shared.loadFinance(for: Date())
    }

    public func refreshWaterFromBridge() {
        let todayKey = dateKey(for: Date())
        let bridgeWater = GrowSuiteBridge.shared.loadWater(for: Date())
        self.waterLogs[todayKey] = bridgeWater.totalWaterMl
        saveObject(waterLogs, to: waterURL)
        HealthKitService.shared.waterIntakeMl = bridgeWater.totalWaterMl
    }

    public func logWater(ml: Double, date: Date = Date(), sourceApp: String = "Growcery") {
        let key = dateKey(for: date)
        let current = waterLogs[key] ?? 0.0
        let newTotal = max(0.0, current + ml)
        waterLogs[key] = newTotal
        saveWater()

        if Calendar.current.isDateInToday(date) {
            HealthKitService.shared.waterIntakeMl = newTotal
            WaterNotificationService.shared.updateNotificationsForCurrentIntake()
        }
        GrowSuiteBridge.shared.logWater(amountMl: ml, date: date, sourceApp: sourceApp)
        HapticFeedbackService.shared.commitSuccess()
    }

    public func setTodayWater(ml: Double, date: Date = Date(), sourceApp: String = "Growcery") {
        let key = dateKey(for: date)
        let target = max(0.0, ml)
        waterLogs[key] = target
        saveWater()

        if Calendar.current.isDateInToday(date) {
            HealthKitService.shared.waterIntakeMl = target
            WaterNotificationService.shared.updateNotificationsForCurrentIntake()
        }
        GrowSuiteBridge.shared.setTotalWater(totalMl: target, date: date, sourceApp: sourceApp)
        HapticFeedbackService.shared.commitSuccess()
    }

    public func resetWater(date: Date = Date(), sourceApp: String = "Growcery") {
        let key = dateKey(for: date)
        waterLogs[key] = 0.0
        saveWater()

        if Calendar.current.isDateInToday(date) {
            HealthKitService.shared.waterIntakeMl = 0.0
            WaterNotificationService.shared.updateNotificationsForCurrentIntake()
        }
        GrowSuiteBridge.shared.resetWater(date: date, sourceApp: sourceApp)
        HapticFeedbackService.shared.commitSuccess()
    }

    public func todayWater(date: Date = Date()) -> Double {
        let key = dateKey(for: date)
        if let val = waterLogs[key] {
            return val
        }
        let bridgeWater = GrowSuiteBridge.shared.loadWater(for: date)
        if bridgeWater.dateString == key && bridgeWater.totalWaterMl > 0 {
            return bridgeWater.totalWaterMl
        }
        return 0.0
    }

    public func handleMidnightReset() {
        let todayKey = dateKey(for: Date())
        if self.waterLogs[todayKey] == nil {
            HealthKitService.shared.waterIntakeMl = 0.0
            _ = GrowSuiteBridge.shared.loadWater(for: Date())
        }
        self.objectWillChange.send()
    }

    // MARK: - Variant Management

    public func findVariants(forItemName rawName: String) -> [PantryItem] {
        let clean = rawName.uppercased()
            .replacingOccurrences(of: "Ä", with: "AE")
            .replacingOccurrences(of: "Ö", with: "OE")
            .replacingOccurrences(of: "Ü", with: "UE")
            .replacingOccurrences(of: "-", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let tokens = clean.split(separator: " ").map { String($0) }.filter { $0.count >= 3 }
        guard !tokens.isEmpty else { return [] }

        return pantryItems.filter { item in
            let itemClean = item.name.uppercased()
                .replacingOccurrences(of: "Ä", with: "AE")
                .replacingOccurrences(of: "Ö", with: "OE")
                .replacingOccurrences(of: "Ü", with: "UE")
                .replacingOccurrences(of: "-", with: " ")

            // Check if any significant token is shared
            for tok in tokens {
                if itemClean.contains(tok) { return true }
            }
            return false
        }
    }

    public func createVariant(
        from baseItem: PantryItem,
        newPackQty: Double,
        newPrice: Double,
        newBarcode: String,
        customNameSuffix: String? = nil
    ) -> PantryItem {
        let newName: String
        if let suffix = customNameSuffix, !suffix.isEmpty {
            newName = "\(baseItem.name) (\(suffix))"
        } else if newPackQty > 0 {
            newName = "\(baseItem.name) \(Int(newPackQty))\(baseItem.unit)"
        } else {
            newName = "\(baseItem.name) (Variante)"
        }

        let variant = PantryItem(
            id: UUID().uuidString,
            name: newName,
            brand: baseItem.brand,
            barcode: newBarcode,
            defaultPackQty: newPackQty > 0 ? newPackQty : baseItem.defaultPackQty,
            defaultPrice: newPrice > 0 ? newPrice : baseItem.defaultPrice,
            currentStockQty: newPackQty > 0 ? newPackQty : baseItem.defaultPackQty,
            unit: baseItem.unit,
            kcal100g: baseItem.kcal100g,
            protein100g: baseItem.protein100g,
            carbs100g: baseItem.carbs100g,
            fat100g: baseItem.fat100g,
            fiber100g: baseItem.fiber100g,
            nutriscore: baseItem.nutriscore,
            store: baseItem.store,
            profile: baseItem.profile,
            subUnitCount: baseItem.subUnitCount,
            subUnitSize: baseItem.subUnitSize,
            subUnitName: baseItem.subUnitName
        )
        addOrUpdatePantryItem(variant)
        return variant
    }

    // MARK: - Skipped Supplement Schedule Tracking

    public func saveSkippedSupplements() {
        let dict = skippedSupplements.mapValues { Array($0) }
        saveObject(dict, to: skippedSupplementsURL)
    }

    private func loadSkippedData() {
        if let dict: [String: [String]] = loadObject(from: skippedSupplementsURL) {
            self.skippedSupplements = dict.mapValues { Set($0) }
        }
    }

    public func isSupplementSkipped(doseId: String, date: Date) -> Bool {
        let key = dateKey(for: date)
        return skippedSupplements[key]?.contains(doseId) ?? false
    }

    public func skipSupplement(doseId: String, date: Date) {
        let key = dateKey(for: date)
        var set = skippedSupplements[key] ?? Set<String>()
        set.insert(doseId)
        skippedSupplements[key] = set
        saveSkippedSupplements()
        HapticFeedbackService.shared.mechanicalClick()
    }

    public func unskipSupplement(doseId: String, date: Date) {
        let key = dateKey(for: date)
        var set = skippedSupplements[key] ?? Set<String>()
        set.remove(doseId)
        skippedSupplements[key] = set
        saveSkippedSupplements()
    }
}


// MARK: - Transferable PDF Representation

public struct PDFTransferable: Transferable {
    public let data: Data
    public let title: String

    public init(data: Data, title: String) {
        self.data = data
        self.title = title
    }

    public static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .pdf) { item in
            item.data
        }
        .suggestedFileName { item in
            "\(item.title).pdf"
        }
    }
}

// MARK: - PDF Export Service

public final class PDFExportService {
    @MainActor
    public static func renderMasterContextPDF(store: LocalStore) -> Data {
        let html = generateMasterContextHTML(pantryItems: store.pantryItems, mealTemplates: store.mealTemplates)
        let printFormatter = UIMarkupTextPrintFormatter(markupText: html)
        let printPageRenderer = UIPrintPageRenderer()
        printPageRenderer.addPrintFormatter(printFormatter, startingAtPageAt: 0)

        // A4 Dimensions: 595.2 x 841.8 pt; Printable Margins: 24 pt
        let paperRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8)
        let printableRect = CGRect(x: 24, y: 24, width: 547.2, height: 793.8)

        printPageRenderer.setValue(NSValue(cgRect: paperRect), forKey: "paperRect")
        printPageRenderer.setValue(NSValue(cgRect: printableRect), forKey: "printableRect")

        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData, paperRect, nil)
        printPageRenderer.prepare(forDrawingPages: NSRange(location: 0, length: max(1, printPageRenderer.numberOfPages)))
        let bounds = UIGraphicsGetPDFContextBounds()

        let pagesCount = max(1, printPageRenderer.numberOfPages)
        for pageIndex in 0..<pagesCount {
            UIGraphicsBeginPDFPage()
            printPageRenderer.drawPage(at: pageIndex, in: bounds)
        }
        UIGraphicsEndPDFContext()

        if pdfData.length > 500 {
            return pdfData as Data
        }

        // CoreText Fallback if WebKit layout returned empty
        if let attr = try? NSAttributedString(
            data: Data(html.utf8),
            options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: String.Encoding.utf8.rawValue],
            documentAttributes: nil
        ) {
            let simpleFormatter = UISimpleTextPrintFormatter(attributedText: attr)
            let altRenderer = UIPrintPageRenderer()
            altRenderer.addPrintFormatter(simpleFormatter, startingAtPageAt: 0)
            altRenderer.setValue(NSValue(cgRect: paperRect), forKey: "paperRect")
            altRenderer.setValue(NSValue(cgRect: printableRect), forKey: "printableRect")

            let fallbackData = NSMutableData()
            UIGraphicsBeginPDFContextToData(fallbackData, paperRect, nil)
            altRenderer.prepare(forDrawingPages: NSRange(location: 0, length: max(1, altRenderer.numberOfPages)))
            for pageIndex in 0..<max(1, altRenderer.numberOfPages) {
                UIGraphicsBeginPDFPage()
                altRenderer.drawPage(at: pageIndex, in: bounds)
            }
            UIGraphicsEndPDFContext()
            if fallbackData.length > 0 {
                return fallbackData as Data
            }
        }

        return pdfData as Data
    }

    @MainActor
    public static func generateMasterContextHTML(pantryItems: [PantryItem], mealTemplates: [MealTemplate]) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "dd.MM.yyyy HH:mm 'Uhr'"
        let dateStr = formatter.string(from: Date())

        let scoring = NutritionalScoringEngine.shared

        var rowsHTML = ""
        for item in pantryItems.sorted(by: { $0.name.localizedCompare($1.name) == .orderedAscending }) {
            let sc = scoring.evaluate(item: item)
            let fiberVal = item.fiber100g > 0 ? item.fiber100g : (item.effectiveProfile().fiber ?? 0.0)
            let priceStr = String(format: "%.2f €", item.defaultPrice)
            let packStr = "\(Int(item.defaultPackQty)) \(item.unit)"
            let stockStr = "\(Int(item.currentStockQty)) \(item.unit)"
            let protStr = String(format: "%.1f", item.protein100g)
            let carbsStr = String(format: "%.1f", item.carbs100g)
            let fatStr = String(format: "%.1f", item.fat100g)
            let fiberStr = String(format: "%.1f", fiberVal)

            rowsHTML += """
            <tr>
                <td style="font-family: monospace; font-size: 7.5pt; color: #475569;">\(item.id)</td>
                <td><strong>\(item.name)</strong></td>
                <td>\(item.brand)</td>
                <td>\(item.store)</td>
                <td style="text-align: right;">\(priceStr)</td>
                <td style="text-align: right;">\(packStr)</td>
                <td style="text-align: right; font-weight: 600;">\(stockStr)</td>
                <td>\(item.storageLocation.rawValue)</td>
                <td style="text-align: right;">\(Int(item.kcal100g))</td>
                <td style="text-align: right; font-weight: 600;">\(protStr)</td>
                <td style="text-align: right;">\(carbsStr)</td>
                <td style="text-align: right;">\(fatStr)</td>
                <td style="text-align: right; font-weight: 600;">\(fiberStr)</td>
                <td style="text-align: center; font-weight: bold;">\(sc.compositeHealthIndex) (\(sc.compositeGrade))</td>
                <td style="text-align: center;">\(sc.bwkVisceralRehaScore)</td>
                <td style="text-align: center;">\(sc.lprSafetyScore)</td>
                <td style="text-align: center;">NOVA \(sc.novaClass)</td>
            </tr>
            """
        }

        var templatesHTML = ""
        for tmpl in mealTemplates {
            var ingsList = ""
            for ing in tmpl.ingredients {
                ingsList += "<li><code>\(ing.pantryItemId)</code>: \(ing.name) (\(Int(ing.grams))g)</li>"
            }
            templatesHTML += """
            <div style="background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 4pt; padding: 6pt 10pt; margin-bottom: 8pt; page-break-inside: avoid;">
                <div style="font-size: 10pt; font-weight: bold; color: #0f172a;">\(tmpl.name) <span style="font-size: 8pt; color: #64748b; font-family: monospace;">(\(tmpl.id))</span></div>
                <div style="font-size: 8.5pt; color: #475569; margin: 2pt 0 4pt 0;">Kategorie: \(tmpl.category)</div>
                <ul style="margin: 0; padding-left: 14pt; font-size: 8.5pt; color: #334155;">
                    \(ingsList)
                </ul>
            </div>
            """
        }

        return """
        <!DOCTYPE html>
        <html lang="de">
        <head>
        <meta charset="utf-8">
        <title>Growcery Master Kontext & Vorrats-Datenbank</title>
        <style>
        @page {
            size: A4;
            margin: 12mm 10mm 12mm 10mm;
        }
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
            color: #0f172a;
            background: #ffffff;
            font-size: 8.5pt;
            line-height: 1.35;
            margin: 0;
            padding: 0;
        }
        .header {
            border-bottom: 2pt solid #0f172a;
            padding-bottom: 6pt;
            margin-bottom: 10pt;
        }
        .title {
            font-size: 15pt;
            font-weight: 800;
            letter-spacing: -0.3pt;
            color: #0f172a;
            text-transform: uppercase;
        }
        .subtitle {
            font-size: 9pt;
            font-weight: 500;
            color: #475569;
            margin-top: 2pt;
        }
        .meta-bar {
            margin-top: 4pt;
            font-size: 7.5pt;
            color: #64748b;
            font-family: ui-monospace, Menlo, Consolas, monospace;
        }
        h2 {
            font-size: 11pt;
            font-weight: 700;
            color: #0f172a;
            border-bottom: 1pt solid #cbd5e1;
            padding-bottom: 3pt;
            margin-top: 14pt;
            margin-bottom: 6pt;
            page-break-after: avoid;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            font-size: 7.5pt;
            margin: 6pt 0 12pt 0;
        }
        tr {
            page-break-inside: avoid;
        }
        th, td {
            border: 1pt solid #e2e8f0;
            padding: 3.5pt 4.5pt;
            vertical-align: middle;
        }
        th {
            background-color: #f8fafc;
            color: #0f172a;
            font-weight: 600;
            text-align: left;
        }
        tr:nth-child(even) td {
            background-color: #fbfcfd;
        }
        code {
            font-family: ui-monospace, Menlo, Consolas, monospace;
            background: #f1f5f9;
            padding: 1pt 2pt;
            border-radius: 2pt;
            font-size: 7.5pt;
        }
        pre {
            background: #f8fafc;
            border: 1pt solid #e2e8f0;
            padding: 6pt;
            font-size: 7.5pt;
            font-family: ui-monospace, Menlo, Consolas, monospace;
            white-space: pre-wrap;
            page-break-inside: avoid;
        }
        </style>
        </head>
        <body>

        <div class="header">
            <div class="title">Growcery Master Kontext & Vorrats-Datenbank</div>
            <div class="subtitle">Klinisches Ernährungsprofil, Mathematisches Gesundheitsscoring-System & Vorratskatalog</div>
            <div class="meta-bar">NUTRIVAULT SYSTEM DIRECTIVE | STAND: \(dateStr) | POSITIONEN: \(pantryItems.count)</div>
        </div>

        <h2>1. Nutzer-Profil & Verbindliche Physiologische Constraints</h2>
        <table>
            <thead>
                <tr>
                    <th style="width: 25%;">Parameter</th>
                    <th style="width: 35%;">Zielkorridor / Vorschrift</th>
                    <th style="width: 40%;">Klinische & Operative Begründung</th>
                </tr>
            </thead>
            <tbody>
                <tr>
                    <td><strong>Nutzer-Status</strong></td>
                    <td>Soldat der Bundeswehr & Student Wirtschaftsinformatik</td>
                    <td>Hohe kognitive Last, Krafttraining (Hypertrophie), militärischer Dienstbetrieb.</td>
                </tr>
                <tr>
                    <td><strong>Tägliches Protein-Ziel</strong></td>
                    <td><strong>145 bis 170 g</strong> (Standard: 160 g)</td>
                    <td>Sicherung der Muskelproteinsynthese, Erhalt fettfreier Masse und langanhaltende Sättigung.</td>
                </tr>
                <tr>
                    <td><strong>Tägliches Kalorien-Budget</strong></td>
                    <td>1.850 bis 2.000 kcal</td>
                    <td>Isokalorischer Erhalt / Recomposition.</td>
                </tr>
                <tr>
                    <td><strong>BWK Ulm Viszeral-Reha</strong></td>
                    <td><strong>25 bis 35 g Ballaststoffe</strong> täglich</td>
                    <td>Post-Analprolaps-Operation (11/2024). Strikte Vermeidung von intraabdominalem Pressdruck; Bristol-Stuhlform Typ 4 erzwingen. Hohe Dichte an löslichen Schleimstoffen.</td>
                </tr>
                <tr>
                    <td><strong>Stiller Reflux (LPR) Schutz</strong></td>
                    <td>Strikte Nahrungskarenz 3h vor Nachtruhe</td>
                    <td>Abends keine Sphinkter-Relaxantien: Kein Kaffee, keine Minze, keine Schokolade, keine rohen Zwiebeln/Knoblauch, Fettgehalt &lt; 15 g/Mahlzeit.</td>
                </tr>
                <tr>
                    <td><strong>AuDHD Blutzucker-Stabilität</strong></td>
                    <td>Niedrige/Moderate Glykämie (GI &le; 55)</td>
                    <td>Kohlenhydrate müssen ausnahmslos an Protein und Ballaststoffe gekoppelt werden (keine isolierten GI-Peaks).</td>
                </tr>
                <tr>
                    <td><strong>Stuben-Küchen-Infrastruktur</strong></td>
                    <td>AirFryer, Mikrowelle, 1-Feld Induktion</td>
                    <td>Keine Backöfen mit langen Vorheizzeiten. Maximale Zubereitungszeit: 10 bis 15 Minuten.</td>
                </tr>
            </tbody>
        </table>

        <h2>2. Das NutriVault Gesundheitsscoring-System (Die 7 Säulen & Phi-Index)</h2>
        <p>Die Qualität jeder Zutat und jedes Rezepts wird über den gewichteten <strong>Composite Health Index &Phi;</strong> (0 bis 100 Punkte) quantifiziert:</p>
        <p style="text-align: center; font-family: monospace; font-size: 8.5pt; background: #f8fafc; border: 1pt solid #cbd5e1; padding: 4pt;">
            &Phi; = 0,25 &times; TuftsFoodCompass + 0,20 &times; TyBealScore + 0,20 &times; BWK_Visceral + 0,15 &times; AMDR_Protein + 0,10 &times; LPR_Safety + 0,10 &times; NOVA
        </p>

        <table>
            <thead>
                <tr>
                    <th>Säule</th>
                    <th>Skala</th>
                    <th>Fokus & Klinische Kriterien</th>
                    <th>Zielwert</th>
                </tr>
            </thead>
            <tbody>
                <tr>
                    <td><strong>1. BWK Ulm Visceral-Reha</strong></td>
                    <td>0 – 100</td>
                    <td>Ballaststoffdichte (&ge; 14g/1000kcal), lösliche Schleimstoffe (+25 Pkt), Abzug bei Natrium &gt; 700mg und gesättigten Fetten &gt; 8g.</td>
                    <td>&ge; 75 (Bristol Typ 4)</td>
                </tr>
                <tr>
                    <td><strong>2. LPR Gastric Safety</strong></td>
                    <td>0 – 100</td>
                    <td>Schutz vor Säurereflux. Fettabzug (&gt; 10g / &gt; 20g), -40 Pkt für Sphinkter-Relaxantien (Koffein, Minze, Schokolade, Chili, Knoblauch, Zwiebel).</td>
                    <td>&ge; 75 für Abendmahlzeiten</td>
                </tr>
                <tr>
                    <td><strong>3. Ty Beal Nutrient Density</strong></td>
                    <td>0 – 100</td>
                    <td>Proteinqualität (25 Pkt), Mikronährstoffe (35 Pkt), Kalium-Natrium-Verhältnis K:Na &ge; 2,0 (25 Pkt), Ballaststoffe (15 Pkt).</td>
                    <td>&ge; 70 (Mikronährstoffreich)</td>
                </tr>
                <tr>
                    <td><strong>4. Tufts Food Compass</strong></td>
                    <td>1 – 100</td>
                    <td>Unverarbeitete Vollwertkost, Mikronährstoffe, Bestrafung von Zuckerzusatz und raffinierter Stärke.</td>
                    <td>&ge; 70 (Bevorzugen)</td>
                </tr>
                <tr>
                    <td><strong>5. NOVA-Klassifikation</strong></td>
                    <td>1 – 4</td>
                    <td>NOVA 1 (Unverarbeitet, 100 Pkt), NOVA 2 (Kulinarisch, 80 Pkt), NOVA 3 (Verarbeitet, 55 Pkt), NOVA 4 (Ultra-verarbeitet, 20 Pkt).</td>
                    <td>NOVA 1 oder 2</td>
                </tr>
                <tr>
                    <td><strong>6. AMDR Protein-Dichte & GI</strong></td>
                    <td>% & GI</td>
                    <td>Proteinanteil 25–40 % der Kalorien, GI &le; 55.</td>
                    <td>Optimal</td>
                </tr>
            </tbody>
        </table>

        <h2>3. Vollständige Rohstoff- & Vorrats-Datenbank (\(pantryItems.count) Positionen)</h2>
        <table>
            <thead>
                <tr>
                    <th>ID</th>
                    <th>Produkt</th>
                    <th>Marke</th>
                    <th>Store</th>
                    <th>Preis</th>
                    <th>Packung</th>
                    <th>Bestand</th>
                    <th>Ort</th>
                    <th>kcal</th>
                    <th>Prot</th>
                    <th>KH</th>
                    <th>Fett</th>
                    <th>Ball</th>
                    <th>Score &Phi;</th>
                    <th>BWK</th>
                    <th>LPR</th>
                    <th>NOVA</th>
                </tr>
            </thead>
            <tbody>
                \(rowsHTML)
            </tbody>
        </table>

        <h2>4. Bestehende Rezepturen & Baukästen (\(mealTemplates.count) Templates)</h2>
        \(templatesHTML)

        <h2>5. Prompt-Vorlage für externe KI (ChatGPT / Claude / Gemini)</h2>
        <pre>Du bist der klinisch-diätetische Küchenchef des NutriVault / Growcery Systems.
Ich habe dir das offizielle Master-PDF mit meinem physiologischen Profil, dem Gesundheitsscoring-System (&Phi;-Index, BWK-Ulm Reha, LPR-Schutz) und meinem \(pantryItems.count)-Zutaten-Vorratskatalog vorgelegt.

AUFGABE:
Erstelle 3 maßgeschneiderte, alltagstaugliche Rezepte:
1. Mittagessen / Warm Roast (AirFryer oder 1-Feld Induktion, Zubereitung &le; 15 Min).
2. Abendmahlzeit (Strikter LPR-Schutz: LPR-Score &ge; 80, Fett &lt; 15g, null Knoblauch/Zwiebeln/Minze/Chili, hoher Ballaststoffanteil).
3. High-Protein Fiber Bowl / Post-Workout (Sättigend, GI &le; 50, Protein &ge; 45g).

REGELN:
- Verwende AUSSCHLIESSLICH Zutaten mit ihren exakten IDs aus der Tabelle.
- Berechne für jedes Rezept: Gesamtkalorien, Protein (g), Kohlenhydrate (g), Fett (g), Ballaststoffe (g) und die Scores (&Phi;-Index, BWK-Score, LPR-Score).
- Küchen-Hardware: Ausschließlich AirFryer, Mikrowelle oder 1-Feld Induktionsplatte.</pre>

        </body>
        </html>
"""
    }
}
