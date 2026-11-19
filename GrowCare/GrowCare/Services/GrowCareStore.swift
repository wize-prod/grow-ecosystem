import Foundation
import SwiftUI
import Combine

@MainActor
public final class GrowCareStore: ObservableObject {
    public static let shared = GrowCareStore()

    // MARK: - Published State
    @Published public var selectedDate: Date = Date()
    @Published public var careRoutines: [CareRoutineItem] = []
    @Published public var chores: [ChoreRoutineItem] = []
    @Published public var products: [CareProduct] = []
    @Published public var logs: [CareLogEntry] = []
    @Published public var completedRoutineIds: [String: Set<String>] = [:] // dateString -> [routineId]
    @Published public var completedChoreIds: [String: Set<String>] = [:]   // dateString -> [choreId]
    @Published public var requestedShoppingProductIds: Set<String> = []

    // MARK: - Persistence URLs
    private let fileManager = FileManager.default
    private var docsURL: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    private var routinesURL: URL { docsURL.appendingPathComponent("care_routines.json") }
    private var choresURL: URL { docsURL.appendingPathComponent("kaserne_chores.json") }
    private var productsURL: URL { docsURL.appendingPathComponent("care_products.json") }
    private var logsURL: URL { docsURL.appendingPathComponent("care_logs.json") }
    private var completedRoutinesURL: URL { docsURL.appendingPathComponent("completed_routines.json") }
    private var completedChoresURL: URL { docsURL.appendingPathComponent("completed_chores.json") }

    public init() {
        loadAllData()
        syncWithGrowFinanceRegistry()
    }

    // MARK: - Data Loading & Seeding
    public func loadAllData() {
        // 1. Care Products (Merge new catalog items into saved state)
        if let data = try? Data(contentsOf: productsURL),
           var saved = try? JSONDecoder().decode([CareProduct].self, from: data),
           !saved.isEmpty {
            let existingIds = Set(saved.map { $0.id })
            var didAdd = false
            for catProd in CareCatalogData.allProducts {
                if !existingIds.contains(catProd.id) {
                    saved.append(catProd)
                    didAdd = true
                }
            }
            self.products = saved
            if didAdd { saveProducts() }
        } else {
            self.products = CareCatalogData.allProducts
            saveProducts()
        }

        // 2. Care Routines (Merge new catalog items into saved state)
        if let data = try? Data(contentsOf: routinesURL),
           var saved = try? JSONDecoder().decode([CareRoutineItem].self, from: data),
           !saved.isEmpty {
            let existingIds = Set(saved.map { $0.id })
            var didAdd = false
            for catRoutine in CareCatalogData.allRoutines {
                if !existingIds.contains(catRoutine.id) {
                    saved.append(catRoutine)
                    didAdd = true
                }
            }
            self.careRoutines = saved
            if didAdd { saveRoutines() }
        } else {
            self.careRoutines = CareCatalogData.allRoutines
            saveRoutines()
        }

        // 3. Kasernen Chores (Excludes CPAP disinfection)
        if let data = try? Data(contentsOf: choresURL),
           let saved = try? JSONDecoder().decode([ChoreRoutineItem].self, from: data),
           !saved.isEmpty {
            self.chores = saved
        } else {
            self.chores = ChoreCatalogData.allChores
            saveChores()
        }

        // 4. Completed Routines Map
        if let data = try? Data(contentsOf: completedRoutinesURL),
           let saved = try? JSONDecoder().decode([String: [String]].self, from: data) {
            self.completedRoutineIds = saved.mapValues { Set($0) }
        }

        // 5. Completed Chores Map
        if let data = try? Data(contentsOf: completedChoresURL),
           let saved = try? JSONDecoder().decode([String: [String]].self, from: data) {
            self.completedChoreIds = saved.mapValues { Set($0) }
        }

        // 6. Care Logs
        if let data = try? Data(contentsOf: logsURL),
           let saved = try? JSONDecoder().decode([CareLogEntry].self, from: data) {
            self.logs = saved
        } else {
            self.logs = []
        }
    }

    // MARK: - Persistence Helpers
    public func saveProducts() {
        if let data = try? JSONEncoder().encode(products) {
            try? data.write(to: productsURL, options: .atomic)
        }
    }

    public func saveRoutines() {
        if let data = try? JSONEncoder().encode(careRoutines) {
            try? data.write(to: routinesURL, options: .atomic)
        }
    }

    public func saveChores() {
        if let data = try? JSONEncoder().encode(chores) {
            try? data.write(to: choresURL, options: .atomic)
        }
    }

    public func saveLogs() {
        if let data = try? JSONEncoder().encode(logs) {
            try? data.write(to: logsURL, options: .atomic)
        }
    }

