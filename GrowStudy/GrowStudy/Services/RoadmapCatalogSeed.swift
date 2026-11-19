import Foundation

public struct RoadmapCatalogSeed {
    public static func defaultSteps() -> [RoadmapStep] {
        var steps: [RoadmapStep] = []

        // MARK: - B.Sc. Wirtschaftsinformatik (HsH) & BFD Roadmap
        // Phase 0: OMB+ Mathematik & Wirtschaftsinformatik Vorbereitung (Nov 2026 – Feb 2027)
        steps.append(RoadmapStep(
            id: "winf-mintfit-diagnostic",
            track: .wirtschaftsinformatik,
            phase: "Phase 0: OMB+ Mathematik & Vorbereitung",
            sequenceNumber: 0,
            title: "MINTFIT Mathe Eingangstests (Diagnose & Einstufung)",
            subtitle: "Orientierungstest der Hamburger Hochschulen (Teil 1: Grundwissen & Teil 2: Oberstufenwissen) zur Kalibrierung des Vorbereitungsplans.",
            type: .examSimulation,
            estimatedHours: 2,
            estimatedMinutes: 90,
            category: "Diagnostik & Einstufung",
            difficulty: "Beginner",
            certBadge: "MINTFIT",
            primaryURL: "https://tests.mintfit.hamburg/mod/quiz/view.php?id=160",
            secondaryURL: "https://tests.mintfit.hamburg/mod/quiz/view.php?id=161",
            prerequisiteIds: [],
            learningGoals: [
                "Diagnose des Schulwissens (Bruchrechnung, Potenzen, Wurzeln, Gleichungen)",
                "Standortbestimmung Oberstufe (Funktionen, Differentialrechnung, Vektorrechnung)",
                "Zielgerichtete Stofffokussierung für die 8 OMB+ Module"
            ],
            subtasks: [
                RoadmapSubtask(id: "mintfit-st-1", text: "Teil 1 (Grundwissen) absolvieren & auswerten", isDone: true),
                RoadmapSubtask(id: "mintfit-st-2", text: "Teil 2 (Oberstufenwissen) absolvieren", isDone: false)
            ],
            submodules: [
                StudySubmodule(
                    id: "mintfit-math-1",
                    title: "MINTFIT Mathe Eingangstest Teil 1: Grundwissen",
                    type: .examDrill,
                    url: "https://tests.mintfit.hamburg/mod/quiz/view.php?id=160",
                    durationMinutes: 45,
                    isCompleted: true,
                    completedDate: Date()
                ),
                StudySubmodule(
                    id: "mintfit-math-2",
                    title: "MINTFIT Mathe Eingangstest Teil 2: Oberstufenwissen",
                    type: .examDrill,
                    url: "https://tests.mintfit.hamburg/mod/quiz/view.php?id=161",
                    durationMinutes: 45,
                    isCompleted: false,
                    plannedDate: Calendar.current.date(bySettingHour: 17, minute: 0, second: 0, of: Date())
                )
            ],
            resources: [
                StepResource(id: "mintfit-res-1", title: "MINTFIT Mathe Test Teil 1", url: "https://tests.mintfit.hamburg/mod/quiz/view.php?id=160", type: "Web-Portal"),
                StepResource(id: "mintfit-res-2", title: "MINTFIT Mathe Test Teil 2", url: "https://tests.mintfit.hamburg/mod/quiz/view.php?id=161", type: "Web-Portal")
            ],
            notes: "Orientierungstest für den Einstieg in WInf an der Hochschule Hannover (HsH).",
            isCompleted: false
        ))

        steps.append(RoadmapStep(
            id: "winf-omb-1a",
            track: .wirtschaftsinformatik,
            phase: "Phase 0: OMB+ Mathematik & Vorbereitung",
            sequenceNumber: 1,
            title: "OMB+ Kap. ⅠA: Elementares Rechnen (Mengen & Zahlen)",
            subtitle: "Mengen, Zahlen, Grundrechenarten, Ordnung, Intervalle, Dezimalzahlen, Rechenregeln, Brüche & Schlussprüfung.",
            type: .webModule,
            estimatedHours: 12,
            estimatedMinutes: 60,
            category: "OMB+ Mathematik",
            difficulty: "Beginner",
            certBadge: "OMB+ ⅠA",
            primaryURL: "https://www.ombplus.de/ombplus/semiprotected/course/start",
            prerequisiteIds: [],
            learningGoals: [],
            subtasks: [
                RoadmapSubtask(id: "omb-1a-st-1", text: "Mengen, Zahlen & Grundrechenarten (Natürliche, ganze & rationale Zahlen)", isDone: false),
                RoadmapSubtask(id: "omb-1a-st-2", text: "Ordnung, Intervalle & Dezimalzahlen auf dem Zahlenstrahl", isDone: false),
                RoadmapSubtask(id: "omb-1a-st-3", text: "Rechenregeln: Punkt vor Strich, Distributivgesetz & Klammerauflösung", isDone: false),
                RoadmapSubtask(id: "omb-1a-st-4", text: "Bruchrechnung: Erweitern, Kürzen, Hauptnenner & Kehrwert-Division", isDone: false),
                RoadmapSubtask(id: "omb-1a-st-5", text: "Schlussprüfung ⅠA (Mindestens 80% für Zertifikatsreife)", isDone: false)
            ],
            submodules: [
                StudySubmodule(id: "omb-1a-sm-1", title: "Mengen, Zahlen & Grundrechenarten (Artikel & Training)", type: .webModule, url: "https://www.ombplus.de/ombplus/semiprotected/course/start", durationMinutes: 30, isCompleted: false),
                StudySubmodule(id: "omb-1a-sm-2", title: "Bruchrechnung & Rechenregeln (Training & Quiz)", type: .webModule, url: "https://www.ombplus.de/ombplus/semiprotected/course/start", durationMinutes: 35, isCompleted: false),
                StudySubmodule(id: "omb-1a-sm-3", title: "Schlussprüfung ⅠA: Elementares Rechnen", type: .examDrill, url: "https://www.ombplus.de/ombplus/semiprotected/course/start", durationMinutes: 45, isCompleted: false)
            ],
            resources: [
                StepResource(id: "omb-1a-res-1", title: "OMB+ Kursübersicht", url: "https://www.ombplus.de/ombplus/semiprotected/course/start", type: "Web-Portal"),
                StepResource(id: "omb-1a-res-2", title: "VE&MINT Ergänzungsportal", url: "https://www.ve-mint.de/", type: "Web-Portal")
            ],
            notes: "Eingeloggt als Parris Nkembi (UID 155396). 100% interaktiv mit sofortiger Aufgabenkorrektur.",
            isCompleted: false
        ))

        steps.append(RoadmapStep(
            id: "winf-omb-1b",
            track: .wirtschaftsinformatik,
            phase: "Phase 0: OMB+ Mathematik & Vorbereitung",
            sequenceNumber: 2,
            title: "OMB+ Kap. ⅠB: Potenzen, Wurzeln & Dreisatz",
            subtitle: "Potenzgesetze, Wurzelrechnung, Proportionalität, Dreisatz, Prozent- und Zinsrechnung für die BWL.",
            type: .webModule,
            estimatedHours: 14,
            estimatedMinutes: 60,
            category: "OMB+ Mathematik",
            difficulty: "Beginner",
            certBadge: "OMB+ ⅠB",
            primaryURL: "https://www.ombplus.de/ombplus/semiprotected/course/start",
            prerequisiteIds: ["winf-omb-1a"],
            learningGoals: [],
            subtasks: [
                RoadmapSubtask(id: "omb-1b-st-1", text: "Potenzgesetze: Gleiche Basis, gleiche Exponenten & Potenzen potenzieren", isDone: false),
                RoadmapSubtask(id: "omb-1b-st-2", text: "Wurzeln & Potenzen mit rationalen Exponenten", isDone: false),
                RoadmapSubtask(id: "omb-1b-st-3", text: "Rechnen mit Wurzeln & Rationalmachen des Nenners", isDone: false),
                RoadmapSubtask(id: "omb-1b-st-4", text: "Proportionalität & Dreisatz (Direkt und indirekt)", isDone: false),
                RoadmapSubtask(id: "omb-1b-st-5", text: "Prozentrechnung & Zinsrechnung (Vorbereitung Finanzmathematik)", isDone: false),
                RoadmapSubtask(id: "omb-1b-st-6", text: "Schlussprüfung ⅠB (Mindestens 80% für Zertifikatsreife)", isDone: false)
            ],
            submodules: [
                StudySubmodule(id: "omb-1b-sm-1", title: "Potenzen & Wurzelgesetze (Training & Quiz)", type: .webModule, url: "https://www.ombplus.de/ombplus/semiprotected/course/start", durationMinutes: 35, isCompleted: false),
                StudySubmodule(id: "omb-1b-sm-2", title: "Dreisatz, Prozent- & Zinsrechnung (Training)", type: .webModule, url: "https://www.ombplus.de/ombplus/semiprotected/course/start", durationMinutes: 35, isCompleted: false),
                StudySubmodule(id: "omb-1b-sm-3", title: "Schlussprüfung ⅠB: Potenzen & Proportionalität", type: .examDrill, url: "https://www.ombplus.de/ombplus/semiprotected/course/start", durationMinutes: 45, isCompleted: false)
            ],
            resources: [
                StepResource(id: "omb-1b-res-1", title: "OMB+ Kursseite", url: "https://www.ombplus.de/ombplus/semiprotected/course/start", type: "Web-Portal")
            ],
            notes: "Zinsrechnung ist Kernbaustein für die ersten Semester Wirtschaftsinformatik.",
            isCompleted: false
        ))

        steps.append(RoadmapStep(
            id: "winf-omb-2",
            track: .wirtschaftsinformatik,
            phase: "Phase 0: OMB+ Mathematik & Vorbereitung",
            sequenceNumber: 3,
            title: "OMB+ Kap. Ⅱ: Gleichungen in einer Unbekannten",
            subtitle: "Aussagen, lineare & quadratische Gleichungen, Faktorisieren, Wurzel-, Bruch- und Logarithmusgleichungen.",
            type: .webModule,
            estimatedHours: 15,
            estimatedMinutes: 60,
            category: "OMB+ Mathematik",
            difficulty: "Beginner",
            certBadge: "OMB+ Ⅱ",
            primaryURL: "https://www.ombplus.de/ombplus/semiprotected/course/start",
            prerequisiteIds: ["winf-omb-1b"],
            learningGoals: [],
            subtasks: [
                RoadmapSubtask(id: "omb-2-st-1", text: "Aussagen, Folgerungen, Äquivalenz & Lösungsmengen", isDone: false),
                RoadmapSubtask(id: "omb-2-st-2", text: "Lineare & quadratische Gleichungen (p/q-Formel)", isDone: false),
                RoadmapSubtask(id: "omb-2-st-3", text: "Gleichungen lösen durch Faktorisieren (Satz vom Nullprodukt)", isDone: false),
                RoadmapSubtask(id: "omb-2-st-4", text: "Wurzelgleichungen & Bruchgleichungen (Definitionsmenge bestimmen)", isDone: false),
                RoadmapSubtask(id: "omb-2-st-5", text: "Betragsgleichungen & Exponential-/Logarithmusgleichungen", isDone: false),
                RoadmapSubtask(id: "omb-2-st-6", text: "Schlussprüfung Ⅱ (Mindestens 80% für Zertifikatsreife)", isDone: false)
            ],
            submodules: [
                StudySubmodule(id: "omb-2-sm-1", title: "Lineare & Quadratische Gleichungen (Training)", type: .webModule, url: "https://www.ombplus.de/ombplus/semiprotected/course/start", durationMinutes: 35, isCompleted: false),
                StudySubmodule(id: "omb-2-sm-2", title: "Bruch-, Wurzel- & Logarithmusgleichungen (Quiz)", type: .webModule, url: "https://www.ombplus.de/ombplus/semiprotected/course/start", durationMinutes: 40, isCompleted: false),
                StudySubmodule(id: "omb-2-sm-3", title: "Schlussprüfung Ⅱ: Gleichungen in einer Unbekannten", type: .examDrill, url: "https://www.ombplus.de/ombplus/semiprotected/course/start", durationMinutes: 45, isCompleted: false)
            ],
            resources: [
                StepResource(id: "omb-2-res-1", title: "OMB+ Kursseite", url: "https://www.ombplus.de/ombplus/semiprotected/course/start", type: "Web-Portal")
            ],
            notes: "Satz vom Nullprodukt spart enorme Rechenzeit bei Prüfungen.",
            isCompleted: false
        ))

        steps.append(RoadmapStep(
            id: "winf-omb-3",
            track: .wirtschaftsinformatik,
            phase: "Phase 0: OMB+ Mathematik & Vorbereitung",
            sequenceNumber: 4,
            title: "OMB+ Kap. Ⅲ: Ungleichungen in einer Variablen",
            subtitle: "Lineare Ungleichungen, Vorzeichenwechsel, quadratische Ungleichungen, Beträge & Bruchungleichungen.",
            type: .webModule,
            estimatedHours: 10,
            estimatedMinutes: 50,
            category: "OMB+ Mathematik",
            difficulty: "Intermediate",
            certBadge: "OMB+ Ⅲ",
            primaryURL: "https://www.ombplus.de/ombplus/semiprotected/course/start",
            prerequisiteIds: ["winf-omb-2"],
            learningGoals: [],
            subtasks: [
                RoadmapSubtask(id: "omb-3-st-1", text: "Lineare Ungleichungen & Umkehrung des Relationszeichens bei Negation", isDone: false),
                RoadmapSubtask(id: "omb-3-st-2", text: "Quadratische Ungleichungen (Vorzeichentabellen)", isDone: false),
                RoadmapSubtask(id: "omb-3-st-3", text: "Betrag und Brüche in Ungleichungen (Fallunterscheidungen)", isDone: false),
                RoadmapSubtask(id: "omb-3-st-4", text: "Schlussprüfung Ⅲ (Mindestens 80% für Zertifikatsreife)", isDone: false)
            ],
            submodules: [
                StudySubmodule(id: "omb-3-sm-1", title: "Lineare & Quadratische Ungleichungen (Training)", type: .webModule, url: "https://www.ombplus.de/ombplus/semiprotected/course/start", durationMinutes: 30, isCompleted: false),
                StudySubmodule(id: "omb-3-sm-2", title: "Betrags- und Bruchungleichungen (Quiz)", type: .webModule, url: "https://www.ombplus.de/ombplus/semiprotected/course/start", durationMinutes: 35, isCompleted: false),
                StudySubmodule(id: "omb-3-sm-3", title: "Schlussprüfung Ⅲ: Ungleichungen in einer Variablen", type: .examDrill, url: "https://www.ombplus.de/ombplus/semiprotected/course/start", durationMinutes: 40, isCompleted: false)
            ],
            resources: [
                StepResource(id: "omb-3-res-1", title: "OMB+ Kursseite", url: "https://www.ombplus.de/ombplus/semiprotected/course/start", type: "Web-Portal")
            ],
            notes: "Unerlässlich für Nebenbedingungen in der Linearen Optimierung.",
            isCompleted: false
        ))

        steps.append(RoadmapStep(
            id: "winf-omb-4",
            track: .wirtschaftsinformatik,
            phase: "Phase 0: OMB+ Mathematik & Vorbereitung",
            sequenceNumber: 5,
            title: "OMB+ Kap. Ⅳ: Lineare Gleichungssysteme (LGS)",
            subtitle: "Additionsverfahren, graphische Interpretation, Gauß-Algorithmus & parameterabhängige Systeme.",
            type: .webModule,
            estimatedHours: 15,
            estimatedMinutes: 60,
            category: "OMB+ Mathematik",
            difficulty: "Intermediate",
            certBadge: "OMB+ Ⅳ",
            primaryURL: "https://www.ombplus.de/ombplus/semiprotected/course/start",
            prerequisiteIds: ["winf-omb-2"],
            learningGoals: [],
            subtasks: [
                RoadmapSubtask(id: "omb-4-st-1", text: "Additions-, Einsetzungs- & Gleichsetzungsverfahren", isDone: false),
                RoadmapSubtask(id: "omb-4-st-2", text: "Graphische Interpretation & Lösbarkeitskriterien (1, 0, unendlich Lösungen)", isDone: false),
                RoadmapSubtask(id: "omb-4-st-3", text: "Das Gauß-Verfahren (Stufenform für 3x3 Matrizen)", isDone: false),
                RoadmapSubtask(id: "omb-4-st-4", text: "Parameterabhängige LGS (Vorstufe zu Produktionsmodellen)", isDone: false),
                RoadmapSubtask(id: "omb-4-st-5", text: "Schlussprüfung Ⅳ (Mindestens 80% für Zertifikatsreife)", isDone: false)
            ],
            submodules: [
                StudySubmodule(id: "omb-4-sm-1", title: "LGS Lösungsverfahren & Graphik (Training)", type: .webModule, url: "https://www.ombplus.de/ombplus/semiprotected/course/start", durationMinutes: 35, isCompleted: false),
                StudySubmodule(id: "omb-4-sm-2", title: "Das Gaußsche Eliminationsverfahren (Quiz)", type: .webModule, url: "https://www.ombplus.de/ombplus/semiprotected/course/start", durationMinutes: 40, isCompleted: false),
                StudySubmodule(id: "omb-4-sm-3", title: "Schlussprüfung Ⅳ: Lineare Gleichungssysteme", type: .examDrill, url: "https://www.ombplus.de/ombplus/semiprotected/course/start", durationMinutes: 45, isCompleted: false)
            ],
            resources: [
                StepResource(id: "omb-4-res-1", title: "OMB+ Kursseite", url: "https://www.ombplus.de/ombplus/semiprotected/course/start", type: "Web-Portal")
            ],
            notes: "Gauß-Verfahren ist die direkte Grundlage für Wirtschaftsmathematik & OR.",
            isCompleted: false
        ))

        steps.append(RoadmapStep(
            id: "winf-omb-6",
            track: .wirtschaftsinformatik,
            phase: "Phase 0: OMB+ Mathematik & Vorbereitung",
            sequenceNumber: 6,
            title: "OMB+ Kap. Ⅵ: Elementare Funktionen & Ökonomie",
            subtitle: "Eigenschaften elementarer Funktionen, Polynome, Exponential-, Logarithmusfunktionen & Break-Even-Analyse.",
            type: .webModule,
            estimatedHours: 16,
            estimatedMinutes: 60,
            category: "OMB+ Mathematik",
            difficulty: "Intermediate",
            certBadge: "OMB+ Ⅵ",
            primaryURL: "https://www.ombplus.de/ombplus/semiprotected/course/start",
            prerequisiteIds: ["winf-omb-4"],
            learningGoals: [],
            subtasks: [
                RoadmapSubtask(id: "omb-6-st-1", text: "Eigenschaften elementarer Funktionen (Definitionsbereich, Symmetrie)", isDone: false),
                RoadmapSubtask(id: "omb-6-st-2", text: "Lineare Funktionen & Polynome (Kosten- & Preisfunktionen)", isDone: false),
                RoadmapSubtask(id: "omb-6-st-3", text: "Exponential- und Logarithmusfunktionen (Zinseszins & Wachstum)", isDone: false),
                RoadmapSubtask(id: "omb-6-st-4", text: "Umkehrfunktionen & Verkettung", isDone: false),
                RoadmapSubtask(id: "omb-6-st-5", text: "Ökonomische Funktionen: K(x), E(x), G(x) und Break-Even-Point", isDone: false),
                RoadmapSubtask(id: "omb-6-st-6", text: "Schlussprüfung Ⅵ (Mindestens 80% für Zertifikatsreife)", isDone: false)
            ],
            submodules: [
                StudySubmodule(id: "omb-6-sm-1", title: "Eigenschaften elementarer Funktionen (Training)", type: .webModule, url: "https://www.ombplus.de/ombplus/semiprotected/course/start", durationMinutes: 35, isCompleted: false),
                StudySubmodule(id: "omb-6-sm-2", title: "Polynome, Exponential- & Logarithmusfunktionen (Quiz)", type: .webModule, url: "https://www.ombplus.de/ombplus/semiprotected/course/start", durationMinutes: 40, isCompleted: false),
                StudySubmodule(id: "omb-6-sm-3", title: "Schlussprüfung Ⅵ: Elementare Funktionen", type: .examDrill, url: "https://www.ombplus.de/ombplus/semiprotected/course/start", durationMinutes: 45, isCompleted: false)
            ],
            resources: [
                StepResource(id: "omb-6-res-1", title: "OMB+ Kursseite", url: "https://www.ombplus.de/ombplus/semiprotected/course/start", type: "Web-Portal")
            ],
            notes: "Direkte betriebswirtschaftliche Anwendung der Wirtschaftsmathematik.",
            isCompleted: false
        ))

        steps.append(RoadmapStep(
            id: "winf-omb-7",
            track: .wirtschaftsinformatik,
            phase: "Phase 0: OMB+ Mathematik & Vorbereitung",
            sequenceNumber: 7,
            title: "OMB+ Kap. Ⅶ: Differenzialrechnung & Gewinnmaximierung",
            subtitle: "Ableitungsbegriff, Ableitungsregeln, Kurvendiskussion, Extremwerte & Gewinnmaximum (G'(x) = 0).",
            type: .webModule,
            estimatedHours: 18,
            estimatedMinutes: 60,
            category: "OMB+ Mathematik",
            difficulty: "Advanced",
            certBadge: "OMB+ Ⅶ",
            primaryURL: "https://www.ombplus.de/ombplus/semiprotected/course/start",
            prerequisiteIds: ["winf-omb-6"],
            learningGoals: [],
            subtasks: [
                RoadmapSubtask(id: "omb-7-st-1", text: "Ableitungsbegriff (Sekante, Tangente, lokale Änderungsrate)", isDone: false),
                RoadmapSubtask(id: "omb-7-st-2", text: "Ableitungsregeln: Potenz-, Faktor-, Summen-, Produkt- & Kettenregel", isDone: false),
                RoadmapSubtask(id: "omb-7-st-3", text: "Höhere Ableitungen & Krümmungsverhalten", isDone: false),
                RoadmapSubtask(id: "omb-7-st-4", text: "Kurvendiskussion: Nullstellen, Hochpunkte, Tiefpunkte & Wendepunkte", isDone: false),
                RoadmapSubtask(id: "omb-7-st-5", text: "Gewinnmaximierung: G'(x) = 0 und Grenzkosten K'(x)", isDone: false),
                RoadmapSubtask(id: "omb-7-st-6", text: "Schlussprüfung Ⅶ (Mindestens 80% für Zertifikatsreife)", isDone: false)
            ],
            submodules: [
                StudySubmodule(id: "omb-7-sm-1", title: "Ableitungsregeln & Differenzieren (Training)", type: .webModule, url: "https://www.ombplus.de/ombplus/semiprotected/course/start", durationMinutes: 40, isCompleted: false),
                StudySubmodule(id: "omb-7-sm-2", title: "Kurvendiskussion & Extremwertprobleme (Quiz)", type: .webModule, url: "https://www.ombplus.de/ombplus/semiprotected/course/start", durationMinutes: 40, isCompleted: false),
                StudySubmodule(id: "omb-7-sm-3", title: "Schlussprüfung Ⅶ: Differenzialrechnung", type: .examDrill, url: "https://www.ombplus.de/ombplus/semiprotected/course/start", durationMinutes: 50, isCompleted: false)
            ],
            resources: [
                StepResource(id: "omb-7-res-1", title: "OMB+ Kursseite", url: "https://www.ombplus.de/ombplus/semiprotected/course/start", type: "Web-Portal")
            ],
            notes: "Klausurrelevant für HsH Wirtschaftsmathematik im 1. Semester.",
            isCompleted: false
        ))

        steps.append(RoadmapStep(
            id: "winf-omb-12",
            track: .wirtschaftsinformatik,
            phase: "Phase 0: OMB+ Mathematik & Vorbereitung",
            sequenceNumber: 8,
            title: "OMB+ Zusatzmodul Ⅻ: Logik, Wahrheitstafeln & Mengen",
            subtitle: "Aussagenlogik, Wahrheitstafeln, Implikation, Quantoren und Mengenlehre (Fundament für Software & Daten).",
            type: .webModule,
            estimatedHours: 12,
            estimatedMinutes: 50,
            category: "OMB+ Informatik",
            difficulty: "Intermediate",
            certBadge: "OMB+ Ⅻ",
            primaryURL: "https://www.ombplus.de/ombplus/semiprotected/course/start",
            prerequisiteIds: ["winf-omb-1a"],
            learningGoals: [],
            subtasks: [
                RoadmapSubtask(id: "omb-12-st-1", text: "Aussagenlogik & Wahrheitstafeln (AND, OR, NOT, XOR)", isDone: false),
                RoadmapSubtask(id: "omb-12-st-2", text: "Implikation, Äquivalenz & Quantoren (Allquantor, Existenzquantor)", isDone: false),
                RoadmapSubtask(id: "omb-12-st-3", text: "Mathematische Beweisformen (Direkt und Widerspruch)", isDone: false),
                RoadmapSubtask(id: "omb-12-st-4", text: "Mengenlehre: Schnitt, Vereinigung, Komplement & Teilmengen", isDone: false),
                RoadmapSubtask(id: "omb-12-st-5", text: "Schlussprüfung Ⅻ (Mindestens 80% für Zertifikatsreife)", isDone: false)
            ],
            submodules: [
                StudySubmodule(id: "omb-12-sm-1", title: "Aussagen, Wahrheitstafeln & Implikation (Training)", type: .webModule, url: "https://www.ombplus.de/ombplus/semiprotected/course/start", durationMinutes: 35, isCompleted: false),
                StudySubmodule(id: "omb-12-sm-2", title: "Mengen, Quantoren & Beweise (Quiz)", type: .webModule, url: "https://www.ombplus.de/ombplus/semiprotected/course/start", durationMinutes: 35, isCompleted: false),
                StudySubmodule(id: "omb-12-sm-3", title: "Schlussprüfung Ⅻ: Logik und Mengen", type: .examDrill, url: "https://www.ombplus.de/ombplus/semiprotected/course/start", durationMinutes: 45, isCompleted: false)
            ],
            resources: [
                StepResource(id: "omb-12-res-1", title: "OMB+ Kursseite", url: "https://www.ombplus.de/ombplus/semiprotected/course/start", type: "Web-Portal")
            ],
            notes: "Zentrales Bindeglied zwischen Mathematik und Informatik (Boolesche Algebra).",
            isCompleted: false
        ))

        steps.append(RoadmapStep(
            id: "winf-p0-scrum",
            track: .wirtschaftsinformatik,
            phase: "Phase 0: Wirtschaftsinformatik Vorbereitung",
            sequenceNumber: 9,
            title: "Agiles Projektmanagement & Scrum Guide (PSM I)",
            subtitle: "Scrum-Werte, Rollen (Product Owner, Scrum Master, Developer), Events & Artefakte zur Vorbereitung auf BFD Lehrgang Nr. 428.",
            type: .reading,
            estimatedHours: 25,
            estimatedMinutes: 45,
            category: "Agilität & Management",
            difficulty: "Beginner",
            certBadge: "PSM I",
            primaryURL: "https://www.scrumguides.org/",
            prerequisiteIds: [],
            learningGoals: [],
            subtasks: [
                RoadmapSubtask(id: "scrum-1", text: "Scrum Guide 2020 durcharbeiten: 3 Rollen, 5 Events, 3 Artefakte", isDone: false),
                RoadmapSubtask(id: "scrum-2", text: "Verantwortungsteilung verinnerlichen: Product Goal vs Sprint Goal", isDone: false),
                RoadmapSubtask(id: "scrum-3", text: "Scrum Open Assessment auf Scrum.org mit >90% bestehen", isDone: false)
            ],
            submodules: [
                StudySubmodule(id: "scrum-sm-1", title: "Offizieller Scrum Guide 2020 (PDF & Web)", type: .readingChapter, url: "https://www.scrumguides.org/", durationMinutes: 30, isCompleted: false),
                StudySubmodule(id: "scrum-sm-2", title: "Scrum.org Open Assessment Practice", type: .examDrill, url: "https://www.scrum.org/open-assessments", durationMinutes: 30, isCompleted: false)
            ],
            resources: [
                StepResource(id: "scrum-res-1", title: "Scrum Guides Portal", url: "https://www.scrumguides.org/", type: "Documentation"),
                StepResource(id: "scrum-res-2", title: "Scrum.org Open Assessments", url: "https://www.scrum.org/open-assessments", type: "Practice")
            ],
            notes: "Grundlage für BFD-Zertifikat Nr. 428 im April 2027.",
            isCompleted: false
        ))

        steps.append(RoadmapStep(
            id: "winf-p0-python-sql",
            track: .wirtschaftsinformatik,
            phase: "Phase 0: Wirtschaftsinformatik Vorbereitung",
            sequenceNumber: 10,
            title: "Programmieren & SQL-Datenbanken via Mimo",
            subtitle: "Grundlagen Algorithmen & Kontrollstrukturen in Python sowie relationale Datenbankabfragen (SQL).",
            type: .handsOnLab,
            estimatedHours: 35,
            estimatedMinutes: 60,
            category: "Software & Daten",
            difficulty: "Beginner",
            certBadge: "Python/SQL",
            primaryURL: "https://mimo.org/",
            prerequisiteIds: [],
            learningGoals: [],
            subtasks: [
                RoadmapSubtask(id: "py-sql-1", text: "Mimo Python Pfad: Variablen, Listen, Schleifen, Funktionen & I/O", isDone: false),
                RoadmapSubtask(id: "py-sql-2", text: "Mimo SQL Pfad: SELECT, WHERE, JOINs (INNER/LEFT), GROUP BY, HAVING", isDone: false),
                RoadmapSubtask(id: "py-sql-3", text: "SQLBolt: Interaktive Lektionen 1 bis 18 fehlerfrei lösen", isDone: false)
            ],
            submodules: [
                StudySubmodule(id: "pysql-sm-1", title: "Mimo App: Python & SQL Lernpfad", type: .webModule, url: "https://mimo.org/", durationMinutes: 30, isCompleted: false),
                StudySubmodule(id: "pysql-sm-2", title: "SQLBolt: Interaktives SQL Tutorial", type: .webModule, url: "https://sqlbolt.com/", durationMinutes: 30, isCompleted: false)
            ],
            resources: [
                StepResource(id: "pysql-res-1", title: "Mimo Web App", url: "https://mimo.org/", type: "Interactive"),
                StepResource(id: "pysql-res-2", title: "SQLBolt Übungen", url: "https://sqlbolt.com/", type: "Interactive")
            ],
            notes: "Bereitet auf Softwareentwicklung und Datenbanksysteme an der HsH vor.",
            isCompleted: false
        ))

        steps.append(RoadmapStep(
            id: "winf-p0-sap-erp",
            track: .wirtschaftsinformatik,
            phase: "Phase 0: Wirtschaftsinformatik Vorbereitung",
            sequenceNumber: 11,
            title: "Geschäftsprozesse & ERP-Systeme (SAP & BPMN)",
            subtitle: "Prozessmodellierung nach BPMN 2.0 und Überblick über ERP-Kernmodule (SAP S/4HANA).",
            type: .handsOnLab,
            estimatedHours: 25,
            estimatedMinutes: 45,
            category: "Geschäftsprozesse",
            difficulty: "Beginner",
            certBadge: "ERP/BPMN",
            primaryURL: "https://bpmn.io/",
            prerequisiteIds: [],
            learningGoals: [],
            subtasks: [
                RoadmapSubtask(id: "erp-1", text: "BPMN 2.0 Elemente: Pools, Lanes, Tasks, XOR/AND Gateways", isDone: false),
                RoadmapSubtask(id: "erp-2", text: "Eigenen Beschaffungsprozess auf bpmn.io modellieren und exportieren", isDone: false),
                RoadmapSubtask(id: "erp-3", text: "ERP-Architektur: Stammdaten vs Bewegungsdaten in SAP S/4HANA", isDone: false)
            ],
            submodules: [
                StudySubmodule(id: "erp-sm-1", title: "bpmn.io Interaktiver Prozess-Modellierer", type: .webModule, url: "https://bpmn.io/", durationMinutes: 30, isCompleted: false),
                StudySubmodule(id: "erp-sm-2", title: "SAP Learning Hub Basics", type: .webModule, url: "https://learning.sap.com/", durationMinutes: 30, isCompleted: false)
            ],
            resources: [
                StepResource(id: "erp-res-1", title: "BPMN.io Modeler", url: "https://bpmn.io/", type: "Tool"),
                StepResource(id: "erp-res-2", title: "SAP Learning Portal", url: "https://learning.sap.com/", type: "Documentation")
            ],
            notes: "Direktes Fundament für BFD Lehrgang Nr. 1179 (SAP S/4HANA) im September 2027.",
            isCompleted: false
        ))

        // Phase 1: BFD-Zertifikate 2027 (Die 7 internen Lehrgänge)
        steps.append(RoadmapStep(
            id: "winf-bfd-249",
            track: .wirtschaftsinformatik,
            phase: "Phase 1: BFD-Zertifikate 2027 (29 Freistellungstage)",
            sequenceNumber: 12,
            title: "BFD Nr. 249: Mathe Grundlagen BQ - Online",
            subtitle: "22.02. – 26.02.2027 (5 Tage Vollzeit-Freistellung): Algebra, Bruchrechnung, Gleichungen für den Hochschulstart.",
            type: .certification,
            estimatedHours: 40,
            estimatedMinutes: 120,
            category: "BFD Zertifikat",
            difficulty: "Beginner",
            certBadge: "BFD 249",
            primaryURL: "https://www.bundeswehr.de/",
            prerequisiteIds: ["winf-omb-1a", "winf-omb-1b", "winf-omb-2", "winf-omb-4"],
            learningGoals: [],
            subtasks: [
                RoadmapSubtask(id: "bfd249-1", text: "Freistellungsantrag gem. § 5 SVG beim Spieß/KpChef einreichen (Frist: Jan 2027)", isDone: false),
                RoadmapSubtask(id: "bfd249-2", text: "5 Tage Online-Unterricht absolvieren und Übungsklausur bestehen", isDone: false)
            ],
            submodules: [],
            resources: [],
            notes: "0 EUR Kosten, kein Urlaubstag beansprucht.",
            isCompleted: false
        ))

        steps.append(RoadmapStep(
            id: "winf-bfd-428",
            track: .wirtschaftsinformatik,
            phase: "Phase 1: BFD-Zertifikate 2027 (29 Freistellungstage)",
            sequenceNumber: 13,
            title: "BFD Nr. 428: Prof. Scrum Master & Product Owner",
            subtitle: "05.04. – 07.04.2027 (3 Tage): Weltweites Branchenzertifikat PSM I & PSPO via Scrum.org.",
            type: .certification,
            estimatedHours: 24,
            estimatedMinutes: 90,
            category: "BFD Zertifikat",
            difficulty: "Intermediate",
            certBadge: "PSM I",
            primaryURL: "https://www.scrum.org/",
            prerequisiteIds: ["winf-p0-scrum"],
            learningGoals: [],
            subtasks: [
                RoadmapSubtask(id: "bfd428-1", text: "Online-Lehrgang absolvieren und Prüfungsvoucher einlösen", isDone: false),
                RoadmapSubtask(id: "bfd428-2", text: "PSM I Zertifizierungsprüfung mit mindestens 85% bestehen", isDone: false)
            ],
            submodules: [],
            resources: [],
            notes: "Weltweit anerkanntes Management-Zertifikat für Wirtschaftsinformatiker.",
            isCompleted: false
        ))

        steps.append(RoadmapStep(
            id: "winf-bfd-574",
            track: .wirtschaftsinformatik,
            phase: "Phase 1: BFD-Zertifikate 2027 (29 Freistellungstage)",
            sequenceNumber: 14,
            title: "BFD Nr. 574: Softwareentwicklung - Grundlagen",
            subtitle: "26.04. – 30.04.2027 (5 Tage): Algorithmen, Datenstrukturen, Kontrollstrukturen & OOP.",
            type: .certification,
            estimatedHours: 40,
            estimatedMinutes: 120,
            category: "BFD Zertifikat",
            difficulty: "Beginner",
            certBadge: "BFD 574",
            primaryURL: "https://www.bundeswehr.de/",
            prerequisiteIds: ["winf-p0-python-sql"],
            learningGoals: [],
            subtasks: [
                RoadmapSubtask(id: "bfd574-1", text: "Grundlagen der Programmierung festigen", isDone: false),
                RoadmapSubtask(id: "bfd574-2", text: "Teilnahmezertifikat für HsH-Anerkennung sichern", isDone: false)
            ],
            submodules: [],
            resources: [],
            notes: "Optimaler Vorlauf für HsH Programmierung 1.",
            isCompleted: false
        ))

        steps.append(RoadmapStep(
            id: "winf-bfd-633",
            track: .wirtschaftsinformatik,
            phase: "Phase 1: BFD-Zertifikate 2027 (29 Freistellungstage)",
            sequenceNumber: 15,
            title: "BFD Nr. 633: Mathematik III - Vertiefung (Online)",
            subtitle: "10.05. – 14.05.2027 (5 Tage): Vertiefung Analysis, Funktionen, lineare Gleichungssysteme.",
            type: .certification,
            estimatedHours: 40,
            estimatedMinutes: 120,
            category: "BFD Zertifikat",
            difficulty: "Intermediate",
            certBadge: "BFD 633",
            primaryURL: "https://www.bundeswehr.de/",
            prerequisiteIds: ["winf-bfd-249"],
            learningGoals: [],
            subtasks: [
                RoadmapSubtask(id: "bfd633-1", text: "Analysis & Matrizenrechnung auf Hochschulniveau festigen", isDone: false),
                RoadmapSubtask(id: "bfd633-2", text: "Lehrgangszertifikat erwerben", isDone: false)
            ],
            submodules: [],
            resources: [],
            notes: "Schließt die mathematische Brücke zum Sommersemester 2028 ab.",
            isCompleted: false
        ))

        steps.append(RoadmapStep(
            id: "winf-bfd-1179",
            track: .wirtschaftsinformatik,
            phase: "Phase 1: BFD-Zertifikate 2027 (29 Freistellungstage)",
            sequenceNumber: 16,
            title: "BFD Nr. 1179: SAP S/4HANA - Grundlagen",
            subtitle: "27.09. – 01.10.2027 (5 Tage): SAP-Zertifizierung: Navigation, ERP-Module, Geschäftsprozesse.",
            type: .certification,
            estimatedHours: 40,
            estimatedMinutes: 120,
            category: "BFD Zertifikat",
            difficulty: "Intermediate",
            certBadge: "SAP S/4",
            primaryURL: "https://www.sap.com/",
            prerequisiteIds: ["winf-p0-sap-erp"],
            learningGoals: [],
            subtasks: [
                RoadmapSubtask(id: "bfd1179-1", text: "SAP S/4HANA Benutzeroberfläche & Geschäftsprozesse beherrschen", isDone: false),
                RoadmapSubtask(id: "bfd1179-2", text: "SAP-Abschlusszertifikat sichern", isDone: false)
            ],
            submodules: [],
            resources: [],
            notes: "Enormer Wettbewerbsvorteil für Werkstudentenstellen in Hannover.",
            isCompleted: false
        ))

        steps.append(RoadmapStep(
            id: "winf-bfd-1279",
            track: .wirtschaftsinformatik,
            phase: "Phase 1: BFD-Zertifikate 2027 (29 Freistellungstage)",
            sequenceNumber: 17,
            title: "BFD Nr. 1279: ITIL 4 Foundation Online",
            subtitle: "11.10. – 13.10.2027 (3 Tage): Weltweites Zertifikat: IT Service Management Best Practices.",
            type: .certification,
            estimatedHours: 24,
            estimatedMinutes: 90,
            category: "BFD Zertifikat",
            difficulty: "Intermediate",
            certBadge: "ITIL 4",
            primaryURL: "https://www.axelos.com/",
            prerequisiteIds: [],
            learningGoals: [],
            subtasks: [
                RoadmapSubtask(id: "bfd1279-1", text: "Service Value System (SVS) & 4 Dimensionen verinnerlichen", isDone: false),
                RoadmapSubtask(id: "bfd1279-2", text: "Offizielle PeopleCert ITIL 4 Foundation Prüfung bestehen", isDone: false)
            ],
            submodules: [],
            resources: [],
            notes: "Standard im IT-Betrieb und IT-Consulting.",
            isCompleted: false
        ))

        steps.append(RoadmapStep(
            id: "winf-bfd-1461",
            track: .wirtschaftsinformatik,
            phase: "Phase 1: BFD-Zertifikate 2027 (29 Freistellungstage)",
            sequenceNumber: 18,
            title: "BFD Nr. 1461: IREB Requirements Engineering (CPRE)",
            subtitle: "17.11. – 19.11.2027 (3 Tage): Certified Professional for Requirements Engineering (CPRE-FL).",
            type: .certification,
            estimatedHours: 24,
            estimatedMinutes: 90,
            category: "BFD Zertifikat",
            difficulty: "Intermediate",
            certBadge: "IREB CPRE",
            primaryURL: "https://www.ireb.org/",
            prerequisiteIds: [],
            learningGoals: [],
            subtasks: [
                RoadmapSubtask(id: "bfd1461-1", text: "Anforderungsanalyse, Dokumentation & Konfliktlösung meistern", isDone: false),
                RoadmapSubtask(id: "bfd1461-2", text: "IREB CPRE Foundation Level Prüfung bestehen", isDone: false)
            ],
            submodules: [],
            resources: [],
            notes: "Kernkompetenz des Wirtschaftsinformatikers an der Schnittstelle IT/Fachbereich.",
            isCompleted: false
        ))

        // Phase 2: Administrative Meilensteine (HsH Bewerbung & DZE)
        steps.append(RoadmapStep(
            id: "winf-adm-fhr-hsh",
            track: .wirtschaftsinformatik,
            phase: "Phase 2: Administrative Meilensteine (HsH & DZE)",
            sequenceNumber: 19,
            title: "Anerkennung Fachhochschulreife & HsH-Bewerbung",
            subtitle: "Bewerbungsportal der Hochschule Hannover: 15.11.2027 bis 15.01.2028 für B.Sc. Wirtschaftsinformatik.",
            type: .administrative,
            estimatedHours: 20,
            estimatedMinutes: 60,
            category: "Hochschul-Bewerbung",
            difficulty: "Beginner",
            certBadge: "HsH Portal",
            primaryURL: "https://www.hs-hannover.de/",
            prerequisiteIds: [],
            learningGoals: [],
            subtasks: [
                RoadmapSubtask(id: "adm-1", text: "Zeugnis der Fachhochschulreife bei Landesschulbehörde prüfen lassen", isDone: false),
                RoadmapSubtask(id: "adm-2", text: "Online-Bewerbung im HsH-Portal für SS 2028 fristgerecht absenden", isDone: false),
                RoadmapSubtask(id: "adm-3", text: "Zulassungsbescheid annehmen & Immatrikulation vollziehen", isDone: false)
            ],
            submodules: [],
            resources: [],
            notes: "Fakultät IV, Ricklinger Stadtweg 120, 30459 Hannover.",
            isCompleted: false
        ))

        steps.append(RoadmapStep(
            id: "winf-adm-dze",
            track: .wirtschaftsinformatik,
            phase: "Phase 2: Administrative Meilensteine (HsH & DZE)",
            sequenceNumber: 20,
            title: "Dienstzeitende (DZE: 31.12.2027) & Übergangsgebührnisse",
            subtitle: "BAPersBw-Formalitäten abschließen, Übergangsgebührnisse aktivieren, Wohnungssuche in Hannover.",
            type: .administrative,
            estimatedHours: 30,
            estimatedMinutes: 60,
            category: "Bundeswehr DZE",
            difficulty: "Beginner",
            certBadge: "DZE SaZ 4",
            primaryURL: "https://www.bundeswehr.de/",
            prerequisiteIds: ["winf-adm-fhr-hsh"],
            learningGoals: [],
            subtasks: [
                RoadmapSubtask(id: "dze-1", text: "Aussteuerung und Entlassungsvorbereitung beim Spieß durchführen", isDone: false),
                RoadmapSubtask(id: "dze-2", text: "BAPersBw: Bescheid über Übergangsgebührnisse (ab 01.03.2028 gesichert) prüfen", isDone: false),
                RoadmapSubtask(id: "dze-3", text: "Wohnheimplatz beim Studierendenwerk Hannover beantragen (Ricklingen/Linden)", isDone: false)
            ],
            submodules: [],
            resources: [],
            notes: "Nahtloser Übergang mit 2 Monaten Puffer (Januar/Februar 2028).",
            isCompleted: false
        ))

        // Phase 3: Hochschule Hannover B.Sc. Wirtschaftsinformatik (Start SS 2028)
        steps.append(RoadmapStep(
            id: "winf-hsh-sem1",
            track: .wirtschaftsinformatik,
            phase: "Phase 3: Hochschule Hannover B.Sc. WI (Start SS 2028)",
            sequenceNumber: 21,
            title: "HsH Semester 1: Wirtschaftsmathematik & WI 1 & BWL",
            subtitle: "Start 01.03.2028 am Campus Ricklinger Stadtweg: 30 ECTS Kernmodule.",
            type: .reading,
            estimatedHours: 60,
            estimatedMinutes: 180,
            category: "Hochschule Hannover",
            difficulty: "Intermediate",
            certBadge: "Semester 1",
            primaryURL: "https://www.hs-hannover.de/",
            prerequisiteIds: ["winf-omb-7", "winf-adm-dze"],
            learningGoals: [],
            subtasks: [
                RoadmapSubtask(id: "hsh1-1", text: "Wirtschaftsmathematik Vorlesungen & Übungen besuchen", isDone: false),
                RoadmapSubtask(id: "hsh1-2", text: "Programmierung 1 (Java / Objektorientierung) Praktikum bestehen", isDone: false),
                RoadmapSubtask(id: "hsh1-3", text: "Grundlagen der Wirtschaftsinformatik & BWL Prüfungen ablegen", isDone: false)
            ],
            submodules: [],
            resources: [],
            notes: "Erstes Fachsemester B.Sc. Wirtschaftsinformatik.",
            isCompleted: false
        ))

        // MARK: - Cyber Security Specialist (Archivierter Pfad)
        steps.append(RoadmapStep(
            id: "cs-comptia-a-core1",
            track: .cyberSecurity,
            phase: "Phase 1: CompTIA A+ & Foundational IT (Core 1 & Core 2)",
            sequenceNumber: 1,
            title: "CompTIA A+ Core 1 (220-1101): Hardware, Networking & Cloud",
            subtitle: "Mobile devices, networking protocols & ports, CPU/RAM/Storage hardware, virtualization hypervisors & hardware diagnostics.",
            type: .certification,
            estimatedHours: 50,
            estimatedMinutes: 150,
            category: "Foundations & Hardware",
            difficulty: "Beginner",
            certBadge: "220-1101",
            primaryURL: "https://www.professormesser.com/free-a-plus-training/220-1101/220-1101-video/220-1101-training-course/",
            prerequisiteIds: [],
            learningGoals: [],
            subtasks: [
                RoadmapSubtask(id: "a1-1", text: "Domain 1.0 Mobile Devices: Laptops, display types (OLED/LCD), USB-C, Lightning, 802.11 WiFi & Bluetooth setup", isDone: false),
                RoadmapSubtask(id: "a1-2", text: "Domain 2.0 Networking: Master standard ports (20/21 FTP, 22 SSH, 23 Telnet, 25 SMTP, 53 DNS, 80 HTTP, 443 HTTPS, 3389 RDP, 445 SMB)", isDone: false),
                RoadmapSubtask(id: "a1-3", text: "Domain 3.0 Hardware: Motherboard form factors (ATX/mATX/ITX), CPUs (Intel LGA vs AMD PGA), RAM (DDR4/DDR5 SO-DIMM), M.2 NVMe PCIe vs SATA SSDs", isDone: false),
                RoadmapSubtask(id: "a1-4", text: "Domain 4.0 Virtualization & Cloud: Bare-metal Type 1 vs Type 2 Hypervisors, Cloud Models (IaaS, PaaS, SaaS), Virtual NICs & resource allocation", isDone: false),
                RoadmapSubtask(id: "a1-5", text: "Domain 5.0 Troubleshooting: POST error codes, multimeter power supply testing, SMART drive diagnostic tools, thermal throttling", isDone: false)
            ],
            submodules: [
                StudySubmodule(id: "a1-sm-1", title: "Professor Messer CompTIA 220-1101 A+ Training Course Playlist", type: .youtubePlaylist, url: "https://www.youtube.com/playlist?list=PLG49S3nxzAnmwkCvw4okAmSmYg5314-88", durationMinutes: 60, videoCount: 68, isCompleted: false),
                StudySubmodule(id: "a1-sm-2", title: "PowerCert Animated Hardware & Network Protocols", type: .youtubePlaylist, url: "https://www.youtube.com/@PowerCertAnimatedVideos", durationMinutes: 30, videoCount: 20, isCompleted: false),
                StudySubmodule(id: "a1-sm-3", title: "CrucialExams CompTIA 220-1101 Practice Tests", type: .examDrill, url: "https://crucialexams.com/exams/comptia/a/220-1101", durationMinutes: 45, isCompleted: false)
            ],
            resources: [
                StepResource(id: "a1-res-1", title: "Professor Messer 220-1101 Course Portal", url: "https://www.professormesser.com/free-a-plus-training/220-1101/220-1101-video/220-1101-training-course/", type: "Video"),
                StepResource(id: "a1-res-2", title: "CompTIA A+ Official Exam Objectives", url: "https://www.comptia.org/certifications/a", type: "Documentation"),
                StepResource(id: "a1-res-3", title: "CrucialExams 220-1101 Drills", url: "https://crucialexams.com/exams/comptia/a/220-1101", type: "Practice")
            ],
            notes: "Foundation for all computer architecture and hardware understanding.",
            isCompleted: false
        ))
        steps.append(RoadmapStep(
            id: "cs-comptia-a-core2",
            track: .cyberSecurity,
            phase: "Phase 1: CompTIA A+ & Foundational IT (Core 1 & Core 2)",
            sequenceNumber: 2,
            title: "CompTIA A+ Core 2 (220-1102): OS, Security & Operations",
            subtitle: "Windows 10/11 CLI commands, Linux terminal, 7-step malware removal procedure, social engineering & ticketing workflows.",
            type: .certification,
            estimatedHours: 50,
            estimatedMinutes: 150,
            category: "OS & Operational Security",
            difficulty: "Beginner",
            certBadge: "220-1102",
            primaryURL: "https://www.professormesser.com/free-a-plus-training/220-1102/220-1102-video/220-1102-training-course/",
            prerequisiteIds: ["cs-comptia-a-core1"],
            learningGoals: [],
            subtasks: [
                RoadmapSubtask(id: "a2-1", text: "Domain 1.0 Operating Systems: Windows CLI (diskpart, chkdsk, sfc /scannow, robocopy, gpupdate), macOS Disk Utility, Linux navigation", isDone: false),
                RoadmapSubtask(id: "a2-2", text: "Domain 2.0 Security: Execute 7-step Malware Remediation process (Identify, Quarantine, Disable Restore, Remediate, Schedule Scans, Enable Restore, Educate User)", isDone: false),
                RoadmapSubtask(id: "a2-3", text: "Domain 2.0 Security: Social Engineering countermeasures (Phishing, Spear Phishing, Vishing), BitLocker/LUKS, Local Firewalls", isDone: false),
                RoadmapSubtask(id: "a2-4", text: "Domain 3.0 Software Troubleshooting: BSOD crash dump inspection, Windows Event Viewer analysis, Safe Mode diagnosis", isDone: false),
                RoadmapSubtask(id: "a2-5", text: "Domain 4.0 Operational Procedures: Incident documentation, ticketing lifecycles, ESD safety wristbands & mats, toxic material disposal", isDone: false)
            ],
            submodules: [
                StudySubmodule(id: "a2-sm-1", title: "Professor Messer CompTIA 220-1102 A+ Training Course Playlist", type: .youtubePlaylist, url: "https://www.youtube.com/playlist?list=PLG49S3nxzAnkL2vCT7948344_41-4777", durationMinutes: 60, videoCount: 65, isCompleted: false),
                StudySubmodule(id: "a2-sm-2", title: "Linux Journey Command Line Mastery", type: .webModule, url: "https://linuxjourney.com/", durationMinutes: 30, isCompleted: false),
                StudySubmodule(id: "a2-sm-3", title: "CrucialExams CompTIA 220-1102 Practice Tests", type: .examDrill, url: "https://crucialexams.com/exams/comptia/a/220-1102", durationMinutes: 45, isCompleted: false)
            ],
            resources: [
                StepResource(id: "a2-res-1", title: "Professor Messer 220-1102 Course Portal", url: "https://www.professormesser.com/free-a-plus-training/220-1102/220-1102-video/220-1102-training-course/", type: "Video"),
                StepResource(id: "a2-res-2", title: "Linux Journey Interactive Guide", url: "https://linuxjourney.com/", type: "Interactive"),
                StepResource(id: "a2-res-3", title: "CrucialExams 220-1102 Drills", url: "https://crucialexams.com/exams/comptia/a/220-1102", type: "Practice")
            ],
            notes: "Full CompTIA A+ certification readiness achieved.",
            isCompleted: false
        ))

        // Phase 1 Additional Modules & Practice
        steps.append(RoadmapStep(
            id: "cs-phase1-linux-basics",
            track: .cyberSecurity,
            phase: "Phase 1: CompTIA A+ & Foundational IT (Core 1 & Core 2)",
            sequenceNumber: 3,
            title: "Linux & CLI Fundamente: Shell Navigation & Berechtigungen",
            subtitle: "Dateisystem-Hierarchie (/etc, /var, /bin), bash CLI Navigation (ls, cd, grep, find), Berechtigungen (chmod, chown) & Prozessmanagement (ps, top, kill).",
            type: .handsOnLab,
            estimatedHours: 20,
            estimatedMinutes: 60,
            category: "Linux & CLI",
            difficulty: "Beginner",
            certBadge: "CLI Lab",
            primaryURL: "https://linuxjourney.com/",
            prerequisiteIds: ["cs-comptia-a-core2"],
            learningGoals: [],
            subtasks: [
                RoadmapSubtask(id: "p1-lx-1", text: "Navigation & Dateibearbeitung: ls, cd, pwd, cat, touch, nano, vim, less, head, tail", isDone: false),
                RoadmapSubtask(id: "p1-lx-2", text: "Berechtigungen: chmod (symbolisch ugo/rwx und oktal 755/644), chown, chgrp, umask", isDone: false),
                RoadmapSubtask(id: "p1-lx-3", text: "Textfilter & Pipelines: |, >, >>, grep, sort, uniq, cut, awk, tr, wc", isDone: false),
                RoadmapSubtask(id: "p1-lx-4", text: "Prozesssteuerung & Monitoring: ps aux, top, htop, kill, pkill, bg, fg, jobs", isDone: false)
            ],
            submodules: [
                StudySubmodule(id: "p1-lx-sm-1", title: "Linux Journey - Command Line Basics", type: .webModule, url: "https://linuxjourney.com/", durationMinutes: 30, isCompleted: false),
                StudySubmodule(id: "p1-lx-sm-2", title: "NetworkChuck - Linux for Hackers Playlist", type: .youtubePlaylist, url: "https://www.youtube.com/playlist?list=PLS1QulFiPE-5kh0Vnuwtda_g_23gA0kFm", durationMinutes: 45, videoCount: 15, isCompleted: false),
                StudySubmodule(id: "p1-lx-sm-3", title: "OverTheWire Bandit - Wargame Levels 0-5", type: .handsOnLab, url: "https://overthewire.org/wargames/bandit/", durationMinutes: 60, isCompleted: false)
            ],
            resources: [
                StepResource(id: "p1-lx-res-1", title: "Linux Journey Portal", url: "https://linuxjourney.com/", type: "Interactive"),
                StepResource(id: "p1-lx-res-2", title: "The Linux Command Line Guide", url: "https://linuxcommand.org/tlcl.php", type: "Book")
            ],
            notes: "Fundamentale Shell-Befehle und Berechtigungs-Struktur verinnerlicht.",
            isCompleted: false
        ))
        steps.append(RoadmapStep(
            id: "cs-phase1-hardware-lab",
            track: .cyberSecurity,
            phase: "Phase 1: CompTIA A+ & Foundational IT (Core 1 & Core 2)",
            sequenceNumber: 4,
            title: "Hardware-Diagnose & Klemmen-Praxis (Disassembly & POST)",
            subtitle: "RAM-Kompilierung, M.2 NVMe Installation, Multimeter-Spannungsprüfung am Netzteil, CMOS-Reset & POST-Fehlercodes.",
            type: .handsOnLab,
            estimatedHours: 15,
            estimatedMinutes: 45,
            category: "Hardware Lab",
            difficulty: "Beginner",
            certBadge: "Hardware Lab",
            primaryURL: "https://www.youtube.com/@PowerCertAnimatedVideos",
            prerequisiteIds: ["cs-comptia-a-core1"],
            learningGoals: [],
            subtasks: [
                RoadmapSubtask(id: "p1-hw-1", text: "Multimeter-Messtechnik am 24-Pin ATX Hauptstecker (+12V, +5V, +3.3V, -12V, +5VSB)", isDone: false),
                RoadmapSubtask(id: "p1-hw-2", text: "POST (Power-On Self-Test) Beep-Codes und Mainboard 7-Segment Debug LEDs interpretieren", isDone: false),
                RoadmapSubtask(id: "p1-hw-3", text: "RAM-Diagnose mit MemTest86 (ECC vs. Non-ECC, Dual-Channel Bestückungsmatrix)", isDone: false),
                RoadmapSubtask(id: "p1-hw-4", text: "Thermische Analyse: Wärmeleitpaste auftragen, CPU-Kühler Montage & Fan-Curves", isDone: false)
            ],
            submodules: [
                StudySubmodule(id: "p1-hw-sm-1", title: "PowerCert Hardware Diagnostics & Tear-Down", type: .youtubePlaylist, url: "https://www.youtube.com/@PowerCertAnimatedVideos", durationMinutes: 35, videoCount: 12, isCompleted: false),
                StudySubmodule(id: "p1-hw-sm-2", title: "iFixit PC Hardware Repair Curriculum", type: .webModule, url: "https://www.ifixit.com/", durationMinutes: 40, isCompleted: false)
            ],
            resources: [
                StepResource(id: "p1-hw-res-1", title: "PowerCert Animated Videos", url: "https://www.youtube.com/@PowerCertAnimatedVideos", type: "Video"),
                StepResource(id: "p1-hw-res-2", title: "iFixit PC Repair", url: "https://www.ifixit.com/", type: "Lab")
            ],
            notes: "Praktische Messungen am Netzteil und Komponententausch erfolgreich.",
            isCompleted: false
        ))
        steps.append(RoadmapStep(
            id: "cs-phase1-pbq-exam-sim",
            track: .cyberSecurity,
            phase: "Phase 1: CompTIA A+ & Foundational IT (Core 1 & Core 2)",
            sequenceNumber: 5,
            title: "CompTIA A+ Performance-Based Questions (PBQ) Drills",
            subtitle: "Interaktive Prüfungssimulationen: Motherboard-Steckplätze, RAID-Konfigurationen (RAID 0, 1, 5, 10), IPv4-Konfiguration & WLAN-Sicherheitsstandards.",
            type: .examSimulation,
            estimatedHours: 25,
            estimatedMinutes: 60,
            category: "Prüfungssimulation",
            difficulty: "Beginner",
            certBadge: "PBQ Prep",
            primaryURL: "https://crucialexams.com/exams/comptia/a/",
            prerequisiteIds: ["cs-comptia-a-core1", "cs-comptia-a-core2"],
            learningGoals: [],
            subtasks: [
                RoadmapSubtask(id: "p1-pbq-1", text: "PBQ Drill 1: Motherboard Komponenten & I/O-Shield Zuordnung unter Zeitdruck", isDone: false),
                RoadmapSubtask(id: "p1-pbq-2", text: "PBQ Drill 2: RAID-Level Auswahl nach Speicherbedarf, Redundanz und Lese-/Schreibperformance", isDone: false),
                RoadmapSubtask(id: "p1-pbq-3", text: "PBQ Drill 3: SOHO-WLAN Router Konfiguration (SSID, WPA3, DHCP IP-Pool, Port Forwarding)", isDone: false),
                RoadmapSubtask(id: "p1-pbq-4", text: "PBQ Drill 4: Windows Recovery Console Befehlsabfolge (bootrec /fixmbr, bootrec /rebuildbcd)", isDone: false)
            ],
            submodules: [
                StudySubmodule(id: "p1-pbq-sm-1", title: "CrucialExams A+ PBQ Simulation Lab", type: .examDrill, url: "https://crucialexams.com/exams/comptia/a/", durationMinutes: 45, isCompleted: false),
                StudySubmodule(id: "p1-pbq-sm-2", title: "Professor Messer A+ Study Group PBQ Breakdowns", type: .youtubePlaylist, url: "https://www.youtube.com/playlist?list=PLG49S3nxzAnmwkCvw4okAmSmYg5314-88", durationMinutes: 60, videoCount: 10, isCompleted: false)
            ],
            resources: [
                StepResource(id: "p1-pbq-res-1", title: "CrucialExams Simulation Engine", url: "https://crucialexams.com/exams/comptia/a/", type: "Practice"),
                StepResource(id: "p1-pbq-res-2", title: "Dion Training PBQ Study Guides", url: "https://diontraining.com/", type: "Course")
            ],
            notes: "PBQ-Simulationen für Core 1 und Core 2 mit hoher Trefferquote absolviert.",
            isCompleted: false
        ))

        steps.append(RoadmapStep(
            id: "cs-networking",
            track: .cyberSecurity,
            phase: "Phase 2: CompTIA Network+ & Packet Analysis",
            sequenceNumber: 6,
            title: "CompTIA Network+ (N10-008): Networking & Subnetting",
            subtitle: "OSI 7-layer stack, IPv4 CIDR/VLSM calculation, TCP 3-way handshake, routing protocols & VLAN segmentation.",
            type: .certification,
            estimatedHours: 60,
            estimatedMinutes: 180,
            category: "Networking Engineering",
            difficulty: "Intermediate",
            certBadge: "N10-008",
            primaryURL: "https://www.professormesser.com/network-plus/n10-008/n10-008-training-course/",
            prerequisiteIds: ["cs-comptia-a-core1"],
            learningGoals: [],
            subtasks: [
                RoadmapSubtask(id: "net-1", text: "Master the 7 OSI layers & 4 TCP/IP layers with exact PDU encapsulations (Bits, Frames, Packets, Segments, Data)", isDone: false),
                RoadmapSubtask(id: "net-2", text: "Practice IPv4 CIDR / VLSM subnetting (calculate network ID, broadcast ID, usable hosts within 30 seconds)", isDone: false),
                RoadmapSubtask(id: "net-3", text: "Analyze TCP 3-way handshake (SYN, SYN-ACK, ACK), TCP control flags (FIN, RST, PSH, URG), and UDP differences", isDone: false),
                RoadmapSubtask(id: "net-4", text: "Understand DNS resolution flow (Root, TLD, Authoritative, Recursive) and DHCP DORA process", isDone: false),
                RoadmapSubtask(id: "net-5", text: "Configure VLANs (802.1Q tagging), Trunking, Spanning Tree Protocol (STP 802.1D) and Default Gateways", isDone: false)
            ],
            submodules: [
                StudySubmodule(id: "cs-networking-sm-1", title: "Professor Messer Network+ N10-008 Training Course Playlist", type: .youtubePlaylist, url: "https://www.youtube.com/playlist?list=PLG49S3nxzAnlCgyLgKnSk-8dWu64UW8Lz", durationMinutes: 60, videoCount: 75, isCompleted: false),
                StudySubmodule(id: "cs-networking-sm-2", title: "Practical Networking Subnetting Mastery", type: .youtubeVideo, url: "https://www.youtube.com/@PracticalNetworking", durationMinutes: 30, isCompleted: false),
                StudySubmodule(id: "cs-networking-sm-3", title: "Subnetting Practice Drills Engine", type: .webModule, url: "https://www.subnetting.net/", durationMinutes: 25, isCompleted: false)
            ],
            resources: [
                StepResource(id: "cs-networking-res-1", title: "Professor Messer Network+ Course", url: "https://www.professormesser.com/network-plus/n10-008/n10-008-training-course/", type: "Course"),
                StepResource(id: "cs-networking-res-2", title: "Practical Networking Channel", url: "https://www.youtube.com/@PracticalNetworking", type: "Video"),
                StepResource(id: "cs-networking-res-3", title: "Subnetting Drills", url: "https://www.subnetting.net/", type: "Practice")
            ],
            notes: "Subnetting speed is high. Working on memorizing /24 down to /30 masks.",
            isCompleted: false
        ))
        steps.append(RoadmapStep(
            id: "cs-wireshark",
            track: .cyberSecurity,
            phase: "Phase 2: CompTIA Network+ & Packet Analysis",
            sequenceNumber: 7,
            title: "Packet Dissection with Wireshark & Tcpdump",
            subtitle: "Capturing live traffic, filter syntax, dissecting TLS handshakes, reconstructing streams & detecting port scans.",
            type: .handsOnLab,
            estimatedHours: 30,
            estimatedMinutes: 90,
            category: "Traffic Analysis",
            difficulty: "Intermediate",
            certBadge: nil,
            primaryURL: "https://wiki.wireshark.org/SampleCaptures",
            prerequisiteIds: ["cs-networking"],
            learningGoals: [],
            subtasks: [
                RoadmapSubtask(id: "ws-1", text: "Capture packets via CLI: tcpdump -i eth0 -nn -s0 -w capture.pcap", isDone: false),
                RoadmapSubtask(id: "ws-2", text: "Master Wireshark display filters: http.request.method == 'POST' || ip.addr == x", isDone: false),
                RoadmapSubtask(id: "ws-3", text: "Follow TCP/HTTP Streams and extract cleartext credentials, payloads & files", isDone: false),
                RoadmapSubtask(id: "ws-4", text: "Detect ARP spoofing, TCP SYN floods, and malware beacon anomalies in PCAPs", isDone: false)
            ],
            submodules: [
                StudySubmodule(id: "cs-wireshark-sm-1", title: "Wireshark Sample Captures Archive", type: .handsOnLab, url: "https://wiki.wireshark.org/SampleCaptures", durationMinutes: 25, isCompleted: false),
                StudySubmodule(id: "cs-wireshark-sm-2", title: "Malware Traffic Analysis PCAP Exercises (Brad Duncan)", type: .webModule, url: "https://www.malware-traffic-analysis.net/", durationMinutes: 25, isCompleted: false)
            ],
            resources: [
                StepResource(id: "cs-wireshark-res-1", title: "Wireshark Sample Captures", url: "https://wiki.wireshark.org/SampleCaptures", type: "Lab"),
                StepResource(id: "cs-wireshark-res-2", title: "Malware Traffic Analysis Exercises", url: "https://www.malware-traffic-analysis.net/", type: "Practice")
            ],
            notes: "Wireshark filter syntax and stream reassembly mastered.",
            isCompleted: false
        ))
        steps.append(RoadmapStep(
            id: "cs-linux-admin",
            track: .cyberSecurity,
            phase: "Phase 3: Linux Administration & Shell Scripting",
            sequenceNumber: 8,
            title: "Linux System Administration & Server Hardening",
            subtitle: "Bash CLI, systemd services, SSH key hardening, file permissions (chmod/chown), cron jobs & package management.",
            type: .handsOnLab,
            estimatedHours: 40,
            estimatedMinutes: 120,
            category: "Linux Administration",
            difficulty: "Intermediate",
            certBadge: nil,
            primaryURL: "https://overthewire.org/wargames/bandit/",
            prerequisiteIds: ["cs-comptia-a-core2"],
            learningGoals: [],
            subtasks: [
                RoadmapSubtask(id: "lx-1", text: "Master core utilities: grep, awk, sed, find, xargs, tar, chmod, chown, systemctl, journalctl", isDone: false),
                RoadmapSubtask(id: "lx-2", text: "Complete OverTheWire: Bandit levels 1 to 20", isDone: false),
                RoadmapSubtask(id: "lx-3", text: "Configure SSH key-based authentication, disable root password login, set UFW firewall rules", isDone: false),
                RoadmapSubtask(id: "lx-4", text: "Inspect /var/log/auth.log, dmesg, and process tables with htop and ps aux", isDone: false)
            ],
            submodules: [
                StudySubmodule(id: "cs-linux-admin-sm-1", title: "OverTheWire Bandit Wargame", type: .handsOnLab, url: "https://overthewire.org/wargames/bandit/", durationMinutes: 30, isCompleted: false),
                StudySubmodule(id: "cs-linux-admin-sm-2", title: "The Linux Command Line by William Shotts (Free Book)", type: .readingChapter, url: "https://linuxcommand.org/tlcl.php", durationMinutes: 30, isCompleted: false)
            ],
            resources: [
                StepResource(id: "cs-linux-admin-res-1", title: "OverTheWire Bandit Wargame", url: "https://overthewire.org/wargames/bandit/", type: "Practice"),
                StepResource(id: "cs-linux-admin-res-2", title: "The Linux Command Line Book", url: "https://linuxcommand.org/tlcl.php", type: "Book")
            ],
            notes: "Bandit levels 1-20 completed. Server hardening scripts in place.",
            isCompleted: false
        ))
        steps.append(RoadmapStep(
            id: "cs-python-automation",
            track: .cyberSecurity,
            phase: "Phase 3: Linux Administration & Shell Scripting",
            sequenceNumber: 9,
            title: "Python for Cyber Security & Automation",
            subtitle: "Socket programming, port scanners, web requests, log parsing automation and regex scripting.",
            type: .reading,
            estimatedHours: 40,
            estimatedMinutes: 120,
            category: "Scripting & Automation",
            difficulty: "Intermediate",
            certBadge: nil,
            primaryURL: "https://automatetheboringstuff.com/",
            prerequisiteIds: ["cs-linux-admin", "cs-networking"],
            learningGoals: [],
            subtasks: [
                RoadmapSubtask(id: "py-1", text: "Build a multi-threaded TCP Port Scanner in Python using socket and threading modules", isDone: false),
                RoadmapSubtask(id: "py-2", text: "Write a web directory bruteforcer with the requests library", isDone: false),
                RoadmapSubtask(id: "py-3", text: "Create Bash one-liners for log extraction using grep -E, awk, cut, sort | uniq -c", isDone: false),
                RoadmapSubtask(id: "py-4", text: "Learn Scapy for custom packet crafting and network fuzzing", isDone: false)
            ],
            submodules: [
                StudySubmodule(id: "cs-python-automation-sm-1", title: "Automate the Boring Stuff with Python", type: .readingChapter, url: "https://automatetheboringstuff.com/", durationMinutes: 30, isCompleted: false),
                StudySubmodule(id: "cs-python-automation-sm-2", title: "Black Hat Python (2nd Edition)", type: .readingChapter, url: "https://nostarch.com/black-hat-python2E", durationMinutes: 30, isCompleted: false)
            ],
            resources: [
                StepResource(id: "cs-python-automation-res-1", title: "Automate the Boring Stuff with Python", url: "https://automatetheboringstuff.com/", type: "Book"),
                StepResource(id: "cs-python-automation-res-2", title: "Black Hat Python", url: "https://nostarch.com/black-hat-python2E", type: "Book")
            ],
            notes: "Custom multithreaded port scanner and banner grabber written in Python.",
            isCompleted: false
        ))
        steps.append(RoadmapStep(
            id: "sec-comptia-secplus",
            track: .cyberSecurity,
            phase: "Phase 4: CompTIA Security+ (SY0-701) & Security Principles",
            sequenceNumber: 10,
            title: "CompTIA Security+ (SY0-701): Threat Modeling & Defense",
            subtitle: "CIA Triad, Zero Trust, AAA, MITRE ATT&CK, PKI & Cryptography, SOC incident response lifecycles & NIST CSF 2.0.",
            type: .certification,
            estimatedHours: 80,
            estimatedMinutes: 240,
            category: "Cyber Security Certification",
            difficulty: "Intermediate",
            certBadge: "SY0-701",
            primaryURL: "https://www.professormesser.com/security-plus/sy0-701/sy0-701-video/sy0-701-training-course/",
            prerequisiteIds: ["cs-networking", "cs-comptia-a-core2"],
            learningGoals: [],
            subtasks: [
                RoadmapSubtask(id: "s7-1", text: "Domain 1.0 General Security Concepts: CIA Triad, Zero Trust Architecture, AAA, Principle of Least Privilege", isDone: false),
                RoadmapSubtask(id: "s7-2", text: "Domain 2.0 Threats & Vulnerabilities: MITRE ATT&CK Matrix, CVE & CVSS v3.1 scoring, Social Engineering, Ransomware", isDone: false),
                RoadmapSubtask(id: "s7-3", text: "Domain 3.0 Security Architecture: Symmetric (AES) vs Asymmetric (RSA/ECC) encryption, TLS 1.3, PKI & CA hierarchy", isDone: false),
                RoadmapSubtask(id: "s7-4", text: "Domain 4.0 Security Operations: SIEM, EDR, SOAR, Incident Response 6 phases (Preparation, Identification, Containment, Eradication, Recovery, Lessons Learned)", isDone: false),
                RoadmapSubtask(id: "s7-5", text: "Domain 5.0 Governance & Compliance: NIST CSF 2.0, ISO/IEC 27001, GDPR, Risk Assessments & Business Continuity Planning (BCP)", isDone: false)
            ],
            submodules: [
                StudySubmodule(id: "s7-sm-1", title: "Professor Messer CompTIA Security+ SY0-701 Training Course Playlist", type: .youtubePlaylist, url: "https://www.youtube.com/playlist?list=PLG49S3nxzAnl4QTVU4BlO3CW841fK55Wp", durationMinutes: 60, videoCount: 80, isCompleted: false),
                StudySubmodule(id: "s7-sm-2", title: "NIST Computer Security Resource Center", type: .webModule, url: "https://csrc.nist.gov/", durationMinutes: 30, isCompleted: false),
                StudySubmodule(id: "s7-sm-3", title: "CrucialExams CompTIA Security+ SY0-701 Practice Tests", type: .examDrill, url: "https://crucialexams.com/exams/comptia/security/sy0-701", durationMinutes: 45, isCompleted: false)
            ],
            resources: [
                StepResource(id: "s7-res-1", title: "Professor Messer SY0-701 Course Portal", url: "https://www.professormesser.com/security-plus/sy0-701/sy0-701-video/sy0-701-training-course/", type: "Course"),
                StepResource(id: "s7-res-2", title: "CompTIA Security+ Official Objectives", url: "https://www.comptia.org/certifications/security", type: "Documentation"),
                StepResource(id: "s7-res-3", title: "CrucialExams SY0-701 Practice Exams", url: "https://crucialexams.com/exams/comptia/security/sy0-701", type: "Practice")
            ],
            notes: "Ready for CompTIA Security+ examination.",
            isCompleted: false
        ))
        steps.append(RoadmapStep(
            id: "sec-cryptography",
            track: .cyberSecurity,
            phase: "Phase 4: CompTIA Security+ (SY0-701) & Security Principles",
            sequenceNumber: 11,
            title: "Applied Cryptography & Public Key Infrastructure (PKI)",
            subtitle: "AES-256, RSA, Elliptic Curve (ECDHE), SHA-256/Argon2id, TLS 1.3 handshake & digital certificates.",
            type: .reading,
            estimatedHours: 25,
            estimatedMinutes: 75,
            category: "Cryptography",
            difficulty: "Intermediate",
            certBadge: nil,
            primaryURL: "https://www.crypto101.io/",
            prerequisiteIds: ["sec-comptia-secplus"],
            learningGoals: [],
            subtasks: [
                RoadmapSubtask(id: "cr-1", text: "Differentiate Block Ciphers (AES-256-GCM) from Stream Ciphers (ChaCha20-Poly1305)", isDone: false),
                RoadmapSubtask(id: "cr-2", text: "Analyze Cryptographic Hashes (SHA-256, SHA-3) and Password KDFs (Argon2id, bcrypt)", isDone: false),
                RoadmapSubtask(id: "cr-3", text: "Understand PKI: Root CA, Intermediate CA, Certificate Revocation Lists (CRL) and OCSP stapling", isDone: false),
                RoadmapSubtask(id: "cr-4", text: "Dissect TLS 1.3 Handshake (ECDHE Key Exchange, ClientHello, EncryptedExtensions)", isDone: false)
            ],
            submodules: [
                StudySubmodule(id: "sec-cryptography-sm-1", title: "Crypto101 (Free Cryptography Book)", type: .readingChapter, url: "https://www.crypto101.io/", durationMinutes: 25, isCompleted: false),
                StudySubmodule(id: "sec-cryptography-sm-2", title: "The Illustrated TLS 1.3 Connection", type: .webModule, url: "https://tls13.xargs.org/", durationMinutes: 25, isCompleted: false)
            ],
            resources: [
                StepResource(id: "sec-cryptography-res-1", title: "Crypto101 Free Book", url: "https://www.crypto101.io/", type: "Book"),
                StepResource(id: "sec-cryptography-res-2", title: "The Illustrated TLS 1.3 Connection", url: "https://tls13.xargs.org/", type: "Interactive")
            ],
            notes: "Deep understanding of TLS 1.3 and cryptographic primitives.",
            isCompleted: false
        ))
        steps.append(RoadmapStep(
            id: "sec-soc-siem",
            track: .cyberSecurity,
            phase: "Phase 5: Hands-on Cyber Labs, SIEM & Web Security",
            sequenceNumber: 12,
            title: "SOC Operations & SIEM Log Analysis (Splunk & Sysmon)",
            subtitle: "Windows Event Logs (Sysmon), Splunk SPL queries, Sigma/YARA rules & threat hunting workflows.",
            type: .handsOnLab,
            estimatedHours: 40,
            estimatedMinutes: 120,
            category: "Blue Team & SOC",
            difficulty: "Intermediate",
            certBadge: nil,
            primaryURL: "https://github.com/splunk/botsv3",
            prerequisiteIds: ["sec-comptia-secplus"],
            learningGoals: [],
            subtasks: [
                RoadmapSubtask(id: "soc-1", text: "Ingest Windows Event Logs with Sysmon (Event IDs: 1 Process Create, 3 Network Connect, 7 Image Load)", isDone: false),
                RoadmapSubtask(id: "soc-2", text: "Write Splunk SPL search queries with stats, eval, timechart, rex regular expressions", isDone: false),
                RoadmapSubtask(id: "soc-3", text: "Investigate Splunk Boss of the SOC (BOTS v3) incident dataset", isDone: false)
            ],
            submodules: [
                StudySubmodule(id: "sec-soc-siem-sm-1", title: "Splunk Boss of the SOC (BOTS) Dataset Repository", type: .handsOnLab, url: "https://github.com/splunk/botsv3", durationMinutes: 30, isCompleted: false),
                StudySubmodule(id: "sec-soc-siem-sm-2", title: "TryHackMe SOC Level 1 Pathway", type: .handsOnLab, url: "https://tryhackme.com/path/outline/soclevel1", durationMinutes: 30, isCompleted: false)
            ],
            resources: [
                StepResource(id: "sec-soc-siem-res-1", title: "Splunk BOTS v3", url: "https://github.com/splunk/botsv3", type: "Lab"),
                StepResource(id: "sec-soc-siem-res-2", title: "TryHackMe SOC Level 1", url: "https://tryhackme.com/path/outline/soclevel1", type: "Course")
            ],
            notes: "Practical SOC analysis with Splunk SPL queries mastered.",
            isCompleted: false
        ))
        steps.append(RoadmapStep(
            id: "sec-web-owasp",
            track: .cyberSecurity,
            phase: "Phase 5: Hands-on Cyber Labs, SIEM & Web Security",
            sequenceNumber: 13,
            title: "Web Security & OWASP Top 10 Exploitation",
            subtitle: "Burp Suite, SQL Injection, XSS, CSRF, SSRF, IDOR & PortSwigger Web Security Academy.",
            type: .handsOnLab,
            estimatedHours: 45,
            estimatedMinutes: 135,
            category: "Web Security",
            difficulty: "Intermediate",
            certBadge: nil,
            primaryURL: "https://portswigger.net/web-security",
            prerequisiteIds: ["cs-networking", "cs-python-automation"],
            learningGoals: [],
            subtasks: [
                RoadmapSubtask(id: "ow-1", text: "SQL Injection: Error-based, UNION-based, Blind boolean & time-based exploitation", isDone: false),
                RoadmapSubtask(id: "ow-2", text: "Cross-Site Scripting (XSS): Reflected, Stored, DOM-based XSS payloads & cookie stealing", isDone: false),
                RoadmapSubtask(id: "ow-3", text: "Server-Side Request Forgery (SSRF) and Local/Remote File Inclusion (LFI/RFI) exploitation", isDone: false),
                RoadmapSubtask(id: "ow-4", text: "Complete 25 Apprentice & Practitioner labs on PortSwigger Web Security Academy", isDone: false)
            ],
            submodules: [
                StudySubmodule(id: "sec-web-owasp-sm-1", title: "PortSwigger Web Security Academy Labs", type: .handsOnLab, url: "https://portswigger.net/web-security", durationMinutes: 30, isCompleted: false),
                StudySubmodule(id: "sec-web-owasp-sm-2", title: "OWASP Top 10 Standard", type: .webModule, url: "https://owasp.org/www-project-top-ten/", durationMinutes: 25, isCompleted: false)
            ],
            resources: [
                StepResource(id: "sec-web-owasp-res-1", title: "PortSwigger Web Security Academy", url: "https://portswigger.net/web-security", type: "Lab"),
                StepResource(id: "sec-web-owasp-res-2", title: "OWASP Top 10 Standard", url: "https://owasp.org/www-project-top-ten/", type: "Documentation")
            ],
            notes: "PortSwigger practitioner labs completed with Burp Suite Repeater and Intruder.",
            isCompleted: false
        ))
        steps.append(RoadmapStep(
            id: "sec-bsc-hm-prep",
            track: .cyberSecurity,
            phase: "Phase 6: B.Sc. Cyber Security Academic Integration (HM München)",
            sequenceNumber: 14,
            title: "HM München B.Sc. Curriculum & Computer Science Prep",
            subtitle: "Discrete mathematics, data structures & algorithms (DSA in Python/C), and academic alignment.",
            type: .reading,
            estimatedHours: 60,
            estimatedMinutes: 180,
            category: "Academic Degree",
            difficulty: "Intermediate",
            certBadge: "B.Sc.",
            primaryURL: "https://www.hm.edu/",
            prerequisiteIds: ["cs-comptia-a-core1", "cs-python-automation"],
            learningGoals: [],
            subtasks: [
                RoadmapSubtask(id: "hm-1", text: "Review HM München B.Sc. Cyber Security module catalog & degree structure", isDone: false),
                RoadmapSubtask(id: "hm-2", text: "Implement foundational data structures in Python / C (Linked Lists, Stacks, Queues, Binary Trees, Hash Maps)", isDone: false),
                RoadmapSubtask(id: "hm-3", text: "Align Matura mathematics (Discrete Math, Calculus, Linear Algebra) with university CS requirements", isDone: false)
            ],
            submodules: [
                StudySubmodule(id: "sec-bsc-hm-prep-sm-1", title: "HM München Official Degree Portal", type: .webModule, url: "https://www.hm.edu/", durationMinutes: 25, isCompleted: false),
                StudySubmodule(id: "sec-bsc-hm-prep-sm-2", title: "Open Source Society University (OSSU) Computer Science Curriculum", type: .webModule, url: "https://github.com/ossu/computer-science", durationMinutes: 30, isCompleted: false)
            ],
            resources: [
                StepResource(id: "sec-bsc-hm-prep-res-1", title: "HM München Degree Portal", url: "https://www.hm.edu/", type: "Portal"),
                StepResource(id: "sec-bsc-hm-prep-res-2", title: "OSSU Computer Science Curriculum", url: "https://github.com/ossu/computer-science", type: "Curriculum")
            ],
            notes: "Prepared for academic success at HM München.",
            isCompleted: false
        ))

        // MARK: - GrowCare Integration: 4C Skincare, Bartpflege & Kasernen-Chores
        steps.append(contentsOf: careAndChoresSteps())

        return steps
    }

