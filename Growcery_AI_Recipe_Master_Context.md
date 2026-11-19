# Growcery Master Context & Datenbank für Externe KI (ChatGPT / Claude / Gemini)

> [!NOTE] SYSTEM DIRECTIVE FOR EXTERNAL LLM (CHATGPT / CLAUDE / GEMINI)
> Diese Datei dient als vollständiger Kontext- und Datenbank-Export des NutriVault / Growcery Ökosystems. Verwende die darin definierten physiologischen Zielkorridore, das mathematische Gesundheitsscoring-System und die hinterlegte Rohstoff-Datenbank, um evidenzbasierte, klinisch konforme und direkt umsetzbare Rezepte für den Nutzer zu generieren.

---

## 1. Nutzer-Profil & Verbindliche Physiologische Constraints

| Parameter | Zielkorridor / Vorschrift | Klinische / Operative Begründung |
| :--- | :--- | :--- |
| **Nutzer-Status** | Soldat der Bundeswehr & Student Wirtschaftsinformatik | Hohe kognitive Last, Krafttraining (Hypertrophie), militärischer Dienstbetrieb. |
| **Tägliches Protein-Ziel** | 145 bis 170 g (Standard: 160 g) | Sicherung der Muskelproteinsynthese, Erhalt fettfreier Masse und Sättigung. |
| **Tägliches Kalorien-Budget**| 1.850 bis 2.000 kcal | Isokalorischer Erhalt / Recomposition. |
| **BWK Ulm Viszeral-Reha** | 25 bis 35 g Ballaststoffe täglich | Post-Analprolaps-Operation (11/2024). Strikte Vermeidung von intraabdominalem Pressdruck; Bristol-Stuhlform Typ 4 erzwingen. Hohe Dichte an löslichen Schleimstoffen. |
| **Stiller Reflux (LPR) Schutz** | Strikte Nahrungskarenz 3h vor Nachtruhe | Abends (> 18:30 Uhr) keine Sphinkter-Relaxantien: Kein Kaffee, keine Minze, keine Schokolade, keine rohen Zwiebeln/Knoblauch, Fettgehalt < 15 g/Mahlzeit. |
| **AuDHD Blutzucker-Stabilität** | Niedrige/Moderate Glykämie (GI <= 55) | Kohlenhydrate müssen ausnahmslos an Protein und Ballaststoffe gekoppelt werden (keine isolierten GI-Peaks). |
| **Stuben-Küchen-Infrastruktur** | AirFryer, Mikrowelle, 1-Feld Induktion | Keine Backöfen mit langen Vorheizzeiten. Maximale Zubereitungszeit: 10 bis 15 Minuten. |

---

## 2. Das NutriVault Gesundheitsscoring-System (Die 7 Säulen & Phi-Index)

Die Qualität jeder Zutat und jedes Rezepts wird über den **NutriVault Composite Health Index $\Phi$** (0 bis 100 Punkte) quantifiziert:

$$\Phi = 0{,}25 \cdot 	ext{FoodCompass} + 0{,}20 \cdot 	ext{TyBeal} + 0{,}20 \cdot 	ext{BWK\_Visceral} + 0{,}15 \cdot 	ext{AMDR} + 0{,}10 \cdot 	ext{LPR} + 0{,}10 \cdot 	ext{NOVA\_Score}$$

### 2.1 Die Säulen im Detail:
1. **BWK Ulm Visceral-Reha Score (0 - 100):**
   - Bewertet die Ballaststoffdichte ($\ge 14	ext{ g Ballaststoffe pro } 1.000	ext{ kcal}$ oder $\ge 6	ext{ g} / 100	ext{ g}$).
   - Bonus für lösliche Schleimstoffe (Haferflocken, Leinsamen, Hülsenfrüchte, Beeren).
   - Abzug für hohe Natriummengen ($> 700	ext{ mg}$) und gesättigte Fette ($> 8	ext{ g}$).
   - **Ziel:** Wert $\ge 75$ (Kategorie: *Zielerfüllung Bristol Typ 4*).

2. **LPR Gastric Safety Score (0 - 100):**
   - Misst den Erhalt des unteren Ösophagussphinkter-Tonus (Schutz vor Reflux im Schlaf).
   - Abzug bei Fettgehalt $> 10	ext{ g}$ bzw. $> 20	ext{ g}$ pro 100 g.
   - Harter Malus (-40 Pkt) für bekannte Sphinkter-Relaxantien (Koffein, Pfefferminze, Schokolade, Chili, säurereiche Zitrusfrüchte).
   - **Ziel für Abendmahlzeiten:** Wert $\ge 75$ (Kategorie: *Reflux-Sicher*).

3. **Ty Beal Nutrient-Density Score (0 - 100):**
   - Goldstandard für Nährstoffdichte: Proteinqualität (bis 25 Pkt), Ballaststoffdichte (bis 15 Pkt), Abdeckung von 16 essenziellen Mikronährstoffen (bis 35 Pkt) und Kalium-zu-Natrium-Quotient ($K:\!Na \ge 2{,}0$).

4. **Food Compass Score (Tufts University, 1 - 100):**
   - Bevorzugt unverarbeitete Lebensmittel, gesunde ungesättigte Fettsäuren und bestraft freie Zuckerzusätze sowie exzessives Salz. $\ge 70 = 	ext{Bevorzugen}$.

