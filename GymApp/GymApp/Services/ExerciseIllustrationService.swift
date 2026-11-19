import Foundation
import SwiftUI
import UIKit

public struct ExerciseIllustrationService {
    public static let shared = ExerciseIllustrationService()

    public struct IllustrationData {
        public let phase1Description: String
        public let phase2Description: String
        public let cadence: String
        public let breathing: String
        public let jointAlignment: String
        public let coachingCue: String
    }

    // Direct 1:1 Verified Animated GIF mapping from Hasan/GymVisual Dataset
    private let directGifMap: [String: String] = [
        "abduktion (maschine)": "hasan_0597.gif",
        "abduktoren-maschine sitzend (leicht vorgebeugt)": "hasan_0597.gif",
        "adduktion (maschine)": "hasan_0598.gif",
        "bankdruecken (langhantel)": "hasan_0025.gif",
        "barren-dips (frei)": "hasan_0009.gif",
        "barren-dips (parallel bars)": "hasan_0009.gif",
        "barren-dips (paralleles dip-geraet)": "hasan_0009.gif",
        "barren-dips mit fokus auf trizeps": "hasan_0009.gif",
        "beinbeugen liegend (maschine)": "hasan_0586.gif",
        "beinpresse 45 grad (schulterbreiter stand)": "hasan_1463.gif",
        "beinpresse 45-grad": "hasan_1463.gif",
        "beinstrecker an der maschine (2s hold)": "hasan_0585.gif",
        "beinstrecker an maschine": "hasan_0585.gif",
        "bettkanten trizeps-druecken (bodyweight triceps extension)": "hasan_0129.gif",
        "bettkanten trizeps-extension (schulter-sicher)": "hasan_0129.gif",
        "bettkanten-liegestuetz (fuesse auf bett erhoeht)": "hasan_0493.gif",
        "bizeps curls langhantel": "hasan_0031.gif",
        "bizepscurls (kurzhanteln)": "hasan_1651.gif",
        "breite liegestuetze (wide grip)": "hasan_0975.gif",
        "brustdruecken (maschine)": "hasan_0576.gif",
        "bulgarische split squats (hinterer fuss auf bettkante)": "hasan_0410.gif",
        "bulgarische split squats (kurzhanteln seitlich)": "hasan_0410.gif",
        "bulgarische split squats mit stuhl": "hasan_0410.gif",
        "butterfly (pec-deck)": "hasan_0596.gif",
        "cable kneeling crunch": "hasan_0242.gif",
        "deadbug mit druck gegen die knie": "hasan_0276.gif",
        "deadbug mit rueckendruck gegen boden": "hasan_0276.gif",
        "diamant-liegestuetz auf knien oder zehen": "hasan_0975.gif",
        "diamant-liegestuetze (calisthenics)": "hasan_0975.gif",
        "dips mit koerpergewicht (kontrolliert)": "hasan_0009.gif",
        "einarmige liegestuetze": "hasan_0725.gif",
        "einarmiges seitheben am kabel": "hasan_0192.gif",
        "einarmiges trizepsdruecken am kabel": "hasan_0201.gif",
        "einbeinige beinpresse": "hasan_1425.gif",
        "einbeinige glute bridge mit 3s peak hold": "hasan_3013.gif",
        "einbeiniges beckenheben am boden": "hasan_3013.gif",
        "einbeiniges rumaenisches kreuzheben (single leg rdl)": "hasan_0085.gif",
        "enges bankdruecken (langhantel)": "hasan_0030.gif",
        "glute bridge am boden (beckenheben)": "hasan_3013.gif",
        "glute bridge einbeinig (single leg bridge)": "hasan_3013.gif",
        "goblet squat (kurzhantel)": "hasan_1760.gif",
        "gymnastikball glute bridge": "hasan_3013.gif",
        "hammer curls kurzhanteln": "hasan_0313.gif",
        "hammer curls mit kurzhanteln stehend": "hasan_0313.gif",
        "hangboard dead hang (fingerkraft)": "hasan_0472.gif",
        "hip thrusts / glute bridges mit kurzhantel": "hasan_3013.gif",
        "incline bench press (schraegbank)": "hasan_0047.gif",
        "incline hammer curls": "hasan_0313.gif",
        "kabel-crunches": "hasan_0242.gif",
        "kabel-crunches kniend": "hasan_0242.gif",
        "kabel-curls (neunstoeckig)": "hasan_0868.gif",
        "kabel-trizepsdruecken einarmig": "hasan_0201.gif",
        "kabel-trizepsdruecken ueber kopf mit seil": "hasan_0201.gif",
        "kabelrudern (neunstoeckig)": "hasan_0861.gif",
        "kabelzug pull-through": "hasan_0196.gif",
        "kabelzug ueberzuege": "hasan_0238.gif",
        "kettlebell deadlift (kreuzheben)": "hasan_0032.gif",
        "klassische crunches (matte)": "hasan_0972.gif",
        "klimmzuege im obergriff (proniert)": "hasan_0015.gif",
        "klimmzuege im obergriff (pull-ups)": "hasan_0015.gif",
        "klimmzuege im untergriff (chin-ups)": "hasan_1431.gif",
        "klimmzuege obergriff (pull-ups)": "hasan_0015.gif",
        "klimmzuege untergriff (chin-ups)": "hasan_1431.gif",
        "kreuzheben (langhantel deadlift)": "hasan_0032.gif",
        "kurzhantel bankdruecken": "hasan_0289.gif",
        "kurzhantel lunges": "hasan_0336.gif",
        "kurzhantel rudern einarmig (stube)": "hasan_3156.gif",
        "kurzhantel rumaenisches kreuzheben (db rdl)": "hasan_0085.gif",
        "kurzhantel schulterdruecken": "hasan_0405.gif",
        "kurzhantel schulterdruecken sitzend": "hasan_0405.gif",
        "kurzhantel-schraegbankdruecken 30 grad": "hasan_0314.gif",
        "langhantel kniebeuge": "hasan_0043.gif",
        "langhantel kniebeugen (squat rack)": "hasan_0043.gif",
        "langhantel shrugs": "hasan_0095.gif",
        "latzug breiter griff": "hasan_2330.gif",
        "latzug enger parallelgriff": "hasan_2330.gif",
        "latzug zur brust": "hasan_2330.gif",
        "latzug zur brust (breit)": "hasan_2330.gif",
        "liegestuetz an turnringen": "hasan_0975.gif",
        "liegestuetze (bwk-konform kontrolliert)": "hasan_0975.gif",
        "mcgill side plank (knie oder fuesse)": "hasan_3544.gif",
        "militaer-schulterdruecken stehend (ohp)": "hasan_1012.gif",
        "multipresse kniebeugen": "hasan_3281.gif",
        "multipresse schulterdruecken": "hasan_0766.gif",
        "passive bar hang (ausklingen mit bauchspannung)": "hasan_0472.gif",
        "passive bar hang mit tiefer ausatmung": "hasan_0472.gif",
        "plank im liegestuetz-stellungswechsel": "hasan_0975.gif",
        "preacher curls (sz-stange / kh)": "hasan_0372.gif",
        "pullover / ueberzuege (maschine)": "hasan_0238.gif",
        "push-up plus (liegestuetz mit scapular-protraktion)": "hasan_0975.gif",
        "reverse butterfly (pec-deck)": "hasan_0601.gif",
        "ring dips support hold": "hasan_0009.gif",
        "rumaenisches kreuzheben (langhantel rdl)": "hasan_0085.gif",
        "rumaenisches kreuzheben kurzhanteln": "hasan_0085.gif",
        "rumpfdrehung (rotary torso)": "hasan_0242.gif",
        "scapular dips am barren (nur schulterabsenkung)": "hasan_0009.gif",
        "scapular pull-ups (stangenzug ohne armbeugung)": "hasan_0015.gif",
        "schraege bank hammer curls": "hasan_0313.gif",
        "schulterdruecken (maschine)": "hasan_0603.gif",
        "seitheben (kurzhanteln)": "hasan_0334.gif",
        "seitheben kurzhanteln": "hasan_0334.gif",
        "seitstuetz (side plank) mit erhoehten fuessen": "hasan_3544.gif",
        "seitstuetz / oblique hold (roemische bank)": "hasan_3544.gif",
        "seitstuetz mit abduktion": "hasan_3544.gif",
        "seitstuetz mit beinhochfuehren": "hasan_3544.gif",
        "single arm push-up": "hasan_0725.gif",
        "standard-liegestuetz (tempo 2-0-1)": "hasan_0975.gif",
        "stehendes wadenheben": "hasan_1372.gif",
        "stehendes wadenheben (schwere last)": "hasan_1372.gif",
        "stuben liegestuetze am schreibtisch / bett": "hasan_0975.gif",
        "stuben-workout: sixpack & liegestuetze (ohne geraete)": "hasan_0975.gif",
        "teppich unterarmstuetz (plank)": "hasan_0464.gif",
        "toter kaefer (deadbug) mit miniband": "hasan_0276.gif",
        "trizepsdruecken am seil (neunstoeckig)": "hasan_0201.gif",
        "unterarmstuetz (plank) mit vor- und zurueckwippen": "hasan_0464.gif",
        "unterarmstuetz / plank": "hasan_0464.gif",
        "unterstuetzte dips (maschine)": "hasan_0009.gif",
        "unterstuetzte klimmzuege (maschine)": "hasan_0017.gif",
        "wadenheben sitzend (maschine)": "hasan_0594.gif",
    ]

