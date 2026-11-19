import Foundation

public struct YouTubeExerciseDetails {
    public let videoId: String
    public let videoTitle: String
    public let channelName: String
    public let instructions: [String]
    public let formCues: [String]
    public let secondaryMuscles: [String]
    public let difficulty: String

    public var videoUrl: URL {
        if !videoId.isEmpty {
            return URL(string: "https://www.youtube.com/watch?v=\(videoId)")!
        }
        let term = videoTitle.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return URL(string: "https://www.youtube.com/results?search_query=\(term)+uebung+tutorial")!
    }

    public var thumbnailUrl: URL {
        if !videoId.isEmpty {
            return URL(string: "https://img.youtube.com/vi/\(videoId)/hqdefault.jpg")!
        }
        return URL(string: "https://img.youtube.com/vi/2pLT-olgUJs/hqdefault.jpg")!
    }

    public init(
        videoId: String,
        videoTitle: String,
        channelName: String,
        instructions: [String],
        formCues: [String],
        secondaryMuscles: [String],
        difficulty: String
    ) {
        self.videoId = videoId
        self.videoTitle = videoTitle
        self.channelName = channelName
        self.instructions = instructions
        self.formCues = formCues
        self.secondaryMuscles = secondaryMuscles
        self.difficulty = difficulty
    }
}

public final class YouTubeExerciseService {
    public static let shared = YouTubeExerciseService()
    private init() {}

