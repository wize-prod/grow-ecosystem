import Foundation
import CoreFoundation

// MARK: - Zero-Muda Event-Driven IPC Bus (Darwin CFNotificationCenter Wrapper)
public enum GrowEcosystemEvent: String, CaseIterable, Sendable {
    case waterIntakeUpdated = "com.nkembi.growcore.waterUpdated"
    case macroNutritionUpdated = "com.nkembi.growcore.macrosUpdated"
    case supplementDoseSealed = "com.nkembi.growcore.suppsUpdated"
    case workoutStateUpdated = "com.nkembi.growcore.workoutUpdated"
    case financeLedgerUpdated = "com.nkembi.growcore.financeUpdated"
    case shoppingListUpdated = "com.nkembi.growcore.shoppingUpdated"
    case studyProgressUpdated = "com.nkembi.growcore.studyUpdated"
}

public final class GrowDarwinEventBus: @unchecked Sendable {
    public static let shared = GrowDarwinEventBus()

    private let center = CFNotificationCenterGetDarwinNotifyCenter()
    private var observers = [String: [() -> Void]]()
    private let lock = NSLock()

    private init() {}

    /// Posts a lightweight, zero-allocation Darwin IPC event to all listening apps
    public func post(_ event: GrowEcosystemEvent) {
        let name = CFNotificationName(event.rawValue as CFString)
        CFNotificationCenterPostNotification(center, name, nil, nil, true)
    }

    /// Registers an observer for a specific event with zero background polling overhead
    public func observe(_ event: GrowEcosystemEvent, onTrigger: @escaping () -> Void) {
        lock.lock()
        var list = observers[event.rawValue] ?? []
        list.append(onTrigger)
        observers[event.rawValue] = list
        lock.unlock()

        let observerPtr = Unmanaged.passUnretained(self).toOpaque()
        let name = CFNotificationName(event.rawValue as CFString)

        CFNotificationCenterAddObserver(
            center,
            observerPtr,
            { _, _, name, _, _ in
                guard let cfName = name?.rawValue as String? else { return }
                GrowDarwinEventBus.shared.notifyObservers(for: cfName)
            },
            name.rawValue,
            nil,
            .deliverImmediately
        )
    }

    private func notifyObservers(for eventName: String) {
        lock.lock()
        let list = observers[eventName] ?? []
        lock.unlock()

        for handler in list {
            handler()
        }
    }
}
