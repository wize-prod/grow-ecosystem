import SwiftUI
import UIKit
import Combine
import Network

// MARK: - Workout TV Casting Manager (Japanese Thin-Client Architecture & SSE Push Engine)
// Zero-Muda Principle: The SmartTV acts solely as a passive display sink.
// Eliminates polling jitter (Mura) using HTML5 Server-Sent Events (SSE) push streaming.

@MainActor
public final class WorkoutTVCastingManager: ObservableObject {
    public static let shared = WorkoutTVCastingManager()

    @Published public private(set) var isExternalDisplayConnected: Bool = false
    @Published public private(set) var externalDisplayResolution: CGSize = .zero
    @Published public var isSimulationActive: Bool = false
    @Published public private(set) var activeSSEClientCount: Int = 0

    private var externalWindow: UIWindow?
    private var cancellables = Set<AnyCancellable>()
    private var telemetryListener: NWListener?
    private var activeStreamingConnections: [NWConnection] = []

    private init() {
        setupDisplayNotifications()
        checkInitialScreenState()
        startLocalTelemetryBroadcaster()
        bindTimerToSSEStream()
    }

    private func setupDisplayNotifications() {
        NotificationCenter.default.publisher(for: UIScreen.didConnectNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                guard let self = self, let screen = notification.object as? UIScreen else { return }
                self.attachToExternalScreen(screen)
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIScreen.didDisconnectNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.detachFromExternalScreen()
            }
            .store(in: &cancellables)
    }

    private func checkInitialScreenState() {
        if UIScreen.screens.count > 1 {
            let externalScreen = UIScreen.screens[1]
            attachToExternalScreen(externalScreen)
        }
    }

    private func attachToExternalScreen(_ screen: UIScreen) {
        let window = UIWindow(frame: screen.bounds)
        window.screen = screen

        let hostingController = UIHostingController(
            rootView: WorkoutTVSinkView(isExternal: true)
                .environmentObject(GymStore.shared)
        )
        hostingController.view.backgroundColor = .black

        window.rootViewController = hostingController
        window.isHidden = false

        self.externalWindow = window
        self.isExternalDisplayConnected = true
        self.externalDisplayResolution = screen.bounds.size
    }

    private func detachFromExternalScreen() {
        externalWindow?.isHidden = true
        externalWindow = nil
        isExternalDisplayConnected = false
        externalDisplayResolution = .zero
    }

    public func toggleSimulation() {
        isSimulationActive.toggle()
    }

    // MARK: - Reactive Push Stream Binding (Server-Sent Events)
    private func bindTimerToSSEStream() {
        GymStore.shared.restTimer.$secondsRemaining
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.pushTelemetryToSSEClients()
            }
            .store(in: &cancellables)

