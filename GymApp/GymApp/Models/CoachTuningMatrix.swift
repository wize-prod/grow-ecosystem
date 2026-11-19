import Foundation

// MARK: - Coach Tuning Matrix (Zwei-Wege-Steuerungsmatrix)
// Persistiert als deterministische Konfiguration: Documents/coach_tuning_matrix.json
// Ermoeglicht Antigravity die Anpassung von Hyperparametern via USB-C ohne Re-Kompilierung.
public struct CoachTuningMatrix: Codable, Equatable, Sendable {
    public struct BanisterConfig: Codable, Equatable, Sendable {
        public var ctl_decay_days: Double = 28.0
        public var atl_decay_days: Double = 7.0
        public var tsb_deload_threshold: Double = -20.0

        public init(
            ctl_decay_days: Double = 28.0,
            atl_decay_days: Double = 7.0,
            tsb_deload_threshold: Double = -20.0
        ) {
            self.ctl_decay_days = ctl_decay_days
            self.atl_decay_days = atl_decay_days
            self.tsb_deload_threshold = tsb_deload_threshold
        }
    }

    public struct DampersConfig: Codable, Equatable, Sendable {
        public var omission_damper_multiplier: Double = 0.50
        public var high_rpe_damper_multiplier: Double = 0.70
        public var decay_duration_hours: Double = 72.0

        public init(
            omission_damper_multiplier: Double = 0.50,
            high_rpe_damper_multiplier: Double = 0.70,
            decay_duration_hours: Double = 72.0
        ) {
            self.omission_damper_multiplier = omission_damper_multiplier
            self.high_rpe_damper_multiplier = high_rpe_damper_multiplier
            self.decay_duration_hours = decay_duration_hours
        }
    }

    public struct CrossAppCompensationConfig: Codable, Equatable, Sendable {
        public var kcal_recovery_ratio: Double = 0.60
        public var carbs_per_tonnage_kg: Double = 0.003
        public var water_ml_per_minute: Double = 10.0
        public var protein_ceiling_grams: Double = 170.0

        public init(
            kcal_recovery_ratio: Double = 0.60,
            carbs_per_tonnage_kg: Double = 0.003,
            water_ml_per_minute: Double = 10.0,
            protein_ceiling_grams: Double = 170.0
        ) {
            self.kcal_recovery_ratio = kcal_recovery_ratio
            self.carbs_per_tonnage_kg = carbs_per_tonnage_kg
            self.water_ml_per_minute = water_ml_per_minute
            self.protein_ceiling_grams = protein_ceiling_grams
        }
    }

    public struct SymmetryConfig: Codable, Equatable, Sendable {
        public var upper_to_lower_friction_ratio: Double = 2.0
        public var primer_set_count: Int = 2

        public init(
            upper_to_lower_friction_ratio: Double = 2.0,
            primer_set_count: Int = 2
        ) {
            self.upper_to_lower_friction_ratio = upper_to_lower_friction_ratio
            self.primer_set_count = primer_set_count
        }
    }

    public struct CircadianConfig: Codable, Equatable, Sendable {
        public var cutoff_hour: Int = 19
        public var cutoff_minute: Int = 30
        public var safe_rir: Int = 4

        public init(
            cutoff_hour: Int = 19,
            cutoff_minute: Int = 30,
            safe_rir: Int = 4
        ) {
            self.cutoff_hour = cutoff_hour
            self.cutoff_minute = cutoff_minute
            self.safe_rir = safe_rir
        }
    }

    public struct FieldDutyConfig: Codable, Equatable, Sendable {
        public var duty_step_threshold: Int = 12000
        public var trimp_multiplier: Double = 12.0

        public init(
            duty_step_threshold: Int = 12000,
            trimp_multiplier: Double = 12.0
        ) {
            self.duty_step_threshold = duty_step_threshold
            self.trimp_multiplier = trimp_multiplier
        }
    }

    public var banister: BanisterConfig = BanisterConfig()
    public var dampers: DampersConfig = DampersConfig()
    public var cross_app_compensation: CrossAppCompensationConfig = CrossAppCompensationConfig()
    public var symmetry: SymmetryConfig = SymmetryConfig()
    public var circadian: CircadianConfig = CircadianConfig()
    public var field_duty: FieldDutyConfig = FieldDutyConfig()

    public init(
        banister: BanisterConfig = BanisterConfig(),
        dampers: DampersConfig = DampersConfig(),
        cross_app_compensation: CrossAppCompensationConfig = CrossAppCompensationConfig(),
        symmetry: SymmetryConfig = SymmetryConfig(),
        circadian: CircadianConfig = CircadianConfig(),
        field_duty: FieldDutyConfig = FieldDutyConfig()
    ) {
        self.banister = banister
        self.dampers = dampers
        self.cross_app_compensation = cross_app_compensation
        self.symmetry = symmetry
        self.circadian = circadian
        self.field_duty = field_duty
    }
}
