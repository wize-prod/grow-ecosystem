import Foundation

public enum MuscleGroup: String, Codable, CaseIterable, Identifiable {
    case functionalCore = "Funktioneller Rumpf (Reha)"
    case lowerBack = "Unterer Ruecken"
    case back = "Ruecken / Latissimus"
    case chest = "Brust"
    case shoulders = "Schultern"
    case glutesPosterior = "Gluteus & Ischios"
    case legs = "Quadrizeps & Waden"
    case arms = "Arme (Bizeps & Trizeps)"
    case cardioConditioning = "Kardiovaskulaer & Vagus"
    case mobilityFlexibility = "Mobilitaet & Dehnung (Rest)"

    public var id: String { rawValue }
}

public enum EquipmentType: String, Codable, CaseIterable, Identifiable {
    // Kraftmaschinen
    case shoulderPressMachine = "Schulterdrueck-Maschine"
    case rowMachine3D = "3D Rudermaschine"
    case assistedChinDipMachine = "Klimmzuege- & Dips-Maschine"
    case rhomboideusMachine = "Rhomboideus-Maschine"
    case legPressMachine = "Beinpress-Maschine"
    case hipThrustGluteDrive = "Hip-Thrust / Glute-Drive-Maschine"
    case nineStationTower = "Neunstoeckige-Maschine"
    case legCurlMachine = "Beinbeuge-Maschine"
    case adductionMachine = "Adduktions-Maschine"
    case abductionMachine = "Abduktions-Maschine"
    case rotaryTorsoMachine = "Rumpfdrehmaschine"
    case lateralFlexionMachine = "Seitneige-Maschine"
    case backExtensionMachine = "Ruecken-Maschine"
    case butterflyPecDeck = "Butterfly-Maschine (Pec-Deck)"
    case pulloverMachine = "Pullover-Maschine"
    case chestPressMachine = "Bruststueck-Maschine"
    case latPulldownMachine = "Latzug-Maschine"
    case smithMachine = "Smith Machine (Multipresse)"
    case seatedCalfRaise = "Wadenmaschine sitzend"

    // Seilzuege & Baenke
    case cableCrossoverTower = "Zugapparat (Kabelzugturm)"
    case singleCableTower = "Zugapparat (Einzel-Variante)"
    case flatBenchBarbell = "Flachbank mit Langhantel"
    case adjustableBench = "Verstellbare Hantelbank"
    case preacherCurlBench = "Scott-Curl-Bank"
    case romanChairBackExtension = "Roemische Bank / Hyperextension"
    case romanChairOblique = "Roemische Bank fuer Bauchtraining"
    case hyperextension45 = "Hyperextensionsbank (45-Grad)"
    case squatRack = "Squat Rack / Kniebeugenstaender"
    case dipStation = "Dipsstation"
    case pullUpBar = "Klimmzugstange"

    // Freihanteln & Calisthenics / Klettern
    case dumbBells = "Kurzhanteln (1-37.5 kg)"
    case kettlebells = "Kettlebells (4-32 kg)"
    case gymRings = "Turnringe (Gym Rings)"
    case campusHangboard = "Campusboard / Hangboard"
    case prowlerSled = "Prowler / Sled (Schlitten)"

    // Cardio & Ergometer
    case upperBodyErgometer = "Oberkoerper-Ergometer"
    case concept2RowErg = "Concept2 RowErg"
    case assaultBike = "Assault Bike (Air Bike)"
    case stationaryBike = "Stationaeres Fahrrad-Ergometer"
    case treadmill = "Laufband"
    case crossTrainer = "Crosstrainer / Ellipsentrainer"
    case outdoorRunning = "Draussen Laufen"

    // Functional, Balance, Mobility & Reha
    case matArea = "Grosse Mattenflaeche"
    case swissBall = "Gymnastikball"
    case medicineBalls = "Medizinbaelle (Leder 3-5 kg)"
    case bosuBall = "BOSU-Ball"
    case mobilityStaff = "Stab (Dehnung & Mobilitaet)"
    case bodyweight = "Eigenkoerpergewicht (Bodyweight)"
    case roomFurniture = "Stube & Zimmer (Tuerrahmen, Stuhl, Bett)"
    case stretchingMat = "Bodenmatte & Dehnung (Mobility)"

    public var id: String { rawValue }

