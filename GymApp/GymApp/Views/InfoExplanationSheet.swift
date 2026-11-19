import SwiftUI

public struct ExplanationDetail: Identifiable, Hashable {
    public var id: String { label }
    public let label: String
    public let text: String

    public init(label: String, text: String) {
        self.label = label
        self.text = text
    }
}

public struct InfoExplanationItem: Identifiable, Hashable {
    public var id: String { title + category }
    public let title: String
    public let category: String
    public let summary: String
    public let details: [ExplanationDetail]

    public init(title: String, category: String, summary: String, details: [ExplanationDetail] = []) {
        self.title = title
        self.category = category
        self.summary = summary
        self.details = details
    }
}

extension InfoExplanationItem {
    public static let nutritionRings = InfoExplanationItem(
        title: "Konzentrische Ernaehrungsringe",
        category: "Metabolismus & Makros",
        summary: "Die 3 konzentrischen Ringe visualisieren die taegliche Zielerreichung der Makronaehrstoffe. Aeusserer Ring: Protein (Muskelproteinsynthese), Mittlerer Ring: Kohlenhydrate (Glykogenspeicher), Innerer Ring: Fette (Hormonsynthese).",
        details: [
            ExplanationDetail(label: "Protein-Ziel", text: "145 bis 170 g taeglich (Standard ~160 g) sichern den Erhalt fettfreier Koerpermasse und postoperative Geweberegeneration."),
            ExplanationDetail(label: "Kalorienbudget", text: "1.850 bis 2.000 kcal Basis-Erhalt zzgl. aktiver Trainingskalorien via HealthKit & Grow-Bridge."),
            ExplanationDetail(label: "Cross-App Sync", text: "Grow liest Live-Mahlzeiten aus Growcery und uebertraegt verbrannte Trainingskalorien zur dynamischen Budget-Anpassung.")
        ]
    )

    public static let nutritionTiming = InfoExplanationItem(
        title: "Pre- & Post-Workout Timing",
        category: "Sporternaehrung",
        summary: "Praezise Naehrstoff-Zufuhr rund um die Trainingseinheit maximiert die Trainingsleistung und beschleunigt die zellulaere Erholung.",
        details: [
            ExplanationDetail(label: "Pre-Workout (60 min)", text: "30-40 g leicht verdauliche Kohlenhydrate (z.B. Reiswaffel, Banane), 500 ml Wasser, 500 mg Rote-Bete-Extrakt (Nitrat zur Gefaesserweiterung)."),
            ExplanationDetail(label: "Post-Workout (0-45 min)", text: "35-45 g schnell verfuegbares Protein (Whey / Isolat) zur Stimulation von mTOR und MPS, kombiniert mit 40-50 g Kohlenhydraten.")
        ]
    )

    public static let calendarSync = InfoExplanationItem(
        title: "Google Kalender & Dienstbetrieb",
        category: "Zeitmanagement & Taktung",
        summary: "Automatische Synchronisation militaerischer Dienstzeiten, Reha-Bloecke und Trainingseinheiten zur Verhinderung von Planungskonflikten.",
        details: [
            ExplanationDetail(label: "Existenz-Anker", text: "Dienstbetrieb (07:00-16:30 Uhr) und Truppenkuechen-Mahlzeiten sind feste Anker."),
            ExplanationDetail(label: "Dekompressionspuffer", text: "Zwischen Dienstende und Training ist stets ein 15-30 minuetiger Uebergangspuffer eingeplant.")
        ]
    )

    public static let rehaBWKUlm = InfoExplanationItem(
        title: "BWK Ulm Reha-Vorgabe",
        category: "Viszeralchirurgische Reha",
        summary: "Postoperative Entlastung der Bauchwand und des Beckenbodens (Z.n. Analprolaps-Operation BWK Ulm 11/2024).",
        details: [
            ExplanationDetail(label: "Absolutes Verbot", text: "Crunches und klassische Sit-ups sind strikt kontraindiziert, um intraabdominalen Druckanstieg zu verhindern."),
            ExplanationDetail(label: "Erlaubte Stabilisation", text: "Statische Planks, Glute Bridges, Bird-Dog, Deadbugs und Pallof Press.")
        ]
    )

    public static let olympicCoach = InfoExplanationItem(
        title: "Olympic Coach Algorithmus",
        category: "Trainingswissenschaft",
        summary: "Berechnet 1RM-Werte, optimiert Lastzonen (Hypertrophie, Kraftausdauer, Maximalkraft) und steuert dynamische Autoregulation.",
        details: [
            ExplanationDetail(label: "Brzycki & Epley", text: "Wissenschaftliche Formeln zur Schaetzung der Maximalkraft aus Satzgewicht und Wiederholungszahl."),
            ExplanationDetail(label: "RPE & RIR", text: "Subjektive Belastungsskala zur taeglichen Anpassung der Satzintensitaet bei erhoehter Ermuedung.")
        ]
    )