5. **NOVA-Verarbeitungsstufe (Klasse 1 bis 4):**
   - **NOVA 1 (100 Pkt):** Unverarbeitet / Minimal verarbeitet (Gemüse, Hafer, Eier, Fleisch, Hülsenfrüchte).
   - **NOVA 2 (80 Pkt):** Kulinarische Zutat (Olivenöl, Butter, Salz, Gewürze).
   - **NOVA 3 (55 Pkt):** Verarbeitetes Lebensmittel (Käse, Thunfischdose, Vollkornbrot).
   - **NOVA 4 (20 Pkt):** Ultra-verarbeitet (Fertiggerichte, Softdrinks, Wurstwaren). Rezepte sollen NOVA 4 meiden.

6. **AMDR Protein-Dichte (Acceptable Macronutrient Distribution Range):**
   - Bewertet den Anteil der Kalorien aus Protein. Optimum für Hypertrophie und Sättigung: 25 bis 40 % der Gesamtkalorien.

---

## 3. Vollständige Rohstoff- & Vorrats-Datenbank (107 Artikel)

| ID | Produkt | Marke | Store | Preis | Packung | Bestand | Ort | kcal | Prot | KH | Fett | Ball | Score $\Phi$ | BWK | LPR | NOVA |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `food_1787511014808_16` | Apfel grün | Pantry | PENNY | 2.79 € | 500 g | 0 g | Vorratsschrank | 52 | 0.3g | 12.0g | 0.2g | 2.4g | 74 (B) | 100 | 80 | NOVA 1 |
| `food_1787511043548_42` | Apfel grün | Giffard | PENNY | 1.99 € | 1 g | 0 g | Vorratsschrank | 332 | 0.0g | 83.0g | 0.0g | 2.4g | 65 (C) | 70 | 80 | NOVA 1 |
| `food_1787511014635_15` | Apfel rot Braeburn Deutschland | Pantry | PENNY | 2.29 € | 500 g | 0 g | Vorratsschrank | 52 | 0.3g | 12.0g | 0.2g | 2.4g | 74 (B) | 100 | 80 | NOVA 1 |
| `food_1787511044107_44` | Avocado Stück | Pantry | PENNY | 2.22 € | 1 Stück | 0 Stück | Vorratsschrank | 160 | 2.0g | 2.0g | 15.0g | 6.7g | 70 (B) | 70 | 65 | NOVA 1 |
| `food_1787511017517_35` | Bananen | PENNY | PENNY | 1.20 € | 600 g | 0 g | Vorratsschrank | 89 | 1.1g | 22.8g | 0.3g | 0.0g | 62 (C) | 45 | 95 | NOVA 1 |
| `cat-basmati-reis-191g` | Basmati Reis Spitzenqualität | Golden Sun / Standard | PENNY | 1.99 € | 1000 g | 0 g | Gefrierfach | 358 | 8.5g | 78.0g | 1.0g | 0.0g | 62 (C) | 45 | 95 | NOVA 1 |
| `food_1787511016349_27` | Berida Thunfisch in Sauce | Pantry | PENNY | 1.29 € | 150 g | 0 g | Vorratsschrank | 110 | 25.5g | 0.0g | 1.0g | 0.0g | 59 (C) | 45 | 80 | NOVA 3 |
| `food_1787511015651_21` | Best Moments Mini Cherry Rispentomaten | Pantry | PENNY | 2.99 € | 300 g | 0 g | Vorratsschrank | 20 | 1.1g | 3.2g | 0.2g | 1.2g | 80 (A) | 85 | 80 | NOVA 1 |
| `supp-beta-alanin` | Beta-Alanin Pulver / Kapseln | Creapure / Standard | Amazon | 14.99 € | 500 g | 250 g | Spind | 392 | 98.0g | 0.0g | 0.0g | 0.0g | 71 (B) | 45 | 80 | NOVA 1 |
| `food_1787655672345_106` | Bio Hartweizen Couscous (Natur Gut) | PENNY / Natur Gut | PENNY | 1.49 € | 750 g | 1 g | Vorratsschrank | 349 | 12.0g | 70.0g | 1.5g | 0.0g | 65 (C) | 45 | 80 | NOVA 1 |
| `food_rote_bete_saft` | Bio Rote-Bete-Saft (NO3 Nitrat Booster) | Alnatura / PENNY | PENNY | 1.29 € | 500 ml | 0 ml | Vorratsschrank | 38 | 1.0g | 8.5g | 0.1g | 0.0g | 65 (C) | 45 | 80 | NOVA 1 |
| `food_1787510995500_2` | Bio Zuckermais | Pantry | PENNY | 2.29 € | 400 g | 0 g | Vorratsschrank | 86 | 3.2g | 16.0g | 1.2g | 0.0g | 56 (C) | 45 | 80 | NOVA 2 |
| `food_1787510995469_1` | Bio Zwiebeln | Barilla | PENNY | 1.99 € | 1000 g | 0 g | Vorratsschrank | 72 | 1.4g | 6.2g | 3.7g | 1.7g | 67 (C) | 70 | 80 | NOVA 1 |
| `food_1787511046628_57` | Bonduelle Mais | Pantry | PENNY | 5.37 € | 140 g | 0 g | Vorratsschrank | 80 | 2.9g | 14.5g | 1.1g | 0.0g | 65 (C) | 45 | 80 | NOVA 1 |
| `food_1787511044029_43` | Cashewkerne | Happy Harvest | PENNY | 2.49 € | 500 g | 0 g | Vorratsschrank | 603 | 21.0g | 22.0g | 47.0g | 0.0g | 55 (C) | 20 | 50 | NOVA 1 |
| `food_1787511046768_60` | Chili Gewürzzubereitung (scharf) | Pantry | PENNY | 0.00 € | 250 g | 0 g | Vorratsschrank | 315 | 14.0g | 10.0g | 16.0g | 0.0g | 56 (C) | 20 | 25 | NOVA 1 |
| `food_1787511045065_52` | Corny Haferkraft | CORNY | PENNY | 2.29 € | 500 g | 0 g | Vorratsschrank | 339 | 7.7g | 62.3g | 10.6g | 10.0g | 74 (B) | 85 | 80 | NOVA 1 |
| `food_couscous` | Couscous | Naturgut / PENNY | PENNY | 1.29 € | 500 g | 0 g | Vorratsschrank | 350 | 12.0g | 70.0g | 1.5g | 0.0g | 65 (C) | 45 | 80 | NOVA 1 |
| `food_creme_fraiche` | Crème fraîche légère | Milbona / PENNY | PENNY | 0.89 € | 200 g | 0 g | Vorratsschrank | 160 | 3.0g | 4.0g | 15.0g | 0.0g | 56 (C) | 30 | 65 | NOVA 1 |
| `food_1787511016043_25` | Deutsche Romana Salatherzen | Pantry | PENNY | 1.00 € | 3 Stück | 0 Stück | Vorratsschrank | 15 | 1.2g | 1.8g | 0.2g | 0.0g | 73 (B) | 45 | 80 | NOVA 1 |
| `food_1787584551166_85` | Echtes Vollkornbrot Roggen | PENNY | PENNY | 0.99 € | 500 g | 0 g | Vorratsschrank | 195 | 6.0g | 38.0g | 1.2g | 7.0g | 67 (C) | 85 | 80 | NOVA 3 |
| `food_1787510995665_3` | EIER BH OKT | Pantry | PENNY | 2.49 € | 10 Stück | 0 Stück | Kühlschrank | 140 | 12.5g | 0.7g | 9.5g | 0.0g | 70 (B) | 30 | 80 | NOVA 1 |
| `cat-erdnussbutter-20166076` | Erdnussbutter Creamy / Crunchy | Markenqualität | Supermarkt | 2.49 € | 350 g | 0 g | Vorratsschrank | 600 | 28.0g | 12.0g | 50.0g | 0.0g | 48 (D) | 20 | 50 | NOVA 2 |
| `food_feta` | Feta / Hirtenkäse light | PENNY / Salakis | PENNY | 1.79 € | 200 g | 0 g | Kühlschrank | 175 | 18.0g | 1.0g | 11.0g | 0.0g | 54 (C) | 30 | 65 | NOVA 3 |
| `food_1787511046808_61` | Fleisch Gewürzsalz | Pantry | PENNY | 0.00 € | 400 g | 0 g | Gefrierfach | 110 | 8.0g | 1.9g | 3.8g | 0.0g | 60 (C) | 30 | 80 | NOVA 2 |
| `food_1787584551166_76` | Frische Eier Bodenhaltung M | PENNY | PENNY | 1.99 € | 10 Stück | 0 Stück | Kühlschrank | 143 | 12.8g | 0.7g | 9.9g | 0.0g | 70 (B) | 30 | 80 | NOVA 1 |
| `food_1787511011995_10` | Frühkartoffeln | Coop, Naturaplan | PENNY | 3.58 € | 1562 g | 0 g | Vorratsschrank | 75 | 2.0g | 16.0g | 0.0g | 2.1g | 74 (B) | 85 | 80 | NOVA 1 |
| `cat-tomaten-penny` | Gehackte Tomaten in Tomatensaft | PENNY / San Fabio | PENNY | 0.79 € | 400 g | 0 g | Kühlschrank | 22 | 1.1g | 3.7g | 0.2g | 1.2g | 80 (A) | 85 | 80 | NOVA 1 |
| `food_1787584551166_80` | Geriebener Gouda leicht | PENNY | PENNY | 1.49 € | 200 g | 0 g | Vorratsschrank | 260 | 30.0g | 0.5g | 16.0g | 0.0g | 62 (C) | 20 | 65 | NOVA 1 |
| `food_1787584551166_81` | Gnocchi di Patate Kühlregal | San Fabio / PENNY | PENNY | 0.99 € | 500 g | 0 g | Vorratsschrank | 155 | 3.5g | 33.0g | 0.5g | 0.0g | 61 (C) | 45 | 80 | NOVA 1 |
| `food_reibekaese` | Gouda gerieben (light) | PENNY / Milbona | PENNY | 1.69 € | 200 g | 0 g | Vorratsschrank | 260 | 30.0g | 1.0g | 15.0g | 0.0g | 66 (C) | 30 | 65 | NOVA 1 |
| `food_1787510996316_7` | Granola Haferflocken | Pantry | PENNY | 0.69 € | 500 g | 0 g | Vorratsschrank | 370 | 13.5g | 58.7g | 7.0g | 10.0g | 80 (A) | 85 | 95 | NOVA 1 |
| `food_1787510996021_4` | Greenl. Spinat NG | Pantry | PENNY | 1.89 € | 800 g | 0 g | Vorratsschrank | 23 | 2.8g | 0.8g | 0.4g | 2.7g | 82 (A) | 85 | 80 | NOVA 1 |
| `food_1787511030203_37` | HA-BRUSTFILET | Pantry | PENNY | 6.49 € | 396 g | 0 g | Vorratsschrank | 110 | 23.5g | 0.0g | 1.5g | 0.0g | 71 (B) | 45 | 80 | NOVA 1 |
| `food_1787584551166_79` | Hähnchenbrustfilet frisch | PENNY | PENNY | 3.99 € | 400 g | 0 g | Kühlschrank | 106 | 23.0g | 0.0g | 1.5g | 0.0g | 71 (B) | 45 | 80 | NOVA 1 |
| `food_1787511044764_50` | Iglo Spinat | Pantry | PENNY | 3.49 € | 500 g | 0 g | Vorratsschrank | 23 | 2.8g | 0.8g | 0.4g | 2.7g | 82 (A) | 85 | 80 | NOVA 1 |
| `food_1787511018163_36` | Karotten | Freshona | PENNY | 0.66 € | 476 g | 0 g | Vorratsschrank | 47 | 2.2g | 7.2g | 0.2g | 2.8g | 80 (A) | 85 | 80 | NOVA 1 |
| `food_1787511044214_45` | Kartoffeln 1,5kg | Pantry | PENNY | 2.29 € | 1500 g | 0 g | Vorratsschrank | 77 | 2.0g | 16.0g | 0.1g | 2.1g | 74 (B) | 85 | 80 | NOVA 1 |
| `food_1787511015576_20` | Kartoffeln fk. lose Zypern | Pantry | PENNY | 2.49 € | 500 g | 0 g | Vorratsschrank | 77 | 2.0g | 16.0g | 0.1g | 2.1g | 74 (B) | 85 | 80 | NOVA 1 |
| `food_1787655672345_105` | Kichererbsen (Greenland / PENNY) | Penny Greenland | PENNY | 0.89 € | 400 g | 1 g | Vorratsschrank | 127 | 7.3g | 16.0g | 2.2g | 7.0g | 84 (A) | 85 | 80 | NOVA 1 |
| `food_1787584551166_83` | Kichererbsen Dose | PENNY | PENNY | 0.69 € | 240 g | 0 g | Vorratsschrank | 120 | 7.0g | 17.0g | 2.5g | 7.0g | 84 (A) | 85 | 80 | NOVA 1 |
| `food_1787511043431_41` | Kichererbsenwaf. | Pantry | PENNY | 1.35 € | 500 g | 0 g | Vorratsschrank | 380 | 20.0g | 55.0g | 6.5g | 7.0g | 79 (B) | 70 | 80 | NOVA 1 |
| `cat-kokosmilch-aldi` | Kokosmilch fettreduziert (Light) | Asia Green Garden / ALDI | Aldi | 0.99 € | 400 ml | 1 ml | Kühlschrank | 121 | 0.7g | 1.4g | 12.0g | 0.0g | 56 (C) | 30 | 65 | NOVA 1 |
| `food_1787511015974_24` | Kopfsalat Deutschland | Pantry | PENNY | 1.19 € | 500 g | 0 g | Vorratsschrank | 15 | 1.2g | 1.8g | 0.2g | 0.0g | 73 (B) | 45 | 80 | NOVA 1 |
| `supp-kreatin-monohydrat` | Kreatin Monohydrat (Creapure) | 100% Reines Creapure | Amazon | 19.99 € | 500 g | 300 g | Vorratsschrank | 0 | 0.0g | 0.0g | 0.0g | 0.0g | 60 (C) | 45 | 80 | NOVA 1 |
| `food_1787584551166_77` | Kräuterquark leicht | PENNY | PENNY | 0.69 € | 200 g | 0 g | Kühlschrank | 80 | 9.0g | 4.0g | 2.5g | 0.0g | 72 (B) | 45 | 95 | NOVA 1 |
| `food_kraeuterquark` | Kräuterquark Magerstufe | Milbona / PENNY | PENNY | 0.89 € | 200 g | 0 g | Kühlschrank | 78 | 10.5g | 3.8g | 2.0g | 0.0g | 72 (B) | 45 | 95 | NOVA 1 |
| `food_1787511016580_29` | Landfreund Milchreis | Landfreund, Landfreund (Penny) | PENNY | 0.99 € | 500 g | 0 g | Gefrierfach | 345 | 7.1g | 76.0g | 1.1g | 0.0g | 62 (C) | 45 | 95 | NOVA 1 |
| `food_1787511016447_28` | Landfreund Parboiled Reis | Pantry | PENNY | 1.39 € | 1000 g | 0 g | Gefrierfach | 355 | 7.5g | 77.0g | 0.8g | 0.0g | 62 (C) | 45 | 95 | NOVA 1 |
| `food_1787584551166_75` | Magerquark Speisequark | PENNY | PENNY | 0.89 € | 500 g | 0 g | Gefrierfach | 67 | 12.0g | 4.3g | 0.2g | 0.0g | 72 (B) | 45 | 95 | NOVA 1 |
| `supp-magnesium-bisglycinat` | Magnesium-Bisglycinat (PM Schlaf & Wind-Down) | Evidenzbasiert / Reinsubstanz | Apotheke | 19.99 € | 120 Kapseln | 60 Kapseln | Spind | 0 | 0.0g | 0.0g | 0.0g | 0.0g | 60 (C) | 45 | 80 | NOVA 1 |
| `supp-magnesium-malat` | Magnesium-Malat (AM Energie & ATP-Synthese) | Reinsubstanz | Apotheke | 19.99 € | 120 Kapseln | 60 Kapseln | Spind | 0 | 0.0g | 0.0g | 0.0g | 0.0g | 60 (C) | 45 | 80 | NOVA 1 |
| `food_1787511014955_17` | Marktliebe Avocado | Pantry | PENNY | 0.99 € | 2 Stück | 0 Stück | Vorratsschrank | 160 | 2.0g | 2.0g | 15.0g | 6.7g | 70 (B) | 70 | 65 | NOVA 1 |
| `food_1787511015875_23` | Marktliebe Eisbergsalat Deutschland | Pantry | PENNY | 0.89 € | 2 Stück | 0 Stück | Gefrierfach | 15 | 1.2g | 1.8g | 0.2g | 0.0g | 73 (B) | 45 | 80 | NOVA 1 |
| `food_1787511015202_18` | Marktliebe Kartoffeln mehligkochend | Marktliebe | PENNY | 3.49 € | 2500 g | 0 g | Vorratsschrank | 77 | 2.0g | 16.0g | 0.1g | 2.1g | 74 (B) | 85 | 80 | NOVA 1 |
| `food_1787511015393_19` | Marktliebe Kartoffeln vorw.festk. | Marktliebe | PENNY | 4.99 € | 4000 g | 0 g | Vorratsschrank | 77 | 2.0g | 16.0g | 0.1g | 2.1g | 74 (B) | 85 | 80 | NOVA 1 |
| `food_1787511015802_22` | Marktliebe Rispentomaten Niederlande | Pantry | PENNY | 1.19 € | 500 g | 0 g | Vorratsschrank | 20 | 1.1g | 3.2g | 0.2g | 1.2g | 80 (A) | 85 | 80 | NOVA 1 |
| `food_1787511030789_38` | MINI MOZZARELLA | GALBANI | PENNY | 1.29 € | 500 g | 0 g | Vorratsschrank | 207 | 17.0g | 1.0g | 15.0g | 0.0g | 68 (C) | 30 | 65 | NOVA 1 |
| `food_1787511046504_55` | MM Peanut Butter | Pantry | PENNY | 1.99 € | 1 Stück | 0 Stück | Vorratsschrank | 524 | 9.5g | 57.1g | 28.6g | 0.0g | 40 (D) | 20 | 50 | NOVA 2 |
| `food_1787511014554_14` | Möhren | Freshona, Kleine Dosen | PENNY | 2.99 € | 2000 g | 0 g | Vorratsschrank | 50 | 2.8g | 6.9g | 0.3g | 2.8g | 80 (A) | 85 | 80 | NOVA 1 |
| `food_1787511016847_31` | Müller's Mühle Berglinsen | Pantry | PENNY | 1.59 € | 500 g | 0 g | Vorratsschrank | 340 | 24.0g | 52.0g | 1.5g | 11.0g | 89 (A) | 100 | 80 | NOVA 1 |
| `food_1787511047339_64` | Natives Olivenöl Extra | Gut & Günstig | PENNY | 0.00 € | 750 ml | 0 ml | Vorratsschrank | 822 | 0.0g | 0.0g | 91.3g | 0.0g | 40 (D) | 20 | 50 | NOVA 2 |
| `food_1787511016695_30` | Naturgut Bio Basmatireis | Pantry | PENNY | 1.59 € | 500 g | 0 g | Gefrierfach | 355 | 7.5g | 77.0g | 0.8g | 0.0g | 62 (C) | 45 | 95 | NOVA 1 |
| `food_1787511012382_13` | Naturgut Bio Möhren | Pantry | PENNY | 2.29 € | 1000 g | 0 g | Vorratsschrank | 39 | 1.0g | 7.5g | 0.2g | 2.8g | 76 (B) | 85 | 80 | NOVA 1 |
| `food_1787511016156_26` | Naturgut Bio Rispentomaten | Pantry | PENNY | 2.39 € | 500 g | 0 g | Vorratsschrank | 20 | 1.1g | 3.2g | 0.2g | 1.2g | 80 (A) | 85 | 80 | NOVA 1 |
| `food_1787511044863_51` | Naturgut Kaiserg | Pantry | PENNY | 10.76 € | 4 Stück | 0 Stück | Vorratsschrank | 35 | 2.5g | 4.0g | 0.5g | 0.0g | 72 (B) | 45 | 80 | NOVA 1 |
| `food_1787511045854_53` | NG Bio Leinsamen | dmBio | PENNY | 1.55 € | 500 g | 0 g | Vorratsschrank | 540 | 22.0g | 3.0g | 43.0g | 27.0g | 76 (B) | 75 | 50 | NOVA 1 |
| `supp-omega-3-tg` | Omega-3 Fischöl / Algenöl (Triglycerid-Form) | High EPA/DHA | Apotheke | 24.90 € | 120 Kapseln | 90 Kapseln | Spind | 900 | 0.0g | 0.0g | 100.0g | 0.0g | 40 (D) | 20 | 50 | NOVA 2 |
| `food_omega3` | Omega-3 Fischöl Kapseln (EPA/DHA) | ESN / Amazon | ESN | 14.99 € | 120 Stück | 0 Stück | Spind | 800 | 18.0g | 0.0g | 75.0g | 0.0g | 41 (D) | 20 | 50 | NOVA 2 |
| `food_1787511045986_54` | PAPRIKA EDELS | Pantry | PENNY | 0.85 € | 500 g | 0 g | Vorratsschrank | 31 | 1.0g | 6.0g | 0.3g | 0.0g | 65 (C) | 45 | 80 | NOVA 1 |
| `food_1787511047278_63` | Paprika Edelsüß | Carat | PENNY | 0.00 € | 125 g | 0 g | Vorratsschrank | 31 | 1.0g | 6.0g | 0.3g | 0.0g | 65 (C) | 45 | 80 | NOVA 1 |
| `food_1787511044429_47` | Paprika rot | Pantry | PENNY | 1.99 € | 400 g | 0 g | Vorratsschrank | 31 | 1.0g | 6.0g | 0.3g | 0.0g | 65 (C) | 45 | 80 | NOVA 1 |
| `food_1787655672345_107` | Passierte Tomaten (San Fabio) | San Fabio / PENNY | PENNY | 0.79 € | 500 g | 1 g | Vorratsschrank | 27 | 1.8g | 3.8g | 0.5g | 1.2g | 83 (A) | 85 | 80 | NOVA 1 |
| `food_1787510996075_5` | Penne Vollk. NG | Pantry | PENNY | 0.85 € | 500 g | 0 g | Vorratsschrank | 350 | 13.0g | 65.0g | 2.5g | 0.0g | 65 (C) | 45 | 80 | NOVA 1 |
| `food_1787510996422_8` | PENNY Kidneyb. NG | Pantry | PENNY | 1.49 € | 130 g | 0 g | Vorratsschrank | 110 | 8.5g | 15.0g | 0.6g | 7.0g | 87 (A) | 85 | 80 | NOVA 1 |
| `food_1787511046569_56` | PENNY Thunfisch | Pantry | PENNY | 6.95 € | 5 Stück | 0 Stück | Vorratsschrank | 110 | 25.5g | 0.0g | 1.0g | 0.0g | 59 (C) | 45 | 80 | NOVA 3 |
| `food_1787511047086_62` | Pfeffer Schwarz gemahlen | Bio Wagner | PENNY | 0.00 € | 140 g | 0 g | Vorratsschrank | 0 | 0.0g | 0.0g | 0.0g | 0.0g | 60 (C) | 45 | 80 | NOVA 1 |
| `food_1787510996764_9` | Pizza Tomaten | Mutti | PENNY | 0.65 € | 400 g | 0 g | Vorratsschrank | 36 | 1.6g | 5.4g | 0.5g | 1.2g | 79 (B) | 85 | 80 | NOVA 1 |
| `food_1787511046734_58` | Rahm Spinat | Pantry | PENNY | 0.00 € | 900 g | 0 g | Vorratsschrank | 23 | 2.8g | 0.8g | 0.4g | 2.7g | 82 (A) | 85 | 80 | NOVA 1 |
| `supp-rhodiola-rosea` | Rhodiola Rosea Extrakt (Rosenwurz Adaptogen) | Standardisiert (3% Rosavine) | Apotheke | 16.50 € | 90 Kapseln | 45 Kapseln | Vorratsschrank | 0 | 0.0g | 0.0g | 0.0g | 0.0g | 60 (C) | 45 | 80 | NOVA 1 |
| `food_1787510996257_6` | Rote Linsen | dmBio | PENNY | 1.45 € | 500 g | 0 g | Vorratsschrank | 334 | 19.0g | 54.0g | 2.1g | 11.0g | 86 (A) | 100 | 80 | NOVA 1 |
| `cat-rote-linsen` | Rote Linsen getrocknet | Bio / Standard | PENNY | 1.49 € | 500 g | 0 g | Vorratsschrank | 340 | 25.0g | 54.0g | 1.5g | 11.0g | 89 (A) | 100 | 80 | NOVA 1 |
| `supp-rote-bete-konzentrat` | Rote-Bete-Saft-Konzentrat (140 ml NO3- Booster) | Biotta / Rote Bete Sport | DM | 2.29 € | 140 ml | 4 ml | Vorratsschrank | 50 | 1.5g | 10.5g | 0.1g | 0.0g | 65 (C) | 45 | 80 | NOVA 1 |
| `food_1787584551166_89` | Salatgurke frisch | PENNY | PENNY | 0.69 € | 1 Stück | 0 Stück | Vorratsschrank | 15 | 0.7g | 2.0g | 0.1g | 0.0g | 69 (C) | 45 | 80 | NOVA 1 |
| `food_1787511012274_12` | San Fab. Pizzato | Pantry | PENNY | 1.18 € | 500 g | 0 g | Vorratsschrank | 25 | 1.2g | 4.0g | 0.2g | 0.0g | 69 (C) | 45 | 80 | NOVA 1 |
| `food_1787511017022_32` | San Fabio Gnocchi | Pantry | PENNY | 0.99 € | 500 g | 0 g | Vorratsschrank | 155 | 3.5g | 32.0g | 0.8g | 0.0g | 61 (C) | 45 | 80 | NOVA 1 |
| `food_1787511031243_39` | SAN FABIO MINI M | Pantry | PENNY | 2.58 € | 2 Stück | 0 Stück | Vorratsschrank | 0 | 0.0g | 0.0g | 0.0g | 0.0g | 60 (C) | 45 | 80 | NOVA 1 |
| `food_1787511017319_34` | San Fabio Tortelloni Spinaci | Pantry | PENNY | 0.99 € | 250 g | 0 g | Vorratsschrank | 0 | 0.0g | 0.0g | 0.0g | 0.0g | 60 (C) | 45 | 80 | NOVA 1 |
| `food_1787511017104_33` | San Fabio Totellini bunt | Pantry | PENNY | 0.99 € | 250 g | 0 g | Vorratsschrank | 280 | 10.0g | 45.0g | 6.0g | 0.0g | 62 (C) | 30 | 80 | NOVA 1 |
| `food_schinkenwuerfel` | Schinkenwürfel mager (2% Fett) | PENNY / Ja! | PENNY | 1.49 € | 150 g | 0 g | Vorratsschrank | 120 | 22.0g | 1.0g | 3.0g | 0.0g | 59 (C) | 45 | 80 | NOVA 3 |
| `food_1787584551166_78` | Schinkenwürfel mager 2% Fett | PENNY | PENNY | 1.79 € | 250 g | 0 g | Vorratsschrank | 125 | 25.0g | 1.0g | 2.5g | 0.0g | 59 (C) | 45 | 80 | NOVA 3 |
| `food_1787511044614_48` | SKYR NATUR | alpro | PENNY | 7.45 € | 5 Stück | 0 Stück | Kühlschrank | 65 | 5.6g | 2.2g | 3.3g | 0.0g | 72 (B) | 30 | 95 | NOVA 1 |
| `food_1787511012164_11` | Snickers Eisriegel | SNICKERS | PENNY | 6.57 € | 5 Stück | 0 Stück | Gefrierfach | 342 | 5.9g | 33.0g | 20.0g | 0.0g | 28 (D) | 20 | 65 | NOVA 4 |
| `food_1787584551166_86` | Speisekartoffeln festkochend 2.5kg | PENNY | PENNY | 2.29 € | 2500 g | 0 g | Gefrierfach | 75 | 2.0g | 15.0g | 0.1g | 2.1g | 74 (B) | 85 | 80 | NOVA 1 |
| `food_1787511044713_49` | SPEISEQUARK MAG. | Pantry | PENNY | 5.56 € | 4 Stück | 0 Stück | Gefrierfach | 66 | 12.0g | 4.1g | 0.2g | 0.0g | 72 (B) | 45 | 95 | NOVA 1 |
| `food_1787584551166_82` | Thunfisch im eigenen Saft | PENNY | PENNY | 1.19 € | 130 g | 0 g | Vorratsschrank | 110 | 25.5g | 0.0g | 0.8g | 0.0g | 59 (C) | 45 | 80 | NOVA 3 |
| `food_1787584551166_88` | TK-Beerenmischung | PENNY | PENNY | 1.99 € | 500 g | 0 g | Gefrierfach | 42 | 1.0g | 6.5g | 0.5g | 5.0g | 77 (B) | 100 | 80 | NOVA 1 |
| `food_tk_gemuese` | TK-Gemüsemischung | PENNY / K-Classic | PENNY | 1.49 € | 750 g | 0 g | Gefrierfach | 35 | 2.0g | 5.0g | 0.5g | 0.0g | 69 (C) | 45 | 80 | NOVA 1 |
| `supp-vitamin-d3-k2` | Vitamin D3 + K2 (MK-7) Tropfen | High Potency | Apotheke | 17.90 € | 50 ml | 30 ml | Spind | 890 | 0.0g | 0.0g | 99.0g | 0.0g | 49 (D) | 20 | 50 | NOVA 1 |
| `food_1787584551166_84` | Vollkorn Wraps | PENNY | PENNY | 1.49 € | 370 g | 0 g | Vorratsschrank | 298 | 8.9g | 51.0g | 4.8g | 7.0g | 75 (B) | 70 | 80 | NOVA 1 |
| `food_vollkornbrot` | Vollkornbrot geschnitten | PENNY / K-Classic | PENNY | 0.99 € | 500 g | 0 g | Vorratsschrank | 195 | 6.5g | 36.0g | 1.5g | 7.0g | 67 (C) | 85 | 80 | NOVA 3 |
| `food_1787511031655_40` | WEIZEN TORTILLAS | ja! | REWE | 1.29 € | 500 g | 0 g | Vorratsschrank | 301 | 9.1g | 53.0g | 4.9g | 0.0g | 62 (C) | 30 | 80 | NOVA 1 |
| `food_1787511046734_59` | Weizen Tortillas | Pantry | PENNY | 0.00 € | 500 g | 0 g | Vorratsschrank | 303 | 9.0g | 53.0g | 5.7g | 0.0g | 62 (C) | 30 | 80 | NOVA 1 |
| `supp-whey-isolat` | Whey Isolat / Protein Pulver Vanille | Premium Isolat 90% | Amazon | 29.99 € | 1000 g | 500 g | Spind | 371 | 88.0g | 2.5g | 1.0g | 0.0g | 71 (B) | 45 | 80 | NOVA 1 |
| `food_1787584551166_87` | Zarte Haferflocken | PENNY | PENNY | 0.69 € | 500 g | 0 g | Vorratsschrank | 370 | 13.5g | 58.0g | 7.0g | 10.0g | 80 (A) | 85 | 95 | NOVA 1 |
| `supp-zink-bisglycinat` | Zink-Bisglycinat 25mg | Reinsubstanz | Apotheke | 12.90 € | 120 Kapseln | 60 Kapseln | Vorratsschrank | 0 | 0.0g | 0.0g | 0.0g | 0.0g | 60 (C) | 45 | 80 | NOVA 1 |
| `food_1787511044347_46` | Zwiebeln Bravos | Marktliebe | PENNY | 0.99 € | 500 g | 0 g | Vorratsschrank | 40 | 1.2g | 8.0g | 0.1g | 1.7g | 75 (B) | 85 | 80 | NOVA 1 |