    // Aliases for backwards compatibility with prior seed references
    public static var cableTower: EquipmentType { .cableCrossoverTower }
    public static var hipThrustMachine: EquipmentType { .hipThrustGluteDrive }
    public static var latPulldown: EquipmentType { .latPulldownMachine }
    public static var chestPress: EquipmentType { .chestPressMachine }
    public static var shoulderPress: EquipmentType { .shoulderPressMachine }
    public static var legPress: EquipmentType { .legPressMachine }
    public static var legCurl: EquipmentType { .legCurlMachine }
    public static var calfMachine: EquipmentType { .seatedCalfRaise }
    public static var adductorMachine: EquipmentType { .adductionMachine }
    public static var abductorMachine: EquipmentType { .abductionMachine }
    public static var rowErgConcept2: EquipmentType { .concept2RowErg }
    public static var barbell: EquipmentType { .flatBenchBarbell }
    public static var kettlebell: EquipmentType { .kettlebells }
    public static var matFloor: EquipmentType { .matArea }
    public static var gymnasticsBall: EquipmentType { .swissBall }
    public static var chinUpDipStation: EquipmentType { .assistedChinDipMachine }
}

public enum DifficultyTier: String, Codable, CaseIterable, Identifiable {
    case beginner = "Anfaenger"
    case intermediate = "Mittelstufe"
    case advanced = "Fortgeschritten"
    case elite = "Elite"

    public var id: String { rawValue }

    public static func from(string: String) -> DifficultyTier {
        let lower = string.lowercased()
        if lower.contains("fortgeschritten") || lower.contains("advanced") { return .advanced }
        if lower.contains("elite") || lower.contains("pro") { return .elite }
        if lower.contains("mittel") || lower.contains("intermediate") { return .intermediate }
        return .beginner
    }
}

public enum MovementCategory: String, Codable, CaseIterable, Identifiable {
    case push = "Push"
    case pull = "Pull"
    case legs = "Legs"
    case core = "Core"
    case cardio = "Cardio"
    case mobility = "Mobility"

    public var id: String { rawValue }

    public static func from(string: String) -> MovementCategory {
        let lower = string.lowercased()
        if lower.contains("push") { return .push }
        if lower.contains("pull") { return .pull }
        if lower.contains("leg") || lower.contains("bein") { return .legs }
        if lower.contains("core") || lower.contains("rumpf") { return .core }
        if lower.contains("cardio") || lower.contains("ausdauer") { return .cardio }
        if lower.contains("mobil") || lower.contains("dehn") { return .mobility }
        return .pull
    }
}

public enum KineticMechanics: String, Codable, CaseIterable, Identifiable {
    case compound = "Grunduebung (Compound)"
    case isolation = "Isolationsuebung (Isolation)"
    case isometric = "Isometrisch"

    public var id: String { rawValue }

    public static func from(string: String) -> KineticMechanics {
        let lower = string.lowercased()
        if lower.contains("isolation") { return .isolation }
        if lower.contains("isometrisch") || lower.contains("isometric") || lower.contains("hold") { return .isometric }
        return .compound
    }
}

public enum MovementPattern: String, Codable, CaseIterable, Identifiable {
    case horizontalPush = "Horizontal Push"
    case verticalPush = "Vertical Push"
    case horizontalPull = "Horizontal Pull"
    case verticalPull = "Vertical Pull"
    case squat = "Squat"
    case hinge = "Hinge"
    case lunge = "Lunge"
    case rotation = "Rotation"
    case carry = "Carry"
    case isolation = "Isolation"

    public var id: String { rawValue }

    public static func from(string: String) -> MovementPattern {
        let lower = string.lowercased()
        if lower.contains("horiz") && lower.contains("push") { return .horizontalPush }
        if lower.contains("vert") && lower.contains("push") { return .verticalPush }
        if lower.contains("horiz") && lower.contains("pull") { return .horizontalPull }
        if lower.contains("vert") && lower.contains("pull") { return .verticalPull }
        if lower.contains("squat") || lower.contains("beuge") { return .squat }
        if lower.contains("hinge") || lower.contains("kreuzheben") || lower.contains("deadlift") { return .hinge }
        if lower.contains("lunge") || lower.contains("ausfallschritt") { return .lunge }
        if lower.contains("rotat") { return .rotation }
        if lower.contains("carry") || lower.contains("tragen") { return .carry }
        if lower.contains("isolat") { return .isolation }
        return .horizontalPull
    }
}

