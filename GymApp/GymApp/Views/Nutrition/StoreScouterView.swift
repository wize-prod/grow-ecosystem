import SwiftUI
import AVFoundation

public struct StoreScouterView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store = LocalStore.shared

    @State private var selectedStore: String = "PENNY"
    @State private var scannedBarcode: String = ""
    @State private var productName: String = ""
    @State private var productBrand: String = ""
    @State private var packQtyString: String = "500"
    @State private var priceString: String = ""
    @State private var unitString: String = "g"
    @State private var kcalString: String = "0"
    @State private var proteinString: String = "0.0"
    @State private var carbsString: String = "0.0"
    @State private var fatString: String = "0.0"
    @State private var fiberString: String = "0.0"

    @State private var isLookingUp: Bool = false
    @State private var lookupSource: String = ""
    @State private var scoutedSessionItems: [PantryItem] = []
    @State private var statusToast: String? = nil
    @State private var showingScanner: Bool = true

    private var storeOptions: [String] {
        LocalStore.shared.allKnownStores + ["SONSTIGE"]
    }

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Store Selection Bar
                        VStack(alignment: .leading, spacing: 6) {
                            Text("SUPERMARKT / BEZUGSQUELLE")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Theme.textMuted)
                                .tracking(0.8)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(storeOptions, id: \.self) { st in
                                        Button(action: {
                                            HapticFeedbackService.shared.lightDetent()
                                            selectedStore = st
                                        }) {
                                            Text(st)
                                                .font(.system(size: 11, weight: selectedStore == st ? .bold : .medium))
                                                .foregroundColor(selectedStore == st ? Theme.bg : Theme.textSecondary)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(
                                                    Capsule()
                                                        .fill(selectedStore == st ? Theme.warmSand : Theme.surfaceElevated)
                                                )
                                        }
                                    }
                                }
                            }
                        }

                        // Scanner Action Tile
                        Button(action: {
                            HapticFeedbackService.shared.lightDetent()
                            showingScanner = true
                        }) {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Theme.sageGreen.opacity(0.15))
                                        .frame(width: 44, height: 44)
                                    Image(systemName: "barcode.viewfinder")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(Theme.sageGreen)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(scannedBarcode.isEmpty ? "EAN-Barcode scannen" : "Barcode: \(scannedBarcode)")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(Theme.textPrimary)
                                    Text(isLookingUp ? "Lade Produktdaten..." : (lookupSource.isEmpty ? "Kamera öffnen & Regaletikett erfassen" : lookupSource))
                                        .font(.system(size: 11, weight: .regular, design: .default))
                                        .foregroundColor(Theme.textMuted)
                                }

                                Spacer()

                                if isLookingUp {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: Theme.warmSand))
                                } else {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(Theme.warmSand)
                                }
                            }
                            .padding(12)
                            .wellnessCard(borderColor: scannedBarcode.isEmpty ? Theme.border : Theme.sageGreen.opacity(0.6))
                        }

                        // Status Toast
                        if let toast = statusToast {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Theme.sageGreen)
                                Text(toast)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(Theme.textPrimary)
                                Spacer()
                            }
                            .padding(10)
                            .background(RoundedRectangle(cornerRadius: 10).fill(Theme.surfaceElevated))
                            .transition(.opacity)
                        }

                        // Product Data Entry
                        VStack(alignment: .leading, spacing: 12) {
                            Text("PRODUKTDATEN & REGALPREIS")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Theme.textMuted)
                                .tracking(0.8)

                            VStack(spacing: 10) {
                                inputField(label: "Artikelname", text: $productName, placeholder: "z.B. Skyr Natur")
                                inputField(label: "Marke / Eigenmarke", text: $productBrand, placeholder: "z.B. San Fabio / Penny")

                                HStack(spacing: 12) {
                                    inputField(label: "Regalpreis (EUR)", text: $priceString, placeholder: "1.49", keyboard: .decimalPad)
                                    inputField(label: "Packungsgröße (\(unitString))", text: $packQtyString, placeholder: unitString == "Stück" ? "10" : "500", keyboard: .decimalPad)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("EINHEIT")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(Theme.textMuted)
                                        .tracking(0.6)

                                    HStack(spacing: 6) {
                                        ForEach(["Stück", "g", "ml", "Kapseln"], id: \.self) { u in
                                            Button(action: {
                                                HapticFeedbackService.shared.lightDetent()
                                                unitString = u
                                                if u == "Stück" && (packQtyString == "500" || packQtyString.isEmpty) {
                                                    packQtyString = "10"
                                                }
                                            }) {
                                                Text(u)
                                                    .font(.system(size: 11, weight: unitString == u ? .bold : .medium))
                                                    .foregroundColor(unitString == u ? Theme.bg : Theme.textSecondary)
                                                    .frame(maxWidth: .infinity)
                                                    .padding(.vertical, 6)
                                                    .background(
                                                        RoundedRectangle(cornerRadius: 8)
                                                            .fill(unitString == u ? Theme.sageGreen : Theme.surfaceElevated)
                                                    )
                                            }
                                        }
                                    }
                                }

                                HStack(spacing: 8) {
                                    inputField(label: "kcal / 100g", text: $kcalString, placeholder: "65", keyboard: .decimalPad)
                                    inputField(label: "Protein (g)", text: $proteinString, placeholder: "11.0", keyboard: .decimalPad)
                                    inputField(label: "Ballastst. (g)", text: $fiberString, placeholder: "0.0", keyboard: .decimalPad)
                                }
                            }
                            .padding(14)
                            .wellnessCard()
                        }

                        // Save Button
                        Button(action: {
                            commitScoutedProduct()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "square.and.arrow.down.fill")
                                Text("In Datenbank erfassen")
                                    .font(.system(size: 14, weight: .bold))
                            }
                            .foregroundColor(Theme.bg)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(productName.trimmingCharacters(in: .whitespaces).isEmpty ? Theme.textMuted : Theme.sageGreen)
                            )
                        }
                        .disabled(productName.trimmingCharacters(in: .whitespaces).isEmpty)

                        // Scouted Session Feed
                        if !scoutedSessionItems.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("IN DIESER SESSION ERFASST (\(scoutedSessionItems.count))")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(Theme.warmSand)
                                    .tracking(0.8)

                                ForEach(scoutedSessionItems) { item in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(item.name)
                                                .font(.system(size: 12, weight: .semibold))
                                                .foregroundColor(Theme.textPrimary)
                                            Text("\(item.store) • \(Int(item.defaultPackQty)) \(item.unit)")
                                                .font(.system(size: 10, weight: .regular, design: .default))
                                                .foregroundColor(Theme.textSecondary)
                                        }
                                        Spacer()
                                        VStack(alignment: .trailing, spacing: 2) {
                                            Text(String(format: "%.2f EUR", item.defaultPrice))
                                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                                .foregroundColor(Theme.warmSand)
                                            Text(String(format: "%.1fg P", item.protein100g))
                                                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                                .foregroundColor(Theme.sageGreen)
                                        }
                                    }
                                    .padding(10)
                                    .wellnessCard()
                                }
                            }
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Store Scouter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fertig") {
                        dismiss()
                    }
                    .foregroundColor(Theme.warmSand)
                }
            }
            .sheet(isPresented: $showingScanner) {
                BarcodeScannerView { code in
                    showingScanner = false
                    handleBarcode(code)
                }
            }
        }
    }

    private func handleBarcode(_ code: String) {
        self.scannedBarcode = code
        self.isLookingUp = true
        self.lookupSource = "Suche in Stammdaten..."

        Task {
            // Check local pantry first
            if let existing = store.pantryItems.first(where: { $0.barcode == code }) {
                await MainActor.run {
                    applyItem(existing, source: "In Vault-Bestand gefunden")
                }
                return
            }

            // Check catalog
            if let catalogItem = MasterDataSeed.getMasterCatalog().first(where: { $0.barcode == code && !$0.barcode.isEmpty }) {
                await MainActor.run {
                    applyItem(catalogItem, source: "Aus Referenzkatalog geladen")
                }
                return
            }

            // Check Open Food Facts
            if let remoteItem = await OpenFoodFactsService.shared.fetchProduct(barcode: code) {
                await MainActor.run {
                    applyItem(remoteItem, source: "Aus Open Food Facts geladen")
                }
                return
            }

            await MainActor.run {
                self.isLookingUp = false
                self.lookupSource = "Neu / Unbekannt – manuelle Eingabe"
                self.productName = ""
                self.productBrand = ""
                HapticFeedbackService.shared.lightDetent()
            }
        }
    }

    private func applyItem(_ item: PantryItem, source: String) {
        self.productName = item.name
        self.productBrand = item.brand
        self.packQtyString = "\(Int(item.defaultPackQty))"
        if item.defaultPrice > 0.01 {
            self.priceString = String(format: "%.2f", item.defaultPrice)
        }
        self.unitString = item.unit
        self.kcalString = "\(Int(item.kcal100g))"
        self.proteinString = String(format: "%.1f", item.protein100g)
        self.carbsString = String(format: "%.1f", item.carbs100g)
        self.fatString = String(format: "%.1f", item.fat100g)
        self.fiberString = String(format: "%.1f", item.fiber100g)
        self.isLookingUp = false
        self.lookupSource = source
        HapticFeedbackService.shared.commitSuccess()
    }

    private func commitScoutedProduct() {
        let cleanName = productName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else { return }

        let parsedPrice = Double(priceString.replacingOccurrences(of: ",", with: ".")) ?? 0.0
        let parsedPack = Double(packQtyString.replacingOccurrences(of: ",", with: ".")) ?? 500.0
        let parsedKcal = Double(kcalString.replacingOccurrences(of: ",", with: ".")) ?? 0.0
        let parsedProtein = Double(proteinString.replacingOccurrences(of: ",", with: ".")) ?? 0.0
        let parsedCarbs = Double(carbsString.replacingOccurrences(of: ",", with: ".")) ?? 0.0
        let parsedFat = Double(fatString.replacingOccurrences(of: ",", with: ".")) ?? 0.0
        let parsedFiber = Double(fiberString.replacingOccurrences(of: ",", with: ".")) ?? 0.0

        // Check if item already exists to preserve currentStockQty
        let existing = store.pantryItems.first(where: {
            (!scannedBarcode.isEmpty && $0.barcode == scannedBarcode) ||
            $0.name.lowercased() == cleanName.lowercased()
        })

        let newItem = PantryItem(
            id: existing?.id ?? "scout_\(UUID().uuidString)",
            name: cleanName,
            brand: productBrand.isEmpty ? "Penny" : productBrand,
            barcode: scannedBarcode,
            defaultPackQty: parsedPack,
            defaultPrice: parsedPrice,
            currentStockQty: existing?.currentStockQty ?? 0.0,
            unit: unitString,
            kcal100g: parsedKcal,
            protein100g: parsedProtein,
            carbs100g: parsedCarbs,
            fat100g: parsedFat,
            fiber100g: parsedFiber,
            nutriscore: existing?.nutriscore ?? "a",
            store: selectedStore
        )

        store.addOrUpdatePantryItem(newItem)
        scoutedSessionItems.insert(newItem, at: 0)

        HapticFeedbackService.shared.commitSuccess()
        statusToast = "\(cleanName) (\(String(format: "%.2f €", parsedPrice))) bei \(selectedStore) gespeichert."

        // Reset inputs for next scan
        self.scannedBarcode = ""
        self.productName = ""
        self.productBrand = ""
        self.priceString = ""
        self.lookupSource = ""
    }

    private func inputField(label: String, text: Binding<String>, placeholder: String, keyboard: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(Theme.textMuted)
            TextField(placeholder, text: text)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(Theme.textPrimary)
                .keyboardType(keyboard)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 8).fill(Theme.surfaceElevated))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 0.5))
        }
    }
}
