import SwiftUI
import PhotosUI
#if canImport(UIKit)
import UIKit
#endif

#if canImport(UIKit)
public struct TargobankScanSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: FinanceStore
    
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var loadedImage: UIImage? = nil
    @State private var isProcessing: Bool = false
    @State private var scanResult: TargobankOCRResult? = nil
    @State private var errorMessage: String? = nil
    
    // Editable draft fields
    @State private var draftDate: Date = Date()
    @State private var draftAmountString: String = ""
    @State private var draftPartner: String = ""
    @State private var draftPurpose: String = ""
    @State private var draftCategory: TransactionCategory = .other
    @State private var selectedTargetAccountId: String = "3201649568"
    @State private var showForceBookConfirmation: Bool = false
    
    public init(store: FinanceStore) {
        self.store = store
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header / Selector
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("UNIVERSAL BUCHUNGSSCANNER")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(Color(red: 0.2, green: 0.6, blue: 1.0))
                            
                            if let res = scanResult {
                                Spacer()
                                Text(res.detectedPlatform)
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .foregroundColor(Color(red: 0.2, green: 0.8, blue: 0.4))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color(red: 0.1, green: 0.3, blue: 0.15))
                                    .cornerRadius(4)
                            }
                        }
                        
                        Text("Targobank, Apple Wallet & Zahlungsbelege erfassen")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("Extrahiert Buchungsdatum, Betrag, Empfaenger/Auftraggeber und Verwendungszweck automatisch via Vision OCR. Verhindert Doppelbuchungen.")
                            .font(.system(size: 12))
                            .foregroundColor(Color.white.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    
                    // Photo Picker Button / Image Preview Area
                    VStack(spacing: 12) {
                        if let image = loadedImage {
                            VStack(spacing: 8) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 220)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                    )
                                
                                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                    HStack {
                                        Image(systemName: "arrow.triangle.2.circlepath")
                                        Text("ANDERES BILD WAEHLEN")
                                    }
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(Color(red: 0.2, green: 0.6, blue: 1.0))
                                    .padding(.vertical, 6)
                                }
                            }
                        } else {
                            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                VStack(spacing: 12) {
                                    Image(systemName: "doc.viewfinder")
                                        .font(.system(size: 38))
                                        .foregroundColor(Color(red: 0.2, green: 0.6, blue: 1.0))
                                    
                                    Text("SCREENSHOT AUS FOTO-MEDIATHEK AUSWAEHLEN")
                                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                                        .foregroundColor(.white)
                                    
                                    Text("Targobank Transaktionsdetails oder Umsatzliste")
                                        .font(.system(size: 11))
                                        .foregroundColor(Color.white.opacity(0.5))
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 160)
                                .background(Color(white: 0.12))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.white.opacity(0.12), style: StrokeStyle(lineWidth: 1, dash: [4]))
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    
                    // Loading indicator
                    if isProcessing {
                        VStack(spacing: 8) {
                            ProgressView()
                                .tint(Color(red: 0.2, green: 0.6, blue: 1.0))
                            Text("ANALYSIERE BELEG VIA VISION OCR...")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(Color.white.opacity(0.7))
                        }
                        .padding(20)
                    }
                    
                    // Error Message
                    if let err = errorMessage {
                        HStack(spacing: 10) {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(Color(red: 1.0, green: 0.3, blue: 0.3))
                            Text(err)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(Color(red: 1.0, green: 0.3, blue: 0.3))
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(red: 0.25, green: 0.05, blue: 0.05))
                        .cornerRadius(6)
                        .padding(.horizontal, 16)
                    }
                    
                    // Duplicate Warning Banner
                    if let res = scanResult, res.isDuplicate {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.shield")
                                    .foregroundColor(Color(red: 1.0, green: 0.7, blue: 0.0))
                                Text("DUPLIKAT ERKANNT - BEREITS VERBUCHT")
                                    .font(.system(size: 11, weight: .heavy, design: .monospaced))
                                    .foregroundColor(Color(red: 1.0, green: 0.7, blue: 0.0))
                            }
                            
                            Text(res.duplicateReason ?? "Diese Transaktion stimmt mit einer bereits existierenden Buchung ueberein.")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(Color.white.opacity(0.85))
                                .lineSpacing(2)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(red: 0.22, green: 0.16, blue: 0.03))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color(red: 1.0, green: 0.7, blue: 0.0).opacity(0.4), lineWidth: 1)
                        )
                        .padding(.horizontal, 16)
                    }
                    
                    // Extracted & Editable Fields Form
                    if scanResult != nil || loadedImage != nil {
                        VStack(spacing: 14) {
                            Text("EXTRAHIERTE TRANSAKTIONSDATEN")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(Color.white.opacity(0.5))
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            // Amount Field
                            VStack(alignment: .leading, spacing: 4) {
                                Text("BETRAG (EUR)")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(Color.white.opacity(0.6))
                                TextField("-0,00", text: $draftAmountString)
                                    .numbersAndPunctuationKeyboard()
                                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white)
                                    .padding(10)
                                    .background(Color(white: 0.14))
                                    .cornerRadius(6)
                            }
                            
                            // Date Picker
                            VStack(alignment: .leading, spacing: 4) {
                                Text("BUCHUNGSDATUM")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(Color.white.opacity(0.6))
                                DatePicker("", selection: $draftDate, displayedComponents: .date)
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                                    .padding(6)
                                    .background(Color(white: 0.14))
                                    .cornerRadius(6)
                            }
                            
                            // Partner
                            VStack(alignment: .leading, spacing: 4) {
                                Text("EMPFAENGER / AUFTRAGGEBER")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(Color.white.opacity(0.6))
                                TextField("Partnername", text: $draftPartner)
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                                    .padding(10)
                                    .background(Color(white: 0.14))
                                    .cornerRadius(6)
                            }
                            
                            // Purpose
                            VStack(alignment: .leading, spacing: 4) {
                                Text("VERWENDUNGSZWECK")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(Color.white.opacity(0.6))
                                TextField("Verwendungszweck", text: $draftPurpose)
                                    .font(.system(size: 13, design: .monospaced))
                                    .foregroundColor(.white)
                                    .padding(10)
                                    .background(Color(white: 0.14))
                                    .cornerRadius(6)
                            }
                            
                            // Category Selector
                            VStack(alignment: .leading, spacing: 4) {
                                Text("KATEGORIE")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(Color.white.opacity(0.6))
                                Picker("Kategorie", selection: $draftCategory) {
                                    ForEach(TransactionCategory.allCases, id: \.self) { cat in
                                        Text(cat.displayName).tag(cat)
                                    }
                                }
                                .pickerStyle(.menu)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(6)
                                .background(Color(white: 0.14))
                                .cornerRadius(6)
                            }
                            
                            // Target Account Selector
                            VStack(alignment: .leading, spacing: 4) {
                                Text("ZIELKONTO (TARGOBANK)")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(Color.white.opacity(0.6))
                                Picker("Zielkonto", selection: $selectedTargetAccountId) {
                                    ForEach(store.accounts) { acc in
                                        Text("\(acc.name) (\(acc.accountNumber))").tag(acc.accountNumber)
                                    }
                                }
                                .pickerStyle(.menu)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(6)
                                .background(Color(white: 0.14))
                                .cornerRadius(6)
                            }
                        }
                        .padding(16)
                        .background(Color(white: 0.09))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                        .padding(.horizontal, 16)
                        
                        // Action Buttons
                        VStack(spacing: 10) {
                            if let res = scanResult, res.isDuplicate {
                                Button(action: {
                                    showForceBookConfirmation = true
                                }) {
                                    Text("TROTZ DUPLIKAT-WARNUNG VERBUCHEN")
                                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(Color(red: 0.7, green: 0.4, blue: 0.1))
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                }
                            } else {
                                Button(action: {
                                    commitBooking()
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "checkmark.circle.fill")
                                        Text("BUCHUNG IN HAUSHALTSBUCH SPEICHERN")
                                    }
                                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color(red: 0.15, green: 0.5, blue: 0.9))
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                                }
                                .disabled(draftAmountString.trimmingCharacters(in: .whitespaces).isEmpty)
                                .opacity(draftAmountString.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1.0)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 30)
                    }
                }
            }
            .background(Color(red: 0.06, green: 0.07, blue: 0.08).ignoresSafeArea())
            .inlineTitleDisplayMode()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { dismiss() }) {
                        Text("ABBRECHEN")
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundColor(Color.white.opacity(0.7))
                    }
                }
            }
            .onChange(of: selectedPhotoItem) { newItem in
                Task {
                    guard let item = newItem else { return }
                    await handlePhotoSelected(item: item)
                }
            }
            .alert("Duplikat trotzdem erfassen?", isPresented: $showForceBookConfirmation) {
                Button("Abbrechen", role: .cancel) { }
                Button("Erfassen", role: .destructive) {
                    commitBooking()
                }
            } message: {
                Text("Das System hat erkannt, dass dieser Betrag an diesem Tag bereits existiert. Mochtest du den Beleg trotzdem buchen?")
            }
        }
    }
    
    private func handlePhotoSelected(item: PhotosPickerItem) async {
        isProcessing = true
        errorMessage = nil
        
        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                throw NSError(domain: "TargobankScan", code: 1, userInfo: [NSLocalizedDescriptionKey: "Konnte Bilddaten nicht laden."])
            }
            
            await MainActor.run {
                self.loadedImage = image
            }
            
            let result = await TargobankScreenshotOCRService.shared.processScreenshot(
                image: image,
                existingTransactions: store.transactions,
                existingScreenshots: store.screenshotRecords
            )
            
            await MainActor.run {
                self.scanResult = result
                self.isProcessing = false
                
                if let record = result.record {
                    if let d = record.extractedDate {
                        self.draftDate = d
                    }
                    if let amt = record.extractedAmount {
                        self.draftAmountString = String(format: "%.2f", amt).replacingOccurrences(of: ".", with: ",")
                    }
                    self.draftPartner = record.extractedPartner
                    self.draftPurpose = record.extractedPurpose
                    self.draftCategory = result.suggestedCategory
                    if let acc = record.extractedAccount, !acc.isEmpty {
                        self.selectedTargetAccountId = acc
                    }
                }
                
                if !result.success && result.duplicateReason == nil {
                    self.errorMessage = "OCR-Erkennung unvollstaendig. Bitte Textfelder manuell ergaenzen."
                }
            }
        } catch {
            await MainActor.run {
                self.isProcessing = false
                self.errorMessage = "Fehler beim Laden des Bildes: \(error.localizedDescription)"
            }
        }
    }
    
    private func commitBooking() {
        guard let result = scanResult, let record = result.record else {
            // Fallback manual commit if OCR failed but user filled fields
            manualCommit()
            return
        }
        
        let cleanedAmountStr = draftAmountString.replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: ",", with: ".")
        guard let amountValue = Double(cleanedAmountStr) else {
            errorMessage = "Ungueltiges Betragsformat."
            return
        }
        
        let tx = BankTransaction(
            date: draftDate,
            recipientOrPurpose: draftPurpose.isEmpty ? "Targobank Screenshot Beleg" : draftPurpose,
            amount: amountValue,
            category: draftCategory,
            accountIBAN: selectedTargetAccountId,
            rawBookingText: "Screenshot Beleg",
            isManual: true,
            partnerName: draftPartner.isEmpty ? "Unbekannter Partner" : draftPartner,
            accountId: selectedTargetAccountId,
            tags: ["Beleg", "Quittung", "Scan"]
        )
        
        store.bookScreenshotTransaction(record: record, draftTx: tx)
        dismiss()
    }
    
    private func manualCommit() {
        let cleanedAmountStr = draftAmountString.replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: ",", with: ".")
        guard let amountValue = Double(cleanedAmountStr) else {
            errorMessage = "Ungueltiges Betragsformat."
            return
        }
        
        let tx = BankTransaction(
            date: draftDate,
            recipientOrPurpose: draftPurpose.isEmpty ? "Manueller Beleg" : draftPurpose,
            amount: amountValue,
            category: draftCategory,
            accountIBAN: selectedTargetAccountId,
            rawBookingText: "Manueller Beleg",
            isManual: true,
            partnerName: draftPartner.isEmpty ? "Unbekannter Partner" : draftPartner,
            accountId: selectedTargetAccountId,
            tags: ["Beleg", "Quittung", "Manuell"]
        )
        
        store.addTransaction(tx)
        dismiss()
    }
}
#endif
