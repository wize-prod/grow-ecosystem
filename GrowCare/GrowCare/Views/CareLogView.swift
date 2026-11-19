import SwiftUI

public struct CareLogView: View {
    @ObservedObject var store = GrowCareStore.shared
    public var filterDate: Date? = nil

    private var activeLogs: [CareLogEntry] {
        if let d = filterDate {
            return store.logs(for: d)
        } else {
            return store.logs(for: store.selectedDate)
        }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("LOG")
                        .font(.system(size: 15, weight: .bold, design: .monospaced))
                        .tracking(1.2)
                        .foregroundColor(CareTheme.textPrimary)

                    Text("Chronologisches Aktivitaetsprotokoll")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(CareTheme.textMuted)
                }

                Spacer()

                Text("\(activeLogs.count) Eintraege")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(activeLogs.isEmpty ? CareTheme.textMuted : CareTheme.careSage)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(activeLogs.isEmpty ? Color.white.opacity(0.04) : CareTheme.careSage.opacity(0.14))
                    )
            }

            if activeLogs.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "list.clipboard")
                        .font(.system(size: 28))
                        .foregroundColor(CareTheme.textMuted)
                    Text("Fuer diesen Tag sind keine Aktivitaeten protokolliert.")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(CareTheme.textMuted)
                    Text("Tippe auf eine Routine oder Aufgabe, um sie als erledigt zu verbuchen.")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(CareTheme.textMuted.opacity(0.8))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
                .careCard()
            } else {
                VStack(spacing: 8) {
                    ForEach(activeLogs) { entry in
                        logRow(entry)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func logRow(_ entry: CareLogEntry) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // Timestamp Badge
            VStack(alignment: .center, spacing: 2) {
                Text(entry.timeString)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(CareTheme.textPrimary)

                Text("\(entry.durationMinutes)m")
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(CareTheme.textMuted)
            }
            .frame(width: 44)
            .padding(.vertical, 4)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(entry.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(CareTheme.textPrimary)

                    Spacer()

                    Text(entry.activityType.rawValue.uppercased())
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(CareTheme.surfaceElevated)
                        .foregroundColor(CareTheme.careLilac)
                        .clipShape(Capsule())
                }

                if !entry.keyProductsUsed.isEmpty {
                    Text(entry.keyProductsUsed.joined(separator: " - "))
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(CareTheme.textSecondary)
                        .lineLimit(1)
                }

                if !entry.note.isEmpty {
                    Text(entry.note)
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(CareTheme.textMuted)
                        .lineLimit(2)
                }
            }

            // Undo / Delete Button
            Button(action: {
                let haptic = UIImpactFeedbackGenerator(style: .medium)
                haptic.impactOccurred()
                store.deleteLog(id: entry.id)
            }) {
                Image(systemName: "arrow.uturn.backward.circle")
                    .font(.system(size: 15))
                    .foregroundColor(CareTheme.textMuted)
                    .padding(4)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(CareTheme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(CareTheme.border, lineWidth: 0.8)
        )
    }
}