    public static let muscleHeatmap = InfoExplanationItem(
        title: "Anatomische Muskel-Heatmap",
        category: "Biomechanik",
        summary: "Visualisiert Primaer- und Sekundaermuskel-Aktivierung jeder Trainingsuebung und Schablone.",
        details: [
            ExplanationDetail(label: "Stimulus-Score", text: "Berechnet aus Volumen, Last und Kontraktionsprofil zur Vermeidung von Muskeldysbalancen."),
            ExplanationDetail(label: "Farbkodierung", text: "Rot = Hohe primaere Belastung; Gruen = Unterstuetzende Stabilisation.")
        ]
    )

    public static let cardioVagus = InfoExplanationItem(
        title: "Kardiologie & Ruhepuls",
        category: "Autonomes Nervensystem",
        summary: "Sportkardiologisches Belastungsprotokoll und Ueberwachung des Parasympathikus.",
        details: [
            ExplanationDetail(label: "Sinusbradykardie", text: "Ruhepuls ab 30-40 bpm ist bei hohem kardiovaskulaerem Trainingszustand physiologisch (hoher Vagotonus)."),
            ExplanationDetail(label: "Abbruchkriterien", text: "Sofortiger Belastungsstopp bei Synkopen, Schwindel oder retrosternalem Engegefuehl.")
        ]
    )

    public static let lprReflux = InfoExplanationItem(
        title: "LPR & Reflux-Schutz",
        category: "Gastroenterologie",
        summary: "Protokoll zur Vermeidung von stillem Reflux und Kehlkopf-Reizungen.",
        details: [
            ExplanationDetail(label: "3h-Fastenfenster", text: "Strikte Nahrungskarenz mindestens 3 Stunden vor Nachtruhe (ab 19:30 Uhr)."),
            ExplanationDetail(label: "Sphinkter-Relaxantien", text: "Verzicht auf Kaffee, Minze, Schokolade, fette Saucen und Kohlensaeure am Abend.")
        ]
    )
}

public struct InfoExplanationSheet: View {
    public let item: InfoExplanationItem
    @Environment(\.dismiss) private var dismiss

    public init(item: InfoExplanationItem) {
        self.item = item
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header Bar
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.category.uppercased())
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(GymTheme.warmSand)
                            .tracking(1.0)
                        Text(item.title)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(GymTheme.textPrimary)
                    }
                    Spacer()
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Fertig")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(GymTheme.sageGreen)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(GymTheme.surfaceElevated))
                    }
                }
                .padding(16)
                .background(GymTheme.bg)

                Divider().background(GymTheme.border)

                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        // Summary Box
                        VStack(alignment: .leading, spacing: 6) {
                            Text("PHYSIOLOGISCHER MECHANISMUS")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(GymTheme.textMuted)
                                .tracking(0.8)
                            Text(item.summary)
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(GymTheme.textPrimary)
                                .lineSpacing(3)
                        }
                        .padding(12)
                        .somaCard(borderColor: GymTheme.sageGreen.opacity(0.35), background: GymTheme.surfaceElevated)

                        // Detail Rows
                        if !item.details.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("KLINISCHE & METHODISCHE DETAILS")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(GymTheme.textMuted)
                                    .tracking(0.8)

                                VStack(spacing: 8) {
                                    ForEach(item.details) { detail in
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(detail.label)
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(GymTheme.warmSand)
                                            Text(detail.text)
                                                .font(.system(size: 12, weight: .regular))
                                                .foregroundColor(GymTheme.textSecondary)
                                                .lineSpacing(2)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(10)
                                        .somaCard(borderColor: GymTheme.border, background: GymTheme.surface)
                                    }
                                }
                            }
                        }
                    }
                    .padding(16)
                }

                // Bottom Thumb-Zone Dismiss Button (iPhone 16 Pro Max Ergonomie)
                VStack(spacing: 0) {
                    Divider().background(GymTheme.borderSubtle)
                    Button(action: {
                        dismiss()
                        HapticFeedback.light()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 13, weight: .bold))
                            Text("Fertig")
                                .font(.system(size: 15, weight: .bold))
                        }
                        .foregroundColor(GymTheme.bg)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(GymTheme.sageGreen)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
                .background(GymTheme.surfaceElevated.ignoresSafeArea(edges: .bottom))
            }
            .background(GymTheme.bg.ignoresSafeArea())
            .navigationBarHidden(true)
        }
        .presentationDragIndicator(.visible)
    }
}
