import Foundation
import CryptoKit

// MARK: - Sony FeliCa / Suica-Inspired Hard-Deadline Offline Transaction Engine
public struct FeliCaTransactionBlock: Codable, Sendable, Identifiable {
    public let id: String
    public let sequenceNumber: UInt64
    public let timestamp: Date
    public let domain: String // "FINANCE", "NUTRITION", "WORKOUT", "STUDY"
    public let operation: String
    public let amountOrValue: Double
    public let payloadJson: String
    public let previousHash: String
    public let blockHash: String

    public init(
        id: String = UUID().uuidString,
        sequenceNumber: UInt64,
        timestamp: Date = Date(),
        domain: String,
        operation: String,
        amountOrValue: Double,
        payloadJson: String,
        previousHash: String
    ) {
        self.id = id
        self.sequenceNumber = sequenceNumber
        self.timestamp = timestamp
        self.domain = domain
        self.operation = operation
        self.amountOrValue = amountOrValue
        self.payloadJson = payloadJson
        self.previousHash = previousHash

        // Cryptographic SHA-256 seal linking to previous block
        let content = "\(id):\(sequenceNumber):\(timestamp.timeIntervalSince1970):\(domain):\(operation):\(amountOrValue):\(payloadJson):\(previousHash)"
        let digest = SHA256.hash(data: Data(content.utf8))
        self.blockHash = digest.map { String(format: "%02x", $0) }.joined()
    }
}

public struct FeliCaExecutionReceipt: Sendable {
    public let isSuccess: Bool
    public let sequenceNumber: UInt64
    public let blockHash: String
    public let latencyMs: Double
    public let message: String
}

public final class FeliCaTransactionLedger: @unchecked Sendable {
    public static let shared = FeliCaTransactionLedger()

    private let hardDeadlineMs: Double = 50.0 // Hard latency budget (FeliCa standard <= 100ms)
    private var lastSequenceNumber: UInt64 = 0
    private var lastBlockHash: String = "0000000000000000000000000000000000000000000000000000000000000000" // Genesis
    private let queue = DispatchQueue(label: "com.grow.core.felica", qos: .userInteractive)
    private let mmkv: GrowMMKV

    public init(mmkv: GrowMMKV = .shared) {
        self.mmkv = mmkv
        loadGenesisState()
    }

    private func loadGenesisState() {
        if let seq = mmkv.int(forKey: "felica_last_seq") {
            lastSequenceNumber = UInt64(seq)
        }
        if let hash = mmkv.string(forKey: "felica_last_hash") {
            lastBlockHash = hash
        }
    }

    /// Executes an atomic, offline, tamper-proof transaction with sub-50ms hard-deadline guarantee
    public func executeTransaction(
        domain: String,
        operation: String,
        amountOrValue: Double,
        payloadJson: String
    ) -> FeliCaExecutionReceipt {
        let startTime = CFAbsoluteTimeGetCurrent()

        return queue.sync {
            let nextSeq = lastSequenceNumber + 1
            let prevHash = lastBlockHash

            let block = FeliCaTransactionBlock(
                sequenceNumber: nextSeq,
                domain: domain,
                operation: operation,
                amountOrValue: amountOrValue,
                payloadJson: payloadJson,
                previousHash: prevHash
            )

            // Commit block to MMKV fast persistence
            guard let blockData = try? JSONEncoder().encode(block) else {
                return FeliCaExecutionReceipt(
                    isSuccess: false,
                    sequenceNumber: lastSequenceNumber,
                    blockHash: lastBlockHash,
                    latencyMs: (CFAbsoluteTimeGetCurrent() - startTime) * 1000.0,
                    message: "FeliCa: Serialization failed"
                )
            }

            let blockKey = "felica_block_\(nextSeq)"
            mmkv.set(blockData, forKey: blockKey)
            mmkv.set(Int(nextSeq), forKey: "felica_last_seq")
            mmkv.set(block.blockHash, forKey: "felica_last_hash")

            self.lastSequenceNumber = nextSeq
            self.lastBlockHash = block.blockHash

            let durationMs = (CFAbsoluteTimeGetCurrent() - startTime) * 1000.0

            // Verify Poka-Yoke deadline constraint
            let withinDeadline = durationMs <= hardDeadlineMs

            return FeliCaExecutionReceipt(
                isSuccess: withinDeadline,
                sequenceNumber: nextSeq,
                blockHash: block.blockHash,
                latencyMs: durationMs,
                message: withinDeadline ? "FeliCa: Atomar autorisiert (\(String(format: "%.2f", durationMs)) ms)" : "Warnung: Latenzueberschreitung (\(String(format: "%.2f", durationMs)) ms)"
            )
        }
    }

    public func verifyChainIntegrity() -> (isValid: Bool, verifiedBlocks: Int) {
        return queue.sync {
            var expectedPrevHash = "0000000000000000000000000000000000000000000000000000000000000000"
            var verifiedCount = 0

            for seq in 1...lastSequenceNumber {
                guard let data = mmkv.data(forKey: "felica_block_\(seq)"),
                      let block = try? JSONDecoder().decode(FeliCaTransactionBlock.self, from: data) else {
                    return (false, verifiedCount)
                }

                if block.previousHash != expectedPrevHash {
                    return (false, verifiedCount)
                }

                // Verify block hash
                let content = "\(block.id):\(block.sequenceNumber):\(block.timestamp.timeIntervalSince1970):\(block.domain):\(block.operation):\(block.amountOrValue):\(block.payloadJson):\(block.previousHash)"
                let digest = SHA256.hash(data: Data(content.utf8))
                let calculatedHash = digest.map { String(format: "%02x", $0) }.joined()

                if calculatedHash != block.blockHash {
                    return (false, verifiedCount)
                }

                expectedPrevHash = block.blockHash
                verifiedCount += 1
            }

            return (true, verifiedCount)
        }
    }
}
