import Foundation
import HealthKit
import Combine

@MainActor
public final class HealthKitService: ObservableObject {
    public static let shared = HealthKitService()

    @Published public var isAvailable: Bool = false
    @Published public var isAuthorized: Bool = false
    @Published public var isSyncing: Bool = false
    @Published public var lastSyncTimestamp: Date? = nil
    @Published public var statusMessage: String = "Bereit"

    // Vitalparameter & Kardiologie
    @Published public var restingHeartRate: Int = 0
    @Published public var latestHeartRate: Int = 0
    @Published public var activeEnergyBurnedToday: Double = 0.0
    @Published public var todaySteps: Int = 0

    // Makronaehrstoffe & Hydration
    @Published public var todayProteinGrams: Double = 0.0
    @Published public var todayCaloriesConsumed: Double = 0.0
    @Published public var todayCarbsGrams: Double = 0.0
    @Published public var todayFatGrams: Double = 0.0
    @Published public var waterIntakeMl: Double = 0.0

    // Biometrie
    @Published public var bodyWeightKg: Double = 78.5
    @Published public var bodyFatPercentage: Double = 13.8
    @Published public var lastWeightDate: Date? = nil

    // Synchronisierte Workouts aus Apple Health / Google Fit
    @Published public var syncedWorkouts: [ExternalWorkoutItem] = []

    private let healthStore = HKHealthStore()

    private init() {
        // Vorab gespeicherte historische Workouts laden fuer sofortige Coach-Verfuegbarkeit (mind. 2 Minuten Dauer)
        if let data = UserDefaults.standard.data(forKey: "grow_synced_workouts"),
           let cached = try? JSONDecoder().decode([ExternalWorkoutItem].self, from: data) {
            self.syncedWorkouts = cached.filter { $0.durationSeconds >= 120.0 }
        }

        self.isAvailable = HKHealthStore.isHealthDataAvailable()
        if isAvailable {
            checkAuthorizationStatus()
        } else {
            self.statusMessage = "HealthKit auf diesem Geraet nicht verfuegbar."
        }
    }

    public func removeSyncedWorkout(id: UUID) {
        syncedWorkouts.removeAll(where: { $0.id == id })
        if let data = try? JSONEncoder().encode(syncedWorkouts) {
            UserDefaults.standard.set(data, forKey: "grow_synced_workouts")
        }
    }

    // MARK: - Autorisierungspruefung
    public func checkAuthorizationStatus() {
        guard isAvailable else { return }
        let workoutType = HKObjectType.workoutType()
        let status = healthStore.authorizationStatus(for: workoutType)
        if status == .sharingAuthorized {
            self.isAuthorized = true
        }
    }

