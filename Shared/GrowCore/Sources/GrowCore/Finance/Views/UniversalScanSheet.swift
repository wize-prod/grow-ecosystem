import SwiftUI
import PhotosUI
#if canImport(UIKit)
import UIKit

public struct UniversalScanSheet: View {
    @ObservedObject private var store = FinanceStore.shared
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var showingFilePicker: Bool = false
    @State private var isProcessing: Bool = false
    @State private var activeDraft: UniversalScanDraft? = nil
    @State private var errorMessage: String? = nil
    @State private var newTagInput: String = ""
    @State private var importAlertMessage: String? = nil
    @State private var showingImportAlert: Bool = false

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header / Instructions
                    VStack(alignment: .leading, spacing: 6) {
                        Text("MULTI-SOURCE BELEG- & TRANSAKTIONS-SCANNER")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(FinanceTheme.textTertiary)
                        Text("Scannen Sie Quittungen, Belege, Haushaltsbuch-Einträge sowie Screenshots von Apple Pay oder PayPal zur automatischen Buchung.")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(FinanceTheme.textSecondary)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(FinanceTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                    // Scanner Action Buttons (Image OCR & File Ingestion)
                    HStack(spacing: 12) {
                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            HStack(spacing: 8) {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.system(size: 13, weight: .bold))
                                Text("Beleg-Foto")
                                    .font(.system(size: 13, weight: .bold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(FinanceTheme.accent)
                            .foregroundColor(Color.black)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        Button {
                            showingFilePicker = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "doc.text.fill")
                                    .font(.system(size: 13, weight: .bold))
                                Text("Haushaltsbuch (.csv)")
                                    .font(.system(size: 13, weight: .bold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(FinanceTheme.surfaceRaised)
                            .foregroundColor(FinanceTheme.textPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(FinanceTheme.surfaceBorder, lineWidth: 1)
                            )
                        }
                    }

                    if isProcessing {
                        VStack(spacing: 12) {
                            ProgressView()
                                .tint(FinanceTheme.accent)
                            Text("Vision OCR analysiert Beleg & erkennt Betrag, Empfänger und Kategorie...")
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundColor(FinanceTheme.textSecondary)
                        }
                        .padding(24)
                    }

                    if let err = errorMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(FinanceTheme.terracotta)
                            Text(err)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(FinanceTheme.terracotta)
                        }
                        .padding(12)
                        .background(FinanceTheme.terracotta.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    // Draft Form
                    if let draft = activeDraft {
                        draftPreviewForm(draft: draft)
                    }
                }
                .padding(16)
            }
            .background(FinanceTheme.background.ignoresSafeArea())
            .navigationTitle("Beleg scannen")
            .inlineTitleDisplayMode()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Schließen") { dismiss() }
                }
            }
            .onChange(of: selectedPhotoItem) { newItem in
                guard let item = newItem else { return }
                Task {
                    await processPickedImage(item: item)
                }
            }
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: [.commaSeparatedText, .tabSeparatedText, .plainText, .text, .json],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let selectedUrl = urls.first else { return }
                    store.importHaushaltsbuchFile(from: selectedUrl)
                    if let err = store.importErrorMessage {
                        self.errorMessage = err
                    } else if let report = store.lastImportReport {
                        self.importAlertMessage = report.summaryMessage
                        self.showingImportAlert = true
                    }
                case .failure(let err):
                    self.errorMessage = err.localizedDescription
                }
            }
            .alert("Haushaltsbuch Import", isPresented: $showingImportAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text(importAlertMessage ?? "Import abgeschlossen.")
            }
        }
    }

    // MARK: - Draft Preview Form
    private func draftPreviewForm(draft: UniversalScanDraft) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("ERFASSTER BELEG-ENTWURF")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(FinanceTheme.textTertiary)
                Spacer()
                Text(draft.detectedPlatform)
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(FinanceTheme.accent.opacity(0.15))
                    .foregroundColor(FinanceTheme.accent)
                    .clipShape(Capsule())
            }

            if draft.isDuplicate, let reason = draft.duplicateReason {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(FinanceTheme.warmSand)
                    Text(reason)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(FinanceTheme.warmSand)
                }
                .padding(10)
                .background(FinanceTheme.warmSand.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // Editable Fields
            VStack(spacing: 12) {
                HStack {
                    Text("Empfänger / Store:")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(FinanceTheme.textSecondary)
                    Spacer()
                    TextField("Empfänger", text: Binding(
                        get: { activeDraft?.partnerName ?? "" },
                        set: { activeDraft?.partnerName = $0 }
                    ))
                    .multilineTextAlignment(.trailing)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(FinanceTheme.textPrimary)
                }

                Divider().background(FinanceTheme.surfaceBorder)

                HStack {
                    Text("Betrag in EUR:")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(FinanceTheme.textSecondary)
                    Spacer()
                    TextField("0.00", value: Binding(
                        get: { activeDraft?.amount ?? 0.0 },
                        set: { activeDraft?.amount = $0 }
                    ), format: .number)
                    .decimalPadKeyboard()
                    .multilineTextAlignment(.trailing)
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(FinanceTheme.terracotta)
                }

                Divider().background(FinanceTheme.surfaceBorder)

                DatePicker("Datum:", selection: Binding(
                    get: { activeDraft?.date ?? Date() },
                    set: { activeDraft?.date = $0 }
                ), displayedComponents: [.date])
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(FinanceTheme.textSecondary)

                Divider().background(FinanceTheme.surfaceBorder)

                // Category & Budget Pickers
                HStack {
                    Text("Kategorie:")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(FinanceTheme.textSecondary)
                    Spacer()
                    Picker("", selection: Binding(
                        get: { activeDraft?.category ?? .other },
                        set: { activeDraft?.category = $0 }
                    )) {
                        ForEach(TransactionCategory.allCases) { cat in
                            Text(cat.displayName).tag(cat)
                        }
                    }
                    .tint(FinanceTheme.accent)
                }

                Divider().background(FinanceTheme.surfaceBorder)

                HStack {
                    Text("Monatsbudget:")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(FinanceTheme.textSecondary)
                    Spacer()
                    Picker("", selection: Binding(
                        get: { activeDraft?.budgetCategory ?? .privat },
                        set: { activeDraft?.budgetCategory = $0 }
                    )) {
                        ForEach(BudgetCategory.allCases) { b in
                            Text(b.rawValue).tag(b)
                        }
                    }
                    .tint(FinanceTheme.accent)
                }

                Divider().background(FinanceTheme.surfaceBorder)

                HStack {
                    Text("Notwendigkeit:")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(FinanceTheme.textSecondary)
                    Spacer()
                    Picker("", selection: Binding(
                        get: { activeDraft?.necessity ?? .neutral },
                        set: { activeDraft?.necessity = $0 }
                    )) {
                        ForEach(ExpenseNecessity.allCases, id: \.self) { nec in
                            Text(nec.rawValue).tag(nec)
                        }
                    }
                    .tint(FinanceTheme.accent)
                }

                Divider().background(FinanceTheme.surfaceBorder)

                // Account Selection
                HStack {
                    Text("Abbuchungskonto:")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(FinanceTheme.textSecondary)
                    Spacer()
                    Picker("", selection: Binding(
                        get: { activeDraft?.targetAccountId ?? "" },
                        set: { activeDraft?.targetAccountId = $0 }
                    )) {
                        ForEach(store.accounts.filter { $0.type != .loan }) { acc in
                            Text(acc.displayName).tag(acc.id)
                        }
                    }
                    .tint(FinanceTheme.accent)
                }
            }
            .padding(14)
            .background(FinanceTheme.surfaceRaised)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Tags Display
            VStack(alignment: .leading, spacing: 8) {
                Text("STICHTWORTE / TAGS")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(FinanceTheme.textTertiary)

                HStack {
                    ForEach(activeDraft?.tags ?? [], id: \.self) { tag in
                        Text(tag)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(FinanceTheme.accent.opacity(0.15))
                            .foregroundColor(FinanceTheme.accent)
                            .clipShape(Capsule())
                    }
                }

                HStack {
                    TextField("#tag hinzufügen", text: $newTagInput)
                        .font(.system(size: 12))
                        .textFieldStyle(.roundedBorder)

                    Button("Tag +") {
                        if !newTagInput.isEmpty {
                            let tag = newTagInput.hasPrefix("#") ? newTagInput : "#\(newTagInput)"
                            activeDraft?.tags.append(tag)
                            newTagInput = ""
                        }
                    }
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(FinanceTheme.accent)
                }
            }

            // Confirm Booking Button
            Button {
                if let d = activeDraft {
                    let res = store.bookScannedDraft(d)
                    if !res.success {
                        self.errorMessage = res.message
                    } else {
                        dismiss()
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16, weight: .bold))
                    Text("Buchung jetzt verbindlich übernehmen")
                        .font(.system(size: 14, weight: .bold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(FinanceTheme.sageGreen)
                .foregroundColor(Color.black)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(18)
        .background(FinanceTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(FinanceTheme.surfaceBorder, lineWidth: 1)
        )
    }

    private func processPickedImage(item: PhotosPickerItem) async {
        isProcessing = true
        errorMessage = nil
        activeDraft = nil

        guard let data = try? await item.loadTransferable(type: Data.self),
              let uiImage = UIImage(data: data) else {
            isProcessing = false
            errorMessage = "Konnte Bilddaten nicht laden."
            return
        }

        let result = await UniversalReceiptAndTransactionScanner.shared.scanImage(
            image: uiImage,
            existingTransactions: store.transactions
        )

        isProcessing = false
        if result.success, var draft = result.draft {
            if draft.targetAccountId.isEmpty {
                draft.targetAccountId = store.accounts.first(where: { $0.isMainAccount })?.id ?? ""
            }
            self.activeDraft = draft
        } else {
            self.errorMessage = result.errorMessage ?? "Keine Transaktionsdaten auf dem Beleg erkannt."
        }
    }
}

#endif