---

## 4. Bestehende Rezepturen & Baukästen (Referenz-Templates)

### 1. AirFryer-Gnocchi mit Gemüse („Knusper-Pfanne“) (`rec_1_gnocchi`)
- **Kategorie:** Warm Roast
- **Zutatenliste:**
  - `food_1787511017022_32`: San Fabio Gnocchi (500g)
  - `food_tk_gemuese`: TK-Gemüsemischung (150g)
  - `food_1787511047339_64`: Natives Olivenöl Extra (10g)

### 2. Protein-Rührei mit Schinken & Vollkornbrot (`rec_2_ruehrei`)
- **Kategorie:** Breakfast / Sandwich
- **Zutatenliste:**
  - `food_1787510995665_3`: EIER BH OKT (220g)
  - `food_schinkenwuerfel`: Schinkenwürfel mager (2% Fett) (50g)
  - `food_vollkornbrot`: Vollkornbrot geschnitten (120g)

### 3. Ofen-Kumpir (Gefüllte Riesen-Kartoffeln) (`rec_3_kumpir`)
- **Kategorie:** Warm Roast
- **Zutatenliste:**
  - `food_1787511011995_10`: Frühkartoffeln (400g)
  - `food_1787510995469_1`: Bio Zwiebeln (150g)
  - `food_reibekaese`: Gouda gerieben (light) (30g)

