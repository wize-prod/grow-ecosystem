import SwiftUI

public struct MeasurementsView: View {
    @EnvironmentObject private var store: GymStore
    @State private var selectedMeasurementTypeForAdd: MeasurementType? = nil
    @State private var selectedMeasurementTypeForHistory: MeasurementType? = nil

    public var body: some View {
        NavigationStack {
            ZStack {
                GymTheme.bg.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Section: CORE
                        sectionBlock(
                            title: "CORE",
                            types: MeasurementType.allCases.filter { $0.category == .core }
                        )

                        // Section: KÖRPERTEIL
                        sectionBlock(
                            title: "KOERPERTEIL",
                            types: MeasurementType.allCases.filter { $0.category == .bodyPart }
                        )

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                }
            }
            .navigationTitle("Messungen")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selectedMeasurementTypeForAdd) { mType in
                AddMeasurementSheet(measurementType: mType)
                    .environmentObject(store)
            }
            .sheet(item: $selectedMeasurementTypeForHistory) { mType in
                MeasurementHistorySheet(measurementType: mType)
                    .environmentObject(store)
            }
        }
    }

    private func sectionBlock(title: String, types: [MeasurementType]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption)
                .fontWeight(.bold)
                .tracking(1.0)
                .foregroundColor(GymTheme.textMuted)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                ForEach(types) { mType in
                    measurementRow(mType: mType)
                    if mType != types.last {
                        Divider().background(GymTheme.border)
                    }
                }
            }
            .background(GymTheme.surface)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(GymTheme.border, lineWidth: 1)
            )
        }
    }

    private func measurementRow(mType: MeasurementType) -> some View {
        let latest = store.latestMeasurement(for: mType)

        return HStack {
            Button {
                selectedMeasurementTypeForHistory = mType
                HapticFeedback.light()
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text(mType.rawValue)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(GymTheme.textPrimary)

                    if let entry = latest {
                        let formatted: String = (mType == .weight)
                            ? String(format: "%.2f", entry.value).replacingOccurrences(of: ".", with: ",")
                            : (entry.value.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(entry.value))" : String(format: "%.1f", entry.value).replacingOccurrences(of: ".", with: ","))
                        Text("\(formatted) \(mType.unit)")
                            .font(.caption2)
                            .foregroundColor(GymTheme.textSecondary)
                    } else {
                        Text("Noch kein Eintrag")
                            .font(.caption2)
                            .foregroundColor(GymTheme.textMuted)
                    }
                }
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
                selectedMeasurementTypeForAdd = mType
                HapticFeedback.light()
            } label: {
                Image(systemName: "plus")
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(8)
                    .background(GymTheme.strongBlue)
                    .foregroundColor(GymTheme.bg)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

// MARK: - Add Measurement Sheet
struct AddMeasurementSheet: View {
    let measurementType: MeasurementType
    @EnvironmentObject private var store: GymStore
    @Environment(\.dismiss) private var dismiss
    @State private var valueText: String = ""
    @State private var note: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                GymTheme.bg.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(measurementType.rawValue)
                            .font(.headline)
                            .foregroundColor(GymTheme.textPrimary)
                        Text("Einheit: \(measurementType.unit)")
                            .font(.caption)
                            .foregroundColor(GymTheme.textSecondary)
                    }
                    .somaCard()

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Wert eingeben")
                            .font(.caption)
                            .foregroundColor(GymTheme.textSecondary)

                        HStack {
                            TextField("z. B. 78.5", text: $valueText)
                                .keyboardType(.decimalPad)
                                .font(.title3)
                                .padding(10)
                                .foregroundColor(GymTheme.textPrimary)
                            Text(measurementType.unit)
                                .font(.headline)
                                .foregroundColor(GymTheme.textSecondary)
                                .padding(.trailing, 10)
                        }
                        .background(GymTheme.surfaceElevated)
                        .cornerRadius(8)
                    }
                    .somaCard()

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Optionale Notiz")
                            .font(.caption)
                            .foregroundColor(GymTheme.textSecondary)

                        TextField("z. B. morgens nuechtern", text: $note)
                            .font(.subheadline)
                            .padding(10)
                            .background(GymTheme.surfaceElevated)
                            .foregroundColor(GymTheme.textPrimary)
                            .cornerRadius(8)
                    }
                    .somaCard()

                    Button {
                        let normalized = valueText.replacingOccurrences(of: ",", with: ".")
                        if let val = Double(normalized) {
                            store.addMeasurement(type: measurementType, value: val, note: note)
                            dismiss()
                        }
                    } label: {
                        Text("Speichern")
                            .font(.headline)
                            .foregroundColor(GymTheme.bg)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(GymTheme.strongBlue)
                            .cornerRadius(10)
                    }

                    Spacer()
                }
                .padding(16)
            }
            .navigationTitle("Messung eintragen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") { dismiss() }
                        .foregroundColor(GymTheme.strongBlue)
                }
            }
        }
    }
}

// MARK: - Measurement History Sheet
struct MeasurementHistorySheet: View {
    let measurementType: MeasurementType
    @EnvironmentObject private var store: GymStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                GymTheme.bg.ignoresSafeArea()

                let history = store.measurements.filter { $0.type == measurementType }

                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(measurementType.rawValue)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(GymTheme.textPrimary)
                            Text("Historischer Verlauf")
                                .font(.caption)
                                .foregroundColor(GymTheme.textSecondary)
                        }
                        .somaCard()

                        if history.isEmpty {
                            Text("Noch keine Messungen fuer diesen Parameter vorhanden.")
                                .font(.caption)
                                .foregroundColor(GymTheme.textMuted)
                                .padding(16)
                        } else {
                            ForEach(history) { entry in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(formatDate(entry.date))
                                            .font(.caption)
                                            .foregroundColor(GymTheme.textSecondary)
                                        if !entry.note.isEmpty {
                                            Text(entry.note)
                                                .font(.caption2)
                                                .foregroundColor(GymTheme.textMuted)
                                        }
                                    }
                                    Spacer()
                                    Text("\(formatValue(entry.value)) \(measurementType.unit)")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(GymTheme.textPrimary)
                                }
                                .padding(10)
                                .background(GymTheme.surface)
                                .cornerRadius(8)
                            }
                        }

                        Spacer()
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Messungsverlauf")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Schliessen") { dismiss() }
                        .foregroundColor(GymTheme.strongBlue)
                }
            }
        }
    }

    private func formatValue(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(value))" : String(format: "%.1f", value).replacingOccurrences(of: ".", with: ",")
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