    private let patternGifRules: [(pattern: String, gifFile: String)] = [
        ("einarmige liegestuetz|single[- ]arm push[- ]up|one[- ]arm push[- ]up", "hasan_0725.gif"),
        ("bettkanten[- ]liegestuetz|liegestuetze|push[- ]up|pushup", "hasan_0662.gif"),
        ("kabel[- ]crunch|kneeling crunch|rotary torso|rumpfdreh", "hasan_0242.gif"),
        ("mcgill.*curl|deadbug|dead bug|toter kaefer", "hasan_0276.gif"),
        ("glute bridge|beckenheben", "hasan_3013.gif"),
        ("klimmzuege|pull[- ]up", "hasan_0652.gif"),
        ("chin[- ]up", "hasan_1326.gif"),
        ("incline bench press|schraegbank.*langhantel", "hasan_0047.gif"),
        ("bankdruecken|barbell bench", "hasan_0025.gif"),
        ("barren[- ]dips|bench dip|trizeps[- ]druecken|dips", "hasan_0129.gif"),
        ("schulterdruecken.*sitzend|seated shoulder press", "hasan_0405.gif"),
        ("rumaenisches kreuzheben|romanian deadlift|rdl", "hasan_0085.gif"),
        ("langhantel rudern|barbell row|bent over row", "hasan_0027.gif"),
        ("goblet squat", "hasan_1760.gif")
    ]

