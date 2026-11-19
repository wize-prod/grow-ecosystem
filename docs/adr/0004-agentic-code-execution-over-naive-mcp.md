# ADR 0004: Agentic Code Execution Architecture over Naive Sequential MCP

## Status: Akzeptiert
Datum: 2026-11-19
Kontext: AI Consultation & Health Onboarding Protocol

## Kontext & Problemstellung
Die Personalisierung von Trainings-, Ernährungs- und Supplement-Vorgaben für unterschiedliche Nutzer (Athlet vs. Mutter mit Osteopenie/Bluthochdruck) erfordert das Filtern Hunderter Übungen, Substanzen und Kontraindikationen. Naives sequentielles MCP-Tool-Calling würde dutzende Roundtrips und über 80.000 Tokens pro Anamnese verbrauchen.

## Betrachtete Alternativen
1. Naives MCP mit granularen Einzelfunktionen (Verworfen: Hohe Latenz >30s, Token-Explosion, Halluzinationsrisiko bei Berechnungen).
2. Statische Regelwerke ohne KI (Verworfen: Kann die Varianz individueller Krankheitsbilder und Medikationen nicht abbilden).
3. Agentic Code Execution / "Code Mode" (Gewählt).

## Getroffene Entscheidung
Umstellung auf das Cloudflare/Anthropic "Code Mode"-Paradigma:
- Das Sprachmodell erhält zwei Basis-Tools (`search_api`, `execute_code`).
- Das Modell generiert ein kompaktes Python/C++-Skript, das lokal in einer gesicherten Sandbox operiert.
- Das Skript greift mit nativer Geschwindigkeit auf die SQLite-Kataloge zu, führt deterministische BMR-Formeln aus und filtert Kontraindikationen auf Maschinenebene (*Poka-Yoke*).
- An die Applikation wird ausschließlich das finale `UserProfileContract`-JSON übergeben.

## Konsequenzen & Metriken
- Token-Einsparung von ca. 99 % (~900 Tokens vs. ~80.000 Tokens).
- Latenzreduktion auf unter 800 Millisekunden (1 Request statt 15 Roundtrips).
- Mathematische und medizinische Korrektheit durch deterministische Code-Ausführung.
