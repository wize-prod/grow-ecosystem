import Foundation

// MARK: - Metrik-Typen fuer programmuebergreifende Standards
public enum BenchmarkMetricType: String, CaseIterable, Codable, Identifiable {
    case estimated1RM = "1RM Schaetzung (Maximalkraft)"
    case bodyweightMaxReps = "Maximal-Wiederholungen (Relative Kraft)"
    case thresholdPaceSeconds = "Schwellen-Pace (Sekunden / km)"
    case isometricHoldSeconds = "Isometrische Haltezeit (Sekunden)"
    case vo2MaxEstimate = "VO2max Schaetzung (ml/kg/min)"

    public var id: String { rawValue }

    public var defaultHalfLifeDays: Double {
        switch self {
        case .estimated1RM: return 42.0          // Myofibrillaere Kraft: Halbwertszeit ~6 Wochen
        case .bodyweightMaxReps: return 30.0     // Kraftausdauer: Halbwertszeit ~4-5 Wochen
        case .thresholdPaceSeconds: return 18.0  // Laktat-Schwellenkapazitaet: Halbwertszeit ~2-3 Wochen
        case .isometricHoldSeconds: return 35.0  // Sehnen- & Kernstiffness: Halbwertszeit ~5 Wochen
        case .vo2MaxEstimate: return 21.0        // Kardiale Spitzen-Aerobie: Halbwertszeit ~3 Wochen
        }
    }
}

// MARK: - Einzelner Leistungsstandard mit physiologischem Zeit-Decay
public struct CrossProgramBenchmark: Identifiable, Codable, Equatable {
    public var id: UUID
    public var metricType: BenchmarkMetricType
    public var exerciseKey: String
    public var peakValue: Double
    public var unit: String
    public var recordedAt: Date
    public var decayHalfLifeDays: Double
    public var sourceProgramTitle: String

    public init(
        id: UUID = UUID(),
        metricType: BenchmarkMetricType,
        exerciseKey: String,
        peakValue: Double,
        unit: String,
        recordedAt: Date = Date(),
        decayHalfLifeDays: Double? = nil,
        sourceProgramTitle: String = "Freies Training"
    ) {
        self.id = id
        self.metricType = metricType
        self.exerciseKey = exerciseKey
        self.peakValue = peakValue
        self.unit = unit
        self.recordedAt = recordedAt
        self.decayHalfLifeDays = decayHalfLifeDays ?? metricType.defaultHalfLifeDays
        self.sourceProgramTitle = sourceProgramTitle
    }

    /// Berechnet den aktuellen effektiven Standard unter Beruecksichtigung der biologischen Halbwertszeit
    public func currentEffectiveValue(asOf date: Date = Date()) -> Double {
        let elapsedDays = max(0, Calendar.current.dateComponents([.day], from: recordedAt, to: date).day ?? 0)

        // Bis zu 4 Tage volle Geltung ohne Degradation
        if elapsedDays <= 4 {
            return peakValue
        }

        // Halbwertszeit-Exponentialzerfall: N(t) = N0 * (0.5)^(t / t_half)
        let decayExponent = Double(elapsedDays) / max(1.0, decayHalfLifeDays)
        let decayFactor = pow(0.5, decayExponent)

        // Fuer Pace (Zeit pro km): hoehere Zahl = langsamer!
        if metricType == .thresholdPaceSeconds {
            // Bei Ausdauer-Decay steigt die benoetigte Zeit pro km um bis zu 25%
            let speedFactor = max(0.75, decayFactor)
            return peakValue / speedFactor
        }

        // Feste Untergrenze von 50 % des Allzeit-Peaks (Muscle-Memory-Fundament)
        let floorFactor = 0.50
        let effectiveFactor = max(floorFactor, decayFactor)
        return peakValue * effectiveFactor
    }

    /// Prozentualer Erhaltungszustand (100% = Peak, 70% = deconditioned)
    public func retentionPercentage(asOf date: Date = Date()) -> Double {
        let effective = currentEffectiveValue(asOf: date)
        if metricType == .thresholdPaceSeconds {
            guard effective > 0 else { return 1.0 }
            return min(1.0, peakValue / effective)
        }
        guard peakValue > 0 else { return 0.0 }
        return min(1.0, effective / peakValue)
    }
}

// MARK: - Zentrale Benchmark-Registry
public struct BenchmarkRegistryState: Codable, Equatable {
    public var benchmarks: [CrossProgramBenchmark] = []

    public init(benchmarks: [CrossProgramBenchmark] = []) {
        self.benchmarks = benchmarks
    }

    /// Aktualisiert oder registriert einen neuen Spitzenwert
    public mutating func recordAchievement(
        metricType: BenchmarkMetricType,
        exerciseKey: String,
        value: Double,
        unit: String,
        sourceProgram: String
    ) {
        let key = exerciseKey.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        if let idx = benchmarks.firstIndex(where: { $0.exerciseKey.lowercased() == key && $0.metricType == metricType }) {
            // Pruefen ob neuer Bestwert oder Refresh des bestehenden Bestwerts
            let current = benchmarks[idx]
            let isImprovement: Bool
            if metricType == .thresholdPaceSeconds {
                isImprovement = value < current.peakValue && value > 0 // Schneller gelaufen
            } else {
                isImprovement = value >= current.peakValue
            }

            if isImprovement {
                benchmarks[idx].peakValue = value
                benchmarks[idx].recordedAt = Date()
                benchmarks[idx].sourceProgramTitle = sourceProgram
            } else {
                // Wert war niedriger, aber erneuert den Zeitstempel anteilig
                let eff = current.currentEffectiveValue()
                if value > eff {
                    benchmarks[idx].peakValue = value
                    benchmarks[idx].recordedAt = Date()
                }
            }
        } else {
            // Neuer Benchmark-Eintrag
            let entry = CrossProgramBenchmark(
                metricType: metricType,
                exerciseKey: exerciseKey,
                peakValue: value,
                unit: unit,
                recordedAt: Date(),
                sourceProgramTitle: sourceProgram
            )
            benchmarks.append(entry)
        }
    }

    /// Holt den aktuellen effektiven Standard fuer eine Uebung
    public func getEffectiveStandard(exerciseKey: String, metricType: BenchmarkMetricType) -> CrossProgramBenchmark? {
        let key = exerciseKey.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return benchmarks.first(where: { $0.exerciseKey.lowercased() == key && $0.metricType == metricType })
    }
}
