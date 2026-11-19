# Grow Ecosystem Architectural Design & Layout Guide
**Version:** 2026.1  
**Status:** Canonical & Mandatory Architecture Directive  
**Geltungsbereich:** Alle nativen Swift/SwiftUI-Applikationen im Workspace (`NutriVaultApp`, `GrowFinance`, `GrowCare`, `GrowStudy`, `GymApp`) über iPhone, iPad mini und Mac.

---

## 1. Geräte- & Plattform-Zuordnungsmatrix

| Plattform / Gerät | Zugeordnete Kern-Applikationen | Formfaktor & Navigationsarchitektur |
| :--- | :--- | :--- |
| **iPhone** (16 Pro Max / 17 Pro) | **Growcery**, **Grow** | Kompakter Einhand-Fokus (`compactHorizontal`). Bottom TabBar (`TabView`), Dynamic Island HUD (Leading & Trailing Wings), konzentrische Kapsel-Buttons mit Standard-Außenabständen. |
| **iPad mini** (A17 Pro) | **GrowCare**, **Growcery** | Multitasking-Brücke (`regularHorizontal`). Haupt-Sektionsumschalter im `.principal`-Toolbar-Slot (spart 50–70 pt vertikale Bauhöhe), native `.searchable`-Integration, Null schwebende Bottom-Docks. |
| **Mac** (MacBook Air M4) | **GrowFinance** | Weite Daten-Leinwand. Sidebar- & Tabellenstrukturen, Inspektor-Panels, Hard Scroll Edge Boundaries, direkte SQLite-Anbindung (`haushaltsbuch.db`), 5-Gate Kauf-Freigabe-Audit. |

---

## 2. Navigation, Toolbars & Bar-Architektur (Apple HIG 2025/2026)

### 2.1 Das Verbot schwebender Overlay-Docks (*Zero-Floating-Docks*)
* **Verboten:** Manuelle ZStack-Docks am unteren Bildschirmrand (`InventoryBottomBarView`, `bottomSearchAndActionBar` etc.), die über dem Content schweben, Schlagschatten werfen und künstliche Scroll-Paddings (`.padding(.bottom, 120)`) erzwingen.
* **Standard:** Vollflächige ScrollViews, bei denen der Inhalt unter den Navigations- und Toolbars hindurchgleitet (`ignoresSafeArea`). Kontrast und Lesbarkeit werden ausschließlich über den nativen System-Materialeffekt (*Scroll Edge Effect*) hergestellt.

### 2.2 Toolbar-Komposition & Hierarchie
1. **Leading Slot:**
   * Navigationskontext, Zurück-Buttons oder Benutzer-Identifikatoren (z. B. `FinanceCircularProfileButton`, Heute-Datums-Reset).
2. **Principal Slot (Mitte):**
   * Auf iPadOS und breiten Fenstern: Einbindung des Segmented Pickers (`Picker.pickerStyle(.segmented)`) direkt in die Toolbar:
     ```swift
     ToolbarItem(placement: .principal) {
         Picker("", selection: $selectedTab) { ... }
             .pickerStyle(.segmented)
             .frame(maxWidth: 420)
     }
     ```
3. **Trailing Slot (Aktions-Cluster):**
   * **Randlose SF Symbols:** Filter (`line.3.horizontal.decrease`) und More-Menü (`ellipsis`) ohne künstliche Umrandungskapseln.
   * **Single Prominent Action (`.prominent`):** Genau ein solitäres, getöntes Bedienelement ganz rechts außen:
     * Growcery: `plus` (Mahlzeit erfassen / Rezept) bzw. `barcode.viewfinder` (Vorrat).
     * GrowFinance: `plus` (Einnahmequelle) bzw. `camera.fill` (Beleg-Scanner).

### 2.3 Trennung von Text und Symbolen in Button-Gruppen
* Buttons, die sich einen gemeinsamen Liquid-Glass-Hintergrund teilen, dürfen niemals Icons mit Text mischen (z. B. Icon direkt neben „Auswählen“), da dies perzeptiv als ein einziger Button wahrgenommen wird.
* Text-Buttons stehen immer auf einem separaten Container.

---

## 3. Formensprache & Konzentrische Geometrie (*Concentric Radii*)

Das Interface spiegelt die physische Krümmung der Hardware wider. Es existieren genau 3 Formtypen:

1. **Fixed Shapes:** Feste Eckenradien für isolierte Standard-Karten (z. B. `16 pt` in `.wellnessCard()` und `.financeCardStyle()`).
2. **Capsules ($r = \frac{h}{2}$):** Für Schalter, Segment-Pills, Status-Badges und primäre Touch-Ziele auf iOS/iPadOS.
3. **Concentric Shapes:** Berechnen ihren Eckenradius mathematisch nach der Heuristik:
   $$\text{Innerer Radius} = \text{Äußerer Radius} - \text{Padding}$$
   * Verhindert optische Verzerrungen („eingeklemmte“ oder „aufgeweitete“ Ecken).
   * Bei Schachtelungen in System-Containern ist `ContainerRelativeShape` einzusetzen.

---

## 4. Semantische Farb-Doktrin & Kontrast-Hierarchie

### 4.1 Farbraum & Spezifikation
Keine redundanten oder verwirrenden Farbbedeutungen. Farben kommunizieren ausschließlich Zweck und Status:

