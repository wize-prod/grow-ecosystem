import SwiftUI

public struct PhysiologicalStatement: Identifiable, Hashable {
    public var id: String { text }
    public let text: String
    public let color: Color

    public init(text: String, color: Color) {
        self.text = text
        self.color = color
    }
}

public struct NutritionalScoresView: View {
    public let score: ComprehensiveNutritionScore
    public var compact: Bool = false

    public init(score: ComprehensiveNutritionScore, compact: Bool = false) {
        self.score = score
        self.compact = compact
    }

    public var body: some View {
        if compact {
            compactScorePills
        } else {
            fullScoreCard
        }
    }

    // MARK: - Compact Score Pill (Pure Indicator & Score, Zero Clutter)
    private var compactScorePills: some View {
        HStack(spacing: 6) {
            if !score.hasSufficientData {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Theme.textMuted)
                        .frame(width: 6, height: 6)
                    Text("KEINE NÄHRWERTE")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundColor(Theme.textMuted)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Theme.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.border, lineWidth: 1))
            } else {
                HStack(spacing: 5) {
                    Circle()
                        .fill(compositeGradeColor(score.compositeGrade))
                        .frame(width: 6, height: 6)
                    Text("GESUNDHEITS-SCORE: \(score.compositeHealthIndex)/100")
                        .font(.system(size: 9, weight: .black, design: .monospaced))
                        .foregroundColor(Theme.textPrimary)
                    Text("[\(score.compositeGrade)]")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundColor(compositeGradeColor(score.compositeGrade))
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Theme.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(compositeGradeColor(score.compositeGrade).opacity(0.35), lineWidth: 1))
            }

            Spacer(minLength: 0)
        }
    }

    // MARK: - Full Score Card (Single Personalized Score + Clear Qualitative Statements)
    private var fullScoreCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("PERSÖNLICHER GESUNDHEITS-SCORE")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(Theme.warmSand)
                        .tracking(1.0)
                    Text("Synthese aus Nährstoffdichte, Viszeral-Reha & Magenphysiologie")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(Theme.textMuted)
                }
                Spacer()
            }

            if !score.hasSufficientData {
                VStack(spacing: 10) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 26))
                        .foregroundColor(Theme.warmSand)
                    Text("KEINE NÄHRWERTDATEN HINTERLEGT")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(Theme.textPrimary)
                    Text("Für diesen Artikel wurden weder Makronährstoffe noch Mikronährstoffe erfasst. Ein Nährwert-Score wird daher nicht berechnet.")
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(Theme.textMuted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 22)
                .background(RoundedRectangle(cornerRadius: 10).fill(Theme.surfaceElevated))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border, lineWidth: 1))
            } else {
                // Unified Hero Score Card with Indication Color & Full Width Gauge
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .center) {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(compositeGradeColor(score.compositeGrade))
                                .frame(width: 12, height: 12)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(score.compositeVerdict)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(Theme.textPrimary)
                                Text(ratingSubtitle(score.compositeGrade))
                                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                                    .foregroundColor(Theme.textMuted)
                            }
                        }
                        Spacer()
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text("\(score.compositeHealthIndex)")
                                .font(.system(size: 28, weight: .black, design: .monospaced))
                                .foregroundColor(compositeGradeColor(score.compositeGrade))
                            Text("/100")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(Theme.textMuted)
                        }
                    }

                    // Continuous Visual Indication Gauge
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Theme.surface)
                                .frame(height: 6)
                            Capsule()
                                .fill(compositeGradeColor(score.compositeGrade))
                                .frame(width: max(8, geo.size.width * CGFloat(min(100, max(0, score.compositeHealthIndex))) / 100.0), height: 6)
                        }
                    }
                    .frame(height: 6)
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12).fill(Theme.surfaceElevated))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(compositeGradeColor(score.compositeGrade).opacity(0.35), lineWidth: 1))

                // Synthesized Physiological Statements (Engine turns numbers into clear statements)
                VStack(alignment: .leading, spacing: 8) {
                    Text("ERNÄHRUNGSPHYSIOLOGISCHE BEWERTUNG")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(Theme.textMuted)
                        .tracking(0.8)

                    VStack(alignment: .leading, spacing: 7) {
                        ForEach(clinicalStatements(for: score)) { statement in
                            HStack(alignment: .top, spacing: 8) {
                                Circle()
                                    .fill(statement.color)
                                    .frame(width: 6, height: 6)
                                    .padding(.top, 4)
                                Text(statement.text)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(Theme.textPrimary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 12).fill(Theme.surfaceElevated))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 1))

                // Minimalist Status Indicators (Pure Color Dots, Zero Algebraic Formulas)
                HStack(spacing: 8) {
                    statusPill(label: "FETT", color: trafficColor(score.trafficLightFat))
                    statusPill(label: "GES. FETT", color: trafficColor(score.trafficLightSatFat))
                    statusPill(label: "ZUCKER", color: trafficColor(score.trafficLightSugar))
                    statusPill(label: "SALZ", color: trafficColor(score.trafficLightSalt))
                }
            }
        }
        .padding(14)
        .background(Theme.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.border, lineWidth: 1))
    }

    // MARK: - Helpers & Engine Logic
    private func statusPill(label: String, color: Color) -> some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(label)
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(color.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(color.opacity(0.3), lineWidth: 1))
    }

    private func clinicalStatements(for s: ComprehensiveNutritionScore) -> [PhysiologicalStatement] {
        var list: [PhysiologicalStatement] = []

        // 1. Protein & Regeneration
        if s.bpiProteinIndex >= 8.0 {
            list.append(PhysiologicalStatement(text: "Hervorragende Proteindichte für Muskelschutz und aktive Regeneration.", color: Theme.sageGreen))
        } else if s.bpiProteinIndex >= 5.0 {
            list.append(PhysiologicalStatement(text: "Solide Proteinquelle zur Deckung des täglichen Aminosäurenbedarfs.", color: Theme.sageGreen))
        } else {
            list.append(PhysiologicalStatement(text: "Geringer Proteinanteil – Kombination mit einer Proteinkomponente empfohlen.", color: Theme.warmSand))
        }

        // 2. Visceral Reha & Pelvic Floor (BWK Ulm Standard, Bristol Type 4)
        if s.bwkVisceralRehaScore >= 75 {
            list.append(PhysiologicalStatement(text: "Hohe Ballaststoffdichte zur Stuhlregulation und Bauchraumentlastung (Ziel: Bristol-Typ 4).", color: Theme.sageGreen))
        } else if s.bwkVisceralRehaScore >= 50 {
            list.append(PhysiologicalStatement(text: "Ausgewogener Faseranteil zur Unterstützung einer geregelten Darmpassage.", color: Theme.sageGreen))
        } else {
            list.append(PhysiologicalStatement(text: "Geringe Ballaststoffdichte – Ergänzung durch lösliche Fasern ratsam.", color: Theme.warmSand))
        }

        // 3. Gastric & Reflux Protection (LPR)
        if s.lprSafetyScore >= 75 {
            list.append(PhysiologicalStatement(text: "Magenschonend und refluxsicher – für abendliche Mahlzeiten optimal geeignet.", color: Theme.sageGreen))
        } else if s.lprSafetyScore >= 50 {
            list.append(PhysiologicalStatement(text: "Moderat fetthaltig – vorzugsweise vor 18:30 Uhr verzehren.", color: Theme.warmSand))
        } else {
            list.append(PhysiologicalStatement(text: "Erhöhter Fett- oder Reizstoffgehalt – mindestens 3 Stunden vor der Nachtruhe verzehren.", color: Theme.terracotta))
        }

        // 4. Food Matrix & Processing Level (NOVA)
        if s.novaClass <= 1 {
            list.append(PhysiologicalStatement(text: "Minimal verarbeitet aus naturbelassenen Vollwert-Zutaten.", color: Theme.sageGreen))
        } else if s.novaClass == 2 {
            list.append(PhysiologicalStatement(text: "Naturbelassene kulinarische Grundzutat.", color: Theme.sageGreen))
        } else if s.novaClass == 3 {
            list.append(PhysiologicalStatement(text: "Handwerklich verarbeitetes Lebensmittel mit ausgewogener Nährstoffmatrix.", color: Theme.warmSand))
        } else {
            list.append(PhysiologicalStatement(text: "Industriell verarbeitet – Verzehrfrequenz im Wochenplan bewusst steuern.", color: Theme.terracotta))
        }

        // 5. Electrolyte & Vascular Balance (K:Na)
        if s.potassiumSodiumRatio >= 2.0 {
            list.append(PhysiologicalStatement(text: "Günstiges Kalium-Natrium-Verhältnis zur Stabilisierung von Gefäßtonus und Blutdruck.", color: Theme.sageGreen))
        } else if s.potassiumSodiumRatio < 1.0 && s.trafficLightSalt == .red {
            list.append(PhysiologicalStatement(text: "Erhöhter Natriumanteil – auf ausreichende Hydratation achten.", color: Theme.terracotta))
        }

        // 6. Glycemic Dynamic
        if s.glycemicIndex <= 55 {
            list.append(PhysiologicalStatement(text: "Niedrige glykämische Last für stabile Blutzuckerwerte ohne reaktive Insulinkurven.", color: Theme.sageGreen))
        } else if s.glycemicIndex >= 70 {
            list.append(PhysiologicalStatement(text: "Schnelle Glukosefreisetzung – vorzugsweise im zeitlichen Umfeld von Trainingseinheiten.", color: Theme.warmSand))
        }

        return list
    }

    private func ratingSubtitle(_ grade: String) -> String {
        switch grade.uppercased() {
        case "A+": return "Exzellent (Klinischer Spitzenstandard)"
        case "A":  return "Optimal (Empfohlenes Nährstoffprofil)"
        case "B":  return "Gut (Ausgewogene Nährstoffmatrix)"
        case "C":  return "Moderat (Gezielte Ergänzung sinnvoll)"
        case "D":  return "Anpassung erforderlich"
        default:   return "Standard"
        }
    }

    private func trafficColor(_ color: TrafficLightColor) -> Color {
        switch color {
        case .green: return Theme.sageGreen
        case .amber: return Theme.warmSand
        case .red:   return Theme.terracotta
        }
    }

    private func compositeGradeColor(_ grade: String) -> Color {
        switch grade.uppercased() {
        case "A+": return Theme.sageGreen
        case "A":  return Theme.sageGreen
        case "B":  return Theme.warmSand
        case "C":  return Color.orange
        case "D":  return Theme.terracotta
        default:   return Theme.textMuted
        }
    }
}