    public static func careAndChoresSteps() -> [RoadmapStep] {
        var items: [RoadmapStep] = []

        // MARK: - 1. Morgen-Routine (Gesicht & UV-Schutz)
        items.append(RoadmapStep(
            id: "care-morning-routine",
            track: .care,
            phase: "Morgen-Routine (Gesicht & UV-Schutz)",
            sequenceNumber: 1,
            title: "Morgenroutine Gesicht & Sonnenschutz (06:15 Uhr)",
            subtitle: "Reinigung von nächtlichem Talg, Wiederherstellung der Ceramid-Barriere und 8h Breitband-UV-Schutz vor Dienstantritt.",
            type: .handsOnLab,
            estimatedHours: 1,
            estimatedMinutes: 5,
            category: "Dermatologie",
            difficulty: "Daily",
            certBadge: "4C Care",
            primaryURL: "https://www.amazon.de/dp/B07C5V894J",
            subtasks: [
                RoadmapSubtask(id: "care-mr-st-1", text: "Schritt 1: Gesichtsreinigung mit CeraVe Hydrating Cleanser (30s)", isDone: false),
                RoadmapSubtask(id: "care-mr-st-2", text: "Schritt 2: Feuchtigkeitsbarriere mit CeraVe Feuchtigkeitscreme verteilen", isDone: false),
                RoadmapSubtask(id: "care-mr-st-3", text: "Schritt 3: Breitband-UV-Schutz La Roche-Posay Anthelios SPF 50+ auftragen", isDone: false)
            ],
            submodules: [
                StudySubmodule(
                    id: "care-mr-sm-1",
                    title: "Schritt 1: Gesichtsreinigung (CeraVe Hydrating Cleanser)",
                    type: .handsOnLab,
                    url: "https://www.amazon.de/dp/B07C5V894J",
                    durationMinutes: 2,
                    isCompleted: false,
                    notes: "Gesicht mit lauwarmem Wasser benetzen. Einen Pumpstoß CeraVe Reinigungslotion 30 Sekunden sanft einmassieren und abspülen. Bewahrt die Barriere mit 3 essenziellen Ceramiden und Hyaluronsäure."
                ),
                StudySubmodule(
                    id: "care-mr-sm-2",
                    title: "Schritt 2: Feuchtigkeitsbarriere (CeraVe Feuchtigkeitscreme)",
                    type: .handsOnLab,
                    url: "https://www.amazon.de/dp/B07C5T648C",
                    durationMinutes: 1,
                    isCompleted: false,
                    notes: "Eine haselnussgroße Menge Feuchtigkeitscreme gleichmäßig auf Gesicht und Hals verteilen. MVE-Technologie sichert kontinuierliche 24h Feuchtigkeitsfreisetzung."
                ),
                StudySubmodule(
                    id: "care-mr-sm-3",
                    title: "Schritt 3: UV-Schutz SPF 50+ (LRP Anthelios Fluid)",
                    type: .handsOnLab,
                    url: "https://www.amazon.de/dp/B09V7N7KLR",
                    durationMinutes: 2,
                    isCompleted: false,
                    notes: "La Roche-Posay Fluid gut schütteln. Großzügig auf Gesicht, Ohren und Nacken auftragen. Zieht rückstandslos ein, brennt nicht in den Augen und schützt vor Melanozyten-Aktivierung."
                )
            ],
            resources: [
                StepResource(id: "res-cmr-1", title: "CeraVe Cleanser (Amazon)", url: "https://www.amazon.de/dp/B07C5V894J", type: "Produkt", badge: "Ceramide"),
                StepResource(id: "res-cmr-2", title: "CeraVe Creme (Amazon)", url: "https://www.amazon.de/dp/B07C5T648C", type: "Produkt", badge: "Barriere"),
                StepResource(id: "res-cmr-3", title: "LRP Anthelios SPF 50+ (Amazon)", url: "https://www.amazon.de/dp/B09V7N7KLR", type: "Produkt", badge: "UV-Schutz")
            ],
            notes: "Morgendliche Reinigung von nächtlichem Talg, Wiederherstellung der Ceramid-Barriere und 8-stündiger Breitband-UV-Schutz vor Dienstantritt.\n\nStrikte 4C Dermatologie-Vorschrift: UV-Schutz verhindert postinflammatorische Hyperpigmentierung (PIH). Mexoryl 400 Breitband-UV-Filter schützt vor ultralangen UVA-Strahlen (380-400nm).",
            isCompleted: false
        ))

        items.append(RoadmapStep(
            id: "care-midday-sunscreen",
            track: .care,
            phase: "Morgen-Routine (Gesicht & UV-Schutz)",
            sequenceNumber: 2,
            title: "20-Sekunden Hals- & UV-Direktapplikation (12:45 Uhr)",
            subtitle: "Direkte Tyrosinase-Hemmung und Unterbindung von UV-induzierter Hyperpigmentierung (PIH).",
            type: .handsOnLab,
            estimatedHours: 1,
            estimatedMinutes: 1,
            category: "Dermatologie",
            difficulty: "Daily",
            certBadge: "UV-Shield",
            primaryURL: "https://www.amazon.de/dp/B09V7N7KLR",
            subtasks: [
                RoadmapSubtask(id: "care-md-st-1", text: "Schritt 1: LRP Fluid schütteln & 1 Fingerlänge aus Spind entnehmen", isDone: false),
                RoadmapSubtask(id: "care-md-st-2", text: "Schritt 2: Direktauftrag auf vorderen Hals & Unterkiefer ohne Waschen", isDone: false)
            ],
            submodules: [
                StudySubmodule(
                    id: "care-md-sm-1",
                    title: "Schritt 1: Fluid schütteln & dosieren (Spind-Depot)",
                    type: .handsOnLab,
                    url: "https://www.amazon.de/dp/B09V7N7KLR",
                    durationMinutes: 1,
                    isCompleted: false,
                    notes: "LRP Anthelios Fluid kurz schütteln. 1 Fingerlänge direkt aus dem Kasernenspind-Depot entnehmen."
                ),
                StudySubmodule(
                    id: "care-md-sm-2",
                    title: "Schritt 2: Gezielter Hals- & Unterkieferauftrag",
                    type: .handsOnLab,
                    url: "https://www.amazon.de/dp/B09V7N7KLR",
                    durationMinutes: 1,
                    isCompleted: false,
                    notes: "Ohne vorheriges Waschen direkt und großzügig auf den vorderen Hals und Unterkiefer auftragen. Verhindert Melanozyten-Reaktivierung nach dem Mittagessen."
                )
            ],
            resources: [],
            notes: "Direkte Tyrosinase-Hemmung und Unterbindung von UV-induzierter Hyperpigmentierung (PIH). Kein vorheriges Waschen erforderlich: 20 Sekunden Direktauftrag aus dem Spind schützt vor Melanozyten-Aktivierung nach dem Mittagessen.",
            isCompleted: false
        ))

        items.append(RoadmapStep(
            id: "care-post-dienst-reset",
            track: .care,
            phase: "Morgen-Routine (Gesicht & UV-Schutz)",
            sequenceNumber: 3,
            title: "Post-Dienst Somatischer Reset (16:30 Uhr)",
            subtitle: "Übergang vom Dienstbetrieb (Dienstschluss 16:30 Uhr), Entlastung und hygienische Vorbereitung.",
            type: .handsOnLab,
            estimatedHours: 1,
            estimatedMinutes: 5,
            category: "Regeneration",
            difficulty: "Daily",
            certBadge: "Reset",
            primaryURL: nil,
            subtasks: [
                RoadmapSubtask(id: "care-pdr-st-1", text: "Schritt 1: Dienstkleidung ablegen & Stubenfenster öffnen", isDone: false),
                RoadmapSubtask(id: "care-pdr-st-2", text: "Schritt 2: Hände & Gesicht erfrischen", isDone: false)
            ],
            submodules: [
                StudySubmodule(
                    id: "care-pdr-sm-1",
                    title: "Schritt 1: Dienstkleidung ablegen & Stube lüften",
                    type: .handsOnLab,
                    url: nil,
                    durationMinutes: 3,
                    isCompleted: false,
                    notes: "Dienstkleidung ablegen, Fenster für 5-10 Minuten öffnen, Sportbekleidung anlegen."
                ),
                StudySubmodule(
                    id: "care-pdr-sm-2",
                    title: "Schritt 2: Hände & Gesicht erfrischen",
                    type: .handsOnLab,
                    url: nil,
                    durationMinutes: 2,
                    isCompleted: false,
                    notes: "Mit lauwarmem frischem Wasser den Staub und Schmutz des Kasernendienstes gründlich abspülen."
                )
            ],
            resources: [],
            notes: "Übergang vom Dienstbetrieb (Dienstschluss 16:30 Uhr). Kasernenkleidung ablegen, Hände waschen, Stube lüften zur Vorbereitung auf Sport und Erholung.",
            isCompleted: false
        ))

        items.append(RoadmapStep(
            id: "care-post-shower-hydration",
            track: .care,
            phase: "Morgen-Routine (Gesicht & UV-Schutz)",
            sequenceNumber: 4,
            title: "Post-Workout Barriere-Repair (17:45 Uhr)",
            subtitle: "Eindämmung des transepidermalen Wasserverlusts (TEWL) nach dem Duschen.",
            type: .handsOnLab,
            estimatedHours: 1,
            estimatedMinutes: 5,
            category: "Dermatologie",
            difficulty: "Daily",
            certBadge: "TEWL-Repair",
            primaryURL: "https://www.amazon.de/dp/B07C5T648C",
            subtasks: [
                RoadmapSubtask(id: "care-psh-st-1", text: "Schritt 1: Sanfte Reinigung unter der Dusche mit CeraVe Cleanser", isDone: false),
                RoadmapSubtask(id: "care-psh-st-2", text: "Schritt 2: Feuchtigkeitsversiegelung auf leicht feuchter Haut", isDone: false)
            ],
            submodules: [
                StudySubmodule(
                    id: "care-psh-sm-1",
                    title: "Schritt 1: Sanfte Reinigung unter der Dusche",
                    type: .handsOnLab,
                    url: "https://www.amazon.de/dp/B07C5V894J",
                    durationMinutes: 2,
                    isCompleted: false,
                    notes: "Unter der Dusche Gesicht mit CeraVe Cleanser reinigen, nicht reiben. Lauwarmes Wasser verwenden."
                ),
                StudySubmodule(
                    id: "care-psh-sm-2",
                    title: "Schritt 2: Feuchtigkeitsversiegelung auf feuchter Haut",
                    type: .handsOnLab,
                    url: "https://www.amazon.de/dp/B07C5T648C",
                    durationMinutes: 3,
                    isCompleted: false,
                    notes: "Auf die noch leicht feuchte Haut sofort CeraVe Feuchtigkeitscreme auftragen, um Wasser in der Epidermis einzuschließen."
                )
            ],
            resources: [],
            notes: "Eindämmung des transepidermalen Wasserverlusts (TEWL) nach dem Duschen. Ceramide restrukturieren die Barriereschicht.",
            isCompleted: false
        ))

        // MARK: - 2. Bartpflege & Pseudofolliculitis Barbae
        items.append(RoadmapStep(
            id: "care-shaving-protocol",
            track: .care,
            phase: "Bartpflege & Pseudofolliculitis Barbae",
            sequenceNumber: 1,
            title: "4C Bart-Trockenschnitt & Antiseptik (18:00 Uhr - Di, Do, Sa)",
            subtitle: "Strikte PFB- und PIH-Prävention bei 4C-Haar. JRL Trimmer 0.5mm & Tend Skin.",
            type: .handsOnLab,
            estimatedHours: 1,
            estimatedMinutes: 10,
            category: "Bartpflege",
            difficulty: "Turnus",
            certBadge: "Anti-PFB",
            primaryURL: "https://www.amazon.de/dp/B0C4M4Q97S",
            subtasks: [
                RoadmapSubtask(id: "care-sh-st-1", text: "Schritt 1: Trockenschnitt mit JRL Diamante Trimmer (0.5mm Stoppeln)", isDone: false),
                RoadmapSubtask(id: "care-sh-st-2", text: "Schritt 2: Tend Skin punktuell auf Hals & Unterkiefer tupfen", isDone: false),
                RoadmapSubtask(id: "care-sh-st-3", text: "Schritt 3: CeraVe Feuchtigkeitscreme Barriere-Schutz auftragen", isDone: false)
            ],
            submodules: [
                StudySubmodule(
                    id: "care-sh-sm-1",
                    title: "Schritt 1: Trockenschnitt 0.5mm (JRL Diamante Trimmer)",
                    type: .handsOnLab,
                    url: "https://www.amazon.de/dp/B0C4M4Q97S",
                    durationMinutes: 6,
                    isCompleted: false,
                    notes: "Trockenschnitt mit JRL FreshFade 2025T Diamante Trimmer ausschließlich in Wuchsrichtung. Schnittlänge 0.5–1.0mm belassen, Klinge niemals aufdrücken."
                ),
                StudySubmodule(
                    id: "care-sh-sm-2",
                    title: "Schritt 2: Tend Skin Antiseptikphase (Punktuell tupfen)",
                    type: .handsOnLab,
                    url: "https://www.amazon.de/dp/B0002CAQ6G",
                    durationMinutes: 2,
                    isCompleted: false,
                    notes: "Etwas Tend Skin auf Wattepad geben. Nur punktuell auf Unterkiefer und Hals tupfen (nicht reiben!). 1-2 Minuten trocknen lassen. Niemals mit BHA kombinieren!"
                ),
                StudySubmodule(
                    id: "care-sh-sm-3",
                    title: "Schritt 3: Barriere-Schutz (CeraVe Creme)",
                    type: .handsOnLab,
                    url: "https://www.amazon.de/dp/B07C5T648C",
                    durationMinutes: 2,
                    isCompleted: false,
                    notes: "Großzügig CeraVe Feuchtigkeitscreme auftragen zur Beruhigung und epidermalen Barriereregeneration."
                )
            ],
            resources: [
                StepResource(id: "res-csh-1", title: "JRL FreshFade 2025T Trimmer", url: "https://www.amazon.de/dp/B0C4M4Q97S", type: "Equipment", badge: "Trimmer"),
                StepResource(id: "res-csh-2", title: "Tend Skin Post-Shave Solution", url: "https://www.amazon.de/dp/B0002CAQ6G", type: "Wirkstoff", badge: "Antiseptik")
            ],
            notes: "Strikte PFB- und PIH-Prävention bei 4C-Haar. JRL Trimmer niemals aufpressen (0.5 mm Stoppelrest schützt vor subkutanem Einwachsen). Tend Skin nur tupfen, nicht reiben. 24h-Sperre für BHA am Abend. Nassrasur ist strikt kontraindiziert bei Pseudofolliculitis Barbae.",
            isCompleted: false
        ))

        // MARK: - 3. Abend-Routine (Reinigung & Barriere)
        items.append(RoadmapStep(
            id: "care-evening-trimmtag",
            track: .care,
            phase: "Abend-Routine (Reinigung & Barriere)",
            sequenceNumber: 1,
            title: "Abendroutine an Trimmtagen (21:30 Uhr - 24h Säurensperre)",
            subtitle: "Post-Rasur Regeneration. BHA strikt weglassen wegen Tend Skin. Azelainsäure 10% gegen PIH.",
            type: .handsOnLab,
            estimatedHours: 1,
            estimatedMinutes: 10,
            category: "Dermatologie",
            difficulty: "Turnus",
            certBadge: "Trimmtag",
            primaryURL: "https://www.amazon.de/dp/B01MT293Q3",
            subtasks: [
                RoadmapSubtask(id: "care-ett-st-1", text: "Schritt 1: CeraVe Cleanser sanfte Vorreinigung", isDone: false),
                RoadmapSubtask(id: "care-ett-st-2", text: "Schritt 2: BHA weglassen! (24h Säurensperre)", isDone: false),
                RoadmapSubtask(id: "care-ett-st-3", text: "Schritt 3: Azelainsäure 10% auf Unterkiefer auftragen", isDone: false),
                RoadmapSubtask(id: "care-ett-st-4", text: "Schritt 4: Okklusive CeraVe Feuchtigkeitscreme auftragen", isDone: false)
            ],
            submodules: [
                StudySubmodule(
                    id: "care-ett-sm-1",
                    title: "Schritt 1: Sanfte Vorreinigung (CeraVe Cleanser)",
                    type: .handsOnLab,
                    url: "https://www.amazon.de/dp/B07C5V894J",
                    durationMinutes: 2,
                    isCompleted: false,
                    notes: "CeraVe Hydrating Cleanser sanft verteilen und mit lauwarmem Wasser abspülen. Wäscht Schweiß und Partikel ab."
                ),
                StudySubmodule(
                    id: "care-ett-sm-2",
                    title: "Schritt 2: BHA weglassen! (24h-Säuren-Sperre)",
                    type: .handsOnLab,
                    url: nil,
                    durationMinutes: 1,
                    isCompleted: false,
                    notes: "BHA strikt aussetzen! Da um 18:00 Uhr bereits Tend Skin genutzt wurde, würde BHA zu einer chemischen Reizung führen."
                ),
                StudySubmodule(
                    id: "care-ett-sm-3",
                    title: "Schritt 3: Azelainsäure 10% Suspension",
                    type: .handsOnLab,
                    url: "https://www.amazon.de/dp/B01MT293Q3",
                    durationMinutes: 4,
                    isCompleted: false,
                    notes: "Eine erbsengroße Menge The Ordinary Azelaic Acid 10% auf die dunklen Stellen am Unterkiefer und Hals auftragen. 5-10 Minuten einziehen lassen."
                ),
                StudySubmodule(
                    id: "care-ett-sm-4",
                    title: "Schritt 4: Okklusive Feuchtigkeit (CeraVe Creme)",
                    type: .handsOnLab,
                    url: "https://www.amazon.de/dp/B07C5T648C",
                    durationMinutes: 3,
                    isCompleted: false,
                    notes: "CeraVe Feuchtigkeitscreme als Barriere-Abschluss auftragen, um die Wirkstoffe über Nacht einzuschließen."
                )
            ],
            resources: [
                StepResource(id: "res-cett-1", title: "Azelaic Acid 10% (Amazon)", url: "https://www.amazon.de/dp/B01MT293Q3", type: "Wirkstoff", badge: "Anti-PIH")
            ],
            notes: "Post-Rasur Regeneration. BHA strikt weglassen wegen Tend Skin-Anwendung um 18:00 Uhr (24h-Säuren-Sperre). Azelainsäure 10% gezielt gegen PIH-Pigmentflecken. Restrukturiert die epidermale Lipidbarriere.",
            isCompleted: false
        ))

        items.append(RoadmapStep(
            id: "care-evening-routine",
            track: .care,
            phase: "Abend-Routine (Reinigung & Barriere)",
            sequenceNumber: 2,
            title: "Abendroutine an rasurfreien Tagen (21:30 Uhr - BHA-Peeling)",
            subtitle: "Follikel-Tiefenreinigung und PIH-Behandlung an den 4 rasurfreien Abenden (Mo, Di, Do, Sa).",
            type: .handsOnLab,
            estimatedHours: 1,
            estimatedMinutes: 15,
            category: "Dermatologie",
            difficulty: "Daily",
            certBadge: "BHA-Peeling",
            primaryURL: "https://www.amazon.de/dp/B00949CTQQ",
            subtasks: [
                RoadmapSubtask(id: "care-er-st-1", text: "Schritt 1: CeraVe Cleanser sanfte Vorreinigung", isDone: false),
                RoadmapSubtask(id: "care-er-st-2", text: "Schritt 2: Paula's Choice 2% BHA Peeling (10-15 Min einziehen)", isDone: false),
                RoadmapSubtask(id: "care-er-st-3", text: "Schritt 3: Azelaic Acid 10% Anti-PIH Wirkstoff auftragen", isDone: false),
                RoadmapSubtask(id: "care-er-st-4", text: "Schritt 4: CeraVe Feuchtigkeitscreme okklusive Nachtpflege", isDone: false)
            ],
            submodules: [
                StudySubmodule(
                    id: "care-er-sm-1",
                    title: "Schritt 1: Sanfte Vorreinigung (CeraVe Cleanser)",
                    type: .handsOnLab,
                    url: "https://www.amazon.de/dp/B07C5V894J",
                    durationMinutes: 2,
                    isCompleted: false,
                    notes: "CeraVe Hydrating Cleanser auftragen, 30s sanft einmassieren und abspülen. Gesicht trocken tupfen."
                ),
                StudySubmodule(
                    id: "care-er-sm-2",
                    title: "Schritt 2: Chemische Exfoliation (Paula's Choice 2% BHA)",
                    type: .handsOnLab,
                    url: "https://www.amazon.de/dp/B00949CTQQ",
                    durationMinutes: 5,
                    isCompleted: false,
                    notes: "Paula's Choice 2% BHA Liquid mit den Handflächen sanft einklopfen. Zwingend 10 bis 15 Minuten einziehen lassen vor dem nächsten Schritt!"
                ),
                StudySubmodule(
                    id: "care-er-sm-3",
                    title: "Schritt 3: Anti-PIH Wirkstoff (Azelaic Acid 10%)",
                    type: .handsOnLab,
                    url: "https://www.amazon.de/dp/B01MT293Q3",
                    durationMinutes: 4,
                    isCompleted: false,
                    notes: "Eine erbsengroße Menge Azelaic Acid 10% auf Wangen, Kiefer und Hals auftragen. Hemmt Tyrosinase und gleicht den Teint aus."
                ),
                StudySubmodule(
                    id: "care-er-sm-4",
                    title: "Schritt 4: Okklusive Nachtpflege (CeraVe Feuchtigkeitscreme)",
                    type: .handsOnLab,
                    url: "https://www.amazon.de/dp/B07C5T648C",
                    durationMinutes: 4,
                    isCompleted: false,
                    notes: "Reichhaltig CeraVe Feuchtigkeitscreme auftragen. Schützt die Lipidbarriere während der zellulären Nachtregeneration."
                )
            ],
            resources: [
                StepResource(id: "res-cer-1", title: "Paula's Choice 2% BHA Liquid", url: "https://www.amazon.de/dp/B00949CTQQ", type: "Peeling", badge: "Salicylsäure"),
                StepResource(id: "res-cer-2", title: "The Ordinary Azelaic Acid 10%", url: "https://www.amazon.de/dp/B01MT293Q3", type: "Wirkstoff", badge: "Azelainsäure")
            ],
            notes: "Follikel-Tiefenreinigung und PIH-Behandlung an den 4 rasurfreien Abenden (Mo, Di, Do, Sa). 2% BHA (Salicylsäure) klärt die Follikel tiefenwirksam und löst Talg, Azelainsäure 10% hemmt Tyrosinase und Melaninbildung.",
            isCompleted: false
        ))

        items.append(RoadmapStep(
            id: "care-oral-morning",
            track: .care,
            phase: "Abend-Routine (Reinigung & Barriere)",
            sequenceNumber: 3,
            title: "Mund- & Zahnpflege Morgen (06:20 Uhr)",
            subtitle: "Beseitigung des nächtlichen Biofilms und Neutralisation saurer Refluxrückstände.",
            type: .handsOnLab,
            estimatedHours: 1,
            estimatedMinutes: 4,
            category: "Zahnpflege",
            difficulty: "Daily",
            certBadge: "Oral Care",
            primaryURL: "https://www.amazon.de/dp/B07P7N6J8S",
            subtasks: [
                RoadmapSubtask(id: "care-om-st-1", text: "Schritt 1: TePe Zungenschaber (2-3x sanft abziehen)", isDone: false),
                RoadmapSubtask(id: "care-om-st-2", text: "Schritt 2: Schallzahnbürste 2 Minuten mit Elmex Aminfluorid", isDone: false),
                RoadmapSubtask(id: "care-om-st-3", text: "Schritt 3: Ausspucken ohne Nachspülen (Fluorid-Depot erhalten)", isDone: false)
            ],
            submodules: [
                StudySubmodule(
                    id: "care-om-sm-1",
                    title: "Schritt 1: Zungenreinigung (TePe Good Schaber)",
                    type: .handsOnLab,
                    url: "https://www.amazon.de/dp/B07P7N6J8S",
                    durationMinutes: 1,
                    isCompleted: false,
                    notes: "Zunge herausstrecken, Schaber hinten ansetzen und 2-3 Mal sanft nach vorne ziehen. Unter fließendem Wasser abspülen. Senkt flüchtige Schwefelverbindungen um 75%."
                ),
                StudySubmodule(
                    id: "care-om-sm-2",
                    title: "Schritt 2: Schallzahnbürste 2 Min (Oral-B iO & Elmex)",
                    type: .handsOnLab,
                    url: "https://www.amazon.de/dp/B09TDQNZ6V",
                    durationMinutes: 2,
                    isCompleted: false,
                    notes: "Erbsengroße Menge Elmex Aminfluorid auftragen. 4 Quadranten je 30 Sekunden im 45-Grad-Winkel ohne Druck reinigen."
                ),
                StudySubmodule(
                    id: "care-om-sm-3",
                    title: "Schritt 3: Spucken ohne Wasserspülung (Fluorid-Depot)",
                    type: .handsOnLab,
                    url: "https://www.amazon.de/dp/B00E4M89FE",
                    durationMinutes: 1,
                    isCompleted: false,
                    notes: "Zahnpasta nur ausspucken, Schmelz NICHT mit Wasser nachspülen, um das Calciumfluorid-Depot zu erhalten."
                )
            ],
            resources: [
                StepResource(id: "res-com-1", title: "TePe Zungenschaber", url: "https://www.amazon.de/dp/B07P7N6J8S", type: "Tool", badge: "Zungenreinigung"),
                StepResource(id: "res-com-2", title: "Elmex Kariesschutz", url: "https://www.amazon.de/dp/B00E4M89FE", type: "Zahnpasta", badge: "Aminfluorid")
            ],
            notes: "Beseitigung des nächtlichen Biofilms und Neutralisation saurer Refluxrückstände. Zungenschaber senkt anaerobe Bakterien um 75%. Schallzahnbürste schont bei Andruckkontrolle Zahnschmelz und Zahnfleischrand. Nicht mit Wasser nachspülen!",
            isCompleted: false
        ))

        items.append(RoadmapStep(
            id: "care-oral-evening",
            track: .care,
            phase: "Abend-Routine (Reinigung & Barriere)",
            sequenceNumber: 4,
            title: "Mund- & Interdental-Tiefenreinigung Abend (21:45 Uhr)",
            subtitle: "Gründliche Plaquebeseitigung in den Interdentalräumen vor der Nachtruhe.",
            type: .handsOnLab,
            estimatedHours: 1,
            estimatedMinutes: 6,
            category: "Zahnpflege",
            difficulty: "Daily",
            certBadge: "Interdental",
            primaryURL: "https://www.amazon.de/dp/B002ZCH1H6",
            subtasks: [
                RoadmapSubtask(id: "care-oe-st-1", text: "Schritt 1: Curaprox Zahnseide in alle Zwischenräume führen", isDone: false),
                RoadmapSubtask(id: "care-oe-st-2", text: "Schritt 2: Schallzahnbürste 2 Minuten systematisch", isDone: false),
                RoadmapSubtask(id: "care-oe-st-3", text: "Schritt 3: Alkoholfreie Mundspülung 30 Sekunden", isDone: false)
            ],
            submodules: [
                StudySubmodule(
                    id: "care-oe-sm-1",
                    title: "Schritt 1: Curaprox Zahnseide / Interdentalreinigung",
                    type: .handsOnLab,
                    url: "https://www.amazon.de/dp/B002ZCH1H6",
                    durationMinutes: 2,
                    isCompleted: false,
                    notes: "Mit gewachster Zahnseide jeden Zahnzwischenraum vorsichtig c-förmig umschließen und Plaque aufwärts abstreifen. Erreicht die 40% der Zahnoberfläche, die Bürsten verpassen."
                ),
                StudySubmodule(
                    id: "care-oe-sm-2",
                    title: "Schritt 2: Schallzahnbürste (2 Minuten systematisch)",
                    type: .handsOnLab,
                    url: "https://www.amazon.de/dp/B09TDQNZ6V",
                    durationMinutes: 2,
                    isCompleted: false,
                    notes: "Alle Außen-, Innen- und Kauflächen mit Schallvibrationen putzen. Auf Andruckkontrolle achten."
                ),
                StudySubmodule(
                    id: "care-oe-sm-3",
                    title: "Schritt 3: Alkoholfreie Mundspülung (30s spülen)",
                    type: .handsOnLab,
                    url: "https://www.amazon.de/dp/B01B79555M",
                    durationMinutes: 2,
                    isCompleted: false,
                    notes: "10-15 ml Sensodyne Cool Mint 30 Sekunden kräftig im Mund bewegen. Alkoholfrei brennt nicht bei Stillem Reflux und schützt Schleimhäute."
                )
            ],
            resources: [
                StepResource(id: "res-coe-1", title: "Curaprox DF 834 Zahnseide", url: "https://www.amazon.de/dp/B002ZCH1H6", type: "Zahnseide", badge: "Interdental"),
                StepResource(id: "res-coe-2", title: "Sensodyne Cool Mint Spülung", url: "https://www.amazon.de/dp/B01B79555M", type: "Mundspülung", badge: "Alkoholfrei")
            ],
            notes: "Gründliche Plaquebeseitigung in den Interdentalräumen vor der Nachtruhe. Verhindert Säureerosionen bei stillem Reflux und schützt vor Karies an schwer zugänglichen Zahnkontaktpunkten.",
            isCompleted: false
        ))

        // MARK: - 4. Afro 4C Haarpflege & Scalp Detox
        items.append(RoadmapStep(
            id: "care-hair-loc",
            track: .care,
            phase: "Afro 4C Haarpflege & Scalp Detox",
            sequenceNumber: 1,
            title: "Afro 4C Haarpflege (LOC-Methode - 20:00 Uhr)",
            subtitle: "Gezielte Hydratation und Feuchtigkeitsversiegelung für hochporöses 4C-Haar.",
            type: .handsOnLab,
            estimatedHours: 1,
            estimatedMinutes: 12,
            category: "Haarpflege",
            difficulty: "Turnus",
            certBadge: "LOC-Method",
            primaryURL: "https://www.amazon.de/dp/B07N7PK9QK",
            subtasks: [
                RoadmapSubtask(id: "care-hl-st-1", text: "Schritt 1: Liquid Feuchtigkeitsspray auftragen", isDone: false),
                RoadmapSubtask(id: "care-hl-st-2", text: "Schritt 2: Mielle Rosemary Mint Öl auf Kopfhaut einmassieren", isDone: false),
                RoadmapSubtask(id: "care-hl-st-3", text: "Schritt 3: Cantu Leave-in & Castor Oil Schaftversiegelung", isDone: false),
                RoadmapSubtask(id: "care-hl-st-4", text: "Schritt 4: Satin Durag vor Nachtruhe anlegen", isDone: false)
            ],
            submodules: [
                StudySubmodule(
                    id: "care-hloc-sm-1",
                    title: "Schritt 1: Liquid (Aloe / Feuchtigkeitsspray)",
                    type: .handsOnLab,
                    url: nil,
                    durationMinutes: 2,
                    isCompleted: false,
                    notes: "Haare mit lauwarmem Wasser oder Aloe-Vera-Spray leicht einsprühen zur Öffnung der Cuticula."
                ),
                StudySubmodule(
                    id: "care-hloc-sm-2",
                    title: "Schritt 2: Oil (Mielle Rosemary Mint Scalp Oil)",
                    type: .handsOnLab,
                    url: "https://www.amazon.de/dp/B07N7PK9QK",
                    durationMinutes: 3,
                    isCompleted: false,
                    notes: "Mielle Rosemary Mint Öl direkt auf die Kopfhaut träufeln und 2 Minuten kreisend einmassieren. Stimuliert die Follikelzirkulation."
                ),
                StudySubmodule(
                    id: "care-hloc-sm-3",
                    title: "Schritt 3: Cream & Castor Oil (Schaftversiegelung)",
                    type: .handsOnLab,
                    url: "https://www.amazon.de/dp/B00449W35S",
                    durationMinutes: 4,
                    isCompleted: false,
                    notes: "Cantu Shea Butter Leave-in Creme im Haar verteilen und die Spitzen mit Jamaican Black Castor Oil okklusiv versiegeln."
                ),
                StudySubmodule(
                    id: "care-hloc-sm-4",
                    title: "Schritt 4: Satin Durag Kompressionshaube anlegen",
                    type: .handsOnLab,
                    url: "https://www.amazon.de/dp/B08DFW9XZ3",
                    durationMinutes: 3,
                    isCompleted: false,
                    notes: "Vor dem Schlafengehen Seiden-Satin Durag anlegen. Verhindert Scherkräfte und Feuchtigkeitsentzug auf Baumwollkissen."
                )
            ],
            resources: [
                StepResource(id: "res-chl-1", title: "Mielle Rosemary Mint Oil", url: "https://www.amazon.de/dp/B07N7PK9QK", type: "Haaröl", badge: "Kopfhaut"),
                StepResource(id: "res-chl-2", title: "Cantu Leave-In Cream", url: "https://www.amazon.de/dp/B00449W35S", type: "Creme", badge: "Hydration"),
                StepResource(id: "res-chl-3", title: "Satin Durag", url: "https://www.amazon.de/dp/B08DFW9XZ3", type: "Equipment", badge: "Schutz")
            ],
            notes: "Gezielte Hydratation für hochporöses 4C-Haar. Die LOC-Methode (Liquid, Oil, Cream) bindet Feuchtigkeit dauerhaft und verhindert mechanischen Haarbruch unter Helmen und Mützen.",
            isCompleted: false
        ))

        items.append(RoadmapStep(
            id: "care-hair-washday",
            track: .care,
            phase: "Afro 4C Haarpflege & Scalp Detox",
            sequenceNumber: 2,
            title: "4C Scalp Detox & Tiefenpflege (Wash Day - Sonntag 19:00 Uhr)",
            subtitle: "Wöchentliche Tiefenreinigung der 4C-Kopfhaut von Talg, Schweiß und Ölablagerungen.",
            type: .handsOnLab,
            estimatedHours: 1,
            estimatedMinutes: 20,
            category: "Haarpflege",
            difficulty: "Weekly",
            certBadge: "Scalp-Detox",
            primaryURL: "https://www.amazon.de/dp/B0784T5Q21",
            subtasks: [
                RoadmapSubtask(id: "care-hwd-st-1", text: "Schritt 1: Sulfatfreies Mielle Shampoo sanft einmassieren", isDone: false),
                RoadmapSubtask(id: "care-hwd-st-2", text: "Schritt 2: SheaMoisture Manuka Masque 10 Min einwirken lassen", isDone: false),
                RoadmapSubtask(id: "care-hwd-st-3", text: "Schritt 3: Gründlich lauwarm ausspülen", isDone: false),
                RoadmapSubtask(id: "care-hwd-st-4", text: "Schritt 4: LOC-Versiegelung & Durag aufsetzen", isDone: false)
            ],
            submodules: [
                StudySubmodule(
                    id: "care-hwd-sm-1",
                    title: "Schritt 1: Sulfatfreie Kopfhautreinigung (Mielle Shampoo)",
                    type: .handsOnLab,
                    url: "https://www.amazon.de/dp/B0784T5Q21",
                    durationMinutes: 5,
                    isCompleted: false,
                    notes: "Mielle Detangling Shampoo sanft mit den Fingerbeeren kreisend in die Kopfhaut einarbeiten und gründlich mit lauwarmem Wasser ausspülen."
                ),
                StudySubmodule(
                    id: "care-hwd-sm-2",
                    title: "Schritt 2: Intensive Tiefenmaske 10 Min (SheaMoisture Masque)",
                    type: .handsOnLab,
                    url: "https://www.amazon.de/dp/B00M850J9M",
                    durationMinutes: 10,
                    isCompleted: false,
                    notes: "SheaMoisture Manuka Honey & Mafura Oil Masque von den Wurzeln bis in die Spitzen verteilen. 10 bis 15 Minuten unter Duschhaube einwirken lassen."
                ),
                StudySubmodule(
                    id: "care-hwd-sm-3",
                    title: "Schritt 3: Kalt/Lauwarm ausspülen",
                    type: .handsOnLab,
                    url: nil,
                    durationMinutes: 2,
                    isCompleted: false,
                    notes: "Maske gründlich ausspülen, um die Schuppenschicht der Haarfaser wieder zu schließen."
                ),
                StudySubmodule(
                    id: "care-hwd-sm-4",
                    title: "Schritt 4: LOC-Versiegelung & Satin Durag",
                    type: .handsOnLab,
                    url: "https://www.amazon.de/dp/B08DFW9XZ3",
                    durationMinutes: 3,
                    isCompleted: false,
                    notes: "Unmittelbar Liquid, Mielle Öl und Cantu Leave-in auftragen, danach Satin Durag anlegen."
                )
            ],
            resources: [
                StepResource(id: "res-chwd-1", title: "Mielle Detangling Shampoo", url: "https://www.amazon.de/dp/B0784T5Q21", type: "Shampoo", badge: "Sulfatfrei"),
                StepResource(id: "res-chwd-2", title: "SheaMoisture Manuka Masque", url: "https://www.amazon.de/dp/B00M850J9M", type: "Maske", badge: "Tiefenpflege")
            ],
            notes: "Wöchentliche Tiefenreinigung der 4C-Kopfhaut von Talg, Schweiß und Ölablagerungen. Sulfatfreies Shampoo schützt die Feuchtigkeitsbarriere, Tiefenmaske restrukturiert die Schuppenschicht nach militärischer Helmnutzung.",
            isCompleted: false
        ))

        // MARK: - 5. Körper, Intim & Bundeswehr-Marschschutz
        items.append(RoadmapStep(
            id: "care-groin-march",
            track: .care,
            phase: "Körper, Intim & Bundeswehr-Marschschutz",
            sequenceNumber: 1,
            title: "Leisten- & Intimbarriere (Post-Dienst / Marsch - 17:00 Uhr)",
            subtitle: "Prävention von Intertrigo (Wolfgelaufen) unter schwerer Dienstbekleidung.",
            type: .handsOnLab,
            estimatedHours: 1,
            estimatedMinutes: 5,
            category: "Intimpflege",
            difficulty: "Daily",
            certBadge: "Marschschutz",
            primaryURL: "https://www.amazon.de/dp/B000KU95LM",
            subtasks: [
                RoadmapSubtask(id: "care-gm-st-1", text: "Schritt 1: Schonendes Abspülen mit Wasser (kein Reiben)", isDone: false),
                RoadmapSubtask(id: "care-gm-st-2", text: "Schritt 2: Sebamed Waschlotion pH 3.8 / 5.5 verwenden", isDone: false),
                RoadmapSubtask(id: "care-gm-st-3", text: "Schritt 3: BodyGlide Anti-Chafing Balm / Bepanthen auftragen", isDone: false),
                RoadmapSubtask(id: "care-gm-st-4", text: "Schritt 4: Saubere Baumwollunterwäsche anlegen", isDone: false)
            ],
            submodules: [
                StudySubmodule(
                    id: "care-gm-sm-1",
                    title: "Schritt 1: Sanftes Abspülen (Lauwarmes Wasser / Bidet)",
                    type: .handsOnLab,
                    url: nil,
                    durationMinutes: 1,
                    isCompleted: false,
                    notes: "Leisten- und Perianalbereich mit lauwarmem Wasser schonend abspülen. Reiben strikt vermeiden, nur sanft mit sauberem Tuch trocken tupfen."
                ),
                StudySubmodule(
                    id: "care-gm-sm-2",
                    title: "Schritt 2: Milde Waschlotion pH 3.8 / 5.5 (Sebamed)",
                    type: .handsOnLab,
                    url: "https://www.amazon.de/dp/B000KU95LM",
                    durationMinutes: 1,
                    isCompleted: false,
                    notes: "Sebamed Intim-Waschlotion sparsam in den Leistenfalten aufschäumen und rückstandslos mit Wasser abspülen."
                ),
                StudySubmodule(
                    id: "care-gm-sm-3",
                    title: "Schritt 3: Anti-Chafing / Wundschutzbarriere",
                    type: .handsOnLab,
                    url: "https://www.amazon.de/dp/B00288L2N6",
                    durationMinutes: 2,
                    isCompleted: false,
                    notes: "Vor langen Märschen oder bei Reizungen BodyGlide Stick oder dünn Bepanthen Wund- und Heilsalbe auftragen."
                ),
                StudySubmodule(
                    id: "care-gm-sm-4",
                    title: "Schritt 4: Atmungsaktive 100% Baumwollwäsche",
                    type: .handsOnLab,
                    url: nil,
                    durationMinutes: 1,
                    isCompleted: false,
                    notes: "Frische, lockere Baumwollunterwäsche anziehen, um Feuchtigkeitsstau und Reibung zu eliminieren."
                )
            ],
            resources: [
                StepResource(id: "res-cgm-1", title: "Sebamed Intim-Waschlotion", url: "https://www.amazon.de/dp/B000KU95LM", type: "Lotion", badge: "pH 3.8"),
                StepResource(id: "res-cgm-2", title: "Body Glide Anti-Chafing Stick", url: "https://www.amazon.de/dp/B00288L2N6", type: "Balsam", badge: "Marschschutz")
            ],
            notes: "Prävention von Intertrigo (Wolfgelaufen) unter schwerer Dienstbekleidung. Postoperative Analhygiene (BWK Ulm): Sanftes Abduschen/Bidet statt mechanischem Reiben. Saure Waschlotion (pH 3.8-5.5) schützt vor mykotischen Infektionen.",
            isCompleted: false
        ))

        items.append(RoadmapStep(
            id: "care-foot-nails",
            track: .care,
            phase: "Körper, Intim & Bundeswehr-Marschschutz",
            sequenceNumber: 2,
            title: "Nagel- & Fußdrill (Bundeswehr Marschschutz - Wöchentlich 19:30 Uhr)",
            subtitle: "Strikte Verhinderung von Unguis incarnatus und Fußpilz im Kampfstiefel.",
            type: .handsOnLab,
            estimatedHours: 1,
            estimatedMinutes: 10,
            category: "Fußpflege",
            difficulty: "Weekly",
            certBadge: "Kampfstiefel",
            primaryURL: "https://www.amazon.de/dp/B07N4T49R4",
            subtasks: [
                RoadmapSubtask(id: "care-fn-st-1", text: "Schritt 1: Zehennägel strikt gerade kürzen (1mm Überstand belassen)", isDone: false),
                RoadmapSubtask(id: "care-fn-st-2", text: "Schritt 2: Feine Grate mit Mont Bleu Glasfeile versiegeln", isDone: false),
                RoadmapSubtask(id: "care-fn-st-3", text: "Schritt 3: Fingernägel feilen & Cuticle Oil einmassieren", isDone: false),
                RoadmapSubtask(id: "care-fn-st-4", text: "Schritt 4: Urea 15% Hornhautpflege auf Ballen & Fersen einmassieren", isDone: false)
            ],
            submodules: [
                StudySubmodule(
                    id: "care-fn-sm-1",
                    title: "Schritt 1: Zehennägel strikt gerade kürzen (Victorinox Knipser)",
                    type: .handsOnLab,
                    url: "https://www.amazon.de/dp/B07N4T49R4",
                    durationMinutes: 3,
                    isCompleted: false,
                    notes: "Zehennägel mit dem Edelstahl-Knipser strikt gerade kürzen. Ecken NIEMALS rund ausschneiden! 1 mm Überstand belassen zur Vermeidung von Unguis incarnatus."
                ),
                StudySubmodule(
                    id: "care-fn-sm-2",
                    title: "Schritt 2: Kanten mit Glasnagelfeile versiegeln",
                    type: .handsOnLab,
                    url: "https://www.amazon.de/dp/B00537I0TU",
                    durationMinutes: 2,
                    isCompleted: false,
                    notes: "Mit der gehärteten Mont Bleu Glasnagelfeile feine Grate und Kanten sanft glätten, um Reibung an Socken zu eliminieren."
                ),
                StudySubmodule(
                    id: "care-fn-sm-3",
                    title: "Schritt 3: Fingernägel formen & Nagelbett-Öl",
                    type: .handsOnLab,
                    url: "https://www.amazon.de/dp/B000AA5VD6",
                    durationMinutes: 2,
                    isCompleted: false,
                    notes: "Fingernägel militärisch kurz und sauber feilen. Einen Tropfen Sally Hansen Vitamin E Öl auf die Nagelfalz einmassieren."
                ),
                StudySubmodule(
                    id: "care-fn-sm-4",
                    title: "Schritt 4: Urea 15% Hornhautpflege (Eucerin UreaRepair)",
                    type: .handsOnLab,
                    url: "https://www.amazon.de/dp/B00V4L7J58",
                    durationMinutes: 3,
                    isCompleted: false,
                    notes: "Eucerin UreaRepair PLUS Fußcreme großzügig auf Fersen und Fußballen einmassieren. Keratolytische Wirkung beugt Marschblasen und Rhagaden vor."
                )
            ],
            resources: [
                StepResource(id: "res-cfn-1", title: "Victorinox Nagelknipser", url: "https://www.amazon.de/dp/B07N4T49R4", type: "Tool", badge: "Edelstahl"),
                StepResource(id: "res-cfn-2", title: "Mont Bleu Glasnagelfeile", url: "https://www.amazon.de/dp/B00537I0TU", type: "Tool", badge: "Glas"),
                StepResource(id: "res-cfn-3", title: "Eucerin UreaRepair 15%", url: "https://www.amazon.de/dp/B00V4L7J58", type: "Creme", badge: "Urea")
            ],
            notes: "Strikte Verhinderung von Unguis incarnatus (eingewachsenen Zehennägeln) und Tinea pedis (Fußpilz) im Kampfstiefel. Zehennägel müssen gerade geschnitten werden. Urea 10-15% löst Verhornungen schmerzfrei auf.",
            isCompleted: false
        ))

        items.append(RoadmapStep(
            id: "care-body-reset",
            track: .care,
            phase: "Körper, Intim & Bundeswehr-Marschschutz",
            sequenceNumber: 3,
            title: "Ganzkörper Dusch- & Follikelschutz (17:15 Uhr)",
            subtitle: "Verhinderung von Acne Mechanica und Rumpf-Follikulitis durch schwere Trageausrüstung.",
            type: .handsOnLab,
            estimatedHours: 1,
            estimatedMinutes: 8,
            category: "Körperpflege",
            difficulty: "Daily",
            certBadge: "Body-Shield",
            primaryURL: "https://www.amazon.de/dp/B07C5V894J",
            subtasks: [
                RoadmapSubtask(id: "care-br-st-1", text: "Schritt 1: Schweißsalze mit lauwarmem Wasser abspülen", isDone: false),
                RoadmapSubtask(id: "care-br-st-2", text: "Schritt 2: CeraVe Cleanser auf Schultern & Rücken verteilen", isDone: false),
                RoadmapSubtask(id: "care-br-st-3", text: "Schritt 3: Sanftes Trockentupfen mit frischem Handtuch", isDone: false)
            ],
            submodules: [
                StudySubmodule(
                    id: "care-br-sm-1",
                    title: "Schritt 1: Schweißsalze mit lauwarmem Wasser abspülen",
                    type: .handsOnLab,
                    url: nil,
                    durationMinutes: 3,
                    isCompleted: false,
                    notes: "Nach Dienst und Sport lauwarm abduschen. Zu heißes Wasser vermeiden, um den transepidermalen Wasserverlust (TEWL) gering zu halten."
                ),
                StudySubmodule(
                    id: "care-br-sm-2",
                    title: "Schritt 2: CeraVe Reinigungslotion auf Schultern & Rücken",
                    type: .handsOnLab,
                    url: "https://www.amazon.de/dp/B07C5V894J",
                    durationMinutes: 3,
                    isCompleted: false,
                    notes: "CeraVe Hydrating Cleanser sanft über Schultern, Rücken und Brustkorb verteilen und abspülen."
                ),
                StudySubmodule(
                    id: "care-br-sm-3",
                    title: "Schritt 3: Sanftes Trockentupfen mit frischem Tuch",
                    type: .handsOnLab,
                    url: nil,
                    durationMinutes: 2,
                    isCompleted: false,
                    notes: "Mit einem sauberen Handtuch sanft trocken tupfen, kein aggressives Scheuern an beanspruchten Rumpfpartien."
                )
            ],
            resources: [],
            notes: "Verhinderung von Acne Mechanica und Rumpf-Follikulitis durch schwere Trageausrüstung, Plattenträger und Rucksäcke. Schnelle Entfernung von getrocknetem Salz und Schweiß schützt die Follikelöffnungen.",
            isCompleted: false
        ))

        items.append(RoadmapStep(
            id: "care-travel-kit",
            track: .care,
            phase: "Körper, Intim & Bundeswehr-Marschschutz",
            sequenceNumber: 4,
            title: "Dienst- & Reise-Kulturbeutel (Freitag 19:00 Uhr)",
            subtitle: "Vollständigkeit der Pflegeartikel für Übungsplatz, Kaserne und Spind.",
            type: .handsOnLab,
            estimatedHours: 1,
            estimatedMinutes: 5,
            category: "Ausrüstung",
            difficulty: "Weekly",
            certBadge: "Kulturbeutel",
            primaryURL: "https://www.amazon.de/dp/B07W8P8M82",
            subtasks: [
                RoadmapSubtask(id: "care-tk-st-1", text: "Schritt 1: 100ml Reisebehälter & Füllstände prüfen", isDone: false),
                RoadmapSubtask(id: "care-tk-st-2", text: "Schritt 2: JRL Trimmer Akku & Klingenreinigung prüfen", isDone: false),
                RoadmapSubtask(id: "care-tk-st-3", text: "Schritt 3: LRP SPF 50+ Spind-Depot kontrollieren", isDone: false)
            ],
            submodules: [
                StudySubmodule(
                    id: "care-tk-sm-1",
                    title: "Schritt 1: Reisebehälter & Füllstände prüfen",
                    type: .handsOnLab,
                    url: "https://www.amazon.de/dp/B07W8P8M82",
                    durationMinutes: 2,
                    isCompleted: false,
                    notes: "Füllstand der 100ml Silikonflaschen mit CeraVe Cleanser, Feuchtigkeitscreme und Shampoo kontrollieren."
                ),
                StudySubmodule(
                    id: "care-tk-sm-2",
                    title: "Schritt 2: Equipment-Check (JRL Diamante Trimmer)",
                    type: .handsOnLab,
                    url: "https://www.amazon.de/dp/B0C4M4Q97S",
                    durationMinutes: 2,
                    isCompleted: false,
                    notes: "JRL Diamante Trimmer auf volle Akkuladung, Klingenreinigung und Schutzhülle prüfen."
                ),
                StudySubmodule(
                    id: "care-tk-sm-3",
                    title: "Schritt 3: Spind-Depot & Wirkstoff-Check",
                    type: .handsOnLab,
                    url: "https://www.amazon.de/dp/B09V7N7KLR",
                    durationMinutes: 1,
                    isCompleted: false,
                    notes: "1 Flasche LRP Anthelios SPF 50+ dauerhaft im Kasernenspind/Uniformtasche deponieren."
                )
            ],
            resources: [
                StepResource(id: "res-ctk-1", title: "Silikon Reiseflaschen 100ml", url: "https://www.amazon.de/dp/B07W8P8M82", type: "Tool", badge: "TSA")
            ],
            notes: "Vollständigkeit der Pflegeartikel für Übungsplatz, Kaserne und Spind. Sicherstellung eines permanenten Spind-Depots für La Roche-Posay SPF 50+.",
            isCompleted: false
        ))

        // MARK: - 6. Tägliche Kasernen-Chores (Stube & Lüften)
        items.append(RoadmapStep(
            id: "chore-morning-airing",
            track: .chores,
            phase: "Tägliche Kasernen-Chores (Stube & Lüften)",
            sequenceNumber: 1,
            title: "Morgen-Stoßlüften & Bett-Lüftung (06:00 Uhr)",
            subtitle: "Luftaustausch zur Senkung von Feuchtigkeit und CO2 direkt nach dem Aufstehen.",
            type: .handsOnLab,
            estimatedHours: 1,
            estimatedMinutes: 5,
            category: "Kasernen-Hygiene",
            difficulty: "Daily",
            certBadge: "Stube",
            primaryURL: nil,
            subtasks: [
                RoadmapSubtask(id: "ch-ma-st-1", text: "Schritt 1: Fenster für 5-10 Minuten ganz öffnen (Stoßlüften)", isDone: false),
                RoadmapSubtask(id: "ch-ma-st-2", text: "Schritt 2: Bettdecke zum Auslüften zurückschlagen", isDone: false)
            ],
            submodules: [
                StudySubmodule(
                    id: "chore-ma-sm-1",
                    title: "Schritt 1: Fenster ganz öffnen (5-10 Min Stoßlüften)",
                    type: .handsOnLab,
                    url: nil,
                    durationMinutes: 3,
                    isCompleted: false,
                    notes: "Fenster für 5 bis 10 Minuten vollständig öffnen (Stoßlüften, kein Kippfenster). Maximale Sauerstoffanreicherung."
                ),
                StudySubmodule(
                    id: "chore-ma-sm-2",
                    title: "Schritt 2: Bettdecke zurückschlagen",
                    type: .handsOnLab,
                    url: nil,
                    durationMinutes: 2,
                    isCompleted: false,
                    notes: "Bettdecke vollständig zurückschlagen, damit Feuchtigkeit aus Matratze und Bezug entweichen kann."
                )
            ],
            resources: [],
            notes: "Luftaustausch zur Senkung von Feuchtigkeit und CO2 direkt nach dem Aufstehen. Verhindert Schimmelbildung und optimiert das Raumklima für den Tag.",
            isCompleted: false
        ))

        items.append(RoadmapStep(
            id: "chore-midday-desk",
            track: .chores,
            phase: "Tägliche Kasernen-Chores (Stube & Lüften)",
            sequenceNumber: 2,
            title: "Mittags-Lüften & Schreibtisch-Klarschiff (13:00 Uhr)",
            subtitle: "5-10 Minuten Stoßlüften und Klärung der Arbeitsfläche vor dem Nachmittagsdienst.",
            type: .handsOnLab,
            estimatedHours: 1,
            estimatedMinutes: 5,
            category: "Kasernen-Hygiene",
            difficulty: "Daily",
            certBadge: "Ordnung",
            primaryURL: nil,
            subtasks: [
                RoadmapSubtask(id: "ch-md-st-1", text: "Schritt 1: 5-10 Minuten Stoßlüften (Fenster ganz auf)", isDone: false),
                RoadmapSubtask(id: "ch-md-st-2", text: "Schritt 2: Schreibtisch komplett freiräumen & Notizen ordnen", isDone: false)
            ],
            submodules: [
                StudySubmodule(
                    id: "chore-md-sm-1",
                    title: "Schritt 1: Fenster öffnen (5-10 Min Stoßlüften)",
                    type: .handsOnLab,
                    url: nil,
                    durationMinutes: 3,
                    isCompleted: false,
                    notes: "5 bis 10 Minuten Stoßlüften zur Senkung des CO2-Pegels nach dem Mittagessen."
                ),
                StudySubmodule(
                    id: "chore-md-sm-2",
                    title: "Schritt 2: Schreibtischklärung & Notizen ordnen",
                    type: .handsOnLab,
                    url: nil,
                    durationMinutes: 2,
                    isCompleted: false,
                    notes: "Gebrauchte Notizen, Dokumente und elektronische Geräte bündig ablegen und Arbeitsfläche freiräumen."
                )
            ],
            resources: [],
            notes: "Stoßlüften zur Senkung des CO2-Pegels und Schreibtisch freiräumen für klaren Arbeitsfokus.",
            isCompleted: false
        ))

        items.append(RoadmapStep(
            id: "chore-trash-disposal",
            track: .chores,
            phase: "Tägliche Kasernen-Chores (Stube & Lüften)",
            sequenceNumber: 3,
            title: "Müllentsorgung & Spind-Hygiene (18:15 Uhr)",
            subtitle: "Tägliche Leerung organischer und Restabfälle zur Einhaltung der Kasernen-Stubenvorschrift.",
            type: .handsOnLab,
            estimatedHours: 1,
            estimatedMinutes: 5,
            category: "Kasernen-Hygiene",
            difficulty: "Daily",
            certBadge: "Hygiene",
            primaryURL: nil,
            subtasks: [
                RoadmapSubtask(id: "ch-td-st-1", text: "Schritt 1: Restmüllbeutel fest verknoten und wegbringen", isDone: false),
                RoadmapSubtask(id: "ch-td-st-2", text: "Schritt 2: Eimer auswischen & frischen Beutel einsetzen", isDone: false)
            ],
            submodules: [
                StudySubmodule(
                    id: "chore-td-sm-1",
                    title: "Schritt 1: Mülleimer leeren & Beutel verknoten",
                    type: .handsOnLab,
                    url: nil,
                    durationMinutes: 3,
                    isCompleted: false,
                    notes: "Restmüllbeutel fest verknoten und direkt zur Kasernen-Entsorgungsstation bringen."
                ),
                StudySubmodule(
                    id: "chore-td-sm-2",
                    title: "Schritt 2: Eimer feucht auswischen & neuen Beutel einsetzen",
                    type: .handsOnLab,
                    url: nil,
                    durationMinutes: 2,
                    isCompleted: false,
                    notes: "Eimer mit Allzwecktuch auswischen und frischen Abfallbeutel bündig einspannen."
                )
            ],
            resources: [],
            notes: "Tägliche Leerung organischer und Restabfälle zur Einhaltung der Kasernen-Stubenvorschrift. Verhindert Geruchsbildung und sichert Inspektionsstandard.",
            isCompleted: false
        ))

        // MARK: - 7. Wöchentlicher Turnus (Ausrüstung & Wäsche)
        items.append(RoadmapStep(
            id: "chore-military-gear",
            track: .chores,
            phase: "Wöchentlicher Turnus (Ausrüstung & Wäsche)",
            sequenceNumber: 1,
            title: "Militärische Ausrüstung & Kampfstiefel (Freitag 16:45 Uhr)",
            subtitle: "Sichert Einsatzbereitschaft, Vollzähligkeit und Materialerhalt gemäß Dienstvorschrift.",
            type: .handsOnLab,
            estimatedHours: 1,
            estimatedMinutes: 25,
            category: "Militär & Ausrüstung",
            difficulty: "Weekly",
            certBadge: "Ausrüstung",
            primaryURL: nil,
            subtasks: [
                RoadmapSubtask(id: "ch-mg-st-1", text: "Schritt 1: Kampfstiefel abbürsten & Lederpflege polieren", isDone: false),
                RoadmapSubtask(id: "ch-mg-st-2", text: "Schritt 2: Tragesatz, Chestrig & Koppel prüfen", isDone: false),
                RoadmapSubtask(id: "ch-mg-st-3", text: "Schritt 3: Gefechtshelm & Brille mit Mikrofasertuch säubern", isDone: false),
                RoadmapSubtask(id: "ch-mg-st-4", text: "Schritt 4: Alarmpackplan im Rucksack herstellen", isDone: false)
            ],
            submodules: [
                StudySubmodule(
                    id: "chore-mg-sm-1",
                    title: "Schritt 1: Kampfstiefel reinigen & polieren",
                    type: .handsOnLab,
                    url: nil,
                    durationMinutes: 8,
                    isCompleted: false,
                    notes: "Groben Schmutz abbürsten, schwarze Bundeswehr-Lederpflege gründlich einarbeiten und mit Glanzbürste auf Hochglanz polieren."
                ),
                StudySubmodule(
                    id: "chore-mg-sm-2",
                    title: "Schritt 2: Tragesatz, Chestrig & Koppel prüfen",
                    type: .handsOnLab,
                    url: nil,
                    durationMinutes: 6,
                    isCompleted: false,
                    notes: "Verschlüsse, Riemen und Magazintaschen auf Beschädigung, Sauberkeit und Vollständigkeit prüfen."
                ),
                StudySubmodule(
                    id: "chore-mg-sm-3",
                    title: "Schritt 3: Gefechtshelm & Schutzbrille säubern",
                    type: .handsOnLab,
                    url: nil,
                    durationMinutes: 5,
                    isCompleted: false,
                    notes: "Helmbezug straffen, Schutzbrille mit Optik-Mikrofasertuch staub- und fettfrei wischen."
                ),
                StudySubmodule(
                    id: "chore-mg-sm-4",
                    title: "Schritt 4: Packordnung herstellen (Alarmpackplan)",
                    type: .handsOnLab,
                    url: nil,
                    durationMinutes: 6,
                    isCompleted: false,
                    notes: "Dienstrucksack gemäß offiziellem Alarmpackplan ordnen und griffbereit im Spind platzieren."
                )
            ],
            resources: [],
            notes: "Sichert Einsatzbereitschaft, Vollzähligkeit und Materialerhalt gemäß Dienstvorschrift.",
            isCompleted: false
        ))

        items.append(RoadmapStep(
            id: "chore-stube-clean",
            track: .chores,
            phase: "Wöchentlicher Turnus (Ausrüstung & Wäsche)",
            sequenceNumber: 2,
            title: "Stubenboden & Flächenreinigung (Di & Fr 17:00 Uhr)",
            subtitle: "Gründliche Reinigung zur Vorbereitung auf die wöchentliche Stubeninspektion durch den Spieß.",
            type: .handsOnLab,
            estimatedHours: 1,
            estimatedMinutes: 20,
            category: "Stube & Raum",
            difficulty: "Turnus",
            certBadge: "Inspektion",
            primaryURL: nil,
            subtasks: [
                RoadmapSubtask(id: "ch-sc-st-1", text: "Schritt 1: Schreibtisch & Spindkanten entstauben", isDone: false),
                RoadmapSubtask(id: "ch-sc-st-2", text: "Schritt 2: Boden gründlich fegen und saugen", isDone: false),
                RoadmapSubtask(id: "ch-sc-st-3", text: "Schritt 3: Kantenrein feucht desinfizierend wischen", isDone: false)
            ],
            submodules: [
                StudySubmodule(
                    id: "chore-sc-sm-1",
                    title: "Schritt 1: Flächen & Spindoberkanten entstauben",
                    type: .handsOnLab,
                    url: nil,
                    durationMinutes: 6,
                    isCompleted: false,
                    notes: "Schreibtisch, Fensterbank und Spindkanten mit nebelfeuchtem Mikrofasertuch und Allzweckreiniger abwischen."
                ),
                StudySubmodule(
                    id: "chore-sc-sm-2",
                    title: "Schritt 2: Boden gründlich fegen & saugen",
                    type: .handsOnLab,
                    url: nil,
                    durationMinutes: 6,
                    isCompleted: false,
                    notes: "Groben Schmutz und Staub vollständig aufnehmen, insbesondere gründlich unter Bett und Schreibtisch."
                ),
                StudySubmodule(
                    id: "chore-sc-sm-3",
                    title: "Schritt 3: Boden kantenrein feucht wischen",
                    type: .handsOnLab,
                    url: nil,
                    durationMinutes: 8,
                    isCompleted: false,
                    notes: "Mit Wischmop und Desinfektionsreiniger kantenrein wischen und bei geöffnetem Fenster trocknen lassen."
                )
            ],
            resources: [],
            notes: "Gründliche Reinigung zur Vorbereitung auf die wöchentliche Stubeninspektion durch den Spieß.",
            isCompleted: false
        ))

        items.append(RoadmapStep(
            id: "chore-bed-linen",
            track: .chores,
            phase: "Wöchentlicher Turnus (Ausrüstung & Wäsche)",
            sequenceNumber: 3,
            title: "Bettwäsche wechseln & Kantenreines Aufschlagen (Samstag 09:30 Uhr)",
            subtitle: "Wöchentlicher Wechsel von Kissen- und Deckenbezug zur Hausstaub- und Allergenreduktion.",
            type: .handsOnLab,
            estimatedHours: 1,
            estimatedMinutes: 15,
            category: "Stube & Raum",
            difficulty: "Weekly",
            certBadge: "Bettordnung",
            primaryURL: nil,
            subtasks: [
                RoadmapSubtask(id: "ch-bl-st-1", text: "Schritt 1: Alte Bettwäsche abziehen & in Kochwäsche geben", isDone: false),
                RoadmapSubtask(id: "ch-bl-st-2", text: "Schritt 2: Matratzenauflage absaugen und Matratze wenden", isDone: false),
                RoadmapSubtask(id: "ch-bl-st-3", text: "Schritt 3: Frische Bezüge aufziehen und kantenrein aufschlagen", isDone: false)
            ],
            submodules: [
                StudySubmodule(
                    id: "chore-bl-sm-1",
                    title: "Schritt 1: Alte Bezüge abziehen & in Kochwäsche geben",
                    type: .handsOnLab,
                    url: nil,
                    durationMinutes: 3,
                    isCompleted: false,
                    notes: "Kissen- und Bettdeckenbezug abziehen und unmittelbar in die 60-90°C Kochwäsche geben."
                ),
                StudySubmodule(
                    id: "chore-bl-sm-2",
                    title: "Schritt 2: Matratzenschoner lüften & Matratze wenden",
                    type: .handsOnLab,
                    url: nil,
                    durationMinutes: 5,
                    isCompleted: false,
                    notes: "Matratzenauflage gründlich absaugen und Matratze wenden zur gleichmäßigen Belastung."
                ),
                StudySubmodule(
                    id: "chore-bl-sm-3",
                    title: "Schritt 3: Frische Bezüge & militärisch kantenrein aufschlagen",
                    type: .handsOnLab,
                    url: nil,
                    durationMinutes: 7,
                    isCompleted: false,
                    notes: "Spannbettlaken straff aufziehen, Decke und Kissen beziehen und militärisch kantenrein aufschlagen."
                )
            ],
            resources: [],
            notes: "Wöchentlicher Wechsel von Kissen- und Deckenbezug zur Hausstaub- und Allergenreduktion.",
            isCompleted: false
        ))

        // MARK: - 8. Wäsche & Kantenreine Spindordnung
        items.append(RoadmapStep(
            id: "chore-laundry-wash",
            track: .chores,
            phase: "Wäsche & Kantenreine Spindordnung",
            sequenceNumber: 1,
            title: "Dienstwäsche & Sportbekleidung waschen (Mo & Do 17:30 Uhr)",
            subtitle: "Hygienische Reinigung schweißgetränkter Trainingsbekleidung und Kasernenkleidung bei 60 Grad.",
            type: .handsOnLab,
            estimatedHours: 1,
            estimatedMinutes: 10,
            category: "Wäsche & Spind",
            difficulty: "Turnus",
            certBadge: "60°C Wäsche",
            primaryURL: nil,
            subtasks: [
                RoadmapSubtask(id: "ch-lw-st-1", text: "Schritt 1: Wäsche sortieren (Funktionswäsche & Baumwolle trennen)", isDone: false),
                RoadmapSubtask(id: "ch-lw-st-2", text: "Schritt 2: 60-Grad-Hygieneprogramm mit Waschmittel starten", isDone: false)
            ],
            submodules: [
                StudySubmodule(
                    id: "chore-lw-sm-1",
                    title: "Schritt 1: Wäsche sortieren & Trommel beladen",
                    type: .handsOnLab,
                    url: nil,
                    durationMinutes: 4,
                    isCompleted: false,
                    notes: "Funktionswäsche und Baumwolle trennen, Dienst- und Sportwäsche getrennt in die Waschmaschine füllen."
                ),
                StudySubmodule(
                    id: "chore-lw-sm-2",
                    title: "Schritt 2: 60-Grad-Hygienewaschgang starten",
                    type: .handsOnLab,
                    url: nil,
                    durationMinutes: 6,
                    isCompleted: false,
                    notes: "Hygienewaschmittel dosieren und 60°C Waschprogramm starten zur vollständigen Eliminierung von Bakterien."
                )
            ],
            resources: [],
            notes: "Hygienische Reinigung schweißgetränkter Trainingsbekleidung und Kasernenkleidung bei 60 Grad.",
            isCompleted: false
        ))

        items.append(RoadmapStep(
            id: "chore-laundry-dry",
            track: .chores,
            phase: "Wäsche & Kantenreine Spindordnung",
            sequenceNumber: 2,
            title: "Wäsche falten & Kantenreine Spindordnung (Mo & Do 19:30 Uhr)",
            subtitle: "Exakte Faltung der Dienstkleidung gemäß militärischem Spind-Ordnungsplan.",
            type: .handsOnLab,
            estimatedHours: 1,
            estimatedMinutes: 15,
            category: "Wäsche & Spind",
            difficulty: "Turnus",
            certBadge: "Spindordnung",
            primaryURL: nil,
            subtasks: [
                RoadmapSubtask(id: "ch-ld-st-1", text: "Schritt 1: Trockner direkt leeren & ausschütteln", isDone: false),
                RoadmapSubtask(id: "ch-ld-st-2", text: "Schritt 2: T-Shirts & Hosen kantenrein auf DIN A4 Maß falten", isDone: false)
            ],
            submodules: [
                StudySubmodule(
                    id: "chore-ld-sm-1",
                    title: "Schritt 1: Trockner sofort leeren",
                    type: .handsOnLab,
                    url: nil,
                    durationMinutes: 3,
                    isCompleted: false,
                    notes: "Wäsche unmittelbar nach Programmende entnehmen, um Knitter- und Faltenbildung zu verhindern."
                ),
                StudySubmodule(
                    id: "chore-ld-sm-2",
                    title: "Schritt 2: Kantenrein falten (DIN A4 Schablone)",
                    type: .handsOnLab,
                    url: nil,
                    durationMinutes: 12,
                    isCompleted: false,
                    notes: "T-Shirts und Diensthosen exakt auf DIN A4 Schablonenmaß falten und bündig im Kasernenspind einsortieren."
                )
            ],
            resources: [],
            notes: "Exakte Faltung der Dienstkleidung gemäß militärischem Spind-Ordnungsplan. DIN A4 Schablonenmaß für bündige Stapel.",
            isCompleted: false
        ))

        // MARK: - 9. Trainingsplan (4er-Split)
        items.append(RoadmapStep(
            id: "gym-push-a",
            track: .gym,
            phase: "Trainingsplan (4er-Split)",
            sequenceNumber: 1,
            title: "Push A: Brust, Vordere Schulter & Trizeps",
            subtitle: "Hypertrophie- & Kraftfokus: Bankdrücken, Schrägbankdrücken, Dips & Seitheben.",
            type: .handsOnLab,
            estimatedHours: 1,
            estimatedMinutes: 65,
            category: "4er-Split",
            difficulty: "Schwer",
            certBadge: "Push A",
            primaryURL: "grow://session",
            subtasks: [
                RoadmapSubtask(id: "push-a-st-1", text: "Bankdrücken Langhantel (3x 6-8 Wdh, RPE 8-9)", isDone: false),
                RoadmapSubtask(id: "push-a-st-2", text: "Schrägbankdrücken Kurzhanteln 30° (3x 8-10 Wdh)", isDone: false),
                RoadmapSubtask(id: "push-a-st-3", text: "Dips mit Zusatzgewicht / Körpergewicht (3x 8-10 Wdh)", isDone: false),
                RoadmapSubtask(id: "push-a-st-4", text: "Seitheben am Kabelzug (4x 12-15 Wdh)", isDone: false),
                RoadmapSubtask(id: "push-a-st-5", text: "Trizepsdrücken Kabelzug Überkopf (3x 10-12 Wdh)", isDone: false)
            ],
            submodules: [
                StudySubmodule(
                    id: "gym-push-a-sm-1",
                    title: "Schritt 1: Brust & Vordere Schulter (Bankdrücken & Schrägbank)",
                    type: .handsOnLab,
                    url: "grow://session",
                    durationMinutes: 35,
                    isCompleted: false,
                    notes: "Saubere Progression im 6-8 Wdh Bereich. Schulterblätter fixiert und Spannung im Lat."
                ),
                StudySubmodule(
                    id: "gym-push-a-sm-2",
                    title: "Schritt 2: Dips, Seitheben & Trizeps-Isolation",
                    type: .handsOnLab,
                    url: "grow://session",
                    durationMinutes: 30,
                    isCompleted: false,
                    notes: "Kontrollierte exzentrische Phase. Voller Bewegungsumfang bei Dips und Seitheben."
                )
            ],
            resources: [
                StepResource(id: "gym-push-res-1", title: "Grow Trainings-App öffnen", url: "grow://session", type: "App-Link")
            ],
            notes: "Reguläre Push-Einheit des 4er-Splits. Warm-up mit Rotatorenmanschette vor dem ersten Arbeitssatz.",
            isCompleted: false
        ))

        items.append(RoadmapStep(
            id: "gym-pull-a",
            track: .gym,
            phase: "Trainingsplan (4er-Split)",
            sequenceNumber: 2,
            title: "Pull A: Rückenbreite, Rückendichte & Bizeps",
            subtitle: "Zugfokus: Klimmzüge mit Zusatzgewicht, Langhantelrudern, Face Pulls & Curls.",
            type: .handsOnLab,
            estimatedHours: 1,
            estimatedMinutes: 65,
            category: "4er-Split",
            difficulty: "Schwer",
            certBadge: "Pull A",
            primaryURL: "grow://session",
            subtasks: [
                RoadmapSubtask(id: "pull-a-st-1", text: "Klimmzüge im Obergriff (3x 6-8 Wdh, RPE 8-9)", isDone: false),
                RoadmapSubtask(id: "pull-a-st-2", text: "Langhantelrudern vorgebeugt (3x 8-10 Wdh)", isDone: false),
                RoadmapSubtask(id: "pull-a-st-3", text: "Latzug enger Parallelgriff (3x 10-12 Wdh)", isDone: false),
                RoadmapSubtask(id: "pull-a-st-4", text: "Face Pulls am Seil für Schultergesundheit (4x 15 Wdh)", isDone: false),
                RoadmapSubtask(id: "pull-a-st-5", text: "SZ-Stangen Bizepscurls (3x 10-12 Wdh)", isDone: false)
            ],
            submodules: [
                StudySubmodule(
                    id: "gym-pull-a-sm-1",
                    title: "Schritt 1: Vertikaler & Horizontaler Zug (Klimmzüge & Rudern)",
                    type: .handsOnLab,
                    url: "grow://session",
                    durationMinutes: 35,
                    isCompleted: false,
                    notes: "Fokus auf maximale Lat-Aktivierung und Kontraktion der Rhomboiden."
                ),
                StudySubmodule(
                    id: "gym-pull-a-sm-2",
                    title: "Schritt 2: Face Pulls, Hintere Schulter & Bizeps",
                    type: .handsOnLab,
                    url: "grow://session",
                    durationMinutes: 30,
                    isCompleted: false,
                    notes: "Strikte Form ohne Schwung zur Schonung des unteren Rückens."
                )
            ],
            resources: [
                StepResource(id: "gym-pull-res-1", title: "Grow Trainings-App öffnen", url: "grow://session", type: "App-Link")
            ],
            notes: "Reguläre Pull-Einheit. Kräftigung der Haltungsmuskulatur für den militärischen Dienstbetrieb.",
            isCompleted: false
        ))

        items.append(RoadmapStep(
            id: "gym-legs-a",
            track: .gym,
            phase: "Trainingsplan (4er-Split)",
            sequenceNumber: 3,
            title: "Legs A: Quadrizeps, Ischios, Waden & Core",
            subtitle: "Unterkörper & Rumpf: Kniebeugen, Rumänisches Kreuzheben, Beinpresse & Core.",
            type: .handsOnLab,
            estimatedHours: 1,
            estimatedMinutes: 65,
            category: "4er-Split",
            difficulty: "Schwer",
            certBadge: "Legs A",
            primaryURL: "grow://session",
            subtasks: [
                RoadmapSubtask(id: "legs-a-st-1", text: "Kniebeugen / Hackenschmidt (3x 6-8 Wdh, RPE 8)", isDone: false),
                RoadmapSubtask(id: "legs-a-st-2", text: "Rumänisches Kreuzheben / RDL (3x 8-10 Wdh)", isDone: false),
                RoadmapSubtask(id: "legs-a-st-3", text: "Beinpresse 45° (3x 10-12 Wdh)", isDone: false),
                RoadmapSubtask(id: "legs-a-st-4", text: "Wadenheben stehend (4x 12-15 Wdh)", isDone: false),
                RoadmapSubtask(id: "legs-a-st-5", text: "Hanging Leg Raises / Rumpfstabilität (3x 12 Wdh)", isDone: false)
            ],
            submodules: [
                StudySubmodule(
                    id: "gym-legs-a-sm-1",
                    title: "Schritt 1: Knie- & Hüftdominante Grundübungen (Squat & RDL)",
                    type: .handsOnLab,
                    url: "grow://session",
                    durationMinutes: 40,
                    isCompleted: false,
                    notes: "Volle Tiefe unter 90 Grad. Neutraler Rücken beim RDL zur Hamstrings-Dehnung."
                ),
                StudySubmodule(
                    id: "gym-legs-a-sm-2",
                    title: "Schritt 2: Beinpresse, Waden & Rumpfstabilität",
                    type: .handsOnLab,
                    url: "grow://session",
                    durationMinutes: 25,
                    isCompleted: false,
                    notes: "Saubere Endkontraktion bei Waden und Core."
                )
            ],
            resources: [
                StepResource(id: "gym-legs-res-1", title: "Grow Trainings-App öffnen", url: "grow://session", type: "App-Link")
            ],
            notes: "Grundlage für Marsch- und Tragleistung im Dienst.",
            isCompleted: false
        ))

        items.append(RoadmapStep(
            id: "gym-upper-b",
            track: .gym,
            phase: "Trainingsplan (4er-Split)",
            sequenceNumber: 4,
            title: "Upper B: Oberkörper Hypertrophie & Arme",
            subtitle: "Volumenfokus: Schulterdrücken KH, Kabel-Rudern, Schrägbank-Flys & Hammer Curls.",
            type: .handsOnLab,
            estimatedHours: 1,
            estimatedMinutes: 60,
            category: "4er-Split",
            difficulty: "Mittel",
            certBadge: "Upper B",
            primaryURL: "grow://session",
            subtasks: [
                RoadmapSubtask(id: "upper-b-st-1", text: "Schulterdrücken mit Kurzhanteln sitzend (3x 8-10 Wdh)", isDone: false),
                RoadmapSubtask(id: "upper-b-st-2", text: "Kabelzugrudern breiter Griff zur Brust (3x 10-12 Wdh)", isDone: false),
                RoadmapSubtask(id: "upper-b-st-3", text: "Kabel-Flys auf der Schrägbank (3x 12-15 Wdh)", isDone: false),
                RoadmapSubtask(id: "upper-b-st-4", text: "Hammer Curls mit Kurzhanteln (3x 10-12 Wdh)", isDone: false),
                RoadmapSubtask(id: "upper-b-st-5", text: "Trizeps Dips an der Bank / Maschine (3x 12-15 Wdh)", isDone: false)
            ],
            submodules: [
                StudySubmodule(
                    id: "gym-upper-b-sm-1",
                    title: "Schritt 1: Schultergürtel & Brust-Flys",
                    type: .handsOnLab,
                    url: "grow://session",
                    durationMinutes: 30,
                    isCompleted: false,
                    notes: "Kontrollierte Dehnung in der exzentrischen Phase."
                ),
                StudySubmodule(
                    id: "gym-upper-b-sm-2",
                    title: "Schritt 2: Oberarm-Isolation (Brachialis & Trizeps)",
                    type: .handsOnLab,
                    url: "grow://session",
                    durationMinutes: 30,
                    isCompleted: false,
                    notes: "Intensiver Pump und Mind-Muscle-Connection."
                )
            ],
            resources: [
                StepResource(id: "gym-upper-res-1", title: "Grow Trainings-App öffnen", url: "grow://session", type: "App-Link")
            ],
            notes: "Zweiter Oberkörper-Tag zur optimalen wöchentlichen Reizdichte.",
            isCompleted: false
        ))

        // MARK: - 10. Kardio & Regeneration
        items.append(RoadmapStep(
            id: "gym-cardio-zone2",
            track: .gym,
            phase: "Kardio & Regeneration",
            sequenceNumber: 1,
            title: "Zone 2 Kardio: Grundlagenausdauer (35-45 Min)",
            subtitle: "Aerobe Kapazität, Senkung des Ruhepulses & Optimierung der mitochondrialen Dichte.",
            type: .handsOnLab,
            estimatedHours: 1,
            estimatedMinutes: 45,
            category: "Kardio",
            difficulty: "Moderat",
            certBadge: "Zone 2",
            primaryURL: "grow://session",
            subtasks: [
                RoadmapSubtask(id: "c-z2-st-1", text: "5 Min Warm-up (HF bis 115 bpm)", isDone: false),
                RoadmapSubtask(id: "c-z2-st-2", text: "35 Min Zone 2 Ausdauerplateau (HF 125-138 bpm)", isDone: false),
                RoadmapSubtask(id: "c-z2-st-3", text: "5 Min Cool-down & Atemregulation", isDone: false)
            ],
            submodules: [
                StudySubmodule(
                    id: "gym-c-z2-sm-1",
                    title: "Schritt 1: Warm-up & Pulsanstieg",
                    type: .handsOnLab,
                    url: "grow://session",
                    durationMinutes: 5,
                    isCompleted: false,
                    notes: "Locker einlaufen oder auf dem Radergometer einrollen."
                ),
                StudySubmodule(
                    id: "gym-c-z2-sm-2",
                    title: "Schritt 2: 35 Min Zone 2 Plateau",
                    type: .handsOnLab,
                    url: "grow://session",
                    durationMinutes: 35,
                    isCompleted: false,
                    notes: "Intensität so wählen, dass Nasenatmung oder lockeres Sprechen noch möglich ist."
                ),
                StudySubmodule(
                    id: "gym-c-z2-sm-3",
                    title: "Schritt 3: 5 Min Cool-down",
                    type: .handsOnLab,
                    url: "grow://session",
                    durationMinutes: 5,
                    isCompleted: false,
                    notes: "Puls kontrolliert absenken und kardiovaskuläre Erholung einleiten."
                )
            ],
            resources: [
                StepResource(id: "gym-c-res-1", title: "Grow Trainings-App öffnen", url: "grow://session", type: "App-Link")
            ],
            notes: "Sportkardiologisches Protokoll: Strikte Zone 2 zur Senkung des Ruhepulses und Regeneration.",
            isCompleted: false
        ))

        items.append(RoadmapStep(
            id: "gym-mobility-reha",
            track: .gym,
            phase: "Kardio & Regeneration",
            sequenceNumber: 2,
            title: "Mobilität & BWK-Reha: Dehnen & Faszien (15 Min)",
            subtitle: "Hüftbeuger, Brustwirbelsäulen-Aufrichtung & Faszien-Rollout zur Verletzungsprophylaxe.",
            type: .handsOnLab,
            estimatedHours: 1,
            estimatedMinutes: 15,
            category: "Regeneration",
            difficulty: "Leicht",
            certBadge: "Mobilität",
            primaryURL: "grow://session",
            subtasks: [
                RoadmapSubtask(id: "m-reh-st-1", text: "Hüftbeuger & Psoas Dehnung (Couch Stretch 2x 60s)", isDone: false),
                RoadmapSubtask(id: "m-reh-st-2", text: "Brustwirbelsäule mobilisieren & Foam Roller Lat/Gluteus", isDone: false)
            ],
            submodules: [
                StudySubmodule(
                    id: "gym-m-reh-sm-1",
                    title: "Schritt 1: Untere Extremität & Hüfte (Couch Stretch)",
                    type: .handsOnLab,
                    url: "grow://session",
                    durationMinutes: 7,
                    isCompleted: false,
                    notes: "Tiefe Atmung, Becken aufgerichtet halten."
                ),
                StudySubmodule(
                    id: "gym-m-reh-sm-2",
                    title: "Schritt 2: BWS-Aufrichtung & Schultergürtel",
                    type: .handsOnLab,
                    url: "grow://session",
                    durationMinutes: 8,
                    isCompleted: false,
                    notes: "Entlastung der Wirbelsäule nach langen Märschen und Belastungen."
                )
            ],
            resources: [
                StepResource(id: "gym-m-res-1", title: "Grow Trainings-App öffnen", url: "grow://session", type: "App-Link")
            ],
            notes: "Essentiell für die Regeneration und Gelenkgesundheit.",
            isCompleted: false
        ))

        // MARK: - 11. Tägliche Mahlzeiten & Makros
        items.append(RoadmapStep(
            id: "nutri-breakfast",
            track: .nutrition,
            phase: "Tägliche Mahlzeiten & Makros",
            sequenceNumber: 1,
            title: "Frühstück: Protein-Kick & Mikronährstoffe (06:45 Uhr)",
            subtitle: "Ziel: 40-50g Eiweiß zur Beendigung des nächtlichen Katabolismus.",
            type: .handsOnLab,
            estimatedHours: 1,
            estimatedMinutes: 15,
            category: "Mahlzeit",
            difficulty: "Routine",
            certBadge: "45g Protein",
            primaryURL: "growcery://recipe",
            subtasks: [
                RoadmapSubtask(id: "n-bf-st-1", text: "4 Eier / Omelett mit Spinat oder Protein-Haferflocken zubereiten", isDone: false),
                RoadmapSubtask(id: "n-bf-st-2", text: "500ml Wasser mit einer Prise Meersalz trinken", isDone: false)
            ],
            submodules: [
                StudySubmodule(
                    id: "nutri-bf-sm-1",
                    title: "Schritt 1: Proteinzufuhr (40-50g Eiweiß)",
                    type: .handsOnLab,
                    url: "growcery://recipe",
                    durationMinutes: 10,
                    isCompleted: false,
                    notes: "Hochwertige Proteinquelle (Eiklar, Whey oder Magerquark) für die Muskelproteinsynthese."
                ),
                StudySubmodule(
                    id: "nutri-bf-sm-2",
                    title: "Schritt 2: Hydration & Elektrolyte",
                    type: .handsOnLab,
                    url: "growcery://recipe",
                    durationMinutes: 5,
                    isCompleted: false,
                    notes: "500ml frisches Wasser zur Rehydrierung nach dem Schlaf."
                )
            ],
            resources: [
                StepResource(id: "nutri-bf-res-1", title: "Growcery Ernährungs-App öffnen", url: "growcery://recipe", type: "App-Link")
            ],
            notes: "Erste Makro-Etappe des Tages. Sichert den Einstieg in das 160g Tagesziel.",
            isCompleted: false
        ))

        items.append(RoadmapStep(
            id: "nutri-lunch",
            track: .nutrition,
            phase: "Tägliche Mahlzeiten & Makros",
            sequenceNumber: 2,
            title: "Mittagessen: Truppenküche / Refuel (12:00 Uhr)",
            subtitle: "Ziel: 50-60g Eiweiß + komplexe Kohlenhydrate für kognitiven & körperlichen Fokus.",
            type: .handsOnLab,
            estimatedHours: 1,
            estimatedMinutes: 30,
            category: "Mahlzeit",
            difficulty: "Routine",
            certBadge: "55g Protein",
            primaryURL: "growcery://recipe",
            subtasks: [
                RoadmapSubtask(id: "n-ln-st-1", text: "Mageres Protein wählen (Hähnchenbrust, Rind, Fisch)", isDone: false),
                RoadmapSubtask(id: "n-ln-st-2", text: "Reis / Kartoffeln + Portion Gemüse als Ballaststoffquelle", isDone: false)
            ],
            submodules: [
                StudySubmodule(
                    id: "nutri-ln-sm-1",
                    title: "Schritt 1: Hauptgericht & mageres Protein (50-60g)",
                    type: .handsOnLab,
                    url: "growcery://recipe",
                    durationMinutes: 20,
                    isCompleted: false,
                    notes: "Truppenküche: Fleisch- / Fischkomponente priorisieren, fettige Saucen meiden."
                ),
                StudySubmodule(
                    id: "nutri-ln-sm-2",
                    title: "Schritt 2: Gemüse & Sättigungsbeilage",
                    type: .handsOnLab,
                    url: "growcery://recipe",
                    durationMinutes: 10,
                    isCompleted: false,
                    notes: "Ballaststoffe für Darmmikrobiom und stabile Blutzuckerkurve."
                )
            ],
            resources: [
                StepResource(id: "nutri-ln-res-1", title: "Growcery Ernährungs-App öffnen", url: "growcery://recipe", type: "App-Link")
            ],
            notes: "Zweite Makro-Etappe. Nach dem Essen: D3 + K2 Einnahme.",
            isCompleted: false
        ))

        items.append(RoadmapStep(
            id: "nutri-dinner",
            track: .nutrition,
            phase: "Tägliche Mahlzeiten & Makros",
            sequenceNumber: 3,
            title: "Abendessen: Casein & Regeneration (18:45 Uhr)",
            subtitle: "Ziel: 45-55g Eiweiß zur Erreichung der 160g Tagesgesamtsumme.",
            type: .handsOnLab,
            estimatedHours: 1,
            estimatedMinutes: 20,
            category: "Mahlzeit",
            difficulty: "Routine",
            certBadge: "50g Protein",
            primaryURL: "growcery://recipe",
            subtasks: [
                RoadmapSubtask(id: "n-dn-st-1", text: "Magerquark-Schale (500g mit Beeren & Leinsamen) oder Lachs mit Ofengemüse", isDone: false),
                RoadmapSubtask(id: "n-dn-st-2", text: "Tages-Makros verifizieren: 160g Protein erreicht", isDone: false)
            ],
            submodules: [
                StudySubmodule(
                    id: "nutri-dn-sm-1",
                    title: "Schritt 1: Slow-Release Casein / Abendmahlzeit",
                    type: .handsOnLab,
                    url: "growcery://recipe",
                    durationMinutes: 15,
                    isCompleted: false,
                    notes: "Casein versorgt die Muskulatur über Nacht langanhaltend mit Aminosäuren."
                ),
                StudySubmodule(
                    id: "nutri-dn-sm-2",
                    title: "Schritt 2: Makro-Audit & Tagesabschluss",
                    type: .handsOnLab,
                    url: "growcery://recipe",
                    durationMinutes: 5,
                    isCompleted: false,
                    notes: "Prüfung der Tagesbilanz in Growcery / GrowTasks."
                )
            ],
            resources: [
                StepResource(id: "nutri-dn-res-1", title: "Growcery Ernährungs-App öffnen", url: "growcery://recipe", type: "App-Link")
            ],
            notes: "Finale Tagesmahlzeit. Sicherung der Hypertrophie- und Regenerationsprozesse.",
            isCompleted: false
        ))

        items.append(RoadmapStep(
            id: "nutri-circadian-supps",
            track: .nutrition,
            phase: "Tägliche Mahlzeiten & Makros",
            sequenceNumber: 4,
            title: "Zirkadianer Supplement-Plan (Tagesverlauf)",
            subtitle: "Präzises Mikronährstoff-Timing: Rhodiola, D3/K2, Omega-3 & Magnesium.",
            type: .handsOnLab,
            estimatedHours: 1,
            estimatedMinutes: 10,
            category: "Supplemente",
            difficulty: "Routine",
            certBadge: "Zirkadian",
            primaryURL: "growcery://recipe",
            subtasks: [
                RoadmapSubtask(id: "supp-st-1", text: "06:00 Uhr: Rhodiola Rosea (500mg, 3% Salidrosid)", isDone: false),
                RoadmapSubtask(id: "supp-st-2", text: "06:30 Uhr: Magnesium-Malat (1000mg / 150mg elementar)", isDone: false),
                RoadmapSubtask(id: "supp-st-3", text: "11:45 Uhr: Vitamin D3 (5000 IE) + K2 MK-7 (200mcg) mit Fett", isDone: false),
                RoadmapSubtask(id: "supp-st-4", text: "16:45 Uhr: Omega-3 EPA/DHA (2000mg)", isDone: false),
                RoadmapSubtask(id: "supp-st-5", text: "21:00 Uhr: Magnesium-Bisglycinat (1500mg / 200mg elementar)", isDone: false)
            ],
            submodules: [
                StudySubmodule(
                    id: "nutri-supp-sm-1",
                    title: "Morgen (06:00 - 06:30 Uhr): Rhodiola Rosea & Magnesium-Malat",
                    type: .handsOnLab,
                    url: "growcery://recipe",
                    durationMinutes: 2,
                    isCompleted: false,
                    notes: "Kortisol-Modulation und mitochondriale Energiebereitstellung."
                ),
                StudySubmodule(
                    id: "nutri-supp-sm-2",
                    title: "Mittag (11:45 Uhr): Vitamin D3 + K2 MK-7",
                    type: .handsOnLab,
                    url: "growcery://recipe",
                    durationMinutes: 2,
                    isCompleted: false,
                    notes: "Mit der Mittagsmahlzeit einnehmen (fettlöslich)."
                ),
                StudySubmodule(
                    id: "nutri-supp-sm-3",
                    title: "Nachmittag (16:45 Uhr): Omega-3 EPA/DHA",
                    type: .handsOnLab,
                    url: "growcery://recipe",
                    durationMinutes: 2,
                    isCompleted: false,
                    notes: "Entzündungshemmung und Gefäßgesundheit."
                ),
                StudySubmodule(
                    id: "nutri-supp-sm-4",
                    title: "Abend (21:00 Uhr): Magnesium-Bisglycinat",
                    type: .handsOnLab,
                    url: "growcery://recipe",
                    durationMinutes: 4,
                    isCompleted: false,
                    notes: "GABAerge Beruhigung des Nervensystems und Schlafförderung."
                )
            ],
            resources: [
                StepResource(id: "nutri-supp-res-1", title: "Growcery Ernährungs-App öffnen", url: "growcery://recipe", type: "App-Link")
            ],
            notes: "Zirkadianer Einnahmeplan gemäß globaler Betriebsvorschrift.",
            isCompleted: false
        ))

        // MARK: - 12. Meal-Prep & Vorratskauf (Growcery)
        items.append(RoadmapStep(
            id: "nutri-grocery-shopping",
            track: .nutrition,
            phase: "Meal-Prep & Vorratskauf (Growcery)",
            sequenceNumber: 1,
            title: "Wocheneinkauf & Pantry-Audit (Growcery)",
            subtitle: "Gezielter Einkauf anhand der Growcery-Vorratsliste & 5-Gate Kaufprüfung.",
            type: .handsOnLab,
            estimatedHours: 1,
            estimatedMinutes: 40,
            category: "Einkauf",
            difficulty: "Turnus",
            certBadge: "Pantry-Audit",
            primaryURL: "growcery://recipe",
            subtasks: [
                RoadmapSubtask(id: "n-sh-st-1", text: "Vorratskammer prüfen & smarte Einkaufsliste in Growcery generieren", isDone: false),
                RoadmapSubtask(id: "n-sh-st-2", text: "Einkauf tätigen (Proteinquellen, Gemüse, Carbs) & Kassenbon scannen", isDone: false)
            ],
            submodules: [
                StudySubmodule(
                    id: "nutri-sh-sm-1",
                    title: "Schritt 1: Vorratsprüfung & Growcery-Liste abgleichen",
                    type: .handsOnLab,
                    url: "growcery://recipe",
                    durationMinutes: 10,
                    isCompleted: false,
                    notes: "Eier, Magerquark, Hähnchen, TK-Beeren, Haferflocken und Gemüse prüfen."
                ),
                StudySubmodule(
                    id: "nutri-sh-sm-2",
                    title: "Schritt 2: Einkauf & Bon-Erfassung",
                    type: .handsOnLab,
                    url: "growcery://recipe",
                    durationMinutes: 30,
                    isCompleted: false,
                    notes: "Keine Impulskäufe. Bon erfassen zur Ausgaben-Synchronisation mit GrowFinance."
                )
            ],
            resources: [
                StepResource(id: "nutri-sh-res-1", title: "Growcery Einkaufsliste öffnen", url: "growcery://recipe", type: "App-Link")
            ],
            notes: "Verhindert Lieferdienstkosten (360 EUR/Monat Einsparpotenzial).",
            isCompleted: false
        ))

        items.append(RoadmapStep(
            id: "nutri-meal-prep",
            track: .nutrition,
            phase: "Meal-Prep & Vorratskauf (Growcery)",
            sequenceNumber: 2,
            title: "Meal-Prep & Batch-Cooking (Wochenvorbereitung)",
            subtitle: "Vorkochen von Proteinquellen und Beilagen in hermetischen Glasbehältern.",
            type: .handsOnLab,
            estimatedHours: 1,
            estimatedMinutes: 45,
            category: "Meal-Prep",
            difficulty: "Turnus",
            certBadge: "Batch-Cook",
            primaryURL: "growcery://recipe",
            subtasks: [
                RoadmapSubtask(id: "n-mp-st-1", text: "1.2kg Hähnchenbrust / Rinderhack anbraten & würzen", isDone: false),
                RoadmapSubtask(id: "n-mp-st-2", text: "Reis / Quinoa im Reiskocher kochen & Gemüse dämpfen", isDone: false),
                RoadmapSubtask(id: "n-mp-st-3", text: "In 4-5 Glas-Meal-Prep-Dosen abfüllen und kühl lagern", isDone: false)
            ],
            submodules: [
                StudySubmodule(
                    id: "nutri-mp-sm-1",
                    title: "Schritt 1: Zubereitung & Garprozess",
                    type: .handsOnLab,
                    url: "growcery://recipe",
                    durationMinutes: 30,
                    isCompleted: false,
                    notes: "Schonende Zubereitung zur Erhaltung von Nährstoffen und Geschmack."
                ),
                StudySubmodule(
                    id: "nutri-mp-sm-2",
                    title: "Schritt 2: Portionierung & Kühlketten-Lagerung",
                    type: .handsOnLab,
                    url: "growcery://recipe",
                    durationMinutes: 15,
                    isCompleted: false,
                    notes: "Gleichmäßige Verteilung von 45-50g Eiweiß pro Portion in Glasbehälter."
                )
            ],
            resources: [
                StepResource(id: "nutri-mp-res-1", title: "Growcery Rezepte öffnen", url: "growcery://recipe", type: "App-Link")
            ],
            notes: "Spart täglich 45 Minuten Kochzeit unter der Woche und sichert 100% Makro-Treue.",
            isCompleted: false
        ))

        return items
    }

    public static func defaultQuotes() -> [StoicQuote] {
        return [
            StoicQuote(quote: "Disziplin bedeutet Freiheit.", author: "Jocko Willink", category: "Disziplin"),
            StoicQuote(quote: "Das Hindernis auf dem Weg wird der Weg.", author: "Marcus Aurelius", category: "Resilienz"),
            StoicQuote(quote: "Wir leiden öfter in der Vorstellung als in der Wirklichkeit.", author: "Seneca", category: "Klarheit"),
            StoicQuote(quote: "Verlange nicht, dass die Dinge geschehen, wie du es wünschst, sondern wünsche sie so, wie sie geschehen.", author: "Epiktet", category: "Akzeptanz"),
            StoicQuote(quote: "Kein Mensch ist frei, der nicht Herr über sich selbst ist.", author: "Epiktet", category: "Selbstbeherrschung"),
            StoicQuote(quote: "Konzentriere dich auf die Handlung, nicht auf das Ergebnis.", author: "Marcus Aurelius", category: "Fokus")
        ]
    }
}