### 4. Blitz-Couscous-Pfanne mit Tomaten & Feta (`rec_4_couscous`)
- **Kategorie:** Soups & Stews
- **Zutatenliste:**
  - `food_couscous`: Couscous (120g)
  - `food_1787510996764_9`: Pizza Tomaten (240g)
  - `food_feta`: Feta / Hirtenkäse light (50g)

### 5. Mexikanische Knusper-Hähnchen-Wraps (`rec_5_wraps`)
- **Kategorie:** Sandwiches & Wraps
- **Zutatenliste:**
  - `food_1787511031655_40`: WEIZEN TORTILLAS (120g)
  - `food_1787511030203_37`: HA-BRUSTFILET (120g)
  - `food_1787511015875_23`: Marktliebe Eisbergsalat Deutschland (50g)

### 6. AirFryer Tuna-Melt Toasties (`rec_6_tuna_melt`)
- **Kategorie:** Sandwiches
- **Zutatenliste:**
  - `food_vollkornbrot`: Vollkornbrot geschnitten (120g)
  - `food_1787511016349_27`: Berida Thunfisch in Sauce (150g)
  - `food_reibekaese`: Gouda gerieben (light) (30g)

### 7. Knusprige Paprika-Kichererbsen mit Kräuterquark (`rec_7_kichererbsen`)
- **Kategorie:** High-Fiber Bowl
- **Zutatenliste:**
  - `food_1787511043431_41`: Kichererbsenwaf. (240g)
  - `food_1787510995469_1`: Bio Zwiebeln (150g)

