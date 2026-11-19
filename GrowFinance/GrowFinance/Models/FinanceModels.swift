import Foundation
import SwiftUI

public enum TransactionCategory: String, CaseIterable, Codable, Identifiable {
    case besoldung = "Besoldung / Gehalt"
    case debtServicing = "Schuldentilgung (Targobank)"
    case fixedContracts = "Fixkosten (Telekom/Versicherung)"
    case groceries = "Lebensmittel (Supermarkt)"
    case deliveryLeak = "Lieferando & Fast Food"
    case mobility = "Mobilitaet (Bahn/Taxi/Sprit)"
    case discretionary = "Konsum & Anschaffungen"
    case bankFees = "Bankgebuehren & Dispo"
    case incomeOther = "Sonstige Gutschriften"
    case internalTransfer = "Umbuchung / Transfer"
    case other = "Sonstiges"

    // Aliases for convenience
    public static let debtRepayment = TransactionCategory.debtServicing
    public static let groceriesCooking = TransactionCategory.groceries
    public static let fastFoodDelivery = TransactionCategory.deliveryLeak
    public static let taxiTransport = TransactionCategory.mobility
    public static let telecomContracts = TransactionCategory.fixedContracts
    public static let investmentsEducation = TransactionCategory.discretionary
    public static let entertainmentGaming = TransactionCategory.discretionary

    public var id: String { rawValue }
    public var displayName: String { rawValue }

    public var isLeak: Bool {
        switch self {
        case .deliveryLeak, .bankFees:
            return true
        default:
            return false
        }
    }

    public var color: Color {
        switch self {
        case .besoldung, .incomeOther:
            return FinanceTheme.sageGreen
        case .debtServicing:
            return FinanceTheme.strongBlue
        case .fixedContracts:
            return Color.purple
        case .groceries:
            return FinanceTheme.warmSand
        case .deliveryLeak, .bankFees:
            return FinanceTheme.terracotta
        case .mobility:
            return Color.cyan
        case .discretionary:
            return Color.indigo
        case .internalTransfer:
            return Color.gray
        case .other:
            return FinanceTheme.textMuted
        }
    }

    public var icon: String {
        switch self {
        case .besoldung, .incomeOther: return "arrow.down.left.circle.fill"
        case .debtServicing: return "banknote.fill"
        case .fixedContracts: return "doc.text.fill"
        case .groceries: return "cart.fill"
        case .deliveryLeak: return "fork.knife.circle.fill"
        case .mobility: return "tram.fill"
        case .discretionary: return "bag.fill"
        case .bankFees: return "exclamationmark.triangle.fill"
        case .internalTransfer: return "arrow.left.arrow.right.circle.fill"
        case .other: return "list.bullet"
        }
    }

    public var iconName: String { icon }
}

public enum DateFilterPreset: String, CaseIterable, Codable, Identifiable {
    case all = "Alle Zeiten"
    case thisMonth = "Dieser Monat"
    case lastMonth = "Letzter Monat"
    case last30Days = "Letzte 30 Tage"
    case last90Days = "Letzte 90 Tage"
    case thisYear = "Dieses Jahr"
    case custom = "Datumsbereich..."

    public var id: String { rawValue }
    
    public var icon: String {
        switch self {
        case .all: return "calendar"
        case .thisMonth: return "calendar.badge.clock"
        case .lastMonth: return "clock.arrow.circlepath"
        case .last30Days: return "calendar.day.timeline.left"
        case .last90Days: return "chart.bar.xaxis"
        case .thisYear: return "calendar.badge.exclamationmark"
        case .custom: return "slider.horizontal.2.square"
        }
    }
}

// MARK: - Account Types (Banken, Kreditkarten, Bargeld, Andere/Brokerage, Urlaub)
public enum AccountType: String, CaseIterable, Codable, Identifiable {
    case checking = "Girokonto"
    case dailySavings = "Tagesgeldkonto"
    case emergencyFund = "Notfallfonds"
    case savingsGoal = "Sparziel"
    case custody = "Depot"
    case loan = "Kredit / Finanzierung"
    case creditCard = "Kreditkarte"
    case bank = "Bankkonto"
    case cash = "Bargeld"
    case other = "Andere (Brokerage)"
    case vacation = "Urlaubskonto"

    public var id: String { rawValue }
    
    public var groupName: String {
        switch self {
        case .creditCard:
            return "Kreditkarten"
        case .checking, .bank, .dailySavings, .emergencyFund, .savingsGoal:
            return "Banken"
        case .cash:
            return "Bargeld"
        case .custody, .other:
            return "Andere (Brokerage)"
        case .vacation:
            return "Urlaub"
        case .loan:
            return "Verbindlichkeiten"
        }
    }

    public var icon: String {
        switch self {
        case .checking, .bank: return "building.columns.fill"
        case .creditCard: return "creditcard.fill"
        case .cash: return "banknote.fill"
        case .custody, .other: return "chart.line.uptrend.xyaxis"
        case .vacation: return "airplane.departure"
        case .dailySavings: return "archivebox.fill"
        case .emergencyFund: return "shield.lefthalf.filled"
        case .savingsGoal: return "target"
        case .loan: return "exclamationmark.triangle.fill"
        }
    }
}

// MARK: - Account Sub-Allocation / Sparziel
public struct AccountSubAllocation: Identifiable, Codable, Hashable {
    public var id: String
    public var name: String
    public var allocatedAmount: Double
    public var targetAmount: Double
    public var icon: String
    public var notes: String

    public var progressFraction: Double {
        guard targetAmount > 0 else { return 0 }
        return min(1.0, max(0.0, allocatedAmount / targetAmount))
    }

    public var remainingAmount: Double {
        max(0.0, targetAmount - allocatedAmount)
    }

    public var formattedAllocated: String {
        String(format: "%.2f €", allocatedAmount)
    }

    public var formattedTarget: String {
        String(format: "%.2f €", targetAmount)
    }

