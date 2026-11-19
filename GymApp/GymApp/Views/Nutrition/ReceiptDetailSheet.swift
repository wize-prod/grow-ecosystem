import SwiftUI
import UIKit

public struct ReceiptDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store = LocalStore.shared

    public let receipt: ReceiptRecord
    @State private var showingFullImage: Bool = false
    @State private var selectedLineItemId: String? = nil
    @State private var showingShareSheet: Bool = false
    @State private var shareItems: [Any] = []
    @State private var toastMessage: String? = nil

    public init(receipt: ReceiptRecord) {
        self.receipt = receipt
    }

    private var activeReceipt: ReceiptRecord {
        store.receipts.first(where: { $0.id == receipt.id }) ?? receipt
    }

    private var receiptImage: UIImage? {
        guard let filename = activeReceipt.imageFilename else { return nil }
        return ReceiptOCRService.shared.getReceiptImage(filename: filename)
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // Receipt Header Summary Card
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(activeReceipt.storeName)
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(Theme.textPrimary)
                                    Text(formattedDate(activeReceipt.date))
                                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                                        .foregroundColor(Theme.textMuted)
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("GESAMT")
                                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                                        .foregroundColor(Theme.warmSand)
                                    Text(String(format: "%.2f €", activeReceipt.totalAmount))
                                        .font(.system(size: 22, weight: .bold, design: .monospaced))
                                        .foregroundColor(Theme.sageGreen)
                                }
                            }

                            if activeReceipt.priceChangeCount > 0 {
                                HStack(spacing: 6) {
                                    Image(systemName: "arrow.triangle.swap")
                                        .font(.system(size: 11))
                                    Text("\(activeReceipt.priceChangeCount) Preisaktualisierungen durch diesen Beleg erfasst")
                                        .font(.system(size: 11, weight: .medium))
                                }
                                .foregroundColor(Theme.warmSand)
                                .padding(.top, 4)
                            }
                        }
                        .padding(16)
                        .wellnessCard(borderColor: Theme.sageGreen)

                        // Scanned Receipt Photo Thumbnail & Action Bar
                        if let image = receiptImage {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("BELEG-DOKUMENT")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(Theme.textMuted)

                                Button(action: { showingFullImage = true }) {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(maxHeight: 180)
                                        .frame(maxWidth: .infinity)
                                        .clipped()
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Theme.border, lineWidth: 1)
                                        )
                                        .overlay(
                                            VStack {
                                                Spacer()
                                                HStack {
                                                    Spacer()
                                                    Text("Vollbild oeffnen & Zoomen")
                                                        .font(.system(size: 11, weight: .semibold))
                                                        .foregroundColor(Theme.bg)
                                                        .padding(.horizontal, 10)
                                                        .padding(.vertical, 5)
                                                        .background(Capsule().fill(Theme.warmSand))
                                                        .padding(8)
                                                }
                                            }
                                        )
                                }

                                // Share & Save Action Row
                                HStack(spacing: 10) {
                                    Button(action: {
                                        shareReceipt(image: image)
                                    }) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "square.and.arrow.up")
                                                .font(.system(size: 12, weight: .semibold))
                                            Text("Teilen & Senden")
                                                .font(.system(size: 12, weight: .bold))
                                        }
                                        .foregroundColor(Theme.textPrimary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(RoundedRectangle(cornerRadius: 10).fill(Theme.surfaceElevated))
                                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border, lineWidth: 1))
                                    }

                                    Button(action: {
                                        downloadReceipt(image: image)
                                    }) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "arrow.down.to.line.circle.fill")
                                                .font(.system(size: 13, weight: .semibold))
                                            Text("In Fotos sichern")
                                                .font(.system(size: 12, weight: .bold))
                                        }
                                        .foregroundColor(Theme.bg)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(RoundedRectangle(cornerRadius: 10).fill(Theme.sageGreen))
                                    }
                                }

                                // Ecosystem Cross-App Action: GrowFinance Sync
                                Button(action: {
                                    GrowEcosystemRouter.shared.openApp(
                                        .growfinance,
                                        path: "expense",
                                        params: [
                                            "amount": String(format: "%.2f", activeReceipt.totalAmount),
                                            "vendor": activeReceipt.storeName
                                        ]
                                    )
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "creditcard.fill")
                                            .font(.system(size: 13, weight: .semibold))
                                        Text("In GrowFinance buchen (\(String(format: "%.2f EUR", activeReceipt.totalAmount)))")
                                            .font(.system(size: 12, weight: .bold))
                                    }
                                    .foregroundColor(Color.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(red: 0.20, green: 0.35, blue: 0.55)))
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.15), lineWidth: 1))
                                }
                            }
                        }

                        // Itemized Line Items
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("ERFASSTE POSITIONEN")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(Theme.textMuted)
                                Spacer()
                                Text("\(activeReceipt.items.count) Artikel (Antippen fuer Details & EAN)")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(Theme.warmSand)
                            }

                            VStack(spacing: 8) {
                                ForEach(activeReceipt.items) { item in
                                    receiptItemRow(item)
                                }
                            }
                        }

                        // Delete Receipt Button
                        Button(action: {
                            store.deleteReceipt(id: activeReceipt.id)
                            dismiss()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "trash")
                                    .font(.system(size: 13))
                                Text("Quittung aus Archiv loeschen")
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .foregroundColor(Theme.terracotta)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Theme.surfaceElevated))
                        }
                        .padding(.top, 12)

                        // Bottom Thumb-Zone Dismiss Button (iPhone 16 Pro Max Ergonomie)
                        Button(action: {
                            HapticFeedbackService.shared.lightDetent()
                            dismiss()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 13, weight: .bold))
                                Text("Schliessen")
                                    .font(.system(size: 15, weight: .bold))
                            }
                            .foregroundColor(Theme.bg)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Theme.sageGreen))
                        }
                        .padding(.top, 4)
                    }
                    .padding(16)
                }

                // Toast Feedback
                if let toast = toastMessage {
                    VStack {
                        Spacer()
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Theme.sageGreen)
                            Text(toast)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Theme.textPrimary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Theme.surfaceElevated)
                        .cornerRadius(24)
                        .overlay(Capsule().stroke(Theme.sageGreen, lineWidth: 1))
                        .shadow(radius: 10)
                        .padding(.bottom, 24)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(100)
                }
            }
            .navigationTitle("Quittungs-Archiv")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    if let img = receiptImage {
                        Button(action: { shareReceipt(image: img) }) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Theme.warmSand)
                        }
                        Button(action: { downloadReceipt(image: img) }) {
                            Image(systemName: "arrow.down.to.line.circle")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Theme.sageGreen)
                        }
                    }
                    Button("Schliessen") { dismiss() }
                        .foregroundColor(Theme.sageGreen)
                }
            }
            .sheet(isPresented: $showingFullImage) {
                if let img = receiptImage {
                    NavigationStack {
                        ZoomableImageView(image: img)
                            .background(Color.black.ignoresSafeArea())
                            .navigationTitle("Quittung")
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbar {
                                ToolbarItem(placement: .cancellationAction) {
                                    Button("Fertig") { showingFullImage = false }
                                        .foregroundColor(Theme.warmSand)
                                }
                                ToolbarItemGroup(placement: .confirmationAction) {
                                    Button(action: { shareReceipt(image: img) }) {
                                        Image(systemName: "square.and.arrow.up")
                                            .font(.system(size: 15))
                                            .foregroundColor(Theme.warmSand)
                                    }
                                    Button(action: { downloadReceipt(image: img) }) {
                                        Image(systemName: "arrow.down.to.line.circle.fill")
                                            .font(.system(size: 16))
                                            .foregroundColor(Theme.sageGreen)
                                    }
                                }
                            }
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                ActivityShareSheet(activityItems: shareItems)
            }
            .sheet(isPresented: Binding(
                get: { selectedLineItemId != nil },
                set: { if !$0 { selectedLineItemId = nil } }
            )) {
                if let lineId = selectedLineItemId {
                    ReceiptItemDetailSheet(receiptId: activeReceipt.id, lineItemId: lineId)
                }
            }
            .onDisappear {
                store.saveReceipts()
                store.savePantry()
            }
        }
        .presentationDragIndicator(.visible)
    }

    private func shareReceipt(image: UIImage?) {
        var items: [Any] = []
        if let img = image {
            items.append(img)
        }
        let summary = generateReceiptSummaryText()
        items.append(summary)
        self.shareItems = items
        self.showingShareSheet = true
        HapticFeedbackService.shared.lightDetent()
    }

    private func downloadReceipt(image: UIImage) {
        HapticFeedbackService.shared.lightDetent()
        ReceiptPhotoLibrarySaver.shared.save(image: image) { success, msg in
            DispatchQueue.main.async {
                withAnimation {
                    self.toastMessage = msg
                }
                if success {
                    HapticFeedbackService.shared.commitSuccess()
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    withAnimation {
                        if self.toastMessage == msg {
                            self.toastMessage = nil
                        }
                    }
                }
            }
        }
    }

    private func generateReceiptSummaryText() -> String {
        var text = "GROWCERY BELEG-DOKUMENT\n"
        text += "Geschaeft: \(activeReceipt.storeName)\n"
        text += "Datum: \(formattedDate(activeReceipt.date))\n"
        text += "Gesamtsumme: \(String(format: "%.2f EUR", activeReceipt.totalAmount))\n\n"
        text += "POSITIONEN:\n"
        for (idx, item) in activeReceipt.items.enumerated() {
            let name = item.matchedPantryItemName ?? item.rawText
            text += String(format: "%2d. %-24@ %6.2f EUR\n", idx + 1, name, item.parsedPrice)
        }
        return text
    }

    private func receiptItemRow(_ item: ReceiptLineItem) -> some View {
        Button(action: {
            selectedLineItemId = item.id
            HapticFeedbackService.shared.lightDetent()
        }) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(item.matchedPantryItemName ?? item.rawText)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Theme.textPrimary)

                        if item.matchedPantryItemId != nil {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 10))
                                .foregroundColor(Theme.sageGreen)
                        }
                    }

                    if item.quantity > 1 {
                        Text("\(item.quantity) Packungen / Stk (\(String(format: "%.2f € / Stk", item.singlePackPrice)))")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundColor(Theme.warmSand)
                    } else if let note = item.quantityNote, !note.isEmpty {
                        Text(note)
                            .font(.system(size: 10, weight: .regular, design: .monospaced))
                            .foregroundColor(Theme.warmSand)
                    }

                    if item.matchedPantryItemName != nil && item.rawText != item.matchedPantryItemName {
                        Text("Bon: \(item.rawText)")
                            .font(.system(size: 10, weight: .regular, design: .monospaced))
                            .foregroundColor(Theme.textMuted)
                    } else if item.matchedPantryItemId == nil {
                        Text("+ EAN / Datenbank erfassen")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Theme.warmSand)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "%.2f €", item.singlePackPrice))
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(Theme.textPrimary)

                    if item.quantity > 1 {
                        Text(String(format: "%d x %.2f € = %.2f €", item.quantity, item.singlePackPrice, item.lineTotalPrice))
                            .font(.system(size: 9, weight: .semibold, design: .monospaced))
                            .foregroundColor(Theme.warmSand)
                    }

                    if item.hasPriceDifference, let prev = item.previousPrice {
                        HStack(spacing: 2) {
                            Text(String(format: "alt: %.2f €", prev))
                                .font(.system(size: 9, weight: .regular, design: .monospaced))
                                .foregroundColor(Theme.textMuted)
                                .strikethrough()
                            Text(String(format: "(%@%.2f €)", item.priceDifference > 0 ? "+" : "", item.priceDifference))
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(item.priceDifference > 0 ? Theme.terracotta : Theme.sageGreen)
                        }
                    }
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Theme.textMuted)
                    .padding(.leading, 4)
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 10).fill(Theme.surfaceElevated))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(item.matchedPantryItemId != nil ? Theme.border : Theme.warmSand.opacity(0.35), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Native Activity Share Sheet Representable
public struct ActivityShareSheet: UIViewControllerRepresentable {
    public let activityItems: [Any]
    public let applicationActivities: [UIActivity]? = nil

    public func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        return controller
    }

    public func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Photo Library Saver Helper
public final class ReceiptPhotoLibrarySaver: NSObject {
    public static let shared = ReceiptPhotoLibrarySaver()
    private var completion: ((Bool, String) -> Void)?

    public func save(image: UIImage, completion: @escaping (Bool, String) -> Void) {
        self.completion = completion
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(didFinishSaving(_:didFinishSavingWithError:contextInfo:)), nil)
    }

    @objc private func didFinishSaving(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            completion?(false, "Fehler beim Speichern: \(error.localizedDescription)")
        } else {
            completion?(true, "Beleg in Fotomediathek gesichert")
        }
        completion = nil
    }
}
