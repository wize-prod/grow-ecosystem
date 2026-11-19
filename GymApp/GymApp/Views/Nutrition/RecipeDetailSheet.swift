import SwiftUI

public struct RecipeDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentTemplate: MealTemplate
    @ObservedObject var store: LocalStore

    @State private var showingCustomizer: Bool = false
    @State private var showingEditor: Bool = false
    @State private var bookedSuccess: Bool = false
    @State private var addedToShoppingSuccess: Bool = false
    @State private var customIngredientGrams: [String: Double] = [:]
    @State private var inspectingIngredientItem: PantryItem? = nil
    @State private var editingPantryItem: PantryItem? = nil

    private func pantryItemForIngredient(_ ing: TemplateIngredient) -> PantryItem {
        if let match = store.findPantryItem(for: ing) {
            return match
        }

        let std = CommodityReferenceCatalog.standardMacros(forProductName: ing.name)
        let resolvedId = (!ing.pantryItemId.isEmpty && !ing.pantryItemId.starts(with: "temp_")) ? ing.pantryItemId : "food_\(UUID().uuidString.prefix(8).lowercased())"
        return PantryItem(
            id: resolvedId,
            name: ing.name,
            brand: "Pantry",
            barcode: "",
            defaultPackQty: max(100.0, ing.grams),
            defaultPrice: 1.49,
            currentStockQty: 0.0,
            unit: "g",
            kcal100g: std?.kcal ?? 100.0,
            protein100g: std?.protein ?? 10.0,
            carbs100g: std?.carbs ?? 10.0,
            fat100g: std?.fat ?? 2.0,
            fiber100g: std?.fiber ?? 2.0,
            store: "PENNY"
        )
    }

    private var missingDbIngredients: [TemplateIngredient] {
        currentTemplate.ingredients.filter { store.findPantryItem(for: $0) == nil }
    }

    public init(template: MealTemplate, store: LocalStore) {
        self._currentTemplate = State(initialValue: template)
        self.store = store
    }

    private func currentGrams(for ing: TemplateIngredient) -> Double {
        return customIngredientGrams[ing.id] ?? ing.grams
    }

    private var hasCustomIngredientAdjustments: Bool {
        !customIngredientGrams.isEmpty && customIngredientGrams.contains { (key, val) in
            if let orig = currentTemplate.ingredients.first(where: { $0.id == key }) {
                return abs(orig.grams - val) > 0.01
            }
            return false
        }
    }

    private var effectiveTemplate: MealTemplate {
        var modified = currentTemplate
        modified.ingredients = currentTemplate.ingredients.map { ing in
            guard let customG = customIngredientGrams[ing.id] else { return ing }
            var adj = ing
            adj.grams = customG
            let pantryMatch = store.pantryItems.first(where: {
                $0.id == ing.pantryItemId || $0.name.lowercased() == ing.name.lowercased()
            })
            if let p = pantryMatch, p.isPieceBased {
                let pieces = customG <= 20 ? customG : (customG / p.unitWeightGrams).rounded()
                adj.rawAmount = pieces
            } else {
                adj.rawAmount = customG
            }
            return adj
        }
        return modified
    }

    private var kcal: Double { store.templateKcal(for: effectiveTemplate) }
    private var protein: Double { store.templateProtein(for: effectiveTemplate) }
    private var carbs: Double { store.templateCarbs(for: effectiveTemplate) }
    private var fat: Double { store.templateFat(for: effectiveTemplate) }
    private var fiber: Double { store.templateFiber(for: effectiveTemplate) }
    private var portionPrice: Double? { store.templatePrice(for: effectiveTemplate) }
    private var recipeMarkdownDocument: String {
        var doc = "# \(effectiveTemplate.name)\n\n"
        doc += "- **Kategorie:** \(effectiveTemplate.category)\n"
        doc += "- **Cuisine:** \(effectiveTemplate.cuisineType ?? "Standard")\n\n"
        doc += "### Naehrwert-Profil\n"
        doc += "- **Kalorien:** \(Int(kcal)) kcal\n"
        doc += "- **Protein:** \(String(format: "%.1f", protein)) g\n"
        doc += "- **Kohlenhydrate:** \(String(format: "%.1f", carbs)) g\n"
        doc += "- **Fett:** \(String(format: "%.1f", fat)) g\n"
        doc += "- **Ballaststoffe:** \(String(format: "%.1f", fiber)) g\n"
        if let price = portionPrice {
            doc += "- **Portionspreis:** \(String(format: "%.2f", price)) EUR\n"
        }
        let nScore = NutritionalScoringEngine.shared.evaluate(template: effectiveTemplate, store: store)
        if nScore.hasSufficientData {
            doc += "- **Nutri-Score:** \(nScore.nutriScoreGrade) | **Food Compass:** \(nScore.foodCompassScore)/100\n"
            doc += "- **Protein-Dichte (BPI):** \(String(format: "%.1f", nScore.bpiProteinIndex)) g/100 kcal (\(nScore.bpiCategory))\n"
        }
        doc += "\n"
        doc += "### Zutaten\n"
        for ing in effectiveTemplate.ingredients {
            doc += "- \(Int(currentGrams(for: ing))) g \(ing.name)\n"
        }
        doc += "\n### Zubereitung & Anleitung\n"
        if effectiveTemplate.instructions.isEmpty {
            doc += "1. Alle Zutaten grammgenau abwiegen und nach gewuenschter Garstufe zubereiten.\n"
        } else {
            for (idx, step) in effectiveTemplate.instructions.enumerated() {
                doc += "\(idx + 1). \(cleanStepText(step))\n"
            }
        }
        return doc
    }

    private var recipeExportURL: URL {
        let cleanName = effectiveTemplate.name
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
            .replacingOccurrences(of: " ", with: "_")
        let filename = (cleanName.isEmpty ? "Rezept" : cleanName) + ".md"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try? recipeMarkdownDocument.write(to: tempURL, atomically: true, encoding: .utf8)
        return tempURL
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Recipe Image (if available)
                    if let img = store.getRecipeImage(filename: currentTemplate.imageFileName) {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 180)
                            .frame(maxWidth: .infinity)
                            .clipped()
                            .cornerRadius(14)
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.border, lineWidth: 1))
                    } else if let urlStr = currentTemplate.imageUrl, let url = URL(string: urlStr) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 180)
                                    .frame(maxWidth: .infinity)
                                    .clipped()
                            default:
                                Color.clear
                                    .frame(height: 180)
                            }
                        }
                        .cornerRadius(14)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.border, lineWidth: 1))
                    }

                    // Category & Title Card
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            let cuisine = currentTemplate.cuisineType ?? CuisineTaxonomy.inferCuisine(name: currentTemplate.name, ingredients: currentTemplate.ingredients.map { $0.name })
                            Text(currentTemplate.category.uppercased())
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Theme.warmSand)
                                .tracking(1.0)
                            Text("•")
                                .foregroundColor(Theme.textMuted)
                            Text(cuisine.uppercased())
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Theme.sageGreen)
                                .tracking(0.8)
                            Spacer()
                            if let pr = portionPrice {
                                Text(String(format: "%.2f € / Portion", pr))
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .foregroundColor(Theme.warmSand)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Capsule().fill(Theme.surfaceElevated))
                                    .overlay(Capsule().stroke(Theme.warmSand.opacity(0.5), lineWidth: 1))
                            } else {
                                Text("Preis unvollständig")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(Theme.textMuted)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Capsule().fill(Theme.surfaceElevated))
                            }
                        }
                        Text(currentTemplate.name)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(Theme.textPrimary)

                        // Prep Time, Cook Time, Total Time, Servings Bar
                        HStack(spacing: 6) {
                            HStack(spacing: 3) {
                                Image(systemName: "timer")
                                    .font(.system(size: 10, weight: .bold))
                                Text("Vorbereitung: \(currentTemplate.prepTimeMinutes) Min")
                                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            }
                            .foregroundColor(Theme.warmSand)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Theme.surfaceElevated))

                            HStack(spacing: 3) {
                                Image(systemName: "flame")
                                    .font(.system(size: 10, weight: .bold))
                                Text("Kochen: \(currentTemplate.cookTimeMinutes) Min")
                                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            }
                            .foregroundColor(Theme.warmSand)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Theme.surfaceElevated))

                            HStack(spacing: 3) {
                                Image(systemName: "clock.badge.checkmark")
                                    .font(.system(size: 10, weight: .bold))
                                Text("Gesamt: \(currentTemplate.totalTimeMinutes) Min")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                            }
                            .foregroundColor(Theme.sageGreen)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Theme.surfaceElevated))

                            HStack(spacing: 3) {
                                Image(systemName: "person.2")
                                    .font(.system(size: 10, weight: .bold))
                                Text("\(currentTemplate.servings) Port.")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                            }
                            .foregroundColor(Theme.textPrimary)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Theme.surfaceElevated))
                        }
                        .padding(.top, 2)

                        if hasCustomIngredientAdjustments {
                            HStack(spacing: 5) {
                                Image(systemName: "slider.horizontal.below.rectangle")
                                    .font(.system(size: 10, weight: .bold))
                                Text("Individuell angepasst • Portionen unverändert (\(currentTemplate.servings))")
                                    .font(.system(size: 11, weight: .bold))
                            }
                            .foregroundColor(Theme.warmSand)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Theme.surfaceElevated))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.warmSand.opacity(0.4), lineWidth: 1))
                            .padding(.top, 2)
                        }
                    }
                    .wellnessCard(borderColor: Theme.border)

                    // Macro Highlights (Live aktualisiert)
                    HStack(spacing: 6) {
                        macroMetricTile(title: "PROTEIN", value: String(format: "%.1f g", protein), accent: Theme.sageGreen)
                        macroMetricTile(title: "ENERGIE", value: "\(Int(kcal)) kcal", accent: Theme.textPrimary)
                        macroMetricTile(title: "CARBS", value: "\(Int(carbs)) g", accent: Theme.textSecondary)
                        macroMetricTile(title: "FETT", value: "\(Int(fat)) g", accent: Theme.textSecondary)
                        if let pr = portionPrice {
                            macroMetricTile(title: "KOSTEN", value: String(format: "%.2f €", pr), accent: Theme.warmSand)
                        } else if fiber > 0 {
                            macroMetricTile(title: "FIBER", value: String(format: "%.1f g", fiber), accent: Theme.warmSand)
                        }
                    }

                    // Comprehensive Personalized Health Score View
                    let recipeScore = NutritionalScoringEngine.shared.evaluate(template: effectiveTemplate, store: store)
                    NutritionalScoresView(score: recipeScore, compact: false)

                    if !missingDbIngredients.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(Theme.terracotta)
                                Text("ZUTATEN FEHLEN IN DATENBANK (\(missingDbIngredients.count))")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(Theme.terracotta)
                            }
                            Text("\(missingDbIngredients.count) Zutat(en) sind noch nicht im Vorrat registriert: \(missingDbIngredients.map { $0.name }.joined(separator: ", ")). Lege sie an, um Nährwerte und Preise exakt zu erfassen.")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Theme.textPrimary)
                        }
                        .wellnessCard(borderColor: Theme.terracotta.opacity(0.5))
                    }

                    // Ingredients List with individual size adjustment steppers
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("ZUTATEN & MENGEN")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Theme.textMuted)
                                .tracking(0.8)
                            Spacer()
                            Button(action: {
                                HapticFeedbackService.shared.lightDetent()
                                let scaled = GenerativeCulinaryEngine.shared.scale(
                                    template: currentTemplate,
                                    targetProtein: store.targetProtein / 3.0,
                                    targetKcal: store.targetKcal / 3.0,
                                    store: store
                                )
                                currentTemplate = scaled
                                customIngredientGrams.removeAll()
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "scalemass.fill")
                                        .font(.system(size: 9, weight: .bold))
                                    Text("Bedarfs-Skalierung")
                                        .font(.system(size: 10, weight: .bold))
                                }
                                .foregroundColor(Theme.sageGreen)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(RoundedRectangle(cornerRadius: 6).fill(Theme.surfaceElevated))
                            }

                            if hasCustomIngredientAdjustments {
                                Button(action: {
                                    HapticFeedbackService.shared.lightDetent()
                                    customIngredientGrams.removeAll()
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "arrow.counterclockwise")
                                            .font(.system(size: 9, weight: .bold))
                                        Text("Mengen zurücksetzen")
                                            .font(.system(size: 10, weight: .bold))
                                    }
                                    .foregroundColor(Theme.warmSand)
                                }
                            }
                        }

                        let match = PantryMatchingEngine.shared.match(template: currentTemplate, pantryItems: store.pantryItems)
                        if !match.missingIngredients.isEmpty {
                            Button(action: {
                                HapticFeedbackService.shared.commitSuccess()
                                store.addMissingIngredientsToShoppingList(for: currentTemplate)
                                addedToShoppingSuccess = true
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: addedToShoppingSuccess ? "checkmark.circle.fill" : "cart.badge.plus")
                                        .font(.system(size: 11, weight: .bold))
                                    Text(addedToShoppingSuccess ? "AUF EINKAUFSLISTE VERBUCHT" : "\(match.missingIngredients.count) FEHLENDE ZUTATEN AUF EINKAUFSLISTE SETZEN")
                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                }
                                .foregroundColor(addedToShoppingSuccess ? Theme.sageGreen : Theme.warmSand)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 7)
                                .background(RoundedRectangle(cornerRadius: 8).fill(Theme.surfaceElevated))
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke((addedToShoppingSuccess ? Theme.sageGreen : Theme.warmSand).opacity(0.4), lineWidth: 1))
                            }
                        }

                        VStack(spacing: 8) {
                            ForEach(currentTemplate.ingredients) { ing in
                                let pantryMatch = store.findPantryItem(for: ing)
                                let isSubUnit = pantryMatch?.hasSubUnits ?? false
                                let isPiece = (pantryMatch?.isPieceBased ?? false) || isSubUnit
                                let currentG = currentGrams(for: ing)
                                let unitWeight = isSubUnit ? (pantryMatch?.effectiveSubUnitSize ?? 25.0) : (pantryMatch?.unitWeightGrams ?? 1.0)
                                let subUnitName = isSubUnit ? (pantryMatch?.effectiveSubUnitName ?? "Scheiben") : (pantryMatch?.unit.isEmpty == false ? pantryMatch!.unit : "Stk")
                                let subUnitSingular: String = {
                                    if subUnitName.hasSuffix("en") { return String(subUnitName.dropLast(2)) }
                                    if subUnitName.hasSuffix("n") { return String(subUnitName.dropLast(1)) }
                                    return subUnitName
                                }()
                                let pieces = isPiece ? max(1.0, (currentG <= 20 && !isSubUnit ? currentG : (currentG / unitWeight)).rounded()) : 0.0
                                let isModified = customIngredientGrams[ing.id] != nil && abs(customIngredientGrams[ing.id]! - ing.grams) > 0.01

                                let unitLabel: String = {
                                    if let p = pantryMatch {
                                        if isSubUnit {
                                            let count = max(1, Int((currentG / p.effectiveSubUnitSize).rounded()))
                                            let nameDisplay = count == 1 ? subUnitSingular : subUnitName
                                            return "\(count) \(nameDisplay) (ca. \(Int(currentG)) g)"
                                        } else if p.isPieceBased {
                                            return "\(Int(pieces)) \(p.unit.isEmpty ? "Stk" : p.unit) (ca. \(Int(currentG)) g)"
                                        } else if p.isLiterUnit || p.isMilliliterUnit {
                                            return "\(Int(currentG)) ml"
                                        }
                                    }
                                    return "\(Int(currentG)) g"
                                }()

                                let hasStock: Bool = {
                                    guard let p = pantryMatch else { return false }
                                    if p.isPieceBased {
                                        let needed = currentG <= 20 ? currentG : (currentG / p.unitWeightGrams)
                                        return p.currentStockQty >= needed
                                    } else if p.isLiterUnit {
                                        let neededLiters = currentG / 1000.0
                                        return p.currentStockQty >= neededLiters
                                    } else {
                                        return p.currentStockQty >= currentG
                                    }
                                }()

                                let ingCost: Double? = {
                                    guard let p = pantryMatch, p.defaultPrice > 0.005, p.defaultPackQty > 0 else { return nil }
                                    if p.isPieceBased {
                                        let pCount = currentG <= 20 ? currentG : (currentG / p.unitWeightGrams)
                                        return pCount * (p.defaultPrice / p.defaultPackQty)
                                    } else if p.isLiterUnit {
                                        let packMl = p.defaultPackQty * 1000.0
                                        return currentG * (p.defaultPrice / packMl)
                                    } else {
                                        return currentG * (p.defaultPrice / p.defaultPackQty)
                                    }
                                }()

                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Button(action: {
                                            HapticFeedbackService.shared.lightDetent()
                                            inspectingIngredientItem = pantryItemForIngredient(ing)
                                        }) {
                                            VStack(alignment: .leading, spacing: 2) {
                                                HStack(spacing: 6) {
                                                    Text(ing.name)
                                                        .font(.system(size: 13, weight: .semibold))
                                                        .foregroundColor(Theme.textPrimary)
                                                    Image(systemName: "info.circle")
                                                        .font(.system(size: 11))
                                                        .foregroundColor(Theme.sageGreen)
                                                    if isModified {
                                                        Text("angepasst")
                                                            .font(.system(size: 9, weight: .bold))
                                                            .foregroundColor(Theme.warmSand)
                                                            .padding(.horizontal, 5)
                                                            .padding(.vertical, 1)
                                                            .background(Capsule().fill(Theme.warmSand.opacity(0.15)))
                                                    }
                                                }
                                                HStack(spacing: 6) {
                                                    if let p = pantryMatch {
                                                        let neededGrams = currentG
                                                        let totalStock = p.currentStockQty
                                                        let unitStr = p.unit.isEmpty ? "g" : p.unit
                                                        let isSufficient = totalStock >= neededGrams
                                                        Text("\(Int(neededGrams))\(unitStr) / \(Int(totalStock))\(unitStr) Vorrat")
                                                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                                                            .foregroundColor(isSufficient ? Theme.sageGreen : Theme.terracotta)
                                                    } else {
                                                        Text("NICHT IN DATENBANK")
                                                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                                                            .foregroundColor(Theme.terracotta)
                                                            .padding(.horizontal, 4)
                                                            .padding(.vertical, 1)
                                                            .background(Capsule().fill(Theme.terracotta.opacity(0.15)))
                                                    }
                                                    if let cost = ingCost {
                                                        Text("•")
                                                            .foregroundColor(Theme.textMuted)
                                                        Text(String(format: "%.2f €", cost))
                                                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                                                            .foregroundColor(Theme.warmSand)
                                                    }
                                                }
                                            }
                                        }
                                        .buttonStyle(.plain)

                                        Spacer()
                                        Text(unitLabel)
                                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                                            .foregroundColor(isModified ? Theme.sageGreen : Theme.warmSand)
                                    }

                                    // Full-Width Bestandsbalken (Bedarf vs. Gesamtlagerbestand)
                                    if let p = pantryMatch {
                                        let neededGrams = currentG
                                        let totalStock = p.currentStockQty
                                        let unitStr = p.unit.isEmpty ? "g" : p.unit
                                        let ratio = totalStock > 0 ? min(1.0, max(0.0, neededGrams / totalStock)) : 0.0
                                        let isSufficient = totalStock >= neededGrams
                                        let remainingAfter = max(0.0, totalStock - neededGrams)
                                        let subUnitDetail: String = {
                                            if p.hasSubUnits && p.effectiveSubUnitSize > 0 {
                                                let neededUnits = max(1, Int((neededGrams / p.effectiveSubUnitSize).rounded()))
                                                let totalUnits = Int((totalStock / p.effectiveSubUnitSize).rounded())
                                                return " (\(neededUnits) von \(totalUnits) \(p.effectiveSubUnitName))"
                                            }
                                            return ""
                                        }()

                                        VStack(alignment: .leading, spacing: 3) {
                                            GeometryReader { g in
                                                ZStack(alignment: .leading) {
                                                    Capsule()
                                                        .fill(Theme.surfaceElevated)
                                                        .frame(width: g.size.width, height: 6)
                                                    Capsule()
                                                        .fill(isSufficient ? Theme.sageGreen : Theme.terracotta)
                                                        .frame(width: max(3.0, min(g.size.width, g.size.width * CGFloat(ratio))), height: 6)
                                                }
                                            }
                                            .frame(height: 6)

                                            HStack {
                                                Text("Bedarf: \(Int(neededGrams)) \(unitStr)\(subUnitDetail) (\(Int(ratio * 100))%)")
                                                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                                                    .foregroundColor(Theme.textMuted)
                                                Spacer()
                                                Text(isSufficient ? "\(Int(remainingAfter)) \(unitStr) verbleiben danach" : "Defizit: \(Int(neededGrams - totalStock)) \(unitStr)")
                                                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                                                    .foregroundColor(isSufficient ? Theme.sageGreen : Theme.terracotta)
                                            }
                                        }
                                        .padding(.vertical, 2)
                                    } else {
                                        HStack {
                                            Text("Nicht in Datenbank hinterlegt.")
                                                .font(.system(size: 9))
                                                .foregroundColor(Theme.textMuted)
                                            Spacer()
                                            Button(action: {
                                                HapticFeedbackService.shared.mechanicalClick()
                                                let candidate = pantryItemForIngredient(ing)
                                                editingPantryItem = candidate
                                            }) {
                                                HStack(spacing: 4) {
                                                    Image(systemName: "plus.circle.fill")
                                                        .font(.system(size: 10, weight: .bold))
                                                    Text("Als Lebensmittel anlegen")
                                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                                }
                                                .foregroundColor(Theme.warmSand)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(RoundedRectangle(cornerRadius: 6).fill(Theme.surfaceElevated))
                                                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.warmSand.opacity(0.4), lineWidth: 1))
                                            }
                                        }
                                        .padding(.vertical, 3)
                                    }

                                    // Quick Adjustment Steppers per Ingredient
                                    HStack(spacing: 6) {
                                        if isPiece {
                                            Button(action: {
                                                HapticFeedbackService.shared.lightDetent()
                                                let newP = max(1.0, pieces - 1.0)
                                                customIngredientGrams[ing.id] = newP * unitWeight
                                            }) {
                                                Text(isSubUnit ? "-1 \(subUnitSingular)" : "-1 Stk")
                                                    .font(.system(size: 11, weight: .bold))
                                                    .foregroundColor(Theme.textPrimary)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 4)
                                                    .background(RoundedRectangle(cornerRadius: 6).fill(Theme.surface))
                                            }

                                            Button(action: {
                                                HapticFeedbackService.shared.lightDetent()
                                                let newP = pieces + 1.0
                                                customIngredientGrams[ing.id] = newP * unitWeight
                                            }) {
                                                Text(isSubUnit ? "+1 \(subUnitSingular)" : "+1 Stk")
                                                    .font(.system(size: 11, weight: .bold))
                                                    .foregroundColor(Theme.textPrimary)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 4)
                                                    .background(RoundedRectangle(cornerRadius: 6).fill(Theme.surface))
                                            }

                                            Button(action: {
                                                HapticFeedbackService.shared.lightDetent()
                                                let newP = pieces + 2.0
                                                customIngredientGrams[ing.id] = newP * unitWeight
                                            }) {
                                                Text(isSubUnit ? "+2 \(subUnitName)" : "+2 Stk")
                                                    .font(.system(size: 11, weight: .bold))
                                                    .foregroundColor(Theme.textPrimary)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 4)
                                                    .background(RoundedRectangle(cornerRadius: 6).fill(Theme.surface))
                                            }
                                        } else {
                                            Button(action: {
                                                HapticFeedbackService.shared.lightDetent()
                                                let step = currentG > 100 ? 25.0 : 10.0
                                                customIngredientGrams[ing.id] = max(10.0, currentG - step)
                                            }) {
                                                Text(currentG > 100 ? "-25g" : "-10g")
                                                    .font(.system(size: 11, weight: .bold))
                                                    .foregroundColor(Theme.textPrimary)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 4)
                                                    .background(RoundedRectangle(cornerRadius: 6).fill(Theme.surface))
                                            }

                                            Button(action: {
                                                HapticFeedbackService.shared.lightDetent()
                                                let step = currentG >= 100 ? 25.0 : 10.0
                                                customIngredientGrams[ing.id] = currentG + step
                                            }) {
                                                Text(currentG >= 100 ? "+25g" : "+10g")
                                                    .font(.system(size: 11, weight: .bold))
                                                    .foregroundColor(Theme.textPrimary)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 4)
                                                    .background(RoundedRectangle(cornerRadius: 6).fill(Theme.surface))
                                            }

                                            Button(action: {
                                                HapticFeedbackService.shared.lightDetent()
                                                customIngredientGrams[ing.id] = currentG + 50.0
                                            }) {
                                                Text("+50g")
                                                    .font(.system(size: 11, weight: .bold))
                                                    .foregroundColor(Theme.textPrimary)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 4)
                                                    .background(RoundedRectangle(cornerRadius: 6).fill(Theme.surface))
                                            }
                                        }

                                        if isModified {
                                            Spacer()
                                            Button(action: {
                                                HapticFeedbackService.shared.lightDetent()
                                                customIngredientGrams.removeValue(forKey: ing.id)
                                            }) {
                                                Text("Reset")
                                                    .font(.system(size: 10, weight: .semibold))
                                                    .foregroundColor(Theme.textMuted)
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 4)
                                            }
                                        }
                                    }
                                    .padding(.top, 2)
                                }
                                .padding(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(isModified ? Theme.warmSand.opacity(0.4) : Color.clear, lineWidth: 1)
                                )
                            }
                        }
                    }
                    // Long Preparation Note (if applicable)
                    if currentTemplate.isLongPrep {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "hourglass.badge.gearshape")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(Theme.warmSand)
                                Text("ZEITINTENSIVE ZUBEREITUNGSMETHODIK")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(Theme.warmSand)
                                    .tracking(0.8)
                            }
                            Text(currentTemplate.longPreparationType ?? "Diese Rezeptur erfordert zeitintensive Prozesse wie Marinieren, Pökeln, Schmoren, Fermentieren oder Teigruhe.")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Theme.textPrimary)
                        }
                        .wellnessCard(borderColor: Theme.warmSand.opacity(0.4))
                    }

                    // Kitchen Equipment Section
                    let eqList: [String] = {
                        if !currentTemplate.equipment.isEmpty {
                            return currentTemplate.equipment
                        }
                        return EquipmentTaxonomy.inferEquipment(instructions: currentTemplate.instructions, name: currentTemplate.name)
                    }()

                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "wrench.and.screwdriver")
                                .font(.system(size: 12))
                                .foregroundColor(Theme.sageGreen)
                            Text("BENÖTIGTE KÜCHENAUSSTATTUNG")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Theme.textMuted)
                                .tracking(0.8)
                            Spacer()
                            Text("\(eqList.count) Utensilien")
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundColor(Theme.textSecondary)
                        }

                        FlowLayout(spacing: 6) {
                            ForEach(eqList, id: \.self) { eq in
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(Theme.sageGreen)
                                    Text(eq)
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(Theme.textPrimary)
                                }
                                .padding(.horizontal, 9)
                                .padding(.vertical, 5)
                                .background(RoundedRectangle(cornerRadius: 8).fill(Theme.surfaceElevated))
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 1))
                            }
                        }
                    }
                    .wellnessCard()

                    // Step-by-step Preparation Guide without numbering
                    if !currentTemplate.instructions.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("ZUBEREITUNG")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Theme.textMuted)
                                .tracking(0.8)

                            VStack(spacing: 8) {
                                ForEach(currentTemplate.instructions, id: \.self) { step in
                                    let cleaned = cleanStepText(step)
                                    HStack(alignment: .top, spacing: 10) {
                                        Circle()
                                            .fill(Theme.sageGreen)
                                            .frame(width: 6, height: 6)
                                            .padding(.top, 6)

                                        Text(cleaned)
                                            .font(.system(size: 13, weight: .regular))
                                            .foregroundColor(Theme.textPrimary)
                                            .fixedSize(horizontal: false, vertical: true)
                                        Spacer()
                                    }
                                    .padding(10)
                                    .background(RoundedRectangle(cornerRadius: 8).fill(Theme.surfaceElevated))
                                }
                            }
                        }
                        .wellnessCard()
                    }

                    // Action Buttons
                    VStack(spacing: 10) {
                        // 1-Tap Buchen Button (nutzt individuell angepasste Zutatengrößen)
                        Button(action: {
                            HapticFeedbackService.shared.commitSuccess()
                            store.depleteAndLogTemplate(effectiveTemplate)
                            bookedSuccess = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                dismiss()
                            }
                        }) {
                            HStack {
                                Image(systemName: bookedSuccess ? "checkmark" : "fork.knife")
                                    .font(.system(size: 13, weight: .bold))
                                Text(bookedSuccess ? "Gegessen & Geloggt" : "Essen")
                                    .font(.system(size: 14, weight: .bold))
                            }
                            .foregroundColor(Theme.bg)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(bookedSuccess ? Theme.warmSand : Theme.sageGreen)
                            .cornerRadius(12)
                        }

                        // Add to Shopping List Button (nutzt individuell angepasste Zutatengrößen)
                        Button(action: {
                            store.addRecipeToShoppingList(template: effectiveTemplate)
                            addedToShoppingSuccess = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                addedToShoppingSuccess = false
                            }
                        }) {
                            HStack {
                                Image(systemName: addedToShoppingSuccess ? "checkmark" : "cart.badge.plus")
                                    .font(.system(size: 13, weight: .bold))
                                Text(addedToShoppingSuccess ? "Zur Einkaufsliste hinzugefügt" : "+ Alle Zutaten zur Einkaufsliste")
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .foregroundColor(Theme.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Theme.surfaceElevated)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 1))
                        }

                        // Action Row: Customize & Edit
                        HStack(spacing: 10) {
                            Button(action: {
                                HapticFeedbackService.shared.lightDetent()
                                showingEditor = true
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "pencil")
                                        .font(.system(size: 11, weight: .bold))
                                    Text("Rezept bearbeiten")
                                        .font(.system(size: 12, weight: .semibold))
                                }
                                .foregroundColor(Theme.warmSand)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(RoundedRectangle(cornerRadius: 10).fill(Theme.surfaceElevated))
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border, lineWidth: 1))
                            }

                            Button(action: {
                                HapticFeedbackService.shared.lightDetent()
                                showingCustomizer = true
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "slider.horizontal.3")
                                        .font(.system(size: 11, weight: .bold))
                                    Text("Portionen skalieren")
                                        .font(.system(size: 12, weight: .medium))
                                }
                                .foregroundColor(Theme.textSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(RoundedRectangle(cornerRadius: 10).fill(Theme.surfaceElevated))
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border, lineWidth: 1))
                            }
                        }
                        .padding(.top, 4)

                        // Bottom Thumb-Zone Dismiss Button (iPhone 16 Pro Max Ergonomie)
                        Button(action: {
                            HapticFeedbackService.shared.lightDetent()
                            dismiss()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 13, weight: .bold))
                                Text("Schliessen")
                                    .font(.system(size: 14, weight: .bold))
                            }
                            .foregroundColor(Theme.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Theme.surfaceElevated))
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(16)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Rezept")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Schließen") {
                        dismiss()
                    }
                    .foregroundColor(Theme.warmSand)
                }
                ToolbarItem(placement: .primaryAction) {
                    HStack(spacing: 12) {
                        ShareLink(
                            item: recipeExportURL,
                            preview: SharePreview(effectiveTemplate.name)
                        ) {
                            HStack(spacing: 4) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 12))
                                Text("Export")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundColor(Theme.warmSand)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Theme.surfaceElevated))
                        }

                        Button("Bearbeiten") {
                            showingEditor = true
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Theme.sageGreen)
                    }
                }
            }
            .sheet(isPresented: $showingCustomizer) {
                CustomizeRecipeSheet(template: currentTemplate, store: store)
            }
            .sheet(isPresented: $showingEditor) {
                EditRecipeSheet(template: currentTemplate, store: store) { updated in
                    currentTemplate = updated
                }
            }
            .sheet(item: $inspectingIngredientItem) { item in
                NutritionDetailSheet(item: item)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(item: $editingPantryItem) { item in
                EditStockSheet(item: item, store: store)
            }
        }
        .presentationDragIndicator(.visible)
    }

    private func macroMetricTile(title: String, value: String, accent: Color) -> some View {
        VStack(spacing: 3) {
            Text(title)
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(Theme.textMuted)
                .tracking(0.6)
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundColor(accent)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 8).fill(Theme.surfaceElevated))
    }

    private func cleanStepText(_ text: String) -> String {
        var cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let match = cleaned.range(of: #"^(?:(?:Schritt\s+)?\d+[\.\)\:\-]\s*)+"#, options: .regularExpression) {
            cleaned.removeSubrange(match)
        }
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