    public init(
        id: String = UUID().uuidString,
        name: String,
        allocatedAmount: Double = 0.0,
        targetAmount: Double = 0.0,
        icon: String = "target",
        notes: String = ""
    ) {
        self.id = id
        self.name = name
        self.allocatedAmount = allocatedAmount
        self.targetAmount = targetAmount
        self.icon = icon
        self.notes = notes
    }
}

public struct BankAccount: Identifiable, Codable, Hashable {
    public let id: String
    public var accountNumber: String
    public var name: String
    public var type: AccountType
    public var balance: Double
    public var iban: String
    public var isMainAccount: Bool
    public var subAllocations: [AccountSubAllocation]

    public var totalAllocated: Double {
        subAllocations.reduce(0.0) { $0 + $1.allocatedAmount }
    }

    public var unallocatedBalance: Double {
        max(0.0, balance - totalAllocated)
    }

    public var displayName: String {
        accountNumber.isEmpty ? name : "\(accountNumber) \(name)"
    }
    
    public var formattedBalance: String {
        String(format: "%.2f €", balance)
    }

    public init(
        id: String = UUID().uuidString,
        accountNumber: String = "",
        name: String,
        type: AccountType,
        balance: Double = 0.0,
        iban: String = "",
        isMainAccount: Bool = false,
        subAllocations: [AccountSubAllocation] = []
    ) {
        self.id = id
        self.accountNumber = accountNumber
        self.name = name
        self.type = type
        self.balance = balance
        self.iban = iban
        self.isMainAccount = isMainAccount
        self.subAllocations = subAllocations
    }

    enum CodingKeys: String, CodingKey {
        case id, accountNumber, name, type, balance, iban, isMainAccount, subAllocations
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.accountNumber = try container.decodeIfPresent(String.self, forKey: .accountNumber) ?? ""
        self.name = try container.decode(String.self, forKey: .name)
        self.type = try container.decode(AccountType.self, forKey: .type)
        self.balance = try container.decode(Double.self, forKey: .balance)
        self.iban = try container.decodeIfPresent(String.self, forKey: .iban) ?? ""
        self.isMainAccount = try container.decodeIfPresent(Bool.self, forKey: .isMainAccount) ?? false
        self.subAllocations = try container.decodeIfPresent([AccountSubAllocation].self, forKey: .subAllocations) ?? []
    }
}

// MARK: - Dedicated Budgets System (9 Requested Categories)
public enum BudgetCategory: String, CaseIterable, Codable, Identifiable {
    case essen = "Essen"
    case gesundheit = "Gesundheit"
    case getraenke = "Getränke"
    case kleidung = "Kleidung"
    case nebenkosten = "Nebenkosten"
    case privat = "Privat"
    case transport = "Transport"
    case unterhaltung = "Unterhaltung"
    case wohnkosten = "Wohnkosten"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .essen: return "fork.knife"
        case .gesundheit: return "cross.case.fill"
        case .getraenke: return "cup.and.saucer.fill"
        case .kleidung: return "tshirt.fill"
        case .nebenkosten: return "bolt.fill"
        case .privat: return "person.crop.circle.fill"
        case .transport: return "car.fill"
        case .unterhaltung: return "tv.fill"
        case .wohnkosten: return "house.fill"
        }
    }

    public var color: Color {
        switch self {
        case .essen: return FinanceTheme.warmSand
        case .gesundheit: return FinanceTheme.sageGreen
        case .getraenke: return Color.cyan
        case .kleidung: return Color.indigo
        case .nebenkosten: return Color.mint
        case .privat: return Color.purple
        case .transport: return FinanceTheme.strongBlue
        case .unterhaltung: return Color.pink
        case .wohnkosten: return Color.teal
        }
    }

    public var defaultMonthlyLimit: Double {
        switch self {
        case .essen: return 350.00
        case .gesundheit: return 120.00
        case .getraenke: return 50.00
        case .kleidung: return 80.00
        case .nebenkosten: return 160.00
        case .privat: return 100.00
        case .transport: return 120.00
        case .unterhaltung: return 60.00
        case .wohnkosten: return 450.00
        }
    }
}

public struct CategoryBudget: Identifiable, Codable {
    public var id: String
    public var category: BudgetCategory
    public var monthlyLimit: Double

    public init(id: String = UUID().uuidString, category: BudgetCategory, monthlyLimit: Double) {
        self.id = id
        self.category = category
        self.monthlyLimit = monthlyLimit
    }
}

// MARK: - Mathematical Hierarchy of Needs & Dynamic Allocation
public enum FinancialNeedTier: Int, CaseIterable, Codable {
    case tier0_survivalFixed = 0     // Fixkosten + 100 EUR Dispo-Schutzlinie
    case tier1_necessaryNutrition = 1 // Gesunde Basis-Ernaehrung (160g Protein, Ballaststoffe, 7.50 - 9.50 EUR/Tag)
    case tier2_debtServicing = 2      // 274,70 EUR Rate + 1.000 EUR Avalanche Sondertilgung (Ziel: Juni 2027)
    case tier3_emergencyReserve = 3   // 500 - 1.500 EUR Notfallfonds
    case tier4_activeMilestones = 4   // B-Fuehrerschein, Bildung/Matura
    case tier5_elasticDiscretionary = 5 // Urlaub, Unterhaltung, Freizeit (Elastisch & Swept)
    
    public var title: String {
        switch self {
        case .tier0_survivalFixed: return "Stufe 0: Existenz & Fixkosten"
        case .tier1_necessaryNutrition: return "Stufe 1: Notwendige Ernaehrung"
        case .tier2_debtServicing: return "Stufe 2: Avalanche-Tilgung"
        case .tier3_emergencyReserve: return "Stufe 3: Notfallreserve"
        case .tier4_activeMilestones: return "Stufe 4: Aktive Meilensteine"
        case .tier5_elasticDiscretionary: return "Stufe 5: Urlaub & Freizeit (Elastisch)"
        }
    }
    
    public var icon: String {
        switch self {
        case .tier0_survivalFixed: return "shield.fill"
        case .tier1_necessaryNutrition: return "fork.knife"
        case .tier2_debtServicing: return "flame.fill"
        case .tier3_emergencyReserve: return "cross.case.fill"
        case .tier4_activeMilestones: return "graduationcap.fill"
        case .tier5_elasticDiscretionary: return "airplane.departure"
        }
    }
}