    public func gifData(for exerciseName: String) -> Data? {
        let cleaned = exerciseName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        var matchedFilename: String? = directGifMap[cleaned]

        if matchedFilename == nil {
            for (pattern, file) in patternGifRules {
                if cleaned.range(of: pattern, options: .regularExpression) != nil {
                    matchedFilename = file
                    break
                }
            }
        }

        guard let filename = matchedFilename else { return nil }

        let baseName = (filename as NSString).deletingPathExtension
        let ext = (filename as NSString).pathExtension.isEmpty ? "gif" : (filename as NSString).pathExtension

        // 1. Bundle lookup directly by full filename
        if let url = Bundle.main.url(forResource: filename, withExtension: nil) {
            if let data = try? Data(contentsOf: url) { return data }
        }

        // 2. Bundle lookup by baseName + ext
        if let url = Bundle.main.url(forResource: baseName, withExtension: ext) {
            if let data = try? Data(contentsOf: url) { return data }
        }

        // 3. Bundle lookup in standard subdirectories
        for sub in ["ExerciseIllustrations", "Resources/ExerciseIllustrations", "Resources"] {
            if let url = Bundle.main.url(forResource: baseName, withExtension: ext, subdirectory: sub) {
                if let data = try? Data(contentsOf: url) { return data }
            }
        }

        // 4. Fallback path lookup
        if let path = Bundle.main.path(forResource: filename, ofType: nil) {
            if let data = try? Data(contentsOf: URL(fileURLWithPath: path)) { return data }
        }

        // 5. Try Local Resources directory (Mac development / Simulator)
        let localDir = "/Users/parris-campbellnkembi/Developer/GrowWorkspace/GymApp/GymApp/Resources/ExerciseIllustrations"
        let fullPath = "\(localDir)/\(filename)"
        if FileManager.default.fileExists(atPath: fullPath), let data = try? Data(contentsOf: URL(fileURLWithPath: fullPath)) {
            return data
        }

        return nil
    }

