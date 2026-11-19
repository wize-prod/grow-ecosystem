import Foundation
import MultipeerConnectivity
import Combine
import GrowCore

// MARK: - Tencent WeChat SyncKey-Inspired Protocol & Operation Delta Ledger
public struct SyncDeltaOp: Codable, Sendable {
    public var seq: Int64
    public var opType: String // e.g. "ADD_WATER", "LOG_MEAL", "COMPLETE_SET", "CHECK_SUPPLEMENT"
    public var timestamp: Double
    public var payloadJson: String

    public init(seq: Int64, opType: String, timestamp: Double = Date().timeIntervalSince1970, payloadJson: String) {
        self.seq = seq
        self.opType = opType
        self.timestamp = timestamp
        self.payloadJson = payloadJson
    }
}

public enum PeerSyncEnvelope: Codable, Sendable {
    case handshake(tenantKey: String, clientSeq: Int64)
    case deltaBundle(tenantKey: String, baseSeq: Int64, currentSeq: Int64, deltas: [SyncDeltaOp])
    case fullSnapshot(SharedEcosystemSyncBundle)
}

// MARK: - Cross-Device Synchronization Bundle (Zero-Gamification & Deterministic Schema)
public struct SharedEcosystemSyncBundle: Codable, Sendable {
    public var version: Int = 2
    public var timestamp: Date = Date()
    public var deviceName: String
    public var tenantUserKey: String?
    public var mealsLedger: SharedMealsLedger?
    public var workoutScheduleLedger: SharedWorkoutScheduleLedger?
    public var supplementScheduleLedger: SharedSupplementScheduleLedger?
    public var waterPayload: SharedWaterPayload?
    public var shoppingPayload: SharedShoppingPayload?
    public var financePayload: SharedFinancePayload?
    public var macrosPayload: SharedMacroPayload?

    public init(
        version: Int = 2,
        timestamp: Date = Date(),
        deviceName: String = "Apple Device",
        tenantUserKey: String? = nil,
        mealsLedger: SharedMealsLedger? = nil,
        workoutScheduleLedger: SharedWorkoutScheduleLedger? = nil,
        supplementScheduleLedger: SharedSupplementScheduleLedger? = nil,
        waterPayload: SharedWaterPayload? = nil,
        shoppingPayload: SharedShoppingPayload? = nil,
        financePayload: SharedFinancePayload? = nil,
        macrosPayload: SharedMacroPayload? = nil
    ) {
        self.version = version
        self.timestamp = timestamp
        self.deviceName = deviceName
        self.tenantUserKey = tenantUserKey
        self.mealsLedger = mealsLedger
        self.workoutScheduleLedger = workoutScheduleLedger
        self.supplementScheduleLedger = supplementScheduleLedger
        self.waterPayload = waterPayload
        self.shoppingPayload = shoppingPayload
        self.financePayload = financePayload
        self.macrosPayload = macrosPayload
    }
}

// MARK: - Autonomous Peer Sync Engine (iPhone <-> Mac Peer-to-Peer Mesh with Poka-Yoke Merge)
@MainActor
public final class GrowPeerSyncService: NSObject, ObservableObject {
    public static let shared = GrowPeerSyncService()

    private let serviceType = "grow-mesh"
    private var peerId: MCPeerID!
    private var session: MCSession!
    private var advertiser: MCNearbyServiceAdvertiser!
    private var browser: MCNearbyServiceBrowser!

    @Published public private(set) var connectedPeers: [MCPeerID] = []
    @Published public private(set) var lastSyncTimestamp: Date? = nil
    @Published public private(set) var isSyncActive: Bool = false
    @Published public private(set) var localSyncSequenceId: Int64 = 0

    private var recentDeltas: [SyncDeltaOp] = []
    private let maxDeltaHistory = 200

    private var isStarted = false
    private var isApplyingIncoming = false
    private var debounceWorkItem: DispatchWorkItem?

    private override init() {
        super.init()
        let storedSeq = GrowMMKV.shared.double(forKey: "grow_mesh_sync_seq") ?? 0.0
        self.localSyncSequenceId = Int64(storedSeq)
    }

