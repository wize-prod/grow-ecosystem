# Systemarchitektur & Schaltplaene: Grow Ecosystem (Version 7.0)

---

## 1. Systemuebersicht & Grundprinzip

Das Grow-Ecosystem ist eine modulare, leistungsorientierte Software-Architektur zur Erfassung, Steuerung und Optimierung von Ernaehrung, Krafttraining, persoenlichen Routinen und Finanzen. Das Gesamtsystem verteilt Aufgaben gemaess den jeweiligen Hardware- und Software-Staerken auf vier Kern-Ebenen:

1. **iPhone 16 Pro Max (Point-of-Performance):** Die native iOS-App-Suite bestehend aus **Grow** (Training & Ernaehrung), **Growcery** (Vorrat, Barcodes, Belege & Einkaufsliste) und **GrowTasks** (Routinen, Studien- und BFD-Meilensteine). Alle Apps agieren als ultra-schlanke Anzeige-, Erfassungs- und Ausfuehrungs-Huelle (Shell) ohne ueberfluessige lokale Kataloge.
2. **Supabase (Zentrale PostgreSQL-Cloud-Datenbank & Storage):** Der globale Datenanker fuer Stammdaten aller Lebensmittel, historische Filial- und Kassenbonpreise, den vollstaendigen 1.324-Uebungskatalog (`public.exercises`) sowie komprimierte Belegarchive.
3. **MacBook Air M4 (Lokale Verarbeitungs- und MCP-Ebene):** Der lokale Schnittstellen-Server (Model Context Protocol auf Port 8765) mit 40 Werkzeugen, C++20-Rechenmodulen und der lokalen Haushaltsbuch-Datenbank (`haushaltsbuch.db`).
4. **Google Gemini (Autonome multimodale KI-Steuerung):** Das Sprachmodell agiert als uebergeordneter Orchestrator. Es analysiert Vorraete, Budgets, Workouts sowie Haltungsfotos und fuehrt vor jeder Empfehlung autonome Konsistenz- und Sicherheitspruefungen durch.

---

## 2. Plattform-Kapazitaeten, Moeglichkeiten und Grenzwerte

Um eine Ueberlastung einzelner Teilsysteme oder unvorhergesehene Speichergrenzen zu verhindern, basiert die Architektur auf einer transparenten Kapazitaets- und Limit-Matrix aller beteiligten Plattformen.

### 2.1 Supabase (PostgreSQL & Storage Starter / Free Tier)

| Metrik / Ressource | Limitierung | System-Nutzung & Auslastungsgrad | Schutzmassnahme / Architektur-Garantie |
| :--- | :--- | :--- | :--- |
| **PostgreSQL Datenbank** | 500 MB | Tabellen `products`, `store_prices` und `exercises`: ca. 150 bis 250 Byte pro Zeile. 10.000 Artikel + 1.324 Uebungen benoetigen lediglich ca. 5,5 MB (< 1,2 % des Limits). | Textbasierte Tabellen mit B-Tree- und GIN-Indizes belasten das Kontingent praktisch nicht. |
| **File Storage (Buckets)** | 1.000 MB (1 GB) Gesamtvolumen, max. 50 MB / Datei | **Kritischer Pfad bei Kassenbons & Screenshots:** Ein unkomprimiertes iPhone-Foto (HEIC/RAW) belegt 3 bis 6 MB. 200 Belege wuerden 1 GB vollstaendig erschoepfen. | **Client-seitige Komprimierungs-Pipeline:** Vor dem Upload skaliert das iPhone Belegbilder auf maximal 1600x1200 Pixel herab und komprimiert sie auf JPEG-Qualitaet 0.65. Dies reduziert die Dateigroesse auf **150 bis 250 KB pro Beleg**. 1.000 Belege belegen somit nur ca. 200 MB (20 % des Kontingents). |
| **Monatlicher Egress (Traffic)** | 2 GB / Monat | Abruf von Stammdaten und gelegentliche Belegansichten verbrauchen < 150 MB / Monat. | Bilder werden nur nach explizitem Nutzerabruf aus der Cloud gestreamt. |
| **Gleichzeitige Verbindungen** | Direct: 60 / Pooled: 200 | App und MCP greifen ueber Supabase REST (PostgREST) zu. | Keine persistenten Datenbank-Sockets, verbindungslos und ressourcenschonend. |

### 2.2 iPhone 16 Pro Max (Native iOS App Suite)

| Metrik / Ressource | Spezifikation / Limit | System-Nutzung | Architektur-Vorteil |
| :--- | :--- | :--- | :--- |
| **Prozessor & NPU** | Apple A18 Pro (6-Core CPU, 16-Core Neural Engine) | On-Device Apple Vision OCR fuer Barcodes und schnelle Sofort-Pruefungen. | Hardware-Sensorik fuer Sub-Sekunden-Barcode-Erkennung (30 ms) ohne Internet und ohne API-Kosten. |
| **Arbeitsspeicher (RAM)** | 8 GB Unified Memory | iOS Memory Watchdog begrenzt einzelne App-Prozesse auf ca. 2 bis 3 GB. | **Zero-Catalog-Architektur:** Keine statischen 17-MB-Kataloge und keine Routine-Uebungen lokal im RAM gehalten. App belegt < 25 MB RAM. |
| **Lokaler Flash-Speicher** | 256 GB+ NVMe SSD | Lokale JSON-Container (`pantry_catalog.json`, `shopping_list.json`, `haushaltsbuch.db`). | Lese- und Schreibzugriffe erfolgen im Mikrosekundenbereich (< 3 ms). |

### 2.3 MacBook Air M4 (Local Host & Unified MCP)

| Metrik / Ressource | Spezifikation / Limit | System-Nutzung | Architektur-Vorteil |
| :--- | :--- | :--- | :--- |
| **Hardware** | Apple M4, 16 GB Unified RAM, 256 GB NVMe + 1 TB ORICO SSD | Betrieb des MCP-Servers (Port 8765), SQLite-WAL-Modus, C++20-Kerne. | Ermoeglicht komplexe analytische SQL-Abfragen ueber Jahre von Finanztransaktionen ohne Verzoegerung. |
| **Erreichbarkeit (Availability)** | Ruhezustand (Lid Closed) trennt Netzwerkprozesse | Lokaler MCP-Server ist bei geschlossenem MacBook ueber Cloudflare nicht erreichbar. | Die iOS-Apps funktionieren vollstaendig autark (Offline-First). Der MCP-Server wird nur fuer Gemini-Abfragen und Synchronisationslaeufe aktiviert. |

### 2.4 Google Gemini (Cloud AI Engine)

| Metrik / Ressource | Spezifikation / Limit | Risiken bei Fehlarchitektur | Loesung: Staging-Architektur |
| :--- | :--- | :--- | :--- |
| **Kontextfenster** | 1.000.000 bis 2.000.000 Tokens | Grosse Prompts (> 30.000 Tokens) fuehren zu Latenzen (3 bis 8 Sekunden) und Halluzinationsrisiken. | **Active Working Memory (< 2.000 Tokens):** Gemini erhaelt niemals rohe Datenbank-Dumps, sondern praezise, vorberechnete Kennzahlen via MCP-Tools. |
| **Multimodale Bildverarbeitung** | Ca. 258 Tokens pro 512x512 Kachel | Zu viele Bilder in einem Kontext verlangsamen die Antwort. | Bilder werden strukturiert analysiert; Metadaten werden direkt ueber MCP-Tools in Supabase und `haushaltsbuch.db` geschrieben. |

### 2.5 Fazit & Architektonische Leitplanken der Plattform-Verteilung

Aus der Kapazitaets- und Limit-Matrix ergeben sich vier verbindliche Architektur-Leitsaetze:

