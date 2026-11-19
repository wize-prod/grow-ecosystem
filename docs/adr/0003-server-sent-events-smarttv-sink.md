# ADR 0003: Server-Sent Events (SSE) Push Stream for SmartTV HUD

## Status: Akzeptiert
Datum: 2026-11-19
Kontext: SmartTV Casting & Workout Live-HUD

## Kontext & Problemstellung
Das initiale Casting auf externe Fernseher nutzte periodisches HTTP-Polling (1 Anfrage pro Sekunde). Dies erzeugte 3.600 HTTP-Verbindungsaufbauten pro Trainingsstunde und führte auf leistungsschwachen SmartTV-Browsern zu Speicherlecks und Systemabstürzen.

## Betrachtete Alternativen
1. Installation einer nativen SmartTV-App (Verworfen: Hoher Pflegeaufwand für Samsung Tizen, LG webOS, Android TV).
2. HTTP-Polling (Verworfen: Hohe CPU-Last auf dem Fernseher, Latenzschwankungen).
3. HTML5 Server-Sent Events (SSE) Push-Streaming (Gewählt).

## Getroffene Entscheidung
Erweiterung des `WorkoutTVCastingManager.swift` um einen persistenten HTTP/1.1 SSE-Endpunkt (`GET /events`):
- Das Smartphone hält eine persistente TCP-Verbindung offen (`Content-Type: text/event-stream`).
- Bei jedem Countdown-Tick oder Satzabschluss sendet das Smartphone einen ultrakompakten 50-Byte-Frame (`data: {...}\n\n`).
- Einbettung eines autarken 2-KB HTML/JS-Thin-Clients (`GET /`), der mit nativem `EventSource` arbeitet.

## Konsequenzen & Metriken
- 0 % CPU-Last auf dem SmartTV im Ruhezustand.
- Keine Notwendigkeit einer App-Installation auf dem SmartTV.
- Exakte, verzögerungsfreie Countdown-Synchronisation.
