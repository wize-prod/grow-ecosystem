import SwiftUI

// MARK: - Cross-App Heat-of-the-Moment Scratchpad UI
public struct FieldScratchpadCard: View {
    public let currentApp: String

    @State private var noteText: String = ""
    @State private var selectedCategory: String = "ALLGEMEIN"
    @State private var notesList: [FieldNoteEntry] = []
    @State private var isExpanded: Bool = false

    private let categories = ["ALLGEMEIN", "BUG", "ENGINE", "LOGIK", "IDEE"]

    public init(currentApp: String) {
        self.currentApp = currentApp
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerButton
            inputSection

            if isExpanded {
                Divider().background(Color.white.opacity(0.1))
                notesSection
            }
        }
        .padding(12)
        .background(Color(red: 0.08, green: 0.09, blue: 0.11))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .onAppear {
            refreshNotes()
            DarwinNotificationCenter.observe(DarwinNotificationCenter.fieldNotesUpdated) {
                refreshNotes()
            }
        }
    }

    private var headerButton: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                isExpanded.toggle()
            }
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("HEAT-OF-THE-MOMENT FIELD NOTES")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.gray)
                    Text("App-uebergreifendes Notiz- & Audit-Radar")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                }
                Spacer()

                Text("\(notesList.count) NOTIZEN")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(4)
                    .foregroundColor(.cyan)

                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.gray)
            }
        }
        .buttonStyle(.plain)
    }

    private var inputSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                ForEach(categories, id: \.self) { cat in
                    categoryButton(for: cat)
                }
            }

            HStack(alignment: .top, spacing: 8) {
                TextField("Spontane Beobachtung, Fehler oder Kritik eingeben...", text: $noteText, axis: .vertical)
                    .lineLimit(2...4)
                    .font(.system(size: 12))
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.white.opacity(0.04))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )

                sendButton
            }
        }
    }

    private func categoryButton(for cat: String) -> some View {
        Button(action: {
            selectedCategory = cat
        }) {
            Text(cat)
                .font(.system(size: 9, weight: selectedCategory == cat ? .bold : .medium, design: .monospaced))
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(selectedCategory == cat ? Color.cyan.opacity(0.2) : Color.white.opacity(0.05))
                .foregroundColor(selectedCategory == cat ? .cyan : .gray)
                .cornerRadius(4)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(selectedCategory == cat ? Color.cyan : Color.white.opacity(0.1), lineWidth: 1)
                )
        }
    }

    private var sendButton: some View {
        Button(action: commitNote) {
            VStack(spacing: 2) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 18))
                Text("SEND")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
            }
            .foregroundColor(noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .cyan)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.08))
            .cornerRadius(6)
        }
        .disabled(noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    @ViewBuilder
    private var notesSection: some View {
        if notesList.isEmpty {
            Text("Keine Notizen erfasst. Eintraege werden sofort zwischen Grow, Growcery und GrowFinance synchronisiert.")
                .font(.system(size: 11))
                .foregroundColor(.gray)
                .padding(.vertical, 4)
        } else {
            VStack(spacing: 8) {
                ForEach(notesList.prefix(6)) { note in
                    noteRow(note)
                }
            }
        }
    }

    private func noteRow(_ note: FieldNoteEntry) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text("[\(note.authorApp.uppercased())]")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(appColor(note.authorApp))

                Text(note.category)
                    .font(.system(size: 8, weight: .semibold, design: .monospaced))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(3)
                    .foregroundColor(.white)

                Spacer()

                Text(formatDate(note.timestamp))
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.gray)
            }

            Text(note.text)
                .font(.system(size: 12))
                .foregroundColor(.white)
        }
        .padding(8)
        .background(Color.white.opacity(0.03))
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    private func commitNote() {
        let text = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        GrowSuiteBridge.shared.saveFieldNote(text: text, authorApp: currentApp, category: selectedCategory)
        noteText = ""
        refreshNotes()
    }

    private func refreshNotes() {
        notesList = GrowSuiteBridge.shared.loadFieldNotes()
    }

    private func appColor(_ app: String) -> Color {
        switch app.lowercased() {
        case "grow", "gymapp": return .green
        case "growcery", "nutrivault": return .orange
        case "growfinance": return .cyan
        default: return .purple
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM HH:mm"
        return formatter.string(from: date)
    }
}
