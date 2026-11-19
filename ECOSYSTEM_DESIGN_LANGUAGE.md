# Grow Ecosystem Design Language: High-Velocity Architecture
**Version:** 2026.3 (Lean & Focused)  
**Status:** Mandatory Directive across `NutriVaultApp`, `GymApp`, `GrowCare`, `GrowStudy`, `GrowFinance`.

---

## 1. Leitphilosophie: Geschwindigkeit, Entlastung & Null UI-Bloat
Das Design dient nicht dekorativer Komplexität oder pseudostrukturierter "Lesbarkeit", sondern **maximaler Ausführungsgeschwindigkeit, kognitiver Ruhe und flüssiger Einhandbedienung**:
1. **Kein UI-Clutter:** Keine horizontalen Knopfbatterien oder verschachtelten Pill-Streifen, die den Bildschirm zupflastern.
2. **Singular Controls:** Mehrere Filterknöpfe werden ausnahmslos zu **einem einzigen Filter-Button mit nativem iOS-Popup-Menü** komprimiert.
3. **Flüssige Reaktionsdynamik:** Sofortiges taktiles Einrasten ohne Trägheit.

---

## 2. Visuelles Fundament & Farb-Hierarchie

| Rolle | Hex / Wert | Semantische Funktion |
| :--- | :--- | :--- |
| **Canvas** | `#000000` | Reines OLED-Schwarz (`ignoresSafeArea()`) |
| **Kartenoberfläche** | `#1C1C1E` | `.wellnessCard()` (18 pt kontinuierlicher Squircle) |
| **Erhöhte Flächen** | `#2C2C2E` | Eingebettete Container, Badges, Suchkapseln |
| **Haarlinie** | `white.opacity(0.08)` | 0.8 pt Lichtkante für Tiefenschärfe |
| **Sage Green** | `#30D158` | Primäraktionen, Zielerreichung, aktiver Status |
| **Warm Sand / Cyan** | `#3CD3FE` | Schwebezustände, Fokusmarkierungen, Pending-Aktionen |
| **Terracotta** | `#FF453A` | Veto, Fehler, Löschaktionen |

---

## 3. Ergonomie: Das kompakte Bottom Command Deck

Auf Großbildschirmen (z. B. iPhone 16 Pro Max, 6,9 Zoll) ist das obere Displaydrittel eine reine Lesezone. Alle interaktiven Werkzeuge liegen gebündelt in **einer einzigen schwebenden Kapsel (42 pt)** im unteren Daumenbereich:

```
+--------------------------------------------------------------+
| [Lupe] [Suchen...]            [Filter v] [Quick-Action / +]  |
+--------------------------------------------------------------+
```

### 3.1 Die Singular-Filter-Regel
* **Verboten:** Aneinandergereihte Reihen von Filter-Chips (`ALLE`, `REWE`, `ALDI`...), die vertikale Höhe und Wischaufwand erzwingen.
* **Verbindlich:** Ein kompakter Menü-Button (`GrowFilterMenuButton`). 
  - Standardzustand: Minimales Symbol (`line.3.horizontal.decrease`).
  - Gefilterter Zustand: Kompakte `sageGreen`-Badge mit dem Namen des aktiven Filters.
  - Interaktion: Ein Tap öffnet sofort das native iOS-Kontextmenü mit Häkchen-Indikator.

### 3.2 ScrollView-Puffer
Um Inhaltsüberdeckung durch das Bottom Deck zu verhindern, erhält die `ScrollView` einen kompakten unteren Puffer von **75 pt** (`Spacer().frame(height: 75)`).

---

## 4. Komponenten-Katalog (`Shared/GrowDesignSystem.swift`)

| Komponente | Signatur / Typ | Ergonomische Funktion |
| :--- | :--- | :--- |
| `.wellnessCard()` | ViewModifier | 18 pt Squircle (`#1C1C1E`) mit 0.8 pt Rand |
| `GrowBottomSearchCapsule` | Container View | Schwebende 42 pt Such- & Filterkapsel für den Daumen |
| `GrowFilterMenuButton` | Menu Button | Singularer Filterknopf mit nativem Kontextmenü |
| `GrowCollapsibleSection` | Accordion | Einklappbarer Sektions-Header mit 90°-Pfeildrehung |
| `GrowCommitBar` | Floating Action Bar | Primäre Bestätigungstaste in `sageGreen` am unteren Rand |
| `GrowInfoExplanationSheet`| Modal Sheet | First-Principles 4-Teiler (Titel, Zweck, Daten, WENN-DANN) |
| `GrowCalendarStrip` | Horizontal Strip | 14-Tage-Datumsleiste mit 36x36 pt Kreis-Badges |
| `GrowBudgetCard` | Progress Card | Monospace-Zahlen mit 6 pt Messkapsel |

