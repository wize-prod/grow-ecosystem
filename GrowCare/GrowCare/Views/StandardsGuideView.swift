import SwiftUI

public struct StandardsGuideView: View {
    @State private var expandedSection: String? = "pfb"

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Title card
                    VStack(alignment: .leading, spacing: 4) {
                        Text("KLINISCHE STANDARDS & PROTOKOLLE")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .tracking(1.0)
                            .foregroundColor(CareTheme.careLilac)

                        Text("Evidenzbasierte 4C Dermatologie & Kasernendienst")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(CareTheme.textPrimary)
                    }
                    .careCard()

                    // Accordion Cards
                    accordionCard(
                        id: "pfb",
                        title: "4C Pseudofolliculitis Barbae (PFB) Protokoll",
                        subtitle: "JRL Trockenschnitt, 0.5 mm Stoppeln & Tend Skin",
                        icon: "scissors",
                        content: """
                        1. Grundregel: Nassrasur mit Klinge fuehrt bei gekruemmtem 4C-Haarfollikel unweigerlich zu subkutanem Einwachsen und Fremdkoerper-Granulomen.
                        2. Trockenschnitt-Doktrin: Ausschliesslich JRL Diamante 2025T Trimmer verwenden. Schnitthoehe 0.5 mm bis 1.0 mm belassen. Klinge parallel zur Wuchsrichtung fuehren, niemals fest in die Haut druecken.
                        3. Tend Skin Antiseptik: Nach dem Schnitt wenige Tropfen Tend Skin auf ein Wattepad geben und punktuell auf Unterkiefer und Hals tupfen (nicht reiben!).
                        4. 24h-Saeuren-Sperre: An Trimmtagen (Tend Skin um 18:00 Uhr) ist das 2% BHA Liquid Peeling am Abend strikt kontraindiziert. Ausschluss chemischer Doppel-Irritation.
                        """
                    )

                    accordionCard(
                        id: "pih",
                        title: "PIH & Breitband-UV-Schutz (Tyrosinase-Hemmung)",
                        subtitle: "Paula's Choice 2% BHA, Azelainsaeure 10% & SPF 50+",
                        icon: "sun.max.fill",
                        content: """
                        1. Postinflammatorische Hyperpigmentierung (PIH): Jeder Entzuendungsherd stimuliert Melanozyten zu uebermaessiger Pigmenteinlagerung bei dunkleren Hauttypen.
                        2. 2% BHA (Salicylsaeure): Lipophile Beta-Hydroxysaeure dringt durch Talg in die Pore ein, loest Keratinpfroepfe und verhindert Follikelblockaden.
                        3. Azelainsaeure 10%: Hemmt kompetitiv das Schluesselenzym Tyrosinase, daempft Rötungen und hellt bestehende Pigmentflecken sanft auf.
                        4. 8-stuendiger UV-Schutz: La Roche-Posay Anthelios SPF 50+ vor Dienstantritt auftragen. Zusaetzlicher 20-Sekunden-Direktauftrag um 12:45 Uhr aus dem Spind-Depot ohne vorheriges Waschen.
                        """
                    )

                    accordionCard(
                        id: "loc",
                        title: "Afro 4C Haarpflege (LOC-Methode)",
                        subtitle: "Liquid, Oil & Cream Feuchtigkeitsversiegelung",
                        icon: "comb.fill",
                        content: """
                        1. High Porosity Challenge: 4C-Locken haben geoeffnete Schuppenschichten, Feuchtigkeit verdunstet extrem schnell, fuehrt zu Sprödigkeit und Bruch unter dem Helm/Muetze.
                        2. Stufe L (Liquid): Kopfhaut und Haare mit warmem Wasser oder Aloe-Vera-Spray anfeuchten.
                        3. Stufe O (Oil): Mielle Rosmarin-Minz-Oel tropfenweise auf die Kopfhaut und die ersten Haarmillimeter einmassieren.
                        4. Stufe C (Cream): Cantu Sheabutter Leave-In Creme zur Schaftversiegelung einarbeiten, Spitzen mit Jamaican Black Castor Oil abschliessen.
                        """
                    )