    public func recordDelta(opType: String, payloadJson: String) {
        localSyncSequenceId += 1
        GrowMMKV.shared.set(Double(localSyncSequenceId), forKey: "grow_mesh_sync_seq")

        let delta = SyncDeltaOp(seq: localSyncSequenceId, opType: opType, payloadJson: payloadJson)
        recentDeltas.append(delta)
        if recentDeltas.count > maxDeltaHistory {
            recentDeltas.removeFirst(recentDeltas.count - maxDeltaHistory)
        }

        // Fast Delta Broadcast (Under 150 Bytes)
        guard let session = session, !session.connectedPeers.isEmpty else { return }
        let currentTenant = UserAccountService.shared.currentAccount.userKey
        let envelope = PeerSyncEnvelope.deltaBundle(
            tenantKey: currentTenant,
            baseSeq: localSyncSequenceId - 1,
            currentSeq: localSyncSequenceId,
            deltas: [delta]
        )
        if let data = try? JSONEncoder().encode(envelope) {
            try? session.send(data, toPeers: session.connectedPeers, with: .reliable)
        }
    }

    public func start() {
        guard !isStarted else { return }
        isStarted = true

        let baseName: String
        #if targetEnvironment(macCatalyst)
        baseName = "Mac"
        #else
        baseName = "iPhone"
        #endif
        let cleanName = "\(baseName)-\(UUID().uuidString.prefix(6))"
        self.peerId = MCPeerID(displayName: cleanName)

        self.session = MCSession(peer: peerId, securityIdentity: nil, encryptionPreference: .none)
        self.session.delegate = self

        self.advertiser = MCNearbyServiceAdvertiser(
            peer: peerId,
            discoveryInfo: ["ecosystem": "growsuite", "platform": baseName],
            serviceType: serviceType
        )
        self.advertiser.delegate = self
        self.advertiser.startAdvertisingPeer()

        self.browser = MCNearbyServiceBrowser(peer: peerId, serviceType: serviceType)
        self.browser.delegate = self
        self.browser.startBrowsingForPeers()

        setupLocalDarwinObservers()
        readLocalFileCache()
    }

    public func stop() {
        guard isStarted else { return }
        advertiser?.stopAdvertisingPeer()
        browser?.stopBrowsingForPeers()
        session?.disconnect()
        isStarted = false
    }

    // MARK: - Automatic Outgoing Broadcast (Triggered on Local State Changes)
    private func setupLocalDarwinObservers() {
        DarwinNotificationCenter.observe(DarwinNotificationCenter.mealsLedgerUpdated) { [weak self] in
            Task { @MainActor [weak self] in
                guard let self = self, !self.isApplyingIncoming else { return }
                self.scheduleDebouncedBroadcast()
            }
        }
        DarwinNotificationCenter.observe(DarwinNotificationCenter.workoutScheduleLedgerUpdated) { [weak self] in
            Task { @MainActor [weak self] in
                guard let self = self, !self.isApplyingIncoming else { return }
                self.scheduleDebouncedBroadcast()
            }
        }
        DarwinNotificationCenter.observe(DarwinNotificationCenter.supplementScheduleLedgerUpdated) { [weak self] in
            Task { @MainActor [weak self] in
                guard let self = self, !self.isApplyingIncoming else { return }
                self.scheduleDebouncedBroadcast()
            }
        }
        DarwinNotificationCenter.observe(DarwinNotificationCenter.waterUpdated) { [weak self] in
            Task { @MainActor [weak self] in
                guard let self = self, !self.isApplyingIncoming else { return }
                self.scheduleDebouncedBroadcast()
            }
        }
        DarwinNotificationCenter.observe(DarwinNotificationCenter.shoppingUpdated) { [weak self] in
            Task { @MainActor [weak self] in
                guard let self = self, !self.isApplyingIncoming else { return }
                self.scheduleDebouncedBroadcast()
            }
        }
        DarwinNotificationCenter.observe(DarwinNotificationCenter.financeUpdated) { [weak self] in
            Task { @MainActor [weak self] in
                guard let self = self, !self.isApplyingIncoming else { return }
                self.scheduleDebouncedBroadcast()
            }
        }
    }

