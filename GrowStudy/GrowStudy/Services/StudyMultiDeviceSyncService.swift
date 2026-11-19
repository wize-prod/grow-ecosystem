import Foundation
import Network
import Combine
import SwiftUI

// MARK: - Multi-Device Sync Payload
public struct GrowTasksSyncPayload: Codable, Sendable {
    public var version: Int = 1
    public var deviceName: String
    public var timestamp: Date
    public var steps: [RoadmapStep]
    public var folders: [StudyFolder]
    public var customListNames: [String]
    public var labels: [TaskColorLabel]
    public var progress: [String: Bool]
    public var subtasks: [String: [String: Bool]]
    public var submodules: [String: [String: Bool]]
    public var planning: [String: StepPlanningRecord]

    public init(
        deviceName: String,
        timestamp: Date = Date(),
        steps: [RoadmapStep],
        folders: [StudyFolder],
        customListNames: [String],
        labels: [TaskColorLabel],
        progress: [String: Bool],
        subtasks: [String: [String: Bool]],
        submodules: [String: [String: Bool]],
        planning: [String: StepPlanningRecord]
    ) {
        self.deviceName = deviceName
        self.timestamp = timestamp
        self.steps = steps
        self.folders = folders
        self.customListNames = customListNames
        self.labels = labels
        self.progress = progress
        self.subtasks = subtasks
        self.submodules = submodules
        self.planning = planning
    }
}

// MARK: - Bonjour P2P & iCloud Multi-Device Sync Engine
public final class StudyMultiDeviceSyncService: ObservableObject {
    public static let shared = StudyMultiDeviceSyncService()

    @Published public private(set) var isConnectedToPeer: Bool = false
    @Published public private(set) var connectedPeerName: String = ""
    @Published public private(set) var lastSyncDate: Date? = nil
    @Published public private(set) var syncStatusText: String = "Bereit"

    private let bonjourType = "_growtasks._tcp"
    private var listener: NWListener?
    private var browser: NWBrowser?
    private var activeConnections: [NWConnection] = []

    private let syncQueue = DispatchQueue(label: "com.nkembi.growstudy.sync", qos: .utility)

    // Fallback iCloud Obsidian Vault Sync Path on Mac
    private let macObsidianSyncURL = URL(fileURLWithPath: "/Users/parris-campbellnkembi/Library/Mobile Documents/iCloud~md~obsidian/Documents/CyberSecurity_Vault/.growtasks_sync.json")

    private init() {
        startBonjourListener()
        startBonjourBrowser()
        Task { @MainActor in
            self.checkiCloudMirrorSync()
        }
    }

    // MARK: - Bonjour Listener (Server Mode)
    public func startBonjourListener() {
        do {
            let params = NWParameters.tcp
            let service = NWListener.Service(type: bonjourType)
            let listener = try NWListener(service: service, using: params)
            listener.stateUpdateHandler = { [weak self] state in
                DispatchQueue.main.async {
                    switch state {
                    case .ready:
                        self?.syncStatusText = "P2P-Sync aktiv"
                    case .failed(let err):
                        self?.syncStatusText = "P2P-Sync offline (\(err.localizedDescription))"
                    default: break
                    }
                }
            }
            listener.newConnectionHandler = { [weak self] connection in
                self?.handleIncomingConnection(connection)
            }
            listener.start(queue: syncQueue)
            self.listener = listener
        } catch {
            print("[StudyMultiDeviceSyncService] Listener init failed: \(error)")
        }
    }

    // MARK: - Bonjour Browser (Client Mode)
    public func startBonjourBrowser() {
        let params = NWParameters.tcp
        let browser = NWBrowser(for: .bonjour(type: bonjourType, domain: nil), using: params)
        browser.browseResultsChangedHandler = { [weak self] results, _ in
            for result in results {
                if case .service(let name, _, _, _) = result.endpoint {
                    #if targetEnvironment(macCatalyst)
                    if name.contains("Mac") { continue }
                    #endif
                    self?.connectToEndpoint(result.endpoint, peerName: name)
                }
            }
        }
        browser.start(queue: syncQueue)
        self.browser = browser
    }

    private func connectToEndpoint(_ endpoint: NWEndpoint, peerName: String) {
        let connection = NWConnection(to: endpoint, using: .tcp)
        connection.stateUpdateHandler = { [weak self] state in
            guard let self = self else { return }
            switch state {
            case .ready:
                self.receivePayload(from: connection)
                Task { @MainActor in
                    self.isConnectedToPeer = true
                    self.connectedPeerName = peerName
                    self.syncStatusText = "Verbunden mit \(peerName)"
                    self.activeConnections.append(connection)
                    self.sendCurrentState(via: connection)
                }
            case .failed, .cancelled:
                Task { @MainActor in
                    self.activeConnections.removeAll { $0 === connection }
                    if self.activeConnections.isEmpty {
                        self.isConnectedToPeer = false
                        self.connectedPeerName = ""
                        self.syncStatusText = "Warte auf Gegenstelle"
                    }
                }
            default: break
            }
        }
        connection.start(queue: syncQueue)
    }

