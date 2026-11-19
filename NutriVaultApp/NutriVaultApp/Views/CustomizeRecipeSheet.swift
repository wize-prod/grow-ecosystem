import SwiftUI

public struct CustomizeRecipeSheet: View {
    public let template: MealTemplate
    @ObservedObject var store: LocalStore
    @Environment(\.presentationMode) var presentationMode

    // Ingredient state: ingredient.id -> current grams
    @State private var ingredientGrams: [String: Double] = [:]

    public init(template: MealTemplate, store: LocalStore) {
        self.template = template
        self.store = store
    }

    private func getItem(for ing: TemplateIngredient) -> PantryItem? {
        return store.pantryItems.first(where: {
            $0.id == ing.pantryItemId || $0.name.lowercased() == ing.name.lowercased()
        })
    }

    private var currentTotals: (kcal: Double, protein: Double, carbs: Double, fat: Double) {
        var k = 0.0
        var p = 0.0
        var c = 0.0
        var f = 0.0

        for ing in template.ingredients {
            let g = ingredientGrams[ing.id] ?? ing.grams
            if let item = getItem(for: ing) {
                let ratio = g / 100.0
                k += item.kcal100g * ratio
                p += item.protein100g * ratio
                c += item.carbs100g * ratio
                f += item.fat100g * ratio
            }
        }
        return (k, p, c, f)
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(template.category.uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Theme.warmSand)
                        .tracking(1.0)
                    Text("Rezept anpassen")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Theme.textPrimary)
                    Text(template.name)
                        .font(.system(size: 13, weight: .medium, design: .default))
                        .foregroundColor(Theme.textSecondary)
                }
                Spacer()
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Abbrechen")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Theme.textMuted)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(Theme.surfaceElevated))
                }
            }
            .padding(16)
            .background(Theme.bg)

            Divider().background(Theme.border)

            // Live Macro Projection HUD
            let totals = currentTotals
            HStack(spacing: 8) {
                macroPill(label: "KALORIEN", val: "\(Int(totals.kcal)) kcal", color: Theme.textPrimary)
                macroPill(label: "PROTEIN", val: String(format: "%.1f g", totals.protein), color: Theme.sageGreen)
                macroPill(label: "KH", val: String(format: "%.1f g", totals.carbs), color: Theme.warmSand)
                macroPill(label: "FETT", val: String(format: "%.1f g", totals.fat), color: Theme.terracotta)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Theme.surface)

            Divider().background(Theme.border)

            // Ingredients List with Steppers
            ScrollView {
                VStack(spacing: 12) {
                    Text("ZUTATEN & MENGEN")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Theme.textMuted)
                        .tracking(0.8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 4)

                    ForEach(template.ingredients) { ing in
                        ingredientRow(ing)
                    }
                }
                .padding(16)
            }

            Divider().background(Theme.border)

            // Commit Button
            VStack(spacing: 8) {
                Button(action: {
                    commitCustomizedMeal()
                }) {
                    HStack {
                        Spacer()
                        Text("Angepasste Mahlzeit buchen")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Theme.bg)
                        Spacer()
                    }
                    .padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Theme.sageGreen))
                }
            }
            .padding(16)
            .background(Theme.surface)
        }
        .background(Theme.bg.ignoresSafeArea())
        .onAppear {
            for ing in template.ingredients {
                ingredientGrams[ing.id] = ing.grams
            }
        }
    }

    private func macroPill(label: String, val: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(Theme.textMuted)
            Text(val)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 8).fill(Theme.surfaceElevated))
    }

    private func ingredientRow(_ ing: TemplateIngredient) -> some View {
        let currentG = ingredientGrams[ing.id] ?? ing.grams
        let item = getItem(for: ing)
        let isPiece = item?.isPieceBased ?? false
        let unitWeight = item?.unitWeightGrams ?? 1.0

        let pieces = isPiece ? max(1.0, (currentG / unitWeight).rounded()) : 0.0

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(ing.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.textPrimary)
                    if let it = item {
                        Text("\(it.brand) • Vorrat: \(Int(it.currentStockQty)) \(it.unit)")
                            .font(.system(size: 11, weight: .regular, design: .default))
                            .foregroundColor(Theme.textSecondary)
                    }
                }
                Spacer()

                // Value Display
                if isPiece {
                    VStack(alignment: .trailing, spacing: 1) {
                        Text("\(Int(pieces)) \(item?.unit ?? "Stück")")
                            .font(.system(size: 15, weight: .semibold, design: .monospaced))
                            .foregroundColor(Theme.sageGreen)
                        Text("ca. \(Int(currentG)) g")
                            .font(.system(size: 10, weight: .regular, design: .monospaced))
                            .foregroundColor(Theme.textMuted)
                    }
                } else {
                    Text("\(Int(currentG)) g")
                        .font(.system(size: 15, weight: .semibold, design: .monospaced))
                        .foregroundColor(Theme.sageGreen)
                }
            }

            // Steppers
            HStack(spacing: 8) {
                if isPiece {
                    Button(action: {
                        HapticFeedbackService.shared.lightDetent()
                        let newPieces = max(1.0, pieces - 1.0)
                        ingredientGrams[ing.id] = newPieces * unitWeight
                    }) {
                        Text("- 1")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Theme.textPrimary)
                            .frame(width: 48, height: 32)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Theme.surfaceElevated))
                    }

                    Button(action: {
                        HapticFeedbackService.shared.lightDetent()
                        let newPieces = pieces + 1.0
                        ingredientGrams[ing.id] = newPieces * unitWeight
                    }) {
                        Text("+ 1")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Theme.textPrimary)
                            .frame(width: 48, height: 32)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Theme.surfaceElevated))
                    }

                    Button(action: {
                        HapticFeedbackService.shared.lightDetent()
                        let newPieces = pieces + 2.0
                        ingredientGrams[ing.id] = newPieces * unitWeight
                    }) {
                        Text("+ 2")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Theme.textPrimary)
                            .frame(width: 48, height: 32)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Theme.surfaceElevated))
                    }
                } else {
                    Button(action: {
                        HapticFeedbackService.shared.lightDetent()
                        let step = currentG > 100 ? 25.0 : 10.0
                        ingredientGrams[ing.id] = max(10.0, currentG - step)
                    }) {
                        Text(currentG > 100 ? "-25g" : "-10g")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Theme.textPrimary)
                            .frame(width: 54, height: 32)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Theme.surfaceElevated))
                    }

                    Button(action: {
                        HapticFeedbackService.shared.lightDetent()
                        let step = currentG >= 100 ? 25.0 : 10.0
                        ingredientGrams[ing.id] = currentG + step
                    }) {
                        Text(currentG >= 100 ? "+25g" : "+10g")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Theme.textPrimary)
                            .frame(width: 54, height: 32)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Theme.surfaceElevated))
                    }

                    Button(action: {
                        HapticFeedbackService.shared.lightDetent()
                        ingredientGrams[ing.id] = currentG + 50.0
                    }) {
                        Text("+50g")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Theme.textPrimary)
                            .frame(width: 54, height: 32)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Theme.surfaceElevated))
                    }
                }

                Spacer()

                // Reset to default
                Button(action: {
                    HapticFeedbackService.shared.lightDetent()
                    ingredientGrams[ing.id] = ing.grams
                }) {
                    Text("Reset")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Theme.textMuted)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                }
            }
        }
        .wellnessCard()
    }

    private func commitCustomizedMeal() {
        var payload: [(item: PantryItem, grams: Double, pieceCount: Double?)] = []

        for ing in template.ingredients {
            let g = ingredientGrams[ing.id] ?? ing.grams
            if let item = getItem(for: ing) {
                let isPiece = item.isPieceBased
                let pieces = isPiece ? max(1.0, (g / item.unitWeightGrams).rounded()) : nil
                payload.append((item: item, grams: g, pieceCount: pieces))
            }
        }

        store.depleteAndLogCustomizedTemplate(
            templateName: template.name,
            category: template.category,
            ingredients: payload
        )

        presentationMode.wrappedValue.dismiss()
    }
}