    public static func extractVideoId(from input: String) -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.contains("youtu.be/") {
            return trimmed.components(separatedBy: "youtu.be/").last?.components(separatedBy: "?").first?.components(separatedBy: "/").first ?? trimmed
        }
        if trimmed.contains("watch?v=") {
            return trimmed.components(separatedBy: "watch?v=").last?.components(separatedBy: "&").first ?? trimmed
        }
        if trimmed.contains("embed/") {
            return trimmed.components(separatedBy: "embed/").last?.components(separatedBy: "?").first ?? trimmed
        }
        if trimmed.contains("v=") {
            return trimmed.components(separatedBy: "v=").last?.components(separatedBy: "&").first ?? trimmed
        }
        return trimmed
    }

    public func details(for exercise: Exercise) -> YouTubeExerciseDetails {
        if let customVid = exercise.youtubeVideoId, !customVid.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let extractedId = YouTubeExerciseService.extractVideoId(from: customVid)
            let instSteps: [String] = {
                let text = !exercise.execution.isEmpty ? exercise.execution : exercise.executionNotes
                let lines = text.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
                return lines.isEmpty ? ["Ergonomische Voreinstellung am Trainingsgeraet ueberpruefen.", "Bewegung kontrolliert ueber vollen Bewegungsumfang ausfuehren."] : lines
            }()
            return YouTubeExerciseDetails(
                videoId: extractedId,
                videoTitle: "\(exercise.name) Video Tutorial",
                channelName: "Custom Video",
                instructions: instSteps,
                formCues: exercise.cues.isEmpty ? ["Neutrale Wirbelsaeule wahren", "Kontrollierte Bewegung"] : exercise.cues,
                secondaryMuscles: exercise.secondaryMusclesDetailed.isEmpty ? exercise.secondaryMuscles.map { $0.rawValue } : exercise.secondaryMusclesDetailed,
                difficulty: exercise.difficulty
            )
        }

        let name = exercise.name.lowercased()

        // 1. Lower Back & LWS Rehab
        if name.contains("kreuzheben (langhantel") || name.contains("deadlift") {
            return YouTubeExerciseDetails(
                videoId: "op9kVnSso6Q",
                videoTitle: "Kreuzheben Langhantel Deadlift Form",
                channelName: "Alan Thrall",
                instructions: [
                    "Huftbreiter Stand vor der Langhantel, Stange mittig ueber den Schnuersenkeln.",
                    "Hip-Hinge ausfuehren, Stange knapp ausserhalb der Knie im Obergriff greifen.",
                    "Schulterblaetter nach hinten unten ziehen, maximale Latissimus- und Rumpfspannung aufbauen.",
                    "Boden ueber die Fersen wegdruecken, Stange eng am Schienbein entlang nach oben fuehren.",
                    "Aufrecht verriegeln ohne Hohlkreuz; anschliessend kontrolliert absenken."
                ],
                formCues: [
                    "Neutrale Wirbelsaeule wahren (kein Einrunden der LWS)",
                    "Dauerhafter Koerperkontakt der Hantelstange",
                    "Synchroner Knie- und Hueftstreckungsverlauf"
                ],
                secondaryMuscles: ["Gluteus Maximus", "Hamstrings", "Latissimus Dorsi", "Trapezius"],
                difficulty: "Mittelstufe"
            )
        }

        if name.contains("rumaenisches kreuzheben") || name.contains("rdl") {
            return YouTubeExerciseDetails(
                videoId: "_oyxCn2iSjU",
                videoTitle: "RDL Rumaenisches Kreuzheben Anleitung",
                channelName: "Jeff Nippard",
                instructions: [
                    "Aufrechter Stand, Knie minimal gebeugt (Micro-Bend) und fixiert.",
                    "Huefte nach hinten schieben (Hip Hinge), waehrend der Oberkoerper mit geradem Ruecken nach vorne wandert.",
                    "Gewicht eng an den Oberschenkeln nach unten fuehren bis maximale Hamstring-Dehnung erreicht ist.",
                    "Ueber Gesaessanspannung die Huefte wieder kraftvoll nach vorn schieben."
                ],
                formCues: [
                    "Knie bleiben fixiert, Bewegung erfolgt ausschliesslich im Hueftgelenk",
                    "Brustbein stolz aufgerichtet lassen",
                    "Blick 2-3 Meter vor sich auf den Boden richten"
                ],
                secondaryMuscles: ["Hamstrings", "Gluteus Maximus", "Erector Spinae"],
                difficulty: "Anfaenger bis Mittelstufe"
            )
        }

        if name.contains("good morning") {
            return YouTubeExerciseDetails(
                videoId: "YA-h3n9L4YU",
                videoTitle: "Good Mornings Hinge Technik",
                channelName: "Squat University",
                instructions: [
                    "Gewicht stabil auf oberem Ruecken oder vor der Brust (Goblet) fixieren.",
                    "Rumpf fest verriegeln, Huefte weit nach hinten schieben.",
                    "Oberkoerper kontrolliert nach vorne neigen bis spuerbare Dehnung eintritt.",
                    "Ueber die Kraft der Lendenstrecker und Glutealmuskeln aufrichten."
                ],
                formCues: [
                    "Kein Schwung, gleichmaessiges Tempo (2-3 Sek. exzentrisch)",
                    "Gewicht stets moderat waehlen zur gezielten Strecker-Aktivierung"
                ],
                secondaryMuscles: ["Erector Spinae", "Gluteus Maximus", "Hamstrings"],
                difficulty: "Mittelstufe"
            )
        }

        if name.contains("rack pull") {
            return YouTubeExerciseDetails(
                videoId: "qFqbJqboCHU",
                videoTitle: "Rack Pulls ab Kniehoehe",
                channelName: "Alan Thrall",
                instructions: [
                    "Langhantel im Rack auf Kniehoehe platzieren.",
                    "Schulterbreiter Stand, Rumpf und oberen Ruecken maximal versteifen.",
                    "Knie und Huefte synchron durchstrecken und oben kurz halten.",
                    "Kontrolliert wieder auf die Sicherheitsablagen absenken."
                ],
                formCues: [
                    "Reduzierter Bewegungsradius entlastet die unterste LWS-Hebelposition",
                    "Schultern am Umkehrpunkt nicht ueberstrecken"
                ],
                secondaryMuscles: ["Trapezius", "Erector Spinae", "Latissimus Dorsi"],
                difficulty: "Mittelstufe"
            )
        }

        if name.contains("45-grad") || name.contains("hyperextension") || name.contains("roemische bank hyperextension") || name.contains("rueckenstrecker") {
            return YouTubeExerciseDetails(
                videoId: "-MTjHC3NC2s",
                videoTitle: "Hyperextensions Rueckenstrecken",
                channelName: "Squat University",
                instructions: [
                    "Auf dem Polster positionieren, Beckenkamm liegt knapp oberhalb der Kante.",
                    "Oberkoerper mit geradem Ruecken langsam nach unten absenken.",
                    "Ueber Rueckenstrecker und Gesaess kontrolliert bis zur neutralen Koerperachse aufrichten.",
                    "Am hoechsten Punkt 1-2 Sekunden isometrisch halten."
                ],
                formCues: [
                    "Niemals ins Hohlkreuz ueberstrecken",
                    "BWK Ulm Reha Safe: Staerkt Erector Spinae ohne LWS-Bandscheibenkompression"
                ],
                secondaryMuscles: ["Erector Spinae", "Gluteus Maximus", "Hamstrings"],
                difficulty: "Anfaenger"
            )
        }

        if name.contains("superman") {
            return YouTubeExerciseDetails(
                videoId: "z6PJMT2y8GQ",
                videoTitle: "Supermans Bodenstreckung LWS",
                channelName: "Athlean-X",
                instructions: [
                    "Flach auf den Bauch legen, Arme nach vorne strecken.",
                    "Gesaess und unteren Ruecken anspannen.",
                    "Arme, Brust und Beine synchron 10-15 cm vom Boden anheben.",
                    "2-3 Sekunden isometrisch halten, danach kontrolliert senken."
                ],
                formCues: [
                    "Blick bleibt auf den Boden gerichtet (HWS-Entlastung)",
                    "Dekomprimiert die Lendenwirbelsaeule"
                ],
                secondaryMuscles: ["Erector Spinae", "Gluteus", "Rhomboideus"],
                difficulty: "Anfaenger (Reha Safe)"
            )
        }

        if name.contains("bird-dog") {
            return YouTubeExerciseDetails(
                videoId: "wiFNA3sqjCA",
                videoTitle: "Bird-Dog McGill Big 3",
                channelName: "Squat University",
                instructions: [
                    "Vierfuesslerstand auf der Matte einnehmen, Haende unter Schultern, Knie unter Hueften.",
                    "Transversalen Bauchmuskel anspannen, neutrale LWS wahren.",
                    "Rechten Arm nach vorn und linkes Bein nach hinten geradlinig ausstrecken.",
                    "Position fuer 2-3 Sekunden halten, dann kontrolliert wechseln."
                ],
                formCues: [
                    "Goldstandard der Reha nach Prof. Stuart McGill",
                    "Becken bleibt vollstaendig waagerecht, keine Rotation"
                ],
                secondaryMuscles: ["Multifidi", "Transversus Abdominis", "Gluteus Maximus"],
                difficulty: "Anfaenger (Reha Safe)"
            )
        }

        if name.contains("skydiver") {
            return YouTubeExerciseDetails(
                videoId: "1OR1gAB-x50",
                videoTitle: "Skydiver Uebung Tiefenmuskeln",
                channelName: "Functional Training",
                instructions: [
                    "Bauchlage, Knie und Ellbogen im 90-Grad-Winkel gebeugt.",
                    "Gesaess und oberen Ruecken anspannen.",
                    "Brust, Arme und Oberschenkel wenige Zentimeter vom Boden abheben.",
                    "2 Sekunden halten und sanft absenken."
                ],
                formCues: [
                    "Knie leicht nach aussen gerichtet",
                    "Schulterblaetter fest zusammenziehen"
                ],
                secondaryMuscles: ["Erector Spinae", "Gluteus Medius", "Infraspinatus"],
                difficulty: "Anfaenger"
            )
        }

        if name.contains("kobra") || name.contains("cobra") {
            return YouTubeExerciseDetails(
                videoId: "jwoTJNgh8BY",
                videoTitle: "Kobra Stretch LWS Dekompression",
                channelName: "Physical Therapy",
                instructions: [
                    "Bauchlage, Haende flach unterhalb der Schultern aufsetzen.",
                    "Oberkoerper sanft aufrichten, Beckenknochen bleiben fest am Boden.",
                    "Schultern tief halten, 20-30 Sekunden tief atmen.",
                    "Langsam wieder absenken."
                ],
                formCues: [
                    "Kein Stauchen im Lendenbereich, nur schmerzfreie Extension",
                    "Bandscheiben-Dekompression"
                ],
                secondaryMuscles: ["Abdominalis", "Pectoralis"],
                difficulty: "Anfaenger (Mobilitaet)"
            )
        }

        if name.contains("lendenwirbelsaeulen-rotation") || name.contains("lumbar rotation") {
            return YouTubeExerciseDetails(
                videoId: "8Xm-ExDuX0s",
                videoTitle: "Lumbar Rotation Dehnung Facettengelenke",
                channelName: "Physical Therapy",
                instructions: [
                    "Rueckenlage, Arme im 90-Grad-Winkel zur Seite ausgebreitet.",
                    "Knie anwinkeln und beide Beine langsam zur Seite sinken lassen.",
                    "Schulterkontakt am Boden aufrechterhalten.",
                    "20-30 Sekunden dehnen, dann Seite wechseln."
                ],
                formCues: [
                    "Gleichmaessig weiteratmen",
                    "Entlastet lumbosakrale Blockaden"
                ],
                secondaryMuscles: ["Obliquus", "Piriformis"],
                difficulty: "Anfaenger (Mobilitaet)"
            )
        }

        if name.contains("kindeshaltung") || name.contains("prayer stretch") {
            return YouTubeExerciseDetails(
                videoId: "u-fC7RD_ql4",
                videoTitle: "Prayer Stretch LWS Dekompression",
                channelName: "Physical Therapy",
                instructions: [
                    "Kniestand, Gesaess auf den Fersen absetzen.",
                    "Oberkoerper nach vorn neigen, Stirn auf der Matte ablegen.",
                    "Arme weit nach vorn schieben und Wirbelsaeule lang ziehen.",
                    "30-60 Sekunden tief in den unteren Ruecken atmen."
                ],
                formCues: [
                    "Gesaess bleibt an den Fersen fixiert",
                    "Maximale axiale Wirbelsaeulen-Entlastung"
                ],
                secondaryMuscles: ["Thorakolumbalfaszie", "Latissimus Dorsi"],
                difficulty: "Anfaenger (Dekompression)"
            )
        }

        if name.contains("katze-kuh") || name.contains("cat-cow") {
            return YouTubeExerciseDetails(
                videoId: "kqnua4rHVVA",
                videoTitle: "Cat-Cow Mobilisation Wirbelsaeule",
                channelName: "Physical Therapy",
                instructions: [
                    "Vierfuesslerstand auf der Matte.",
                    "Einatmen: LWS sanft senken, Brustbein anheben (Kuh).",
                    "Ausatmen: Ruecken rund nach oben woben (Katzenbuckel).",
                    "10-15 Wiederholungen fliessend mit dem Atem verbinden."
                ],
                formCues: [
                    "Segmentale Bewegung vom Steissbein bis zur HWS",
                    "Keine ruckartigen Ueberstreckungen"
                ],
                secondaryMuscles: ["Erector Spinae", "Rectus Abdominis"],
                difficulty: "Anfaenger (Mobilitaet)"
            )
        }

        if name.contains("pull-through") {
            return YouTubeExerciseDetails(
                videoId: "v_L0e-SntSU",
                videoTitle: "Cable Pull Through Hinge Muster",
                channelName: "Jeff Nippard",
                instructions: [
                    "Seilzug ganz unten einhaengen, Seil mit dem Ruecken zum Turm fassen.",
                    "Zwei Schritte nach vorn gehen, Huftbreiter Stand.",
                    "Hinge-Bewegung: Huefte nach hinten schieben, Ruecken gerade halten.",
                    "Huefte nach vorn druecken und Gluteus oben kontrahieren."
                ],
                formCues: [
                    "Konstante Zugspannung entlastet axiale Wirbelsaeulenkompression",
                    "Arme bleiben entspannt als reine Kraftuebertragung"
                ],
                secondaryMuscles: ["Gluteus Maximus", "Hamstrings", "Erector Spinae"],
                difficulty: "Anfaenger bis Mittelstufe"
            )
        }

        // 2. Chest & Pectoralis
        if name.contains("bankdruecken (langhantel)") {
            return YouTubeExerciseDetails(
                videoId: "vcBig73ojpE",
                videoTitle: "Langhantel Bankdruecken Technik",
                channelName: "Jeff Nippard",
                instructions: [
                    "Auf der Flachbank positionieren, Augen unter der Hantelstange.",
                    "Schulterblaetter zusammenziehen und fest in die Bank graben.",
                    "Stange im mittleren Griff greifen, kontrolliert zur unteren Brust fuehren.",
                    "Aus der Brust kraftvoll nach oben druecken, Ellbogen nicht ganz durchstrecken."
                ],
                formCues: [
                    "Fuesse fest auf dem Boden verankern (Leg Drive)",
                    "Handgelenke gerade ueber den Unterarmen halten"
                ],
                secondaryMuscles: ["Trizeps", "Vordere Schulter"],
                difficulty: "Mittelstufe"
            )
        }

        if name.contains("enges bankdruecken") {
            return YouTubeExerciseDetails(
                videoId: "nEF0bv2FW94",
                videoTitle: "Enges Bankdruecken fuer Trizeps",
                channelName: "Renaissance Periodization",
                instructions: [
                    "Griffbreite schulterbreit (nicht zu eng zur Schonung der Handgelenke).",
                    "Stange zur unteren Brust absenken, Ellbogen eng am Koerper fuehren.",
                    "Aus dem Trizeps kraftvoll nach oben herausdruecken."
                ],
                formCues: [
                    "Ellbogen bleiben nah am Brustkorb",
                    "Maximale Trizeps-Faserrekrutierung"
                ],
                secondaryMuscles: ["Trizeps Brachii", "Vordere Schulter", "Pectoralis Major"],
                difficulty: "Mittelstufe"
            )
        }

        if name.contains("incline bench press") || name.contains("schraegbankdruecken") {
            return YouTubeExerciseDetails(
                videoId: "8iPEnn-ltC8",
                videoTitle: "Schraegbankdruecken richtige Ausfuehrung",
                channelName: "Jeremy Ethier",
                instructions: [
                    "Bank auf 15-30 Grad Neigung einstellen (zu steil belastet die Schulter).",
                    "Schulterblaetter fixieren, Stange zum Schluesselbein absenken.",
                    "Aus dem oberen Brustbereich kraftvoll nach oben druecken."
                ],
                formCues: [
                    "Bankwinkel moderat halten (unter 30 Grad fuer optimale Clavicular-Faser Aktivierung)"
                ],
                secondaryMuscles: ["Oberer Pectoralis", "Anterior Deltoid", "Trizeps"],
                difficulty: "Mittelstufe"
            )
        }

        if name.contains("kurzhantel bankdruecken") {
            return YouTubeExerciseDetails(
                videoId: "1V3vpcaxRYQ",
                videoTitle: "Kurzhantel Bankdruecken Anleitung",
                channelName: "Jeff Nippard",
                instructions: [
                    "Kurzhanteln mit Hilfe der Knie in die Startposition ueber der Brust bringen.",
                    "Hanteln kontrolliert absenken, tiefe Brustdehnung am Umkehrpunkt spueren.",
                    "In einem leichten Bogen nach oben zusammendruecken ohne anzuschlagen."
                ],
                formCues: [
                    "Freie Gelenkbeweglichkeit schont die Schulterrotatoren",
                    "45-Grad Ellbogenwinkel zur Schonung des Schulterdachs"
                ],
                secondaryMuscles: ["Pectoralis Major", "Trizeps", "Vordere Schulter"],
                difficulty: "Mittelstufe"
            )
        }

        if name.contains("brustdruecken (maschine)") {
            return YouTubeExerciseDetails(
                videoId: "xUm0BiZCWlQ",
                videoTitle: "Brustpresse Maschine Einstellung",
                channelName: "Renaissance Periodization",
                instructions: [
                    "Sitzhoehe so einstellen, dass sich die Griffe auf Hoehe der Brustwarzen befinden.",
                    "Ruecken fest an das Polster druecken, Schulterblaetter hinten fixieren.",
                    "Gewicht kontrolliert nach vorne druecken, kurz vor Streckung anhalten.",
                    "Langsame exzentrische Rueckfuehrung ueber 2-3 Sekunden."
                ],
                formCues: [
                    "Schultern waehrend des gesamten Drucks hinten unten halten",
                    "Feste Rumpfspannung"
                ],
                secondaryMuscles: ["Trizeps", "Vordere Schulter"],
                difficulty: "Anfaenger"
            )
        }

        if name.contains("butterfly") || name.contains("pec-deck") {
            return YouTubeExerciseDetails(
                videoId: "Z57CtFmRMxA",
                videoTitle: "Pec Deck Butterfly Kontraktion",
                channelName: "Jeff Nippard",
                instructions: [
                    "Sitz so einstellen, dass Ellbogen und Schultern auf einer Hoehe sind.",
                    "Brustbein heben, Arme in leicht gebeugtem Winkel halten.",
                    "Polster/Griffe vor der Brust zusammenfuehren, 1 Sekunde Spitzenkontraktion halten.",
                    "Langsam oeffnen bis spuerbare Dehnung im Brustmuskel einsetzt."
                ],
                formCues: [
                    "Schultern nicht nach vorn einrollen lassen",
                    "Isolationsuebung: Kein Schwung mit dem Oberkoerper"
                ],
                secondaryMuscles: ["Pectoralis Major", "Anterior Deltoid"],
                difficulty: "Anfaenger"
            )
        }

        if name.contains("cable crossover") || name.contains("flys") {
            return YouTubeExerciseDetails(
                videoId: "I-Ue34qLxc4",
                videoTitle: "Cable Crossover Flys am Kabelzug",
                channelName: "Athlean-X",
                instructions: [
                    "Seilzuege auf obere oder mittlere Position einstellen, Ausfallschritt fuer Stabilitaet.",
                    "Arme mit leichter Ellbogenbeugung nach vorn unten zusammenfuehren.",
                    "Am Endpunkt die Haende leicht ueberkreuzen fuer maximale Kontraktion.",
                    "Kontrolliert in die Dehnposition zurueckkehren."
                ],
                formCues: [
                    "Konstante Spannung ueber den gesamten Bewegungsumfang",
                    "Rumpf bleibt absolut stabil"
                ],
                secondaryMuscles: ["Pectoralis Sternal / Clavicular", "Coracobrachialis"],
                difficulty: "Mittelstufe"
            )
        }

        // 3. Back & Latissimus
        if name.contains("3d rudern") {
            return YouTubeExerciseDetails(
                videoId: "vwHG9Jfu4sw",
                videoTitle: "3D Rudern am Kabel / Maschine",
                channelName: "Jeff Nippard",
                instructions: [
                    "Brustpolster anpassen, Griffe mit neutralem oder Obergriff fassen.",
                    "Schulterblaetter zuerst nach hinten ziehen, danach die Ellbogen eng am Koerper vorbeifuehren.",
                    "Volle Kontraktion im Latissimus und oberen Ruecken fuer 1 Sekunde spueren.",
                    "Gewicht kontrolliert zuruecklassen und am vorderen Punkt in die Vor-Dehnung gehen."
                ],
                formCues: [
                    "Ellbogen fuehren die Bewegung, nicht der Bizeps",
                    "Brustbein bleibt fest am Polster fixiert"
                ],
                secondaryMuscles: ["Latissimus Dorsi", "Rhomboideus", "Bizeps"],
                difficulty: "Anfaenger bis Mittelstufe"
            )
        }

        if name.contains("kabelrudern") {
            return YouTubeExerciseDetails(
                videoId: "GZbfZ033f74",
                videoTitle: "Kabelrudern sitzend saubere Technik",
                channelName: "Renaissance Periodization",
                instructions: [
                    "Aufrecht hinsetzen, Fuesse an den Fussrasten mit leicht gebeugten Knien platzieren.",
                    "Griff fassen, Ruecken aufrichten und LWS neutral verriegeln.",
                    "Griff zum unteren Bauch ziehen, Schulterblaetter hinten fest zusammenpressen.",
                    "Kontrolliert nach vorn nachgeben, ohne den unteren Ruecken rund werden zu lassen."
                ],
                formCues: [
                    "Kein extremes Vor- und Zurueckwippen des Oberkoerpers",
                    "Zuglinie zum Bauchnabel schont die Schultern und trifft den Latissimus"
                ],
                secondaryMuscles: ["Latissimus Dorsi", "Trapezius Pars Transversa", "Bizeps"],
                difficulty: "Anfaenger"
            )
        }

        if name.contains("latzug") {
            return YouTubeExerciseDetails(
                videoId: "CAwf7n6Luuc",
                videoTitle: "Latzug zur Brust richtige Ausfuehrung",
                channelName: "Jeremy Ethier",
                instructions: [
                    "Oberschenkelpolster fest einstellen, Stange im breiten Obergriff fassen.",
                    "Leicht nach hinten lehnen (ca. 10-15 Grad), Brustbein aufrichten.",
                    "Stange kontrolliert zum Schluesselbein ziehen, Ellbogen nach unten hinten fuehren.",
                    "Am tiefsten Punkt kurz pausieren, danach kontrolliert nach oben zurueckfuehren."
                ],
                formCues: [
                    "Niemals in den Nacken ziehen (Schont HWS und Rotatorenmanschette)",
                    "Volle Dehnung am obersten Umkehrpunkt zulassen"
                ],
                secondaryMuscles: ["Latissimus Dorsi", "Bizeps", "Teres Major"],
                difficulty: "Anfaenger bis Mittelstufe"
            )
        }

        if name.contains("unterstuetzte klimmzuege") || name.contains("klimmzug") || name.contains("pull-up") || name.contains("chin-up") {
            return YouTubeExerciseDetails(
                videoId: "eGo4IYlbE5g",
                videoTitle: "Klimmzuege perfekt ausfuehren (Pull-ups)",
                channelName: "Calisthenicmovement",
                instructions: [
                    "Stange im gewaehlten Griff fassen, im Dead-Hang beginnen.",
                    "Schulterblaetter aktiv nach unten ziehen (Hollow Body Position).",
                    "Brustkorb zur Stange ziehen, bis das Kinn klar ueber der Stange ist.",
                    "Vollstaendig kontrolliert bis in den Hang absenken."
                ],
                formCues: [
                    "Kein Kipping oder Zappeln mit den Beinen",
                    "Schulteraktivierung vor der Armbeugung"
                ],
                secondaryMuscles: ["Latissimus Dorsi", "Bizeps", "Rumpf"],
                difficulty: "Mittelstufe bis Fortgeschritten"
            )
        }

        if name.contains("rhomboideus") || name.contains("reverse butterfly") {
            return YouTubeExerciseDetails(
                videoId: "GZbfZ033f74",
                videoTitle: "Hintere Schulter & Rhomboideus Isolation",
                channelName: "Renaissance Periodization",
                instructions: [
                    "Brust am Polster anlegen, Griffe mit neutralem Griff fassen.",
                    "Arme mit leichter Beugung nach aussen hinten ziehen.",
                    "Schulterblaetter bewusst zusammenpressen.",
                    "Langsam nach vorne zurueckfuehren."
                ],
                formCues: [
                    "Trapezius oben nicht hochziehen",
                    "Perfekt gegen Rundruecken und fuer Haltungskorrektur"
                ],
                secondaryMuscles: ["Rhomboideus", "Deltoideus Posterior", "Trapezius"],
                difficulty: "Anfaenger"
            )
        }

        if name.contains("pullover") || name.contains("ueberzuege") {
            return YouTubeExerciseDetails(
                videoId: "JdzaVp3zEAM",
                videoTitle: "Pullover Ueberzuege Maschine",
                channelName: "Renaissance Periodization",
                instructions: [
                    "Sitz einstellen, Ellbogen auf die Polster legen und Griffe locker halten.",
                    "Aus dem Latissimus heraus die Ellbogen nach unten vorne bis zur Huefte druecken.",
                    "Volle Kontraktion am tiefsten Punkt halten.",
                    "Kontrolliert in die Dehnung ueber Kopf zurueckkehren."
                ],
                formCues: [
                    "Pure Lat-Isolation ohne Bizeps-Beteiligung",
                    "LWS fest am Polster halten"
                ],
                secondaryMuscles: ["Latissimus Dorsi", "Teres Major", "Pectoralis Minor"],
                difficulty: "Mittelstufe"
            )
        }

        // 4. Shoulders & Deltoids
        if name.contains("schulterdruecken") || name.contains("overhead press") || name.contains("ohp") {
            return YouTubeExerciseDetails(
                videoId: "zoN5EH50Dro",
                videoTitle: "Schulterdruecken Technik & Anatomie",
                channelName: "Jeff Nippard",
                instructions: [
                    "Stabile Sitz- oder Standposition einnehmen, Rumpf fest angespannt.",
                    "Gewicht auf Schluesselbeinhoehe starten, Ellbogen leicht vor dem Koerper.",
                    "Gewicht kontrolliert ueber den Kopf druecken bis zur vollen Streckung.",
                    "Langsam absenken bis knapp unter Kinnhoehe."
                ],
                formCues: [
                    "Ellbogen nicht 90 Grad nach aussen stellen (Scapular Plane schont Rotatoren)",
                    "Kein extremes Ausweichen in ein Hohlkreuz"
                ],
                secondaryMuscles: ["Anterior & Lateral Deltoid", "Trizeps", "Oberer Trapezius"],
                difficulty: "Mittelstufe"
            )
        }

        if name.contains("seitheben") {
            return YouTubeExerciseDetails(
                videoId: "3VcKaXpzqRo",
                videoTitle: "Seitheben Kurzhanteln ohne Nackenspannung",
                channelName: "Jeff Nippard",
                instructions: [
                    "Leicht nach vorn gebeugter Stand, Hanteln oder Kabel seitlich fuehren.",
                    "Arme mit minimalem Ellbogenknick seitlich bis Schulterhoehe anheben.",
                    "Ellbogen fuehren die Bewegung, Daumen leicht nach unten geneigt.",
                    "Kontrolliert absenken ueber 2 Sekunden."
                ],
                formCues: [
                    "Nacken (oberer Trapezius) entspannt lassen",
                    "Schulterhoehe nicht ueberschreiten zur Schonung des Subakromialraums"
                ],
                secondaryMuscles: ["Lateral Deltoid", "Supraspinatus"],
                difficulty: "Anfaenger bis Mittelstufe"
            )
        }

        if name.contains("face pull") {
            return YouTubeExerciseDetails(
                videoId: "rep-qVOkqgk",
                videoTitle: "Face Pulls richtige Ausfuehrung gegen Rundruecken",
                channelName: "Athlean-X",
                instructions: [
                    "Seil auf Augenhoehe am Kabelzug befestigen, Seilenden mit Daumen nach hinten greifen.",
                    "Schritt zurueck, Seil zum Gesicht ziehen.",
                    "Am Ende der Bewegung die Haende nach aussen rotieren (W-Position).",
                    "Schulterblaetter fest zusammenkneifen, kurz halten."
                ],
                formCues: [
                    "Essentielle Praeventionsuebung fuer Rotatorenmanschette",
                    "Daumen fuehren nach hinten fuer Aussenrotation"
                ],
                secondaryMuscles: ["Infraspinatus", "Teres Minor", "Rhomboideus", "Deltoideus Posterior"],
                difficulty: "Anfaenger (Praevention)"
            )
        }

        // 5. Legs & Lower Body
        if name.contains("beinpresse") {
            return YouTubeExerciseDetails(
                videoId: "IZxyjW7MPJQ",
                videoTitle: "45 Grad Beinpresse maximale Quadrizeps-Aktivierung",
                channelName: "Jeff Nippard",
                instructions: [
                    "Rueckenlehne so einstellen, dass das Becken stabil auf dem Polster verankert bleibt.",
                    "Fuesse huftbreit auf der Plattform platzieren.",
                    "Schlitten kontrolliert absenken bis 90 Grad Kniebeugung erreicht ist.",
                    "Kraftvoll ueber die ganze Fusssohle nach oben druecken, Knie nicht durchschlagen."
                ],
                formCues: [
                    "BWK Ulm Reha: Becken darf sich NIEMALS von der Rueckenlehne einrollen (Butt Wink Verbot)",
                    "Knie bleiben in einer Linie mit den Fussspitzen"
                ],
                secondaryMuscles: ["Quadrizeps", "Gluteus Maximus", "Adduktoren"],
                difficulty: "Anfaenger bis Mittelstufe"
            )
        }

        if name.contains("hip thrust") || name.contains("glute drive") {
            return YouTubeExerciseDetails(
                videoId: "xDmFkJxPzeM",
                videoTitle: "Hip Thrust Maschine & Glute Drive",
                channelName: "Bret Contreras",
                instructions: [
                    "Gurt oder Polster ueber dem Becken fixieren, Schulterblaetter stabil anlehnen.",
                    "Fuesse so platzieren, dass am obersten Punkt 90 Grad Kniewinkel entstehen.",
                    "Huefte kraftvoll nach oben strecken, Gesaess 2 Sekunden maximal anspannen.",
                    "Kontrolliert absenken, Kinn bleibt zur Brust gerichtet."
                ],
                formCues: [
                    "Kein Hohlkreuz: Bewegung erfolgt rein aus der Hueftstreckung",
                    "Blick bleibt nach vorn gerichtet"
                ],
                secondaryMuscles: ["Gluteus Maximus", "Hamstrings", "Adduktoren"],
                difficulty: "Anfaenger bis Mittelstufe"
            )
        }

        if name.contains("beinbeugen") || name.contains("leg curl") {
            return YouTubeExerciseDetails(
                videoId: "1Tq3QdYUuHs",
                videoTitle: "Beinbeuger liegend Maschine Technik",
                channelName: "Renaissance Periodization",
                instructions: [
                    "Liegend auf der Bank einrichten, Knieachse fluchtet mit der Drehachse des Geraets.",
                    "Polster knapp unterhalb der Waden positionieren.",
                    "Fersen kraftvoll zum Gesaess ziehen, am Endpunkt 1 Sekunde halten.",
                    "Gewicht kontrolliert absenken."
                ],
                formCues: [
                    "Becken bleibt fest auf das Polster gedrueckt",
                    "Fuesse in Dorsalextension (Fussspitzen angezogen)"
                ],
                secondaryMuscles: ["Biceps Femoris", "Semimembranosus", "Semitendinosus"],
                difficulty: "Anfaenger"
            )
        }

        if name.contains("adduktion") || name.contains("abduktion") {
            return YouTubeExerciseDetails(
                videoId: "tu4o4quPv2k",
                videoTitle: "Adduktoren & Abduktoren Maschine Beckenstabilitaet",
                channelName: "Renaissance Periodization",
                instructions: [
                    "Sitzposition einnehmen, Ruecken fest am Polster.",
                    "Polster auf Oberschenkelinnenseite (Adduktion) bzw. Aussenseite (Abduktion) einrichten.",
                    "Kontrolliert zusammendruecken bzw. auseinanderfuehren.",
                    "Spitzenkontraktion kurz halten, langsam rueckfuehren."
                ],
                formCues: [
                    "Wichtig fuer Becken- und Kniestabilitaet",
                    "Keine ruckartigen Bewegungen"
                ],
                secondaryMuscles: ["Adductor Magnus / Longus", "Gluteus Medius"],
                difficulty: "Anfaenger"
            )
        }

        if name.contains("kniebeuge") || name.contains("squat") {
            return YouTubeExerciseDetails(
                videoId: "bEv6CCg2BC8",
                videoTitle: "Kniebeugen Langhantel Squat Technik",
                channelName: "Squat University",
                instructions: [
                    "Langhantel stabil auf dem oberen Ruecken platzieren (High- oder Low-Bar).",
                    "Schulterbreiter Stand, Fuesse leicht nach aussen rotiert.",
                    "Gleichzeitig Knie und Huefte beugen, Oberkoerper stabil halten.",
                    "Bis mindestens Oberschenkel parallel zum Boden absenken.",
                    "Ueber die Fersen kraftvoll nach oben herausdruecken."
                ],
                formCues: [
                    "Knie kollabieren nicht nach innen (Tracking ueber Fusszehen)",
                    "Brustkorb aufgerichtet, Wirbelsaeule neutral"
                ],
                secondaryMuscles: ["Quadrizeps", "Gluteus Maximus", "Core", "Waden"],
                difficulty: "Fortgeschritten"
            )
        }

        if name.contains("waden") || name.contains("calf") {
            return YouTubeExerciseDetails(
                videoId: "JbyjNymZOt0",
                videoTitle: "Wadenheben sitzend Soleus Fokus",
                channelName: "Renaissance Periodization",
                instructions: [
                    "Ballen auf die Trittflaeche setzen, Kniepolster fest ueber den Knien einstellen.",
                    "Fersen so weit wie moeglich nach unten senken fuer maximale Dehnung.",
                    "Kraftvoll auf die Zehenspitzen hochdruecken, 2 Sekunden Spitzenkontraktion.",
                    "Langsam absenken ueber 3 Sekunden."
                ],
                formCues: [
                    "Tiefe Dehnung ist der wichtigste Wachstumsreiz fuer Waden",
                    "Kein Wippen mit dem Polster"
                ],
                secondaryMuscles: ["Soleus", "Gastrocnemius"],
                difficulty: "Anfaenger"
            )
        }

        if name.contains("mcgill") && (name.contains("curl") || name.contains("curl-up") || name.contains("curlup")) {
            return YouTubeExerciseDetails(
                videoId: "I_drRVYlHbc",
                videoTitle: "McGill Curl-Up (Reha-Goldstandard LWS)",
                channelName: "BackFitPro / Dr. Stuart McGill",
                instructions: [
                    "Rueckenlage auf der Matte einnehmen. Ein Bein im Knie angewinkelt (Fuss flach am Boden), das andere Bein flach ausgestreckt.",
                    "Beide Haende flach mit den Handflaechen nach unten unter die Lendenwirbelsaeule (LWS) schieben (zur Wahrung der natuerlichen Lendenlordose).",
                    "Kopf und oberen Schulterguertel als starre Einheit nur minimal (2-4 cm) vom Boden anheben.",
                    "Die Position exakt 10 Sekunden isometrisch halten. Gleichmaessig weiteratmen, kein Pressen (Valsalva-Schutz).",
                    "Sanft absenken, kurze Atempause, naechste Wiederholung."
                ],
                formCues: [
                    "LWS bleibt unbeweglich – der Druck auf die Haende unter der LWS darf sich niemals veraendern",
                    "Kein Einrollen / keine Wirbelsaeulenflexion (strikt bandscheiben- und prolapssicher)",
                    "Strikter 10-Sekunden Isometrie-Hold pro Wiederholung"
                ],
                secondaryMuscles: ["M. rectus abdominis", "M. transversus abdominis", "M. obliquus internus"],
                difficulty: "Reha-Spezifisch (BWK Ulm Standard)"
            )
        }

        // 6. Arms (Biceps & Triceps)
        if name.contains("curl") || name.contains("bizeps") {
            return YouTubeExerciseDetails(
                videoId: "ykJmrZ5v0Oo",
                videoTitle: "Bizepscurls perfekte Form & Supination",
                channelName: "Jeff Nippard",
                instructions: [
                    "Aufrechter Stand oder Sitz, Hanteln/Kabel in neutralem oder supiniertem Griff.",
                    "Ellbogen seitlich am Koerper fixieren.",
                    "Gewicht kontrolliert nach oben beugen, am Endpunkt volle Muskelanspannung.",
                    "Ueber 2-3 Sekunden kontrolliert absenken."
                ],
                formCues: [
                    "Ellbogen bleiben an der Koerperachse arretiert",
                    "Kein Schwung aus dem Ruecken"
                ],
                secondaryMuscles: ["Biceps Brachii", "Brachialis", "Brachioradialis"],
                difficulty: "Anfaenger"
            )
        }

        if name.contains("bettkante") || name.contains("bodyweight triceps") || name.contains("trizeps-extension") || name.contains("trizeps-druecken") {
            return YouTubeExerciseDetails(
                videoId: "9c3cI98-XpA",
                videoTitle: "Bodyweight Triceps Extension (Schulter-sichere Dips-Alternative)",
                channelName: "Calisthenicmovement",
                instructions: [
                    "Haende schulterbreit auf die Bettkante oder Tischkante stuetzen.",
                    "Koerper in eine gerade Plank-Linie bringen, Rumpf fest anspannen (kein Hohlkreuz).",
                    "Kontrolliert die Ellbogen beugen und die Stirn in Richtung Bettkante absenken.",
                    "Ausschliesslich durch Streckung der Ellbogen aus dem Trizeps zurueck in die Ausgangslage druecken.",
                    "Die Schultern bleiben in neutraler Position – vollstaendige Vermeidung von Schulter-Hyperextension."
                ],
                formCues: [
                    "Ellbogen parallel fuehren, nicht unkontrolliert nach aussen klappen",
                    "Koerperlinie bleibt waehrend der gesamten Wiederholung brettsteif",
                    "Volle Isolierung des Trizeps ohne vorderen Kapseldruck"
                ],
                secondaryMuscles: ["Triceps Brachii (Langer Kopf)", "Transversus Abdominis", "Vordere Rumpfwand"],
                difficulty: "Fortgeschritten (Reha-Schonend)"
            )
        }

        if name.contains("trizeps") || name.contains("dip") {
            return YouTubeExerciseDetails(
                videoId: "2-LAMcpzODU",
                videoTitle: "Trizepsdruecken am Seilzug Technik",
                channelName: "Jeff Nippard",
                instructions: [
                    "Seilzug oben einhaengen, Seilenden mit Daumen nach oben greifen.",
                    "Leichte Oberkoerpervorneigung, Ellbogen eng am Koerper fixieren.",
                    "Unterarme nach unten strecken und am tiefsten Punkt das Seil nach aussen spreizen.",
                    "Kontrolliert bis 90 Grad Ellbogenbeugung zurueckfuehren."
                ],
                formCues: [
                    "Oberarme bewegen sich nicht vor und zurueck",
                    "Volle Ellbogenstreckung fuer den lateralen Trizepskopf"
                ],
                secondaryMuscles: ["Triceps Brachii (alle 3 Koepfe)"],
                difficulty: "Anfaenger"
            )
        }

        // 7. Core & Trunk
        if name.contains("plank") || name.contains("unterarmstuetz") {
            return YouTubeExerciseDetails(
                videoId: "v25dawSzRTM",
                videoTitle: "Plank richtige Haltung & Rumpfspannung",
                channelName: "Squat University",
                instructions: [
                    "Unterarmstuetz auf der Matte, Ellbogen unter den Schultern.",
                    "Beine strecken, Gesaess anspannen, Becken in posteriorer Kippung verriegeln.",
                    "Koerper bildet eine kerzengerade Linie vom Kopf bis zu den Fersen.",
                    "Gleichmaessig atmen und Rumpf isometrisch versteifen."
                ],
                formCues: [
                    "BWK Ulm Reha Safe: Goldstandard fuer Rumpfstabilitaet ohne intraabdominalen Druck",
                    "Kein Durchhaengen im Lendenbereich"
                ],
                secondaryMuscles: ["Transversus Abdominis", "Rectus Abdominis", "Gluteus"],
                difficulty: "Anfaenger"
            )
        }

        if name.contains("pallof press") {
            return YouTubeExerciseDetails(
                videoId: "5aZ0IhJS8O8",
                videoTitle: "Pallof Press Antirotation Kabelzug",
                channelName: "Squat University",
                instructions: [
                    "Seitlich zum Kabelturm stellen, Kabel auf Brusthoehe.",
                    "Griff mit beiden Haenden vor die Brust fassen, Fuesse schulterbreit.",
                    "Arme geradlinig nach vorn ausstrecken und der Rotationskraft des Kabels widerstehen.",
                    "2-3 Sekunden halten, kontrolliert zur Brust zurueckfuehren."
                ],
                formCues: [
                    "Reine Antirotations-Uebung: Koerper dreht sich keinen Millimeter",
                    "Stabilisiert die lumbale Wirbelsaeule gegen Scherkraefte"
                ],
                secondaryMuscles: ["Obliquus Internus/Externus", "Transversus", "Schultern"],
                difficulty: "Anfaenger bis Mittelstufe"
            )
        }

        if name.contains("rotary torso") || name.contains("rumpfdrehung") || name.contains("seitneigen") {
            return YouTubeExerciseDetails(
                videoId: "4LoAmWp_h9g",
                videoTitle: "Rotary Torso kontrollierte Rotation",
                channelName: "Physical Therapy",
                instructions: [
                    "Sitzposition einrichten, Polster vor der Brust fixieren.",
                    "Rumpf langsam und gefuehrt zur Seite drehen.",
                    "Spitzenkontraktion halten, kontrolliert zur Mitte zurueckkehren.",
                    "Seite wechseln."
                ],
                formCues: [
                    "Niemals ruckartig mit schwerem Gewicht drehen",
                    "Bewegung erfolgt aus der Brustwirbelsaeule, LWS bleibt stabil"
                ],
                secondaryMuscles: ["Schraege Bauchmuskeln", "Interkostalmuskeln"],
                difficulty: "Anfaenger"
            )
        }

        // 8. Functional, Cardio & Conditioning
        if name.contains("farmers walk") {
            return YouTubeExerciseDetails(
                videoId: "1uOs1hP3u4A",
                videoTitle: "Farmers Walk Haltung & Griffkraft",
                channelName: "Alan Thrall",
                instructions: [
                    "Zwei schwere Gewichte (Kettlebells/Kurzhanteln) aufnehmen.",
                    "Brustkorb stolz aufrichten, Schultern nach hinten unten ziehen.",
                    "In kleinen, kontrollierten Schritten aufrecht vorwaerts gehen.",
                    "Rumpf maximal anspannen, um seitliches Kippen zu verhindern."
                ],
                formCues: [
                    "Hervorragend fuer Haltung, Griffkraft und Rumpfstabilitaet",
                    "Schultern nicht nach vorn einfallen lassen"
                ],
                secondaryMuscles: ["Unterarme", "Trapezius", "Core", "Waden"],
                difficulty: "Mittelstufe"
            )
        }

        if name.contains("prowler") || name.contains("sled") || name.contains("schlitten") {
            return YouTubeExerciseDetails(
                videoId: "d46IugXBFJk",
                videoTitle: "Sled Training fuer Kniegesundheit & Kraft",
                channelName: "Kneesovertoesguy",
                instructions: [
                    "Schlitten an den Holmen fassen (Push) oder am Gurt rueckwaerts gehen (Pull).",
                    "Rumpf fest verriegeln, aus den Beinen kraftvoll gegen den Widerstand arbeiten.",
                    "Gleichmaessiges Tempo ueber die vorgegebene Distanz halten."
                ],
                formCues: [
                    "Rueckwaerts-Ziehen staerkt die Patellasehne und baut Kniegelenk-Resilienz auf",
                    "Schlitten-Push trainiert kardiovaskulaere Kapazitaet ohne exzentrischen Muskelschaden"
                ],
                secondaryMuscles: ["Quadrizeps", "Gesaess", "Waden", "Cardio"],
                difficulty: "Anfaenger bis Fortgeschritten"
            )
        }

        if name.contains("rowerg") || name.contains("concept2") || name.contains("ruder") {
            return YouTubeExerciseDetails(
                videoId: "4zWu1yuJ0_g",
                videoTitle: "Concept2 Rower Rudertechnik",
                channelName: "Dark Horse Rowing",
                instructions: [
                    "Fuesse festgurten, Griff im Obergriff locker fassen.",
                    "Drive: Beine druecken -> Oberkoerper kippt nach hinten -> Arme ziehen zur Brust.",
                    "Recovery: Arme strecken -> Oberkoerper kippt vor -> Beine beugen.",
                    "Gleichmaessigen Rhythmus (1:2 Taktung) halten."
                ],
                formCues: [
                    "60% Beinkraft, 20% Rumpf, 20% Arme",
                    "Lendenwirbelsaeule bleibt stets aufgerichtet"
                ],
                secondaryMuscles: ["Ganzkoerper", "Cardio"],
                difficulty: "Anfaenger bis Mittelstufe"
            )
        }

        if name.contains("airbike") || name.contains("assault") {
            return YouTubeExerciseDetails(
                videoId: "w9UHEGM8dpI",
                videoTitle: "Assault AirBike Pacing & Sprinttechnik",
                channelName: "CrossFit Training",
                instructions: [
                    "Sattelhoehe einstellen: Bein bei unterster Pedalstellung fast gestreckt.",
                    "Griffe fest fassen, Druck und Zug auf den Armen synchron mit den Beinen koordinieren.",
                    "Intervall- oder Grundlagentempo gleichmaessig halten."
                ],
                formCues: [
                    "Maximale Ganzkoerper-Konditionierung ohne Gelenkstossbelastung"
                ],
                secondaryMuscles: ["Ganzkoerper", "Cardio"],
                difficulty: "Mittelstufe"
            )
        }

        if name.contains("laufband") || name.contains("running") || name.contains("lauf") || name.contains("mvpa") {
            return YouTubeExerciseDetails(
                videoId: "6GLC-wdknH0",
                videoTitle: "Laufband & Walking Training Form",
                channelName: "Running Technique",
                instructions: [
                    "Laufband betreten, Sicherheitsclip befestigen.",
                    "Aufrechte Haltung, Schultern entspannt, Blick nach vorn.",
                    "Fussaufsatz sanft unter dem Koerperschwerpunkt.",
                    "Bei Steigungswalking: Mindestens 8-12% Steigung bei 4.5-5.5 km/h fuer gelenkschonende MVPA."
                ],
                formCues: [
                    "Kein Festhalten an den Holmen (verfaelscht Energieverbrauch und Schrittmuster)",
                    "Morgendliche 20 min MVPA aktiviert Kreislauf und Stoffwechsel"
                ],
                secondaryMuscles: ["Waden", "Quadrizeps", "Gesaess", "Herz-Kreislauf"],
                difficulty: "Anfaenger"
            )
        }

        if name.contains("ergometer") || name.contains("crosstrainer") || name.contains("fahrrad") {
            return YouTubeExerciseDetails(
                videoId: "izkkfnhirak",
                videoTitle: "Ergometer & Cardio Grundlagenausdauer",
                channelName: "Cardio Conditioning",
                instructions: [
                    "Geraet auf individuelle Koerpergroesse ergonomisch anpassen.",
                    "Ruhige, gleichmaessige Tritt- oder Kurbelfrequenz im GA1-Bereich halten.",
                    "Aufrechte Sitzhaltung ohne Rundruecken wahren."
                ],
                formCues: [
                    "Gelenkschonende Grundlagenausdauer",
                    "Regelmaessige Nasenatmung"
                ],
                secondaryMuscles: ["Herz-Kreislauf-System", "Unterkoerper"],
                difficulty: "Anfaenger"
            )
        }

        // Generic Fallback with dynamic YouTube search query
        return YouTubeExerciseDetails(
            videoId: "2pLT-olgUJs",
            videoTitle: "\(exercise.name) Uebungsanleitung",
            channelName: "YouTube Fitness Tutorial",
            instructions: [
                "Ergonomische Voreinstellung am Trainingsgeraet ueberpruefen.",
                "Grundspannung im transversalen Rumpf aufbauen, Wirbelsaeule neutral verriegeln.",
                "Bewegung kontrolliert und ohne Schwung ueber den vollstaendigen Bewegungsumfang fuehren.",
                "Am Punkt maximaler Kontraktion fuer 1 Sekunde halten.",
                "Gewicht langsam ueber 2-3 Sekunden in die Ausgangsposition absenken."
            ],
            formCues: [
                "Neutrale Wirbelsaeule wahren",
                "Gleichmaessige Atmung ohne Valsalva-Pressatmung",
                "Kontrollierte exzentrische Phase"
            ],
            secondaryMuscles: ["Rumpfstabilisatoren", "Synergisten"],
            difficulty: "Mittelstufe"
        )
    }
}
