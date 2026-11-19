import Foundation
import Network

public struct GrowSyncPacket: Codable, Sendable {
    public let deviceId: String
    public let timestamp: Double
    public let entityType: String
    public let payloadJson: String

    public init(deviceId: String, timestamp: Double = Date().timeIntervalSince1970, entityType: String, payloadJson: String) {
        self.deviceId = deviceId
        self.timestamp = timestamp
        self.entityType = entityType
        self.payloadJson = payloadJson
    }
}

public final class GrowMeshSyncEngine: @unchecked Sendable {
    public static let shared = GrowMeshSyncEngine()
    public static let serviceType = "_growmesh._tcp"

    private let deviceId = UUID().uuidString
    private var listener: NWListener?
    private var browser: NWBrowser?
    private var activeConnections: [NWConnection] = []
    private let queue = DispatchQueue(label: "com.grow.core.mesh", qos: .utility)

    public var onPacketReceived: ((GrowSyncPacket) -> Void)?

    public init() {}

    public func startMesh() {
        startListener()
        startBrowser()
    }

    public func stopMesh() {
        listener?.cancel()
        browser?.cancel()
        for conn in activeConnections {
            conn.cancel()
        }
        activeConnections.removeAll()
    }

    // MARK: - Bonjour Listener (Server)
    private func startListener() {
        do {
            let params = NWParameters.tcp
            let listener = try NWListener(using: params)
            listener.service = NWListener.Service(type: Self.serviceType)

            listener.newConnectionHandler = { [weak self] newConnection in
                self?.handleIncomingConnection(newConnection)
            }

            listener.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    print("GrowMeshSyncEngine: Bonjour listener active on \(Self.serviceType)")
                case .failed(let err):
                    print("GrowMeshSyncEngine: Listener error: \(err)")
                default:
                    break
                }
            }

            listener.start(queue: queue)
            self.listener = listener
        } catch {
            print("GrowMeshSyncEngine: Failed to create NWListener: \(error)")
        }
    }

    // MARK: - Bonjour Browser (Client Discovery)
    private func startBrowser() {
        let params = NWParameters()
        let descriptor = NWBrowser.Descriptor.bonjour(type: Self.serviceType, domain: nil)
        let browser = NWBrowser(for: descriptor, using: params)

        browser.browseResultsChangedHandler = { [weak self] results, changes in
            guard let self = self else { return }
            for result in results {
                if case .service = result.endpoint {
                    // Connect to discovered peer
                    self.connectToPeer(endpoint: result.endpoint)
                }
            }
        }

        browser.start(queue: queue)
        self.browser = browser
    }

    private func connectToPeer(endpoint: NWEndpoint) {
        let conn = NWConnection(to: endpoint, using: .tcp)
        conn.stateUpdateHandler = { [weak self] state in
            if state == .ready {
                self?.setupReceive(on: conn)
            }
        }
        conn.start(queue: queue)
        activeConnections.append(conn)
    }

    private func handleIncomingConnection(_ conn: NWConnection) {
        conn.stateUpdateHandler = { [weak self] state in
            if state == .ready {
                self?.setupReceive(on: conn)
            }
        }
        conn.start(queue: queue)
        activeConnections.append(conn)
    }

    private func setupReceive(on conn: NWConnection) {
        conn.receive(minimumIncompleteLength: 4, maximumLength: 65536) { [weak self] content, _, isComplete, error in
            if let data = content, let packet = try? JSONDecoder().decode(GrowSyncPacket.self, from: data) {
                if packet.deviceId != self?.deviceId {
                    self?.onPacketReceived?(packet)
                }
            }
            if !isComplete && error == nil {
                self?.setupReceive(on: conn)
            }
        }
    }

    public func broadcastDelta(entityType: String, payloadJson: String) {
        let packet = GrowSyncPacket(deviceId: self.deviceId, entityType: entityType, payloadJson: payloadJson)
        guard let data = try? JSONEncoder().encode(packet) else { return }

        for conn in activeConnections {
            conn.send(content: data, completion: .idempotent)
        }
    }
}