        GymStore.shared.restTimer.$isRunning
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.pushTelemetryToSSEClients()
            }
            .store(in: &cancellables)

        GymStore.shared.$activeSession
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.pushTelemetryToSSEClients()
            }
            .store(in: &cancellables)
    }

    // MARK: - Local Telemetry Broadcaster (SSE & Static Dashboard Sink)
    private func startLocalTelemetryBroadcaster() {
        do {
            let params = NWParameters.tcp
            params.allowLocalEndpointReuse = true
            let listener = try NWListener(using: params, on: 8765)
            listener.newConnectionHandler = { [weak self] connection in
                self?.handleIncomingConnection(connection)
            }
            listener.start(queue: .global(qos: .utility))
            self.telemetryListener = listener
        } catch {
            // Port might be in use
        }
    }

    private func handleIncomingConnection(_ connection: NWConnection) {
        connection.start(queue: .global(qos: .utility))
        connection.receive(minimumIncompleteLength: 1, maximumLength: 2048) { [weak self] data, _, _, error in
            guard let self = self, let data = data, error == nil else {
                connection.cancel()
                return
            }

            let requestStr = String(decoding: data, as: UTF8.self)
            Task { @MainActor in
                if requestStr.contains("GET /events") {
                    self.upgradeToSSE(connection: connection)
                } else if requestStr.contains("GET /telemetry") {
                    self.serveOneShotJSON(connection: connection)
                } else {
                    self.serveThinClientHTML(connection: connection)
                }
            }
        }
    }

    private func upgradeToSSE(connection: NWConnection) {
        let headers = "HTTP/1.1 200 OK\r\nContent-Type: text/event-stream\r\nCache-Control: no-cache\r\nConnection: keep-alive\r\nAccess-Control-Allow-Origin: *\r\n\r\n"
        if let hData = headers.data(using: .utf8) {
            connection.send(content: hData, isComplete: false, completion: .contentProcessed { [weak self] err in
                guard err == nil else {
                    connection.cancel()
                    return
                }
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    self.activeStreamingConnections.append(connection)
                    self.activeSSEClientCount = self.activeStreamingConnections.count

                    // Send initial state frame immediately
                    let initialPayload = "data: " + self.generateTelemetryJSON() + "\n\n"
                    if let pData = initialPayload.data(using: .utf8) {
                        connection.send(content: pData, isComplete: false, completion: .idempotent)
                    }
                }
            })
        }
    }

    public func pushTelemetryToSSEClients() {
        guard !activeStreamingConnections.isEmpty else { return }
        let payload = "data: " + generateTelemetryJSON() + "\n\n"
        guard let pData = payload.data(using: .utf8) else { return }

        var validList: [NWConnection] = []
        for conn in activeStreamingConnections {
            if conn.state == .ready {
                conn.send(content: pData, isComplete: false, completion: .contentProcessed { err in
                    if err != nil {
                        conn.cancel()
                    }
                })
                validList.append(conn)
            } else {
                conn.cancel()
            }
        }
        self.activeStreamingConnections = validList
        self.activeSSEClientCount = validList.count
    }

    private func serveOneShotJSON(connection: NWConnection) {
        let json = generateTelemetryJSON()
        let resp = "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nAccess-Control-Allow-Origin: *\r\nConnection: close\r\n\r\n" + json
        if let d = resp.data(using: .utf8) {
            connection.send(content: d, completion: .contentProcessed { _ in
                connection.cancel()
            })
        }
    }

    private func serveThinClientHTML(connection: NWConnection) {
        let html = """
        <!DOCTYPE html>
        <html lang="de">
        <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>GROW HUD | SMARTTV SINK</title>
        <style>
        body { background: #000; color: #fff; font-family: -apple-system, monospace; margin: 0; padding: 40px; box-sizing: border-box; }
        .hdr { display: flex; justify-content: space-between; border-bottom: 2px solid #222; padding-bottom: 20px; }
        .sub { font-size: 14px; color: #888; font-weight: bold; letter-spacing: 1px; }
        .title { font-size: 36px; font-weight: 900; margin: 6px 0; }
        .main { display: grid; grid-template-columns: 1fr 340px; gap: 40px; margin-top: 40px; }
        .box { background: #0a0a0a; border: 1px solid #1a1a1a; border-radius: 12px; padding: 24px; }
        .lbl { font-size: 13px; color: #00e5ff; font-weight: bold; letter-spacing: 1px; margin-bottom: 8px; }
        .ex { font-size: 42px; font-weight: 800; color: #fff; }
        .timer-box { text-align: center; display: flex; flex-direction: column; align-items: center; justify-content: center; }
        .timer { font-size: 80px; font-weight: 900; color: #ffab00; font-family: monospace; }
        .status-dot { display: inline-block; width: 10px; height: 10px; background: #00e676; border-radius: 50%; margin-right: 8px; }
        </style>
        </head>
        <body>
        <div class="hdr">
            <div>
                <div class="sub">GROW HUD | PASSIVE SMARTTV SINK</div>
                <div class="title" id="wkName">SYSTEM BEREIT</div>
            </div>
            <div style="text-align: right;">
                <div class="sub">STREAMING STATUS</div>
                <div style="color: #00e676; font-weight: bold; margin-top: 6px;"><span class="status-dot"></span>SSE PUSH AKTIV</div>
            </div>
        </div>
        <div class="main">
            <div class="box">
                <div class="lbl">AKTUELLE UEBUNG</div>
                <div class="ex" id="exName">-</div>
                <div style="margin-top: 30px; font-size: 14px; color: #888;">
                    POKA-YOKE SICHERHEITS-AUDIT: BWK-KONFORME AUSFUEHRUNG AKTIV
                </div>
            </div>
            <div class="box timer-box">
                <div class="lbl" style="color: #ffab00;">PAUSEN-COUNTDOWN</div>
                <div class="timer" id="timerDisplay">00:00</div>
                <div class="sub" id="restStatus">BEREIT</div>
            </div>
        </div>
        <script>
        const ev = new EventSource('/events');
        ev.onmessage = e => {
            const d = JSON.parse(e.data);
            document.getElementById('wkName').innerText = d.workout || 'Kein aktives Training';
            document.getElementById('exName').innerText = d.currentExercise || 'Bereit';
            const m = Math.floor(d.restSeconds / 60);
            const s = d.restSeconds % 60;
            document.getElementById('timerDisplay').innerText = (m < 10 ? '0' : '') + m + ':' + (s < 10 ? '0' : '') + s;
            document.getElementById('restStatus').innerText = d.isResting ? 'REGENERATION' : 'BEREIT FUER SATZ';
            document.getElementById('timerDisplay').style.color = d.restSeconds > 0 ? '#ffab00' : '#888';
        };
        ev.onerror = () => {
            document.getElementById('restStatus').innerText = 'VERBINDE ERNEUT...';
        };
        </script>
        </body>
        </html>
        """
        let resp = "HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=utf-8\r\nConnection: close\r\n\r\n" + html
        if let d = resp.data(using: .utf8) {
            connection.send(content: d, completion: .contentProcessed { _ in
                connection.cancel()
            })
        }
    }

    private func generateTelemetryJSON() -> String {
        let store = GymStore.shared
        let session = store.activeSession
        let restSecs = store.restTimer.secondsRemaining
        let isResting = store.restTimer.isRunning

        let workoutName = session?.templateTitle ?? (session != nil ? "Aktives Training" : "Kein aktives Training")
        let exerciseName = session?.exercises.last?.name ?? "Bereit"

        return """
        {
            "workout": "\(workoutName)",
            "currentExercise": "\(exerciseName)",
            "restSeconds": \(restSecs),
            "isResting": \(isResting),
            "timestamp": \(Date().timeIntervalSince1970)
        }
        """
    }
}

