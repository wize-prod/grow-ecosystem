import SwiftUI

// MARK: - RecipesView (Dedicated Rezepte Tab)
public struct RecipesView: View {
    @ObservedObject private var store = LocalStore.shared

    public init() {}

    public var body: some View {
        NavigationStack {
            DepotRecipesSection()
                .background(Theme.bg.ignoresSafeArea())
                .navigationTitle("Rezepte")
                .navigationBarTitleDisplayMode(store.isPadInstance ? .inline : .large)
        }
    }
}

public struct DepotRecipesSection: View {
    @ObservedObject var store = LocalStore.shared

    @State private var recipeSearchText: String = ""
    @FocusState private var isRecipeSearchFocused: Bool
    @State private var recipeCategoryFilter: String = "ALLE"
    @State private var recipeCuisineFilter: String = "ALLE"
    @State private var recipeEquipmentFilter: String = "ALLE"
    @State private var recipeSortOption: RecipeSortOption = .none
    @State private var minProteinFilter: Double = 0.0
    @State private var maxPriceFilter: Double = 0.0
    @State private var maxKcalFilter: Double = 0.0
    @State private var maxCarbsFilter: Double = 0.0
    @State private var maxFatFilter: Double = 0.0
    @State private var showingRecipeFilterSheet: Bool = false
    @State private var inspectingTemplate: MealTemplate? = nil
    @State private var customizingTemplate: MealTemplate? = nil
    @State private var newRecipeTemplate: MealTemplate? = nil
    @State private var selectedExplanation: InfoExplanationItem? = nil
    @State private var displayedRecipeCount: Int = 40
    @State private var pantryMatchFilter: PantryMatchFilter = .all

    public init() {}

    private var isAnyRecipeFilterActive: Bool {
        recipeCategoryFilter != "ALLE" ||
        recipeCuisineFilter != "ALLE" ||
        recipeEquipmentFilter != "ALLE" ||
        recipeSortOption != .none ||
        pantryMatchFilter != .all ||
        minProteinFilter > 0 ||
        maxPriceFilter > 0 ||
        maxKcalFilter > 0 ||
        maxCarbsFilter > 0 ||
        maxFatFilter > 0
    }

