import Foundation
import Security
#if canImport(UIKit)
import UIKit
#endif
import SwiftUI

// MARK: - 1. Shared Macro Payload (Growcery -> Grow)
public struct SharedMacroPayload: Codable, Equatable, Sendable {
    public var protein: Double
    public var carbs: Double
    public var fat: Double
    public var calories: Double
    public var proteinTarget: Double
    public var caloriesTarget: Double
    public var fiber: Double
    public var hydrationLiters: Double
    public var dateString: String
    public var timestamp: Date

    public init(
        protein: Double,
        carbs: Double,
        fat: Double,
        calories: Double,
        proteinTarget: Double = 160.0,
        caloriesTarget: Double = 1900.0,
        fiber: Double = 0.0,
        hydrationLiters: Double = 0.0,
        date: Date = Date()
    ) {
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.calories = calories
        self.proteinTarget = proteinTarget
        self.caloriesTarget = caloriesTarget
        self.fiber = fiber
        self.hydrationLiters = hydrationLiters
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        self.dateString = formatter.string(from: date)
        self.timestamp = date
    }
}

// MARK: - 2. Shared Workout Payload (Grow -> Growcery)
public struct SharedWorkoutPayload: Codable, Equatable, Sendable {
    public var workoutId: String
    public var title: String
    public var completionDate: Date
    public var durationMinutes: Int
    public var totalTonnageKg: Double
    public var caloriesBurned: Double
    public var perceivedExertionRPE: Int
    public var muscleGroupsHit: [String]
    public var isBWKReha: Bool
    public var dateString: String

    public init(
        workoutId: String = UUID().uuidString,
        title: String,
        completionDate: Date = Date(),
        durationMinutes: Int,
        totalTonnageKg: Double,
        caloriesBurned: Double,
        perceivedExertionRPE: Int = 7,
        muscleGroupsHit: [String] = [],
        isBWKReha: Bool = false
    ) {
        self.workoutId = workoutId
        self.title = title
        self.completionDate = completionDate
        self.durationMinutes = durationMinutes
        self.totalTonnageKg = totalTonnageKg
        self.caloriesBurned = caloriesBurned
        self.perceivedExertionRPE = perceivedExertionRPE
        self.muscleGroupsHit = muscleGroupsHit
        self.isBWKReha = isBWKReha
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        self.dateString = formatter.string(from: completionDate)
    }
}

// MARK: - 3. Shared Supplement Payload (Single Source of Truth)
public struct SharedSupplementPayload: Codable, Equatable, Sendable {
    public var dateString: String
    public var takenDoseIds: [String: Date]
    public var lastUpdated: Date

    public init(
        date: Date = Date(),
        takenDoseIds: [String: Date] = [:],
        lastUpdated: Date = Date()
    ) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        self.dateString = formatter.string(from: date)
        self.takenDoseIds = takenDoseIds
        self.lastUpdated = lastUpdated
    }
}

// MARK: - 4. Shared Water Payload (Realtime Hydration Sync across 3 Apps)
public struct SharedWaterEntry: Identifiable, Codable, Equatable, Sendable {
    public var id: String
    public var amountMl: Double
    public var timestamp: Date
    public var sourceApp: String // "Grow", "Growcery", "GrowStudy"

    public init(
        id: String = UUID().uuidString,
        amountMl: Double,
        timestamp: Date = Date(),
        sourceApp: String = "GrowStudy"
    ) {
        self.id = id
        self.amountMl = amountMl
        self.timestamp = timestamp
        self.sourceApp = sourceApp
    }
}

public struct SharedWaterPayload: Codable, Equatable, Sendable {
    public var dateString: String
    public var totalWaterMl: Double
    public var targetWaterMl: Double
    public var entries: [SharedWaterEntry]
    public var lastUpdated: Date

    public init(
        date: Date = Date(),
        totalWaterMl: Double = 0.0,
        targetWaterMl: Double = 2500.0,
        entries: [SharedWaterEntry] = [],
        lastUpdated: Date = Date()
    ) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        self.dateString = formatter.string(from: date)
        self.totalWaterMl = totalWaterMl
        self.targetWaterMl = targetWaterMl
        self.entries = entries
        self.lastUpdated = lastUpdated
    }
}

// MARK: - 5. Shared Finance Payload (Cross-App Financial Telemetry & Discipline Gates)
public struct SharedFinancePayload: Codable, Equatable, Sendable {
    public var dateString: String
    public var plusKontoBalance: Double
    public var safeToSpend: Double
    public var isDispoSafe: Bool
    public var totalSavings: Double
    public var remainingLoan: Double
    public var foodLeakFreeStreakDays: Int
    public var savedLeakCapitalTotal: Double
    public var lastDeliveryDetectedDate: Date?
    public var dynamicFoodBudgetMonthly: Double
    public var dynamicFoodBudgetRemaining: Double
    public var dailyFoodRate: Double
    public var lastUpdated: Date

    enum CodingKeys: String, CodingKey {
        case dateString, plusKontoBalance, safeToSpend, isDispoSafe, totalSavings, remainingLoan
        case foodLeakFreeStreakDays, savedLeakCapitalTotal, lastDeliveryDetectedDate
        case dynamicFoodBudgetMonthly, dynamicFoodBudgetRemaining, dailyFoodRate, lastUpdated
    }

    public init(
        date: Date = Date(),
        plusKontoBalance: Double = 202.49,
        safeToSpend: Double = 102.49,
        isDispoSafe: Bool = true,
        totalSavings: Double = 9319.94,
        remainingLoan: Double = 11481.97,
        foodLeakFreeStreakDays: Int = 7,
        savedLeakCapitalTotal: Double = 84.0,
        lastDeliveryDetectedDate: Date? = nil,
        dynamicFoodBudgetMonthly: Double = 255.0,
        dynamicFoodBudgetRemaining: Double = 85.0,
        dailyFoodRate: Double = 8.50,
        lastUpdated: Date = Date()
    ) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        self.dateString = formatter.string(from: date)
        self.plusKontoBalance = plusKontoBalance
        self.safeToSpend = safeToSpend
        self.isDispoSafe = isDispoSafe
        self.totalSavings = totalSavings
        self.remainingLoan = remainingLoan
        self.foodLeakFreeStreakDays = foodLeakFreeStreakDays
        self.savedLeakCapitalTotal = savedLeakCapitalTotal
        self.lastDeliveryDetectedDate = lastDeliveryDetectedDate
        self.dynamicFoodBudgetMonthly = dynamicFoodBudgetMonthly
        self.dynamicFoodBudgetRemaining = dynamicFoodBudgetRemaining
        self.dailyFoodRate = dailyFoodRate
        self.lastUpdated = lastUpdated
    }
}

