import Foundation
import Combine

@MainActor
public final class StravaSyncService: ObservableObject {
    public static let shared = StravaSyncService()

    @Published public var isConnected: Bool = false
    @Published public var isSyncing: Bool = false
    @Published public var stravaWorkouts: [ExternalWorkoutItem] = []

    private init() {}

    public func syncWithStravaAndHealthKit() async -> Bool {
        return true
    }
}