    private var filteredMealTemplates: [MealTemplate] {
        var list = store.activeMealTemplates

        // Pantry Match Availability Filter (O(1) dictionary lookups)
        switch pantryMatchFilter {
        case .all:
            break
        case .canCook:
            list = list.filter { (store.cachedMatchResults[$0.id] ?? store.matchResult(for: $0)).canCookNow }
        case .almostComplete:
            list = list.filter { tmpl in
                let res = store.cachedMatchResults[tmpl.id] ?? store.matchResult(for: tmpl)
                return res.matchScore >= 0.50 && res.matchScore < 1.0
            }
        case .missingMore:
            list = list.filter { tmpl in
                let res = store.cachedMatchResults[tmpl.id] ?? store.matchResult(for: tmpl)
                return res.matchScore < 0.50
            }
        case .missingInDb:
            list = list.filter { tmpl in
                tmpl.ingredients.contains { ing in
                    store.findPantryItem(for: ing) == nil
                }
            }
        }

        // Category filter
        if recipeCategoryFilter != "ALLE" {
            list = list.filter { $0.standardizedCategory == recipeCategoryFilter }
        }

        // Cuisine filter
        if recipeCuisineFilter != "ALLE" {
            list = list.filter { tmpl in
                let c = tmpl.cuisineType ?? CuisineTaxonomy.inferCuisine(name: tmpl.name, ingredients: tmpl.ingredients.map { $0.name })
                if c.caseInsensitiveCompare(recipeCuisineFilter) == .orderedSame {
                    return true
                }
                if let reg = CuisineTaxonomy.matchRegion(for: c), reg.caseInsensitiveCompare(recipeCuisineFilter) == .orderedSame {
                    return true
                }
                return false
            }
        }

        // Equipment / Method filter
        if recipeEquipmentFilter != "ALLE" {
            let eq = recipeEquipmentFilter.lowercased()
            list = list.filter { tmpl in
                let inferred = EquipmentTaxonomy.inferEquipment(instructions: tmpl.instructions, name: tmpl.name)
                let combined = (tmpl.equipment + inferred).map { $0.lowercased() }
                if eq.contains("ofen") || eq.contains("back") {
                    return combined.contains(where: { $0.contains("ofen") || $0.contains("back") || $0.contains("auflauf") })
                } else if eq.contains("airfryer") || eq.contains("heißluft") {
                    return combined.contains(where: { $0.contains("airfryer") || $0.contains("heißluft") })
                } else if eq.contains("pfanne") {
                    return combined.contains(where: { $0.contains("pfanne") || $0.contains("wok") || $0.contains("braten") })
                } else if eq.contains("topf") || eq.contains("kochtopf") {
                    return combined.contains(where: { $0.contains("topf") || $0.contains("kochen") })
                } else if eq.contains("schmor") || eq.contains("bräter") {
                    return combined.contains(where: { $0.contains("schmor") || $0.contains("bräter") })
                } else if eq.contains("mixer") || eq.contains("pürier") {
                    return combined.contains(where: { $0.contains("mixer") || $0.contains("pürier") || $0.contains("blender") })
                } else if eq.contains("kalt") || eq.contains("kein kochen") {
                    return !combined.contains(where: { $0.contains("ofen") || $0.contains("pfanne") || $0.contains("topf") || $0.contains("airfryer") })
                }
                return combined.contains(where: { $0.contains(eq) })
            }
        }

        // Search text
        let cleanQuery = recipeSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !cleanQuery.isEmpty {
            list = list.filter {
                $0.name.localizedCaseInsensitiveContains(cleanQuery) ||
                $0.category.localizedCaseInsensitiveContains(cleanQuery) ||
                $0.ingredients.contains(where: { $0.name.localizedCaseInsensitiveContains(cleanQuery) })
            }
        }

        // Min protein filter
        if minProteinFilter > 0 {
            list = list.filter { store.templateProtein(for: $0) >= minProteinFilter }
        }

        // Max price filter
        if maxPriceFilter > 0 {
            list = list.filter {
                guard let price = store.templatePrice(for: $0) else { return false }
                return price <= maxPriceFilter
            }
        }

        // Max kcal filter
        if maxKcalFilter > 0 {
            list = list.filter { store.templateKcal(for: $0) <= maxKcalFilter }
        }

        // Max carbs filter
        if maxCarbsFilter > 0 {
            list = list.filter { store.templateCarbs(for: $0) <= maxCarbsFilter }
        }

        // Max fat filter
        if maxFatFilter > 0 {
            list = list.filter { store.templateFat(for: $0) <= maxFatFilter }
        }

        // Sorting
        switch recipeSortOption {
        case .none:
            break
        case .proteinDesc:
            let mapped = list.map { ($0, store.templateProtein(for: $0)) }
            list = mapped.sorted { $0.1 > $1.1 }.map { $0.0 }
        case .priceAsc:
            let mapped = list.map { ($0, store.templatePrice(for: $0) ?? Double.greatestFiniteMagnitude) }
            list = mapped.sorted { $0.1 < $1.1 }.map { $0.0 }
        case .kcalAsc:
            let mapped = list.map { ($0, store.templateKcal(for: $0)) }
            list = mapped.sorted { $0.1 < $1.1 }.map { $0.0 }
        case .kcalDesc:
            let mapped = list.map { ($0, store.templateKcal(for: $0)) }
            list = mapped.sorted { $0.1 > $1.1 }.map { $0.0 }
        case .carbsDesc:
            let mapped = list.map { ($0, store.templateCarbs(for: $0)) }
            list = mapped.sorted { $0.1 > $1.1 }.map { $0.0 }
        case .fatDesc:
            let mapped = list.map { ($0, store.templateFat(for: $0)) }
            list = mapped.sorted { $0.1 > $1.1 }.map { $0.0 }
        }

        return list
    }