---

## 5. Haptik & Reaktions-Physik

* **Schaltflächen (`AppleTactileButtonStyle`):**
  - Kompression: `scaleEffect(0.96)`, `opacity(0.88)`
  - Federung: `.spring(response: 0.25, dampingFraction: 0.75)`
* **Haptisches Feedback:**
  - `GrowHaptics.light()`: Menü-Aufrufe, Filter-Wechsel, Tippen auf Suchfeld.
  - `GrowHaptics.success()`: Quittierungen, erledigte Buchungen.
  - `GrowHaptics.error()`: Ungültige Eingaben, 5-Gate Vetos.

---

## 6. Zero-Emoji-Doktrin
Keine Emojis in Benutzeroberflächen, Code, Dokumenten oder Tooltips. Piktogramme werden ausschliesslich durch semantische Apple SF Symbols dargestellt.

---

## 7. Informations-Repräsentations-Hierarchie (Text vs. Grafik vs. Menü)

Um kognitive Überlastung zu verhindern, gilt ein striktes Darstellungs-Budget. Informationen dürfen niemals als Textblöcke auf Karten geschüttet werden, wenn sie kompakter visualisiert werden können:

| Anwendungsfall | Verbotene Form (Text-Bloat) | Verbindliche Form (Kompakt & Grafisch) |
| :--- | :--- | :--- |
| **Status & Erfüllung** | Text: *"Proteinziel fast erreicht"* | **Grafik:** Apple-Fitness-Ring oder 6 pt Kapselbalken + Monospace-Zahl (`145 / 160 g`) |
| **Qualitäts-Einstufung** | Text: *"Sehr gesund und viele Ballaststoffe"* | **Symbol/Badge:** Nutri-Score Badge (`A` in Grün) oder 6 pt Tag (`HOCH PROTEIN`) |
| **Zustand & Warnung** | Text: *"Achtung, Artikel läuft bald ab"* | **Glyphe:** SF Symbol `exclamationmark.triangle.fill` in Terracotta (`#FF453A`) |
| **Aktions-Optionen** | 4–6 sichtbare Schaltflächen auf einer Karte | **Menü:** Ein kompakter Drei-Punkte-Button (`ellipsis`) mit nativem Kontextmenü |
| **Filter & Parameter** | Horizontale Reihen von Text-Buttons | **Menü-Button:** Ein singularer 32 pt Menü-Button (`line.3.horizontal.decrease`) |
| **Hintergrundwissen** | 3–5 Zeilen Erklärungstext auf der Karte | **i-Box:** SF Symbol `info.circle` (15 pt) öffnet `GrowInfoExplanationSheet` |

### 7.1 Das 2-Zeilen-Kartenlimit
* Eine Hauptkarte oder Zeile darf maximal **2 Textzeilen** enthalten (Titel + 1 Subtitel/Kennzahl).
* Jeglicher weiterführende Fließtext gehört ausnahmslos in ein modales Detail-Sheet.

---

## 8. Tastatur-Wegwisch-Regel (Swipe-Down Dismissal)

Jede scrollbare Ansicht mit einem Texteingabefeld (`TextField`) **MUSS** ausnahmslos die interaktive Tastatur-Wegwisch-Geste implementieren:

```swift
ScrollView {
    // Inhaltsfluss
}
.scrollDismissesKeyboard(.interactively)
```

* **Interaktives Mitgleiten:** Beim Herunterwischen über die Liste oder den Bildschirmrand gleitet die iOS-Software-Tastatur synchron zur Fingerbewegung nach unten aus dem Bild.
* **Hintergrund-Tap-Dismissal:** Ein Tap auf freie Bildschirmflächen oder den `hideKeyboard()`-Trigger schließt das Keyboard sofort ohne Verzögerung.

---

## 9. Icon-Design-System & App-Icon-Systematik

### 9.1 In-App Icon-Standards (SF Symbols)
1. **Typ:** Ausschliesslich Apple SF Symbols im Rendering-Modus `.hierarchical` oder `.monochrome`.
2. **Optische Skalierung:**
   - Mikro-Badges & Tags: $10\text{ bis }12\text{ pt}$, `.semibold`
   - Zeilen- & Menü-Icons: $13\text{ bis }14\text{ pt}$, `.medium`
   - Sektions-Header: $16\text{ pt}$, `.semibold`
   - Hero-Metriken & Empty States: $24\text{ bis }32\text{ pt}$, `.regular`
3. **Farbbindung:** Icons tragen niemals willkürliche Schmuckfarben, sondern strikt semantische System-Tokens (`sageGreen`, `cyan`, `terracotta`, `textSecondary`).