    private func handleIncomingConnection(_ connection: NWConnection) {
        connection.stateUpdateHandler = { [weak self] state in
            guard let self = self else { return }
            switch state {
            case .ready:
                self.receivePayload(from: connection)
                Task { @MainActor in
                    self.isConnectedToPeer = true
                    self.syncStatusText = "Gegenstelle verbunden"
                    self.activeConnections.append(connection)
                    self.sendCurrentState(via: connection)
                }
            case .failed, .cancelled:
                Task { @MainActor in
                    self.activeConnections.removeAll { $0 === connection }
                    if self.activeConnections.isEmpty {
                        self.isConnectedToPeer = false
                        self.connectedPeerName = ""
                    }
                }
            default: break
            }
        }
        connection.start(queue: syncQueue)
    }

    // MARK: - Send / Receive Protocols
    @MainActor
    public func broadcastSync() {
        for conn in activeConnections {
            sendCurrentState(via: conn)
        }
        exportToiCloudMirror()
    }

    @MainActor
    private func sendCurrentState(via connection: NWConnection) {
        guard let payload = createSyncPayload() else { return }
        guard let data = try? JSONEncoder().encode(payload) else { return }

        var length = UInt32(data.count).bigEndian
        var packet = Data(bytes: &length, count: 4)
        packet.append(data)

        connection.send(content: packet, completion: .contentProcessed { [weak self] error in
            if error == nil {
                Task { @MainActor in
                    self?.lastSyncDate = Date()
                    self?.syncStatusText = "Synchronisiert: \(self?.formatTime(Date()) ?? "")"
                }
            }
        })
    }

    private func receivePayload(from connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 4, maximumLength: 4) { [weak self] data, _, isComplete, error in
            guard let self = self, let data = data, data.count == 4, error == nil else {
                if !isComplete { self?.receivePayload(from: connection) }
                return
            }

            let length = data.withUnsafeBytes { $0.load(as: UInt32.self).bigEndian }
            connection.receive(minimumIncompleteLength: Int(length), maximumLength: Int(length)) { payloadData, _, _, err in
                if let payloadData = payloadData, err == nil {
                    if let receivedPayload = try? JSONDecoder().decode(GrowTasksSyncPayload.self, from: payloadData) {
                        Task { @MainActor in
                            self.applyReceivedPayload(receivedPayload)
                        }
                    }
                }
                self.receivePayload(from: connection)
            }
        }
    }

    // MARK: - State Application
    @MainActor
    private func applyReceivedPayload(_ payload: GrowTasksSyncPayload) {
        let store = StudyStore.shared

        if let last = self.lastSyncDate, payload.timestamp < last {
            return
        }

        var existingMap = Dictionary(uniqueKeysWithValues: store.steps.map { ($0.id, $0) })
        for incoming in payload.steps {
            if let existing = existingMap[incoming.id] {
                var merged = existing
                merged.notes = incoming.notes.isEmpty ? existing.notes : incoming.notes
                merged.plannedDate = incoming.plannedDate ?? existing.plannedDate
                merged.calendarEventId = incoming.calendarEventId ?? existing.calendarEventId
                merged.isCompleted = incoming.isCompleted || existing.isCompleted
                merged.resources = incoming.resources.isEmpty ? existing.resources : incoming.resources
                merged.submodules = incoming.submodules.isEmpty ? existing.submodules : incoming.submodules
                existingMap[incoming.id] = merged
            } else {
                existingMap[incoming.id] = incoming
            }
        }
        store.steps = Array(existingMap.values)

        var folderMap = Dictionary(uniqueKeysWithValues: store.folders.map { ($0.id, $0) })
        for incoming in payload.folders {
            folderMap[incoming.id] = incoming
        }
        store.folders = Array(folderMap.values)

        store.saveAllData()
        self.lastSyncDate = Date()
        self.syncStatusText = "Synchronisiert mit \(payload.deviceName)"
    }

    @MainActor
    private func createSyncPayload() -> GrowTasksSyncPayload? {
        let store = StudyStore.shared
        #if targetEnvironment(macCatalyst)
        let name = "MacBook Air"
        #else
        let name = "iPhone 16 Pro Max"
        #endif

        return GrowTasksSyncPayload(
            deviceName: name,
            timestamp: Date(),
            steps: store.steps,
            folders: store.folders,
            customListNames: store.customListNames,
            labels: store.labels,
            progress: store.progressMap,
            subtasks: store.subtasksMap,
            submodules: store.submodulesMap,
            planning: store.planningMap
        )
    }

    // MARK: - iCloud Mirror Bridge
    @MainActor
    private func exportToiCloudMirror() {
        #if targetEnvironment(macCatalyst)
        guard let payload = createSyncPayload(),
              let data = try? JSONEncoder().encode(payload) else { return }
        try? data.write(to: macObsidianSyncURL, options: .atomic)
        #endif
    }

    @MainActor
    private func checkiCloudMirrorSync() {
        #if targetEnvironment(macCatalyst)
        if FileManager.default.fileExists(atPath: macObsidianSyncURL.path),
           let data = try? Data(contentsOf: macObsidianSyncURL),
           let payload = try? JSONDecoder().decode(GrowTasksSyncPayload.self, from: data) {
            applyReceivedPayload(payload)
        }
        #endif
    }

    private func formatTime(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "HH:mm:ss"
        return df.string(from: date)
    }
}