    // MARK: - Autorisierung anfordern (Read & Write)
    public func checkAndRequestAuthorization() {
        guard isAvailable else { return }

        var readTypes = Set<HKObjectType>()
        readTypes.insert(HKObjectType.workoutType())
        if let t = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) { readTypes.insert(t) }
        if let t = HKQuantityType.quantityType(forIdentifier: .heartRate) { readTypes.insert(t) }
        if let t = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) { readTypes.insert(t) }
        if let t = HKQuantityType.quantityType(forIdentifier: .stepCount) { readTypes.insert(t) }
        if let t = HKQuantityType.quantityType(forIdentifier: .dietaryProtein) { readTypes.insert(t) }
        if let t = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed) { readTypes.insert(t) }
        if let t = HKQuantityType.quantityType(forIdentifier: .dietaryCarbohydrates) { readTypes.insert(t) }
        if let t = HKQuantityType.quantityType(forIdentifier: .dietaryFatTotal) { readTypes.insert(t) }
        if let t = HKQuantityType.quantityType(forIdentifier: .bodyMass) { readTypes.insert(t) }
        if let t = HKQuantityType.quantityType(forIdentifier: .bodyFatPercentage) { readTypes.insert(t) }
        if let t = HKQuantityType.quantityType(forIdentifier: .leanBodyMass) { readTypes.insert(t) }

        var shareTypes = Set<HKSampleType>()
        shareTypes.insert(HKObjectType.workoutType())
        if let t = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) { shareTypes.insert(t) }
        if let t = HKQuantityType.quantityType(forIdentifier: .dietaryProtein) { shareTypes.insert(t) }
        if let t = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed) { shareTypes.insert(t) }
        if let t = HKQuantityType.quantityType(forIdentifier: .dietaryCarbohydrates) { shareTypes.insert(t) }
        if let t = HKQuantityType.quantityType(forIdentifier: .dietaryFatTotal) { shareTypes.insert(t) }

        healthStore.requestAuthorization(toShare: shareTypes, read: readTypes) { [weak self] success, error in
            Task { @MainActor in
                guard let self = self else { return }
                if success {
                    self.isAuthorized = true
                    self.statusMessage = "HealthKit autorisiert."
                    self.fetchAllHealthData()
                } else {
                    self.statusMessage = "HealthKit Autorisierung fehlgeschlagen: \(error?.localizedDescription ?? "Unbekannt")"
                }
            }
        }
    }

    // MARK: - Datenabruf (Read)
    public func fetchAllHealthData() {
        guard isAvailable else { return }
        isSyncing = true
        statusMessage = "Synchronisiere mit HealthKit..."

        let group = DispatchGroup()

        // 1. Aktive Kalorien heute
        group.enter()
        fetchCumulative(typeIdentifier: .activeEnergyBurned, unit: .kilocalorie()) { [weak self] val in
            self?.activeEnergyBurnedToday = val
            group.leave()
        }

        // 2. Schritte heute
        group.enter()
        fetchCumulative(typeIdentifier: .stepCount, unit: .count()) { [weak self] val in
            self?.todaySteps = Int(val)
            group.leave()
        }

        // 3. Protein heute
        group.enter()
        fetchCumulative(typeIdentifier: .dietaryProtein, unit: .gram()) { [weak self] val in
            self?.todayProteinGrams = val
            group.leave()
        }

        // 4. Kalorienaufnahme heute
        group.enter()
        fetchCumulative(typeIdentifier: .dietaryEnergyConsumed, unit: .kilocalorie()) { [weak self] val in
            self?.todayCaloriesConsumed = val
            group.leave()
        }

        // 5. Kohlenhydrate heute
        group.enter()
        fetchCumulative(typeIdentifier: .dietaryCarbohydrates, unit: .gram()) { [weak self] val in
            self?.todayCarbsGrams = val
            group.leave()
        }

        // 6. Fett heute
        group.enter()
        fetchCumulative(typeIdentifier: .dietaryFatTotal, unit: .gram()) { [weak self] val in
            self?.todayFatGrams = val
            group.leave()
        }

        // 7. Ruhepuls
        group.enter()
        let bpmUnit = HKUnit.count().unitDivided(by: .minute())
        fetchMostRecent(typeIdentifier: .restingHeartRate, unit: bpmUnit) { [weak self] val, _ in
            if let v = val, v > 0 {
                self?.restingHeartRate = Int(v)
            }
            group.leave()
        }

        // 8. Aktueller Puls
        group.enter()
        fetchMostRecent(typeIdentifier: .heartRate, unit: bpmUnit) { [weak self] val, _ in
            if let v = val, v > 0 {
                self?.latestHeartRate = Int(v)
            }
            group.leave()
        }

        // 9. Workouts der letzten 14 Tage
        group.enter()
        fetchRecentWorkoutsInternal {
            group.leave()
        }

        // 10. Koerpergewicht (Renpho / Apple Health)
        group.enter()
        fetchMostRecent(typeIdentifier: .bodyMass, unit: .gramUnit(with: .kilo)) { [weak self] val, date in
            if let v = val, v > 30.0 {
                let roundedWeight = (v * 100.0).rounded() / 100.0
                Task { @MainActor in
                    self?.bodyWeightKg = roundedWeight
                    self?.lastWeightDate = date
                    GymStore.shared.addMeasurement(type: .weight, value: roundedWeight, date: date ?? Date(), note: "Apple Health (Renpho)")
                }
            }
            group.leave()
        }

        // 11. Koerperfettanteil (Renpho / Apple Health)
        group.enter()
        fetchMostRecent(typeIdentifier: .bodyFatPercentage, unit: .percent()) { [weak self] val, date in
            if let v = val, v > 0 {
                let pct = (v * 100.0 * 10.0).rounded() / 10.0
                Task { @MainActor in
                    self?.bodyFatPercentage = pct
                    GymStore.shared.addMeasurement(type: .bodyFat, value: pct, date: date ?? Date(), note: "Apple Health (Renpho)")
                }
            }
            group.leave()
        }

        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            self.isSyncing = false
            self.lastSyncTimestamp = Date()
            self.statusMessage = "Erfolgreich mit Apple Health & Google Fit synchronisiert."
        }
    }

    public func fetchRecentWorkouts() {
        fetchRecentWorkoutsInternal(completion: nil)
    }

    private func fetchRecentWorkoutsInternal(completion: (() -> Void)? = nil) {
        guard isAvailable else {
            completion?()
            return
        }

        let workoutType = HKObjectType.workoutType()
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        // Abruf ALLER historischen Einheiten (Google Fit, Apple Watch etc.) ohne kuenstliches Zeitlimit
        let query = HKSampleQuery(sampleType: workoutType, predicate: nil, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { [weak self] _, results, _ in
            guard let workouts = results as? [HKWorkout] else {
                Task { @MainActor in
                    completion?()
                }
                return
            }

            let mapped: [ExternalWorkoutItem] = workouts.compactMap { workout in
                // Quellennamen ermitteln (z.B. Google Fit, Strava, Apple Watch)
                let source = workout.sourceRevision.source.name
                let activityName = Self.activityName(for: workout.workoutActivityType)
                let duration = workout.duration
                // Fake- und Testdaten eliminieren (Workouts unter 2 Minuten werden verworfen)
                guard duration >= 120.0 else { return nil }

                let kcal = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0.0
                let distance = workout.totalDistance?.doubleValue(for: .meter())

                var title = activityName
                if let brand = workout.metadata?[HKMetadataKeyWorkoutBrandName] as? String {
                    title = "\(brand) • \(activityName)"
                } else if let customTitle = workout.metadata?["WorkoutTitle"] as? String {
                    title = customTitle
                }

                return ExternalWorkoutItem(
                    id: workout.uuid,
                    title: title,
                    activityType: activityName,
                    startDate: workout.startDate,
                    durationSeconds: duration,
                    distanceMeters: distance,
                    caloriesBurned: kcal,
                    sourceName: source,
                    averageHeartRate: nil,
                    maxHeartRate: nil
                )
            }

            Task { @MainActor in
                self?.syncedWorkouts = mapped
                if let encoded = try? JSONEncoder().encode(mapped) {
                    UserDefaults.standard.set(encoded, forKey: "grow_synced_workouts")
                }
                completion?()
            }
        }

        healthStore.execute(query)
    }

    // MARK: - Workout Schreiben (Outbound nach Apple Health / Google Fit)
    @discardableResult
    public func saveWorkout(session: WorkoutSession) async -> Bool {
        guard isAvailable else { return false }

        return await withCheckedContinuation { continuation in
            let startTime = session.startTime
            let endTime = session.endTime ?? Date()
            let durationSeconds = max(60.0, endTime.timeIntervalSince(startTime))
            let energyKcal = max(session.estimatedCaloriesBurned, Double(session.durationMinutes) * 5.0)

            let energyQuantity = HKQuantity(unit: .kilocalorie(), doubleValue: energyKcal)

            var metadata: [String: Any] = [
                HKMetadataKeyWorkoutBrandName: "Grow",
                HKMetadataKeyIndoorWorkout: true,
                "TonnageKg": session.totalTonnageKg,
                "WorkoutTitle": session.title,
                "PerceivedExertionRPE": session.perceivedExertionRPE
            ]
            if !session.somaticNotes.isEmpty {
                metadata["SomaticNotes"] = session.somaticNotes
            }

            let workout = HKWorkout(
                activityType: .traditionalStrengthTraining,
                start: startTime,
                end: endTime,
                duration: durationSeconds,
                totalEnergyBurned: energyQuantity,
                totalDistance: nil,
                metadata: metadata
            )

            healthStore.save(workout) { [weak self] success, error in
                Task { @MainActor in
                    guard let self = self else {
                        continuation.resume(returning: false)
                        return
                    }
                    if success {
                        self.lastSyncTimestamp = Date()
                        self.statusMessage = "Workout \"\(session.title)\" in HealthKit verbucht."
                        // Daten neu laden, um Aktivkalorien direkt zu aktualisieren
                        self.fetchAllHealthData()
                        continuation.resume(returning: true)
                    } else {
                        self.statusMessage = "Fehler beim Speichern des Workouts: \(error?.localizedDescription ?? "Unbekannt")"
                        continuation.resume(returning: false)
                    }
                }
            }
        }
    }

    // MARK: - Makros Schreiben (Outbound)
    @discardableResult
    public func writeDietaryMacros(protein: Double, calories: Double, carbs: Double = 0.0, fat: Double = 0.0, date: Date = Date()) async -> Bool {
        guard isAvailable else { return false }

        return await withCheckedContinuation { continuation in
            var samples: [HKQuantitySample] = []

            if protein > 0, let type = HKQuantityType.quantityType(forIdentifier: .dietaryProtein) {
                let q = HKQuantity(unit: .gram(), doubleValue: protein)
                samples.append(HKQuantitySample(type: type, quantity: q, start: date, end: date))
            }
            if calories > 0, let type = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed) {
                let q = HKQuantity(unit: .kilocalorie(), doubleValue: calories)
                samples.append(HKQuantitySample(type: type, quantity: q, start: date, end: date))
            }
            if carbs > 0, let type = HKQuantityType.quantityType(forIdentifier: .dietaryCarbohydrates) {
                let q = HKQuantity(unit: .gram(), doubleValue: carbs)
                samples.append(HKQuantitySample(type: type, quantity: q, start: date, end: date))
            }
            if fat > 0, let type = HKQuantityType.quantityType(forIdentifier: .dietaryFatTotal) {
                let q = HKQuantity(unit: .gram(), doubleValue: fat)
                samples.append(HKQuantitySample(type: type, quantity: q, start: date, end: date))
            }

            guard !samples.isEmpty else {
                continuation.resume(returning: true)
                return
            }

            healthStore.save(samples) { [weak self] success, error in
                Task { @MainActor in
                    guard let self = self else {
                        continuation.resume(returning: false)
                        return
                    }
                    if success {
                        self.lastSyncTimestamp = Date()
                        self.statusMessage = "Makros in HealthKit geschrieben."
                        self.fetchAllHealthData()
                        continuation.resume(returning: true)
                    } else {
                        self.statusMessage = "Fehler beim Schreiben der Makros: \(error?.localizedDescription ?? "Unbekannt")"
                        continuation.resume(returning: false)
                    }
                }
            }
        }
    }

    // MARK: - Interne Abfragehelfer
    private func fetchCumulative(typeIdentifier: HKQuantityTypeIdentifier, unit: HKUnit, completion: @escaping (Double) -> Void) {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: typeIdentifier) else {
            completion(0.0)
            return
        }

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
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: typeIdentifier) else {
            completion(nil, nil)
            return
        }

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

    // MARK: - Nutrition & Water Methods (Grow Parity)
    public func fetchTodayHealthData() {
        fetchAllHealthData()
    }

    public func writeMealNutrients(protein: Double, carbs: Double, fat: Double, calories: Double, date: Date = Date()) {
        Task {
            _ = await writeDietaryMacros(protein: protein, calories: calories, carbs: carbs, fat: fat, date: date)
        }
    }

    public func logWaterIntake(amountMl: Double, date: Date = Date()) {
        waterIntakeMl += amountMl
        GrowSuiteBridge.shared.logWater(amountMl: amountMl, date: date, sourceApp: "Grow")

        guard isAvailable, amountMl > 0, let waterType = HKQuantityType.quantityType(forIdentifier: .dietaryWater) else {
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
        GrowSuiteBridge.shared.setTotalWater(totalMl: 0.0, sourceApp: "Grow")
    }

    nonisolated private static func activityName(for activityType: HKWorkoutActivityType) -> String {
        switch activityType {
        case .running: return "Lauf"
        case .cycling: return "Radfahrt"
        case .walking: return "Gehen"
        case .traditionalStrengthTraining, .functionalStrengthTraining: return "Krafttraining"
        case .crossTraining: return "Cross-Training"
        case .rowing: return "Rudern"
        case .swimming: return "Schwimmen"
        case .yoga: return "Yoga"
        case .highIntensityIntervalTraining: return "HIIT"
        default: return "Training"
        }
    }
}