1. **Kein Datenmuell auf dem Smartphone (Ultra-Lean App Shell):** Das iPhone speichert weder 1.324 Uebungen noch feste Routine-Listen lokal ab. Auf dem Geraet existiert nur die aktuelle Tages-Session. Alles andere verbleibt in Supabase und wird ueber die Suchleiste oder von Gemini on-demand bereitgestellt.
2. **Semantische Intelligenz in die Cloud (Gemini), Sensorik aufs iPhone:** Die Analyse von komplexen Kassenbelegen, Bank-Screenshots und Haltungsfotos gehoert zu 100 % in Google Gemini. Das Smartphone uebernimmt ausschliesslich zeitkritische Sensoraufgaben (30-ms-Barcode-Beep, haptische Timer, Bildschirm-Wachhaltung).
3. **Client-seitige Komprimierungspflicht:** Kein Foto verlaesst das iPhone in nativer 48-Megapixel-Aufloesung. Durch die automatische Komprimierung auf 150 bis 250 KB bleibt das Supabase-Free-Tier-Volumen (1 GB) ueber Jahre hinweg stabil bei unter 25 % Auslastung.
4. **Schlanker KI-Kontext (Zero Context Blowout):** Google Gemini fungiert als reiner Entscheidungs- und Logik-Orchestrator. Die MCP-Tools verdichten Rohdaten lokal auf dem Mac M4, sodass Gemini pro Abfrage weniger als 2.000 Tokens Active Working Memory verarbeitet.

---

## 3. Wirtschaftsinformatische Begruendung: Warum native Phone-App & wann Gemini-Scan?

Die Kernfrage lautet: *Warum benoetigen wir ueberhaupt noch native Scanner oder Apps auf dem Smartphone, wenn Gemini mit multimodaler Intelligenz Kassenbons, Screenshots und Fotos viel praeziser analysieren und direkt via MCP in Supabase loggen kann?*

Die Antwort liegt in der wirtschaftsinformatischen Differenzierung zwischen **Semantischer Erkennungs-Tiefe** (AI Brain) und **physischen Point-of-Performance-Bedingungen** (Native Client).

```mermaid
flowchart TD
    classDef aiGate fill:#2C223B,stroke:#9B82BA,stroke-width:2px,color:#FFFFFF;
    classDef phoneGate fill:#1E3A2F,stroke:#7A9A7E,stroke-width:2px,color:#FFFFFF;
    classDef dbGate fill:#3D2B1F,stroke:#D9C3A5,stroke-width:2px,color:#FFFFFF;

    subgraph INTAKE["1. Semantische Erfassung & Verbuchung (Gemini + MCP)"]
        A1["Komplexe Kassenbons (Penny, Rewe, Edeka)\n- Zerknittertes Papier, kryptische Zeilen\n- Pfandabzuege, Rabatte, Mehrwertsteuer"]:::aiGate
        A2["Multi-Source Finanz-Screenshots\n- PayPal, Targobank App, Apple Wallet, Email\n- Unstrukturierte Layouts, Dark Mode"]:::aiGate
        A3["Multimodale Haltungs- & Physio-Fotos\n- Asymmetrien, Schultertilt, Lordose"]:::aiGate
        
        A1 --> GemBrain["Google Gemini Vision Engine\n(Versteht Semantik, Rabatte & Kontext)"]:::aiGate
        A2 --> GemBrain
        A3 --> GemBrain
        GemBrain --> MCPLog["MCP-Tools (ingest_receipt, log_expense, etc.)"]:::aiGate
        MCPLog --> SupaDB[("Supabase & haushaltsbuch.db\n(Zentrale Datenhaltung)")]:::dbGate
    end

    subgraph EXECUTION["2. Physische Ausfuehrung am Point-of-Performance (iPhone Shell)"]
        P1["Supermarkt-Kueche Barcode-Scan (EAN)\n- 30 Millisekunden Hardware-Erkennung (AVFoundation)\n- Sofortiges haptisches Feedback (Klick)\n- 10 Artikel in 15 Sekunden ohne Warten"]:::phoneGate
        P2["Funkloch- & Keller-Sicherheit (Offline-First)\n- Kein Netz im Gym-Keller oder Discounter\n- Workout laeuft weiter, Saetze werden erfasst\n- Sync erfolgt automatisch bei Wiederverbindung"]:::phoneGate
        P3["Aktive Gym-Ergonomie (Rest-Timer & Haptik)\n- Bildschirm-Wachhaltung (UIApplication.isIdleTimerDisabled)\n- Apple Watch / Hosentaschen-Vibration nach 90s Pause\n- Schnelle Satz-Eingabe mit kreideigenen Fingern"]:::phoneGate
    end

    SupaDB -.->|Synchronisiert geplante Workouts & Bestaende| EXECUTION
```

### Der Vergleich im Detail

| Kriterium | Gemini + MCP + Supabase (AI Gate) | Native iPhone App (Point-of-Performance) | Architektonisches Urteil |
| :--- | :--- | :--- | :--- |
| **Kassenbons & Belege** | **Exzellent:** Erkennt selbst unleserliche Abkuerzungen („G&G H-MILCH 1,5%“), verrechnet Pfandbons und prueft gegen das Monatsbudget. | **Schwach/Starr:** Reine On-Device OCR scheitert an komplexen Tabellenstrukturen und Rabatten. | **Gemini gewinnt zu 100 %:** Belege und Rechnungen werden primaer an Gemini uebergeben. |
| **Finanz-Screenshots (PayPal / Bank)** | **Exzellent:** Erkennt Betrag, Buchungsstatus (Pending vs. Settled) und Haendler aus beliebigem Bildausschnitt. | **Eingeschraenkt:** Benoetigt starre Vorlagen fuer jede Bank-App. | **Gemini gewinnt zu 100 %:** Transaktions-Screenshots wandern direkt in den Gemini-Chat. |
| **Barcode-Scan (Supermarkt / Kueche)** | **Unbrauchbar im Alltag:** Foto aufnehmen, 4 Sekunden Upload, 3 Sekunden Inferenz = 7 Sekunden pro Artikel. | **Unschlagbar:** Kamera-Sensor liest EAN in **0,03 Sekunden (30 ms)** mit sofortiger Haptik. 10 Artikel in 15 Sekunden. | **iPhone gewinnt zu 100 %:** Barcode-Scanner bleibt als reiner Hardware-Sensor auf dem iPhone. |
| **Netzwerk-Abhaengigkeit (Funkloch)** | **Blockiert:** Ohne 5G/WLAN keine Inferenz. Im Gym-Keller oder Supermarkt-Untergeschoss unbenutzbar. | **Autark:** Speichert Saetze und Aenderungen lokal und gleicht sie nach Netzrueckkehr ab. | **iPhone gewinnt:** Essentiell fuer unterbrechungsfreies Training. |
| **Interaktive Trainings-Ergonomie** | **Ungeeignet:** Man kann nicht nach jedem schweren Satz Bankdruecken einen Chatbot anschreiben („Habe 100 kg x 8 Wdh gemacht“). | **Perfekt:** Rest-Timer laeuft im Hintergrund, vibriert in der Hosentasche, haelt das Display wach, Stepper fuer Gewichte. | **iPhone gewinnt:** Dient als reines Durchfuehrungswerkzeug. |

**Architektonische Konsequenz:**
* **Gemini ist die Intake- und Planungs-Zentrale:** Alle Belege, Bank-Screenshots, Haltungsfotos und die Erstellung von Wochenplaenen laufen ueber Gemini. Gemini schreibt ueber MCP direkt in Supabase und `haushaltsbuch.db`.
* **Die Grow-App ist eine reine Durchfuehrungs-Huelle (Execution Shell):** Die App muss keine schweren OCR-Module oder Uebungsdatenbanken hosten. Sie holt sich geplante Einheiten aus Supabase, fuehrt sie im Gym offline-sicher mit Timer und Haptik aus und uebergibt das Ergebnis zurueck an die Cloud.

### 3.1 Speicherorte fuer Belege & Das All-Time Haushaltsbuch: Wer pflegt was?

Aus den Fragen nach dem konkreten Speicherort und der Pflege des Haushaltsbuchs leitet sich eine transparente Dreiteilung ab:

#### 1. Wo werden Belege & Screenshots physisch und in der Cloud gespeichert?
* **Die Bilddateien (JPG/PDF):**
  * *Cloud-Archiv:* Werden ueber das MCP-Tool im Supabase Storage Bucket `receipt_images/YYYY-MM/bon_<hash>.jpg` abgelegt (komprimiert auf 150 bis 250 KB). Dies dient als steuerliches Langzeitarchiv (4 Jahre Aufbewahrungsfrist nach Abgabenordnung fuer WISO & Soldatenpauschalen).
  * *Lokales Backup:* Auf dem MacBook unter `~/Library/CloudStorage/GoogleDrive-wize.prod6878@gmail.com/.../Finanzen/Belege/`.