// MARK: - 4.5 Cross-App Field Note Payload (Heat-of-the-Moment Scratchpad)
public struct FieldNoteEntry: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let timestamp: Date
    public let authorApp: String
    public var text: String
    public var category: String
    public var isResolved: Bool

    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        authorApp: String,
        text: String,
        category: String = "ALLGEMEIN",
        isResolved: Bool = false
    ) {
        self.id = id
        self.timestamp = timestamp
        self.authorApp = authorApp
        self.text = text
        self.category = category
        self.isResolved = isResolved
    }
}

public struct FieldNotesPayload: Codable, Sendable {
    public var notes: [FieldNoteEntry]
    public var lastUpdated: Date

    public init(notes: [FieldNoteEntry] = [], lastUpdated: Date = Date()) {
        self.notes = notes
        self.lastUpdated = lastUpdated
    }
}

// MARK: - Shared Shopping Payload (GrowFinance <-> Growcery Sync)
public struct SharedShoppingItem: Identifiable, Codable, Equatable, Sendable {
    public var id: String
    public var name: String
    public var price: Double
    public var store: String
    public var quantity: Int
    public var category: String
    public var webUrl: String?
    public var isBought: Bool
    public var isSaved: Bool
    public var recurrenceRule: CustomRecurrenceRule?
    public var lastUpdated: Date

    public init(
        id: String = UUID().uuidString,
        name: String,
        price: Double = 0.0,
        store: String = "AMAZON",
        quantity: Int = 1,
        category: String = "Allgemein",
        webUrl: String? = nil,
        isBought: Bool = false,
        isSaved: Bool = false,
        recurrenceRule: CustomRecurrenceRule? = nil,
        lastUpdated: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.price = price
        self.store = store
        self.quantity = quantity
        self.category = category
        self.webUrl = webUrl
        self.isBought = isBought
        self.isSaved = isSaved
        self.recurrenceRule = recurrenceRule
        self.lastUpdated = lastUpdated
    }
}

public struct SharedShoppingPayload: Codable, Equatable, Sendable {
    public var items: [SharedShoppingItem]
    public var deletedIds: [String]
    public var lastUpdated: Date

    public init(items: [SharedShoppingItem] = [], deletedIds: [String] = [], lastUpdated: Date = Date()) {
        self.items = items
        self.deletedIds = deletedIds
        self.lastUpdated = lastUpdated
    }
}

// MARK: - 8. Shared Device Google Account Payload
public struct SharedDeviceGoogleAccountPayload: Codable, Equatable, Sendable {
    public var email: String
    public var displayName: String
    public var initial: String
    public var roleTag: String
    public var lastUpdated: Date

    public init(
        email: String,
        displayName: String,
        initial: String = "",
        roleTag: String = "Test-Nutzer",
        lastUpdated: Date = Date()
    ) {
        self.email = email
        self.displayName = displayName
        self.initial = initial.isEmpty ? String(displayName.prefix(1)).uppercased() : initial
        self.roleTag = roleTag
        self.lastUpdated = lastUpdated
    }
}

// MARK: - 9. Shared Grocery Receipt Payload (Growcery -> GrowFinance)
public struct SharedGroceryReceiptPayload: Codable, Equatable, Sendable {
    public var id: String
    public var date: Date
    public var storeName: String
    public var totalAmount: Double
    public var foodAmount: Double
    public var nonFoodAmount: Double
    public var itemCount: Int
    public var lineItemSummaries: [String]
    public var nonFoodSummaries: [String]
    public var lastUpdated: Date

    enum CodingKeys: String, CodingKey {
        case id, date, storeName, totalAmount, foodAmount, nonFoodAmount, itemCount, lineItemSummaries, nonFoodSummaries, lastUpdated
    }

    public init(
        id: String = UUID().uuidString,
        date: Date = Date(),
        storeName: String,
        totalAmount: Double,
        foodAmount: Double? = nil,
        nonFoodAmount: Double = 0.0,
        itemCount: Int = 1,
        lineItemSummaries: [String] = [],
        nonFoodSummaries: [String] = [],
        lastUpdated: Date = Date()
    ) {
        self.id = id
        self.date = date
        self.storeName = storeName
        self.totalAmount = totalAmount
        self.foodAmount = foodAmount ?? max(0.0, totalAmount - nonFoodAmount)
        self.nonFoodAmount = nonFoodAmount
        self.itemCount = itemCount
        self.lineItemSummaries = lineItemSummaries
        self.nonFoodSummaries = nonFoodSummaries
        self.lastUpdated = lastUpdated
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.date = try container.decode(Date.self, forKey: .date)
        self.storeName = try container.decode(String.self, forKey: .storeName)
        let total = try container.decode(Double.self, forKey: .totalAmount)
        self.totalAmount = total
        let nonFood = try container.decodeIfPresent(Double.self, forKey: .nonFoodAmount) ?? 0.0
        self.nonFoodAmount = nonFood
        self.foodAmount = try container.decodeIfPresent(Double.self, forKey: .foodAmount) ?? max(0.0, total - nonFood)
        self.itemCount = try container.decodeIfPresent(Int.self, forKey: .itemCount) ?? 1
        self.lineItemSummaries = try container.decodeIfPresent([String].self, forKey: .lineItemSummaries) ?? []
        self.nonFoodSummaries = try container.decodeIfPresent([String].self, forKey: .nonFoodSummaries) ?? []
        self.lastUpdated = try container.decodeIfPresent(Date.self, forKey: .lastUpdated) ?? Date()
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(date, forKey: .date)
        try container.encode(storeName, forKey: .storeName)
        try container.encode(totalAmount, forKey: .totalAmount)
        try container.encode(foodAmount, forKey: .foodAmount)
        try container.encode(nonFoodAmount, forKey: .nonFoodAmount)
        try container.encode(itemCount, forKey: .itemCount)
        try container.encode(lineItemSummaries, forKey: .lineItemSummaries)
        try container.encode(nonFoodSummaries, forKey: .nonFoodSummaries)
        try container.encode(lastUpdated, forKey: .lastUpdated)
    }
}

public struct SharedGroceryReceiptsLedger: Codable, Equatable, Sendable {
    public var receipts: [SharedGroceryReceiptPayload]
    public var lastUpdated: Date

    public init(receipts: [SharedGroceryReceiptPayload] = [], lastUpdated: Date = Date()) {
        self.receipts = receipts
        self.lastUpdated = lastUpdated
    }
}