public enum ForceType: String, Codable, CaseIterable, Identifiable {
    case push = "Push"
    case pull = "Pull"
    case staticHold = "Static"
    case hold = "Hold"

    public var id: String { rawValue }

    public static func from(string: String) -> ForceType {
        let lower = string.lowercased()
        if lower.contains("push") { return .push }
        if lower.contains("pull") { return .pull }
        if lower.contains("static") { return .staticHold }
        if lower.contains("hold") { return .hold }
        return .pull
    }
}

public struct Exercise: Identifiable, Codable, Equatable, Hashable {
    public var id: UUID
    public var name: String
    public var targetMuscle: MuscleGroup
    public var equipment: EquipmentType
    public var isBWKRehaSafe: Bool
    public var isContraindicated: Bool
    public var secondaryMuscles: [MuscleGroup]
    public var executionNotes: String
    public var defaultSets: Int
    public var defaultReps: Int
    public var defaultRestSeconds: Int
    public var isCustom: Bool

    // Strongly-Typed Enriched Technical Attributes
    public var difficultyTier: DifficultyTier
    public var categoryTypeEnum: MovementCategory
    public var mechanicsEnum: KineticMechanics
    public var movementPatternEnum: MovementPattern
    public var forceTypeEnum: ForceType

    // String Backwards Compatibility Bridges
    public var difficulty: String {
        get { difficultyTier.rawValue }
        set { difficultyTier = DifficultyTier.from(string: newValue) }
    }
    public var categoryType: String {
        get { categoryTypeEnum.rawValue }
        set { categoryTypeEnum = MovementCategory.from(string: newValue) }
    }
    public var mechanics: String {
        get { mechanicsEnum.rawValue }
        set { mechanicsEnum = KineticMechanics.from(string: newValue) }
    }
    public var movementPattern: String {
        get { movementPatternEnum.rawValue }
        set { movementPatternEnum = MovementPattern.from(string: newValue) }
    }
    public var force: String {
        get { forceTypeEnum.rawValue }
        set { forceTypeEnum = ForceType.from(string: newValue) }
    }

    public var isExplicitlyTimeBased: Bool? = nil

    public var isTimeBased: Bool {
        if let explicit = isExplicitlyTimeBased {
            return explicit
        }
        if mechanicsEnum == .isometric || forceTypeEnum == .staticHold || forceTypeEnum == .hold {
            return true
        }
        let lower = name.lowercased()
        return lower.contains("plank") ||
               lower.contains("halten") ||
               lower.contains("hold") ||
               lower.contains("wall sit") ||
               lower.contains("dead hang") ||
               lower.contains("statisch") ||
               (lower.contains("mcgill") && (lower.contains("curl") || lower.contains("curl-up")))
    }

    public var isUnilateral: Bool {
        let lower = name.lowercased()
        return lower.contains("einarmig") ||
               lower.contains("one-arm") ||
               lower.contains("single-arm") ||
               lower.contains("single arm") ||
               lower.contains("side plank") ||
               lower.contains("seitlicher unterarmstuetz") ||
               lower.contains("einbeinig") ||
               lower.contains("single-leg") ||
               lower.contains("single leg") ||
               lower.contains("bulgarian") ||
               lower.contains("unilateral") ||
               lower.contains("step-up")
    }

    public var dynamicRestSeconds: Int {
        if isTimeBased || targetMuscle == .functionalCore || targetMuscle == .lowerBack || targetMuscle == .mobilityFlexibility {
            return 25 // 20-30s Dichte-Regelung fuer Rumpf-Isometrie & Stabi
        } else if equipment == .bodyweight || equipment == .roomFurniture {
            return 60 // 60s fuer Calisthenics-Volumen
        } else {
            return defaultRestSeconds > 0 ? defaultRestSeconds : 90
        }
    }

    public var primaryMusclesDetailed: [String]
    public var secondaryMusclesDetailed: [String]
    public var stabilizersDetailed: [String]
    public var setup: String
    public var execution: String
    public var commonMistakes: [String]
    public var cues: [String]
    public var easierOptions: [String]
    public var harderOptions: [String]
    public var programmingGuidance: String
    public var youtubeVideoId: String?

