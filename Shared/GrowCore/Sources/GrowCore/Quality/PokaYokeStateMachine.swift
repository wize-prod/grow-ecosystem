import Foundation

// MARK: - Japanese Poka-Yoke Tagged-Union State Machines (Algebraic Data Types)

/// Poka-Yoke Supplement Lifecycle:
/// Enforces terminal irreversibility of ingested doses to eliminate accidental double-intake.
public enum DoseLifecycle: Codable, Equatable, Sendable {
    case scheduled(timeString: String)
    case sealedTaken(takenAt: Date, sourceNode: String)

    public var isTaken: Bool {
        switch self {
        case .scheduled: return false
        case .sealedTaken: return true
        }
    }

    /// Pure Poka-Yoke State Transition Function:
    /// Rejects transitions from sealedTaken back to scheduled.
    public func transition(to next: DoseLifecycle) -> DoseLifecycle {
        switch (self, next) {
        case (.sealedTaken, .scheduled):
            // Poka-Yoke: Impossible to un-take an ingested dose via out-of-order sync
            return self
        case (.scheduled, .sealedTaken(let at, let node)):
            return .sealedTaken(takenAt: at, sourceNode: node)
        default:
            return next
        }
    }
}

/// Poka-Yoke 5-Gate Finance Discipline Lifecycle:
/// Enforces formal gate checks before liquidity is released.
public enum ExpenseGateLifecycle: Codable, Equatable, Sendable {
    case pendingAudit(amountEur: Double)
    case quarantined72h(releaseDate: Date, amountEur: Double)
    case blockedByGate(gateNumber: Int, violationReason: String)
    case fullyApproved(approvalDate: Date, safeBalanceRemaining: Double)

    public var isApproved: Bool {
        if case .fullyApproved = self { return true }
        return false
    }

    public var isBlocked: Bool {
        if case .blockedByGate = self { return true }
        return false
    }
}

/// Poka-Yoke Academic & Task Milestone Lifecycle:
/// Prevents uncertified completion or accidental regressions.
public enum StudyTaskLifecycle: Codable, Equatable, Sendable {
    case backlog
    case scheduled(targetDate: Date)
    case inFocusSession(startedAt: Date)
    case certifiedComplete(completedAt: Date, sessionMinutes: Int)

    public var isCompleted: Bool {
        if case .certifiedComplete = self { return true }
        return false
    }

    public func markCompleted(minutes: Int = 25) -> StudyTaskLifecycle {
        return .certifiedComplete(completedAt: Date(), sessionMinutes: minutes)
    }
}