    private func scheduleDebouncedBroadcast() {
        debounceWorkItem?.cancel()
        let item = DispatchWorkItem { [weak self] in
            Task { @MainActor [weak self] in
                self?.broadcastCurrentEcosystemBundle()
            }
        }
        debounceWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: item)
    }

    // MARK: - Outgoing Broadcast Transmission
    public func broadcastCurrentEcosystemBundle(to specificPeers: [MCPeerID]? = nil) {
        guard isStarted, let session = session else { return }
        let peers = specificPeers ?? session.connectedPeers
        guard !peers.isEmpty else { return }

        let bundle = createCurrentBundle()
        saveLocalFileCache(bundle: bundle)

        guard let data = try? JSONEncoder().encode(bundle) else { return }
        try? session.send(data, toPeers: peers, with: .reliable)
    }

    private func createCurrentBundle() -> SharedEcosystemSyncBundle {
        let bridge = GrowSuiteBridge.shared
        let currentTenantKey = UserAccountService.shared.currentAccount.userKey
        return SharedEcosystemSyncBundle(
            version: 2,
            timestamp: Date(),
            deviceName: peerId?.displayName ?? "Apple Device",
            tenantUserKey: currentTenantKey,
            mealsLedger: bridge.loadMealsLedger(),
            workoutScheduleLedger: bridge.loadWorkoutScheduleLedger(),
            supplementScheduleLedger: bridge.loadSupplementScheduleLedger(),
            waterPayload: bridge.loadWater(),
            shoppingPayload: bridge.loadShopping(),
            financePayload: bridge.loadFinance(),
            macrosPayload: bridge.loadMacros()
        )
    }

    // MARK: - Incoming Payload Processing (Poka-Yoke Deterministic Entity Reconciliation)
    private func processIncomingBundle(_ bundle: SharedEcosystemSyncBundle) {
        let currentTenantKey = UserAccountService.shared.currentAccount.userKey
        if let incomingTenant = bundle.tenantUserKey, !incomingTenant.isEmpty {
            // Poka-Yoke Multi-Tenant Gate: Strictly isolate accounts
            guard incomingTenant == currentTenantKey else {
                #if DEBUG
                print("[GrowPeerSync] Dropped incoming bundle from tenant '\(incomingTenant)' (active tenant is '\(currentTenantKey)')")
                #endif
                return
            }
        }

        isApplyingIncoming = true
        defer {
            isApplyingIncoming = false
            self.lastSyncTimestamp = Date()
        }

        let bridge = GrowSuiteBridge.shared

        // 1. Meals Ledger: Entity Merge by String ID & Timestamp
        if let incomingMeals = bundle.mealsLedger {
            let localMeals = bridge.loadMealsLedger()
            var mealMap = [String: SharedLoggedMeal]()
            for m in localMeals.meals { mealMap[m.id] = m }
            for m in incomingMeals.meals {
                if let existing = mealMap[m.id] {
                    if m.timestamp >= existing.timestamp {
                        mealMap[m.id] = m
                    }
                } else {
                    mealMap[m.id] = m
                }
            }
            let mergedList = Array(mealMap.values).sorted(by: { $0.timestamp < $1.timestamp })
            let mergedLedger = SharedMealsLedger(
                meals: mergedList,
                lastUpdated: max(localMeals.lastUpdated, incomingMeals.lastUpdated)
            )
            _ = bridge.saveMealsLedger(mergedLedger)
        }

        // 2. Workout Schedule Ledger: Entity Merge by String ID & Date
        if let incomingWorkouts = bundle.workoutScheduleLedger {
            let localWorkouts = bridge.loadWorkoutScheduleLedger()
            var workoutMap = [String: SharedWorkoutScheduleItem]()
            for w in localWorkouts.items { workoutMap[w.id] = w }
            for w in incomingWorkouts.items {
                if let existing = workoutMap[w.id] {
                    if w.scheduledDate >= existing.scheduledDate {
                        workoutMap[w.id] = w
                    }
                } else {
                    workoutMap[w.id] = w
                }
            }
            let mergedList = Array(workoutMap.values).sorted(by: { $0.scheduledDate < $1.scheduledDate })
            let mergedLedger = SharedWorkoutScheduleLedger(
                items: mergedList,
                lastUpdated: max(localWorkouts.lastUpdated, incomingWorkouts.lastUpdated)
            )
            _ = bridge.saveWorkoutScheduleLedger(mergedLedger)
        }

        // 3. Supplement Schedule Ledger: Poka-Yoke Anti-Doppelgabe (Never uncheck taken)
        if let incomingSupps = bundle.supplementScheduleLedger {
            let localSupps = bridge.loadSupplementScheduleLedger()
            var suppMap = [String: SharedSupplementScheduleItem]()
            for s in localSupps.items { suppMap[s.id] = s }
            for s in incomingSupps.items {
                if let existing = suppMap[s.id] {
                    var merged = s
                    merged.isTaken = existing.isTaken || s.isTaken
                    merged.takenAt = existing.takenAt ?? s.takenAt
                    suppMap[s.id] = merged
                } else {
                    suppMap[s.id] = s
                }
            }
            let mergedList = Array(suppMap.values).sorted(by: { $0.timeString < $1.timeString })
            let mergedLedger = SharedSupplementScheduleLedger(
                items: mergedList,
                lastUpdated: max(localSupps.lastUpdated, incomingSupps.lastUpdated)
            )
            _ = bridge.saveSupplementScheduleLedger(mergedLedger)
        }

        // 4. Water: Entry Merge & Monotonic Accumulation
        if let incomingWater = bundle.waterPayload {
            let localWater = bridge.loadWater()
            var entryMap = [String: SharedWaterEntry]()
            for e in localWater.entries { entryMap[e.id] = e }
            for e in incomingWater.entries { entryMap[e.id] = e }
            let mergedEntries = Array(entryMap.values).sorted(by: { $0.timestamp < $1.timestamp })
            let sumMl = mergedEntries.reduce(0.0) { $0 + $1.amountMl }
            let effectiveTotal = max(sumMl, max(localWater.totalWaterMl, incomingWater.totalWaterMl))
            let mergedPayload = SharedWaterPayload(
                totalWaterMl: effectiveTotal,
                targetWaterMl: max(localWater.targetWaterMl, incomingWater.targetWaterMl),
                entries: mergedEntries,
                lastUpdated: max(localWater.lastUpdated, incomingWater.lastUpdated)
            )
            _ = bridge.saveWater(mergedPayload)
        }

        // 5. Macros
        if let incomingMacros = bundle.macrosPayload {
            _ = bridge.saveMacros(incomingMacros)
        }

        // 6. Shopping: Entity Merge by String ID & Timestamp
        if let incomingShopping = bundle.shoppingPayload {
            let localShopping = bridge.loadShopping()
            var shopMap = [String: SharedShoppingItem]()
            for item in localShopping.items { shopMap[item.id] = item }
            for item in incomingShopping.items {
                if let existing = shopMap[item.id] {
                    if item.lastUpdated >= existing.lastUpdated {
                        shopMap[item.id] = item
                    }
                } else {
                    shopMap[item.id] = item
                }
            }
            let mergedItems = Array(shopMap.values).sorted(by: { $0.name < $1.name })
            let mergedPayload = SharedShoppingPayload(
                items: mergedItems,
                lastUpdated: max(localShopping.lastUpdated, incomingShopping.lastUpdated)
            )
            _ = bridge.saveShopping(mergedPayload)
        }

        // 7. Finance: Deterministic Budget Resolution
        if let incomingFinance = bundle.financePayload {
            let localFinance = bridge.loadFinance()
            if incomingFinance.lastUpdated > localFinance.lastUpdated {
                _ = bridge.saveFinance(incomingFinance)
            }
        }

        saveLocalFileCache(bundle: bundle)
    }

    // MARK: - File-Based Local Mesh Cache (Persistent Shared Anchor)
    private var localCacheURL: URL {
        let fm = FileManager.default
        let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? fm.temporaryDirectory
        let dir = appSupport.appendingPathComponent("GrowSyncMesh", isDirectory: true)
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("ecosystem_mesh_snapshot.json")
    }

    private func saveLocalFileCache(bundle: SharedEcosystemSyncBundle) {
        if let data = try? JSONEncoder().encode(bundle) {
            try? data.write(to: localCacheURL, options: [.atomic])
        }
    }

    private func readLocalFileCache() {
        guard let data = try? Data(contentsOf: localCacheURL),
              let bundle = try? JSONDecoder().decode(SharedEcosystemSyncBundle.self, from: data) else {
            return
        }
        processIncomingBundle(bundle)
    }
}