    public init(
        id: UUID = UUID(),
        name: String,
        targetMuscle: MuscleGroup,
        secondaryMuscles: [MuscleGroup] = [],
        equipment: EquipmentType,
        isBWKRehaSafe: Bool = true,
        isContraindicated: Bool = false,
        executionNotes: String = "",
        defaultSets: Int = 3,
        defaultReps: Int = 10,
        defaultRestSeconds: Int = 90,
        difficulty: String = "Intermediate",
        categoryType: String = "Pull",
        mechanics: String = "Compound",
        movementPattern: String = "Vertical Pull",
        force: String = "Pull",
        primaryMusclesDetailed: [String] = [],
        secondaryMusclesDetailed: [String] = [],
        stabilizersDetailed: [String] = [],
        setup: String = "",
        execution: String = "",
        commonMistakes: [String] = [],
        cues: [String] = [],
        easierOptions: [String] = [],
        harderOptions: [String] = [],
        programmingGuidance: String = "",
        youtubeVideoId: String? = nil,
        isCustom: Bool = false,
        isExplicitlyTimeBased: Bool? = nil
    ) {
        self.id = id
        self.name = name
        self.targetMuscle = targetMuscle
        self.secondaryMuscles = secondaryMuscles
        self.equipment = equipment
        self.isBWKRehaSafe = isBWKRehaSafe
        self.isContraindicated = isContraindicated
        self.executionNotes = executionNotes
        self.defaultSets = defaultSets
        self.defaultReps = defaultReps
        self.defaultRestSeconds = defaultRestSeconds
        self.isCustom = isCustom
        self.isExplicitlyTimeBased = isExplicitlyTimeBased
        self.difficultyTier = DifficultyTier.from(string: difficulty)
        self.categoryTypeEnum = MovementCategory.from(string: categoryType)
        self.mechanicsEnum = KineticMechanics.from(string: mechanics)
        self.movementPatternEnum = MovementPattern.from(string: movementPattern)
        self.forceTypeEnum = ForceType.from(string: force)
        self.primaryMusclesDetailed = primaryMusclesDetailed
        self.secondaryMusclesDetailed = secondaryMusclesDetailed
        self.stabilizersDetailed = stabilizersDetailed
        self.setup = setup
        self.execution = execution
        self.commonMistakes = commonMistakes
        self.cues = cues
        self.easierOptions = easierOptions
        self.harderOptions = harderOptions
        self.programmingGuidance = programmingGuidance
        self.youtubeVideoId = youtubeVideoId
        self.isExplicitlyTimeBased = isExplicitlyTimeBased
    }

