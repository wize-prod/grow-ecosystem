import SwiftUI

public struct DeepMuscleReportSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: GymStore

    @State private var selectedRegion: MuscleRegion? = nil

    private var report: DeepMuscleAnalysisReport {
        DeepMuscleEngine.shared.evaluateAllMuscles(sessions: store.allSessionsWithExternal)
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    // MARK: - 1. Kompakte Symmetrie- & Status-Übersicht (Header)
                    symmetrySummaryHeader(report: report)

                    // MARK: - 2. Regionale Balance & Tiefenstabilität (mit dynamisch integrierten Defiziten)
                    regionalOverviewSection(report: report)

                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 16)
            }
            .background(GymTheme.bg.ignoresSafeArea())
            .safeAreaInset(edge: .bottom) {
                // Fixed Bottom Dismiss Button
                VStack(spacing: 0) {
                    Divider().background(GymTheme.borderSubtle)
                    Button(action: {
                        dismiss()
                        HapticFeedback.light()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.down")
                                .font(.system(size: 13, weight: .bold))
                            Text("Schliessen")
                                .font(.system(size: 15, weight: .bold))
                        }
                        .foregroundColor(GymTheme.bg)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(GymTheme.accentOrange)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
                .background(GymTheme.surfaceElevated)
            }
            .navigationTitle("Tiefenmuskel-Index & Regionale Balance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Schliessen") {
                        dismiss()
                    }
                    .foregroundColor(GymTheme.textPrimary)
                }
            }
            .sheet(item: $selectedRegion) { reg in
                RegionUnitsPopupSheet(region: reg, score: report.regionHealth[reg] ?? 0.0, report: report)
            }
        }
        .presentationDragIndicator(.visible)
    }

    // MARK: - 1. Symmetrie- & Status-Header
    private func symmetrySummaryHeader(report: DeepMuscleAnalysisReport) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("TIEFENMUSKEL-INDEX (TMI)")
                    .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                    .foregroundColor(GymTheme.textMuted)
                    .tracking(0.8)

                Spacer()

                Text("4-SCHICHTEN-MODELL")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(GymTheme.cyanAccent)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(GymTheme.cyanAccent.opacity(0.15))
                    .cornerRadius(4)
            }

            HStack(spacing: 16) {
                // Symmetrie Score
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(Int(report.overallSymmetryScore)) / 100")
                        .font(.system(size: 26, weight: .bold, design: .monospaced))
                        .foregroundColor(report.overallSymmetryScore >= 70 ? GymTheme.sageGreen : (report.overallSymmetryScore >= 40 ? Color(hex: "F39C12") : Color(hex: "E74C3C")))
                    Text("Gesamt-Symmetrie")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(GymTheme.textSecondary)
                }

                Divider()
                    .frame(height: 36)
                    .background(GymTheme.borderSubtle)

                // Getrackte Muskeln
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(report.totalMusclesTracked) / 50")
                        .font(.system(size: 26, weight: .bold, design: .monospaced))
                        .foregroundColor(GymTheme.textPrimary)
                    Text("Einheiten erfasst")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(GymTheme.textSecondary)
                }

                Spacer()

                // Defizite Status Badge
                VStack(alignment: .trailing, spacing: 2) {
                    if report.criticalDeficits.isEmpty {
                        Text("BALANCED")
                            .font(.system(size: 11, weight: .heavy, design: .monospaced))
                            .foregroundColor(GymTheme.sageGreen)
                        Text("Keine akuten Defizite")
                            .font(.system(size: 10))
                            .foregroundColor(GymTheme.textSecondary)
                    } else {
                        Text("\(report.criticalDeficits.count) DEFIZIT\(report.criticalDeficits.count == 1 ? "" : "E")")
                            .font(.system(size: 11, weight: .heavy, design: .monospaced))
                            .foregroundColor(Color(hex: "E74C3C"))
                        Text("In Regionen markiert")
                            .font(.system(size: 10))
                            .foregroundColor(GymTheme.textSecondary)
                    }
                }
            }
        }
        .padding(14)
        .background(GymTheme.surfaceElevated)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(GymTheme.borderSubtle, lineWidth: 1))
    }

    // MARK: - 2. Regionale Balance mit integrierten Schwachstellen & Defiziten
    private func regionalOverviewSection(report: DeepMuscleAnalysisReport) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("REGIONALE BALANCE & TIEFENSTABILITAET")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(0.8)
                    .foregroundColor(GymTheme.textSecondary)
                Spacer()
                Text("12 Regionen • Tippen fuer Einheiten")
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .foregroundColor(GymTheme.cyanAccent)
            }

            VStack(spacing: 8) {
                ForEach(MuscleRegion.allCases) { reg in
                    let score = report.regionHealth[reg] ?? 0.0
                    let regionMuscles = DeepMuscleIndex.allMuscles.filter { $0.region == reg }
                    let regionDeficits = report.criticalDeficits.filter { $0.muscle.region == reg }
                    let hasDeficits = !regionDeficits.isEmpty

                    Button {
                        selectedRegion = reg
                        HapticFeedback.light()
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: reg.systemIcon)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(hasDeficits ? Color(hex: "E74C3C") : (score >= 50.0 ? GymTheme.sageGreen : Color(hex: "F39C12")))
                                    .frame(width: 22)

                                Text(reg.rawValue)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(GymTheme.textPrimary)

                                Text("• \(regionMuscles.count) Einheiten")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(GymTheme.textSecondary)

                                Spacer()

                                // Dynamisches Defizit- / Balance-Abzeichen
                                if hasDeficits {
                                    HStack(spacing: 4) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .font(.system(size: 8.5))
                                        Text("\(regionDeficits.count) DEFIZIT\(regionDeficits.count == 1 ? "" : "E")")
                                            .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                                    }
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color(hex: "E74C3C").opacity(0.18))
                                    .foregroundColor(Color(hex: "E74C3C"))
                                    .cornerRadius(4)
                                } else if score >= 50.0 {
                                    HStack(spacing: 3) {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 8, weight: .bold))
                                        Text("BALANCE")
                                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                                    }
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(GymTheme.sageGreen.opacity(0.15))
                                    .foregroundColor(GymTheme.sageGreen)
                                    .cornerRadius(4)
                                }

                                Text("\(Int(score))%")
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .foregroundColor(hasDeficits ? Color(hex: "E74C3C") : (score >= 50.0 ? GymTheme.sageGreen : Color(hex: "F39C12")))

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(GymTheme.textMuted)
                            }

                            // Bei akuten Defiziten: Spezifische Muskel-Namen direkt auflisten
                            if hasDeficits {
                                HStack(spacing: 5) {
                                    Text("Schwachstelle:")
                                        .font(.system(size: 9.5, weight: .bold))
                                        .foregroundColor(Color(hex: "E74C3C"))
                                    Text(regionDeficits.map { $0.muscle.commonName }.joined(separator: ", "))
                                        .font(.system(size: 9.5, weight: .medium))
                                        .foregroundColor(GymTheme.textSecondary)
                                        .lineLimit(1)
                                }
                                .padding(.top, 1)
                            }

                            // Dynamic Progress Bar
                            GeometryReader { g in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 2).fill(GymTheme.surfaceElevated)
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(hasDeficits ? Color(hex: "E74C3C") : (score >= 50.0 ? GymTheme.sageGreen : Color(hex: "F39C12")))
                                        .frame(width: g.size.width * CGFloat(min(1.0, score / 100.0)))
                                }
                            }
                            .frame(height: 4)
                        }
                        .padding(12)
                        .background(GymTheme.surface)
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(hasDeficits ? Color(hex: "E74C3C").opacity(0.35) : GymTheme.borderSubtle, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Pop-up Sheet fuer Anatomische Einheiten der Region (mit Defizit-Hervorhebung)
struct RegionUnitsPopupSheet: View {
    let region: MuscleRegion
    let score: Double
    let report: DeepMuscleAnalysisReport
    @Environment(\.dismiss) private var dismiss

    private var regionMuscles: [AnatomicalMuscleEntity] {
        DeepMuscleIndex.allMuscles.filter { $0.region == region }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                GymTheme.bg.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Region Header Card
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(GymTheme.surfaceElevated)
                                    .frame(width: 44, height: 44)
                                Image(systemName: region.systemIcon)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(GymTheme.cyanAccent)
                            }

                            VStack(alignment: .leading, spacing: 3) {
                                Text(region.rawValue)
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(GymTheme.textPrimary)

                                Text("\(regionMuscles.count) Anatomische Einheiten • Balance-Score: \(Int(score))%")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(score >= 50.0 ? GymTheme.sageGreen : Color(hex: "F39C12"))
                            }
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(GymTheme.surfaceElevated)
                        .cornerRadius(12)

                        // Anatomical units list
                        VStack(alignment: .leading, spacing: 10) {
                            Text("ANATOMISCHE EINHEITEN DER REGION (\(regionMuscles.count))")
                                .font(.system(size: 10, weight: .bold))
                                .tracking(0.8)
                                .foregroundColor(GymTheme.textMuted)

                            ForEach(regionMuscles) { m in
                                muscleUnitCard(m)
                            }
                        }

                        Spacer(minLength: 20)
                    }
                    .padding(16)
                }
            }
            .navigationTitle(region.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Schliessen") {
                        dismiss()
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(GymTheme.textPrimary)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func muscleUnitCard(_ m: AnatomicalMuscleEntity) -> some View {
        let isDeep = m.tier == .deepStabilizer
        let deficit = report.criticalDeficits.first(where: { $0.muscle.id == m.id })
        let isDeficient = (deficit != nil)

        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(m.commonName)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(GymTheme.textPrimary)
                    Text(m.latinName)
                        .font(.system(size: 11, weight: .medium))
                        .italic()
                        .foregroundColor(GymTheme.accentGold)
                }

                Spacer()

                if isDeficient {
                    HStack(spacing: 3) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 8))
                        Text("DEFIZIT")
                            .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color(hex: "E74C3C").opacity(0.18))
                    .foregroundColor(Color(hex: "E74C3C"))
                    .cornerRadius(4)
                } else {
                    Text(isDeep ? "TIEFENSCHICHT" : "OBERFLAECHE")
                        .font(.system(size: 8.5, weight: .heavy, design: .monospaced))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(isDeep ? GymTheme.strongBlue.opacity(0.18) : GymTheme.surfaceElevated)
                        .foregroundColor(isDeep ? GymTheme.strongBlue : GymTheme.textSecondary)
                        .cornerRadius(4)
                }
            }

            if let d = deficit {
                HStack(spacing: 8) {
                    Text("Reiz-Status: \(Int(d.currentStrengthScore))/100")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(hex: "E74C3C"))
                    Text("• Zuletzt stimuliert: vor \(d.daysSinceLastStimulus) Tagen")
                        .font(.system(size: 10))
                        .foregroundColor(GymTheme.textSecondary)
                }
                .padding(.vertical, 2)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("Biomechanische Funktion:")
                    .font(.system(size: 9.5, weight: .bold))
                    .foregroundColor(GymTheme.textMuted)
                Text(m.primaryFunction)
                    .font(.system(size: 11))
                    .foregroundColor(GymTheme.textPrimary)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("Klinischer Nutzen & Rumpfschutz:")
                    .font(.system(size: 9.5, weight: .bold))
                    .foregroundColor(Color(hex: "00B4D8"))
                Text(m.clinicalSignificance)
                    .font(.system(size: 11))
                    .foregroundColor(GymTheme.textSecondary)
                    .lineSpacing(1.5)
            }

            if m.isBWKCoreCritical {
                HStack(spacing: 6) {
                    Text("Athletik-Schutz:")
                        .font(.system(size: 9.5, weight: .bold))
                        .foregroundColor(Color(hex: "00B4D8"))
                    Text("Kritischer Kernstabilisator (Aktive Bauchwandkontrolle)")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Color(hex: "00B4D8"))
                }
            }
        }
        .padding(12)
        .background(GymTheme.surface)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(isDeficient ? Color(hex: "E74C3C").opacity(0.4) : GymTheme.borderSubtle, lineWidth: 1))
    }
}