    public func saveCompletions() {
        let routinesMapped = completedRoutineIds.mapValues { Array($0) }
        if let data = try? JSONEncoder().encode(routinesMapped) {
            try? data.write(to: completedRoutinesURL, options: .atomic)
        }

        let choresMapped = completedChoreIds.mapValues { Array($0) }
        if let data = try? JSONEncoder().encode(choresMapped) {
            try? data.write(to: completedChoresURL, options: .atomic)
        }
    }

    // MARK: - Date Helpers
    public func dateKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    // MARK: - Routine Actions
    public func isRoutineCompleted(_ routine: CareRoutineItem, on date: Date) -> Bool {
        let key = dateKey(for: date)
        return completedRoutineIds[key]?.contains(routine.id) ?? false
    }

    public func toggleRoutineCompletion(_ routine: CareRoutineItem, on date: Date) {
        let key = dateKey(for: date)
        var set = completedRoutineIds[key] ?? Set<String>()
        if set.contains(routine.id) {
            set.remove(routine.id)
        } else {
            set.insert(routine.id)
        }
        completedRoutineIds[key] = set
        saveCompletions()
    }

    // MARK: - Chore Actions
    public func isChoreCompleted(_ chore: ChoreRoutineItem, on date: Date) -> Bool {
        let key = dateKey(for: date)
        return completedChoreIds[key]?.contains(chore.id) ?? false
    }

    public func toggleChoreCompletion(_ chore: ChoreRoutineItem, on date: Date) {
        let key = dateKey(for: date)
        var set = completedChoreIds[key] ?? Set<String>()
        if set.contains(chore.id) {
            set.remove(chore.id)
        } else {
            set.insert(chore.id)
        }
        completedChoreIds[key] = set
        saveCompletions()
    }

    public func deleteLog(id: String) {
        if let item = logs.first(where: { $0.id == id }) {
            let key = item.dateString
            var routines = completedRoutineIds[key] ?? Set<String>()
            routines.remove(item.routineId)
            completedRoutineIds[key] = routines

            var chores = completedChoreIds[key] ?? Set<String>()
            chores.remove(item.routineId)
            completedChoreIds[key] = chores

            logs.removeAll { $0.id == id }
            saveCompletions()
            saveLogs()
        }
    }

    // MARK: - Scheduled Filters
    public func scheduledRoutines(for date: Date) -> [CareRoutineItem] {
        careRoutines.filter { CareCatalogData.isRoutineScheduled($0, on: date) }
    }

    public func scheduledRoutines(for date: Date, zone: CareZone) -> [CareRoutineItem] {
        let all = scheduledRoutines(for: date)
        if zone == .all { return all }
        return all.filter { $0.zone == zone }
    }

    public func scheduledChores(for date: Date) -> [ChoreRoutineItem] {
        chores.filter { ChoreCatalogData.isChoreScheduled($0, on: date) }
    }

    public func scheduledChores(for date: Date, zone: CareZone) -> [ChoreRoutineItem] {
        let all = scheduledChores(for: date)
        if zone == .all || zone == .chores { return all }
        return []
    }

    public func products(for zone: CareZone) -> [CareProduct] {
        if zone == .all { return products }
        return products.filter { $0.zone == zone }
    }

    public func logs(for date: Date) -> [CareLogEntry] {
        let key = dateKey(for: date)
        return logs.filter { $0.dateString == key }
    }

    // MARK: - GrowFinance Shopping Bridge Connection
    public func requestProductOrder(product: CareProduct) {
        let item = SharedShoppingItem(
            id: UUID().uuidString,
            name: "\(product.brand) \(product.name)",
            price: product.price,
            store: "AMAZON",
            quantity: 1,
            category: "Pflege",
            webUrl: product.amazonUrl,
            isBought: false,
            isSaved: false,
            recurrenceRule: nil,
            lastUpdated: Date()
        )

        var existingPayload = GrowSuiteBridge.shared.loadShopping()
        // Deduplicate
        if !existingPayload.items.contains(where: { $0.name == item.name && !$0.isBought }) {
            existingPayload.items.insert(item, at: 0)
            existingPayload.lastUpdated = Date()
            _ = GrowSuiteBridge.shared.saveShopping(existingPayload)
        }
        requestedShoppingProductIds.insert(product.id)
    }

    public func isProductRequestedInFinance(product: CareProduct) -> Bool {
        if requestedShoppingProductIds.contains(product.id) { return true }
        let payload = GrowSuiteBridge.shared.loadShopping()
        return payload.items.contains {
            ($0.name.contains(product.name) || $0.webUrl == product.amazonUrl) && !$0.isBought
        }
    }

    public func syncWithGrowFinanceRegistry() {
        let payload = GrowSuiteBridge.shared.loadShopping()
        for p in products {
            if payload.items.contains(where: { ($0.name.contains(p.name) || $0.webUrl == p.amazonUrl) && !$0.isBought }) {
                requestedShoppingProductIds.insert(p.id)
            }
        }
    }
}