public struct HierarchyTierStatus: Identifiable, Codable {
    public var id: Int { tier.rawValue }
    public let tier: FinancialNeedTier
    public let requiredAmount: Double
    public let fundedAmount: Double
    public let isFullyFunded: Bool
    public let statusMessage: String
    
    public init(
        tier: FinancialNeedTier,
        requiredAmount: Double,
        fundedAmount: Double,
        isFullyFunded: Bool,
        statusMessage: String
    ) {
        self.tier = tier
        self.requiredAmount = requiredAmount
        self.fundedAmount = fundedAmount
        self.isFullyFunded = isFullyFunded
        self.statusMessage = statusMessage
    }
}

public struct AccountAllocationDirective: Identifiable, Codable {
    public let id: String
    public let sourceAccountName: String
    public let targetAccountName: String
    public let amount: Double
    public let rationale: String
    public let priority: Int
    
    public init(
        id: String = UUID().uuidString,
        sourceAccountName: String,
        targetAccountName: String,
        amount: Double,
        rationale: String,
        priority: Int
    ) {
        self.id = id
        self.sourceAccountName = sourceAccountName
        self.targetAccountName = targetAccountName
        self.amount = amount
        self.rationale = rationale
        self.priority = priority
    }
}

public struct HierarchyOfNeedsReport: Codable {
    public let tierStatuses: [HierarchyTierStatus]
    public let dynamicGroceryMonthlyLimit: Double
    public let dynamicGroceryDailyRate: Double
    public let dynamicDiscretionaryMonthlyLimit: Double
    public let dynamicVacationMonthlyLimit: Double
    public let allocationDirectives: [AccountAllocationDirective]
    public let daysRemainingUntilSalary: Int
    public let netAvailableCash: Double
    
    public init(
        tierStatuses: [HierarchyTierStatus] = [],
        dynamicGroceryMonthlyLimit: Double = 250.0,
        dynamicGroceryDailyRate: Double = 8.50,
        dynamicDiscretionaryMonthlyLimit: Double = 50.0,
        dynamicVacationMonthlyLimit: Double = 0.0,
        allocationDirectives: [AccountAllocationDirective] = [],
        daysRemainingUntilSalary: Int = 30,
        netAvailableCash: Double = 0.0
    ) {
        self.tierStatuses = tierStatuses
        self.dynamicGroceryMonthlyLimit = dynamicGroceryMonthlyLimit
        self.dynamicGroceryDailyRate = dynamicGroceryDailyRate
        self.dynamicDiscretionaryMonthlyLimit = dynamicDiscretionaryMonthlyLimit
        self.dynamicVacationMonthlyLimit = dynamicVacationMonthlyLimit
        self.allocationDirectives = allocationDirectives
        self.daysRemainingUntilSalary = daysRemainingUntilSalary
        self.netAvailableCash = netAvailableCash
    }
}

// MARK: - Expense Necessity & Fixed Costs Engine
public enum ExpenseNecessity: String, CaseIterable, Codable {
    case necessary = "Notwendig"
    case unnecessary = "Unnötig"
    case neutral = "Neutral"

    public var color: Color {
        switch self {
        case .necessary: return FinanceTheme.sageGreen
        case .unnecessary: return FinanceTheme.terracotta
        case .neutral: return FinanceTheme.textTertiary
        }
    }
}

public enum FixedCostType: String, CaseIterable, Codable {
    case subscription = "Abonnement"
    case insurance = "Versicherung"
    case contract = "Vertrag"
    case housing = "Wohnen"
    case debtRate = "Kreditrate"
    case other = "Sonstiges"

    public var icon: String {
        switch self {
        case .subscription: return "repeat"
        case .insurance: return "shield.fill"
        case .contract: return "doc.text.fill"
        case .housing: return "house.fill"
        case .debtRate: return "banknote.fill"
        case .other: return "list.bullet"
        }
    }
}

public struct FinanceContractOrSubscription: Identifiable, Codable {
    public var id: String
    public var name: String
    public var type: FixedCostType
    public var monthlyAmount: Double
    public var billingCycle: String
    public var billingDayOfMonth: Int
    public var category: TransactionCategory
    public var budgetCategory: BudgetCategory
    public var necessity: ExpenseNecessity
    public var provider: String
    public var policyOrContractNumber: String
    public var isCancelled: Bool
    public var startDate: Date?
    public var notes: String

    public init(
        id: String = UUID().uuidString,
        name: String,
        type: FixedCostType,
        monthlyAmount: Double,
        billingCycle: String = "Monatlich",
        billingDayOfMonth: Int = 1,
        category: TransactionCategory = .fixedContracts,
        budgetCategory: BudgetCategory = .nebenkosten,
        necessity: ExpenseNecessity = .necessary,
        provider: String = "",
        policyOrContractNumber: String = "",
        isCancelled: Bool = false,
        startDate: Date? = nil,
        notes: String = ""
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.monthlyAmount = monthlyAmount
        self.billingCycle = billingCycle
        self.billingDayOfMonth = billingDayOfMonth
        self.category = category
        self.budgetCategory = budgetCategory
        self.necessity = necessity
        self.provider = provider
        self.policyOrContractNumber = policyOrContractNumber
        self.isCancelled = isCancelled
        self.startDate = startDate
        self.notes = notes
    }
}

// MARK: - User Profile, Income Sources & Savings Goals
public struct IncomeSource: Identifiable, Codable {
    public var id: String
    public var name: String
    public var monthlyAmount: Double
    public var recurrence: String
    public var isPrimary: Bool

    public init(
        id: String = UUID().uuidString,
        name: String,
        monthlyAmount: Double,
        recurrence: String = "Monatlich",
        isPrimary: Bool = false
    ) {
        self.id = id
        self.name = name
        self.monthlyAmount = monthlyAmount
        self.recurrence = recurrence
        self.isPrimary = isPrimary
    }
}