    public func details(for exercise: Exercise) -> IllustrationData {
        let nameLower = exercise.name.lowercased()

        if nameLower.contains("einarmige liegestuetz") || nameLower.contains("single arm push") {
            return IllustrationData(
                phase1Description: "Einhand-Stützposition, stützende Hand unter dem Brustkorb, freier Arm hinter dem Rücken oder seitlich fixiert. Füße weit gegrätscht für Dreiecks-Stabilität.",
                phase2Description: "Brustkorb kontrolliert absenken, Becken und Schultern parallel zum Boden halten (Anti-Rotations-Spannung). Kraftvolles Wegdrücken aus Brust und Trizeps.",
                cadence: "3-1-1-0 (Kontrollierte Absenkung)",
                breathing: "Einatmen beim Absenken, kraftvolles Ausatmen beim Einarm-Druck",
                jointAlignment: "Kein Verwinden der LWS; Beckenknochen bleiben waagerecht zum Boden",
                coachingCue: "Fokus auf die maximale Anti-Rotations-Stabilität des Rumpfes; die freie Hand berührt niemals den Boden."
            )
        } else if nameLower.contains("incline bench") || nameLower.contains("schraegbank") {
            return IllustrationData(
                phase1Description: "Rückenlage auf 30°-Schrägbank. Schulterblätter retrahiert, Hantel über oberer Brust im Pronationsgriff.",
                phase2Description: "Hantel kontrolliert zur oberen Brust absenken, Ellbogen im 45°-Winkel. Kraftvoll nach oben drücken.",
                cadence: "2-1-1-0 (Strikter oberer Clavicular-Fokus)",
                breathing: "Einatmen beim Absenken, Ausatmen beim Hochdrücken",
                jointAlignment: "Handgelenke gerade über den Ellbogengelenken einrasten",
                coachingCue: "Drücke die Ellbogen gedanklich zusammen, um den oberen M. pectoralis major clavicularis maximal zu isolieren."
            )
        } else if nameLower.contains("bulgarische split") || nameLower.contains("bulgarian split") {
            return IllustrationData(
                phase1Description: "Ausfallschrittstellung, hinterer Fuß auf Bank oder Erhöhung abgelegt. Vorderes Knie über Fußmitte.",
                phase2Description: "Hüfte senkrecht nach unten führen, bis das hintere Knie kurz vor dem Boden ist. Über vordere Ferse hochdrücken.",
                cadence: "3-1-1-0 (Tiefe Dehnung im Gluteus)",
                breathing: "Einatmen beim Absenken, Ausatmen beim Hochdrücken",
                jointAlignment: "Vorderes Knie trackt in einer Linie mit der zweiten Zehe",
                coachingCue: "Belaste zu 85 % das vordere Bein; das hintere Bein dient nur der Balance."
            )
        } else if nameLower.contains("mcgill curl") || nameLower.contains("curl-up") {
            return IllustrationData(
                phase1Description: "Hände unter LWS zur Erhaltung der natürlichen Lordose. Ein Bein 90° angewinkelt, ein Bein gestreckt.",
                phase2Description: "Kopf und Brustwirbelsäule 2–3 cm als rigider Block anheben. Kinn leicht angezogen, kein Beugen der HWS.",
                cadence: "Isometrisch 8–10s Haltezeit",
                breathing: "Ruhige Bauchatmung gegen angespannten Rumpf (Bracing)",
                jointAlignment: "Lendenwirbelsäule komplett neutral, kein Abflachen",
                coachingCue: "Stell dir vor, Kopf und Brustkorb sind ein massiver Zementblock, der sich nur minimal vom Boden löst."
            )
        } else if nameLower.contains("side plank") || nameLower.contains("seitstuetz") {
            return IllustrationData(
                phase1Description: "Seitlage auf dem Unterarm, Ellbogen direkt unter der Schulter. Knie 90° gebeugt (oder Beine gestreckt).",
                phase2Description: "Becken kontrolliert anheben, bis Oberschenkel, Becken und Rumpf eine exakte Diagonale bilden.",
                cadence: "Isometrisch 10–15s pro Seite",
                breathing: "Kontinuierlich und gleichmäßig durch die Nase",
                jointAlignment: "Schulter aktiv nach unten drücken, kein Einsinken im Gelenk",
                coachingCue: "Fokus auf den unteren M. quadratus lumborum und die schrägen Bauchmuskeln; Becken darf nicht nach hinten kippen."
            )
        } else if nameLower.contains("deadbug") || nameLower.contains("kaefer") {
            return IllustrationData(
                phase1Description: "Rückenlage, Arme senkrecht zur Decke gestreckt, Knie und Hüfte im 90°-Winkel (Tabletop).",
                phase2Description: "Rechter Arm und linkes Bein senken sich diagonal ab, ohne dass die Lendenwirbelsäule den Bodenkontakt verliert.",
                cadence: "3-1-3-0 (3s Absenken, 1s Halten)",
                breathing: "Ausatmen beim Absenken der Extremitäten, Einatmen beim Zurückführen",
                jointAlignment: "LWS fest in die Unterlage gepresst (Anti-Extension)",
                coachingCue: "Bewege Arm und Bein nur so weit, wie du den Rumpf stabil und unbeweglich halten kannst."
            )
        } else if nameLower.contains("glute bridge") || nameLower.contains("becken") || nameLower.contains("thrust") {
            return IllustrationData(
                phase1Description: "Rückenlage, Fersen hüftbreit aufgestellt, Knie 90°, Arme entspannt neben dem Körper.",
                phase2Description: "Becken über die Fersen hochdrücken, bis Oberschenkel und Oberkörper eine Linie bilden. Gesäß maximal anspannen.",
                cadence: "2-2-2-0 (2s Halten am Umkehrpunkt)",
                breathing: "Ausatmen beim Hochdrücken, Einatmen beim kontrollierten Absenken",
                jointAlignment: "Knie über den Fußgelenken, kein Hohlkreuz überstrecken",
                coachingCue: "Drücke den Boden durch deine Fersen weg und kneife die Gesäßmuskeln am obersten Punkt fest zusammen."
            )
        } else if nameLower.contains("plank") || nameLower.contains("unterarmstuetz") {
            return IllustrationData(
                phase1Description: "Vierfüßlerstand auf Unterarmen, Ellbogen unter Schultern, Blick neutral zum Boden.",
                phase2Description: "Beine nacheinander strecken, Fersen nach hinten schieben, Rumpf und Gluteus voll einrasten.",
                cadence: "Isometrisch 30–60s",
                breathing: "Tiefe, kontrollierte Zwerchfellatmung",
                jointAlignment: "Gerade Achse von Kopf bis Fersen; kein Durchhängen des Beckens",
                coachingCue: "Ziehe Ellbogen und Zehenspitzen isometrisch zueinander, um maximale Spannung im M. transversus abdominis aufzubauen."
            )
        } else if nameLower.contains("bird dog") || nameLower.contains("vierfuess") {
            return IllustrationData(
                phase1Description: "Vierfüßlerstand auf einer Matte, Hände unter Schultern, Knie unter Hüften, Rücken neutral.",
                phase2Description: "Rechten Arm und linkes Bein parallel zum Boden ausstrecken; Daumen zeigt nach oben, Ferse drückt nach hinten.",
                cadence: "3-2-3-0 (2s Endposition halten)",
                breathing: "Ausatmen bei Streckung, Einatmen bei Rückkehr",
                jointAlignment: "Becken bleibt exakt horizontal, keine Rotation der LWS",
                coachingCue: "Stell dir vor, auf deinem unteren Rücken steht ein gefülltes Glas Wasser, das nicht verschüttet werden darf."
            )
        } else if nameLower.contains("liegestuetz") || nameLower.contains("push") {
            return IllustrationData(
                phase1Description: "Hohe Liegestützposition, Hände leicht breiter als schulterbreit, Körper vollständig gestreckt.",
                phase2Description: "Brustkorb bis wenige Zentimeter über den Boden absenken, Ellbogen in ca. 45°-Winkel zum Körper führen.",
                cadence: "2-0-1-0 (2s Absenken, kraftvolles Hochdrücken)",
                breathing: "Einatmen beim Absenken, Ausatmen beim Wegdrücken",
                jointAlignment: "Schulterblätter am tiefsten Punkt zusammenziehen, oben voll protrahieren",
                coachingCue: "Bewege den gesamten Körper wie ein einziges Brett; kein Durchhängen der Lendenwirbelsäule."
            )
        } else {
            return IllustrationData(
                phase1Description: "Ausgangsposition einnehmen, Rumpf stabilisieren und Gelenke ausrichten.",
                phase2Description: "Kontrollierte Bewegungsausführung entlang des anatomischen Vektors bis zum Zielpunkt.",
                cadence: "2-1-2-0 (Standardkadenz)",
                breathing: "Ausatmen bei der Belastung, Einatmen bei Rückführung",
                jointAlignment: "Gelenke in funktioneller Neutralnull-Stellung",
                coachingCue: "Fokus auf gleichmäßige Kraftübertragung und Mind-Muscle-Connection im \(exercise.targetMuscle.rawValue)."
            )
        }
    }
}
