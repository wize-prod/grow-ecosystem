import SwiftUI

// MARK: - Quick Add Meal Sheet (Food & Recipe Picker with Bottom Search & EAN Barcode Scanner)
public struct QuickAddMealSheet: View {
    public let targetDate: Date
    @ObservedObject var store: LocalStore
    public let onSelectPantryItem: (PantryItem) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var searchText: String = ""
    @State private var selectedFilter: MealPickerCategory = .all
    @State private var showingBarcodeScanner: Bool = false
    @State private var scannedFeedbackBanner: String? = nil

    enum MealPickerCategory: String, CaseIterable {
        case all = "Alle"
        case food = "Lebensmittel"
        case recipes = "Rezepte"
    }

    public init(targetDate: Date, store: LocalStore, onSelectPantryItem: @escaping (PantryItem) -> Void) {
        self.targetDate = targetDate
        self.store = store
        self.onSelectPantryItem = onSelectPantryItem
    }

    private var filteredItems: [PantryItem] {
        var items = store.pantryItems
        if !searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            let q = searchText.lowercased()
            items = items.filter { $0.name.lowercased().contains(q) || $0.brand.lowercased().contains(q) || $0.store.lowercased().contains(q) || $0.barcode.contains(q) }
        }
        return items
    }

    private var filteredTemplates: [MealTemplate] {
        var templates = store.mealTemplates
        if !searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            let q = searchText.lowercased()
            templates = templates.filter {
                $0.name.lowercased().contains(q) ||
                $0.category.lowercased().contains(q) ||
                $0.ingredients.contains { $0.name.lowercased().contains(q) }
            }
        }
        return templates
    }

    private var formattedDateString: String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "de_DE")
        df.dateFormat = "EEEE, d. MMMM yyyy"
        return df.string(from: targetDate)
    }

    public var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                VStack(spacing: 10) {
                    // Header Target Date & Category Segment
                    VStack(spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("NACHTRAGEN / ERFASSEN FUER")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(Theme.warmSand)
                                    .tracking(1.0)
                                Text(formattedDateString)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(Theme.textPrimary)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 4)

                        // Segmented Filter
                        HStack(spacing: 6) {
                            ForEach(MealPickerCategory.allCases, id: \.self) { cat in
                                Button {
                                    HapticFeedbackService.shared.lightDetent()
                                    selectedFilter = cat
                                } label: {
                                    Text(cat.rawValue)
                                        .font(.system(size: 12, weight: selectedFilter == cat ? .bold : .medium))
                                        .foregroundColor(selectedFilter == cat ? Theme.textPrimary : Theme.textSecondary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 7)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(selectedFilter == cat ? Theme.surfaceElevated : Color.clear)
                                        )
                                }
                            }
                        }
                        .padding(3)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Theme.surface))
                        .padding(.horizontal, 16)
                    }

                    if let banner = scannedFeedbackBanner {
                        HStack(spacing: 6) {
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(Theme.warmSand)
                            Text(banner)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Theme.warmSand)
                            Spacer()
                            Button {
                                scannedFeedbackBanner = nil
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(Theme.textMuted)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Theme.warmSand.opacity(0.12)))
                        .padding(.horizontal, 16)
                    }

                    // Scrollable List of Recipes & Foods
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            // Recipes Section
                            if selectedFilter == .all || selectedFilter == .recipes {
                                if !filteredTemplates.isEmpty {
                                    HStack {
                                        Text("REZEPTE (\(filteredTemplates.count))")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(Theme.sageGreen)
                                            .tracking(1.0)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 4)
                                    .padding(.top, 4)

                                    ForEach(filteredTemplates.prefix(searchText.isEmpty ? 50 : 250)) { tmpl in
                                        recipeCardRow(tmpl)
                                    }
                                }
                            }

                            // Pantry Food Items Section
                            if selectedFilter == .all || selectedFilter == .food {
                                if !filteredItems.isEmpty {
                                    HStack {
                                        Text("LEBENSMITTEL AUS VORRAT (\(filteredItems.count))")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(Theme.warmSand)
                                            .tracking(1.0)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 4)
                                    .padding(.top, 8)

                                    ForEach(filteredItems.prefix(searchText.isEmpty ? 50 : 250)) { item in
                                        pantryItemRow(item)
                                    }
                                }
                            }

                            if (selectedFilter == .recipes && filteredTemplates.isEmpty) ||
                               (selectedFilter == .food && filteredItems.isEmpty) ||
                               (selectedFilter == .all && filteredTemplates.isEmpty && filteredItems.isEmpty) {
                                VStack(spacing: 6) {
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 24))
                                        .foregroundColor(Theme.textMuted)
                                    Text("Keine passenden Einträge gefunden")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(Theme.textMuted)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                            }

                            // Bottom spacer so content doesn't get covered by docked bottom bar
                            Spacer().frame(height: 72)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 4)
                    }
                }

                // Docked Bottom Search Bar with Circular Scanner Button
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(Theme.border.opacity(0.7))
                        .frame(height: 1)

                    HStack(spacing: 10) {
                        // Search Bar TextField
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(Theme.textMuted)
                                .font(.system(size: 14))
                            TextField("Lebensmittel oder Rezept suchen...", text: $searchText)
                                .font(.system(size: 13))
                                .foregroundColor(Theme.textPrimary)
                            if !searchText.isEmpty {
                                Button { searchText = "" } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(Theme.textMuted)
                                        .font(.system(size: 13))
                                }
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Theme.surfaceElevated))

                        // Circular Scanner Button
                        Button {
                            HapticFeedbackService.shared.lightDetent()
                            showingBarcodeScanner = true
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Theme.sageGreen)
                                    .frame(width: 42, height: 42)
                                Image(systemName: "barcode.viewfinder")
                                    .font(.system(size: 19, weight: .semibold))
                                    .foregroundColor(Theme.bg)
                            }
                        }
                        .accessibilityLabel("EAN Barcode scannen")
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 6)
                    .background(Theme.surface.ignoresSafeArea(edges: .bottom))
                }
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Mahlzeit erfassen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Schliessen") {
                        dismiss()
                    }
                    .foregroundColor(Theme.textSecondary)
                }
            }
            .sheet(isPresented: $showingBarcodeScanner) {
                BarcodeScannerView { code in
                    showingBarcodeScanner = false
                    let clean = code.trimmingCharacters(in: .whitespacesAndNewlines)
                    if let match = store.pantryItems.first(where: { $0.barcode == clean || $0.id == clean }) {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            onSelectPantryItem(match)
                        }
                    } else {
                        searchText = clean
                        scannedFeedbackBanner = "EAN \(clean) nicht im Vorrat hinterlegt. Suche angepasst."
                        HapticFeedbackService.shared.lightDetent()
                    }
                }
            }
        }
    }

    // MARK: - Recipe Card Row
    private func recipeCardRow(_ tmpl: MealTemplate) -> some View {
        Button {
            HapticFeedbackService.shared.commitSuccess()
            store.depleteAndLogTemplate(tmpl)
            dismiss()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(tmpl.name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Theme.textPrimary)
                        .lineLimit(1)
                    let macros = store.templateMacros(for: tmpl)
                    HStack(spacing: 6) {
                        Text("\(Int(macros.kcal)) kcal")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(Theme.textSecondary)
                        Text("•")
                            .foregroundColor(Theme.textMuted)
                        Text("\(String(format: "%.1f", macros.protein))g P")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(Theme.sageGreen)
                        Text("•")
                            .foregroundColor(Theme.textMuted)
                        Text("\(String(format: "%.1f", macros.carbs))g K")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(Theme.warmSand)
                        Text("•")
                            .foregroundColor(Theme.textMuted)
                        Text("\(String(format: "%.1f", macros.fat))g F")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(Theme.textSecondary)
                    }
                }
                Spacer()
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Theme.sageGreen)
            }
            .padding(12)
            .wellnessCard()
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Pantry Item Row
    private func pantryItemRow(_ item: PantryItem) -> some View {
        Button {
            HapticFeedbackService.shared.lightDetent()
            dismiss()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                onSelectPantryItem(item)
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Theme.textPrimary)
                        .lineLimit(1)
                    HStack(spacing: 6) {
                        if !item.brand.isEmpty && item.brand.uppercased() != "PANTRY" {
                            Text(item.brand)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(Theme.warmSand)
                            Text("•")
                                .foregroundColor(Theme.textMuted)
                        }
                        Text("\(Int(item.kcal100g)) kcal")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(Theme.textSecondary)
                        Text("•")
                            .foregroundColor(Theme.textMuted)
                        Text("\(String(format: "%.1f", item.protein100g))g P")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(Theme.sageGreen)
                    }
                }
                Spacer()
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Theme.warmSand)
            }
            .padding(12)
            .wellnessCard()
        }
        .buttonStyle(PlainButtonStyle())
    }
}