* **Die extrahierten Artikel- und Preiszeilen:**
  * Werden dauerhaft in Supabase PostgreSQL (`public.store_prices`) gespeichert (EAN, gelesene Zeile, Supermarkt, Preis), um historische Preisvergleiche zu ermoeglichen.

#### 2. Was ist das All-Time Haushaltsbuch und wo liegt es?
* **Die zentrale Datenbank:** `haushaltsbuch.db` (SQLite im WAL-Modus), synchronisiert ueber Google Drive unter:
  `/Users/parris-campbellnkembi/Library/CloudStorage/GoogleDrive-wize.prod6878@gmail.com/Meine Ablage/02_Cyber_Security_und_IT/cyber sec/CyberSec_Vault/Finanzen/haushaltsbuch.db`
* **Inhalt:** Enthaelt die lueckenlose Historie aller Einnahmen, Ausgaben, Tilgungen und Kontostaende seit Juni 2026 (ueber 194 gepruefte Buchungen).
* **Tabellenstruktur (`transactions`):**
  * `id`: Eindeutige Transaktions-ID.
  * `booking_date`: Buchungsdatum (YYYY-MM-DD).
  * `tx_type`: Buchungsart (`LIVE_SCREENSHOT`, `RECEIPT_SCAN`, `CSV_TARGOBANK`, `FIXKOSTEN`).
  * `recipient_or_purpose`: Vollstaendige, aussagekraeftige Beschreibung (z. B. *"Edeka - Wocheneinkauf: Magerquark, Haferflocken, Bananen"*).
  * `amount`: Betrag in EUR (z. B. `-24.50`).
  * `category`: Feste Budgetkategorie (`Lebensmittel & Drogerie`, `Wohnen & Fixkosten`, `Schuldentilgung`).
  * `account_iban`: Zugeordnetes Girokonto.

#### 3. Wer pflegt dieses Haushaltsbuch dynamisch und formuliert Beschreibungen?
* **Google Gemini ist der autonome Buchhalter (Autonomous Scribe / Accountant):**
  * Der Nutzer muss **keine Excel-Tabellen oeffnen, keinen Text abtippen und keine SQL-Befehle kennen**.
  * **Workflow:**
    1. Der Nutzer sendet ein Foto eines Kassenbons oder einen Screenshot (PayPal, Targobank, Apple Wallet) in den Gemini-Chat.
    2. Gemini analysiert das Bild mit seiner multimodalen Vision Engine, erkennt Datum, Gesamtbetrag, Haendler und Einzelposten.
    3. Gemini formuliert automatisch eine praezise, verstaendliche Buchungsnotiz (z. B. *"PayPal an Edeka - Einkauf Grundnahrungsmittel"*).
    4. Gemini ruft das MCP-Tool `log_expense_transaction(...)` auf.
    5. Das MCP-Tool schreibt den Eintrag per atomarem SQL-Befehl direkt in `haushaltsbuch.db`, aktualisiert den Kontostand und prueft das Restbudget gegen den 350-EUR-Monatsdeckel.
    6. Gemini bestaetigt die Verbuchung und nennt das verbleibende Restbudget fuer den Monat.

#### 4. Welche Rolle spielt die Grow-App auf dem iPhone?
* Die Grow-App (Buchungen-Tab) ist ein reines, latenzfreies **Lese- und Kontroll-Dashboard**:
  * Sie liest `haushaltsbuch.db` (bzw. Supabase REST) aus und zeigt den aktuellen Saldo, den Monatsverlauf und das verbleibende Lebensmittelbudget uebersichtlich auf dem iPhone an.

---

## 4. High-Speed MCP-Architektur & Multi-Domain Orchestrierung

### 4.1 Beseitigung des "Verbindungsaufbau... mit GymApp"-Problems

In frueheren Testlaeufen blockierte Gemini haeufig mit dem Status *„Verbindungsaufbau... mit GymApp“*. Eine technische Ursachenanalyse ergab vier konkrete Engpaesse, die in dieser Architektur vollstaendig behoben sind:

1. **CORS / OPTIONS Pre-Flight:** Browser-basierte Web-Clients (`gemini.google.com`) senden vor jedem POST-Aufruf einen HTTP `OPTIONS`-Preflight. In `scripts/gymapp_mcp/server.py` wurde Starlettes `CORSMiddleware` (`allow_origins=["*"]`, `allow_methods=["*"]`, `allow_headers=["*"]`) integriert. Preflights werden nun sofort mit Status 200 beantwortet.
2. **Beseitigung unindizierter 17-MB-Festplattenzugriffe:** Die fruehere Funktion `search_exercise_catalog` parste bei jeder Suchanfrage eine unindizierte 17-MB-JSON-Datei synchron von der Festplatte. Durch In-Memory-Caching und die Verlagerung nach Supabase antwortet das Werkzeug in unter 1 Millisekunde.
3. **Tool-Konsolidierung (40 Werkzeuge):** Statt ueber 70 ueberladener Tools wird das Schema beim Handshake kompakt gehalten, was die Initialisierung auf unter 50 ms verkuerzt.
4. **Stabile Tunnel-Architektur:** Durch saubere Keep-Alive-Header antwortet der Cloudflare-Tunnel sofort auf jede Anfrage.

---

### 4.2 Multi-Domain Orchestrierung: Turn-Level Concurrency (Max 2-3 Tools) vs. Multi-Turn Chaining

Ein zentrales Missverstaendnis in der KI-Orchestrierung besteht in der Verwechslung von **parallelen Tool-Aufrufen in einem einzelnen Inferenz-Turn** und der **Gesamtzahl an Tools ueber einen komplexen Nutzer-Prompt hinweg**.

#### Das Prinzip: Turn vs. Prompt

| Begriff | Definition | Tool-Grenzwert |
| :--- | :--- | :--- |
| **Nutzer-Prompt** | Die Gesamtanweisung des Nutzers an Gemini (z. B. 2 Belege buchen, Budget pruefen, Reha checken, Workout planen). | Unbegrenzt (kann 10 bis 15 Tools im Verlauf des Workflows ausloesen). |
| **Agent-Turn (Schritt)** | Ein einzelner Inferenz-Zyklus von Gemini: Eingabe $\longrightarrow$ LLM erzeugt `tool_calls` $\longrightarrow$ Ausfuehrung $\longrightarrow$ Rueckgabe. | **Maximal 2 bis 3 Tools parallel pro Turn**. |
| **Agent-Loop** | Die automatische Schleife, in der Gemini nach Erhalt der Tool-Ergebnisse den naechsten Turn startet, bis die Aufgabe geloest ist. | Typischerweise 3 bis 5 sequentielle Turns. |

Die Regel **„Maximal 3 Tool-Calls gleichzeitig“** gilt strikt fuer **einen einzelnen Turn (Turn-Level Concurrency)**, **nicht** fuer den gesamten Prompt.

#### Warum ein gleichzeitiges Feuern von 10 Tools im selben Turn scheitern wuerde

1. **Kausale Datenabhaengigkeiten (Data Dependencies):** 
   - Tool B benoetigt zwingend den Rueckgabewert von Tool A.
   - *Beispiel:* Das Tool `generate_smart_shopping_list` kann nicht gleichzeitig mit `ingest_receipt` aufgerufen werden. Gemini muss zunaechst abwarten, wie viel Geld die neuen Belege gekostet haben und wie der berechnete Restsaldo fuer den Monat lautet (`get_shopping_budget_status`), bevor eine Budget-konforme Einkaufsliste generiert werden kann.
2. **Kontext-Stabilitaet & Fehler-Isolation (Self-Correction):**
   - Feuert ein Modell 10 Tools auf einmal ab und ein Aufruf wirft einen Parameter- oder Netzwerkfehler, scheitert haeufig der gesamte Inferenz-Schritt.
   - Bei 2 bis 3 Tools pro Turn kann Gemini Teilergebnisse sofort validieren und bei Rueckfragen oder Fehlern im naechsten Turn adaptiv gegensteuern.