// MARK: - 6. Shared Logged Meals Ledger (Past, Present & Future)
public struct SharedLoggedMeal: Identifiable, Codable, Equatable, Sendable {
    public var id: String
    public var foodName: String
    public var mealType: String
    public var recipeName: String?
    public var weightGrams: Double
    public var kcal: Double
    public var protein: Double
    public var carbs: Double
    public var fat: Double
    public var fiber: Double
    public var timestamp: Date
    public var dateString: String

    public init(
        id: String = UUID().uuidString,
        foodName: String,
        mealType: String = "Mahlzeit",
        recipeName: String? = nil,
        weightGrams: Double,
        kcal: Double,
        protein: Double,
        carbs: Double,
        fat: Double,
        fiber: Double = 0.0,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.foodName = foodName
        self.mealType = mealType
        self.recipeName = recipeName
        self.weightGrams = weightGrams
        self.kcal = kcal
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.fiber = fiber
        self.timestamp = timestamp
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        self.dateString = formatter.string(from: timestamp)
    }
}

public struct SharedMealsLedger: Codable, Equatable, Sendable {
    public var meals: [SharedLoggedMeal]
    public var lastUpdated: Date

    public init(meals: [SharedLoggedMeal] = [], lastUpdated: Date = Date()) {
        self.meals = meals
        self.lastUpdated = lastUpdated
    }
}

// MARK: - 7. Shared Workout Schedule Ledger (Past Completed & Future Planned)
public struct SharedWorkoutScheduleItem: Identifiable, Codable, Equatable, Sendable {
    public var id: String
    public var title: String
    public var scheduledDate: Date
    public var dateString: String
    public var isCompleted: Bool
    public var completedAt: Date?
    public var exerciseNames: [String]
    public var notes: String?
    public var totalTonnageKg: Double?
    public var durationMinutes: Int?

    public init(
        id: String = UUID().uuidString,
        title: String,
        scheduledDate: Date,
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        exerciseNames: [String] = [],
        notes: String? = nil,
        totalTonnageKg: Double? = nil,
        durationMinutes: Int? = nil
    ) {
        self.id = id
        self.title = title
        self.scheduledDate = scheduledDate
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.exerciseNames = exerciseNames
        self.notes = notes
        self.totalTonnageKg = totalTonnageKg
        self.durationMinutes = durationMinutes
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        self.dateString = formatter.string(from: scheduledDate)
    }
}

public struct SharedWorkoutScheduleLedger: Codable, Equatable, Sendable {
    public var items: [SharedWorkoutScheduleItem]
    public var lastUpdated: Date

    public init(items: [SharedWorkoutScheduleItem] = [], lastUpdated: Date = Date()) {
        self.items = items
        self.lastUpdated = lastUpdated
    }
}

// MARK: - 8. Shared Supplement Schedule Ledger
public struct SharedSupplementScheduleItem: Identifiable, Codable, Equatable, Sendable {
    public var id: String
    public var title: String
    public var timeString: String
    public var dosage: String
    public var targetEffect: String
    public var isTaken: Bool
    public var takenAt: Date?
    public var dateString: String

    public init(
        id: String = UUID().uuidString,
        title: String,
        timeString: String,
        dosage: String,
        targetEffect: String,
        isTaken: Bool = false,
        takenAt: Date? = nil,
        date: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.timeString = timeString
        self.dosage = dosage
        self.targetEffect = targetEffect
        self.isTaken = isTaken
        self.takenAt = takenAt
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        self.dateString = formatter.string(from: date)
    }
}

public struct SharedSupplementScheduleLedger: Codable, Equatable, Sendable {
    public var items: [SharedSupplementScheduleItem]
    public var lastUpdated: Date

    public init(items: [SharedSupplementScheduleItem] = [], lastUpdated: Date = Date()) {
        self.items = items
        self.lastUpdated = lastUpdated
    }
}

// MARK: - Darwin Notification Bus for Realtime Inter-App Sync
public final class DarwinNotificationCenter {
    public static let waterUpdated = "com.nkembi.growsuite.waterUpdated"
    public static let macrosUpdated = "com.nkembi.growsuite.macrosUpdated"
    public static let suppsUpdated = "com.nkembi.growsuite.suppsUpdated"
    public static let financeUpdated = "com.nkembi.growsuite.financeUpdated"
    public static let fieldNotesUpdated = "com.nkembi.growsuite.fieldnotesUpdated"
    public static let shoppingUpdated = "com.nkembi.growsuite.shoppingUpdated"
    public static let deviceGoogleAccountUpdated = "com.nkembi.growsuite.deviceGoogleAccountUpdated"
    public static let groceryReceiptsUpdated = "com.nkembi.growsuite.groceryreceiptsUpdated"
    public static let mealsLedgerUpdated = "com.nkembi.growsuite.mealsLedgerUpdated"
    public static let workoutScheduleLedgerUpdated = "com.nkembi.growsuite.workoutScheduleLedgerUpdated"
    public static let supplementScheduleLedgerUpdated = "com.nkembi.growsuite.supplementScheduleLedgerUpdated"

    public static func post(_ name: String) {
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        CFNotificationCenterPostNotification(center, CFNotificationName(name as CFString), nil, nil, true)
    }

    public static func observe(_ name: String, callback: @escaping () -> Void) {
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        let observer = Unmanaged.passRetained(CallbackWrapper(callback)).toOpaque()
        CFNotificationCenterAddObserver(
            center,
            observer,
            { _, observer, _, _, _ in
                guard let observer = observer else { return }
                let wrapper = Unmanaged<CallbackWrapper>.fromOpaque(observer).takeUnretainedValue()
                DispatchQueue.main.async {
                    wrapper.action()
                }
            },
            name as CFString,
            nil,
            .deliverImmediately
        )
    }
}

private final class CallbackWrapper {
    let action: () -> Void
    init(_ action: @escaping () -> Void) {
        self.action = action
    }
}

// MARK: - 5. Unified GrowSuite Bridge Engine
public final class GrowSuiteBridge {
    public static let shared = GrowSuiteBridge()

    private let accessGroup = "X83D9W2G74.com.nkembi.sharedMacros"
    private let serviceKey = "com.nkembi.growsuitebridge"
    private let macrosAccountKey = "daily_macro_payload"
    private let workoutAccountKey = "latest_workout_payload"
    private let supplementAccountKey = "daily_supplement_payload"
    private let waterAccountKey = "daily_water_payload"
    private let financeAccountKey = "daily_finance_payload"
    private let fieldNotesAccountKey = "daily_field_notes_payload"
    private let shoppingAccountKey = "daily_shopping_payload"
    private let groceryReceiptsAccountKey = "shared_grocery_receipts_payload"
    private let mealsLedgerAccountKey = "shared_meals_ledger_payload"
    private let workoutScheduleAccountKey = "shared_workout_schedule_payload"
    private let supplementScheduleAccountKey = "shared_supplement_schedule_payload"
    