### 9.2 App-Icon-Architektur (Ecosystem Homescreen-Matrix)
Alle 5 Apps bilden auf dem iOS-Homescreen eine monolithische, unverkennbare Werkzeug-Familie:

* **Canvas:** Reines OLED-Tiefschwarz (`#000000`).
* **Kanten-Definition:** Subtile 0.8 pt Lichtkante (`white.opacity(0.12)`) auf dem Squircle.
* **Zentral-Glyphe:** Extrem reduziertes, gestochen scharfes Symbol (belegt exakt 48 % der Icon-Fläche):

| App | Primär-Glyph | Akzentfarbe | Semantische Aussage |
| :--- | :--- | :--- | :--- |
| **NutriVaultApp** (Growcery) | Konzentrische Tri-Rings | `#30D158` (Sage Green) | Biologischer Treibstoff, 160g Protein, Vorrat |
| **GymApp** | Athletische Flamme (`flame.fill`) | `#30D158` mit rotem Kern | Physische Kraft, progressive Überlastung |
| **GrowCare** | Lebensfunke (`sparkles`) | `#3CD3FE` (Eiscyan) | CPAP, 4C Skincare, zirkadiane Hygiene |
| **GrowStudy** | Fokus-Bücher / Terminal | `#30D158` (Sage Green) | Matura, BFD-Zertifikate, HsH Wirtschaftsinformatik |
| **GrowFinance** | Monolithischer Tresor / Trend | `#30D158` (Sage Green) | 5-Gate Kauf-Freigabe, Schulden-Avalanche |

---

## 10. Architektur- & Performance-Governance: Das iterative Beschleunigungs-System

Um zu verhindern, dass die Apps im Laufe der Weiterentwicklung schleichend verlangsamen ("Trägheits-Drift"), ist jedes Update an das **5-Gesetze-Performance-System** und den automatisierten Architektur-Auditor gebunden:

### 10.1 Die 5 Gesetze für maximale Geschwindigkeit (120 Hz ProMotion)
1. **Zero-Allocation im Render-Pass:** 
   - `DateFormatter`, `NumberFormatter` oder `Calendar` dürfen niemals innerhalb von `var body` oder berechneten View-Properties instanziiert werden.
   - Pflicht zur Nutzung des statischen, gecachten Pools: `GrowFormatters` in [`GrowDesignSystem.swift`](file:///Users/parris-campbellnkembi/Developer/GrowWorkspace/Shared/GrowDesignSystem.swift).
2. **Trennung von Render-Tree und Compute-Tree:**
   - Keine rechenintensiven Operationen (`.filter()`, `.sorted()`, Suchbaum-Traversierung) im Render-Zyklus.
   - Daten müssen im Repository, Actor oder ViewModel vorab gefiltert und als O(1) Lookup-Tabellen bereitgestellt werden.
3. **Strikte Lazy-Identität:**
   - Alle dynamischen Listen verwenden zwingend `LazyVStack`.
   - Stabile Identifikatoren (`id: \.id`). Das Generieren von `UUID()` in `ForEach`-Schleifen ist streng verboten, da es die View-Identität zerstört und 100 % Neurendering erzwingt.
4. **Granulare Observation Boundaries:**
   - Große God-Objects (`@ObservedObject` mit dutzenden `@Published`-Feldern) dürfen nicht an Child-Zellen durchgereicht werden.
   - Child-Zellen erhalten ausschließlich primitive Werttypen (`let item: PantryItem`) oder nutzen `.equatable()`, um Render-Kaskaden bei Fremdänderungen zu blockieren.
5. **GPU Compositing Guardrails:**
   - Keine unbegrenzten Gaußschen Weichzeichner (`.blur(radius: > 20)`) auf scrollenden Inhalten.
   - Hardwarebeschleunigung via `.clipShape()` und `.drawingGroup()` bei komplexen Vektoren.

### 10.2 Das iterative Architektur-Prüfwerkzeug (`audit_architecture_and_speed.py`)
Im Verzeichnis [`scripts/audit_architecture_and_speed.py`](file:///Users/parris-campbellnkembi/Developer/GrowWorkspace/scripts/audit_architecture_and_speed.py) steht ein automatisierter Scanner bereit. Er prüft kontinuierlich alle Swift-Dateien auf die 5 Performance-Gesetze und berechnet den **Performance Index (0–100 %)**:

```bash
# Iterativer Architektur- und Speed-Audit
./scripts/audit_architecture_and_speed.py
```

Kein Release wird freigegeben, wenn neue kritische Allokationen oder Compute-Flaschenhälse im UI-Thread nachgewiesen werden.