public struct SavingsGoal: Identifiable, Codable {
    public var id: String
    public var title: String
    public var targetAmount: Double
    public var currentAmount: Double
    public var deadline: Date?
    public var notes: String
    public var icon: String

    public var progressFraction: Double {
        guard targetAmount > 0 else { return 0 }
        return min(1.0, max(0.0, currentAmount / targetAmount))
    }

    public var remainingAmount: Double {
        max(0.0, targetAmount - currentAmount)
    }

    public init(
        id: String = UUID().uuidString,
        title: String,
        targetAmount: Double,
        currentAmount: Double = 0.0,
        deadline: Date? = nil,
        notes: String = "",
        icon: String = "target"
    ) {
        self.id = id
        self.title = title
        self.targetAmount = targetAmount
        self.currentAmount = currentAmount
        self.deadline = deadline
        self.notes = notes
        self.icon = icon
    }
}

public struct UserProfile: Codable {
    public var fullName: String
    public var monthlyNetIncome: Double
    public var incomeSources: [IncomeSource]
    public var savingsGoals: [SavingsGoal]
    public var lastUpdated: Date

    public init(
        fullName: String = "Parris-Campbell Nkembi",
        monthlyNetIncome: Double = 2850.00,
        incomeSources: [IncomeSource] = [
            IncomeSource(name: "Bundeswehr Besoldung", monthlyAmount: 2850.00, recurrence: "Monatlich", isPrimary: true)
        ],
        savingsGoals: [SavingsGoal] = [
            SavingsGoal(title: "Notfallfonds (Emergency Fund)", targetAmount: 5000.00, currentAmount: 0.00, icon: "shield.lefthalf.filled"),
            SavingsGoal(title: "Targobank Entschuldung", targetAmount: 11481.97, currentAmount: 0.00, icon: "banknote.fill"),
            SavingsGoal(title: "B-Führerschein Reserve", targetAmount: 2500.00, currentAmount: 0.00, icon: "car.fill"),
            SavingsGoal(title: "Urlaub & Regeneration", targetAmount: 1500.00, currentAmount: 0.00, icon: "airplane.departure")
        ],
        lastUpdated: Date = Date()
    ) {
        self.fullName = fullName
        self.monthlyNetIncome = monthlyNetIncome
        self.incomeSources = incomeSources
        self.savingsGoals = savingsGoals
        self.lastUpdated = lastUpdated
    }
}

// MARK: - Bank Transaction with Tags, Necessity, Budget Mapping
public struct BankTransaction: Identifiable, Codable {
    public let id: String
    public let date: Date
    public let recipientOrPurpose: String
    public let amount: Double
    public var category: TransactionCategory
    public let accountIBAN: String
    public var rawBookingText: String
    public var isManual: Bool
    public let partnerName: String
    public var accountId: String?
    public var tags: [String]
    public var necessity: ExpenseNecessity
    public var budgetCategory: BudgetCategory?
    public var isInternalTransfer: Bool
    public var linkedTransferTransactionId: String?

    public var displayRecipient: String {
        partnerName.isEmpty ? recipientOrPurpose : partnerName
    }

    public var isDebit: Bool {
        amount < 0
    }

    public var purpose: String {
        recipientOrPurpose
    }

    public var iban: String {
        accountIBAN
    }

    public var formattedAmount: String {
        String(format: "%+.2f €", amount)
    }

    public func matchesDateQuery(_ q: String) -> Bool {
        let df1 = DateFormatter()
        df1.dateFormat = "dd.MM.yyyy"
        let s1 = df1.string(from: date).lowercased()
        
        let df2 = DateFormatter()
        df2.dateFormat = "dd.MM."
        let s2 = df2.string(from: date).lowercased()
        
        let df3 = DateFormatter()
        df3.dateFormat = "yyyy-MM-dd"
        let s3 = df3.string(from: date).lowercased()
        
        let df4 = DateFormatter()
        df4.locale = Locale(identifier: "de_DE")
        df4.dateFormat = "MMMM yyyy"
        let s4 = df4.string(from: date).lowercased()
        
        let df5 = DateFormatter()
        df5.locale = Locale(identifier: "de_DE")
        df5.dateFormat = "MMMM"
        let s5 = df5.string(from: date).lowercased()
        
        let df6 = DateFormatter()
        df6.dateFormat = "yyyy"
        let s6 = df6.string(from: date).lowercased()
        
        return s1.contains(q) || s2.contains(q) || s3.contains(q) || s4.contains(q) || s5.contains(q) || (q.count >= 4 && s6.contains(q))
    }

    public init(
        id: String = UUID().uuidString,
        date: Date,
        recipientOrPurpose: String,
        amount: Double,
        category: TransactionCategory,
        accountIBAN: String = "DE28300209003201649568",
        rawBookingText: String = "",
        isManual: Bool = false,
        partnerName: String? = nil,
        accountId: String? = nil,
        tags: [String] = [],
        necessity: ExpenseNecessity = .neutral,
        budgetCategory: BudgetCategory? = nil,
        isInternalTransfer: Bool = false,
        linkedTransferTransactionId: String? = nil
    ) {
        self.id = id
        self.date = date
        self.recipientOrPurpose = recipientOrPurpose
        self.amount = amount
        self.category = category
        self.accountIBAN = accountIBAN
        self.rawBookingText = rawBookingText
        self.isManual = isManual
        self.partnerName = partnerName ?? recipientOrPurpose
        self.accountId = accountId
        self.tags = tags
        self.necessity = necessity
        self.budgetCategory = budgetCategory
        self.isInternalTransfer = isInternalTransfer
        self.linkedTransferTransactionId = linkedTransferTransactionId
    }