    private let pasteboardMacrosName = "com.nkembi.growsharedmacros"
    private let pasteboardWorkoutName = "com.nkembi.growsharedworkout"
    private let pasteboardSupplementName = "com.nkembi.growsharedsupps"
    private let pasteboardWaterName = "com.nkembi.growsharedwater"
    private let pasteboardFinanceName = "com.nkembi.growsharedfinance"
    private let pasteboardFieldNotesName = "com.nkembi.growsharednotes"
    private let pasteboardShoppingName = "com.nkembi.growsharedshopping"
    private let pasteboardGroceryReceiptsName = "com.nkembi.growsharedreceipts"
    private let pasteboardMealsLedgerName = "com.nkembi.growsharedmealsledger"
    private let pasteboardWorkoutScheduleName = "com.nkembi.growsharedworkoutschedule"
    private let pasteboardSupplementScheduleName = "com.nkembi.growsharedsupplementschedule"

    private init() {}

    // MARK: - Device Google Account Sync (Assign across all Grow apps on this device)
    private let deviceAccountKey = "assigned_device_google_account_v2"
    private let pasteboardDeviceAccountName = "com.nkembi.growdeviceaccount"

    @discardableResult
    public func saveDeviceGoogleAccount(email: String, displayName: String, roleTag: String = "Test-Nutzer") -> Bool {
        let initial = String(displayName.prefix(1)).uppercased()
        let payload = SharedDeviceGoogleAccountPayload(
            email: email,
            displayName: displayName,
            initial: initial,
            roleTag: roleTag,
            lastUpdated: Date()
        )
        guard let data = try? JSONEncoder().encode(payload) else { return false }
        writeKeychain(data: data, accountKey: deviceAccountKey)
        writeCache(data: data, filename: "shared_device_google_account.json")
        writePasteboard(data: data, pasteboardName: pasteboardDeviceAccountName)
        DarwinNotificationCenter.post(DarwinNotificationCenter.deviceGoogleAccountUpdated)
        return true
    }

    public func loadDeviceGoogleAccount() -> SharedDeviceGoogleAccountPayload? {
        if let data = readKeychain(accountKey: deviceAccountKey),
           let payload = try? JSONDecoder().decode(SharedDeviceGoogleAccountPayload.self, from: data) {
            return payload
        }
        if let data = readCache(filename: "shared_device_google_account.json"),
           let payload = try? JSONDecoder().decode(SharedDeviceGoogleAccountPayload.self, from: data) {
            return payload
        }
        if let data = readPasteboard(pasteboardName: pasteboardDeviceAccountName),
           let payload = try? JSONDecoder().decode(SharedDeviceGoogleAccountPayload.self, from: data) {
            return payload
        }
        return nil
    }

    // MARK: - Shopping Sync (GrowFinance <-> Growcery)
    @discardableResult
    public func saveShopping(_ payload: SharedShoppingPayload) -> Bool {
        guard let data = try? JSONEncoder().encode(payload) else { return false }
        writeKeychain(data: data, accountKey: shoppingAccountKey)
        writeCache(data: data, filename: "shared_shopping.json")
        writePasteboard(data: data, pasteboardName: pasteboardShoppingName)
        DarwinNotificationCenter.post(DarwinNotificationCenter.shoppingUpdated)
        return true
    }

    public func loadShopping() -> SharedShoppingPayload {
        if let data = readKeychain(accountKey: shoppingAccountKey),
           let p = try? JSONDecoder().decode(SharedShoppingPayload.self, from: data) {
            return p
        }
        if let data = readCache(filename: "shared_shopping.json"),
           let p = try? JSONDecoder().decode(SharedShoppingPayload.self, from: data) {
            return p
        }
        if let data = readPasteboard(pasteboardName: pasteboardShoppingName),
           let p = try? JSONDecoder().decode(SharedShoppingPayload.self, from: data) {
            return p
        }
        return SharedShoppingPayload()
    }

    // MARK: - Grocery Receipts Sync (Growcery -> GrowFinance Cross-Device & Local)
    @discardableResult
    public func saveGroceryReceipts(_ payload: SharedGroceryReceiptsLedger) -> Bool {
        guard let data = try? JSONEncoder().encode(payload) else { return false }
        writeKeychain(data: data, accountKey: groceryReceiptsAccountKey)
        writeCache(data: data, filename: "shared_grocery_receipts.json")
        writePasteboard(data: data, pasteboardName: pasteboardGroceryReceiptsName)

        // Cross-device iCloud Key-Value Sync (iPhone <-> iPad mini across physical distance)
        NSUbiquitousKeyValueStore.default.set(data, forKey: groceryReceiptsAccountKey)
        NSUbiquitousKeyValueStore.default.synchronize()

        DarwinNotificationCenter.post(DarwinNotificationCenter.groceryReceiptsUpdated)
        return true
    }

    public func loadGroceryReceipts() -> SharedGroceryReceiptsLedger {
        // 1. Check iCloud Ubiquitous Key-Value store first (cross-device source of truth)
        if let data = NSUbiquitousKeyValueStore.default.data(forKey: groceryReceiptsAccountKey),
           let p = try? JSONDecoder().decode(SharedGroceryReceiptsLedger.self, from: data) {
            return p
        }
        // 2. Check Keychain (local on-device)
        if let data = readKeychain(accountKey: groceryReceiptsAccountKey),
           let p = try? JSONDecoder().decode(SharedGroceryReceiptsLedger.self, from: data) {
            return p
        }
        // 3. Check Cache
        if let data = readCache(filename: "shared_grocery_receipts.json"),
           let p = try? JSONDecoder().decode(SharedGroceryReceiptsLedger.self, from: data) {
            return p
        }
        // 4. Check Pasteboard
        if let data = readPasteboard(pasteboardName: pasteboardGroceryReceiptsName),
           let p = try? JSONDecoder().decode(SharedGroceryReceiptsLedger.self, from: data) {
            return p
        }
        return SharedGroceryReceiptsLedger()
    }

    public func appendGroceryReceipt(_ receipt: SharedGroceryReceiptPayload) {
        var ledger = loadGroceryReceipts()
        if !ledger.receipts.contains(where: { $0.id == receipt.id }) {
            ledger.receipts.insert(receipt, at: 0)
            ledger.lastUpdated = Date()
            saveGroceryReceipts(ledger)
        }
    }