3. **Datenbank-Konsistenz & Race Conditions:**
   - Gleichzeitige unkoordinierte Schreib- und Lesezugriffe auf dieselbe lokale SQLite-Tabelle (`haushaltsbuch.db`) oder Supabase-Entitaet koennen zu Locking-Konflikten fuehren. Sequentielle Phasen garantieren ACID-Transaktionssicherheit.

#### Phasen-Kaskadierung im Multi-Domain-Betrieb

Ein komplexer Multi-Domain-Prompt (Finanzen + Vorrat + Reha + Workout) wird von Gemini souveraen in 3 bis 4 sequentielle Phasen zerlegt:

```mermaid
sequenceDiagram
    autonumber
    actor User as Nutzer
    participant Gemini as Gemini Agent
    participant MCP as Grow MCP Server (Port 8765)
    participant DB as Supabase / haushaltsbuch.db

    User->>Gemini: Multi-Domain-Prompt (2 Belege + Budget + BWK-Reha + Workout)
    
    Note over Gemini: Turn 1: Domain Finanzen & Belege (Max 2 Tools)
    Gemini->>MCP: ingest_receipt(lidl_receipt) & ingest_receipt(rewe_receipt)
    MCP->>DB: Ausgaben verbuchen & Einzelposten extrahieren
    DB-->>MCP: Bestaetigung (Lidl 24.50 EUR, Rewe 18.20 EUR verbucht)
    MCP-->>Gemini: Tool Response Turn 1
    
    Note over Gemini: Turn 2: Domain Budget & Reha-Audit (Max 2 Tools)
    Gemini->>MCP: get_shopping_budget_status() & audit_bwk_reha_safety()
    MCP->>DB: Monatsausgaben summieren & Rueckenbelastung pruefen
    DB-->>MCP: Budget: 180 EUR verbleibend | BWK-Status: Akut (Keine Axiallast)
    MCP-->>Gemini: Tool Response Turn 2
    
    Note over Gemini: Turn 3: Domain Uebungs-Lookup & Workout (Max 2 Tools)
    Gemini->>MCP: search_exercise_catalog("Chest Supported Row") & plan_workout(...)
    MCP->>DB: Biomechanik laden & Workout-Session eintragen
    DB-->>MCP: Workout ID #1042 angelegt
    MCP-->>Gemini: Tool Response Turn 3
    
    Note over Gemini: Turn 4: Finale Synthese (0 Tools)
    Gemini-->>User: Vollstaendige Rueckmeldung: Belege gebucht, Saldo aktualisiert, reha-sicheres Rueckentraining steht bereit.
```

#### Orchestrierungs-Matrix eines Multi-Domain-Prompts

| Phase / Turn | Domaenen-Fokus | Aufgerufene MCP-Tools | Parallele Tools | Zweck & Kausalitaet |
| :--- | :--- | :--- | :--- | :--- |
| **Turn 1** | **Finanzen & Belege** | `ingest_receipt`, `log_expense_transaction` | 2 Tools | Extraktion und Verbuchung der Rohdaten. Basis fuer Kontostand. |
| **Turn 2** | **Budget & Reha-Safety** | `get_shopping_budget_status`, `audit_bwk_reha_safety` | 2 Tools | Pruefung der Rahmenbedingungen: Wie viel Budget bleibt? Ist die Wirbelsaeule belastbar? |
| **Turn 3** | **Planung & Persistenz** | `search_exercise_catalog`, `plan_workout` | 2 Tools | Auswahl bio-mechanisch sicherer Uebungen und Eintragung in Supabase. |
| **Turn 4** | **Ergebnis-Synthese** | *Keine weiteren Tools (Reine Textgenerierung)* | 0 Tools | Zusammenfassende, unmissverstaendliche Antwort an den Nutzer. |
| **Gesamt** | **4 Domaenen geloest** | **Sequentiell kaskadiert** | **Max 2-3 / Turn** | **6 Tools total, 0 Timeout-Risiko, 100 % Datenkonsistenz** |

---

## 5. Schaltplan 1: Gesamtsystem-Topologie

Dieser Schaltplan zeigt die physische Vernetzung zwischen der iOS-Dreier-Suite (Grow, Growcery, GrowTasks), dem MacBook, der Supabase-Cloud und Google Gemini.

```mermaid
flowchart TD
    classDef clientZone fill:#1E3A2F,stroke:#7A9A7E,stroke-width:2px,color:#FFFFFF;
    classDef macZone fill:#1A2B3C,stroke:#4A6B82,stroke-width:2px,color:#FFFFFF;
    classDef cloudZone fill:#3D2B1F,stroke:#D9C3A5,stroke-width:2px,color:#FFFFFF;
    classDef aiZone fill:#2C223B,stroke:#9B82BA,stroke-width:2px,color:#FFFFFF;

    subgraph Z1["Zone 1: iPhone 16 Pro Max (Lean Execution Shell)"]
        direction TB
        subgraph APPS["iOS App Suite (com.nkembi.*)"]
            GrowFit["Grow / GymApp\n(Heute-Tab, Timer, RPE, Keine lokalen Uebungskataloge)"]:::clientZone
            Growcery["Growcery\n(Vorrat, 30ms-Barcode-Beep, Einkaufsliste)"]:::clientZone
            GrowTasks["GrowTasks\n(Routinen, Studium, BFD)"]:::clientZone
        end
        
        Bridge["SharedMacrosBridge.swift\n(App Groups, Shared Keychain, Darwin Notifications)"]:::clientZone
        HW_Scanner["AVFoundation Hardware-Scanner\n(30 ms Barcode-Sensorik)"]:::clientZone
        LocalSession["Lokale Session-Daten\n(aktiver Tag: planned_workouts.json, pantry.json)"]:::clientZone

        GrowFit <==>|Ecosystem IPC| Bridge
        Growcery <==>|Ecosystem IPC| Bridge
        GrowTasks <==>|Ecosystem IPC| Bridge
        HW_Scanner --> Growcery
        GrowFit --- LocalSession
        Growcery --- LocalSession
        GrowTasks --- LocalSession
    end

    subgraph Z2["Zone 2: MacBook Air M4 (Lokale Analyse & MCP-Host)"]
        direction TB
        MCP["Unified MCP Server (Port 8765)\n(40 spezialisierte Kontroll-Werkzeuge mit CORS)"]:::macZone
        CF["Cloudflared Tunnel Daemon\n(Sicherer HTTPS-Endpunkt)"]:::macZone
        FinanceDB["haushaltsbuch.db (SQLite WAL)\n(Transaktionen, Salden, Tilgungsplan)"]:::macZone
        Dossier["GROW_ATHLETE_DOSSIER.md\n(Multimodales Gedaechtnis)"]:::macZone

        LocalSession <==>|Synchronisation| MCP
        FinanceDB <==> MCP
        MCP <==> Dossier
        CF <==>|Tunnel 127.0.0.1:8765| MCP
    end

    subgraph Z3["Zone 3: Supabase Cloud & Externe APIs"]
        direction TB
        Supa_Prod["PostgreSQL: public.products\n(Globale Lebensmittel-Stammdaten)"]:::cloudZone
        Supa_Price["PostgreSQL: public.store_prices\n(Filialpreise, Bon-Zeilen & Orte)"]:::cloudZone
        Supa_Ex["PostgreSQL: public.exercises\n(1.324 Uebungen: Muskelkarten, Cues, YouTube-Links)"]:::cloudZone
        Supa_Storage["Storage Bucket: receipt_images\n(Max. 250 KB / Bild komprimiert)"]:::cloudZone

        Growcery -.->|REST: Lebensmittel abfragen| Supa_Prod
        GrowFit -.->|REST: Uebungen via Searchbar suchen| Supa_Ex
        Growcery -.->|Kompakt-Belegupload| Supa_Storage
        MCP -.->|Preisvergleiche & Stammdaten| Supa_Prod
        MCP -.->|Uebungskatalog abfragen| Supa_Ex
    end

    subgraph Z4["Zone 4: KI-Ebene (Google Gemini)"]
        direction TB
        Gemini["Google Gemini (Web & Mobile)"]:::aiZone
        MCP_Connector["Gemini MCP Connector\n(@GymApp Controller)"]:::aiZone
        PreFlight["Pre-Flight Sicherheits-Audit\n(Budget & Reha vorab pruefen)"]:::aiZone
        PostFlight["Post-Flight Scribe\n(Neue Fakten autonom sichern)"]:::aiZone

        Gemini <==> MCP_Connector
        MCP_Connector <==>|High-Speed HTTPS via Tunnel| CF
        Gemini --- PreFlight
        Gemini --- PostFlight
    end
```