    public init(
        date: Date,
        type: String,
        partnerName: String,
        purpose: String,
        amount: Double,
        iban: String,
        category: TransactionCategory,
        accountId: String? = nil,
        tags: [String] = [],
        necessity: ExpenseNecessity = .neutral,
        budgetCategory: BudgetCategory? = nil,
        isInternalTransfer: Bool = false,
        linkedTransferTransactionId: String? = nil
    ) {
        self.id = UUID().uuidString
        self.date = date
        self.recipientOrPurpose = purpose.isEmpty ? partnerName : "\(partnerName) - \(purpose)"
        self.amount = amount
        self.category = category
        self.accountIBAN = iban
        self.rawBookingText = "\(type) \(partnerName) \(purpose)"
        self.isManual = true
        self.partnerName = partnerName
        self.accountId = accountId
        self.tags = tags
        self.necessity = necessity
        self.budgetCategory = budgetCategory
        self.isInternalTransfer = isInternalTransfer
        self.linkedTransferTransactionId = linkedTransferTransactionId
    }

    // Custom Decodable to maintain backward compatibility with old transactions.json files
    enum CodingKeys: String, CodingKey {
        case id, date, recipientOrPurpose, amount, category, accountIBAN, rawBookingText, isManual, partnerName, accountId, tags, necessity, budgetCategory, isInternalTransfer, linkedTransferTransactionId
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.date = try container.decode(Date.self, forKey: .date)
        self.recipientOrPurpose = try container.decode(String.self, forKey: .recipientOrPurpose)
        self.amount = try container.decode(Double.self, forKey: .amount)
        self.category = try container.decode(TransactionCategory.self, forKey: .category)
        self.accountIBAN = try container.decodeIfPresent(String.self, forKey: .accountIBAN) ?? ""
        self.rawBookingText = try container.decodeIfPresent(String.self, forKey: .rawBookingText) ?? ""
        self.isManual = try container.decodeIfPresent(Bool.self, forKey: .isManual) ?? false
        self.partnerName = try container.decodeIfPresent(String.self, forKey: .partnerName) ?? recipientOrPurpose
        self.accountId = try container.decodeIfPresent(String.self, forKey: .accountId)
        self.tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        self.necessity = try container.decodeIfPresent(ExpenseNecessity.self, forKey: .necessity) ?? .neutral
        self.budgetCategory = try container.decodeIfPresent(BudgetCategory.self, forKey: .budgetCategory)
        self.isInternalTransfer = try container.decodeIfPresent(Bool.self, forKey: .isInternalTransfer) ?? false
        self.linkedTransferTransactionId = try container.decodeIfPresent(String.self, forKey: .linkedTransferTransactionId)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(date, forKey: .date)
        try container.encode(recipientOrPurpose, forKey: .recipientOrPurpose)
        try container.encode(amount, forKey: .amount)
        try container.encode(category, forKey: .category)
        try container.encode(accountIBAN, forKey: .accountIBAN)
        try container.encode(rawBookingText, forKey: .rawBookingText)
        try container.encode(isManual, forKey: .isManual)
        try container.encode(partnerName, forKey: .partnerName)
        try container.encodeIfPresent(accountId, forKey: .accountId)
        try container.encode(tags, forKey: .tags)
        try container.encode(necessity, forKey: .necessity)
        try container.encodeIfPresent(budgetCategory, forKey: .budgetCategory)
        try container.encode(isInternalTransfer, forKey: .isInternalTransfer)
        try container.encodeIfPresent(linkedTransferTransactionId, forKey: .linkedTransferTransactionId)
    }
}

// MARK: - Rule 6: 5-Gate Purchase Clearance Verdict
public enum FiveGateVerdict: String, Codable {
    case approved = "Freigegeben"
    case blocked = "Blockiert"
    case quarantine72h = "72h-Quarantaene"

    public static let cleared = FiveGateVerdict.approved
    public static let quarantine = FiveGateVerdict.quarantine72h

    public var displayName: String { rawValue }

    public var color: Color {
        switch self {
        case .approved: return FinanceTheme.sageGreen
        case .blocked: return FinanceTheme.terracotta
        case .quarantine72h: return FinanceTheme.warmSand
        }
    }
}

public struct GateStatus: Identifiable, Codable {
    public var id: Int
    public let title: String
    public let passed: Bool
    public let detail: String
    public let mathematicalFact: String

    public init(id: Int, title: String, passed: Bool, detail: String = "", mathematicalFact: String = "") {
        self.id = id
        self.title = title
        self.passed = passed
        self.detail = detail
        self.mathematicalFact = mathematicalFact
    }
}

public struct FiveGateCheckResult: Identifiable, Codable {
    public let id: String
    public let itemName: String
    public let price: Double
    public let date: Date
    public let verdict: FiveGateVerdict
    public let gates: [GateStatus]
    public let rationale: String
    public let gate1Passed: Bool
    public let gate2Passed: Bool
    public let gate3Passed: Bool
    public let gate4Passed: Bool
    public let requires72hQuarantine: Bool
    public let potentialDispoCost: Double
    public let auditLogs: [String]
    
    // Empirical Behavioral Decision Engine Fields
    public let debtRepaymentDelayDays: Double
    public let opportunityCostEur: Double
    public let historicalPastSpendOnMerchant: Double
    public let historicalMerchantTransactionsCount: Int
    public let riskWindowWarning: String?

    public var reason: String { rationale }

    public init(
        id: String = UUID().uuidString,
        itemName: String = "",
        price: Double = 0,
        date: Date = Date(),
        verdict: FiveGateVerdict,
        gates: [GateStatus] = [],
        rationale: String = "",
        reason: String? = nil,
        gate1Passed: Bool = true,
        gate2Passed: Bool = true,
        gate3Passed: Bool = true,
        gate4Passed: Bool = true,
        requires72hQuarantine: Bool = false,
        potentialDispoCost: Double = 0,
        auditLogs: [String] = [],
        debtRepaymentDelayDays: Double = 0.0,
        opportunityCostEur: Double = 0.0,
        historicalPastSpendOnMerchant: Double = 0.0,
        historicalMerchantTransactionsCount: Int = 0,
        riskWindowWarning: String? = nil
    ) {
        self.id = id
        self.itemName = itemName
        self.price = price
        self.date = date
        self.verdict = verdict
        self.gates = gates
        self.rationale = reason ?? rationale
        self.gate1Passed = gate1Passed
        self.gate2Passed = gate2Passed
        self.gate3Passed = gate3Passed
        self.gate4Passed = gate4Passed
        self.requires72hQuarantine = requires72hQuarantine
        self.potentialDispoCost = potentialDispoCost
        self.auditLogs = auditLogs
        self.debtRepaymentDelayDays = debtRepaymentDelayDays
        self.opportunityCostEur = opportunityCostEur
        self.historicalPastSpendOnMerchant = historicalPastSpendOnMerchant
        self.historicalMerchantTransactionsCount = historicalMerchantTransactionsCount
        self.riskWindowWarning = riskWindowWarning
    }
}