    // MARK: - Macro Sync (Growcery -> Grow)
    @discardableResult
    public func saveMacros(_ payload: SharedMacroPayload) -> Bool {
        guard let data = try? JSONEncoder().encode(payload) else { return false }
        writeKeychain(data: data, accountKey: macrosAccountKey)
        writeCache(data: data, filename: "shared_macros.json")
        GrowMMKV.shared.set(data, forKey: "shared_macros")
        GrowDarwinEventBus.shared.post(.macroNutritionUpdated)
        DarwinNotificationCenter.post(DarwinNotificationCenter.macrosUpdated)
        return true
    }

    public func loadMacros() -> SharedMacroPayload? {
        if let data = GrowMMKV.shared.data(forKey: "shared_macros"),
           let p = try? JSONDecoder().decode(SharedMacroPayload.self, from: data) {
            return p
        }
        if let data = readKeychain(accountKey: macrosAccountKey),
           let payload = try? JSONDecoder().decode(SharedMacroPayload.self, from: data) {
            return payload
        }
        if let data = readCache(filename: "shared_macros.json"),
           let payload = try? JSONDecoder().decode(SharedMacroPayload.self, from: data) {
            return payload
        }
        return nil
    }

    // MARK: - Workout Sync (Grow -> Growcery)
    @discardableResult
    public func saveWorkout(_ payload: SharedWorkoutPayload) -> Bool {
        guard let data = try? JSONEncoder().encode(payload) else { return false }
        writeKeychain(data: data, accountKey: workoutAccountKey)
        writeCache(data: data, filename: "shared_workout.json")
        writePasteboard(data: data, pasteboardName: pasteboardWorkoutName)
        return true
    }

    public func loadLatestWorkout() -> SharedWorkoutPayload? {
        if let data = readKeychain(accountKey: workoutAccountKey),
           let payload = try? JSONDecoder().decode(SharedWorkoutPayload.self, from: data) {
            return payload
        }
        if let data = readCache(filename: "shared_workout.json"),
           let payload = try? JSONDecoder().decode(SharedWorkoutPayload.self, from: data) {
            return payload
        }
        if let data = readPasteboard(pasteboardName: pasteboardWorkoutName),
           let payload = try? JSONDecoder().decode(SharedWorkoutPayload.self, from: data) {
            return payload
        }
        return nil
    }

    // MARK: - Supplement Single Source of Truth & Anti-Doppelgabe
    @discardableResult
    public func saveSupplements(_ payload: SharedSupplementPayload) -> Bool {
        guard let data = try? JSONEncoder().encode(payload) else { return false }
        writeKeychain(data: data, accountKey: supplementAccountKey)
        writeCache(data: data, filename: "shared_supplements.json")
        GrowMMKV.shared.set(data, forKey: "shared_supplements")
        GrowDarwinEventBus.shared.post(.supplementDoseSealed)
        DarwinNotificationCenter.post(DarwinNotificationCenter.suppsUpdated)
        return true
    }

    public func loadSupplements(for date: Date = Date()) -> SharedSupplementPayload {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd"
        let todayStr = formatter.string(from: date)

        // 1. Zero-Copy POSIX mmap check (< 1 us)
        if let data = GrowMMKV.shared.data(forKey: "shared_supplements"),
           let p = try? JSONDecoder().decode(SharedSupplementPayload.self, from: data),
           p.dateString == todayStr {
            return p
        }

        var payload: SharedSupplementPayload?
        if let data = readKeychain(accountKey: supplementAccountKey),
           let p = try? JSONDecoder().decode(SharedSupplementPayload.self, from: data) {
            payload = p
        } else if let data = readCache(filename: "shared_supplements.json"),
                  let p = try? JSONDecoder().decode(SharedSupplementPayload.self, from: data) {
            payload = p
        }

        if let p = payload, p.dateString == todayStr {
            if let encoded = try? JSONEncoder().encode(p) {
                GrowMMKV.shared.set(encoded, forKey: "shared_supplements")
            }
            return p
        }
        return SharedSupplementPayload(date: date)
    }

    // MARK: - Meals Ledger Sync (Growcery <-> GrowTasks for Past, Present & Future)
    @discardableResult
    public func saveMealsLedger(_ payload: SharedMealsLedger) -> Bool {
        guard let data = try? JSONEncoder().encode(payload) else { return false }
        writeKeychain(data: data, accountKey: mealsLedgerAccountKey)
        writeCache(data: data, filename: "shared_meals_ledger.json")
        writePasteboard(data: data, pasteboardName: pasteboardMealsLedgerName)
        DarwinNotificationCenter.post(DarwinNotificationCenter.mealsLedgerUpdated)
        return true
    }

    public func loadMealsLedger() -> SharedMealsLedger {
        if let data = readKeychain(accountKey: mealsLedgerAccountKey),
           let p = try? JSONDecoder().decode(SharedMealsLedger.self, from: data) {
            return p
        } else if let data = readCache(filename: "shared_meals_ledger.json"),
                  let p = try? JSONDecoder().decode(SharedMealsLedger.self, from: data) {
            return p
        } else if let data = readPasteboard(pasteboardName: pasteboardMealsLedgerName),
                  let p = try? JSONDecoder().decode(SharedMealsLedger.self, from: data) {
            return p
        }
        return SharedMealsLedger()
    }

    // MARK: - Workout Schedule Ledger Sync (Grow <-> GrowTasks for Past & Future)
    @discardableResult
    public func saveWorkoutScheduleLedger(_ payload: SharedWorkoutScheduleLedger) -> Bool {
        guard let data = try? JSONEncoder().encode(payload) else { return false }
        writeKeychain(data: data, accountKey: workoutScheduleAccountKey)
        writeCache(data: data, filename: "shared_workout_schedule.json")
        writePasteboard(data: data, pasteboardName: pasteboardWorkoutScheduleName)
        DarwinNotificationCenter.post(DarwinNotificationCenter.workoutScheduleLedgerUpdated)
        return true
    }

    public func loadWorkoutScheduleLedger() -> SharedWorkoutScheduleLedger {
        if let data = readKeychain(accountKey: workoutScheduleAccountKey),
           let p = try? JSONDecoder().decode(SharedWorkoutScheduleLedger.self, from: data) {
            return p
        } else if let data = readCache(filename: "shared_workout_schedule.json"),
                  let p = try? JSONDecoder().decode(SharedWorkoutScheduleLedger.self, from: data) {
            return p
        } else if let data = readPasteboard(pasteboardName: pasteboardWorkoutScheduleName),
                  let p = try? JSONDecoder().decode(SharedWorkoutScheduleLedger.self, from: data) {
            return p
        }
        return SharedWorkoutScheduleLedger()
    }