---

## 6. Schaltplan 2: Barcode-Erfassung & Bestandsfuehrung

Dieses Sequenzdiagramm dokumentiert die Erfassung von Lebensmitteln ueber den 30-Millisekunden-Hardware-Sensor des iPhones.

```mermaid
sequenceDiagram
    autonumber
    actor User as Nutzer
    participant Cam as iPhone Kamera (AVFoundation)
    participant Local as LocalStore.swift
    participant Disk as pantry_catalog.json
    participant Supa as Supabase (products)

    User->>Cam: 1. Barcode anvisieren (z. B. Haferflocken EAN 5906827022278)
    Cam->>Local: 2. Hardware-Sensor liefert EAN in 30 ms + Haptischer Klick
    
    Local->>Disk: 3. Produkt im lokalen Bestand suchen
    alt Fall A: Produkt lokal vorhanden
        Disk-->>Local: 4. Lokale Stammdaten geladen
        Local->>User: 5. Schnell-Dialog: "Bestand erhoehen um Packungsgroesse?"
    else Fall B: Produkt lokal unbekannt
        Local->>Supa: 6. Produkt in Supabase abfragen (GET /products?barcode=eq...)
        Supa-->>Local: 7. Stammdaten empfangen (Name, Marke, Kcal, Makros)
        Local->>User: 8. Erfassungsmaske: Menge und Lagerort eingeben
    end

    User->>Local: 9. Bestaetigen (z. B. 1.000 g, Ort: Vorratsschrank)
    Local->>Disk: 10. Eintrag speichern (currentStockQty: 1000.0)
    Local-->>User: 11. Haptisches Signal & Anzeige in Vorratsliste
```

---

## 7. Schaltplan 3: Unified Federated Search (Katalogsuche fuer Artikel mit Bestand = 0)

Die Suchleiste der Grow-App fuehrt eine parallele Abfrage ueber zwei Datenquellen durch: den lokalen Kuechenbestand und den Supabase-Katalog.

```mermaid
flowchart TD
    classDef searchInput fill:#1E3A2F,stroke:#7A9A7E,stroke-width:2px,color:#FFFFFF;
    classDef localBranch fill:#1A2B3C,stroke:#4A6B82,stroke-width:2px,color:#FFFFFF;
    classDef cloudBranch fill:#3D2B1F,stroke:#D9C3A5,stroke-width:2px,color:#FFFFFF;
    classDef uiAction fill:#2C223B,stroke:#9B82BA,stroke-width:2px,color:#FFFFFF;

    A["Nutzer tippt Suchbegriff in Grow-Suchleiste:\nz. B. 'Magerquark'"]:::searchInput --> B["Parallele Abfrage ausfuehren"]:::searchInput
    
    subgraph LOCAL["1. Lokaler Kuechenvorrat (pantry_catalog.json)"]
        B --> C["Lokalen Bestand filtern:\nBedingung: currentStockQty > 0"]:::localBranch
        C --> D["Treffer: 'Milsani Magerquark 500g (250g im Kuehlschrank)'"]:::localBranch
    end

    subgraph CLOUD["2. Zentraler Supabase-Katalog (CloudProductCatalogService)"]
        B --> E["Supabase REST-Abfrage:\nGET /products?name=ilike.*Magerquark*"]:::cloudBranch
        E --> F["Treffer mit aktuellem Bestand = 0:\n- Gut & Guenstig Magerquark (Edeka)\n- Ja! Speisequark Magerstufe (Rewe)"]:::cloudBranch
    end

    subgraph DISPLAY["3. Geteilte Benutzeroberflaeche"]
        D --> G["Sektion: 'Aktuell im Vorrat'\n[Button: Verzehr buchen | Bestand aendern]"]:::uiAction
        F --> H["Sektion: 'Aus dem Katalog (Aktuell 0 g)'\n[Button: Auf Einkaufsliste setzen]"]:::uiAction
    end

    H --> I["Klick: Artikel wandert mit Packungsgroesse,\nNaehrwerten und Richtpreis direkt auf die Einkaufsliste"]:::uiAction
```

---

## 8. Schaltplan 4: Einkaufsliste, Buchungen-Tab & Kumulative Monatsbudget-Fuehrung

Jeder Lebensmitteleinkauf wird lueckenlos mit seinem Gesamtpreis in `haushaltsbuch.db` verbucht. Die Einkaufsliste berechnet fuer jeden Folge-Einkauf dynamisch das verbleibende Monatsbudget, um ein Ueberschreiten des 350-EUR-Limits verbindlich zu verhindern.

```mermaid
sequenceDiagram
    autonumber
    actor User as Nutzer
    participant ShopUI as Einkaufsliste Tab (Growcery)
    participant Local as LocalStore.swift
    participant MCP as Unified MCP Server
    participant FinanceDB as haushaltsbuch.db (transactions)
    participant Gem as Google Gemini

    User->>ShopUI: 1. Einkaufsliste oeffnen
    ShopUI->>Local: 2. Geplante Artikel summieren
    Local-->>ShopUI: 3. Geschaetzter Warenkorbpreis (z. B. 28,40 EUR)

    ShopUI->>MCP: 4. Budget-Status abrufen via get_shopping_budget_status()
    MCP->>FinanceDB: 5. SQL-Aggregationsabfrage:
    Note over FinanceDB: SELECT SUM(amount) FROM transactions<br/>WHERE category='Lebensmittel & Drogerie'<br/>AND substr(booking_date, 1, 7) = aktueller_Monat
    FinanceDB-->>MCP: 6. Ausgaben bisher: 242,10 EUR | Monatslimit: 350,00 EUR
    MCP-->>ShopUI: 7. Restbudget = 350,00 EUR - 242,10 EUR = 107,90 EUR

    alt Fall A: Warenkorb (28,40 EUR) <= Restbudget (107,90 EUR)
        ShopUI-->>User: 8. Gruener Status: 'Freigegeben. Verbleibend nach Einkauf: 79,50 EUR'
    else Fall B: Warenkorb uebersteigt Restbudget oder gefaehrdet 100 EUR Dispo-Puffer
        ShopUI-->>User: 8. Rote Warnung: 'Budget ueberschritten! Limit-Sicherung aktiv.'
        User->>Gem: 9. "Passe meine Einkaufsliste an mein Restbudget an!"
        Gem->>MCP: 10. get_shopping_budget_status() + get_pantry_catalog()
        Gem-->>User: 11. Optimierte Liste: Priorisierung proteinreicher Grundnahrungsmittel (Quark, Haferflocken, Eier)
    end

    User->>ShopUI: 12. Einkauf im Markt abschliessen & Kassenbon fotografieren / an Gemini senden
    ShopUI->>FinanceDB: 13. Exakte Gesamtsumme sofort als neue Ausgabe verbuchen
    FinanceDB-->>ShopUI: 14. Kumulierte Monatsausgaben aktualisiert
```

---

## 9. Schaltplan 5: Multi-Source Screenshot- & Beleg-Ingestion ueber Gemini

Komplexe Kassenbons und Finanz-Screenshots (PayPal, Targobank, Apple Wallet) werden ueber die multimodale Ingestion von Google Gemini verarbeitet, welche die Daten ueber MCP direkt in `haushaltsbuch.db` und Supabase speichert.

