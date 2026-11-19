import SwiftUI

public struct NutritionDetailSheet: View {
    public let title: String
    public let subtitle: String
    public let storeName: String
    public let packSizeText: String
    public let priceText: String?
    public let kcal: Double
    public let protein: Double
    public let carbs: Double
    public let fat: Double
    public let fiber: Double
    public let profile: NutritionalProfile

    public var targetProtein: Double? = nil
    public var targetCarbs: Double? = nil
    public var targetFat: Double? = nil
    public var remainingKcal: Double? = nil
    public var isDailyOverview: Bool = false
    public var supplementKcal: Double = 0.0
    public var supplementProtein: Double = 0.0
    public var supplementCarbs: Double = 0.0
    public var supplementFat: Double = 0.0
    public var supplementFiber: Double = 0.0

    public var storageLocationText: String? = nil
    public var storageInstructionsText: String? = nil
    public var storageIconName: String? = nil
    public var underlyingPantryItem: PantryItem? = nil

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var store = LocalStore.shared
    @State private var selectedTab: DetailTab = .macros
    @State private var editingItem: PantryItem? = nil

    private var effectivePantryItem: PantryItem? {
        if let item = underlyingPantryItem {
            return store.pantryItems.first(where: { $0.id == item.id }) ?? item
        }
        return store.pantryItems.first(where: {
            $0.name.lowercased() == title.lowercased() ||
            title.lowercased().contains($0.name.lowercased()) ||
            $0.name.lowercased().contains(title.lowercased())
        })
    }

    enum DetailTab: String, CaseIterable {
        case macros = "Makros"
        case scores = "Scores"
        case details = "Fett & Zucker"
        case vitamins = "Vitamine"
        case minerals = "Mineralstoffe"
    }

    public init(
        title: String,
        subtitle: String,
        storeName: String,
        packSizeText: String,
        priceText: String? = nil,
        kcal: Double,
        protein: Double,
        carbs: Double,
        fat: Double,
        fiber: Double,
        profile: NutritionalProfile
    ) {
        self.title = title
        self.subtitle = subtitle
        self.storeName = storeName
        self.packSizeText = packSizeText
        self.priceText = priceText
        self.kcal = kcal
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.fiber = fiber
        self.profile = profile
    }

    // Convenience init from PantryItem
    public init(item: PantryItem) {
        self.init(
            title: item.name,
            subtitle: item.brand,
            storeName: item.store,
            packSizeText: "\(Int(item.defaultPackQty)) \(item.unit)",
            priceText: item.defaultPrice > 0 ? item.priceFormatted : nil,
            kcal: item.kcal100g,
            protein: item.protein100g,
            carbs: item.carbs100g,
            fat: item.fat100g,
            fiber: item.fiber100g,
            profile: item.effectiveProfile()
        )
        self.storageLocationText = item.storageLocation.rawValue
        self.storageInstructionsText = item.effectiveStorageInstructions
        self.storageIconName = item.storageLocation.iconName
        self.underlyingPantryItem = item
    }

    // Convenience init from MealTemplate
    public init(template: MealTemplate, store: LocalStore) {
        let price = store.templatePrice(for: template)
        let priceStr = price != nil ? String(format: "%.2f €", price!) : nil
        self.init(
            title: template.name,
            subtitle: template.category,
            storeName: "Mahlzeit",
            packSizeText: "\(template.ingredients.count) Zutaten",
            priceText: priceStr,
            kcal: store.templateKcal(for: template),
            protein: store.templateProtein(for: template),
            carbs: store.templateCarbs(for: template),
            fat: store.templateFat(for: template),
            fiber: store.templateFiber(for: template),
            profile: store.templateProfile(for: template)
        )
    }

    // Convenience init from MealLogEntry
    public init(log: MealLogEntry, store: LocalStore) {
        self.init(
            title: log.foodName,
            subtitle: log.brand,
            storeName: log.mealType,
            packSizeText: "\(Int(log.weightGrams)) g",
            kcal: log.kcal,
            protein: log.protein,
            carbs: log.carbs,
            fat: log.fat,
            fiber: log.fiber,
            profile: store.mealLogProfile(for: log)
        )
    }

