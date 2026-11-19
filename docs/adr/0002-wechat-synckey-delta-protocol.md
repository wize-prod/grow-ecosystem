# ADR 0002: WeChat SyncKey Protocol & Vector Clock Delta Synchronization

## Status: Akzeptiert
Datum: 2026-11-19
Kontext: Cross-Device Peer-to-Peer Mesh (MultipeerConnectivity)

## Kontext & Problemstellung
Das bisherige Mesh-Netzwerk übertrug bei jeder Zustandsänderung das vollständige `SharedEcosystemSyncBundle` (Hunderte Mahlzeiten, alle Workouts, alle Notizen). Dies erzeugte bei wachsender Datenbankgröße Hunderte Kilobytes an JSON-Datenverkehr pro Sync und führte zu Re-Transmits in schwachen WLAN-Netzwerken.

## Betrachtete Alternativen
1. Regelmäßiges Full-State Polling (Verworfen: Hoher Bandbreiten- und CPU-Overhead).
2. Zentraler Cloud-Sync via Firebase (Verworfen: Cloud-Kosten, Abhängigkeit, Latenz).
3. Monotone Sequenznummern mit Delta-Operationen nach dem WeChat SyncKey-Prinzip (Gewählt).

## Getroffene Entscheidung
Implementierung des `PeerSyncEnvelope`-Protokolls in `GrowPeerSyncService.swift`:
1. Jedes Gerät führt eine monotone `localSyncSequenceId` in `GrowMMKV`.
2. Bei Verbindung tauschen Geräte einen sub-100-Byte-Handshake (`handshake(tenantKey, clientSeq)`) aus.
3. Nur wenn `clientSeq < localSyncSequenceId` gilt, werden ausschließlich die fehlenden Deltas (`[SyncDeltaOp]`) übertragen.
4. Bei identischer Sequenznummer erfolgt keine Datenübertragung (0 Bytes).

## Konsequenzen & Metriken
- Reduktion des Netzwerkverkehrs bei Routine-Änderungen um über 99,5 % (< 150 Bytes pro Update).
- Vermeidung von Netzwerk-Jitter (*Mura*).
- Robuste Ausfallsicherheit auch bei schlechter Verbindung.