```mermaid
flowchart TD
    classDef inputZone fill:#1E3A2F,stroke:#7A9A7E,stroke-width:2px,color:#FFFFFF;
    classDef ocrZone fill:#1A2B3C,stroke:#4A6B82,stroke-width:2px,color:#FFFFFF;
    classDef dedupZone fill:#3D2B1F,stroke:#D9C3A5,stroke-width:2px,color:#FFFFFF;
    classDef dbZone fill:#2C223B,stroke:#9B82BA,stroke-width:2px,color:#FFFFFF;

    subgraph SOURCES["1. Multi-Source Bild-Erfassung"]
        S1["Apple Wallet Push / Detail"]:::inputZone
        S2["PayPal Transaktions-Screenshot"]:::inputZone
        S3["Targobank Push-Benachrichtigung"]:::inputZone
        S4["Email-Rechnung / Bestaetigung"]:::inputZone
        S5["Papier-Kassenbon (Supermarkt)"]:::inputZone
    end

    subgraph GEMINI_VISION["2. Google Gemini Vision Engine (Cloud Brain)"]
        SOURCES --> Gem["Google Gemini multimodale Analyse:\nLiest Betraege, Haendler, Rabatte, Pfandzeilen und Status"]:::ocrZone
        Gem --> ToolCall["MCP-Aufruf: log_expense_transaction() oder scan_food_receipt()"]:::ocrZone
    end

    subgraph DEDUP["3. Intelligente Deduplizierungs-Engine (Fuzzy Hash Matching)"]
        ToolCall --> HashGen["Erzeuge synthetischen Transaktions-Hash:\nHash = f(Betrag_Cent, Zeitfenster_+-3Tage, Haendler_Token)"]:::dedupZone
        
        HashGen --> Check{"Existiert bereits Buchung\nmit identischem Hash in\nhaushaltsbuch.db?"}:::dedupZone
        
        Check -->|Nein: Neue Transaktion| InsertLive["Eintragen mit Status 'LIVE_UNSETTLED'\nSofortige Verrechnung mit Kontosaldo"]:::dedupZone
        Check -->|Ja: Treffer gefunden| MergeMeta["Metadaten zusammenfuehren:\nKeine Betragsverdopplung!"]:::dedupZone
    end

    subgraph CSV_IMPORT["4. Spaeterer Targobank CSV-Import (Monatsabschluss)"]
        CSV["Targobank Monats-CSV\n(Offline-Import)"]:::dbZone --> CSVEngine["CSV Reconciliation Parser"]:::dbZone
        CSVEngine --> MatchCheck{"Passt CSV-Zeile auf bestehenden\n'LIVE_UNSETTLED'-Eintrag?\n(Betrag exakt, Datum +- 3 Tage)"}:::dbZone
        
        MatchCheck -->|Match gefunden| Upgrade["Status auf 'AUDITED_SETTLED' heben\nOffizielle Buchungsreferenz ergaenzen\nBetrag bleibt unveraendert"]:::dbZone
        MatchCheck -->|Kein Match| InsertNew["Als neue gepruefte Buchung einfuegen"]:::dbZone
    end

    InsertLive --> DB[("haushaltsbuch.db\n(transactions)")]:::dbZone
    MergeMeta --> DB
    Upgrade --> DB
    InsertNew --> DB
```

---

## 10. Schaltplan 6: Dual-Horizon Transaktions-Architektur (Echtzeit vs. Historische CSV)

Dieser Schaltplan loest das Problem der verzoegerten Buchungsdaten. Er ueberbrueckt die Luecke zwischen historischen Monatsauszuegen und aktuellen Ausgaben der letzten 1 bis 7 Tage.

```mermaid
flowchart LR
    classDef macroZone fill:#1A2B3C,stroke:#4A6B82,stroke-width:2px,color:#FFFFFF;
    classDef microZone fill:#1E3A2F,stroke:#7A9A7E,stroke-width:2px,color:#FFFFFF;
    classDef calcZone fill:#3D2B1F,stroke:#D9C3A5,stroke-width:2px,color:#FFFFFF;
    classDef outZone fill:#2C223B,stroke:#9B82BA,stroke-width:2px,color:#FFFFFF;

    subgraph HORIZON_A["Horizont A: Historische Basis (> 30 Tage)"]
        CSV_Files["Targobank CSV-Dateien\n(Periodischer Batch-Import)"]:::macroZone
        Audited_Rows["Gepruefte Bank-Datensaetze\nStatus: AUDITED_SETTLED\n(194 Buchungen historisch gesichert)"]:::macroZone
        CSV_Files --> Audited_Rows
    end

    subgraph HORIZON_B["Horizont B: Echtzeit-Erfassung (1 Sekunde bis 30 Tage)"]
        direction TB
        Live1["Screenshot-Scanner via Gemini (Wallet / PayPal)"]:::microZone
        Live2["Kassenbon-Scanner via Gemini (Supermarkt)"]:::microZone
        Live3["Quick-Booking (1-Klick Bareingabe)"]:::microZone
        Pending_Rows["Vorlaeufige Datensaetze\nStatus: LIVE_UNSETTLED\n(Aktuelle Woche / Laufender Monat)"]:::microZone
        
        Live1 --> Pending_Rows
        Live2 --> Pending_Rows
        Live3 --> Pending_Rows
    end

    subgraph RECONCILER["Dynamische Salden-Kalkulation (haushaltsbuch.db)"]
        Audited_Rows --> Engine["Echtzeit-Finanz-Rechner\n(C++20 & SQL)"]:::calcZone
        Pending_Rows --> Engine
        
        Formula["Formel:\nEchtzeit-Saldo = Basis-Saldo (CSV)\n+ Neue Einnahmen (Live)\n- Neue Ausgaben (Live)"]:::calcZone
        Engine --- Formula
    end

    subgraph UI_OUTPUT["Anzeige im Buchungen-Tab & Einkaufsliste"]
        Engine --> DisplaySaldo["Echtzeit-Kontostand (tagesaktuell)"]:::outZone
        Engine --> DisplayBudget["Verfuegbares Lebensmittel-Restbudget"]:::outZone
        Engine --> DisplayBuffer["Pruefung 100 EUR Mindestpuffer"]:::outZone
    end
```

---

## 11. Schaltplan 7: Quittungs-Architektur & Hybride Aufbewahrung

Dieser Schaltplan zeigt die Aufbewahrung, Komprimierung und rechtliche/steuerliche Verwendung von Belegen.

```mermaid
flowchart TD
    classDef cap fill:#1E3A2F,stroke:#7A9A7E,stroke-width:2px,color:#FFFFFF;
    classDef ocr fill:#1A2B3C,stroke:#4A6B82,stroke-width:2px,color:#FFFFFF;
    classDef store fill:#3D2B1F,stroke:#D9C3A5,stroke-width:2px,color:#FFFFFF;
    classDef use fill:#2C223B,stroke:#9B82BA,stroke-width:2px,color:#FFFFFF;

    A["Kassenbon fotografieren & an Gemini senden"]:::cap --> B["On-Device Bild-Vorverarbeitung:\n1. Skalierung auf max. 1600x1200\n2. JPEG-Komprimierung (Quality 0.65)\nErgebnis: 150 bis 250 KB Dateigroesse"]:::ocr
    
    B --> C["Gemini Vision Engine:\nBetraege, Artikelzeilen & Haendler semantisch parsen"]:::ocr
    
    subgraph ARCHIV["Hybride Datenspeicherung"]
        B --> D["Supabase Storage Bucket:\n'receipt_images/YYYY-MM/bon_ID.jpg'\n(Verbrauch: nur ca. 20 MB / 100 Belege)"]:::store
        C --> E["Supabase PostgreSQL: public.store_prices\n- EAN-Barcode & Bon-Textzeile\n- Filialname (Penny, Rewe, Edeka)\n- Einzelpreis (EUR)"]:::store
        C --> F["Lokale haushaltsbuch.db:\n- Gesamtbetrag, Datum, Kategorie"]:::store
    end

    subgraph ANWENDUNG["Rechtliche, steuerliche & praktische Nutzung"]
        D --> G["Zweck 1: Steuererklaerung (WISO / Soldatenpauschalen)\n- Aufbewahrung: 4 Jahre (Pflicht nach AO)\n- Nachweis Verpflegungsmehraufwand & Dienstreisen\n- Ziel: 800 bis 1.500 EUR Steuerrueckerstattung fuer Sondertilgung"]:::use
        E --> H["Zweck 2: Filial-Preisvergleich & Inflationstracking\n- Permanente Speicherung (< 1 MB pro Jahr)\n- Gemini vergleicht guenstigste Supermaerkte"]:::use
        F --> I["Zweck 3: Monatsbudget-Abgleich\n- Sofortige Restbudget-Aktualisierung"]:::use
    end
```

---

## 12. Schaltplan 8: Grow-App & GrowTasks Native Inter-Process-Synchronisation

Die Synchronisation zwischen **Grow** (GymApp/GrowFit), **Growcery** und **GrowTasks** erfolgt ueber native iOS Inter-Process Communication (IPC) ohne externe Clouddienste.