    // Convenience init for Daily Intake
    public init(dailyDate: Date, store: LocalStore, activeBurn: Double = 0.0) {
        let formatter = DateFormatter()
        formatter.dateFormat = "d. MMMM yyyy"
        formatter.locale = Locale(identifier: "de_DE")
        let dateStr = formatter.string(from: dailyDate)

        let dKcal = store.kcal(for: dailyDate)
        let dProt = store.protein(for: dailyDate)
        let dCarbs = store.carbs(for: dailyDate)
        let dFat = store.fat(for: dailyDate)
        let dFib = store.fiber(for: dailyDate)
        let netRem = (store.targetKcal + activeBurn) - dKcal

        self.init(
            title: "Makronährstoffe der Tagesbilanz",
            subtitle: dateStr,
            storeName: "Gesamtaufnahme",
            packSizeText: "\(store.logs(for: dailyDate).count) Mahlzeiten",
            kcal: dKcal,
            protein: dProt,
            carbs: dCarbs,
            fat: dFat,
            fiber: dFib,
            profile: store.dailyProfile(for: dailyDate)
        )
        self.targetProtein = store.targetProtein
        self.targetCarbs = store.targetCarbs
        self.targetFat = store.targetFat
        self.remainingKcal = netRem
        self.isDailyOverview = true
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(subtitle.uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Theme.warmSand)
                        .tracking(1.0)
                    Text(title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Theme.textPrimary)
                    HStack(spacing: 8) {
                        Text(storeName)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(Theme.textMuted)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Theme.surfaceElevated))

                        if let pr = priceText {
                            Text(pr)
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(Theme.sageGreen)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(RoundedRectangle(cornerRadius: 6).fill(Theme.surfaceElevated))
                        }