                    accordionCard(
                        id: "oral",
                        title: "Zahngesundheit & Biofilm-Protokoll (LPR- & Reflux-Schutz)",
                        subtitle: "Schallzahnbuerste, Aminfluorid, TePe Zungenschaber & Interdental",
                        icon: "mouth",
                        content: """
                        1. LPR & Reflux-Schmelzerosion: Stiller Reflux transportiert nachts Magensaeure und Pepsin in den Oropharynx. Saeuren erweichen den Zahnschmelz und demineralisieren die Zahnsubstanz.
                        2. Zungenschaber (TePe Good): 75% aller geruchsbildenden Anaerobier und Plaquebakterien siedeln in den tiefen Krypten der Zungenpapillen. 2-3 sanfte Zuege von hinten nach vorne morgens senken die bakterielle Besiedlung drastisch.
                        3. Schallzahnbuerste (Oral-B iO / Sonicare): 2 Minuten Quadranten-Putztechnik. Andruckkontrolle verhindert mechanische Gingiva-Rezessionen.
                        4. Fluorid-Depoteffekt: Zahnpasta nach dem Putzen nur ausspucken, NIEMALS mit Wasser nachspuelen. Das Aminfluorid-Depot (1400 ppm) benoetigt mindestens 30 Minuten, um die Schmelzkristalle zu haerten.
                        5. Interdental-Reinigung: Zahnseide oder Interdentalbuersten jeden Abend vor dem Putzen anwenden, um 40% der nicht buerstenzugaenglichen Kontaktflaechen zu sanieren.
                        """
                    )

                    accordionCard(
                        id: "groin",
                        title: "Leisten- & Reibungsschutz (Marschhygiene)",
                        subtitle: "Sanfte Reinigung, pH 3.8-5.5 & Reibungsprophylaxe",
                        icon: "shield.lefthalf.filled",
                        content: """
                        1. Sanfte Hautreinigung: Mechanisches Scheuern vermeiden. Sanftes Abspülen mit lauwarmem Wasser und vorsichtiges Trockentupfen.
                        2. Saeureschutzmantel (pH 3.8 - 5.5): Milde Waschlotionen stabilisieren die Barriere und verhindern Irritationen.
                        3. Intertrigo-Prophylaxe (Wolfgelaufen): Lange Märsche und Dienstbekleidung fuehren durch Schweiss und mechanische Reibung zu Reizungen. Vor Belastungen dünn Hirschtalg oder Reibungsschutz auftragen.
                        4. Dexpanthenol-Pflege: Bei Rötungen oder Beanspruchung dünn Dexpanthenol-Salbe auftragen.
                        """
                    )

                    accordionCard(
                        id: "nails",
                        title: "Bundeswehr Marsch- & Fussgesundheit",
                        subtitle: "Unguis incarnatus Praevention, Glasnagelfeile & Urea 15%",
                        icon: "hand.raised.fill",
                        content: """
                        1. Gerader Nagelschnitt-Doktrin: Zehennaegel duerfen im schweren Kampfstiefel NIEMALS oval oder rund geschnitten werden. Rundung der Ecken fuehrt unter dem axialen Druck beim Bergabmarsch unweigerlich zu Unguis incarnatus (eingewachsenem Zehennagel).
                        2. Kantenversiegelung mit Glasfeile: Nach dem Knipsen Kanten gratfrei mit einer professionellen Glasfeile versiegeln, um Faedenfangen und Nagelspaltung zu verhindern.
                        3. Urea 10-15% Keratolyse: Dicke Hornhaut an Fersen und Ballen ist unelastisch und schert bei Marschbelastung als Blase ab. Woechentliche Anwendung von 10-15% Urea spendet Tiefenfeuchtigkeit und baut Verhornungen sanft ab.
                        4. Tinea Pedis Prophylaxe: Kampfstiefel nach dem Dienst lueften, taeglich frische Woll-/Funktionssocken anziehen und Zehenzwischenraeume nach dem Duschen vollstaendig trocknen.
                        """
                    )