    // MARK: - Supplement Schedule Ledger Sync (Growcery <-> GrowTasks for Past & Future)
    @discardableResult
    public func saveSupplementScheduleLedger(_ payload: SharedSupplementScheduleLedger) -> Bool {
        guard let data = try? JSONEncoder().encode(payload) else { return false }
        writeKeychain(data: data, accountKey: supplementScheduleAccountKey)
        writeCache(data: data, filename: "shared_supplement_schedule.json")
        writePasteboard(data: data, pasteboardName: pasteboardSupplementScheduleName)
        DarwinNotificationCenter.post(DarwinNotificationCenter.supplementScheduleLedgerUpdated)
        return true
    }

    public func loadSupplementScheduleLedger() -> SharedSupplementScheduleLedger {
        if let data = readKeychain(accountKey: supplementScheduleAccountKey),
           let p = try? JSONDecoder().decode(SharedSupplementScheduleLedger.self, from: data) {
            return p
        } else if let data = readCache(filename: "shared_supplement_schedule.json"),
                  let p = try? JSONDecoder().decode(SharedSupplementScheduleLedger.self, from: data) {
            return p
        } else if let data = readPasteboard(pasteboardName: pasteboardSupplementScheduleName),
                  let p = try? JSONDecoder().decode(SharedSupplementScheduleLedger.self, from: data) {
            return p
        }
        return SharedSupplementScheduleLedger()
    }

    public func markSupplement(doseId: String, isTaken: Bool, date: Date = Date()) {
        var current = loadSupplements(for: date)
        if isTaken {
            current.takenDoseIds[doseId] = Date()
        } else {
            current.takenDoseIds.removeValue(forKey: doseId)
        }
        current.lastUpdated = Date()
        saveSupplements(current)
    }

    public func isSupplementTaken(doseId: String, date: Date = Date()) -> Bool {
        let payload = loadSupplements(for: date)
        return payload.takenDoseIds[doseId] != nil
    }

    public func canTakeSupplement(doseId: String, date: Date = Date()) -> (permitted: Bool, reason: String?) {
        let payload = loadSupplements(for: date)
        if let takenAt = payload.takenDoseIds[doseId] {
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm"
            let timeStr = timeFormatter.string(from: takenAt)
            return (false, "Anti-Doppelgabe-Sperre aktiv: Bereits heute um \(timeStr) Uhr eingenommen.")
        }
        return (true, nil)
    }

    // MARK: - Water & Hydration Realtime Sync (Grow <-> Growcery <-> GrowStudy)
    @discardableResult
    public func saveWater(_ payload: SharedWaterPayload) -> Bool {
        guard let data = try? JSONEncoder().encode(payload) else { return false }
        writeKeychain(data: data, accountKey: waterAccountKey)
        writeCache(data: data, filename: "shared_water.json")
        GrowMMKV.shared.set(data, forKey: "shared_water")
        GrowDarwinEventBus.shared.post(.waterIntakeUpdated)
        DarwinNotificationCenter.post(DarwinNotificationCenter.waterUpdated)
        return true
    }

    public func loadWater(for date: Date = Date()) -> SharedWaterPayload {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd"
        let todayStr = formatter.string(from: date)

        // 1. Zero-Copy POSIX mmap check (< 1 us)
        if let data = GrowMMKV.shared.data(forKey: "shared_water"),
           let p = try? JSONDecoder().decode(SharedWaterPayload.self, from: data),
           p.dateString == todayStr {
            return p
        }

        var payload: SharedWaterPayload?
        if let data = readKeychain(accountKey: waterAccountKey),
           let p = try? JSONDecoder().decode(SharedWaterPayload.self, from: data) {
            payload = p
        } else if let data = readCache(filename: "shared_water.json"),
                  let p = try? JSONDecoder().decode(SharedWaterPayload.self, from: data) {
            payload = p
        }

        if let p = payload, p.dateString == todayStr {
            if let encoded = try? JSONEncoder().encode(p) {
                GrowMMKV.shared.set(encoded, forKey: "shared_water")
            }
            return p
        }
        let freshPayload = SharedWaterPayload(date: date, totalWaterMl: 0.0, targetWaterMl: 2500.0, entries: [], lastUpdated: Date())
        saveWater(freshPayload)
        return freshPayload
    }

    public func logWater(amountMl: Double, date: Date = Date(), sourceApp: String = "GrowStudy") {
        var current = loadWater(for: date)
        let entry = SharedWaterEntry(amountMl: amountMl, timestamp: Date(), sourceApp: sourceApp)
        current.entries.append(entry)
        current.totalWaterMl = max(0.0, current.entries.reduce(0.0) { $0 + $1.amountMl })
        current.lastUpdated = Date()
        saveWater(current)
    }

    public func setTotalWater(totalMl: Double, date: Date = Date(), sourceApp: String = "GrowStudy") {
        var current = loadWater(for: date)
        if abs(current.totalWaterMl - totalMl) < 0.5 { return }
        current.totalWaterMl = max(0.0, totalMl)
        let entry = SharedWaterEntry(amountMl: totalMl, timestamp: Date(), sourceApp: sourceApp)
        current.entries = [entry]
        current.lastUpdated = Date()
        saveWater(current)
    }

    public func resetWater(date: Date = Date(), sourceApp: String = "GrowStudy") {
        var current = loadWater(for: date)
        current.totalWaterMl = 0.0
        current.entries = []
        current.lastUpdated = Date()
        saveWater(current)
    }

    // MARK: - Finance & Governance Cross-App Sync
    @discardableResult
    public func saveFinance(_ payload: SharedFinancePayload) -> Bool {
        guard let data = try? JSONEncoder().encode(payload) else { return false }
        writeKeychain(data: data, accountKey: financeAccountKey)
        writeCache(data: data, filename: "shared_finance.json")
        GrowMMKV.shared.set(data, forKey: "shared_finance")
        GrowDarwinEventBus.shared.post(.financeLedgerUpdated)
        DarwinNotificationCenter.post(DarwinNotificationCenter.financeUpdated)
        return true
    }