// MARK: - Empirical Behavioral Profiles
public struct TemporalRiskProfile: Codable {
    public let isCurrentlyHighRisk: Bool
    public let riskDescription: String
    public let peakWeekday: String
    public let peakHourRange: String
    public let historicalLeakCount: Int
    public let historicalLeakVolumeEur: Double
    
    public init(
        isCurrentlyHighRisk: Bool = false,
        riskDescription: String = "",
        peakWeekday: String = "",
        peakHourRange: String = "",
        historicalLeakCount: Int = 0,
        historicalLeakVolumeEur: Double = 0.0
    ) {
        self.isCurrentlyHighRisk = isCurrentlyHighRisk
        self.riskDescription = riskDescription
        self.peakWeekday = peakWeekday
        self.peakHourRange = peakHourRange
        self.historicalLeakCount = historicalLeakCount
        self.historicalLeakVolumeEur = historicalLeakVolumeEur
    }
}

public struct PredictiveTrajectoryResult: Codable {
    public let projectedBalanceAtMonthEnd: Double
    public let isDispoCollisionProjected: Bool
    public let collisionDayOfMonth: Int?
    public let dailyBurnRateEur: Double
    public let recommendedAdjustedDailyAllowance: Double
    
    public init(
        projectedBalanceAtMonthEnd: Double,
        isDispoCollisionProjected: Bool,
        collisionDayOfMonth: Int? = nil,
        dailyBurnRateEur: Double,
        recommendedAdjustedDailyAllowance: Double
    ) {
        self.projectedBalanceAtMonthEnd = projectedBalanceAtMonthEnd
        self.isDispoCollisionProjected = isDispoCollisionProjected
        self.collisionDayOfMonth = collisionDayOfMonth
        self.dailyBurnRateEur = dailyBurnRateEur
        self.recommendedAdjustedDailyAllowance = recommendedAdjustedDailyAllowance
    }
}

// MARK: - 72h Anti-Leak Quarantine
public struct QuarantinedPurchase: Identifiable, Codable {
    public let id: String
    public let title: String
    public let amount: Double
    public let category: TransactionCategory
    public let quarantineStartDate: Date
    public let notes: String
    public var isCancelled: Bool
    public var isApprovedAfter72h: Bool

    public init(
        id: String = UUID().uuidString,
        title: String,
        amount: Double,
        category: TransactionCategory,
        quarantineStartDate: Date = Date(),
        notes: String = "",
        isCancelled: Bool = false,
        isApprovedAfter72h: Bool = false
    ) {
        self.id = id
        self.title = title
        self.amount = amount
        self.category = category
        self.quarantineStartDate = quarantineStartDate
        self.notes = notes
        self.isCancelled = isCancelled
        self.isApprovedAfter72h = isApprovedAfter72h
    }

    public var isResolved: Bool {
        isCancelled || isApprovedAfter72h
    }

    public var hoursRemaining: Double {
        let elapsedSeconds = Date().timeIntervalSince(quarantineStartDate)
        let totalRequiredSeconds: Double = 72.0 * 3600.0
        let remainingSeconds = max(0, totalRequiredSeconds - elapsedSeconds)
        return remainingSeconds / 3600.0
    }

    public var remainingTimeFormatted: String {
        let hrs = Int(hoursRemaining)
        let mins = Int((hoursRemaining - Double(hrs)) * 60)
        if hrs > 0 {
            return "\(hrs)h \(mins)m"
        } else {
            return "\(mins)m"
        }
    }
}

// MARK: - Monthly Summary
public struct MonthlyFinanceSummary: Codable {
    public let monthName: String
    public let totalIncome: Double
    public let totalExpenses: Double
    public let netCashflow: Double
    public let totalDebtRepaid: Double
    public let totalLeaksDetected: Double

    public init(
        monthName: String,
        totalIncome: Double,
        totalExpenses: Double,
        netCashflow: Double,
        totalDebtRepaid: Double,
        totalLeaksDetected: Double
    ) {
        self.monthName = monthName
        self.totalIncome = totalIncome
        self.totalExpenses = totalExpenses
        self.netCashflow = netCashflow
        self.totalDebtRepaid = totalDebtRepaid
        self.totalLeaksDetected = totalLeaksDetected
    }
}

// MARK: - Debt & Avalanche Repayment Status
public struct DebtStatus: Codable {
    public let initialPrincipal: Double
    public let totalPaidSoFar: Double
    public let remainingPrincipal: Double
    public let monthlyRate: Double
    public let monthlySondertilgung: Double
    public let projectedMonthsToFreedom: Int
    public let targetFreedomDate: Date

    public var totalMonthlyDebtServicing: Double {
        monthlyRate + monthlySondertilgung
    }

    public var progressFraction: Double {
        guard initialPrincipal > 0 else { return 0 }
        return min(1.0, max(0.0, totalPaidSoFar / initialPrincipal))
    }

    public init(
        initialPrincipal: Double = 13500.0,
        totalPaidSoFar: Double = 2018.03,
        remainingPrincipal: Double = 11481.97,
        monthlyRate: Double = 274.70,
        monthlySondertilgung: Double = 1000.0,
        projectedMonthsToFreedom: Int = 9,
        targetFreedomDate: Date = Calendar.current.date(byAdding: .month, value: 9, to: Date()) ?? Date()
    ) {
        self.initialPrincipal = initialPrincipal
        self.totalPaidSoFar = totalPaidSoFar
        self.remainingPrincipal = remainingPrincipal
        self.monthlyRate = monthlyRate
        self.monthlySondertilgung = monthlySondertilgung
        self.projectedMonthsToFreedom = projectedMonthsToFreedom
        self.targetFreedomDate = targetFreedomDate
    }
}