    public var body: some View {
        let allFiltered = filteredMealTemplates
        let displayed = Array(allFiltered.prefix(displayedRecipeCount))

        return ZStack(alignment: .bottom) {
            ScrollView {
                LazyVStack(spacing: 12) {
                    // Live-Vorrats-Matching Filter Bar
                    if allFiltered.isEmpty {
                        VStack(spacing: 6) {
                            Text("Keine passenden Rezepte")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Theme.textPrimary)
                            Text("Versuchen Sie andere Suchbegriffe oder passen Sie die Nährwert-/Preis-Filter an.")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(Theme.textMuted)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 16)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 36)
                        .wellnessCard()
                    } else {
                        ForEach(displayed) { template in
                            RecipeCardView(
                                template: template,
                                macros: store.templateMacros(for: template),
                                score: store.templateScore(for: template),
                                matchResult: store.cachedMatchResults[template.id] ?? store.matchResult(for: template),
                                missingDbCount: store.missingDbCount(for: template),
                                onInspect: {
                                    HapticFeedbackService.shared.lightDetent()
                                    inspectingTemplate = template
                                },
                                onQuickLog: {
                                    HapticFeedbackService.shared.commitSuccess()
                                    store.depleteAndLogTemplate(template)
                                },
                                onAddMissing: {
                                    HapticFeedbackService.shared.lightDetent()
                                    store.addMissingIngredientsToShoppingList(for: template)
                                }
                            )
                            .onAppear {
                                if template.id == displayed.last?.id && displayedRecipeCount < allFiltered.count {
                                    displayedRecipeCount += 40
                                }
                            }
                        }

                        if displayedRecipeCount < allFiltered.count {
                            Button(action: {
                                HapticFeedbackService.shared.lightDetent()
                                displayedRecipeCount += 40
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "arrow.down.circle")
                                        .font(.system(size: 13, weight: .semibold))
                                    Text("Weitere Rezepte laden (\(displayed.count) von \(allFiltered.count))")
                                        .font(.system(size: 13, weight: .semibold))
                                }
                                .foregroundColor(Theme.sageGreen)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Theme.surfaceElevated))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 1))
                            }
                            .padding(.top, 4)
                        }
                    }

                    Spacer().frame(height: 75)
                }
                .padding(16)
            }
            .scrollDismissesKeyboard(.interactively)

            // MARK: - BOTTOM COMMAND DECK (SINGULAR SLEEK CAPSULE)
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Theme.textSecondary)

                TextField("Rezepte suchen...", text: $recipeSearchText)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(Theme.textPrimary)
                    .autocorrectionDisabled()

                if !recipeSearchText.isEmpty {
                    Button(action: {
                        HapticFeedbackService.shared.lightDetent()
                        recipeSearchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Theme.textMuted)
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                // Singular Filter Menu Button
                Menu {
                    ForEach(PantryMatchFilter.allCases) { filter in
                        Button(action: {
                            HapticFeedbackService.shared.lightDetent()
                            pantryMatchFilter = filter
                        }) {
                            HStack {
                                Text(filter.rawValue)
                                let count = store.pantryMatchCounts[filter] ?? (filter == .all ? store.mealTemplates.count : 0)
                                Text("(\(count))")
                                if pantryMatchFilter == filter {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }

                    Divider()

                    Button(action: {
                        HapticFeedbackService.shared.lightDetent()
                        showingRecipeFilterSheet = true
                    }) {
                        Label("Erweiterte Filter...", systemImage: "slider.horizontal.3")
                    }
                } label: {
                    let isFiltered = pantryMatchFilter != .all || isAnyRecipeFilterActive
                    HStack(spacing: 4) {
                        Image(systemName: isFiltered ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease")
                            .font(.system(size: 13, weight: .semibold))
                        if pantryMatchFilter != .all {
                            Text(pantryMatchFilter.rawValue.prefix(6))
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                        }
                    }
                    .foregroundColor(isFiltered ? Theme.sageGreen : Theme.textSecondary)
                    .padding(.horizontal, isFiltered ? 8 : 6)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(isFiltered ? Theme.sageGreen.opacity(0.15) : Color.clear)
                    )
                }
                .accessibilityLabel("Rezeptfilter öffnen")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                Theme.surface
                    .opacity(0.95)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Theme.border, lineWidth: 0.8)
                    )
                    .shadow(color: Color.black.opacity(0.35), radius: 10, y: 3)
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 6)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Menu {
                        Button(action: {
                            HapticFeedbackService.shared.lightDetent()
                            store.recomputeRankedTemplates()
                        }) {
                            Label("Vorrats-Matching neu berechnen", systemImage: "arrow.clockwise")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundColor(Theme.textSecondary)
                    }

                    Button(action: {
                        HapticFeedbackService.shared.mechanicalClick()
                        let placeholder = MealTemplate(
                            id: "custom_\(UUID().uuidString.prefix(8))",
                            name: "",
                            category: "Mittagessen",
                            ingredients: [],
                            instructions: ["Zubereitungsschritt 1"],
                            equipment: []
                        )
                        newRecipeTemplate = placeholder
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Theme.bg)
                            .frame(width: 28, height: 28)
                            .background(Circle().fill(Theme.sageGreen))
                    }
                    .accessibilityLabel("Rezept erstellen")
                }
            }
        }
        .sheet(item: $inspectingTemplate) { tmpl in
            RecipeDetailSheet(template: tmpl, store: store)
        }
        .sheet(item: $customizingTemplate) { tmpl in
            CustomizeRecipeSheet(template: tmpl, store: store)
        }
        .sheet(item: $newRecipeTemplate) { tmpl in
            EditRecipeSheet(template: tmpl, store: store) { _ in }
        }
        .sheet(isPresented: $showingRecipeFilterSheet) {
            RecipeFilterSheet(
                selectedCategory: $recipeCategoryFilter,
                selectedCuisine: $recipeCuisineFilter,
                selectedEquipment: $recipeEquipmentFilter,
                sortOption: $recipeSortOption,
                minProtein: $minProteinFilter,
                maxPrice: $maxPriceFilter,
                maxKcal: $maxKcalFilter,
                maxCarbs: $maxCarbsFilter,
                maxFat: $maxFatFilter
            )
        }
        .sheet(item: $selectedExplanation) { item in
            InfoExplanationSheet(item: item)
        }
        .onChange(of: recipeSearchText) { _ in displayedRecipeCount = 40 }
        .onChange(of: recipeCategoryFilter) { _ in displayedRecipeCount = 40 }
        .onChange(of: recipeCuisineFilter) { _ in displayedRecipeCount = 40 }
        .onChange(of: recipeEquipmentFilter) { _ in displayedRecipeCount = 40 }
        .onChange(of: recipeSortOption) { _ in displayedRecipeCount = 40 }
        .onChange(of: minProteinFilter) { _ in displayedRecipeCount = 40 }
        .onChange(of: maxPriceFilter) { _ in displayedRecipeCount = 40 }
        .onChange(of: maxKcalFilter) { _ in displayedRecipeCount = 40 }
        .onChange(of: maxCarbsFilter) { _ in displayedRecipeCount = 40 }
        .onChange(of: maxFatFilter) { _ in displayedRecipeCount = 40 }
    }
}