### 8. Stuben-Shakshuka mit roten Linsen & 3 Eiern (`rec_8_shakshuka`)
- **Kategorie:** Soups & Stews
- **Zutatenliste:**
  - `food_1787510996257_6`: Rote Linsen (80g)
  - `food_1787510996764_9`: Pizza Tomaten (200g)
  - `food_1787510995665_3`: EIER BH OKT (165g)

### 9. AirFryer Hähnchen-Kartoffel Wedges (`rec_9_wedges`)
- **Kategorie:** Warm Roast
- **Zutatenliste:**
  - `food_1787511011995_10`: Frühkartoffeln (300g)
  - `food_1787511030203_37`: HA-BRUSTFILET (120g)

### 10. Warmes Baked-Protein-Oatmeal aus dem AirFryer (`rec_10_baked_oats`)
- **Kategorie:** Sweet Breakfast
- **Zutatenliste:**
  - `food_1787510996316_7`: Granola Haferflocken (80g)
  - `food_1787510995665_3`: EIER BH OKT (55g)
  - `food_beeren`: TK-Beerenmischung (80g)
  - `food_whey`: Whey Protein Isolat (20g)

### 15. Cremiges Kokos-Tomaten-Dal mit 191g Basmati-Reis & Erdnussbutter (`recipe-kokos-tomaten-dal`)
- **Kategorie:** Soups & Stews
- **Zutatenliste:**
  - `cat-rote-linsen`: Rote Linsen getrocknet (180g)
  - `cat-basmati-reis-191g`: Basmati Reis Spitzenqualität (191g)
  - `cat-tomaten-penny`: Gehackte Tomaten in Tomatensaft (400g)
  - `cat-kokosmilch-aldi`: Kokosmilch fettreduziert (Light) (200g)
  - `cat-erdnussbutter-20166076`: Erdnussbutter Creamy / Crunchy (31g)