| Semantische Rolle | System-Farbe | Dark-Mode-Wert | Verwendung |
| :--- | :--- | :--- | :--- |
| **Canvas Base** | `systemBackground` / OLED | `#000000` / `#0D0D0D` | Grund-Ebene aller ScrollViews |
| **Karten Primary** | `secondarySystemGroupedBackground` | `#1C1C1E` / `#161616` | Standard `.wellnessCard()`, `.financeCardStyle()` |
| **Sub-Cards Secondary** | `tertiarySystemGroupedBackground` | `#2C2C2E` / `#212121` | Eingebettete Container, Badge-Hintergründe |
| **Positiv / Erfüllt** | `systemGreen` | `#30D158` | Zielerreichung (Protein, Kalorien, Stock vorrätig) |
| **Sekundär / Schwebe** | `systemCyan` | `#3CD3FE` | Offene Supplement-Aktionen, Wasser-HUD, Filter-Pills |
| **Gefahr / Blockade** | `systemRed` | `#FF4245` | Fehlende Zutaten, 5-Gate Veto, Leaks, Defizite |
| **Primäraktion** | `systemBlue` | `#0091FF` / `#0A84FF` | Navigation, Haupt-Aktionen, Essen-Buttons |

### 4.2 Inclusive Color & Dual Encoding
* Statusinformationen werden niemals allein durch Farbe codiert.
* Jeder Farbindikator besitzt zwingend ein begleitendes SF Symbol und ein Text-Label (z. B. `checkmark` + "SOFORT KOCHBAR" vs. `exclamationmark.triangle` + "BLOCKIERT").
* Zur Vermeidung von Blend-Effekten im Dark Mode wird gebrochenes Weiß (`#F2F2F7` / `textPrimary`) auf tiefschwarzem Grund verwendet (Kontrastverhältnis $> 7:1$).

---

## 5. Typografie-Standard (`GrowTypography`)

Ausnahmslose Nutzung von Apples System-Schriftfamilie:
* **Fließtext & Hierarchie (`SF Pro`):**
  * `largeTitle` ($32\text{ pt}$, Bold)
  * `title1` bis `title3` ($24\text{ bis }17\text{ pt}$, Semibold/Bold)
  * `headline` / `body` ($15\text{ bis }14\text{ pt}$, Regular/Medium/Semibold)
  * `caption` / `micro` ($11\text{ bis }10\text{ pt}$, Medium/Bold)
  * **Verbot:** Dünne Schnitte (*Ultralight*, *Thin*, *Light*) sind im gesamten System unzulässig.
* **Finanzen, Zähler & Metriken (`SF Mono / Tabular Numbers`):**
  * `metricHero` ($38\text{ pt}$, Bold, Monospaced)
  * `metricLarge` ($28\text{ pt}$, Bold, Monospaced)
  * `badgeMono` ($9.5\text{ pt}$, Bold, Monospaced)
  * Alle Geldbeträge, Gramm-Werte und Timer nutzen `.monospacedDigit()`, um horizontales Layout-Zittern (*layout jitter*) bei Wertänderungen auszuschließen.
* **Symbol-Weight-Harmonie:** Jedes SF Symbol übernimmt exakt das typografische Gewicht des umgebenden Textes (`.medium`, `.semibold` oder `.bold`).

---

## 6. Live Activities & Dynamic Island Spezifikation (HIG 2026)

Jede Live Activity unterstützt vier standardisierte Präsentationen:
1. **Compact Presentation ($62{,}33 \times 36{,}67\text{ pt}$):**
   * Snug an die TrueDepth-Kamera angepasst.
   * Leading Wing: Kernmetrik (z. B. eingenommenes Protein `flame.fill`).
   * Trailing Wing: Zeittakt oder Restbedarf.
2. **Limited Width Presentation ($28 \times 28\text{ pt}$ Kreis):**
   * Im Querformat auf dem iPhone schrumpft die Anzeige auf ein 28 pt-Kürzel oder Einzelsymbol (`isDynamicIslandLimitedInWidth`).
3. **Minimal Presentation ($36{,}67\text{ bis }45\text{ pt}$):**
   * Bei mehreren aktiven Aktivitäten detached als Kreis/Oval.
4. **Expanded Presentation & Lock Screen ($408 \times 84\text{ bis }160\text{ pt}$):**
   * $14\text{ pt}$ Standard-Marge, $36\text{ pt}$ Eckenradius, interaktives HUD.
* **Lebenszyklus:** Maximal 8 Stunden Laufzeit. Unmittelbare Beendigung nach Ereignisabschluss; 15–30 Minuten Zusammenfassung auf dem Lock Screen.

---

## 7. UX Writing, Tonalität & Zero-Emoji Doktrin

1. **Strikte Zero-Emoji-Doktrin:**
   * Null Emojis in Benutzeroberflächen, Alerts, Quellcode-Kommentaren, Menüs oder Dokumentationen.
2. **Tonalität:**
   * Nüchtern, akademisch, diszipliniert und militärisch-technisch.
   * Verzicht auf emotionale Floskeln („Oops!“, „Super gemacht!“) und werbliche Anbiederung.
3. **Aktionsorientierte Verben:**
   * Buttons tragen klare Verben: „Mahlzeit erfassen“, „Beleg scannen“, „CSV importieren“, „Zurücksetzen“.
4. **Verzicht auf Possessivpronomen:**
   * „Einkaufsliste“ statt „Deine Einkaufsliste“; „Konten“ statt „Meine Konten“.
   * Fehlermeldungen beschreiben die Ursache sachlich und bieten die nächste motorische Lösung an („Datei nicht lesbar. Bitte CSV-Format prüfen.“).