```mermaid
sequenceDiagram
    autonumber
    actor User as Nutzer
    participant Fit as Grow / GymApp (Heute-Tab)
    participant Bridge as SharedMacrosBridge.swift
    participant Group as App Group & Shared Keychain (com.nkembi.shared)
    participant Darwin as DarwinNotificationCenter (iOS Kernel)
    participant Tasks as GrowTasks (com.nkembi.growstudy)

    User->>Fit: 1. Letzten Satz abschliessen & 'Workout beenden' tippen
    Fit->>Fit: 2. Workout als Barebones Shell archivieren

    rect rgb(26, 43, 60)
        Note over Fit,Tasks: NATIVE INTER-PROCESS SYNCHRONISATION (Zero-Latency IPC)
        Fit->>Bridge: 3. saveWorkoutScheduleLedger(payload) aufrufen
        Bridge->>Group: 4. Shared JSON schreiben ('shared_workout_schedule.json')
        Bridge->>Group: 5. Shared Keychain updaten (workoutScheduleAccountKey)
        Bridge->>Darwin: 6. System-Event ausloesen:\nDarwinNotificationCenter.post(workoutScheduleLedgerUpdated)
        
        Darwin-->>Tasks: 7. Kernel benachrichtigt GrowTasks-Prozess
        Tasks->>Bridge: 8. loadWorkoutScheduleLedger() ausfuehren
        Bridge->>Group: 9. Aktualisierten Ledger auslesen
        Group-->>Bridge: 10. Workout-Status geladen (Session 'Push A' abgeschlossen)
        Bridge-->>Tasks: 11. Entsprechende Tagesaufgabe identifizieren
        Tasks->>Tasks: 12. Aufgabe 'Sport / Training' automatisch auf erledigt setzen
    end

    Tasks-->>User: 13. UI-Aktualisierung & Haptisches Feedback in GrowTasks
```

---

## 13. Schaltplan 9: Krafttraining & Workout-Steuerung (Supabase-Uebungskatalog & Two-State Workout UI)

### 13.1 Verlagerung des Uebungskatalogs nach Supabase (`public.exercises`)

Gemäß der Zero-Local-Storage-Doktrin wird der bisherige 17 Megabyte grosse statische Katalog vollstaendig aus dem App-Bundle entfernt. Der gesamte **Katalog-Tab der Grow-App entfaellt ersatzlos**.

#### Das relationale Schema in Supabase (`public.exercises`)
Supabase hostet alle 1.324 Uebungen mit folgenden Attributen:
* **Identifikation & Benennung:** `id` (z. B. `ex_0042`), `name_de`, `name_en`, `aliases` (z. B. "BSS", "Ausfallschritt").
* **Muskel-Architektur (fuer visuelle Skelett-Muskelkarten):**
  * `primary_muscles` (z. B. `["quadriceps", "gluteus_maximus"]`)
  * `secondary_muscles` (z. B. `["adductor_magnus", "soleus"]`)
  * `stabilizers` (z. B. `["core_abdominals", "erector_spinae"]`)
  * `synergists` und `antagonists` (zur farblichen Hinterlegung auf vorder- und rueckseitigen Muskelkarten: Anterior & Posterior).
* **Geraete & Ausruestung:** `equipment` (z. B. `["dumbbell", "flat_bench"]`).
* **Anleitung & Biomechanik:**
  * `setup_and_starting_position` (Exakte Gelenkwinkel, Standbreite, Bankhoehe)
  * `movement_execution_steps` (Sequenzieller Ablauf)
  * `mental_cues` (z. B. "Boden wegschieben", "Brust stolz halten")
  * `common_mistakes` (z. B. "Knie kollabiert nach innen", "Gewicht auf den Zehenspitzen")
  * `general_execution_notes`
  * `youtube_demonstration_url` (Direkter Hyperlink zu sauberer Demonstration)
* **Uebungsparameter:**
  * `tracking_mode` (z. B. `WEIGHT_AND_REPS`, `BODYWEIGHT_REPS`, `TIME_DURATION`)
  * `default_rest_seconds` (z. B. 90 bis 180 s)
  * `difficulty_tier` (Beginner, Intermediate, Advanced)
  * `mechanics_type` (Compound / Mehrgelenk vs. Isolation / Isolationsuebung)
  * `force_type` (Push, Pull, Static / Isometrisch)
  * `movement_pattern` (Squat, Hinge, Horizontal Push, Vertical Push, Pull, Carry)
* **Variationen & Progressionen (Relationale Links im Katalog):**
  * `regressions` (Leichtere Alternativen, z. B. Split Squat mit Koerpergewicht)
  * `progressions` (Schwerere Alternativen, z. B. Barbell Bulgarian Split Squat mit Defizit)

### 13.2 Das Two-State Workout UI Model auf dem iPhone

Der Nutzer sieht Uebungsdaten ausschliesslich in zwei Situationen:
1. **Grow-Suchleiste:** Gezielte REST-Suche in Supabase nach einer Uebung.
2. **Heute-Tab (Geplantes Workout):** Gemini und der MCP-Server haben das Workout geplant und in den Heute-Tab sowie in GrowTasks eingetragen.

```mermaid
stateDiagram-v2
    [*] --> ScheduledState: Gemini & MCP planen Workout auf Heute-Tab

    state ScheduledState {
        direction TB
        CollapsedCard: Kompakte Uebungskarte auf Heute-Tab\n(Titel, Zielzeit, Saetze)
        TapAction: Nutzer tippt auf Uebungskarte
        
        state FullArchitectureView {
            direction TB
            MuscleMap: Visuelle Skelett-Muskelkarte\n(Anterior & Posterior hervorgehoben)
            Parameters: Saetze, Ziel-Wdh, Vorgeschlagenes Gewicht
            InstructionCues: Setup, Mentale Cues, Typische Fehler & YouTube-Link
            Buttons: 'Workout Starten' & 'Workout Loeschen'
        }
        
        CollapsedCard --> TapAction
        TapAction --> FullArchitectureView
    }

    FullArchitectureView --> ActiveExecution: Klick auf 'Workout Starten'

    state ActiveExecution {
        direction TB
        LiveTimer: Bildschirm-Wachhaltung & Hintergrund-Rest-Timer
        Haptics: Hosentaschen-Vibration nach 90s Pause
        SetLogging: Satz-Eingabe (Gewicht, Wdh, RPE)
        Autoregulation: Satz-fuer-Satz Anpassung bei RPE >= 9.5
    }

    ActiveExecution --> BarebonesShell: Letzter Satz beendet & 'Workout abschliessen'

    state BarebonesShell {
        direction TB
        ShellView: Minimalistische Historien-Huelle\n(Nur noch: Datum, bewegte Tonnage, Saetze/Wdh, RPE)\nAlle Anleitungen & schweren Muskelkarten werden verworfen
    }

    BarebonesShell --> [*]: Archivierung in workout_history.json & Supabase
```

---

## 14. Schaltplan 10: Zirkadiane Rhythmik & Hydration

Der taegliche Zeitablauf fuer Nahrungsergaenzung und Wasserzufuhr zur Unterstuetzung von Regeneration und Leistungsfaehigkeit.