                    accordionCard(
                        id: "hair_wash",
                        title: "4C Scalp Detox & Durag-Schlafhygiene",
                        subtitle: "Woechentlicher Wash Day, Tiefenmaske & Reibungsisolation",
                        icon: "comb.fill",
                        content: """
                        1. Scalp Detox Rhythmus: Woechentlich am Sonntag (Wash Day) mit sulfatfreiem Shampoo die Kopfhaut von Sebum und Schweiss befreien. Fingerbeeren, niemals Fingernaegel verwenden.
                        2. Tiefenconditioner (10-15 Min): Hochporoeses 4C-Haar benoetigt regelmaessige Proteine und Feuchtigkeitsmasken unter einer Duschhaube, um Schuppenschichten zu glaetten.
                        3. LOC-Versiegelung: Liquid (Feuchtigkeit), Oil (Mielle Rosmarin-Minze) und Cream (Cantu Leave-in & Jamaican Black Castor Oil).
                        4. Satin Durag / Bonnet Doktrin: Reines Seiden- oder Satintuch vor dem Zubettgehen schuetzt vor Scherkraeften und Feuchtigkeitsentzug durch Baumwollbettwaesche.
                        """
                    )

                    accordionCard(
                        id: "body",
                        title: "Tactical Gear & Follikulitis-Schutz (Acne Mechanica)",
                        subtitle: "Schulter-, Ruecken- und Brustschutz unter Weste & Koppel",
                        icon: "figure.stand",
                        content: """
                        1. Pathomechanismus: Plattentraeger, Schutzwesten und Rucksaecke pressen Schweiss und Bakterien in verstopfte Haarfollikel am Ruecken und Dekollete (Acne Mechanica).
                        2. Post-Dienst Abreinigung: Unmittelbar nach Dienstschluss Schweiss abspuelen. Sanfte Reinigungslotion statt aggressiver Schaelmittel schont die Follikeloeffnungen.
                        3. Hydratation ohne Fettfilm: CeraVe Feuchtigkeitscreme zieht schnell ein und repariert Ceramide, ohne Poren zu verstopfen.
                        """
                    )

                    accordionCard(
                        id: "kaserne",
                        title: "Kasernendienst & Stubenhygiene",
                        subtitle: "Militaerischer Standard gemaess Dienstvorschrift",
                        icon: "shield.fill",
                        content: """
                        1. Stosslueften: Taeglich morgens (06:00 Uhr) und mittags (13:00 Uhr) fuer 5-10 Minuten Fenster ganz oeffnen.
                        2. Spind-Ordnung: T-Shirts und Dienstwaesche kantenrein auf DIN A4 Schablonenmass gefaltet im Spind ablegen.
                        3. Stiefelpflege: Kampfstiefel nach dem Dienst grob abbuersten, Lederbalsam einarbeiten und mit Polierbuerste auf Hochglanz bringen.
                        4. Waesche-Rhythmus: Dienst- und Sportwaesche zweimal woechentlich bei 60 Grad waschen.
                        """
                    )
                }
                .padding(16)
            }
            .background(CareTheme.bg.ignoresSafeArea())
            .navigationTitle("Standards & Guides")
        }
    }

    @ViewBuilder
    private func accordionCard(id: String, title: String, subtitle: String, icon: String, content: String) -> some View {
        let isExpanded = expandedSection == id

        VStack(alignment: .leading, spacing: 10) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    expandedSection = isExpanded ? nil : id
                }
            }) {
                HStack(alignment: .top) {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(CareTheme.careLilac)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(title)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(CareTheme.textPrimary)
                            .multilineTextAlignment(.leading)

                        Text(subtitle)
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(CareTheme.textSecondary)
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(CareTheme.textMuted)
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                Divider().background(CareTheme.border)

                Text(content)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(CareTheme.textSecondary)
                    .lineSpacing(4)
                    .padding(.top, 4)
            }
        }
        .careCard()
    }
}

