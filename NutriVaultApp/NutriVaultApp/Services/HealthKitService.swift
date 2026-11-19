import Foundation
import HealthKit
import Combine

@MainActor
public final class HealthKitService: ObservableObject {
    public static let shared = HealthKitService()

    @Published public var isAvailable: Bool = false
    @Published public var isAuthorized: Bool = false
    @Published public var isSyncing: Bool = false
    @Published public var lastSyncTimestamp: Date?

    // Biometrie & Körperzusammensetzung
    @Published public var bodyWeightKg: Double = 78.5
    @Published public var bodyFatPercentage: Double = 13.8
    @Published public var lastWeightDate: Date?

    // Aktivität & Bewegung
    @Published public var activeEnergyBurned: Double = 0.0
    @Published public var stepCount: Int = 0
    @Published public var exerciseTimeMinutes: Int = 0

    // Kardiologie & Vitalparameter
    @Published public var restingHeartRate: Int = 38
    @Published public var latestHeartRate: Int = 54
    @Published public var bloodGlucoseMgDl: Double = 92.0
    @Published public var oxygenSaturationPct: Double = 98.0

    // 2-Wege Ernährungs- und Flüssigkeitssynchronisation
    @Published public var waterIntakeMl: Double = 0.0
    @Published public var syncedTodayProtein: Double = 0.0
    @Published public var syncedTodayCarbs: Double = 0.0
    @Published public var syncedTodayFat: Double = 0.0
    @Published public var syncedTodayCalories: Double = 0.0

    private let healthStore = HKHealthStore()

    private init() {
        // HealthKit entitlement is currently on hold. Prevent invalid HK requests.
        self.isAvailable = false
        self.isAuthorized = false
    }

    // MARK: - Autorisierung (Read & Write)
    public func checkAndRequestAuthorization() {
        // No-op while entitlement is on hold
        self.isAvailable = false
        self.isAuthorized = false
    }

