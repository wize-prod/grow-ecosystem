import Foundation

// MARK: - Poka-Yoke Deterministic Entity Reconciler (TPS Muda-Free Reconciliation)
public enum PokaYokeReconciler {

    /// Reconciles two collections of identifiable entities using Last-Write-Wins based on entity timestamps.
    /// Eliminates split-brain divergence and ensures mathematical convergence between nodes.
    public static func reconcileEntities<T: Identifiable>(
        local: [T],
        incoming: [T],
        timestamp: (T) -> Date
    ) -> [T] where T.ID: Hashable {
        var map = [T.ID: T]()
        for item in local {
            map[item.id] = item
        }
        for item in incoming {
            if let existing = map[item.id] {
                if timestamp(item) >= timestamp(existing) {
                    map[item.id] = item
                }
            } else {
                map[item.id] = item
            }
        }
        return Array(map.values)
    }

    /// Poka-Yoke Hydration Reconciler:
    /// Enforces monotonic accumulation for the same calendar date to prevent accidental erasure of logged fluid intake.
    public static func reconcileHydration(localMl: Double, incomingMl: Double) -> Double {
        return max(localMl, incomingMl)
    }

    /// Poka-Yoke Supplement Protection:
    /// A supplement dose marked as taken on ANY device remains taken to prevent dangerous accidental double-dosing.
    public struct ReconcilableDose: Identifiable {
        public let id: String
        public let scheduledTime: String
        public let isTaken: Bool
        public let timestamp: Date

        public init(id: String, scheduledTime: String, isTaken: Bool, timestamp: Date = Date()) {
            self.id = id
            self.scheduledTime = scheduledTime
            self.isTaken = isTaken
            self.timestamp = timestamp
        }
    }

    public static func reconcileDoses(_ local: [ReconcilableDose], _ incoming: [ReconcilableDose]) -> [ReconcilableDose] {
        var map = [String: ReconcilableDose]()
        for dose in local {
            map[dose.id] = dose
        }
        for dose in incoming {
            if let existing = map[dose.id] {
                // If either node marked it taken, taken status is permanently preserved
                let taken = existing.isTaken || dose.isTaken
                let latestTs = max(existing.timestamp, dose.timestamp)
                map[dose.id] = ReconcilableDose(id: dose.id, scheduledTime: dose.scheduledTime, isTaken: taken, timestamp: latestTs)
            } else {
                map[dose.id] = dose
            }
        }
        return Array(map.values).sorted(by: { $0.scheduledTime < $1.scheduledTime })
    }
}
