import SwiftUI
#if canImport(UIKit)
import UIKit

public struct TargobankBelegeGalleryView: View {
    @ObservedObject var store: FinanceStore
    @Binding var showingScannerSheet: Bool
    @State private var selectedRecordForDetail: TargobankScreenshotRecord? = nil
    
    public init(store: FinanceStore, showingScannerSheet: Binding<Bool>) {
        self.store = store
        self._showingScannerSheet = showingScannerSheet
    }
    
    public var body: some View {
        VStack(spacing: 12) {
            // Header stats & info
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("GESPEICHERTE BELEGE")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(FinanceTheme.accent)
                    
                    Text("\(store.screenshotRecords.count) SCREENSHOTS IM SPEICHER")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(FinanceTheme.textPrimary)
                }
                
                Spacer()
                
                Button(action: { showingScannerSheet = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "camera.viewfinder")
                        Text("SCAN")
                    }
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(FinanceTheme.accent)
                    .foregroundColor(FinanceTheme.textPrimary)
                    .cornerRadius(6)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            
            if store.screenshotRecords.isEmpty {
                Spacer()
                
                VStack(spacing: 16) {
                    Image(systemName: "doc.text.image")
                        .font(.system(size: 44))
                        .foregroundColor(FinanceTheme.textTertiary)
                    
                    Text("NOCH KEINE TARGOBANK-SCREENSHOTS")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(FinanceTheme.textSecondary)
                    
                    Text("Mache einen Screenshot einer Transaktion in der Targobank-App und scanne ihn hier. Er wird dauerhaft gespeichert und kann direkt als Buchung verbucht werden.")
                        .font(.system(size: 12))
                        .foregroundColor(FinanceTheme.textTertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    
                    Button(action: { showingScannerSheet = true }) {
                        Text("ERSTEN SCREENSHOT ERFASSEN")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(FinanceTheme.accent)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(FinanceTheme.surfaceRaised)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(FinanceTheme.border, lineWidth: 1)
                            )
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(store.screenshotRecords) { record in
                            BelegCard(record: record)
                                .onTapGesture {
                                    selectedRecordForDetail = record
                                }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 80)
                }
            }
        }
        .sheet(item: $selectedRecordForDetail) { record in
            BelegDetailSheet(record: record, store: store)
        }
    }
}

private struct BelegCard: View {
    let record: TargobankScreenshotRecord
    
    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            if let image = TargobankScreenshotOCRService.shared.loadImage(filename: record.filename) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 56, height: 56)
                    .cornerRadius(6)
                    .clipped()
            } else {
                Rectangle()
                    .fill(FinanceTheme.surfaceRaised)
                    .frame(width: 56, height: 56)
                    .cornerRadius(6)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(FinanceTheme.textTertiary)
                    )
            }
            
            // Details
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(record.extractedPartner.isEmpty ? "Unbekannter Partner" : record.extractedPartner)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(FinanceTheme.textPrimary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if let amt = record.extractedAmount {
                        Text(String(format: "%.2f EUR", amt))
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(amt > 0 ? FinanceTheme.positive : FinanceTheme.textPrimary)
                    }
                }
                
                HStack {
                    if let d = record.extractedDate {
                        Text(formattedDate(d))
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(FinanceTheme.textSecondary)
                    }
                    
                    Spacer()
                    
                    // Status Badge
                    if record.isBooked {
                        Text("VERBUCHT")
                            .font(.system(size: 9, weight: .heavy, design: .monospaced))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(FinanceTheme.positive.opacity(0.2))
                            .foregroundColor(FinanceTheme.positive)
                            .cornerRadius(3)
                    } else if record.isDuplicate {
                        Text("DUPLIKAT")
                            .font(.system(size: 9, weight: .heavy, design: .monospaced))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(FinanceTheme.warning.opacity(0.2))
                            .foregroundColor(FinanceTheme.warning)
                            .cornerRadius(3)
                    } else {
                        Text("OFFEN")
                            .font(.system(size: 9, weight: .heavy, design: .monospaced))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(FinanceTheme.accent.opacity(0.2))
                            .foregroundColor(FinanceTheme.accent)
                            .cornerRadius(3)
                    }
                }
                
                if !record.extractedPurpose.isEmpty {
                    Text(record.extractedPurpose)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(FinanceTheme.textTertiary)
                        .lineLimit(1)
                }
            }
        }
        .padding(10)
        .background(FinanceTheme.surfaceCard)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(FinanceTheme.borderSubtle, lineWidth: 1)
        )
    }
    
    private func formattedDate(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .none
        return df.string(from: date)
    }
}

private struct BelegDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let record: TargobankScreenshotRecord
    @ObservedObject var store: FinanceStore
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let image = TargobankScreenshotOCRService.shared.loadImage(filename: record.filename) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 320)
                            .cornerRadius(8)
                            .padding(.horizontal, 16)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("BELEG-DETAILS")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(FinanceTheme.textTertiary)
                        
                        DetailRow(title: "EMPFAENGER / PARTNER", value: record.extractedPartner.isEmpty ? "Nicht erkannt" : record.extractedPartner)
                        if let amt = record.extractedAmount {
                            DetailRow(title: "BETRAG", value: String(format: "%.2f EUR", amt))
                        }
                        if let d = record.extractedDate {
                            DetailRow(title: "DATUM", value: DateFormatter.localizedString(from: d, dateStyle: .long, timeStyle: .none))
                        }
                        if !record.extractedPurpose.isEmpty {
                            DetailRow(title: "VERWENDUNGSZWECK", value: record.extractedPurpose)
                        }
                        DetailRow(title: "STATUS", value: record.isBooked ? "Bereits verbucht" : (record.isDuplicate ? "Duplikat erkannt" : "Offen"))
                        
                        if let dupReason = record.duplicateReason {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("DUPLIKAT-HINWEIS")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(FinanceTheme.warning)
                                Text(dupReason)
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundColor(FinanceTheme.textPrimary)
                            }
                            .padding(10)
                            .background(FinanceTheme.warning.opacity(0.15))
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(FinanceTheme.warning.opacity(0.3), lineWidth: 1)
                            )
                        }
                    }
                    .padding(16)
                    .background(FinanceTheme.surfaceCard)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(FinanceTheme.borderSubtle, lineWidth: 1)
                    )
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 16)
            }
            .background(FinanceTheme.bg.ignoresSafeArea())
            .navigationTitle("Targobank Beleg")
            .inlineTitleDisplayMode()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Schliessen") { dismiss() }
                }
            }
        }
    }
}

private struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(FinanceTheme.textTertiary)
            Text(value)
                .font(.system(size: 13))
                .foregroundColor(FinanceTheme.textPrimary)
        }
    }
}
#endif