```mermaid
flowchart TD
    classDef morning fill:#1A2B3C,stroke:#4A6B82,stroke-width:2px,color:#FFFFFF;
    classDef noon fill:#3D2B1F,stroke:#D9C3A5,stroke-width:2px,color:#FFFFFF;
    classDef evening fill:#1E3A2F,stroke:#7A9A7E,stroke-width:2px,color:#FFFFFF;
    classDef night fill:#2C223B,stroke:#9B82BA,stroke-width:2px,color:#FFFFFF;

    subgraph T1["06:00 - 06:45 Uhr: Morgen-Start"]
        A1["06:00 Uhr: 500 mg Rhodiola Rosea (3 % Salidrosid fuer Fokus)"]:::morning
        A2["06:30 Uhr: 150 mg elementares Magnesium-Malat (ATP & Zellelastizitaet)"]:::morning
        A3["Wasser: 500 ml nach dem Aufstehen"]:::morning
        A1 --> A2 --> A3
    end

    subgraph T2["11:45 - 12:30 Uhr: Mittags-Anker"]
        B1["11:45 Uhr: Vitamin D3 (5.000 IE) + K2 MK-7 (200 mcg) zum Essen"]:::noon
        B2["Wasser: 1.500 ml kumulierter Zwischenstand"]:::noon
        A3 --> B1 --> B2
    end

    subgraph T3["16:00 - 17:00 Uhr: Trainings-Fenster"]
        C1["16:00 Uhr: Rote Bete / Nitrat (Pre-Workout Vasodilation)"]:::evening
        C2["16:45 Uhr: 2.000 mg Omega-3 EPA/DHA (Post-Workout Entzuendungshemmung)"]:::evening
        C3["Wasser: 2.500 ml kumulierter Zwischenstand"]:::evening
        B2 --> C1 --> C2 --> C3
    end

    subgraph T4["21:00 - 22:00 Uhr: Schlaf-Vorbereitung"]
        D1["21:00 Uhr: 200 mg elementares Magnesium-Bisglycinat (GABA & Schlaf)"]:::night
        D2["Wasser: 3.500 ml Tagesziel abgeschlossen (keine grossen Mengen vor dem Schlaf)"]:::night
        C3 --> D1 --> D2
    end
```

---

## 15. Master-Integrationsschaltplan: Gesamtkreislauf aller Module

Dieses Gesamtdiagramm fuehrt alle Teilsysteme in einem geschlossenen, sich selbst regulierenden Regelkreis zusammen:

```mermaid
flowchart TD
    classDef coreUI fill:#1E3A2F,stroke:#7A9A7E,stroke-width:2px,color:#FFFFFF;
    classDef mcpCore fill:#1A2B3C,stroke:#4A6B82,stroke-width:2px,color:#FFFFFF;
    classDef cloudDB fill:#3D2B1F,stroke:#D9C3A5,stroke-width:2px,color:#FFFFFF;
    classDef brainAI fill:#2C223B,stroke:#9B82BA,stroke-width:2px,color:#FFFFFF;

    subgraph HARDWARE_CLIENT["iPhone 16 Pro Max (Lean Execution Shell)"]
        UI_Food["Ernaehrung & Vorrat (Growcery)\n(30ms Hardware-Barcode-Beep)"]:::coreUI
        UI_Shop["Einkaufsliste Tab (Growcery)\n(Auto-Budgetkontrolle)"]:::coreUI
        UI_Gym["Krafttraining (Grow Heute-Tab)\n(Two-State UI: Full Architecture vs. Barebones Shell)"]:::coreUI
        UI_Finance["Buchungen Tab (GrowFinance)\n(Saldo- & Ausgabenanzeige)"]:::coreUI
        UI_Tasks["GrowTasks App\n(Routinen & Akademik-Tracking)"]:::coreUI
        Bridge_Core["SharedMacrosBridge (IPC)\n(Keychain & Darwin Notifications)"]:::coreUI

        UI_Gym <==> Bridge_Core
        UI_Food <==> Bridge_Core
        UI_Tasks <==> Bridge_Core
    end

    subgraph MAC_BRAIN["MacBook Air M4 (Lokale Verarbeitungs- und Schnittstellenebene)"]
        MCP_Server["Unified MCP Server (Port 8765)\n40 Werkzeuge, CORSMiddleware, In-Memory-Cache"]:::mcpCore
        Dossier_Store["GROW_ATHLETE_DOSSIER.md\n- 8 Rohdaten-Kategorien (Tier 1-4)\n- Multimodale Haltungsbefunde\n- 14-Tage Ephemer-Bereinigung"]:::mcpCore
        Local_JSON["Lokale JSON-Dateien\n(pantry, shopping, history)"]:::mcpCore
        Finance_DB["haushaltsbuch.db (SQLite WAL)\n(Echtzeit-Saldo, Tilgung, Restbudget)"]:::mcpCore
    end

    subgraph CLOUD_STORAGE["Supabase Cloud PostgreSQL & Storage"]
        DB_Products["products\n(Globale Lebensmittel-Stammdaten)"]:::cloudDB
        DB_Prices["store_prices\n(Filialbezogene Kassenbonpreise)"]:::cloudDB
        DB_Exercises["exercises\n(1.324 Uebungen: Muskelkarten, Cues, YouTube-Links)"]:::cloudDB
        Storage_Buckets["receipt_images\n(Kompakt-Belege max. 250 KB / Bild)"]:::cloudDB
    end

    subgraph AI_ORCHESTRATOR["Google Gemini (Autonome Entscheidungszentrale)"]
        Gemini_Core["Gemini Web- & Mobile-Interface"]:::brainAI
        PreFlight_Hook["1. Pre-Flight Dossier- & Budget-Audit\n(Prueft Reha, Tilgung & Puffer vorab)"]:::brainAI
        PostFlight_Scribe["2. Post-Flight Intent-Klassifikator\n(Speichert neue Fakten automatisch ins Dossier)"]:::brainAI
        Vision_Engine["3. Multimodale Ingestion & Haltungsanalyse\n(Liest Kassenbons, Screenshots & Koerperbau)"]:::brainAI
    end

    %% Client interne Verbindungen
    UI_Food <==>|Bestandsabgleich| Local_JSON
    UI_Shop <==>|Einkaufslisten-Sync| Local_JSON
    UI_Gym <==>|Workouthistorie| Local_JSON
    UI_Finance <==>|Buchungssaldo & Deduplizierung| Finance_DB

    %% Client zu Cloud
    UI_Food -.->|Katalogsuche Bestand 0| DB_Products
    UI_Gym -.->|Uebungssuche via Searchbar| DB_Exercises

    %% Mac interne Verbindungen
    Local_JSON <==> MCP_Server
    Finance_DB <==> MCP_Server
    Dossier_Store <==> MCP_Server

    %% Mac zu Cloud
    MCP_Server -.->|Artikel fuer Rezepte abrufen| DB_Products
    MCP_Server -.->|Supermarktpreise vergleichen| DB_Prices
    MCP_Server -.->|Uebungsdaten abrufen| DB_Exercises

    %% Mac zu Gemini
    MCP_Server <==>|High-Speed Cloudflare Tunnel / HTTPS| Gemini_Core

    %% Gemini Intent Loop
    Gemini_Core --> PreFlight_Hook
    PreFlight_Hook -->|Liest Budget-Status & Reha| Dossier_Store
    PreFlight_Hook -->|Liest Rest-Lebensmittelbudget| Finance_DB
    Gemini_Core --> PostFlight_Scribe
    PostFlight_Scribe -->|Schreibt neue Symptome / Praeferenzen| Dossier_Store
    Gemini_Core --> Vision_Engine
    Vision_Engine -->|Schreibt Beleg- und Buchungsdaten| MCP_Server
    Vision_Engine -->|Registriert Haltungsbefunde| Dossier_Store
    Gemini_Core -->|Plant Workout auf Heute-Tab| UI_Gym
    Gemini_Core -->|Synchronisiert Sport-Aufgabe| UI_Tasks
```

### Zusammenfassung der System-Leitlinien (Version 7.0)

1. **Gemini als Chief Ingestion Brain:** Kassenbons, Bank-Screenshots und Haltungsfotos werden primaer an Gemini uebergeben. Gemini analysiert die Semantik und verbucht die Daten ueber MCP direkt in Supabase und `haushaltsbuch.db`.
2. **iPhone als Ultra-Lean Execution Shell:** Das Smartphone hostet keine statischen Uebungs- oder Lebensmittelkataloge und speichert keine festen Routine-Uebungen lokal. Der fruehere Katalog-Tab entfaellt vollstaendig.
3. **Supabase-zentrierter Uebungskatalog (`public.exercises`):** Alle 1.324 Uebungen liegen zentral in Supabase inklusive detaillierter Muskelkarten (Anterior/Posterior Synergisten & Stabilisatoren), mentalen Cues, typischen Fehlern und YouTube-Demonstrations-Links.
4. **Two-State Workout UI Model:** Ein geplantes Workout oeffnet bei Antippen die vollstaendige interaktive Architektur-Ansicht mit Skelett-Muskelkarte und Satzparametern. Nach Trainingsabschluss verfaellt die Ansicht in eine schlanke, unveränderbare Historien-Huelle (Barebones Shell).
