import SwiftUI

public struct FinanceInfoTopic: Identifiable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let description: String
    public let technicalContext: String
    
    public init(id: String, title: String, subtitle: String, description: String, technicalContext: String) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.description = description
        self.technicalContext = technicalContext
    }
    
    public static let avalancheTilgung = FinanceInfoTopic(
        id: "avalancheTilgung",
        title: "Avalanche-Tilgungsmethode",
        subtitle: "Mathematische Zinsminimierung",
        description: "Die Debt-Avalanche-Strategie priorisiert Kredite mit den hoechsten Zinssaetzen. Hier wird die Targobank-Kreditverbindlichkeit durch die monatliche Mindestrate von 274,70 EUR sowie eine zusaetzliche Sondertilgung von 1.000,00 EUR maximal schnell abgebaut, um Zinseszinseffekte zu eliminieren.",
        technicalContext: "Referenz: Haushaltsbuch-Doktrin & Targobank Kreditvertrag. Zinsvorteil durch vorzeitige Tilgung: Vermeidung von ueber 1.400 EUR Gesamtzinslast bis Juni 2027."
    )
    
    public static let safeToSpend = FinanceInfoTopic(
        id: "safeToSpend",
        title: "Frei verfuegbar (Safe-to-Spend)",
        subtitle: "Echtzeit-Ausgabenkorridor",
        description: "Berechnet den real verfuegbaren Betrag fuer den restlichen Monat. Zieht vom aktuellen PLUS-KONTO-Guthaben den festen Dispo-Schutzpuffer (100,00 EUR) sowie alle noch ausstehenden fixen Monatsverbindlichkeiten ab.",
        technicalContext: "Formel: Guthaben - 100 EUR Dispo-Puffer - verbleibende Monatsfixkosten. Verhindert unbemerkten Kontoueberzug vor Monatsabschluss."
    )
    
    public static let dispoSchutz = FinanceInfoTopic(
        id: "dispoSchutz",
        title: "Dispositionskredit-Schutz",
        subtitle: "Puffer gegen Zinsfallen",
        description: "Ein eiserner Mindestbestand von 100,00 EUR auf dem PLUS-KONTO. Faellt das Girokonto unter diese Schwelle, fallen Dispositionszinsen von 13,73% bis 16,73% p.a. an. Das System warnt proaktiv vor jeder Unterschreitung.",
        technicalContext: "Geregelt gemaess Gate-2-Finanzdoktrin. Verhindert unnoetige Zinsabfluesse an die Bank."
    )
    
    public static let belegScanner = FinanceInfoTopic(
        id: "belegScanner",
        title: "Targobank Beleg-Scanner",
        subtitle: "OCR-Transaktionserfassung",
        description: "Erkennt Transaktionsdaten direkt aus Screenshots der mobilen Targobank-App via Apple Vision OCR. Liest Datum, Betrag, Buchungspartner und Verwendungszweck vollstaendig offline aus.",
        technicalContext: "Integrierte Duplikaterkennung gleicht Betrag, Datum und Textmuster mit bestehenden Buchungen und gespeicherten Belegen ab, um Doppelbuchungen auszuschliessen."
    )
    
    public static let kontoFilter = FinanceInfoTopic(
        id: "kontoFilter",
        title: "Konto-Filterung",
        subtitle: "Segmentierte Buchungsansicht",
        description: "Ermoeglicht die gezielte Filterung der Transaktionsliste nach einzelnen Targobank-Konten (Girokonto, Tagesgeldkonten oder Online-Kredit) fuer detaillierte Einzelpruefungen.",
        technicalContext: "Filtert Transaktionen anhand der zugeordneten Konto-ID sowie der IBAN-Kennung."
    )
    
    public static let kontenStatus = FinanceInfoTopic(
        id: "kontenStatus",
        title: "Konten- & Vermoegensstatus",
        subtitle: "Aggregierte Kontenuebersicht",
        description: "Zeigt die Salden aller aktiven Konten bei der Targobank inklusive Girokonto, Spar- und Notgroschenkonten sowie des aktuellen Kreditstandes.",
        technicalContext: "Erscheint zur Reduzierung kognitiver Last durch Antippen der Safe-to-Spend Statusanzeige."
    )
    
    public static let smartEngine = FinanceInfoTopic(
        id: "smartEngine",
        title: "Dynamische Finanz-Engine",
        subtitle: "Echtzeit-Run-Rate-Analyse",
        description: "Analysiert Ausgabegeschwindigkeit, Resttage des Monats, Sparquoten und potenzielle Konsum-Leaks in Echtzeit. Passt Empfehlungen kontinuierlich an das verbleibende Tagesbudget an.",
        technicalContext: "Berechnet taegliche Verbrennungsrate (Burn Rate) und prognostiziert den Monatsendstand."
    )
}

public struct FinanceInfoExplanationSheet: View {
    @Environment(\.dismiss) private var dismiss
    public let topic: FinanceInfoTopic
    
    public init(topic: FinanceInfoTopic) {
        self.topic = topic
    }
    
    public var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(topic.subtitle.uppercased())
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(red: 0.2, green: 0.6, blue: 1.0))
                    
                    Text(topic.title)
                        .font(.system(size: 20, weight: .heavy))
                        .foregroundColor(.white)
                }
                
                Divider()
                    .background(Color.white.opacity(0.15))
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("FUNKTIONSWEISE & ZWECK")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(Color.white.opacity(0.6))
                    
                    Text(topic.description)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(Color.white.opacity(0.9))
                        .lineSpacing(4)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(white: 0.12))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("TECHNISCHE & DOKTRIN-PARAMETER")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(Color.white.opacity(0.6))
                    
                    Text(topic.technicalContext)
                        .font(.system(size: 13, weight: .regular, design: .monospaced))
                        .foregroundColor(Color(white: 0.75))
                        .lineSpacing(3)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(white: 0.08))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Text("SCHLIESSEN")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(white: 0.18))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding(20)
            .background(Color(red: 0.07, green: 0.08, blue: 0.10).ignoresSafeArea())
            .inlineTitleDisplayMode()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color.white.opacity(0.7))
                    }
                }
            }
        }
    }
}