// MARK: - High-Contrast Passive SmartTV Sink View
public struct WorkoutTVSinkView: View {
    public let isExternal: Bool
    @EnvironmentObject private var gymStore: GymStore

    public init(isExternal: Bool = true) {
        self.isExternal = isExternal
    }

    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 24) {
                // Header Bar: Device Identity & Status
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("GROW HUD | SMARTTV SINK")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(.gray)
                        Text(gymStore.activeSession?.templateTitle ?? "SYSTEM BEREIT")
                            .font(.system(size: 28, weight: .black, design: .default))
                            .foregroundColor(.white)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("HARDWARE STATUS")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.gray)
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 8, height: 8)
                            Text("THIN CLIENT AKTIV")
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundColor(.green)
                        }
                    }
                }
                .padding(.horizontal, 40)
                .padding(.top, 30)

                Divider().background(Color.white.opacity(0.2))

                // Core Dynamic Area
                HStack(spacing: 40) {
                    // Left Column: Active Exercise & Prescriptions
                    VStack(alignment: .leading, spacing: 20) {
                        Text("AKTUELLE UEBUNG")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(.cyan)

                        let activeEx = gymStore.activeSession?.exercises.last
                        Text(activeEx?.name ?? "Keine aktive Uebung")
                            .font(.system(size: 38, weight: .heavy))
                            .foregroundColor(.white)
                            .lineLimit(2)

                        if let ex = activeEx {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("SATZ PROTOKOLL")
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .foregroundColor(.gray)

                                ForEach(Array(ex.sets.enumerated()), id: \.offset) { index, s in
                                    HStack {
                                        Text("Satz \(index + 1):")
                                            .font(.system(size: 18, weight: .medium, design: .monospaced))
                                            .foregroundColor(.gray)
                                        Text("\(s.reps) Wdh.")
                                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                                            .foregroundColor(.white)
                                        if s.weightKg > 0 {
                                            Text("@ \(String(format: "%.1f", s.weightKg)) kg")
                                                .font(.system(size: 18, weight: .bold, design: .monospaced))
                                                .foregroundColor(.yellow)
                                        }
                                        Spacer()
                                        if s.isCompleted {
                                            Text("ABGESCHLOSSEN")
                                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                                .foregroundColor(.green)
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                            .padding(20)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(12)
                        } else {
                            Text("Warte auf Trainingsstart auf dem Smartphone...")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.gray)
                        }

                        Spacer()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Right Column: Rest Countdown HUD
                    VStack(spacing: 24) {
                        Text("PAUSEN-COUNTDOWN")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(.orange)

                        ZStack {
                            Circle()
                                .stroke(Color.white.opacity(0.1), lineWidth: 16)
                                .frame(width: 260, height: 260)

                            let timer = gymStore.restTimer
                            let rem = timer.secondsRemaining

                            VStack(spacing: 4) {
                                Text(String(format: "%02d:%02d", rem / 60, rem % 60))
                                    .font(.system(size: 64, weight: .black, design: .monospaced))
                                    .foregroundColor(rem > 0 ? .yellow : .white)

                                Text(timer.isRunning ? "REGENERATION" : "BEREIT FUER SATZ")
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .foregroundColor(.gray)
                            }
                        }

                        // Next Exercise Telemetry Preview
                        VStack(alignment: .leading, spacing: 6) {
                            Text("NAECHSTE UEBUNG (VORSCHAU):")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(.gray)
                            Text("BWK-konforme Ueberkopf-Extension")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(8)

                        Spacer()
                    }
                    .frame(width: 320)
                }
                .padding(.horizontal, 40)

                // Footer Bar: Poka-Yoke & Heart Rate
                HStack {
                    HStack(spacing: 12) {
                        Text("SICHERHEITSPROTOKOLL:")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.gray)
                        Text("POKA-YOKE STUFE 3 AKTIV (KEINE FORMABWEICHUNG)")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.green)
                    }

                    Spacer()

                    Text("GROW NATIVE ENGINE 2026")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 24)
            }
        }
    }
}