    // MARK: - Datenabruf (Read)
    public func fetchTodayHealthData() {
        guard isAvailable && isAuthorized else { return }
        isSyncing = true

        let bridgeWater = GrowSuiteBridge.shared.loadWater()
        let group = DispatchGroup()

        var newBurn = self.activeEnergyBurned
        var newSteps = self.stepCount
        var newExercise = self.exerciseTimeMinutes
        var newWater = bridgeWater.totalWaterMl
        var newProtein = self.syncedTodayProtein
        var newCarbs = self.syncedTodayCarbs
        var newFat = self.syncedTodayFat
        var newCalories = self.syncedTodayCalories
        var newWeight = self.bodyWeightKg
        var newWeightDate = self.lastWeightDate
        var newFatPct = self.bodyFatPercentage
        var newRestingHR = self.restingHeartRate
        var newHeartRate = self.latestHeartRate
        var newGlucose = self.bloodGlucoseMgDl
        var newOxygen = self.oxygenSaturationPct

        group.enter()
        fetchCumulative(typeIdentifier: .activeEnergyBurned, unit: .kilocalorie()) { val in
            newBurn = val
            group.leave()
        }
        group.enter()
        fetchCumulative(typeIdentifier: .stepCount, unit: .count()) { val in
            newSteps = Int(val)
            group.leave()
        }
        group.enter()
        fetchCumulative(typeIdentifier: .appleExerciseTime, unit: .minute()) { val in
            newExercise = Int(val)
            group.leave()
        }
        group.enter()
        fetchCumulative(typeIdentifier: .dietaryWater, unit: .literUnit(with: .milli)) { val in
            let currentBridge = GrowSuiteBridge.shared.loadWater()
            newWater = max(val, currentBridge.totalWaterMl)
            group.leave()
        }
        group.enter()
        fetchCumulative(typeIdentifier: .dietaryProtein, unit: .gram()) { val in
            newProtein = val
            group.leave()
        }
        group.enter()
        fetchCumulative(typeIdentifier: .dietaryCarbohydrates, unit: .gram()) { val in
            newCarbs = val
            group.leave()
        }
        group.enter()
        fetchCumulative(typeIdentifier: .dietaryFatTotal, unit: .gram()) { val in
            newFat = val
            group.leave()
        }
        group.enter()
        fetchCumulative(typeIdentifier: .dietaryEnergyConsumed, unit: .kilocalorie()) { val in
            newCalories = val
            group.leave()
        }
        group.enter()
        fetchMostRecent(typeIdentifier: .bodyMass, unit: .gramUnit(with: .kilo)) { val, date in
            if let v = val, v > 0 {
                newWeight = v
                newWeightDate = date
            }
            group.leave()
        }
        group.enter()
        fetchMostRecent(typeIdentifier: .bodyFatPercentage, unit: .percent()) { val, _ in
            if let v = val, v > 0 {
                newFatPct = v * 100.0
            }
            group.leave()
        }
        group.enter()
        fetchMostRecent(typeIdentifier: .restingHeartRate, unit: HKUnit(from: "count/min")) { val, _ in
            if let v = val, v > 0 {
                newRestingHR = Int(v)
            }
            group.leave()
        }
        group.enter()
        fetchMostRecent(typeIdentifier: .heartRate, unit: HKUnit(from: "count/min")) { val, _ in
            if let v = val, v > 0 {
                newHeartRate = Int(v)
            }
            group.leave()
        }
        group.enter()
        fetchMostRecent(typeIdentifier: .bloodGlucose, unit: HKUnit(from: "mg/dL")) { val, _ in
            if let v = val, v > 0 {
                newGlucose = v
            }
            group.leave()
        }
        group.enter()
        fetchMostRecent(typeIdentifier: .oxygenSaturation, unit: .percent()) { val, _ in
            if let v = val, v > 0 {
                newOxygen = v * 100.0
            }
            group.leave()
        }

        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            self.activeEnergyBurned = newBurn
            self.stepCount = newSteps
            self.exerciseTimeMinutes = newExercise
            self.waterIntakeMl = newWater
            self.syncedTodayProtein = newProtein
            self.syncedTodayCarbs = newCarbs
            self.syncedTodayFat = newFat
            self.syncedTodayCalories = newCalories
            self.bodyWeightKg = newWeight
            self.lastWeightDate = newWeightDate
            self.bodyFatPercentage = newFatPct
            self.restingHeartRate = newRestingHR
            self.latestHeartRate = newHeartRate
            self.bloodGlucoseMgDl = newGlucose
            self.oxygenSaturationPct = newOxygen
            self.isSyncing = false
            self.lastSyncTimestamp = Date()
        }
    }

    private func fetchCumulative(typeIdentifier: HKQuantityTypeIdentifier, unit: HKUnit, completion: @escaping (Double) -> Void) {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: typeIdentifier) else { return }

        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        let query = HKStatisticsQuery(quantityType: quantityType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, statistics, _ in
            let value = statistics?.sumQuantity()?.doubleValue(for: unit) ?? 0.0
            Task { @MainActor in
                completion(value)
            }
        }
        healthStore.execute(query)
    }

    private func fetchMostRecent(typeIdentifier: HKQuantityTypeIdentifier, unit: HKUnit, completion: @escaping (Double?, Date?) -> Void) {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: typeIdentifier) else { return }

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: quantityType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, results, _ in
            guard let sample = results?.first as? HKQuantitySample else {
                Task { @MainActor in
                    completion(nil, nil)
                }
                return
            }
            let value = sample.quantity.doubleValue(for: unit)
            let date = sample.startDate
            Task { @MainActor in
                completion(value, date)
            }
        }
        healthStore.execute(query)
    }

    // MARK: - 2-Wege Synchronisation (Write nach Apple Health / Google Health)
    public func writeMealNutrients(protein: Double, carbs: Double, fat: Double, calories: Double, date: Date = Date()) {
        guard isAvailable && isAuthorized else { return }

        var samplesToSave = [HKQuantitySample]()

        if protein > 0, let pType = HKQuantityType.quantityType(forIdentifier: .dietaryProtein) {
            let q = HKQuantity(unit: .gram(), doubleValue: protein)
            samplesToSave.append(HKQuantitySample(type: pType, quantity: q, start: date, end: date))
        }
        if carbs > 0, let cType = HKQuantityType.quantityType(forIdentifier: .dietaryCarbohydrates) {
            let q = HKQuantity(unit: .gram(), doubleValue: carbs)
            samplesToSave.append(HKQuantitySample(type: cType, quantity: q, start: date, end: date))
        }
        if fat > 0, let fType = HKQuantityType.quantityType(forIdentifier: .dietaryFatTotal) {
            let q = HKQuantity(unit: .gram(), doubleValue: fat)
            samplesToSave.append(HKQuantitySample(type: fType, quantity: q, start: date, end: date))
        }
        if calories > 0, let eType = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed) {
            let q = HKQuantity(unit: .kilocalorie(), doubleValue: calories)
            samplesToSave.append(HKQuantitySample(type: eType, quantity: q, start: date, end: date))
        }

        guard !samplesToSave.isEmpty else { return }

        healthStore.save(samplesToSave) { [weak self] success, _ in
            if success {
                Task { @MainActor in
                    self?.syncedTodayProtein += protein
                    self?.syncedTodayCarbs += carbs
                    self?.syncedTodayFat += fat
                    self?.syncedTodayCalories += calories
                    self?.lastSyncTimestamp = Date()
                }
            }
        }
    }

    public func logWaterIntake(amountMl: Double, date: Date = Date()) {
        waterIntakeMl += amountMl
        GrowSuiteBridge.shared.logWater(amountMl: amountMl, date: date, sourceApp: "Growcery")

        guard isAvailable && isAuthorized, amountMl > 0, let waterType = HKQuantityType.quantityType(forIdentifier: .dietaryWater) else {
            return
        }

        let quantity = HKQuantity(unit: .literUnit(with: .milli), doubleValue: amountMl)
        let sample = HKQuantitySample(type: waterType, quantity: quantity, start: date, end: date)

        healthStore.save(sample) { [weak self] success, _ in
            Task { @MainActor in
                if success {
                    self?.lastSyncTimestamp = Date()
                }
            }
        }
    }

    public func resetWaterIntake() {
        waterIntakeMl = 0.0
        GrowSuiteBridge.shared.setTotalWater(totalMl: 0.0, sourceApp: "Growcery")
    }
}