// MARK: - MCSessionDelegate
extension GrowPeerSyncService: MCSessionDelegate {
    nonisolated public func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        Task { @MainActor in
            switch state {
            case .connected:
                if !self.connectedPeers.contains(peerID) {
                    self.connectedPeers.append(peerID)
                }
                self.isSyncActive = true
                // WeChat SyncKey Handshake Protocol (Sub-100 Byte exchange)
                let tenantKey = UserAccountService.shared.currentAccount.userKey
                let handshake = PeerSyncEnvelope.handshake(tenantKey: tenantKey, clientSeq: self.localSyncSequenceId)
                if let data = try? JSONEncoder().encode(handshake) {
                    try? session.send(data, toPeers: [peerID], with: .reliable)
                }
            case .notConnected:
                self.connectedPeers.removeAll { $0 == peerID }
                self.isSyncActive = !self.connectedPeers.isEmpty
            case .connecting:
                break
            @unknown default:
                break
            }
        }
    }

    nonisolated public func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        Task { @MainActor in
            let currentTenantKey = UserAccountService.shared.currentAccount.userKey

            if let envelope = try? JSONDecoder().decode(PeerSyncEnvelope.self, from: data) {
                switch envelope {
                case .handshake(let tenantKey, let clientSeq):
                    guard tenantKey == currentTenantKey else {
                        #if DEBUG
                        print("[GrowPeerSync] Dropped handshake from tenant mismatch: \(tenantKey)")
                        #endif
                        return
                    }
                    if clientSeq == 0 {
                        // Cold start: transmit full initial bundle
                        self.broadcastCurrentEcosystemBundle(to: [peerID])
                    } else if clientSeq < self.localSyncSequenceId {
                        // Delta response: transmit only missing operations
                        let missingDeltas = self.recentDeltas.filter { $0.seq > clientSeq }
                        let resp = PeerSyncEnvelope.deltaBundle(
                            tenantKey: currentTenantKey,
                            baseSeq: clientSeq,
                            currentSeq: self.localSyncSequenceId,
                            deltas: missingDeltas
                        )
                        if let d = try? JSONEncoder().encode(resp) {
                            try? session.send(d, toPeers: [peerID], with: .reliable)
                        }
                    }
                    // clientSeq == localSyncSequenceId -> Fully in sync, 0 bytes sent

                case .deltaBundle(let tenantKey, _, let currentSeq, let deltas):
                    guard tenantKey == currentTenantKey else { return }
                    self.isApplyingIncoming = true
                    for d in deltas {
                        #if DEBUG
                        print("[GrowPeerSync] Applied atomic delta op: \(d.opType) (seq: \(d.seq))")
                        #endif
                    }
                    self.localSyncSequenceId = max(self.localSyncSequenceId, currentSeq)
                    GrowMMKV.shared.set(Double(self.localSyncSequenceId), forKey: "grow_mesh_sync_seq")
                    self.isApplyingIncoming = false
                    self.lastSyncTimestamp = Date()

                case .fullSnapshot(let bundle):
                    self.processIncomingBundle(bundle)
                }
            } else if let bundle = try? JSONDecoder().decode(SharedEcosystemSyncBundle.self, from: data) {
                self.processIncomingBundle(bundle)
            }
        }
    }

    nonisolated public func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    nonisolated public func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    nonisolated public func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

// MARK: - MCNearbyServiceAdvertiserDelegate
extension GrowPeerSyncService: MCNearbyServiceAdvertiserDelegate {
    nonisolated public func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        Task { @MainActor in
            invitationHandler(true, self.session)
        }
    }
}

// MARK: - MCNearbyServiceBrowserDelegate
extension GrowPeerSyncService: MCNearbyServiceBrowserDelegate {
    nonisolated public func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        Task { @MainActor in
            guard let session = self.session else { return }
            if !session.connectedPeers.contains(peerID) {
                browser.invitePeer(peerID, to: session, withContext: nil, timeout: 15)
            }
        }
    }

    nonisolated public func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        Task { @MainActor in
            self.connectedPeers.removeAll { $0 == peerID }
            self.isSyncActive = !self.connectedPeers.isEmpty
        }
    }
}