    enum CodingKeys: String, CodingKey {
        case id, name, targetMuscle, secondaryMuscles, equipment
        case isBWKRehaSafe, isContraindicated, executionNotes
        case defaultSets, defaultReps, defaultRestSeconds, isCustom
        case difficulty, categoryType, mechanics, movementPattern, force
        case primaryMusclesDetailed, secondaryMusclesDetailed, stabilizersDetailed
        case setup, execution, commonMistakes, cues, easierOptions, harderOptions, programmingGuidance
        case youtubeVideoId, isExplicitlyTimeBased
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(targetMuscle, forKey: .targetMuscle)
        try container.encode(secondaryMuscles, forKey: .secondaryMuscles)
        try container.encode(equipment, forKey: .equipment)
        try container.encode(isBWKRehaSafe, forKey: .isBWKRehaSafe)
        try container.encode(isContraindicated, forKey: .isContraindicated)
        try container.encode(executionNotes, forKey: .executionNotes)
        try container.encode(defaultSets, forKey: .defaultSets)
        try container.encode(defaultReps, forKey: .defaultReps)
        try container.encode(defaultRestSeconds, forKey: .defaultRestSeconds)
        try container.encode(isCustom, forKey: .isCustom)
        try container.encode(difficulty, forKey: .difficulty)
        try container.encode(categoryType, forKey: .categoryType)
        try container.encode(mechanics, forKey: .mechanics)
        try container.encode(movementPattern, forKey: .movementPattern)
        try container.encode(force, forKey: .force)
        try container.encode(primaryMusclesDetailed, forKey: .primaryMusclesDetailed)
        try container.encode(secondaryMusclesDetailed, forKey: .secondaryMusclesDetailed)
        try container.encode(stabilizersDetailed, forKey: .stabilizersDetailed)
        try container.encode(setup, forKey: .setup)
        try container.encode(execution, forKey: .execution)
        try container.encode(commonMistakes, forKey: .commonMistakes)
        try container.encode(cues, forKey: .cues)
        try container.encode(easierOptions, forKey: .easierOptions)
        try container.encode(harderOptions, forKey: .harderOptions)
        try container.encode(programmingGuidance, forKey: .programmingGuidance)
        try container.encodeIfPresent(youtubeVideoId, forKey: .youtubeVideoId)
        try container.encodeIfPresent(isExplicitlyTimeBased, forKey: .isExplicitlyTimeBased)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decode(String.self, forKey: .name)
        targetMuscle = try container.decode(MuscleGroup.self, forKey: .targetMuscle)
        secondaryMuscles = try container.decodeIfPresent([MuscleGroup].self, forKey: .secondaryMuscles) ?? []
        equipment = try container.decode(EquipmentType.self, forKey: .equipment)
        isBWKRehaSafe = try container.decodeIfPresent(Bool.self, forKey: .isBWKRehaSafe) ?? true
        isContraindicated = try container.decodeIfPresent(Bool.self, forKey: .isContraindicated) ?? false
        executionNotes = try container.decodeIfPresent(String.self, forKey: .executionNotes) ?? ""
        defaultSets = try container.decodeIfPresent(Int.self, forKey: .defaultSets) ?? 3
        defaultReps = try container.decodeIfPresent(Int.self, forKey: .defaultReps) ?? 10
        defaultRestSeconds = try container.decodeIfPresent(Int.self, forKey: .defaultRestSeconds) ?? 90
        isCustom = try container.decodeIfPresent(Bool.self, forKey: .isCustom) ?? false
        isExplicitlyTimeBased = try container.decodeIfPresent(Bool.self, forKey: .isExplicitlyTimeBased)
        
        let diffStr = try container.decodeIfPresent(String.self, forKey: .difficulty) ?? "Intermediate"
        difficultyTier = DifficultyTier.from(string: diffStr)

        let catStr = try container.decodeIfPresent(String.self, forKey: .categoryType) ?? "Pull"
        categoryTypeEnum = MovementCategory.from(string: catStr)

        let mechStr = try container.decodeIfPresent(String.self, forKey: .mechanics) ?? "Compound"
        mechanicsEnum = KineticMechanics.from(string: mechStr)

        let patternStr = try container.decodeIfPresent(String.self, forKey: .movementPattern) ?? "Vertical Pull"
        movementPatternEnum = MovementPattern.from(string: patternStr)

        let forceStr = try container.decodeIfPresent(String.self, forKey: .force) ?? "Pull"
        forceTypeEnum = ForceType.from(string: forceStr)

        primaryMusclesDetailed = try container.decodeIfPresent([String].self, forKey: .primaryMusclesDetailed) ?? []
        secondaryMusclesDetailed = try container.decodeIfPresent([String].self, forKey: .secondaryMusclesDetailed) ?? []
        stabilizersDetailed = try container.decodeIfPresent([String].self, forKey: .stabilizersDetailed) ?? []
        setup = try container.decodeIfPresent(String.self, forKey: .setup) ?? ""
        execution = try container.decodeIfPresent(String.self, forKey: .execution) ?? ""
        commonMistakes = try container.decodeIfPresent([String].self, forKey: .commonMistakes) ?? []
        cues = try container.decodeIfPresent([String].self, forKey: .cues) ?? []
        easierOptions = try container.decodeIfPresent([String].self, forKey: .easierOptions) ?? []
        harderOptions = try container.decodeIfPresent([String].self, forKey: .harderOptions) ?? []
        programmingGuidance = try container.decodeIfPresent(String.self, forKey: .programmingGuidance) ?? ""
        youtubeVideoId = try container.decodeIfPresent(String.self, forKey: .youtubeVideoId)
        isExplicitlyTimeBased = try container.decodeIfPresent(Bool.self, forKey: .isExplicitlyTimeBased)
    }

    public var isBWKContraindicated: Bool {
        if isContraindicated { return true }
        let n = name.lowercased()
        let e = executionNotes.lowercased()
        return n.contains("crunch") || n.contains("sit-up") || n.contains("situp") || n.contains("ab wheel") || e.contains("crunch") || e.contains("sit-up")
    }
}