// MARK: - Recipe Card View
struct RecipeCardView: View {
    let template: MealTemplate
    let macros: LocalStore.RecipeMacros
    let score: ComprehensiveNutritionScore
    let matchResult: RecipeMatchResult
    let missingDbCount: Int
    let onInspect: () -> Void
    let onQuickLog: () -> Void
    let onAddMissing: () -> Void

    var body: some View {
        let cleanName = template.cleanName
        let p = macros.protein
        let c = macros.carbs
        let k = macros.kcal
        let f = macros.fat
        let cuisine = template.cuisineType ?? "Klassiker"

        return HStack(spacing: 12) {
            Button(action: onInspect) {
                HStack(alignment: .center, spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Theme.surfaceElevated)
                        Image(systemName: template.categoryIconName)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(Theme.sageGreen)
                    }
                    .frame(width: 52, height: 52)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 1))

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            if missingDbCount > 0 {
                                Text("\(missingDbCount) FEHLT IN DATENBANK")
                                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                                    .foregroundColor(Theme.terracotta)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(Theme.terracotta.opacity(0.15)))
                                    .overlay(Capsule().stroke(Theme.terracotta.opacity(0.4), lineWidth: 0.8))
                            } else if matchResult.isFullyInStock {
                                Text("100% VORRÄTIG")
                                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                                    .foregroundColor(Theme.sageGreen)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(Theme.sageGreen.opacity(0.15)))
                            } else if matchResult.canCookNow {
                                Text("\(matchResult.matchedIngredients.count)/\(template.ingredients.count) VORRÄTIG")
                                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                                    .foregroundColor(Theme.warmSand)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(Theme.warmSand.opacity(0.15)))
                            } else {
                                Text("\(matchResult.matchedIngredients.count)/\(template.ingredients.count) VORRÄTIG")
                                    .font(.system(size: 8, weight: .medium, design: .monospaced))
                                    .foregroundColor(Theme.textMuted)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(Theme.surfaceElevated))
                            }

                            Text(cuisine)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(Theme.textSecondary)

                            if template.isLongPrep {
                                HStack(spacing: 3) {
                                    Image(systemName: "hourglass.badge.gearshape")
                                        .font(.system(size: 8, weight: .bold))
                                    Text(template.longPreparationType ?? "Zeitintensiv")
                                        .font(.system(size: 8, weight: .bold))
                                }
                                .foregroundColor(Theme.warmSand)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Theme.surfaceElevated))
                                .overlay(Capsule().stroke(Theme.warmSand.opacity(0.4), lineWidth: 1))
                            }
                        }

                        Text(cleanName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Theme.textPrimary)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)

                        HStack(spacing: 6) {
                            Text("\(Int(p))g P")
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundColor(Theme.sageGreen)
                            Text("•")
                                .foregroundColor(Theme.textMuted)
                            Text("\(Int(c))g C")
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundColor(Color(red: 0.58, green: 0.88, blue: 0.28))
                            Text("•")
                                .foregroundColor(Theme.textMuted)
                            Text("\(Int(k)) kcal")
                                .font(.system(size: 11, weight: .regular, design: .monospaced))
                                .foregroundColor(Theme.textSecondary)
                            Text("•")
                                .foregroundColor(Theme.textMuted)
                            Text("\(Int(f))g F")
                                .font(.system(size: 11, weight: .regular, design: .monospaced))
                                .foregroundColor(Color(red: 0.0, green: 0.82, blue: 0.92))
                        }

                        // Compact Multi-Score Pill (Nutri-Score + Food Compass)
                        NutritionalScoresView(score: score, compact: true)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())

            Spacer()

            VStack(spacing: 6) {
                Button(action: onQuickLog) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(Theme.sageGreen)
                        .frame(width: 38, height: 38)
                        .background(Circle().fill(Theme.surfaceElevated))
                }
                .buttonStyle(PlainButtonStyle())

                if !matchResult.missingIngredients.isEmpty {
                    Button(action: onAddMissing) {
                        Image(systemName: "cart.badge.plus")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Theme.warmSand)
                            .frame(width: 28, height: 28)
                            .background(Circle().fill(Theme.surfaceElevated))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(10)
        .wellnessCard(borderColor: missingDbCount == 0 ? Theme.border : Theme.terracotta.opacity(0.45), cornerRadius: 10)
    }
}

// MARK: - 3. DepotShoppingSection (Einkaufsliste & GrowFinance Budget)