// MARK: - Monthly Recurring Fixed Cost Item
public struct MonthlyFixedCostItem: Identifiable, Codable {
    public var id: String
    public var name: String
    public var expectedAmount: Double
    public var expectedDayOfMonth: Int
    public var isPaidThisMonth: Bool
    public var paidDate: Date?
    public var paidAmount: Double?
    public var category: TransactionCategory
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        expectedAmount: Double,
        expectedDayOfMonth: Int,
        isPaidThisMonth: Bool = false,
        paidDate: Date? = nil,
        paidAmount: Double? = nil,
        category: TransactionCategory = .fixedContracts
    ) {
        self.id = id
        self.name = name
        self.expectedAmount = expectedAmount
        self.expectedDayOfMonth = expectedDayOfMonth
        self.isPaidThisMonth = isPaidThisMonth
        self.paidDate = paidDate
        self.paidAmount = paidAmount
        self.category = category
    }

    public var expectedDueDateThisMonth: Date? {
        var comps = Calendar.current.dateComponents([.year, .month], from: Date())
        comps.day = expectedDayOfMonth
        return Calendar.current.date(from: comps)
    }
}

// MARK: - Targobank Screenshot Record (Audit & Duplicate Prevention)
public struct TargobankScreenshotRecord: Identifiable, Codable, Equatable, Sendable {
    public let id: String
    public var filename: String
    public var timestamp: Date
    public var extractedDate: Date?
    public var extractedAmount: Double?
    public var extractedPartner: String
    public var extractedPurpose: String
    public var extractedAccount: String?
    public var isBooked: Bool
    public var bookedTransactionId: String?
    public var isDuplicate: Bool
    public var duplicateReason: String?
    public var rawText: String

    public init(
        id: String = UUID().uuidString,
        filename: String,
        timestamp: Date = Date(),
        extractedDate: Date? = nil,
        extractedAmount: Double? = nil,
        extractedPartner: String = "",
        extractedPurpose: String = "",
        extractedAccount: String? = nil,
        isBooked: Bool = false,
        bookedTransactionId: String? = nil,
        isDuplicate: Bool = false,
        duplicateReason: String? = nil,
        rawText: String = ""
    ) {
        self.id = id
        self.filename = filename
        self.timestamp = timestamp
        self.extractedDate = extractedDate
        self.extractedAmount = extractedAmount
        self.extractedPartner = extractedPartner
        self.extractedPurpose = extractedPurpose
        self.extractedAccount = extractedAccount
        self.isBooked = isBooked
        self.bookedTransactionId = bookedTransactionId
        self.isDuplicate = isDuplicate
        self.duplicateReason = duplicateReason
        self.rawText = rawText
    }
}

// MARK: - Reporting Data Structures
public struct CategorySummary: Identifiable {
    public var id: String { categoryName }
    public let categoryName: String
    public let totalAmount: Double
    public let transactionCount: Int
    public let averageAmount: Double
    public let percentage: Double
    public let icon: String
    public let color: Color
    public let transactions: [BankTransaction]
}

public struct CategoryShare: Identifiable {
    public var id: String { name }
    public let name: String
    public let amount: Double
    public let percentage: Double
    public let icon: String
    public let color: Color
}

public struct SubscriptionMetric: Identifiable {
    public var id: String { contract.id }
    public let contract: FinanceContractOrSubscription
    public let totalPaidHistorically: Double
    public let monthlyRate: Double
    public let yearlyProjectedCost: Double
    public let paymentCount: Int
}

public struct MonthlyComparisonPoint: Identifiable {
    public var id: String { monthKey }
    public let monthKey: String
    public let monthName: String
    public let income: Double
    public let expenses: Double
    public let netSavings: Double
    public let savingsRate: Double
}

public struct MonthlyProjectionPoint: Identifiable {
    public var id: String { monthKey }
    public let monthKey: String
    public let monthName: String
    public let projectedNetWorth: Double
    public let delta: Double
}

public struct PayeeSummary: Identifiable {
    public var id: String { payeeName }
    public let payeeName: String
    public let totalAmount: Double
    public let transactionCount: Int
    public let latestDate: Date
    public let category: TransactionCategory
    public let transactions: [BankTransaction]
}

public struct TagSummary: Identifiable {
    public var id: String { tagName }
    public let tagName: String
    public let totalAmount: Double
    public let count: Int
    public let transactions: [BankTransaction]
}

public struct BudgetStatus: Identifiable {
    public var id: String { budget.id }
    public let budget: CategoryBudget
    public let spentThisMonth: Double
    public let effectiveLimit: Double
    public var remainingAmount: Double {
        effectiveLimit - spentThisMonth
    }
    public var progressFraction: Double {
        guard effectiveLimit > 0 else { return 0 }
        return min(1.0, max(0.0, spentThisMonth / effectiveLimit))
    }
    public var isOverBudget: Bool {
        spentThisMonth > effectiveLimit
    }
    public let isAutoAdjusted: Bool
    public let dynamicDailyRate: Double?
    public let dynamicRationale: String?
    public let monthlyHistory: [(month: String, amount: Double)]
    public let latestTransactions: [BankTransaction]
    
    public init(
        budget: CategoryBudget,
        spentThisMonth: Double,
        effectiveLimit: Double? = nil,
        isAutoAdjusted: Bool = false,
        dynamicDailyRate: Double? = nil,
        dynamicRationale: String? = nil,
        monthlyHistory: [(month: String, amount: Double)],
        latestTransactions: [BankTransaction]
    ) {
        self.budget = budget
        self.spentThisMonth = spentThisMonth
        self.effectiveLimit = effectiveLimit ?? budget.monthlyLimit
        self.isAutoAdjusted = isAutoAdjusted
        self.dynamicDailyRate = dynamicDailyRate
        self.dynamicRationale = dynamicRationale
        self.monthlyHistory = monthlyHistory
        self.latestTransactions = latestTransactions
    }
}

