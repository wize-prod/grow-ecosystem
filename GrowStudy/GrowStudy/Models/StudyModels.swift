import Foundation

public enum StudyTrack: String, Codable, CaseIterable, Identifiable {
    case wirtschaftsinformatik = "B.Sc. Wirtschaftsinformatik (HsH)"
    case bfd = "BFD-Zertifikate 2027"
    case gym = "Training & Fitness"
    case nutrition = "Ernährung & Meal-Prep"
    case care = "Pflege & Dermatologie"
    case chores = "Haushalt & Chores"
    case cyberSecurity = "Cyber Security & IT (Archiviert)"

    public var id: String { rawValue }

    public var shortTitle: String {
        switch self {
        case .wirtschaftsinformatik:
            return "WInf"
        case .bfd:
            return "BFD"
        case .gym:
            return "Gym"
        case .nutrition:
            return "Ernährung"
        case .care:
            return "Pflege"
        case .chores:
            return "Chores"
        case .cyberSecurity:
            return "CyberSec"
        }
    }

    public var deadlineNote: String {
        switch self {
        case .wirtschaftsinformatik:
            return "HsH B.Sc. WI (Start SS 2028)"
        case .bfd:
            return "BFD 2027 (7 Lehrgänge)"
        case .gym:
            return "4er-Split & Kardio"
        case .nutrition:
            return "160g Protein & Growcery"
        case .care:
            return "4C Haut- & Bartpflege"
        case .chores:
            return "Stube & Kasernen-Hygiene"
        case .cyberSecurity:
            return "Archiviert (Vorheriger Pfad)"
        }
    }

    public var systemImage: String {
        switch self {
        case .wirtschaftsinformatik:
            return "laptopcomputer"
        case .bfd:
            return "rosette"
        case .gym:
            return "figure.run"
        case .nutrition:
            return "fork.knife"
        case .care:
            return "cross.case.fill"
        case .chores:
            return "house.fill"
        case .cyberSecurity:
            return "shield.lefthalf.filled"
        }
    }
}

public enum SubmoduleType: String, Codable, CaseIterable {
    case youtubePlaylist = "YouTube Playlist"
    case youtubeVideo = "YouTube Video"
    case handsOnLab = "Praxis-Lab / CLI"
    case readingChapter = "Fachbuch / Skript"
    case examDrill = "Prüfungs-Drill"
    case webModule = "Web-Modul"
    case pdfDocument = "PDF / Dokument"
    case webLink = "Web-Link"
    case file = "Datei"

    public var systemImage: String {
        switch self {
        case .youtubePlaylist:
            return "play.rectangle.on.rectangle.fill"
        case .youtubeVideo:
            return "play.rectangle.fill"
        case .handsOnLab:
            return "terminal.fill"
        case .readingChapter:
            return "book.closed.fill"
        case .examDrill:
            return "checkmark.shield.fill"
        case .webModule:
            return "globe"
        case .pdfDocument:
            return "doc.richtext.fill"
        case .webLink:
            return "link"
        case .file:
            return "doc.fill"
        }
    }
}

public struct StudySubmodule: Identifiable, Codable, Equatable {
    public var id: String
    public var title: String
    public var type: SubmoduleType
    public var url: String?
    public var durationMinutes: Int
    public var videoCount: Int?
    public var isCompleted: Bool
    public var completedDate: Date?
    public var plannedDate: Date?
    public var calendarEventId: String?
    public var isUserAdded: Bool?
    public var attachedResources: [StepResource]?
    public var notes: String?
    public var recurrenceRule: CustomRecurrenceRule?
    public var labelId: String?

    public var allResources: [StepResource] {
        var items = attachedResources ?? []
        if let primary = url, !primary.isEmpty {
            if !items.contains(where: { $0.url == primary }) {
                let isFile = primary.hasPrefix("file://")
                let defaultTitle = isFile ? (URL(string: primary)?.lastPathComponent ?? "PDF-Dokument") : (title.isEmpty ? "Web-Link" : title)
                items.insert(StepResource(id: "primary-\(id)", title: defaultTitle, url: primary, type: isFile ? "PDF" : "Web"), at: 0)
            }
        }
        return items
    }

    public init(
        id: String = UUID().uuidString,
        title: String,
        type: SubmoduleType = .youtubeVideo,
        url: String? = nil,
        durationMinutes: Int = 25,
        videoCount: Int? = nil,
        isCompleted: Bool = false,
        completedDate: Date? = nil,
        plannedDate: Date? = nil,
        calendarEventId: String? = nil,
        isUserAdded: Bool? = false,
        attachedResources: [StepResource]? = [],
        notes: String? = nil,
        recurrenceRule: CustomRecurrenceRule? = nil,
        labelId: String? = nil
    ) {
        self.id = id
        self.title = title
        self.type = type
        self.url = url
        self.durationMinutes = durationMinutes
        self.videoCount = videoCount
        self.isCompleted = isCompleted
        self.completedDate = completedDate
        self.plannedDate = plannedDate
        self.calendarEventId = calendarEventId
        self.isUserAdded = isUserAdded
        self.attachedResources = attachedResources
        self.notes = notes
        self.recurrenceRule = recurrenceRule
        self.labelId = labelId
    }
}

public enum StepType: String, Codable, CaseIterable {
    case video = "Video / Playlist"
    case webModule = "Web-Modul / Portal"
    case examSimulation = "Prüfungssimulation"
    case handsOnLab = "Praxis-Lab / CLI"
    case reading = "Skript / Fachliteratur"
    case certification = "Zertifizierung"
    case milestone = "Meilenstein"
    case administrative = "Verwaltung / Antrag"