    public func loadFinance(for date: Date = Date()) -> SharedFinancePayload {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayStr = formatter.string(from: date)

        // 1. Zero-Copy POSIX mmap check (< 1 us)
        if let data = GrowMMKV.shared.data(forKey: "shared_finance"),
           let p = try? JSONDecoder().decode(SharedFinancePayload.self, from: data),
           p.dateString == todayStr {
            return p
        }

        var payload: SharedFinancePayload?
        if let data = readKeychain(accountKey: financeAccountKey),
           let p = try? JSONDecoder().decode(SharedFinancePayload.self, from: data) {
            payload = p
        } else if let data = readCache(filename: "shared_finance.json"),
                  let p = try? JSONDecoder().decode(SharedFinancePayload.self, from: data) {
            payload = p
        }

        if let p = payload, p.dateString == todayStr {
            if let encoded = try? JSONEncoder().encode(p) {
                GrowMMKV.shared.set(encoded, forKey: "shared_finance")
            }
            return p
        }
        return SharedFinancePayload(date: date)
    }

    // MARK: - Resilient Transport Channels
    private func writeKeychain(data: Data, accountKey: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceKey,
            kSecAttrAccount as String: accountKey,
            kSecAttrAccessGroup as String: accessGroup
        ]
        SecItemDelete(query as CFDictionary)

        var addQuery = query
        addQuery[kSecValueData as String] = data
        addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        let status = SecItemAdd(addQuery as CFDictionary, nil)

        if status != errSecSuccess {
            var localQuery = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: serviceKey,
                kSecAttrAccount as String: accountKey
            ] as [String: Any]
            SecItemDelete(localQuery as CFDictionary)
            localQuery[kSecValueData as String] = data
            localQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
            SecItemAdd(localQuery as CFDictionary, nil)
        }
    }

    private func readKeychain(accountKey: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceKey,
            kSecAttrAccount as String: accountKey,
            kSecAttrAccessGroup as String: accessGroup,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecSuccess, let data = result as? Data {
            return data
        }

        let localQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceKey,
            kSecAttrAccount as String: accountKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var localResult: AnyObject?
        if SecItemCopyMatching(localQuery as CFDictionary, &localResult) == errSecSuccess,
           let localData = localResult as? Data {
            return localData
        }
        return nil
    }

    private var sharedContainerURL: URL {
        if let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.nkembi.somagym") {
            try? FileManager.default.createDirectory(at: groupURL, withIntermediateDirectories: true)
            return groupURL
        }
        let paths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        return paths.first ?? FileManager.default.temporaryDirectory
    }

    private func writeCache(data: Data, filename: String) {
        let fileURL = sharedContainerURL.appendingPathComponent(filename)
        try? data.write(to: fileURL, options: .atomic)
    }

    private func readCache(filename: String) -> Data? {
        let fileURL = sharedContainerURL.appendingPathComponent(filename)
        if FileManager.default.fileExists(atPath: fileURL.path) {
            return try? Data(contentsOf: fileURL)
        }
        if let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
            let legacyURL = cacheDir.appendingPathComponent(filename)
            return try? Data(contentsOf: legacyURL)
        }
        return nil
    }

    private func writePasteboard(data: Data, pasteboardName: String) {
        // Zero-Muda: UIPasteboard is bypassed to eliminate clipboard pollution and IPC race conditions
    }

    private func readPasteboard(pasteboardName: String) -> Data? {
        // Zero-Muda: UIPasteboard is bypassed
        return nil
    }

    // MARK: - 5.5 Field Notes Sync (Heat-of-the-Moment Scratchpad)
    @discardableResult
    public func saveFieldNote(text: String, authorApp: String, category: String = "ALLGEMEIN") -> FieldNoteEntry? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        var currentPayload = loadFieldNotesPayload() ?? FieldNotesPayload()
        let newEntry = FieldNoteEntry(authorApp: authorApp, text: trimmed, category: category)
        currentPayload.notes.insert(newEntry, at: 0)
        if currentPayload.notes.count > 200 {
            currentPayload.notes = Array(currentPayload.notes.prefix(200))
        }
        currentPayload.lastUpdated = Date()

        guard let data = try? JSONEncoder().encode(currentPayload) else { return nil }
        writeKeychain(data: data, accountKey: fieldNotesAccountKey)
        writeCache(data: data, filename: "heat_of_the_moment_notes.json")
        writeDocument(data: data, filename: "heat_of_the_moment_notes.json")
        writePasteboard(data: data, pasteboardName: pasteboardFieldNotesName)
        DarwinNotificationCenter.post(DarwinNotificationCenter.fieldNotesUpdated)
        return newEntry
    }

    public func loadFieldNotes() -> [FieldNoteEntry] {
        return loadFieldNotesPayload()?.notes ?? []
    }

    public func loadFieldNotesPayload() -> FieldNotesPayload? {
        if let data = readKeychain(accountKey: fieldNotesAccountKey),
           let payload = try? JSONDecoder().decode(FieldNotesPayload.self, from: data) {
            return payload
        }
        if let data = readDocument(filename: "heat_of_the_moment_notes.json"),
           let payload = try? JSONDecoder().decode(FieldNotesPayload.self, from: data) {
            return payload
        }
        if let data = readCache(filename: "heat_of_the_moment_notes.json"),
           let payload = try? JSONDecoder().decode(FieldNotesPayload.self, from: data) {
            return payload
        }
        if let data = readPasteboard(pasteboardName: pasteboardFieldNotesName),
           let payload = try? JSONDecoder().decode(FieldNotesPayload.self, from: data) {
            return payload
        }
        return nil
    }

    private func writeDocument(data: Data, filename: String) {
        if let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = docs.appendingPathComponent(filename)
            try? data.write(to: fileURL, options: .atomic)
        }
    }

    private func readDocument(filename: String) -> Data? {
        if let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = docs.appendingPathComponent(filename)
            return try? Data(contentsOf: fileURL)
        }
        return nil
    }
}

// Backwards-compatible alias for existing callers
public typealias SharedMacrosBridge = GrowSuiteBridge

// MARK: - 6. Failure & Logic Violation Telemetry Engine
public enum TelemetrySeverity: String, Codable {
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
    case logicViolation = "LOGIC_VIOLATION"
}

public enum TelemetryCategory: String, Codable {
    case network = "NETWORK"
    case syncBridge = "SYNC_BRIDGE"
    case uiInteraction = "UI_INTERACTION"
    case nutritionExcess = "NUTRITION_EXCESS"
    case refluxHazard = "REFLUX_HAZARD"
    case financialLeak = "FINANCIAL_LEAK"
    case athleticStrain = "ATHLETIC_STRAIN"
    case dataIntegrity = "DATA_INTEGRITY"
}