                        Text(packSizeText)
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(Theme.textSecondary)
                    }
                }
                Spacer()
                HStack(spacing: 8) {
                    if let item = underlyingPantryItem {
                        Button(action: {
                            HapticFeedbackService.shared.lightDetent()
                            editingItem = item
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "pencil")
                                    .font(.system(size: 11, weight: .bold))
                                Text("Bearbeiten")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(Theme.warmSand)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(Theme.surfaceElevated))
                        }
                    }

                    Button(action: {
                        dismiss()
                    }) {
                        Text("Fertig")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Theme.sageGreen)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(Theme.surfaceElevated))
                    }
                }
            }
            .padding(16)
            .background(Theme.bg)

            Divider().background(Theme.border)

            // Vorratsbestand Progress Bar (Requirement: bar showing how much of the item is left)
            if let item = effectivePantryItem {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        HStack(spacing: 5) {
                            Image(systemName: "shippingbox.fill")
                                .font(.system(size: 11))
                                .foregroundColor(Theme.warmSand)
                            Text("VORRATSBESTAND")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(Theme.textMuted)
                        }
                        Spacer()
                        Text("\(item.formattedStockWithSubUnits) von \(Int(item.defaultPackQty)) \(item.unit) übrig (\(Int(item.stockRatio * 100))%)")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(item.currentStockQty <= 0 ? Theme.terracotta : (item.isLowStock ? Theme.warmSand : Theme.sageGreen))
                    }

                    // Horizontal Stock Bar
                    GeometryReader { g in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Theme.surfaceElevated)
                                .frame(height: 7)
                            Capsule()
                                .fill(item.currentStockQty <= 0 ? Theme.terracotta : (item.isLowStock ? Theme.warmSand : Theme.sageGreen))
                                .frame(width: max(4.0, g.size.width * CGFloat(min(1.0, max(0.0, item.stockRatio)))), height: 7)
                        }
                    }
                    .frame(height: 7)

                    HStack {
                        Text(item.currentStockQty <= 0 ? "Aufgebraucht (0%)" : (item.isLowStock ? "Niedriger Bestand (Nachkauf empfohlen)" : "Ausreichend auf Lager"))
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(item.currentStockQty <= 0 ? Theme.terracotta : (item.isLowStock ? Theme.warmSand : Theme.sageGreen))
                        Spacer()
                        if item.currentStockQty > 0 {
                            Text("Reichweite: ca. \(String(format: "%.1f", max(1.0, item.currentStockQty / max(1.0, (item.isPieceBased ? item.unitWeightGrams : 100.0))))) Portionen")
                                .font(.system(size: 9, weight: .medium, design: .monospaced))
                                .foregroundColor(Theme.textMuted)
                        }
                    }
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 10).fill(Theme.surfaceElevated.opacity(0.6)))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border.opacity(0.4), lineWidth: 0.5))
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }

            if let loc = storageLocationText, let icon = storageIconName {
                HStack(spacing: 10) {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Theme.warmSand)
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(Theme.surfaceElevated))

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text("LAGERORT:")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(Theme.textMuted)
                            Text(loc.uppercased())
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Theme.warmSand)
                        }
                        if let instr = storageInstructionsText, !instr.isEmpty {
                            Text(instr)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Theme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Theme.surfaceElevated.opacity(0.4))
            }

            // Tab Selector
            HStack(spacing: 4) {
                ForEach(DetailTab.allCases, id: \.self) { tab in
                    Button(action: {
                        HapticFeedbackService.shared.lightDetent()
                        selectedTab = tab
                    }) {
                        Text(tab.rawValue)
                            .font(.system(size: 11, weight: selectedTab == tab ? .bold : .medium))
                            .foregroundColor(selectedTab == tab ? Theme.textPrimary : Theme.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedTab == tab ? Theme.surfaceElevated : Color.clear)
                            )
                    }
                }
            }
            .padding(6)
            .background(Theme.surface)

            Divider().background(Theme.border)

            // Tab Content
            ScrollView {
                VStack(spacing: 12) {
                    switch selectedTab {
                    case .macros:
                        macroOverviewSection
                    case .scores:
                        let score = NutritionalScoringEngine.shared.calculateScore(
                            kcal100g: kcal,
                            protein100g: protein,
                            carbs100g: carbs,
                            fat100g: fat,
                            fiber100g: fiber,
                            sugars100g: profile.sugars ?? 0.0,
                            satFat100g: profile.saturatedFat ?? 0.0,
                            sodiumMg100g: profile.sodium ?? ((profile.salt ?? 0.0) * 400.0),
                            salt100g: profile.salt ?? ((profile.sodium ?? 0.0) / 400.0),
                            potassiumMg100g: profile.potassium ?? 0.0,
                            polyFat100g: profile.polyunsaturatedFat ?? 0.0,
                            profile: profile,
                            productName: title
                        )
                        NutritionalScoresView(score: score, compact: false)
                    case .details:
                        fatsAndSugarsSection
                    case .vitamins:
                        vitaminsSection
                    case .minerals:
                        mineralsSection
                    }
                }
                .padding(16)
            }
        }
        .background(Theme.bg.ignoresSafeArea())
        .sheet(item: $editingItem) { item in
            EditStockSheet(item: item, store: store)
        }
    }

    // MARK: - Sections
    private var macroOverviewSection: some View {
        VStack(spacing: 12) {
            if isDailyOverview {
                // 1. Primary Daily Tiles: Energie, Rest-Budget, Ballaststoffe
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("ENERGIE")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(Theme.textMuted)
                            .tracking(0.5)
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text("\(Int(kcal))")
                                .font(.system(size: 15, weight: .bold, design: .monospaced))
                                .foregroundColor(Theme.textPrimary)
                            Text("kcal")
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundColor(Theme.textMuted)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Theme.surfaceElevated))

                    let rem = remainingKcal ?? 0
                    VStack(alignment: .leading, spacing: 2) {
                        Text("REST-BUDGET")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(Theme.textMuted)
                            .tracking(0.5)
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text("\(Int(rem))")
                                .font(.system(size: 15, weight: .bold, design: .monospaced))
                                .foregroundColor(rem >= 0 ? Theme.sageLight : Theme.terracotta)
                            Text("kcal")
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundColor(Theme.textMuted)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Theme.surfaceElevated))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("BALLASTSTOFFE")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(Theme.textMuted)
                            .tracking(0.5)
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text(String(format: "%.1f", fiber))
                                .font(.system(size: 15, weight: .bold, design: .monospaced))
                                .foregroundColor(fiber >= 25.0 ? Theme.sageGreen : Theme.warmSand)
                            Text("g")
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundColor(Theme.textMuted)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Theme.surfaceElevated))
                }

                // 2. Makronährstoffe der Tagesbilanz Section Header
                sectionHeader("Makronährstoffe der Tagesbilanz")

                // Supplement Nutrition Contribution Card
                if supplementKcal > 0 || supplementFat > 0 || supplementProtein > 0 {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: "pills.fill")
                                .font(.caption2)
                                .foregroundColor(Theme.warmSand)
                            Text("DAVON DURCH TAGES-SUPPLEMENTS")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(Theme.warmSand)
                            Spacer()
                            Text(String(format: "%.1f kcal", supplementKcal))
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(Theme.textPrimary)
                        }

                        HStack(spacing: 12) {
                            if supplementProtein > 0 {
                                Text("Protein: \(String(format: "%.1f", supplementProtein))g")
                                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                                    .foregroundColor(Color(red: 0.96, green: 0.25, blue: 0.37))
                            }
                            if supplementFat > 0 {
                                Text("Fett (Omega-3): \(String(format: "%.1f", supplementFat))g")
                                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                                    .foregroundColor(Color(red: 0.0, green: 0.82, blue: 0.92))
                            }
                            if supplementCarbs > 0 {
                                Text("KH: \(String(format: "%.1f", supplementCarbs))g")
                                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                                    .foregroundColor(Color(red: 0.58, green: 0.88, blue: 0.28))
                            }
                            if supplementFiber > 0 {
                                Text("Ballaststoffe: \(String(format: "%.1f", supplementFiber))g")
                                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                                    .foregroundColor(Theme.sageLight)
                            }
                        }
                    }
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Theme.surfaceElevated))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.warmSand.opacity(0.3), lineWidth: 1))
                }

                // 3. 2x2 Nutrient Matrix with Target Tracking
                HStack(spacing: 10) {
                    nutrientCard(label: "PROTEIN", value: String(format: "%.1f", protein), unit: "/ \(Int(targetProtein ?? 160))g", accent: Color(red: 0.96, green: 0.25, blue: 0.37))
                    nutrientCard(label: "KOHLENHYDRATE", value: "\(Int(carbs))", unit: "/ \(Int(targetCarbs ?? 390))g", accent: Color(red: 0.58, green: 0.88, blue: 0.28))
                }
                HStack(spacing: 10) {
                    nutrientCard(label: "FETTE", value: "\(Int(fat))", unit: "/ \(Int(targetFat ?? 75))g", accent: Color(red: 0.0, green: 0.82, blue: 0.92))
                    nutrientCard(label: "BALLASTSTOFFE", value: String(format: "%.1f", fiber), unit: "/ 30g", accent: Theme.sageLight)
                }
                HStack(spacing: 10) {
                    nutrientCard(label: "SALZ", value: formatVal(profile.salt), unit: profile.salt != nil ? "g" : "", accent: Theme.textSecondary)
                }
            } else {
                HStack(spacing: 10) {
                    nutrientCard(label: "KALORIEN", value: "\(Int(kcal))", unit: "kcal", accent: Theme.textPrimary)
                    nutrientCard(label: "PROTEIN", value: String(format: "%.1f", protein), unit: "g", accent: Color(red: 0.96, green: 0.25, blue: 0.37))
                }
                HStack(spacing: 10) {
                    nutrientCard(label: "KOHLENHYDRATE", value: String(format: "%.1f", carbs), unit: "g", accent: Color(red: 0.58, green: 0.88, blue: 0.28))
                    nutrientCard(label: "FETT", value: String(format: "%.1f", fat), unit: "g", accent: Color(red: 0.0, green: 0.82, blue: 0.92))
                }
                HStack(spacing: 10) {
                    nutrientCard(label: "BALLASTSTOFFE", value: String(format: "%.1f", fiber), unit: "g", accent: Theme.sageLight)
                    nutrientCard(label: "SALZ", value: formatVal(profile.salt), unit: profile.salt != nil ? "g" : "", accent: Theme.textSecondary)
                }
            }
        }
    }

    private var fatsAndSugarsSection: some View {
        VStack(spacing: 8) {
            sectionHeader("Detaillierte Kohlenhydrate")
            VStack(spacing: 6) {
                row(name: "Ballaststoffe", val: formatVal(profile.fiber ?? fiber, unit: "g"))
                row(name: "Zucker gesamt", val: formatVal(profile.sugars, unit: "g"))
                row(name: "Davon Zuckerzusatz", val: formatVal(profile.addedSugars, unit: "g"))
            }
            .wellnessCard()

            sectionHeader("Detaillierte Fettsäuren")
            VStack(spacing: 6) {
                row(name: "Gesättigte Fettsäuren", val: formatVal(profile.saturatedFat, unit: "g"))
                row(name: "Einfach ungesättigte Fettsäuren", val: formatVal(profile.monounsaturatedFat, unit: "g"))
                row(name: "Mehrfach ungesättigte Fettsäuren", val: formatVal(profile.polyunsaturatedFat, unit: "g"))
                row(name: "Transfettsäuren", val: formatVal(profile.transFat, unit: "g"))
            }
            .wellnessCard()

            sectionHeader("Sonstige Bestandteile")
            VStack(spacing: 6) {
                row(name: "Alkohol", val: formatVal(profile.alcohol, unit: "g"))
                row(name: "Cholesterin", val: formatVal(profile.cholesterol, unit: "mg"))
                row(name: "Natrium", val: formatVal(profile.sodium, unit: "mg"))
                row(name: "Salz", val: formatVal(profile.salt, unit: "g"))
                row(name: "Wassergehalt", val: formatVal(profile.water, unit: "g"))
            }
            .wellnessCard()
        }
    }

    private var vitaminsSection: some View {
        VStack(spacing: 8) {
            sectionHeader("Fettlösliche Vitamine")
            VStack(spacing: 6) {
                row(name: "Vitamin A", val: formatVal(profile.vitaminA, unit: "mcg"))
                row(name: "Vitamin D", val: formatVal(profile.vitaminD, unit: "mcg"))
                row(name: "Vitamin E", val: formatVal(profile.vitaminE, unit: "mg"))
                row(name: "Vitamin K", val: formatVal(profile.vitaminK, unit: "mcg"))
            }
            .wellnessCard()

            sectionHeader("Wasserlösliche Vitamine & B-Komplex")
            VStack(spacing: 6) {
                row(name: "Vitamin C", val: formatVal(profile.vitaminC, unit: "mg"))
                row(name: "Vitamin B1 (Thiamin)", val: formatVal(profile.vitaminB1, unit: "mg"))
                row(name: "Vitamin B2 (Riboflavin)", val: formatVal(profile.vitaminB2, unit: "mg"))
                row(name: "Vitamin B3 (Niacin)", val: formatVal(profile.vitaminB3, unit: "mg"))
                row(name: "Vitamin B5 (Pantothensäure)", val: formatVal(profile.vitaminB5, unit: "mg"))
                row(name: "Vitamin B6 (Pyridoxin)", val: formatVal(profile.vitaminB6, unit: "mg"))
                row(name: "Vitamin B7 (Biotin)", val: formatVal(profile.vitaminB7, unit: "mcg"))
                row(name: "Vitamin B11 (Folsäure / Folat)", val: formatVal(profile.vitaminB11, unit: "mcg"))
                row(name: "Vitamin B12 (Cobalamin)", val: formatVal(profile.vitaminB12, unit: "mcg"))
            }
            .wellnessCard()
        }
    }

    private var mineralsSection: some View {
        VStack(spacing: 8) {
            sectionHeader("Mengenelemente")
            VStack(spacing: 6) {
                row(name: "Kalzium", val: formatVal(profile.calcium, unit: "mg"))
                row(name: "Magnesium", val: formatVal(profile.magnesium, unit: "mg"))
                row(name: "Kalium", val: formatVal(profile.potassium, unit: "mg"))
                row(name: "Phosphor", val: formatVal(profile.phosphorus, unit: "mg"))
                row(name: "Chlorid", val: formatVal(profile.chloride, unit: "mg"))
                row(name: "Schwefel", val: formatVal(profile.sulfur, unit: "mg"))
            }
            .wellnessCard()

            sectionHeader("Spurenelemente & Mineralstoffe")
            VStack(spacing: 6) {
                row(name: "Eisen", val: formatVal(profile.iron, unit: "mg"))
                row(name: "Zink", val: formatVal(profile.zinc, unit: "mg"))
                row(name: "Kupfer", val: formatVal(profile.copper, unit: "mg"))
                row(name: "Mangan", val: formatVal(profile.manganese, unit: "mg"))
                row(name: "Jod", val: formatVal(profile.iodine, unit: "mcg"))
                row(name: "Selen", val: formatVal(profile.selenium, unit: "mcg"))
                row(name: "Chrom", val: formatVal(profile.chromium, unit: "mcg"))
                row(name: "Molybdän", val: formatVal(profile.molybdenum, unit: "mcg"))
                row(name: "Fluor / Fluorid", val: formatVal(profile.fluoride ?? profile.fluorine, unit: "mg"))
                row(name: "Cholin", val: formatVal(profile.choline, unit: "mg"))
                row(name: "Bor", val: formatVal(profile.boron, unit: "mg"))
                row(name: "Silizium", val: formatVal(profile.silicon, unit: "mg"))
                row(name: "Vanadium", val: formatVal(profile.vanadium, unit: "mcg"))
                row(name: "Arsen", val: formatVal(profile.arsenic, unit: "mcg"))
                row(name: "Kobalt", val: formatVal(profile.cobalt, unit: "mcg"))
                row(name: "Rubidium", val: formatVal(profile.rubidium, unit: "mcg"))
                row(name: "Zinn", val: formatVal(profile.tin, unit: "mcg"))
            }
            .wellnessCard()
        }
    }

    // MARK: - Row & Tile Helpers
    private func nutrientCard(label: String, value: String, unit: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(Theme.textMuted)
                .tracking(0.8)
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(.system(size: 18, weight: .semibold, design: .monospaced))
                    .foregroundColor(accent)
                Text(unit)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(Theme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .wellnessCard()
    }

    private func row(name: String, val: String) -> some View {
        HStack {
            Text(name)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Theme.textPrimary)
            Spacer()
            Text(val)
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundColor(val == "Nicht ausgewiesen" ? Theme.textMuted : Theme.warmSand)
        }
        .padding(.vertical, 2)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(Theme.textMuted)
            .tracking(0.8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 4)
    }

    private func formatVal(_ val: Double?, unit: String = "") -> String {
        guard let v = val, v > 0 else { return "Nicht ausgewiesen" }
        if v >= 10.0 {
            return String(format: "%.1f %@", v, unit)
        } else if v >= 1.0 {
            return String(format: "%.2f %@", v, unit)
        } else {
            return String(format: "%.3f %@", v, unit)
        }
    }
}