    public var systemImage: String {
        switch self {
        case .video:
            return "play.rectangle.fill"
        case .webModule:
            return "globe"
        case .examSimulation:
            return "checkmark.shield.fill"
        case .handsOnLab:
            return "terminal.fill"
        case .reading:
            return "book.closed.fill"
        case .certification:
            return "rosette"
        case .milestone:
            return "flag.fill"
        case .administrative:
            return "doc.text.fill"
        }
    }
}

public enum StepStatus: String, Codable {
    case locked = "Gesperrt"
    case available = "Verfügbar"
    case inProgress = "In Bearbeitung"
    case completed = "Abgeschlossen"
}

public struct RoadmapSubtask: Identifiable, Codable, Equatable {
    public var id: String
    public var text: String
    public var isDone: Bool

    public init(id: String = UUID().uuidString, text: String, isDone: Bool = false) {
        self.id = id
        self.text = text
        self.isDone = isDone
    }
}

public struct StepResource: Identifiable, Codable, Equatable {
    public var id: String
    public var title: String
    public var url: String
    public var type: String
    public var badge: String?
    public var isUserAdded: Bool?

    public init(id: String = UUID().uuidString, title: String, url: String, type: String = "Web", badge: String? = nil, isUserAdded: Bool? = false) {
        self.id = id
        self.title = title
        self.url = url
        self.type = type
        self.badge = badge
        self.isUserAdded = isUserAdded
    }
}

public struct StepCustomizationRecord: Codable {
    public var customSubmodules: [StudySubmodule]
    public var customResources: [StepResource]

    public init(customSubmodules: [StudySubmodule] = [], customResources: [StepResource] = []) {
        self.customSubmodules = customSubmodules
        self.customResources = customResources
    }
}

public struct RoadmapStep: Identifiable, Codable, Equatable {
    public var id: String
    public var track: StudyTrack
    public var phase: String
    public var sequenceNumber: Int
    public var title: String
    public var subtitle: String
    public var type: StepType
    public var estimatedHours: Double
    public var estimatedMinutes: Int
    public var category: String
    public var difficulty: String
    public var certBadge: String?
    public var primaryURL: String?
    public var secondaryURL: String?
    public var prerequisiteIds: [String]
    public var learningGoals: [String]
    public var subtasks: [RoadmapSubtask]
    public var submodules: [StudySubmodule]
    public var resources: [StepResource]
    public var notes: String
    public var isCompleted: Bool
    public var completedDate: Date?
    public var plannedDate: Date?
    public var calendarEventId: String?
    public var recurrenceRule: CustomRecurrenceRule?
    public var labelId: String?

    public init(
        id: String = UUID().uuidString,
        track: StudyTrack,
        phase: String = "",
        sequenceNumber: Int,
        title: String,
        subtitle: String,
        type: StepType,
        estimatedHours: Double = 5.0,
        estimatedMinutes: Int = 25,
        category: String = "",
        difficulty: String = "Intermediate",
        certBadge: String? = nil,
        primaryURL: String? = nil,
        secondaryURL: String? = nil,
        prerequisiteIds: [String] = [],
        learningGoals: [String] = [],
        subtasks: [RoadmapSubtask] = [],
        submodules: [StudySubmodule] = [],
        resources: [StepResource] = [],
        notes: String = "",
        isCompleted: Bool = false,
        completedDate: Date? = nil,
        plannedDate: Date? = nil,
        calendarEventId: String? = nil,
        recurrenceRule: CustomRecurrenceRule? = nil,
        labelId: String? = nil
    ) {
        self.id = id
        self.track = track
        self.phase = phase
        self.sequenceNumber = sequenceNumber
        self.title = title
        self.subtitle = subtitle
        self.type = type
        self.estimatedHours = estimatedHours
        self.estimatedMinutes = estimatedMinutes
        self.category = category
        self.difficulty = difficulty
        self.certBadge = certBadge
        self.primaryURL = primaryURL
        self.secondaryURL = secondaryURL
        self.prerequisiteIds = prerequisiteIds
        self.learningGoals = learningGoals
        self.subtasks = subtasks
        self.submodules = submodules
        self.resources = resources
        self.notes = notes
        self.isCompleted = isCompleted
        self.completedDate = completedDate
        self.plannedDate = plannedDate
        self.calendarEventId = calendarEventId
        self.recurrenceRule = recurrenceRule
        self.labelId = labelId
    }
}

// MARK: - Task Color Label (Farb-Labels nach Google Tasks & Calendar Standard)
public struct TaskColorLabel: Identifiable, Codable, Equatable, Hashable {
    public var id: String
    public var name: String
    public var colorHex: String

    public init(id: String = UUID().uuidString, name: String, colorHex: String) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
    }
}

public struct StoicQuote: Identifiable, Codable {
    public var id: String
    public var quote: String
    public var author: String
    public var category: String

    public init(
        id: String = UUID().uuidString,
        quote: String,
        author: String,
        category: String
    ) {
        self.id = id
        self.quote = quote
        self.author = author
        self.category = category
    }
}

// MARK: - Study Folder (Gruppierung mehrerer Aufgabenlisten / Phasen)
public struct StudyFolder: Identifiable, Codable, Equatable, Hashable {
    public var id: String
    public var name: String
    public var listNames: [String] // Zugeordnete Phasen-/Listen-Namen
    public var colorHex: String?

    public init(
        id: String = UUID().uuidString,
        name: String,
        listNames: [String] = [],
        colorHex: String? = nil
    ) {
        self.id = id
        self.name = name
        self.listNames = listNames
        self.colorHex = colorHex
    }
}
