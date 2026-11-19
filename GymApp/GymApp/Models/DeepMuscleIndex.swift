import Foundation
import SwiftUI

// MARK: - Anatomische Muskel-Regionen (Wikipedia / Terminologia Anatomica Standard)
public enum MuscleRegion: String, CaseIterable, Codable, Identifiable {
    case cranialJaw = "Schaedel, Kiefer & Gesicht"
    case cervicalNeck = "Hals & Nacken"
    case shoulderScapula = "Schulter & Scapula"
    case chestThorax = "Brustkorb & Respiration"
    case backLatUpper = "Oberer Ruecken & Latissimus"
    case spineMultifidi = "Wirbelsaeule & Multifidi"
    case deepCorePelvis = "Tiefer Rumpf & Beckenboden"
    case hipGluteRotator = "Huefte, Gluteus & Tiefe Rotatoren"
    case quadricepsThigh = "Vorderer Oberschenkel & Adduktoren"
    case hamstringsPosterior = "Hintere Kette & Ischios"
    case lowerLegFoot = "Unterschenkel & Sprunggelenk"
    case armsForearms = "Arme & Unterarmkompartimente"

    public var id: String { rawValue }

    public var systemIcon: String {
        switch self {
        case .cranialJaw: return "brain.head.profile"
        case .cervicalNeck: return "figure.cooldown"
        case .shoulderScapula: return "figure.arms.open"
        case .chestThorax: return "figure.mind.and.body"
        case .backLatUpper: return "figure.rower"
        case .spineMultifidi: return "figure.core.training"
        case .deepCorePelvis: return "shield.lefthalf.filled"
        case .hipGluteRotator: return "figure.walk"
        case .quadricepsThigh: return "figure.run"
        case .hamstringsPosterior: return "figure.step.training"
        case .lowerLegFoot: return "figure.cross.training"
        case .armsForearms: return "dumbbell.fill"
        }
    }
}

// MARK: - Tiefenschichten (Tiers)
public enum MuscleLayerTier: String, Codable {
    case superficial = "Oberflaechlich (Primaerbeweger)"
    case deepStabilizer = "Tiefe Stabilisatoren & Synergisten"
    case microProprioceptive = "Mikro-Propriozeptoren (Segmentale Steuerung)"
}

// MARK: - Einzelner Muskel-Eintrag im Tiefen-Index
public struct AnatomicalMuscleEntity: Identifiable, Codable {
    public var id: String // z.B. "splenius_capitis"
    public var latinName: String
    public var commonName: String
    public var region: MuscleRegion
    public var tier: MuscleLayerTier
    public var primaryFunction: String
    public var clinicalSignificance: String
    public var isBWKCoreCritical: Bool

    public init(
        id: String,
        latinName: String,
        commonName: String,
        region: MuscleRegion,
        tier: MuscleLayerTier,
        primaryFunction: String,
        clinicalSignificance: String,
        isBWKCoreCritical: Bool = false
    ) {
        self.id = id
        self.latinName = latinName
        self.commonName = commonName
        self.region = region
        self.tier = tier
        self.primaryFunction = primaryFunction
        self.clinicalSignificance = clinicalSignificance
        self.isBWKCoreCritical = isBWKCoreCritical
    }
}

// MARK: - Muskel-Evaluationsstatus
public enum MuscleBalanceStatus: String, Codable {
    case peak = "Optimal konditioniert"
    case adequate = "Erhaltungsbereich"
    case lagging = "Leichtes Defizit"
    case criticalNeglect = "Kritisch vernachlaessigt"

    public var badgeColorHex: String {
        switch self {
        case .peak: return "2ECC71"
        case .adequate: return "3498DB"
        case .lagging: return "F39C12"
        case .criticalNeglect: return "E74C3C"
        }
    }
}

public struct MuscleEvaluationMetric: Identifiable, Codable {
    public var id: String { muscle.id }
    public var muscle: AnatomicalMuscleEntity
    public var effectiveVolumeScore30Days: Double
    public var daysSinceLastStimulus: Int
    public var decayFactor: Double
    public var currentStrengthScore: Double
    public var status: MuscleBalanceStatus

