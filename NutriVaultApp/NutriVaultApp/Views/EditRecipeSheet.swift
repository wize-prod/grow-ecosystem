import SwiftUI

public struct EditRecipeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: LocalStore

    @State private var recipeName: String
    @State private var category: String
    @State private var instructions: [String]
    @State private var ingredients: [TemplateIngredient]
    @State private var prepTimeMinutes: Int
    @State private var cookTimeMinutes: Int
    @State private var servings: Int
    @State private var cuisineType: String
    @State private var equipment: [String]
    @State private var newEquipmentText: String = ""
    @State private var longPreparationType: String
    private let isAutoRatioActive: Bool = true
    @State private var newStepText: String = ""
    @State private var showingAddIngredientSheet: Bool = false
    @State private var pantrySearchText: String = ""
    @State private var selectedImage: UIImage?
    @State private var imageFileName: String?
    @State private var showingImagePicker: Bool = false
    @State private var imagePickerSource: UIImagePickerController.SourceType = .photoLibrary

    let onSave: (MealTemplate) -> Void
    private let templateId: String
    private let isNewRecipe: Bool

    private let standardCategories = ["Frühstück", "Mittagessen", "Abendessen", "Snack", "Warm Roast", "Sweet Breakfast", "Soups & Stews", "Sandwiches & Wraps"]

    public init(template: MealTemplate, store: LocalStore, onSave: @escaping (MealTemplate) -> Void) {
        self.templateId = template.id
        self.store = store
        self.onSave = onSave
        self.isNewRecipe = template.name.isEmpty || !store.mealTemplates.contains(where: { $0.id == template.id })
        _recipeName = State(initialValue: template.name)
        _category = State(initialValue: template.category.isEmpty ? "Mittagessen" : template.category)
        _instructions = State(initialValue: template.instructions)
        _ingredients = State(initialValue: template.ingredients)
        _prepTimeMinutes = State(initialValue: template.prepTimeMinutes)
        _cookTimeMinutes = State(initialValue: template.cookTimeMinutes)
        _servings = State(initialValue: max(1, template.servings))
        _imageFileName = State(initialValue: template.imageFileName)
        _selectedImage = State(initialValue: store.getRecipeImage(filename: template.imageFileName))
        _cuisineType = State(initialValue: template.cuisineType ?? CuisineTaxonomy.inferCuisine(name: template.name, ingredients: template.ingredients.map { $0.name }))
        _equipment = State(initialValue: template.equipment.isEmpty ? EquipmentTaxonomy.inferEquipment(instructions: template.instructions, name: template.name) : template.equipment)
        _longPreparationType = State(initialValue: template.longPreparationType ?? "")
    }

    private var previewTemplate: MealTemplate {
        MealTemplate(
            id: templateId,
            name: recipeName.isEmpty ? "Neues Rezept" : recipeName,
            category: category.isEmpty ? "Mittagessen" : category,
            ingredients: ingredients,
            instructions: instructions,
            imageFileName: imageFileName,
            prepTimeMinutes: prepTimeMinutes,
            cookTimeMinutes: cookTimeMinutes,
            servings: servings,
            cuisineType: cuisineType,
            equipment: equipment,
            longPreparationType: longPreparationType.isEmpty ? nil : longPreparationType,
            imageUrl: nil
        )
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    // Header Card: Title & Category
                    VStack(alignment: .leading, spacing: 12) {
                        Text("REZEPT-STAMMDATEN")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Theme.textMuted)
                            .tracking(0.8)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Name des Rezepts")
                                .font(.system(size: 11, weight: .medium, design: .default))
                                .foregroundColor(Theme.textSecondary)
                            TextField("z.B. Protein-Rührei", text: $recipeName)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(Theme.textPrimary)
                                .padding(10)
                                .background(Theme.surfaceElevated)
                                .cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 1))
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Kategorie")
                                .font(.system(size: 11, weight: .medium, design: .default))
                                .foregroundColor(Theme.textSecondary)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    ForEach(standardCategories, id: \.self) { cat in
                                        Button(action: {
                                            HapticFeedbackService.shared.lightDetent()
                                            category = cat
                                        }) {
                                            Text(cat)
                                                .font(.system(size: 11, weight: category == cat ? .bold : .medium))
                                                .foregroundColor(category == cat ? Theme.bg : Theme.textSecondary)
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 6)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .fill(category == cat ? Theme.sageGreen : Theme.surfaceElevated)
                                                )
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .stroke(Theme.border, lineWidth: category == cat ? 0 : 1)
                                                )
                                        }
                                    }
                                }
                            }
                        }

                        // Recipe Image Section
                        VStack(alignment: .leading, spacing: 6) {
                            Text("REZEPT-FOTO")
                                .font(.system(size: 11, weight: .medium, design: .default))
                                .foregroundColor(Theme.textSecondary)

                            if let img = selectedImage {
                                ZStack(alignment: .topTrailing) {
                                    Image(uiImage: img)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(height: 140)
                                        .frame(maxWidth: .infinity)
                                        .clipped()
                                        .cornerRadius(10)
                                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border, lineWidth: 1))

                                    HStack(spacing: 6) {
                                        Button(action: {
                                            imagePickerSource = .photoLibrary
                                            showingImagePicker = true
                                        }) {
                                            Image(systemName: "pencil")
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundColor(Theme.bg)
                                                .padding(6)
                                                .background(Circle().fill(Theme.sageGreen))
                                        }

                                        Button(action: {
                                            selectedImage = nil
                                            imageFileName = nil
                                        }) {
                                            Image(systemName: "xmark")
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundColor(Theme.bg)
                                                .padding(6)
                                                .background(Circle().fill(Theme.terracotta))
                                        }
                                    }
                                    .padding(8)
                                }
                            } else {
                                Button(action: {
                                    imagePickerSource = .photoLibrary
                                    showingImagePicker = true
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "photo.badge.plus")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(Theme.warmSand)
                                        Text("Rezept-Foto hinzufügen (wird in Detailansicht gezeigt)")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(Theme.textSecondary)
                                        Spacer()
                                    }
                                    .padding(12)
                                    .background(RoundedRectangle(cornerRadius: 8).fill(Theme.surfaceElevated))
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 1))
                                }
                            }
                        }
                    }
                    .wellnessCard()

                    // Section: Länderküche & Zeitintensive Vorbereitung
                    VStack(alignment: .leading, spacing: 12) {
                        Text("LÄNDERKÜCHE & ZUBEREITUNGSMETHODE")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Theme.textMuted)
                            .tracking(0.8)

                        // Cuisine Selection
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Länderküche")
                                    .font(.system(size: 11, weight: .medium, design: .default))
                                    .foregroundColor(Theme.textSecondary)
                                Spacer()
                                Text(cuisineType)
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(Theme.sageGreen)
                            }

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    ForEach(CuisineTaxonomy.allSubCuisines, id: \.self) { sub in
                                        Button(action: {
                                            HapticFeedbackService.shared.lightDetent()
                                            cuisineType = sub
                                        }) {
                                            Text(sub)
                                                .font(.system(size: 11, weight: cuisineType == sub ? .bold : .regular))
                                                .foregroundColor(cuisineType == sub ? Theme.bg : Theme.textPrimary)
                                                .padding(.horizontal, 9)
                                                .padding(.vertical, 5)
                                                .background(RoundedRectangle(cornerRadius: 8).fill(cuisineType == sub ? Theme.sageGreen : Theme.surfaceElevated))
                                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 1))
                                        }
                                    }
                                }
                            }
                        }

                        // Long Preparation Method Selection
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Zeitintensive Methodik (Long Prep)")
                                .font(.system(size: 11, weight: .medium, design: .default))
                                .foregroundColor(Theme.textSecondary)

                            let prepMethods = [
                                "Keine",
                                "Marinieren & Beizen",
                                "Pökeln & Brining",
                                "Schmoren & Braising",
                                "Fermentieren & Proofing",
                                "Ruhen & Aging"
                            ]

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    ForEach(prepMethods, id: \.self) { method in
                                        let isSel = (method == "Keine" && longPreparationType.isEmpty) || (longPreparationType == method)
                                        Button(action: {
                                            HapticFeedbackService.shared.lightDetent()
                                            longPreparationType = (method == "Keine") ? "" : method
                                        }) {
                                            HStack(spacing: 3) {
                                                if method != "Keine" {
                                                    Image(systemName: "hourglass.badge.gearshape")
                                                        .font(.system(size: 9))
                                                }
                                                Text(method)
                                                    .font(.system(size: 11, weight: isSel ? .bold : .regular))
                                            }
                                            .foregroundColor(isSel ? Theme.bg : Theme.textPrimary)
                                            .padding(.horizontal, 9)
                                            .padding(.vertical, 5)
                                            .background(RoundedRectangle(cornerRadius: 8).fill(isSel ? Theme.warmSand : Theme.surfaceElevated))
                                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 1))
                                        }
                                    }
                                }
                            }
                        }

                        // Equipment Section
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Benötigte Küchenausstattung")
                                .font(.system(size: 11, weight: .medium, design: .default))
                                .foregroundColor(Theme.textSecondary)

                            if !equipment.isEmpty {
                                FlowLayout(spacing: 6) {
                                    ForEach(equipment, id: \.self) { eq in
                                        HStack(spacing: 4) {
                                            Text(eq)
                                                .font(.system(size: 11, weight: .medium))
                                                .foregroundColor(Theme.textPrimary)
                                            Button(action: {
                                                HapticFeedbackService.shared.lightDetent()
                                                equipment.removeAll(where: { $0 == eq })
                                            }) {
                                                Image(systemName: "xmark")
                                                    .font(.system(size: 8, weight: .bold))
                                                    .foregroundColor(Theme.textMuted)
                                            }
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(RoundedRectangle(cornerRadius: 6).fill(Theme.surfaceElevated))
                                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.border, lineWidth: 1))
                                    }
                                }
                            }

                            // Add Equipment Field
                            HStack(spacing: 6) {
                                TextField("z.B. Wok, Gusseisenpfanne...", text: $newEquipmentText)
                                    .font(.system(size: 12))
                                    .foregroundColor(Theme.textPrimary)
                                    .padding(8)
                                    .background(Theme.surfaceElevated)
                                    .cornerRadius(6)
                                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.border, lineWidth: 1))

                                Button(action: {
                                    let trimmed = newEquipmentText.trimmingCharacters(in: .whitespaces)
                                    guard !trimmed.isEmpty else { return }
                                    if !equipment.contains(trimmed) {
                                        equipment.append(trimmed)
                                    }
                                    newEquipmentText = ""
                                }) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(Theme.bg)
                                        .padding(8)
                                        .background(RoundedRectangle(cornerRadius: 6).fill(Theme.sageGreen))
                                }
                            }
                        }
                    }
                    .wellnessCard()

                    // Section: Zeitaufwand & Portionen
                    VStack(alignment: .leading, spacing: 12) {
                        Text("ZEITAUFWAND & PORTIONEN")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Theme.textMuted)
                            .tracking(0.8)

                        HStack(spacing: 8) {
                            // Prep Time
                            VStack(alignment: .center, spacing: 4) {
                                Text("VORBEREITUNG")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(Theme.textMuted)
                                HStack(spacing: 4) {
                                    Button(action: {
                                        HapticFeedbackService.shared.lightDetent()
                                        prepTimeMinutes = max(0, prepTimeMinutes - 5)
                                    }) {
                                        Image(systemName: "minus")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(Theme.textPrimary)
                                            .frame(width: 22, height: 22)
                                            .background(Circle().fill(Theme.surfaceElevated))
                                    }
                                    Text("\(prepTimeMinutes)m")
                                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                                        .foregroundColor(Theme.warmSand)
                                        .frame(minWidth: 32)
                                    Button(action: {
                                        HapticFeedbackService.shared.lightDetent()
                                        prepTimeMinutes += 5
                                    }) {
                                        Image(systemName: "plus")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(Theme.textPrimary)
                                            .frame(width: 22, height: 22)
                                            .background(Circle().fill(Theme.surfaceElevated))
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Theme.surfaceElevated))

                            // Cook Time
                            VStack(alignment: .center, spacing: 4) {
                                Text("KOCHEN/BACKEN")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(Theme.textMuted)
                                HStack(spacing: 4) {
                                    Button(action: {
                                        HapticFeedbackService.shared.lightDetent()
                                        cookTimeMinutes = max(0, cookTimeMinutes - 5)
                                    }) {
                                        Image(systemName: "minus")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(Theme.textPrimary)
                                            .frame(width: 22, height: 22)
                                            .background(Circle().fill(Theme.surfaceElevated))
                                    }
                                    Text("\(cookTimeMinutes)m")
                                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                                        .foregroundColor(Theme.warmSand)
                                        .frame(minWidth: 32)
                                    Button(action: {
                                        HapticFeedbackService.shared.lightDetent()
                                        cookTimeMinutes += 5
                                    }) {
                                        Image(systemName: "plus")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(Theme.textPrimary)
                                            .frame(width: 22, height: 22)
                                            .background(Circle().fill(Theme.surfaceElevated))
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Theme.surfaceElevated))

                            // Total Time
                            VStack(alignment: .center, spacing: 4) {
                                Text("GESAMTZEIT")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(Theme.textMuted)
                                Text("\(prepTimeMinutes + cookTimeMinutes)m")
                                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                                    .foregroundColor(Theme.sageGreen)
                                    .padding(.vertical, 3)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Theme.surfaceElevated))

                            // Servings
                            VStack(alignment: .center, spacing: 4) {
                                Text("PORTIONEN")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(Theme.textMuted)
                                HStack(spacing: 4) {
                                    Button(action: {
                                        HapticFeedbackService.shared.lightDetent()
                                        servings = max(1, servings - 1)
                                    }) {
                                        Image(systemName: "minus")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(Theme.textPrimary)
                                            .frame(width: 22, height: 22)
                                            .background(Circle().fill(Theme.surfaceElevated))
                                    }
                                    Text("\(servings)")
                                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                                        .foregroundColor(Theme.textPrimary)
                                        .frame(minWidth: 20)
                                    Button(action: {
                                        HapticFeedbackService.shared.lightDetent()
                                        servings += 1
                                    }) {
                                        Image(systemName: "plus")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(Theme.textPrimary)
                                            .frame(width: 22, height: 22)
                                            .background(Circle().fill(Theme.surfaceElevated))
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Theme.surfaceElevated))
                        }
                    }
                    .wellnessCard()

                    // Live Projected Macros & Cost
                    let prev = previewTemplate
                    let tKcal = store.templateKcal(for: prev)
                    let tProt = store.templateProtein(for: prev)
                    let tCarb = store.templateCarbs(for: prev)
                    let tFat = store.templateFat(for: prev)
                    let tPrice = store.templatePrice(for: prev)

                    HStack(spacing: 6) {
                        macroMetricTile(title: "PROTEIN", value: String(format: "%.1f g", tProt), accent: Theme.sageGreen)
                        macroMetricTile(title: "ENERGIE", value: "\(Int(tKcal)) kcal", accent: Theme.textPrimary)
                        macroMetricTile(title: "CARBS", value: "\(Int(tCarb)) g", accent: Theme.textSecondary)
                        macroMetricTile(title: "FETT", value: "\(Int(tFat)) g", accent: Theme.textSecondary)
                        if let pr = tPrice {
                            macroMetricTile(title: "KOSTEN", value: String(format: "%.2f €", pr), accent: Theme.warmSand)
                        }
                    }

                    // Section 1: Zubereitungsschritte (Preparation Steps)
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("ZUBEREITUNGSSCHRITTE")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Theme.textMuted)
                                .tracking(0.8)
                            Spacer()
                            Text("\(instructions.count) Schritte")
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundColor(Theme.textSecondary)
                        }

                        if instructions.isEmpty {
                            Text("Noch keine Zubereitungsschritte vorhanden.")
                                .font(.system(size: 12, weight: .regular, design: .default))
                                .foregroundColor(Theme.textMuted)
                                .padding(.vertical, 8)
                        } else {
                            VStack(spacing: 10) {
                                ForEach(Array(instructions.enumerated()), id: \.offset) { idx, step in
                                    stepEditRow(index: idx, text: step)
                                }
                            }
                        }

                        // Add new step input field
                        VStack(spacing: 8) {
                            HStack(alignment: .top, spacing: 8) {
                                TextField("Neuen Zubereitungsschritt eingeben...", text: $newStepText, axis: .vertical)
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(Theme.textPrimary)
                                    .lineLimit(2...5)
                                    .padding(8)
                                    .background(Theme.surfaceElevated)
                                    .cornerRadius(8)
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 1))

                                Button(action: {
                                    addNewStep()
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(newStepText.trimmingCharacters(in: .whitespaces).isEmpty ? Theme.textMuted : Theme.sageGreen)
                                }
                                .disabled(newStepText.trimmingCharacters(in: .whitespaces).isEmpty)
                                .padding(.top, 4)
                            }
                        }
                        .padding(.top, 6)
                    }
                    .wellnessCard()

                    // Section 2: Zutaten (Ingredients)
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("ZUTATEN DES REZEPTS")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Theme.textMuted)
                                .tracking(0.8)
                            Spacer()
                            Text("\(ingredients.count) Zutaten")
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundColor(Theme.textSecondary)
                        }

                        // Background Ratio Calculator Banner (Always-on Engine - Zero-Button Requirement)
                        HStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(Theme.sageGreen.opacity(0.18))
                                    .frame(width: 22, height: 22)
                                Image(systemName: "scalemass.fill")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(Theme.sageGreen)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text("Automatischer Rations-Rechner")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(Theme.textPrimary)
                                    HStack(spacing: 3) {
                                        Circle()
                                            .fill(Theme.sageGreen)
                                            .frame(width: 5, height: 5)
                                        Text("Aktiv (Hintergrund)")
                                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                                            .foregroundColor(Theme.sageGreen)
                                    }
                                }
                                Text("Skaliert bei Mengenaenderung einer Zutat alle weiteren Zutaten proportional im Hintergrund mit.")
                                    .font(.system(size: 10, weight: .regular))
                                    .foregroundColor(Theme.textMuted)
                            }
                            Spacer()
                        }
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Theme.surfaceElevated))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.sageGreen.opacity(0.3), lineWidth: 1))

                        VStack(spacing: 8) {
                            ForEach(Array(ingredients.enumerated()), id: \.element.id) { idx, ing in
                                ingredientEditRow(index: idx, ingredient: ing)
                            }
                        }

                        Button(action: {
                            HapticFeedbackService.shared.lightDetent()
                            showingAddIngredientSheet = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle")
                                Text("Zutat aus Vorratskammer hinzufügen")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundColor(Theme.warmSand)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Theme.surfaceElevated))
                        }
                        .padding(.top, 4)
                    }
                    .wellnessCard()
                }
                .padding(16)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle(isNewRecipe ? "Neues Rezept erstellen" : "Rezept bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                    .foregroundColor(Theme.textMuted)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isNewRecipe ? "Erstellen" : "Speichern") {
                        saveChanges()
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Theme.sageGreen)
                }
            }
            .sheet(isPresented: $showingAddIngredientSheet) {
                addIngredientPickerView
            }
            .sheet(isPresented: $showingImagePicker) {
                ReceiptImagePicker(sourceType: imagePickerSource) { img in
                    selectedImage = img
                    showingImagePicker = false
                }
            }
        }
    }

    // MARK: - Step Row View
    private func stepEditRow(index: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                .fill(Theme.sageGreen)
                .frame(width: 8, height: 8)
                .padding(.top, 12)

            TextField("Zubereitungsschritt", text: Binding(
                get: {
                    if index < instructions.count { return instructions[index] }
                    return ""
                },
                set: { newVal in
                    if index < instructions.count {
                        instructions[index] = newVal
                    }
                }
            ), axis: .vertical)
            .font(.system(size: 13, weight: .regular))
            .foregroundColor(Theme.textPrimary)
            .lineLimit(1...6)
            .padding(8)
            .background(Theme.surfaceElevated)
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 1))

            VStack(spacing: 4) {
                if index > 0 {
                    Button(action: {
                        HapticFeedbackService.shared.lightDetent()
                        instructions.swapAt(index, index - 1)
                    }) {
                        Image(systemName: "chevron.up")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Theme.textSecondary)
                            .frame(width: 24, height: 20)
                    }
                }

                if index < instructions.count - 1 {
                    Button(action: {
                        HapticFeedbackService.shared.lightDetent()
                        instructions.swapAt(index, index + 1)
                    }) {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Theme.textSecondary)
                            .frame(width: 24, height: 20)
                    }
                }

                Button(action: {
                    HapticFeedbackService.shared.mechanicalClick()
                    instructions.remove(at: index)
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.terracotta)
                        .frame(width: 24, height: 20)
                }
            }
            .padding(.top, 4)
        }
    }

    // MARK: - Ingredient Row View
    private let selectableUnits = ["g", "ml", "l", "kg", "mg", "Stk"]

    private func ingredientEditRow(index: Int, ingredient: TemplateIngredient) -> some View {
        let pantryMatch = store.pantryItems.first(where: {
            $0.id == ingredient.pantryItemId || $0.name.lowercased() == ingredient.name.lowercased()
        })
        let currentUnit = ingredient.unit ?? (pantryMatch?.isPieceBased == true ? (pantryMatch?.unit ?? "Stk") : (pantryMatch?.isLiterUnit == true ? "ml" : "g"))

        return HStack(spacing: 8) {
            Button(action: {
                HapticFeedbackService.shared.lightDetent()
                dismiss()
                if let match = pantryMatch {
                    store.navigateToPantryItemInVorratskammer(match)
                } else {
                    store.navigateToPantrySearchInVorratskammer(ingredient.name)
                }
            }) {
                HStack(spacing: 6) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text(ingredient.name)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Theme.textPrimary)
                                .lineLimit(1)
                            Image(systemName: "arrow.up.right.square")
                                .font(.system(size: 10))
                                .foregroundColor(Theme.sageGreen)
                        }
                        if let brand = pantryMatch?.brand, !brand.isEmpty {
                            Text("\(brand) • In Vorratskammer anzeigen")
                                .font(.system(size: 10, weight: .regular))
                                .foregroundColor(Theme.sageGreen)
                        } else {
                            Text("In Vorratskammer anzeigen")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(Theme.sageGreen.opacity(0.85))
                        }
                    }
                }
            }
            .buttonStyle(.plain)

            Spacer()

            HStack(spacing: 4) {
                TextField("Menge", value: Binding(
                    get: {
                        if index < ingredients.count {
                            return ingredients[index].displayAmount
                        }
                        return 0.0
                    },
                    set: { newVal in
                        if index < ingredients.count {
                            let u = ingredients[index].unit ?? currentUnit
                            handleAmountChange(index: index, newAmount: newVal, unit: u)
                        }
                    }
                ), format: .number)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundColor(Theme.warmSand)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .frame(width: 60)
                .padding(.vertical, 4)
                .background(Theme.surfaceElevated)
                .cornerRadius(6)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.border, lineWidth: 1))

                // Unit Picker Menu
                Menu {
                    ForEach(selectableUnits, id: \.self) { u in
                        Button(action: {
                            HapticFeedbackService.shared.lightDetent()
                            if index < ingredients.count {
                                ingredients[index].unit = u
                                let amt = ingredients[index].displayAmount
                                ingredients[index].grams = TemplateIngredient.toNormalizedGrams(amount: amt, unit: u)
                            }
                        }) {
                            HStack {
                                Text(u)
                                if currentUnit == u {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 2) {
                        Text(currentUnit)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Theme.sageGreen)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundColor(Theme.textMuted)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Theme.surfaceElevated))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.border, lineWidth: 1))
                }
            }

            Button(action: {
                HapticFeedbackService.shared.mechanicalClick()
                ingredients.remove(at: index)
            }) {
                Image(systemName: "trash")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.terracotta)
                    .frame(width: 24, height: 24)
            }
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 8).fill(Theme.surfaceElevated))
    }

    // MARK: - Add Ingredient Picker
    private var addIngredientPickerView: some View {
        NavigationStack {
            VStack(spacing: 10) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Theme.textMuted)
                    TextField("Lebensmittel suchen...", text: $pantrySearchText)
                        .foregroundColor(Theme.textPrimary)
                }
                .padding(10)
                .background(Theme.surfaceElevated)
                .cornerRadius(10)
                .padding(.horizontal, 16)
                .padding(.top, 12)

                List {
                    ForEach(filteredPantryItems) { pItem in
                        Button(action: {
                            addPantryItemToRecipe(pItem)
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(pItem.name)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(Theme.textPrimary)
                                    Text("\(pItem.brand) • \(Int(pItem.kcal100g)) kcal • \(String(format: "%.1f", pItem.protein100g))g Protein")
                                        .font(.system(size: 10, weight: .regular, design: .default))
                                        .foregroundColor(Theme.textMuted)
                                }
                                Spacer()
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(Theme.sageGreen)
                            }
                        }
                        .listRowBackground(Theme.surface)
                    }
                }
                .listStyle(.plain)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Zutat wählen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Schließen") {
                        showingAddIngredientSheet = false
                    }
                    .foregroundColor(Theme.warmSand)
                }
            }
        }
    }

    private var filteredPantryItems: [PantryItem] {
        let q = pantrySearchText.trimmingCharacters(in: .whitespaces).lowercased()
        if q.isEmpty { return store.pantryItems }
        return store.pantryItems.filter { $0.name.lowercased().contains(q) || $0.brand.lowercased().contains(q) }
    }

    private func addPantryItemToRecipe(_ pItem: PantryItem) {
        HapticFeedbackService.shared.commitSuccess()
        let defaultUnit = pItem.isPieceBased ? (pItem.unit.isEmpty ? "Stk" : pItem.unit) : (pItem.isLiterUnit ? "ml" : "g")
        let defaultAmt: Double = pItem.isPieceBased ? 1.0 : (pItem.isLiterUnit ? 50.0 : 100.0)
        let normalizedG = TemplateIngredient.toNormalizedGrams(amount: defaultAmt, unit: defaultUnit)
        let newIng = TemplateIngredient(
            pantryItemId: pItem.id,
            name: pItem.name,
            grams: normalizedG,
            unit: defaultUnit,
            rawAmount: defaultAmt
        )
        ingredients.append(newIng)
        showingAddIngredientSheet = false
    }

    private func cleanStepText(_ text: String) -> String {
        var cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let match = cleaned.range(of: #"^(?:(?:Schritt\s+)?\d+[\.\)\:\-]\s*)+"#, options: .regularExpression) {
            cleaned.removeSubrange(match)
        }
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func addNewStep() {
        let clean = cleanStepText(newStepText)
        guard !clean.isEmpty else { return }
        HapticFeedbackService.shared.lightDetent()
        instructions.append(clean)
        newStepText = ""
    }

    private func saveChanges() {
        var savedFileName = imageFileName
        if let img = selectedImage {
            savedFileName = store.saveRecipeImage(img, templateId: templateId)
        } else {
            savedFileName = nil
        }

        let cleanedInstructions = instructions
            .map { cleanStepText($0) }
            .filter { !$0.isEmpty }

        let finalTemplate = MealTemplate(
            id: templateId,
            name: recipeName.trimmingCharacters(in: .whitespaces).isEmpty ? "Rezept" : recipeName,
            category: category,
            ingredients: ingredients,
            instructions: cleanedInstructions,
            imageFileName: savedFileName,
            prepTimeMinutes: prepTimeMinutes,
            cookTimeMinutes: cookTimeMinutes,
            servings: servings,
            cuisineType: cuisineType,
            equipment: equipment,
            longPreparationType: longPreparationType.isEmpty ? nil : longPreparationType,
            imageUrl: nil
        )
        store.updateMealTemplate(finalTemplate)
        onSave(finalTemplate)
        dismiss()
    }

    private func handleAmountChange(index: Int, newAmount: Double, unit: String) {
        guard index < ingredients.count else { return }
        let oldAmount = ingredients[index].displayAmount
        let amt = max(0.0, newAmount)

        ingredients[index].rawAmount = amt
        ingredients[index].unit = unit
        ingredients[index].grams = TemplateIngredient.toNormalizedGrams(amount: amt, unit: unit)

        if isAutoRatioActive && oldAmount > 0 && amt > 0 && ingredients.count > 1 {
            let factor = amt / oldAmount
            for i in 0..<ingredients.count where i != index {
                let currentAmt = ingredients[i].displayAmount
                if currentAmt > 0 {
                    let scaledAmt = (currentAmt * factor * 10).rounded() / 10.0
                    ingredients[i].rawAmount = scaledAmt
                    let u = ingredients[i].unit ?? unit
                    ingredients[i].grams = TemplateIngredient.toNormalizedGrams(amount: scaledAmt, unit: u)
                }
            }
        }
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
}