---

## 5. Protokoll & Ausgabeformat für Rezeptgenerierungen

Wenn du (externe KI) neue Rezepte für den Nutzer kreierst, halte dich exakt an die folgende Ausgabe-Struktur:

```markdown
### [Nummer]. [Rezept-Name]
- **Kategorie:** [Warm Roast / Soups & Stews / Sandwiches & Wraps / High-Fiber Bowl / Sweet Breakfast]
- **Equipment:** [AirFryer / 1-Feld Induktion / Mikrowelle]
- **Zubereitungszeit:** [Max. 15 Minuten]
- **Zutatenliste:**
  - [Exakte Artikel-ID aus Datenbank]: [Produktname] - [Grammangabe]g
- **Zubereitungsschritte:**
  1. [Schritt 1]
  2. [Schritt 2]
  3. [Schritt 3]
- **Nährwertbilanz (Gesamtmahlzeit):**
  - Brennwert: [X] kcal
  - Protein: [X] g (Ziel: 35–50g pro Hauptmahlzeit)
  - Kohlenhydrate: [X] g (komplex, ballaststoffgebunden)
  - Fett: [X] g (< 15g bei Abendmahlzeiten)
  - Ballaststoffe: [X] g (Ziel: 8–15g pro Mahlzeit für BWK-Ulm Reha)
- **Klinische NutriVault-Bewertung:**
  - Berechneter Composite Health Index $\Phi$: [0-100] (Ziel: >= 80, Note A/A+)
  - BWK-Ulm Viszeral-Score: [0-100] (Begründung zur Stuhlregulation Typ 4)
  - LPR-Reflux-Sicherheit: [0-100] (Sphinkterschonung)
```

---

## 6. Beispiel-Prompt für den Nutzer zum Einfügen in ChatGPT / Claude

Kopiere den folgenden Text zusammen mit dieser Datei in ChatGPT oder Claude:

> *"Ich habe dir meine vollständige Growcery-Vorratsdatenbank sowie meine klinischen Ernährungsrichtlinien (BWK-Ulm Viszeralreha, 160g Protein, Stiller Reflux LPR-Schutz, AirFryer Kasernenküche) bereitgestellt.*
>
> *Bitte erstelle mir auf Basis meiner aktuellen Vorratsartikel 3 neue, abwechslungsreiche Rezepte für [Morgen / Mittag / Abend]. Achte strikt darauf, dass die Rezepte einen NutriVault Composite Index $\Phi \ge 80$ erreichen, mindestens 35g Protein und mindestens 8g Ballaststoffe liefern und in maximal 15 Minuten zubereitet sind."*
