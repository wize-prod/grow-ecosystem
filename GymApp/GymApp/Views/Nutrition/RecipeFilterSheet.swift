import SwiftUI

public enum RecipeSortOption: String, CaseIterable, Codable {
    case none = "Standard"
    case proteinDesc = "Protein (höchste zuerst)"
    case priceAsc = "Preis (günstigste zuerst)"
    case kcalAsc = "Kalorien (niedrigste zuerst)"
    case kcalDesc = "Kalorien (höchste zuerst)"
    case carbsDesc = "Kohlenhydrate"
    case fatDesc = "Fett"
}

public struct RecipeFilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedCategory: String
    @Binding var selectedCuisine: String
    @Binding var selectedEquipment: String
    @Binding var sortOption: RecipeSortOption
    @Binding var minProtein: Double
    @Binding var maxPrice: Double
    @Binding var maxKcal: Double
    @Binding var maxCarbs: Double
    @Binding var maxFat: Double

    private let categories = ["ALLE", "Frühstück", "Mittagessen", "Abendessen", "Snack"]
    private let equipmentOptions = [
        "ALLE",
        "Backofen",
        "AirFryer",
        "Pfanne",
        "Kochtopf",
        "Schmortopf / Bräter",
        "Pürierstab / Mixer",
        "Kein Kochen / Kalt"
    ]

    public init(
        selectedCategory: Binding<String>,
        selectedCuisine: Binding<String>,
        selectedEquipment: Binding<String> = .constant("ALLE"),
        sortOption: Binding<RecipeSortOption>,
        minProtein: Binding<Double>,
        maxPrice: Binding<Double>,
        maxKcal: Binding<Double>,
        maxCarbs: Binding<Double>,
        maxFat: Binding<Double>
    ) {
        self._selectedCategory = selectedCategory
        self._selectedCuisine = selectedCuisine
        self._selectedEquipment = selectedEquipment
        self._sortOption = sortOption
        self._minProtein = minProtein
        self._maxPrice = maxPrice
        self._maxKcal = maxKcal
        self._maxCarbs = maxCarbs
        self._maxFat = maxFat
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        // Section: Category
                        VStack(alignment: .leading, spacing: 10) {
                            Text("MAHLZEITEN-KATEGORIE")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Theme.warmSand)
                                .tracking(0.8)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(categories, id: \.self) { cat in
                                        Button(action: {
                                            HapticFeedbackService.shared.lightDetent()
                                            selectedCategory = cat
                                        }) {
                                            Text(cat)
                                                .font(.system(size: 12, weight: selectedCategory == cat ? .bold : .medium))
                                                .foregroundColor(selectedCategory == cat ? Theme.bg : Theme.textPrimary)
                                                .padding(.horizontal, 14)
                                                .padding(.vertical, 8)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .fill(selectedCategory == cat ? Theme.warmSand : Theme.surfaceElevated)
                                                )
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(selectedCategory == cat ? Theme.warmSand : Theme.border, lineWidth: 1)
                                                )
                                        }
                                    }
                                }
                            }
                        }
                        .wellnessCard()

                        // Section: Cuisine Type
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("LÄNDERKÜCHE / CUISINE")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(Theme.warmSand)
                                    .tracking(0.8)
                                Spacer()
                                Text(selectedCuisine == "ALLE" ? "Alle Küchen" : selectedCuisine)
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(Theme.sageGreen)
                            }

                            // Horizontal Pill for "ALLE" + Regions
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    Button(action: {
                                        HapticFeedbackService.shared.lightDetent()
                                        selectedCuisine = "ALLE"
                                    }) {
                                        Text("ALLE")
                                            .font(.system(size: 11, weight: selectedCuisine == "ALLE" ? .bold : .medium))
                                            .foregroundColor(selectedCuisine == "ALLE" ? Theme.bg : Theme.textPrimary)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(RoundedRectangle(cornerRadius: 8).fill(selectedCuisine == "ALLE" ? Theme.sageGreen : Theme.surfaceElevated))
                                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 1))
                                    }

                                    ForEach(CuisineTaxonomy.regions) { region in
                                        Button(action: {
                                            HapticFeedbackService.shared.lightDetent()
                                            selectedCuisine = region.name
                                        }) {
                                            Text(region.name)
                                                .font(.system(size: 11, weight: selectedCuisine == region.name ? .bold : .medium))
                                                .foregroundColor(selectedCuisine == region.name ? Theme.bg : Theme.textPrimary)
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 6)
                                                .background(RoundedRectangle(cornerRadius: 8).fill(selectedCuisine == region.name ? Theme.warmSand : Theme.surfaceElevated))
                                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 1))
                                        }
                                    }
                                }
                            }

                            // Sub-cuisines grouped by active region or full expandable list
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(CuisineTaxonomy.regions) { region in
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(region.name.uppercased())
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundColor(Theme.textMuted)
                                            .padding(.top, 2)

                                        FilterFlowLayout(spacing: 6) {
                                            ForEach(region.subCuisines, id: \.self) { sub in
                                                Button(action: {
                                                    HapticFeedbackService.shared.lightDetent()
                                                    selectedCuisine = sub
                                                }) {
                                                    Text(sub)
                                                        .font(.system(size: 11, weight: selectedCuisine == sub ? .bold : .regular))
                                                        .foregroundColor(selectedCuisine == sub ? Theme.bg : Theme.textSecondary)
                                                        .padding(.horizontal, 8)
                                                        .padding(.vertical, 5)
                                                        .background(RoundedRectangle(cornerRadius: 6).fill(selectedCuisine == sub ? Theme.sageGreen : Theme.surfaceElevated))
                                                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(selectedCuisine == sub ? Theme.sageGreen : Theme.border, lineWidth: 1))
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .wellnessCard()

                        // Section: Equipment / Preparation Method
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("ZUBEREITUNG & GERÄTE (EQUIPMENT)")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(Theme.warmSand)
                                    .tracking(0.8)
                                Spacer()
                                Text(selectedEquipment == "ALLE" ? "Alle Geräte" : selectedEquipment)
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(Theme.sageGreen)
                            }

                            FilterFlowLayout(spacing: 6) {
                                ForEach(equipmentOptions, id: \.self) { equip in
                                    Button(action: {
                                        HapticFeedbackService.shared.lightDetent()
                                        selectedEquipment = equip
                                    }) {
                                        HStack(spacing: 4) {
                                            if equip == "Backofen" {
                                                Image(systemName: "flame.fill")
                                            } else if equip == "AirFryer" {
                                                Image(systemName: "wind")
                                            } else if equip == "Pfanne" {
                                                Image(systemName: "frying.pan.fill")
                                            } else if equip == "Kochtopf" {
                                                Image(systemName: "cooktop.fill")
                                            } else if equip == "Schmortopf / Bräter" {
                                                Image(systemName: "oval.portrait.fill")
                                            } else if equip == "Pürierstab / Mixer" {
                                                Image(systemName: "blender.fill")
                                            } else if equip == "Kein Kochen / Kalt" {
                                                Image(systemName: "leaf.fill")
                                            }
                                            Text(equip)
                                        }
                                        .font(.system(size: 11, weight: selectedEquipment == equip ? .bold : .medium))
                                        .foregroundColor(selectedEquipment == equip ? Theme.bg : Theme.textPrimary)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 7)
                                        .background(RoundedRectangle(cornerRadius: 8).fill(selectedEquipment == equip ? Theme.warmSand : Theme.surfaceElevated))
                                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(selectedEquipment == equip ? Theme.warmSand : Theme.border, lineWidth: 1))
                                    }
                                }
                            }
                        }
                        .wellnessCard()

                        // Section: Sort Order
                        VStack(alignment: .leading, spacing: 10) {
                            Text("SORTIERUNG")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Theme.warmSand)
                                .tracking(0.8)

                            VStack(spacing: 6) {
                                ForEach(RecipeSortOption.allCases, id: \.self) { opt in
                                    Button(action: {
                                        HapticFeedbackService.shared.lightDetent()
                                        sortOption = opt
                                    }) {
                                        HStack {
                                            Text(opt.rawValue)
                                                .font(.system(size: 13, weight: sortOption == opt ? .bold : .regular))
                                                .foregroundColor(sortOption == opt ? Theme.textPrimary : Theme.textSecondary)
                                            Spacer()
                                            if sortOption == opt {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(Theme.sageGreen)
                                            }
                                        }
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 12)
                                        .background(RoundedRectangle(cornerRadius: 8).fill(sortOption == opt ? Theme.surfaceElevated : Color.clear))
                                    }
                                }
                            }
                        }
                        .wellnessCard()

                        // Section: Slide Scaled Filters
                        VStack(alignment: .leading, spacing: 18) {
                            Text("GLEITSKALEN-FILTER (SLIDER)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Theme.warmSand)
                                .tracking(0.8)

                            // 1. Min Protein Slider
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("Mindest-Protein")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(Theme.textPrimary)
                                    Spacer()
                                    Text(minProtein <= 0 ? "Kein Limit" : "Ab \(Int(minProtein)) g")
                                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                                        .foregroundColor(Theme.sageGreen)
                                }
                                Slider(value: $minProtein, in: 0...100, step: 5)
                                    .tint(Theme.sageGreen)
                                HStack {
                                    Text("0 g")
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundColor(Theme.textMuted)
                                    Spacer()
                                    Text("50 g")
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundColor(Theme.textMuted)
                                    Spacer()
                                    Text("100 g")
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundColor(Theme.textMuted)
                                }
                            }

                            Divider().background(Theme.border)

                            // 2. Max Price Slider
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("Maximaler Portionspreis")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(Theme.textPrimary)
                                    Spacer()
                                    Text(maxPrice <= 0 ? "Kein Limit" : "Bis \(String(format: "%.2f €", maxPrice))")
                                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                                        .foregroundColor(Theme.warmSand)
                                }
                                Slider(value: $maxPrice, in: 0...15, step: 0.5)
                                    .tint(Theme.warmSand)
                                HStack {
                                    Text("0 €")
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundColor(Theme.textMuted)
                                    Spacer()
                                    Text("7.50 €")
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundColor(Theme.textMuted)
                                    Spacer()
                                    Text("15.00 €")
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundColor(Theme.textMuted)
                                }
                            }

                            Divider().background(Theme.border)

                            // 3. Max Kcal Slider
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("Maximale Kalorien (Energie)")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(Theme.textPrimary)
                                    Spacer()
                                    Text(maxKcal <= 0 ? "Kein Limit" : "Bis \(Int(maxKcal)) kcal")
                                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                                        .foregroundColor(Theme.textPrimary)
                                }
                                Slider(value: $maxKcal, in: 0...1500, step: 50)
                                    .tint(Theme.textPrimary)
                                HStack {
                                    Text("0")
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundColor(Theme.textMuted)
                                    Spacer()
                                    Text("750 kcal")
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundColor(Theme.textMuted)
                                    Spacer()
                                    Text("1500 kcal")
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundColor(Theme.textMuted)
                                }
                            }

                            Divider().background(Theme.border)

                            // 4. Max Carbs Slider
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("Maximale Kohlenhydrate")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(Theme.textPrimary)
                                    Spacer()
                                    Text(maxCarbs <= 0 ? "Kein Limit" : "Bis \(Int(maxCarbs)) g")
                                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                                        .foregroundColor(Theme.textSecondary)
                                }
                                Slider(value: $maxCarbs, in: 0...150, step: 5)
                                    .tint(Color(red: 0.58, green: 0.88, blue: 0.28))
                                HStack {
                                    Text("0 g")
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundColor(Theme.textMuted)
                                    Spacer()
                                    Text("75 g")
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundColor(Theme.textMuted)
                                    Spacer()
                                    Text("150 g")
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundColor(Theme.textMuted)
                                }
                            }

                            Divider().background(Theme.border)

                            // 5. Max Fat Slider
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("Maximaler Fettgehalt")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(Theme.textPrimary)
                                    Spacer()
                                    Text(maxFat <= 0 ? "Kein Limit" : "Bis \(Int(maxFat)) g")
                                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                                        .foregroundColor(Color(red: 0.0, green: 0.82, blue: 0.92))
                                }
                                Slider(value: $maxFat, in: 0...100, step: 5)
                                    .tint(Color(red: 0.0, green: 0.82, blue: 0.92))
                                HStack {
                                    Text("0 g")
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundColor(Theme.textMuted)
                                    Spacer()
                                    Text("50 g")
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundColor(Theme.textMuted)
                                    Spacer()
                                    Text("100 g")
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundColor(Theme.textMuted)
                                }
                            }
                        }
                        .wellnessCard()

                        // Reset All Filters Button
                        Button(action: {
                            HapticFeedbackService.shared.mechanicalClick()
                            selectedCategory = "ALLE"
                            selectedCuisine = "ALLE"
                            selectedEquipment = "ALLE"
                            sortOption = .none
                            minProtein = 0.0
                            maxPrice = 0.0
                            maxKcal = 0.0
                            maxCarbs = 0.0
                            maxFat = 0.0
                        }) {
                            Text("Filter zurücksetzen")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Theme.terracotta)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Theme.surfaceElevated))
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Rezept-Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Anwenden") {
                        dismiss()
                    }
                    .foregroundColor(Theme.sageGreen)
                    .font(.system(size: 14, weight: .bold))
                }
            }
        }
    }
}

/// Simple flow layout for wrapping pills
public struct FilterFlowLayout: Layout {
    public var spacing: CGFloat = 6

    public init(spacing: CGFloat = 6) {
        self.spacing = spacing
    }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var height: CGFloat = 0
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > width && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        height = y + rowHeight
        return CGSize(width: width, height: height)
    }

    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX && x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