    public init(
        muscle: AnatomicalMuscleEntity,
        effectiveVolumeScore30Days: Double,
        daysSinceLastStimulus: Int,
        decayFactor: Double,
        currentStrengthScore: Double,
        status: MuscleBalanceStatus
    ) {
        self.muscle = muscle
        self.effectiveVolumeScore30Days = effectiveVolumeScore30Days
        self.daysSinceLastStimulus = daysSinceLastStimulus
        self.decayFactor = decayFactor
        self.currentStrengthScore = currentStrengthScore
        self.status = status
    }
}

// MARK: - Der vollstaendige Tiefenmuskel-Katalog (Wikipedia / Terminologia Anatomica)
public struct DeepMuscleIndex {
    public static let allMuscles: [AnatomicalMuscleEntity] = [
        // 1. Schaedel, Kiefer & Craniofazial
        AnatomicalMuscleEntity(
            id: "masseter_temporalis",
            latinName: "M. masseter & M. temporalis",
            commonName: "Kaumuskulatur & Schlaefenmuskel",
            region: .cranialJaw,
            tier: .superficial,
            primaryFunction: "Mandibulare Adduktion, Kieferschluss und Kaukraft",
            clinicalSignificance: "Zentraler Anker fuer Kiefer-Nacken-Reflexe (Bruxismus/Zaehneknirschen) und craniomandibulaere Dysfunktion (CMD)."
        ),
        AnatomicalMuscleEntity(
            id: "pterygoidei",
            latinName: "Mm. pterygoideus medialis & lateralis",
            commonName: "Tiefe Fluegelmuskeln des Kiefers",
            region: .cranialJaw,
            tier: .deepStabilizer,
            primaryFunction: "Kiefervorschub, Mahlbewegungen und Diskus-Stabilisation",
            clinicalSignificance: "Feinjustierung des Kiefergelenks; reagiert empfindlich auf ZNS-Stress und Nackenhypertonus."
        ),

        // 2. Hals & Nacken (Cervical)
        AnatomicalMuscleEntity(
            id: "splenius_capitis",
            latinName: "M. splenius capitis & cervicis",
            commonName: "Riemenmuskel des Kopfes / Nackenstrecker",
            region: .cervicalNeck,
            tier: .deepStabilizer,
            primaryFunction: "Dorsalextension des Kopfes, ipsilaterale Rotation",
            clinicalSignificance: "Verhindert Vorwaertskopfhaltung (Forward Head Posture) und Nackenverspannungen bei Bildschirmarbeit."
        ),
        AnatomicalMuscleEntity(
            id: "longus_colli",
            latinName: "M. longus colli & longus capitis",
            commonName: "Tiefe praevertebrale Halsbeuger",
            region: .cervicalNeck,
            tier: .deepStabilizer,
            primaryFunction: "Ventralflexion und segmentale Halswirbel-Stabilisation",
            clinicalSignificance: "Zentraler Antagonist zu hyperaktiven Sternocleidomastoidei; schuetzt HWS vor Schleudertraumata und Fehlstellungen."
        ),
        AnatomicalMuscleEntity(
            id: "scaleni_group",
            latinName: "Mm. scaleni (anterior, medius, posterior)",
            commonName: "Treppenmuskeln der Halswirbelsaeule",
            region: .cervicalNeck,
            tier: .deepStabilizer,
            primaryFunction: "Lateralflexion der HWS, Hebung der 1. und 2. Rippe (Atemhilfe)",
            clinicalSignificance: "Bilden die Skalenusluecke; Hypertonus fuehrt zu Nerven- und Gefaesskompression des Arms (Thoracic Outlet)."
        ),
        AnatomicalMuscleEntity(
            id: "suboccipitales",
            latinName: "Mm. suboccipitales (Rectus & Obliquus capitis)",
            commonName: "Kurze Nackenmuskeln (Subokzipital)",
            region: .cervicalNeck,
            tier: .microProprioceptive,
            primaryFunction: "Feinmotorische Kopfjustierung, Propriozeption des Gleichgewichts",
            clinicalSignificance: "Enthalten hoechste Dichte an Muskelspindeln im Koerper; Schluessel fuer vestibulookulaere Koordination."
        ),
        AnatomicalMuscleEntity(
            id: "sternocleidomastoideus",
            latinName: "M. sternocleidomastoideus",
            commonName: "Grosser Kopfwender",
            region: .cervicalNeck,
            tier: .superficial,
            primaryFunction: "Kopfdrehung, Kopfneigung und Atemhilfsmuskel",
            clinicalSignificance: "Neigt bei Dysbalancen zu Hypertonus; bedarf ausgewogener antagonistischer Rueckendehnung."
        ),

        // 3. Schulter & Scapula
        AnatomicalMuscleEntity(
            id: "supraspinatus",
            latinName: "M. supraspinatus",
            commonName: "Obergraetenmuskel (Rotatorenmanschette)",
            region: .shoulderScapula,
            tier: .deepStabilizer,
            primaryFunction: "Initialisierung der Armabduktion (0-15 Grad), Humeruskopf-Zentrierung",
            clinicalSignificance: "Haeufigste Lokalisation von Impingement-Syndromen; profitiert von Scaption und kontrollierter Drucktechnik."
        ),
        AnatomicalMuscleEntity(
            id: "infraspinatus_teres_minor",
            latinName: "M. infraspinatus & teres minor",
            commonName: "Aussenrotatoren der Schulter",
            region: .shoulderScapula,
            tier: .deepStabilizer,
            primaryFunction: "Glenohumerale Aussenrotation, Rueckwaertszug des Humeruskopfs",
            clinicalSignificance: "Kritischer Puffer gegen Innenrotations-Ueberhang (Bankdruecker-Schulter); aktiviert durch Face Pulls."
        ),
        AnatomicalMuscleEntity(
            id: "subscapularis",
            latinName: "M. subscapularis",
            commonName: "Unterschulterblattmuskel",
            region: .shoulderScapula,
            tier: .deepStabilizer,
            primaryFunction: "Kraeftige Innenrotation, ventrale Schultergelenkssicherung",
            clinicalSignificance: "Groesster Muskel der Rotatorenmanschette; stabilisiert den Humerus bei Zugbewegungen."
        ),
        AnatomicalMuscleEntity(
            id: "serratus_anterior",
            latinName: "M. serratus anterior",
            commonName: "Vorderer Saegemuskel",
            region: .shoulderScapula,
            tier: .superficial,
            primaryFunction: "Protraktion und Aufwaertsrotation der Scapula (Ueberkopfbewegung)",
            clinicalSignificance: "Verhindert Scapula alata (Engelsfluegel); Schluesselmuskel fuer schmerzfreie Dips und Liegestuetze."
        ),
        AnatomicalMuscleEntity(
            id: "deltoideus_lateralis",
            latinName: "M. deltoideus pars acromialis",
            commonName: "Seitlicher Deltamuskel",
            region: .shoulderScapula,
            tier: .superficial,
            primaryFunction: "Abduktion des Arms bis zur Horizontalen",
            clinicalSignificance: "Verantwortlich fuer Schulterbreite und V-Taper Aesthetik."
        ),

        // 4. Brustkorb & Respiration
        AnatomicalMuscleEntity(
            id: "pectoralis_major",
            latinName: "M. pectoralis major (Clavicular & Sternal)",
            commonName: "Grosser Brustmuskel",
            region: .chestThorax,
            tier: .superficial,
            primaryFunction: "Adduktion, Anteversion und Innenrotation des Arms",
            clinicalSignificance: "Haupttreiber horizontaler Druckbewegungen; erfordert Dehnung der Faszien zur Erhaltung aufrechter Haltung."
        ),
        AnatomicalMuscleEntity(
            id: "pectoralis_minor",
            latinName: "M. pectoralis minor",
            commonName: "Kleiner Brustmuskel",
            region: .chestThorax,
            tier: .deepStabilizer,
            primaryFunction: "Kippt Scapula nach anterior-inferior, Atemhilfsmuskel",
            clinicalSignificance: "Neigt zu Verkuerzung; komprimiert den Plexus brachialis bei fehlendem antagonistischem Gegenzug."
        ),
        AnatomicalMuscleEntity(
            id: "intercostales_group",
            latinName: "Mm. intercostales externi & interni",
            commonName: "Zwischenrippenmuskulatur (Atemmuskeln)",
            region: .chestThorax,
            tier: .deepStabilizer,
            primaryFunction: "Thoraxhebung bei Inspiration, Thoraxsenkung bei forcierter Exspiration",
            clinicalSignificance: "Essenziell fuer VDOT-Atemoekonomie beim Laufen und Laktatpufferung unter Vollbelastung."
        ),

        // 5. Oberer Ruecken & Latissimus
        AnatomicalMuscleEntity(
            id: "latissimus_dorsi",
            latinName: "M. latissimus dorsi",
            commonName: "Breiter Rueckenmuskel",
            region: .backLatUpper,
            tier: .superficial,
            primaryFunction: "Adduktion, Retroversion und Innenrotation des Arms (vertikaler Zug)",
            clinicalSignificance: "Groesster Muskel des Oberkoerpers; verbindet Beckenkamm ueber Thorakolumbalfaszie mit Humerus."
        ),
        AnatomicalMuscleEntity(
            id: "rhomboidei",
            latinName: "Mm. rhomboideus major & minor",
            commonName: "Rautenmuskeln",
            region: .backLatUpper,
            tier: .deepStabilizer,
            primaryFunction: "Retraktion und kraniale Fixierung der Schulterblaetter zur Wirbelsaeule",
            clinicalSignificance: "Essenziell fuer aufrechte MilFit-Haltung und Schulterstabilitaet bei schwerem Tragen."
        ),
        AnatomicalMuscleEntity(
            id: "trapezius_ascendens",
            latinName: "M. trapezius pars ascendens",
            commonName: "Unterer Trapezmuskel",
            region: .backLatUpper,
            tier: .deepStabilizer,
            primaryFunction: "Depression der Scapula, Unterstuetzung der Scapula-Aussenrotation",
            clinicalSignificance: "Verhindert Schulterhochstand und Nackenverspannung; haeufig chronisch unteraktiviert."
        ),

        // 6. Wirbelsaeule & Multifidi
        AnatomicalMuscleEntity(
            id: "multifidi",
            latinName: "Mm. multifidi (Cervical, Thoracal, Lumbal)",
            commonName: "Tiefe vielgefiederte Rueckenmuskeln",
            region: .spineMultifidi,
            tier: .deepStabilizer,
            primaryFunction: "Segmentale Stabilitaet der LWS, Schutz gegen Scherkraefte",
            clinicalSignificance: "Zentraler BWK-Ulm Reha-Schutzmuskel. Sichert Facettengelenke und Bandscheiben vor intraabdominaler Kompression.",
            isBWKCoreCritical: true
        ),
        AnatomicalMuscleEntity(
            id: "rotatores_semispinalis",
            latinName: "Mm. rotatores & semispinalis",
            commonName: "Rotatoren & Halbdornmuskeln der Wirbelsaeule",
            region: .spineMultifidi,
            tier: .microProprioceptive,
            primaryFunction: "Segmentale Wirbelrotation, Haltungsjustierung und propriozeptives Feedback",
            clinicalSignificance: "Reagieren mikrosekundenschnell auf Lastverschiebungen und verhindern Wirbelgleiten."
        ),
        AnatomicalMuscleEntity(
            id: "erector_spinae",
            latinName: "M. erector spinae (Iliocostalis, Longissimus, Spinalis)",
            commonName: "Rueckenstrecker-Kette",
            region: .spineMultifidi,
            tier: .superficial,
            primaryFunction: "Aufrichtung und laterale Flexion der Wirbelsaeule",
            clinicalSignificance: "Traegt Rumpflasten beim Heben; erfordert ausgewogene isometrische Rumpfgurtung."
        ),
        AnatomicalMuscleEntity(
            id: "quadratus_lumborum",
            latinName: "M. quadratus lumborum",
            commonName: "Quadratischer Lendenmuskel",
            region: .spineMultifidi,
            tier: .deepStabilizer,
            primaryFunction: "Lateralflexion, Fixierung der 12. Rippe bei tiefer Zwerchfellatmung",
            clinicalSignificance: "Bindeglied zwischen LWS und Becken; kompensiert haeufig schwache Gluteen."
        ),

        // 7. Tiefer Rumpf & Beckenboden (BWK Reha)
        AnatomicalMuscleEntity(
            id: "transversus_abdominis",
            latinName: "M. transversus abdominis",
            commonName: "Querer Bauchmuskel (Koerper-Korsett)",
            region: .deepCorePelvis,
            tier: .deepStabilizer,
            primaryFunction: "Kompression der Bauchorgane, LWS-Vorspannung vor Extremitaetenbewegung",
            clinicalSignificance: "Hoechste Reha-Prioritaet BWK Ulm (Analprolaps-Schutz). Erhoeht Rumpfsteifigkeit ohne Bandscheibenbeugung.",
            isBWKCoreCritical: true
        ),
        AnatomicalMuscleEntity(
            id: "pelvic_floor_levator_ani",
            latinName: "M. levator ani (Puborectalis, Pubococcygeus, Iliococcygeus)",
            commonName: "Beckenbodenmuskulatur",
            region: .deepCorePelvis,
            tier: .deepStabilizer,
            primaryFunction: "Kontinenzsicherung, viszerale Abstuetzung gegen intraabdominalen Druck",
            clinicalSignificance: "Post-OP Viszeral-Schutz (BWK Ulm). Reaktivierung via Zwerchfellatmung und isometrischer Grundspannung.",
            isBWKCoreCritical: true
        ),
        AnatomicalMuscleEntity(
            id: "obliquus_internus_externus",
            latinName: "Mm. obliquus externus & internus abdominis",
            commonName: "Schraege Bauchmuskeln",
            region: .deepCorePelvis,
            tier: .superficial,
            primaryFunction: "Rumpfrotation, Lateralflexion, Beckenaufrichtung",
            clinicalSignificance: "Arbeiten im Verbund mit dem Transversus; uebertragen diagonale Drehmomente beim Gehen und Laufen."
        ),
        AnatomicalMuscleEntity(
            id: "rectus_abdominis",
            latinName: "M. rectus abdominis",
            commonName: "Gerader Bauchmuskel",
            region: .deepCorePelvis,
            tier: .superficial,
            primaryFunction: "Rumpfbeugung, Beckenkippung nach hinten",
            clinicalSignificance: "Vermeidung dynamischer Crunch-Kompression gemaess BWK-Ulm Standard; Training erfolgt statisch via Planks."
        ),

        // 8. Huefte, Gluteus & Tiefe Rotatoren
        AnatomicalMuscleEntity(
            id: "gluteus_maximus",
            latinName: "M. gluteus maximus",
            commonName: "Grosser Gesaessmuskel",
            region: .hipGluteRotator,
            tier: .superficial,
            primaryFunction: "Hueftstreckung, Aussenrotation, Beckenstabilisation",
            clinicalSignificance: "Staerkster Einzeltreiber fuer Sprint- und Hebeleistung; schuetzt die LWS vor Ueberlastung."
        ),
        AnatomicalMuscleEntity(
            id: "gluteus_medius_minimus",
            latinName: "Mm. gluteus medius & minimus",
            commonName: "Mittlerer und kleiner Gesaessmuskel",
            region: .hipGluteRotator,
            tier: .deepStabilizer,
            primaryFunction: "Abduktion, Beckenstabilisation im Einbeinstand (Trendelenburg-Praevention)",
            clinicalSignificance: "Verhindert Knievalgus und Laeuferknie (ITBS); aktiviert via Einbein-Kniebeugen und Seitstuetz."
        ),
        AnatomicalMuscleEntity(
            id: "piriformis_obturatorius",
            latinName: "M. piriformis, M. obturatorius internus/externus, Mm. gemelli",
            commonName: "Tiefe Aussenrotatoren & Huftgelenkssicherer",
            region: .hipGluteRotator,
            tier: .deepStabilizer,
            primaryFunction: "Feinjustierte Aussenrotation, femorale Gelenkkopfzentrierung im Azetabulum",
            clinicalSignificance: "Vermeidet Ischiadikus-Kompression (Piriformis-Syndrom) und sorgt fuer Beckensymmetrie."
        ),
        AnatomicalMuscleEntity(
            id: "iliopsoas",
            latinName: "M. iliopsoas (Psoas major & Iliacus)",
            commonName: "Lenden-Darmbeinmuskel (Haeuptiger Hueftbeuger)",
            region: .hipGluteRotator,
            tier: .deepStabilizer,
            primaryFunction: "Starke Hueftbeugung, LWS-Lordosierung bei Beugung",
            clinicalSignificance: "Zieht direkt von der LWS zum Femur; neigt bei langem Sitzen zu Verkuerzung und Hyperlordose."
        ),

        // 9. Vorderer Oberschenkel & Adduktoren (Quads)
        AnatomicalMuscleEntity(
            id: "vastus_medialis",
            latinName: "M. vastus medialis (VMO)",
            commonName: "Innerer Oberschenkelmuskel",
            region: .quadricepsThigh,
            tier: .superficial,
            primaryFunction: "Kniestreckung, mediale Patellafuehrung in den letzten Graden der Extension",
            clinicalSignificance: "Schuetzt Patellasehne vor Lateralisation; Schluessel fuer kniegesunde Kniebeugen."
        ),
        AnatomicalMuscleEntity(
            id: "vastus_lateralis_intermedius",
            latinName: "M. vastus lateralis & intermedius",
            commonName: "Aeussere und mittlere Kniestrecker",
            region: .quadricepsThigh,
            tier: .superficial,
            primaryFunction: "Volle Kniestreckung und Lastaufnahme bei Kniebeugen",
            clinicalSignificance: "Hauptanteil des Quadrizepsvolumens; verlangt ausgeglichene antagonistische Dehnung."
        ),
        AnatomicalMuscleEntity(
            id: "rectus_femoris",
            latinName: "M. rectus femoris",
            commonName: "Gerader Oberschenkelmuskel (Zweigelenkig)",
            region: .quadricepsThigh,
            tier: .superficial,
            primaryFunction: "Kniestreckung und Hueftbeugung",
            clinicalSignificance: "Verbindet Becken mit Tibia; neigt bei viel Sitzen zu Verkuerzung."
        ),
        AnatomicalMuscleEntity(
            id: "adductor_group",
            latinName: "Mm. adductores (magnus, longus, brevis, gracilis)",
            commonName: "Adduktoren-Gruppe der Oberschenkel",
            region: .quadricepsThigh,
            tier: .deepStabilizer,
            primaryFunction: "Heranfuehren des Oberschenkels, Beckenstabilisation im Gang",
            clinicalSignificance: "Haeufigste Lokalisation von Leistenzerrungen bei abrupten Richtungswechseln im BFT-Sprint."
        ),

        // 10. Hintere Kette & Ischios (Hamstrings)
        AnatomicalMuscleEntity(
            id: "biceps_femoris",
            latinName: "M. biceps femoris (Caput longum & breve)",
            commonName: "Zweikoepfiger Oberschenkelmuskel",
            region: .hamstringsPosterior,
            tier: .superficial,
            primaryFunction: "Kniebeugung, Aussenrotation des Unterschenkels, Hueftextension",
            clinicalSignificance: "Haeufigster Muskel bei Sprint-Zerrungen; verlangt exzentrisches Nordic-Curl / RDL Training."
        ),
        AnatomicalMuscleEntity(
            id: "semitendinosus_semimembranosus",
            latinName: "Mm. semitendinosus & semimembranosus",
            commonName: "Mediale Beinbeuger",
            region: .hamstringsPosterior,
            tier: .deepStabilizer,
            primaryFunction: "Kniebeugung, Innenrotation des Unterschenkels, Hueftstreckung",
            clinicalSignificance: "Vordere Kreuzband-Synergisten; sichern die Tibia gegen vorderen Schub."
        ),

        // 11. Unterschenkel & Sprunggelenk
        AnatomicalMuscleEntity(
            id: "tibialis_anterior",
            latinName: "M. tibialis anterior",
            commonName: "Vorderer Schienbeinmuskel",
            region: .lowerLegFoot,
            tier: .deepStabilizer,
            primaryFunction: "Dorsalextension des Fusses, Supination",
            clinicalSignificance: "Hauptpuffer gegen Schienbeinkantensyndrom (Shin Splints) beim Laufen und BFT-Sprint."
        ),
        AnatomicalMuscleEntity(
            id: "tibialis_posterior",
            latinName: "M. tibialis posterior",
            commonName: "Hinterer Schienbeinmuskel",
            region: .lowerLegFoot,
            tier: .deepStabilizer,
            primaryFunction: "Plantarflektion, Inversion, dynamische Aufrechterhaltung des Fusslaengsgewoelbes",
            clinicalSignificance: "Verhindert Ueberpronation und Plattfussbildung; Schluessel fuer langlebige Laufmechanik."
        ),
        AnatomicalMuscleEntity(
            id: "soleus",
            latinName: "M. soleus",
            commonName: "Schollenmuskel (Tiefe Wade)",
            region: .lowerLegFoot,
            tier: .deepStabilizer,
            primaryFunction: "Plantarflektion unabhaengig vom Kniewinkel (reine Typ-I-Ausdauerfasern)",
            clinicalSignificance: "Groesster Stossdaempfer beim Joggen; absorbiert das Mehrfache des Koerpergewichts pro Schritt."
        ),
        AnatomicalMuscleEntity(
            id: "gastrocnemius",
            latinName: "M. gastrocnemius",
            commonName: "Zweikoepfiger Wadenmuskel",
            region: .lowerLegFoot,
            tier: .superficial,
            primaryFunction: "Explosive Plantarflektion und Kniebeugungs-Assistenz",
            clinicalSignificance: "Aesthetische Kontur der Wade und explosiver Antritt."
        ),
        AnatomicalMuscleEntity(
            id: "peroneus_group",
            latinName: "Mm. fibulares / peronei (longus & brevis)",
            commonName: "Wadenbeinmuskeln",
            region: .lowerLegFoot,
            tier: .deepStabilizer,
            primaryFunction: "Pronation (Eversion), Sicherung des Aussenknoechels gegen Umknicken",
            clinicalSignificance: "Praevention von Supinationstraumata und Baenderrissen beim Gelaendelauf."
        ),

        // 12. Arme & Unterarmkompartimente
        AnatomicalMuscleEntity(
            id: "brachialis",
            latinName: "M. brachialis",
            commonName: "Armbeuger (unter dem Bizeps)",
            region: .armsForearms,
            tier: .deepStabilizer,
            primaryFunction: "Reine Ellbogenbeugung in Pronation und Supination",
            clinicalSignificance: "Staerkster Beuger des Ellbogens; schiebt den Bizeps optisch nach oben und schuetzt den Sehnenansatz."
        ),
        AnatomicalMuscleEntity(
            id: "biceps_brachii",
            latinName: "M. biceps brachii (Caput longum & breve)",
            commonName: "Zweikoepfiger Armbeuger",
            region: .armsForearms,
            tier: .superficial,
            primaryFunction: "Unterarm-Supination, Ellbogenflexion, Humeruskopf-Anteversion",
            clinicalSignificance: "Lange Bizepssehne stabilisiert das Schultergelenk ventral."
        ),
        AnatomicalMuscleEntity(
            id: "triceps_brachii",
            latinName: "M. triceps brachii (Caput longum, laterale, mediale)",
            commonName: "Dreikoepfiger Armstrecker",
            region: .armsForearms,
            tier: .superficial,
            primaryFunction: "Ellbogenstreckung, Caput longum unterstuetzt Retroversion im Glenohumeralgelenk",
            clinicalSignificance: "Macht 60 % des Oberarmvolumens aus; Haupttreiber aller Druck- und Stoßbewegungen."
        ),
        AnatomicalMuscleEntity(
            id: "forearm_flexors",
            latinName: "Mm. flexores carpi & digitorum (superficialis & profundus)",
            commonName: "Tiefe Finger- und Handgelenksbeuger",
            region: .armsForearms,
            tier: .deepStabilizer,
            primaryFunction: "Isometrische Griffkraft, Handgelenksstabilisation",
            clinicalSignificance: "Direkte Determinante der BFT-Klimmhangdauer und schweren Kreuzhebens."
        ),
        AnatomicalMuscleEntity(
            id: "forearm_extensors_pronator",
            latinName: "Mm. extensores carpi & M. pronator teres",
            commonName: "Unterarmstrecker & Einwaertsdreher",
            region: .armsForearms,
            tier: .deepStabilizer,
            primaryFunction: "Handgelenksextension (Gegenspannung beim Greifen), Unterarmpronation",
            clinicalSignificance: "Verhindert Epicondylitis (Tennis- und Golferellbogen) durch Antagonisten-Balance."
        )
    ]
}