public struct TelemetryEvent: Identifiable, Codable {
    public let id: UUID
    public let timestamp: Date
    public let appName: String
    public let severity: TelemetrySeverity
    public let category: TelemetryCategory
    public let title: String
    public let detail: String
    public let metadata: [String: String]

    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        appName: String,
        severity: TelemetrySeverity,
        category: TelemetryCategory,
        title: String,
        detail: String,
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.timestamp = timestamp
        self.appName = appName
        self.severity = severity
        self.category = category
        self.title = title
        self.detail = detail
        self.metadata = metadata
    }
}

public final class GrowTelemetryService {
    public static let shared = GrowTelemetryService()

    private let queue = DispatchQueue(label: "com.nkembi.growsuite.telemetry", qos: .utility)
    private var inMemoryEvents: [TelemetryEvent] = []
    private let maxEvents = 500

    private var telemetryURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("audit_telemetry.json")
    }

    private init() {
        loadEvents()
    }

    public func log(
        appName: String,
        severity: TelemetrySeverity,
        category: TelemetryCategory,
        title: String,
        detail: String,
        metadata: [String: String] = [:]
    ) {
        let event = TelemetryEvent(
            appName: appName,
            severity: severity,
            category: category,
            title: title,
            detail: detail,
            metadata: metadata
        )
        queue.async {
            self.inMemoryEvents.append(event)
            if self.inMemoryEvents.count > self.maxEvents {
                self.inMemoryEvents.removeFirst(self.inMemoryEvents.count - self.maxEvents)
            }
            self.persistEvents()
        }
    }

    public func logTaskFailure(appName: String, category: TelemetryCategory, title: String, error: Error?, metadata: [String: String] = [:]) {
        var meta = metadata
        if let err = error {
            meta["error_description"] = err.localizedDescription
        }
        log(appName: appName, severity: .error, category: category, title: title, detail: error?.localizedDescription ?? "Task execution failed", metadata: meta)
    }

    public func logLogicViolation(appName: String, category: TelemetryCategory, title: String, detail: String, metadata: [String: String] = [:]) {
        log(appName: appName, severity: .logicViolation, category: category, title: title, detail: detail, metadata: metadata)
    }

    public func getEvents() -> [TelemetryEvent] {
        return queue.sync { inMemoryEvents }
    }

    private func loadEvents() {
        queue.async {
            guard FileManager.default.fileExists(atPath: self.telemetryURL.path),
                  let data = try? Data(contentsOf: self.telemetryURL),
                  let events = try? JSONDecoder().decode([TelemetryEvent].self, from: data) else {
                return
            }
            self.inMemoryEvents = events
        }
    }

    private func persistEvents() {
        guard let data = try? JSONEncoder().encode(self.inMemoryEvents) else { return }
        try? data.write(to: self.telemetryURL, options: .atomic)
    }
}

// MARK: - 7. Cross-App Heat-of-the-Moment Scratchpad UI
public struct FieldScratchpadCard: View {
    public let currentApp: String

    @State private var noteText: String = ""
    @State private var selectedCategory: String = "ALLGEMEIN"
    @State private var notesList: [FieldNoteEntry] = []
    @State private var isExpanded: Bool = false

    private let categories = ["ALLGEMEIN", "BUG", "ENGINE", "LOGIK", "IDEE"]

    public init(currentApp: String) {
        self.currentApp = currentApp
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("HEAT-OF-THE-MOMENT FIELD NOTES")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.gray)
                        Text("App-uebergreifendes Notiz- & Audit-Radar")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    Spacer()

                    Text("\(notesList.count) NOTIZEN")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(4)
                        .foregroundColor(.cyan)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.gray)
                }
            }
            .buttonStyle(.plain)

            VStack(spacing: 8) {
                HStack(spacing: 6) {
                    ForEach(categories, id: \.self) { cat in
                        Button(action: {
                            selectedCategory = cat
                        }) {
                            Text(cat)
                                .font(.system(size: 9, weight: selectedCategory == cat ? .bold : .medium, design: .monospaced))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 4)
                                .background(selectedCategory == cat ? Color.cyan.opacity(0.2) : Color.white.opacity(0.05))
                                .foregroundColor(selectedCategory == cat ? .cyan : .gray)
                                .cornerRadius(4)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(selectedCategory == cat ? Color.cyan : Color.white.opacity(0.1), lineWidth: 1)
                                )
                        }
                    }
                }

                HStack(alignment: .top, spacing: 8) {
                    TextField("Spontane Beobachtung, Fehler oder Kritik eingeben...", text: $noteText, axis: .vertical)
                        .lineLimit(2...4)
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.white.opacity(0.04))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )

                    Button(action: commitNote) {
                        VStack(spacing: 2) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 18))
                            Text("SEND")
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                        }
                        .foregroundColor(noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .cyan)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(6)
                    }
                    .disabled(noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }

            if isExpanded {
                Divider().background(Color.white.opacity(0.1))

                if notesList.isEmpty {
                    Text("Keine Notizen erfasst. Eintraege werden sofort zwischen Grow, Growcery und GrowFinance synchronisiert.")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                        .padding(.vertical, 4)
                } else {
                    VStack(spacing: 8) {
                        ForEach(notesList.prefix(6)) { note in
                            VStack(alignment: .leading, spacing: 3) {
                                HStack {
                                    Text("[\(note.authorApp.uppercased())]")
                                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                                        .foregroundColor(appColor(note.authorApp))

                                    Text(note.category)
                                        .font(.system(size: 8, weight: .semibold, design: .monospaced))
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 1)
                                        .background(Color.white.opacity(0.08))
                                        .cornerRadius(3)
                                        .foregroundColor(.white)

                                    Spacer()

                                    Text(formatDate(note.timestamp))
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundColor(.gray)
                                }

                                Text(note.text)
                                    .font(.system(size: 12))
                                    .foregroundColor(.white)
                            }
                            .padding(8)
                            .background(Color.white.opacity(0.03))
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
                            )
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(Color(red: 0.08, green: 0.09, blue: 0.11))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .onAppear {
            refreshNotes()
            DarwinNotificationCenter.observe(DarwinNotificationCenter.fieldNotesUpdated) {
                refreshNotes()
            }
        }
    }

    private func commitNote() {
        let text = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        GrowSuiteBridge.shared.saveFieldNote(text: text, authorApp: currentApp, category: selectedCategory)
        noteText = ""
        refreshNotes()
    }

    private func refreshNotes() {
        notesList = GrowSuiteBridge.shared.loadFieldNotes()
    }

    private func appColor(_ app: String) -> Color {
        switch app.lowercased() {
        case "grow", "gymapp": return .green
        case "growcery", "nutrivault": return .orange
        case "growfinance": return .cyan
        default: return .purple
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM HH:mm"
        return formatter.string(from: date)
    }
}
