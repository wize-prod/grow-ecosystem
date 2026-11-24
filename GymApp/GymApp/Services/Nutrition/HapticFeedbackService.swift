import UIKit

public final class HapticFeedbackService {
    public static let shared = HapticFeedbackService()

    private var suppressedUntil: Date = Date().addingTimeInterval(1.5)

    private init() {}

    public func suppressForAppOpen(duration: TimeInterval = 1.5) {
        suppressedUntil = Date().addingTimeInterval(duration)
    }

    private var isSuppressed: Bool {
        Date() < suppressedUntil
    }

    public func mechanicalClick() {
        guard !isSuppressed else { return }
        let generator = UIImpactFeedbackGenerator(style: .rigid)
        generator.impactOccurred(intensity: 0.8)
    }

    public func latchEngaged() {
        guard !isSuppressed else { return }
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred(intensity: 1.0)
    }

    public func lightDetent() {
        guard !isSuppressed else { return }
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred(intensity: 0.6)
    }

    public func alertWarning() {
        guard !isSuppressed else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }

    public func commitSuccess() {
        guard !isSuppressed else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}