// MARK: - Cadence Pattern Scanner Models
public enum CadenceInterval: String, CaseIterable, Codable {
    case weekly = "Wöchentlich"
    case biweekly = "Zweiwöchentlich"
    case monthly = "Monatlich"
    case quarterly = "Quartalsweise"
    case annual = "Jährlich"
    case irregular = "Unregelmäßig"

    public var expectedDays: Double {
        switch self {
        case .weekly: return 7.0
        case .biweekly: return 14.0
        case .monthly: return 30.0
        case .quarterly: return 91.0
        case .annual: return 365.0
        case .irregular: return 0.0
        }
    }

    public var icon: String {
        switch self {
        case .weekly, .biweekly: return "repeat.1"
        case .monthly: return "repeat"
        case .quarterly: return "calendar.badge.clock"
        case .annual: return "calendar.badge.checkmark"
        case .irregular: return "chart.bar.xaxis"
        }
    }
}

public struct DetectedCadencePattern: Identifiable, Codable, Hashable {
    public var id: String
    public var counterparty: String
    public var averageIntervalDays: Double
    public var cadence: CadenceInterval
    public var latestAmount: Double
    public var previousAmount: Double?
    public var hasPriceHike: Bool
    public var priceHikeDelta: Double
    public var isRegisteredSubscription: Bool
    public var transactionIds: [String]
    public var confidenceScore: Double
    public var lastSeenDate: Date
    public var firstSeenDate: Date
    public var occurrenceCount: Int
    public var recommendedType: FixedCostType
    public var recommendedBudgetCategory: BudgetCategory

    public var isNewDiscovery: Bool {
        !isRegisteredSubscription
    }

    public var formattedLatestAmount: String {
        String(format: "%.2f €", latestAmount)
    }

    public var formattedPriceHikeDelta: String {
        String(format: "+%.2f €", priceHikeDelta)
    }

    public init(
        id: String = UUID().uuidString,
        counterparty: String,
        averageIntervalDays: Double,
        cadence: CadenceInterval,
        latestAmount: Double,
        previousAmount: Double? = nil,
        hasPriceHike: Bool = false,
        priceHikeDelta: Double = 0.0,
        isRegisteredSubscription: Bool = false,
        transactionIds: [String] = [],
        confidenceScore: Double = 1.0,
        lastSeenDate: Date = Date(),
        firstSeenDate: Date = Date(),
        occurrenceCount: Int = 1,
        recommendedType: FixedCostType = .subscription,
        recommendedBudgetCategory: BudgetCategory = .nebenkosten
    ) {
        self.id = id
        self.counterparty = counterparty
        self.averageIntervalDays = averageIntervalDays
        self.cadence = cadence
        self.latestAmount = latestAmount
        self.previousAmount = previousAmount
        self.hasPriceHike = hasPriceHike
        self.priceHikeDelta = priceHikeDelta
        self.isRegisteredSubscription = isRegisteredSubscription
        self.transactionIds = transactionIds
        self.confidenceScore = confidenceScore
        self.lastSeenDate = lastSeenDate
        self.firstSeenDate = firstSeenDate
        self.occurrenceCount = occurrenceCount
        self.recommendedType = recommendedType
        self.recommendedBudgetCategory = recommendedBudgetCategory
    }
}

// MARK: - Envelope Rollover & Debt Sweep Models
public enum EnvelopeRolloverType: String, CaseIterable, Codable {
    case sinkingFund = "Sinking Fund (Ansparrücklage)"
    case debtRepaymentSweep = "Schuldentilgung-Sweep (Targobank)"

    public var icon: String {
        switch self {
        case .sinkingFund: return "archivebox.circle.fill"
        case .debtRepaymentSweep: return "arrow.right.circle.fill"
        }
    }

    public var color: Color {
        switch self {
        case .sinkingFund: return FinanceTheme.sageGreen
        case .debtRepaymentSweep: return FinanceTheme.strongBlue
        }
    }
}

public struct CategoryRolloverStatus: Identifiable, Codable {
    public var id: String { category.rawValue }
    public var category: BudgetCategory
    public var type: EnvelopeRolloverType
    public var allocatedMonthlyBudget: Double
    public var spentThisMonth: Double
    public var accumulatedSinkingBalance: Double
    public var sweptToDebtAmount: Double

    public var availableEffectiveBudget: Double {
        switch type {
        case .sinkingFund:
            return max(0.0, (allocatedMonthlyBudget + accumulatedSinkingBalance) - spentThisMonth)
        case .debtRepaymentSweep:
            return max(0.0, allocatedMonthlyBudget - spentThisMonth)
        }
    }

    public var remainingUnspentInCurrentCycle: Double {
        max(0.0, allocatedMonthlyBudget - spentThisMonth)
    }

    public init(
        category: BudgetCategory,
        type: EnvelopeRolloverType,
        allocatedMonthlyBudget: Double,
        spentThisMonth: Double,
        accumulatedSinkingBalance: Double = 0.0,
        sweptToDebtAmount: Double = 0.0
    ) {
        self.category = category
        self.type = type
        self.allocatedMonthlyBudget = allocatedMonthlyBudget
        self.spentThisMonth = spentThisMonth
        self.accumulatedSinkingBalance = accumulatedSinkingBalance
        self.sweptToDebtAmount = sweptToDebtAmount
    }
}

public struct EnvelopeRolloverLedger: Codable {
    public var lastUpdated: Date
    public var totalSinkingFundsAccumulated: Double
    public var totalDebtSweepGenerated: Double
    public var categoryStatuses: [CategoryRolloverStatus]

    public init(
        lastUpdated: Date = Date(),
        totalSinkingFundsAccumulated: Double = 0.0,
        totalDebtSweepGenerated: Double = 0.0,
        categoryStatuses: [CategoryRolloverStatus] = []
    ) {
        self.lastUpdated = lastUpdated
        self.totalSinkingFundsAccumulated = totalSinkingFundsAccumulated
        self.totalDebtSweepGenerated = totalDebtSweepGenerated
        self.categoryStatuses = categoryStatuses
    }
}

