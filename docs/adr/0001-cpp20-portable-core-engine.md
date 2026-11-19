# ADR 0001: C++20 Portable Core Engine as Single Source of Truth

## Status: Akzeptiert
Datum: 2026-11-19
Kontext: Grow Ecosystem Architecture (Cross-Platform Parity)

## Kontext & Problemstellung
Zuvor existierten geschäfts- und berechnungskritische Logiken (Atwater-Makroberechnung, 5-Gate-Finanzfreigaben, monotone Hydrations-Konsistenz) dupliziert in Swift (iOS) und Kotlin (Android). Dies führte zu Code-Drift und widersprach dem Poka-Yoke-Prinzip (Fehlervermeidung an der Quelle).

## Betrachtete Alternativen
1. Separate Pflege der Logik in Swift und Kotlin (Verworfen: Hohe Redundanz, asynchrone Fehlerbehebungen).
2. Progressive Web App / WebAssembly im WebKit-Container (Verworfen: Hoher Idle-Memory-Footprint 200-400 MB, GC-Latenzen).
3. Gemeinsamer C++20 Core mit nativer C-ABI (Gewählt).

## Getroffene Entscheidung
Auslagerung aller mathematischen, physiologischen und zustandslogischen Berechnungen in eine portable C++20 Shared Library (`GrowCoreCPP`).
- Bereitstellung einer reinen C-ABI (`GrowCoreEngine.h`).
- Direkte Einbindung in Swift ohne Bridging-Header via Swift Package Manager.
- Direkte Einbindung in Android via NDK / JNI (`GrowNativeBridge.kt`).

## Konsequenzen & Metriken
- 100 % Code-Wiederverwendung für Geschäftslogik.
- Deterministische Ausführung im Sub-Mikrosekundenbereich (0 ms Garbage Collection).
- Einheitliches Verhalten auf allen Plattformen.
