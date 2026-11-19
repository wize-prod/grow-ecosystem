import Foundation
import SwiftUI

// MARK: - Detailed Anatomical Muscle Entity (Terminologia Anatomica Standard)
public struct DetailedAnatomicalMuscle: Identifiable, Hashable {
    public let id: String
    public let commonName: String
    public let latinName: String
    public let zone: AnatomicalZone
    public let region: String
    public let primaryAction: String
    public let antagonist: String
    public let synergists: String
    public let innervation: String
    public let nerveRoots: String
    public let originInsertion: String
    public let functionalDescription: String
    public let clinicalRelevance: String
    public let recommendedExercises: [String]

    public init(
        id: String,
        commonName: String,
        latinName: String,
        zone: AnatomicalZone,
        region: String,
        primaryAction: String,
        antagonist: String,
        synergists: String,
        innervation: String,
        nerveRoots: String,
        originInsertion: String,
        functionalDescription: String,
        clinicalRelevance: String,
        recommendedExercises: [String]
    ) {
        self.id = id
        self.commonName = commonName
        self.latinName = latinName
        self.zone = zone
        self.region = region
        self.primaryAction = primaryAction
        self.antagonist = antagonist
        self.synergists = synergists
        self.innervation = innervation
        self.nerveRoots = nerveRoots
        self.originInsertion = originInsertion
        self.functionalDescription = functionalDescription
        self.clinicalRelevance = clinicalRelevance
        self.recommendedExercises = recommendedExercises
    }
}

// MARK: - Anatomical Muscle Catalog (Comprehensive Knowledge Base)
public enum AnatomicalMuscleCatalog {
    public static let allMuscles: [DetailedAnatomicalMuscle] = [
        // 1. CHEST / PECTORALIS
        DetailedAnatomicalMuscle(
            id: "pectoralis_major",
            commonName: "Grosse Brustmuskulatur",
            latinName: "Musculus pectoralis major (Pars clavicularis, sternocostalis & abdominalis)",
            zone: .chest,
            region: "Thorax / Vordere Rumpfwand",
            primaryAction: "Adduktion, Innenrotation und horizontale Flexion (Anteversion) des Humerus im Glenohumeralgelenk. Pars clavicularis unterstuetzt Anteversion bis 90 Grad; Pars sternocostalis senkt den erhobenen Arm.",
            antagonist: "Musculus latissimus dorsi, Musculus teres major, Musculus deltoideus (Pars spinalis), Musculi rhomboidei.",
            synergists: "Musculus deltoideus (Pars clavicularis), Musculus coracobrachialis, Musculus pectoralis minor.",
            innervation: "Nervus pectoralis medialis & Nervus pectoralis lateralis (Plexus brachialis)",
            nerveRoots: "C5, C6, C7, C8, Th1",
            originInsertion: "Ursprung: Mediale Clavicula-Haelfte, Sternum, Knorpel der Rippen 1-6, Rektusscheide. Ansatz: Crista tuberculi majoris humeri.",
            functionalDescription: "Hauptmotor fuer saemtliche drueckende Bewegungen nach vorne sowie das Heranfuehren der Arme an den Koerper unter hoher Last.",
            clinicalRelevance: "Verkuerzung fuehrt zu Protraktion der Schultern (Kyphose-Neigung). Kontrollierte Dehnung und gezieltes Training der Antagonisten (Rhomboiden) sichern Schulterblattbalance.",
            recommendedExercises: ["Bankdruecken (Langhantel / Kurzhantel)", "Dips an Barren", "Schraegbankdruecken", "Liegestuetze mit Zusatzlast", "Kabelzug-Flys"]
        ),

        // 2. FRONT DELTS / VORDERE SCHULTER
        DetailedAnatomicalMuscle(
            id: "deltoideus_anterior",
            commonName: "Vordere Deltamuskel-Portion",
            latinName: "Musculus deltoideus (Pars clavicularis & Pars acromialis)",
            zone: .frontDelts,
            region: "Schulterguertel / Glenohumeralgelenk",
            primaryAction: "Anteversion (Vorwaertsbeugung), Innenrotation und horizontale Adduktion des Armes; Pars acromialis initiiert und fuehrt die Abduktion bis 90 Grad.",
            antagonist: "Musculus deltoideus (Pars spinalis), Musculus latissimus dorsi, Musculus infraspinatus, Musculus teres major.",
            synergists: "Musculus pectoralis major (Pars clavicularis), Musculus biceps brachii (Caput longum), Musculus coracobrachialis.",
            innervation: "Nervus axillaris (Fasciculus posterior, Plexus brachialis)",
            nerveRoots: "C5, C6",
            originInsertion: "Ursprung: Laterales Drittel der Clavicula (Pars clavicularis) und Acromion (Pars acromialis). Ansatz: Tuberositas deltoidea humeri.",
            functionalDescription: "Primaerer Treiber fuer saemtliche vertikale Ueberkopfdrueck- und Fronthebebewegungen des Humerus.",
            clinicalRelevance: "Haeufig dominant gegenueber der posterioren Schulter. Erfordert ausgewogene Antagonisten-Stimulation (Face Pulls, Reverse Flys) zur Vorbeugung eines Impingement-Syndroms.",
            recommendedExercises: ["Militaerdruecken / Overhead Press (OHP)", "Kurzhantel-Schulterdruecken", "Handstand-Liegestuetze", "Frontheben"]
        ),

        // 3. BICEPS & BRACHIALIS
        DetailedAnatomicalMuscle(
            id: "biceps_brachii",
            commonName: "Zweikoepfiger Oberarmmuskel & Armbeuger",
            latinName: "Musculus biceps brachii (Caput longum & breve) & Musculus brachialis",
            zone: .biceps,
            region: "Vorderes Oberarmkompartiment (Compartimentum anterius)",
            primaryAction: "Kraftvollster Supinator des Unterarms bei 90 Grad gebeugtem Ellenbogen; Beugung im Ellenbogengelenk. Caput longum assistiert bei Abduktion und Innenrotation des Humerus.",
            antagonist: "Musculus triceps brachii, Musculus anconeus.",
            synergists: "Musculus brachialis (reiner Beuger), Musculus brachioradialis, Musculus pronator teres.",
            innervation: "Nervus musculocutaneus (Fasciculus lateralis, Plexus brachialis)",
            nerveRoots: "C5, C6, C7",
            originInsertion: "Ursprung: Tuberculum supraglenoidale (Caput longum) & Processus coracoideus (Caput breve). Ansatz: Tuberositas radii & Lacertus fibrosus.",
            functionalDescription: "Schluesselmuskel fuer ziehende Flexionsbewegungen (Klimmzuege, Curls) und Griffkraft-Stabilisation.",
            clinicalRelevance: "Die lange Bizepssehne verlaeuft intraartikulaer im Sulcus intertubercularis. Bei chronischer Fehlbelastung Anfaelligkeit fuer Tendinitis; Erfordert exzentrische Kontrolle.",
            recommendedExercises: ["Langhantel-Curls", "Klimmzuege im Untergriff (Chin-Ups)", "Schraegbank-Kurzhantelcurls", "Hammercurls (Fokus Brachialis)"]
        ),

        // 4. FOREARMS / UNTERARME
        DetailedAnatomicalMuscle(
            id: "forearms_flexors_extensors",
            commonName: "Unterarm-Flexoren, Extensoren & Brachioradialis",
            latinName: "Musculus brachioradialis, Pronator teres, Flexor carpi radialis/ulnaris, Extensores digitorum",
            zone: .forearms,
            region: "Vorderes & hinteres Unterarmkompartiment",
            primaryAction: "Palmarflexion und Dorsalextension im Handgelenk, Radial- und Ulnarabduktion, Fingerflexion (Griffkraft) sowie Pronation und Supination des Radius gegen die Ulna.",
            antagonist: "Reziproke Antagonisten: Oberflaechliche und tiefe Beuger (Flexoren) antagonistisch zu Streckern (Extensoren).",
            synergists: "Mm. lumbricales, Mm. interossei dorsales et palmares.",
            innervation: "Nervus medianus, Nervus ulnaris und Nervus radialis (Ramus profundus)",
            nerveRoots: "C6, C7, C8, Th1",
            originInsertion: "Ursprung: Epicondylus medialis humeri (Flexoren) & Epicondylus lateralis humeri (Extensoren). Ansatz: Ossa metacarpi und Phalangen.",
            functionalDescription: "Fundament fuer statische und dynamische Greifkraft, Langhantel-Kontrolle, Klettergriffe und Hebeluebertragung.",
            clinicalRelevance: "Disbalancen zwischen Flexoren und Extensoren verursachen Epicondylitis humeri radialis (Tennisellenbogen) oder ulnaris (Golferellenbogen).",
            recommendedExercises: ["Dead Hangs (Passives & Aktives Haengen)", "Farmers Walk", "Handgelenk-Curls & Reverse Curls", "Gripper-Training"]
        ),

        // 5. RECTUS ABDOMINIS & SERRATUS
        DetailedAnatomicalMuscle(
            id: "rectus_abdominis",
            commonName: "Gerader Bauchmuskel & Vorderer Saegemuskel",
            latinName: "Musculus rectus abdominis & Musculus serratus anterior",
            zone: .abdominals,
            region: "Vordere Rumpf- und Thoraxwand",
            primaryAction: "Ventralflexion der Lenden- und Brustwirbelsaeule, Beckenaufrichtung (hinterer Beckenkipp / Posterior Pelvic Tilt), Bauchpresse. Serratus anterior: Protraktion und Aufwaertsrotation der Scapula.",
            antagonist: "Musculus erector spinae (Spinalstrecker), Musculus iliopsoas (bei Rumpfstreckung).",
            synergists: "Musculus transversus abdominis, Musculus obliquus externus & internus abdominis.",
            innervation: "Nervi intercostales (Th7-Th12) fuer Rectus abdominis; Nervus thoracicus longus (C5-C7) fuer Serratus anterior.",
            nerveRoots: "Th7, Th8, Th9, Th10, Th11, Th12 (Rectus) & C5, C6, C7 (Serratus)",
            originInsertion: "Ursprung Rectus: Knorpel der Rippen 5-7, Processus xiphoideus. Ansatz: Crista pubica und Symphysis pubica. Zwischensehnen: Intersectiones tendineae (6-Pack).",
            functionalDescription: "Zentraler Pfeiler der Rumpfstabilitaet; uebertraegt Kraft zwischen Becken und Brustkorb ohne Hyperextension der Lendenwirbelsaeule.",
            clinicalRelevance: "BWK-Ulm Reha-Constraint: Klassische Crunches mit hoher intraabdominaler Druckspitze sind verboten. Funktionelle Planks, Hollow Body und Pallof Press schuetzen Beckenboden und Analregion.",
            recommendedExercises: ["Unterarmstuetz (Plank) mit KSP-Spannung", "Hollow Body Hold", "Hanging Leg Raises / L-Sit", "Ab-Wheel Rollouts"]
        ),

        // 6. OBLIQUES / SEITLICHE BAUCHMUSKELN
        DetailedAnatomicalMuscle(
            id: "obliques_core",
            commonName: "Aeussere und innere schraege Bauchmuskeln",
            latinName: "Musculus obliquus externus abdominis & Musculus obliquus internus abdominis",
            zone: .obliques,
            region: "Laterale Bauchwand & Beckenkamm",
            primaryAction: "Einseitig: Lateralflexion der Wirbelsaeule nach ipsilateral und Rumpfrotation (Externus nach kontralateral, Internus nach ipsilateral). Beidseitig: Ventralflexion und Ausatmung (Bauchpresse).",
            antagonist: "Kontralaterale Obliquus-Muskeln und Musculus quadratus lumborum.",
            synergists: "Musculus transversus abdominis, Musculus rectus abdominis, Musculi rotatores.",
            innervation: "Nervi intercostales (Th7-Th12), Nervus iliohypogastricus, Nervus ilioinguinalis",
            nerveRoots: "Th7, Th8, Th9, Th10, Th11, Th12, L1",
            originInsertion: "Ursprung: Rippen 5-12 (Externus) bzw. Crista iliaca und Fascia thoracolumbalis (Internus). Ansatz: Linea alba, Crista pubica, Rippen 10-12.",
            functionalDescription: "Stabilisiert die Rotationsachse des Torsos gegen unerwuenschte Scherkraefte bei Kniebeugen, Kreuzheben und Spurtlaeufen.",
            clinicalRelevance: "Unterstuetzt die Dekompression der Bandscheiben L4/L5 und L5/S1 durch Aufbau eines zylindrischen Rumpfdruck-Korsetts.",
            recommendedExercises: ["Pallof Press am Kabelzug", "Side Planks mit Beinheben", "Suitcase Deadlifts / Carries", "Woodchoppers"]
        ),

        // 7. QUADRICEPS FEMORIS
        DetailedAnatomicalMuscle(
            id: "quadriceps_femoris",
            commonName: "Vierkoepfiger Oberschenkelmuskel",
            latinName: "Musculus quadriceps femoris (Rectus femoris, Vastus lateralis, Vastus medialis & intermedius)",
            zone: .quads,
            region: "Vorderes Oberschenkelkompartiment (Extensoren)",
            primaryAction: "Kraftvollste Extension (Streckung) im Kniegelenk ueber die Patellarsehne. Musculus rectus femoris ueberbrueckt als zwei-gelenkiger Muskel zusaetzlich das Hueftgelenk und fuehrt Hueftflexion aus.",
            antagonist: "Ischiocrurale Muskelgruppe (Hamstrings: M. biceps femoris, M. semitendinosus, M. semimembranosus).",
            synergists: "Musculus tensor fasciae latae, Musculus sartorius, Musculus pectineus.",
            innervation: "Nervus femoralis (Plexus lumbalis)",
            nerveRoots: "L2, L3, L4",
            originInsertion: "Ursprung: Spina iliaca anterior inferior (Rectus) & Linea aspera / Trochanter major (Vasti). Ansatz: Tuberositas tibiae via Ligamentum patellae.",
            functionalDescription: "Hauptantrieb fuer Kniebeugen, Spruenge, Treppensteigen, Sprints und vertikale Explosivkraft.",
            clinicalRelevance: "Vastus medialis (VMO / Teardrop) ist unverzichtbar fuer das patellofemorale Gleitlager und verhindert lateralen Patellasubluxationstendenz.",
            recommendedExercises: ["Kniebeugen (Back Squats / Front Squats)", "Ausfallschritte (Walking Lunges)", "Bulgarian Split Squats", "Beinpresse 45 Grad"]
        ),

        // 8. CALVES ANTERIOR & POSTERIOR
        DetailedAnatomicalMuscle(
            id: "calves_tibialis_gastrocnemius",
            commonName: "Dreikoepfiger Wadenmuskel & Vorderer Schienbeinmuskel",
            latinName: "Musculus triceps surae (Gastrocnemius Caput mediale/laterale & Soleus) & Musculus tibialis anterior",
            zone: .calvesAnterior,
            region: "Unterschenkel (Crus) - Ventral- und Dorsalkompartiment",
            primaryAction: "Triceps surae: Plantarflexion im oberen Sprunggelenk, Inversion im unteren Sprunggelenk, Knieflexion (Gastrocnemius). Tibialis anterior: Kraeftige Dorsalextension und Supination.",
            antagonist: "Reziprok: Triceps surae ist direkter Antagonist des Musculus tibialis anterior und Extensor digitorum longus.",
            synergists: "Musculus plantaris, Musculus tibialis posterior, Musculi peronei (fibulari).",
            innervation: "Nervus tibialis (fuer Triceps surae) & Nervus fibularis/peroneus profundus (fuer Tibialis anterior)",
            nerveRoots: "L4, L5, S1, S2",
            originInsertion: "Ursprung: Condylus medialis & lateralis femoris (Gastrocnemius), Tibia/Fibula (Soleus). Ansatz: Tuber calcanei ueber Tendo calcaneus (Achillessehne).",
            functionalDescription: "Stoessedaempfung beim Fersenauftritt, katapultartiger Vortrieb beim Sprinten und Stabilisierung des Sprunggelenks im Einbeinstand.",
            clinicalRelevance: "Ausgewogenes Verhaeltnis zwischen Waden und Schienbeinmuskel schuetzt vor Shin Splints (Tibiakantensyndrom) und Achillessehnenentzuendung.",
            recommendedExercises: ["Stehendes Wadenheben (Fokus Gastrocnemius)", "Sitzendes Wadenheben (Fokus Soleus)", "Tibialis-Raises", "Seilspringen"]
        ),

        // 9. TRAPEZIUS & NECK
        DetailedAnatomicalMuscle(
            id: "trapezius_neck",
            commonName: "Trapezmuskel & Nackenmuskulatur",
            latinName: "Musculus trapezius (Pars descendens, transversa & ascendens) & Splenius capitis",
            zone: .traps,
            region: "Dorsaler Nacken- und oberer Rueckenbereich",
            primaryAction: "Pars descendens: Hebung (Elevation) der Scapula und Drehung des Kopfes nach kontralateral; Pars transversa: Kraeftige Retraktion (Zusammenziehen) der Schulterblaetter nach medial; Pars ascendens: Depression (Senkung) der Scapula.",
            antagonist: "Musculus serratus anterior und Musculus pectoralis minor (fuer Scapula-Retraktion).",
            synergists: "Musculus levator scapulae, Musculi rhomboidei major et minor, Musculus latissimus dorsi (untere Fasern).",
            innervation: "Nervus accessorius (Hirnnerv XI) & Rami anteriores der Spinalnerven C3-C4 (Plexus cervicalis)",
            nerveRoots: "CN XI, C3, C4",
            originInsertion: "Ursprung: Linea nuchalis superior, Protuberantia occipitalis externa, Dornfortsaetze C1-Th12. Ansatz: Laterales Drittel der Clavicula, Acromion, Spina scapulae.",
            functionalDescription: "Verankert die Scapula am Achsenskelett, traegt Lasten am herabhaengenden Arm und stabilisiert die Halswirbelsaeule bei schwerem Heben.",
            clinicalRelevance: "Hypertonie der Pars descendens durch Schreibtischhaltung haeufig Ausloeser von zervikogenen Spannungskopfschmerzen. Pars ascendens gezielt kraeftigen.",
            recommendedExercises: ["Shrugs mit Langhantel / Kurzhanteln", "Face Pulls mit Aussenrotation", "Scapular Pull-Ups", "Farmer's Walk mit schwerem Gewicht"]
        ),

        // 10. REAR DELTS / HINTERE SCHULTER
        DetailedAnatomicalMuscle(
            id: "deltoideus_posterior",
            commonName: "Hintere Deltamuskel-Portion",
            latinName: "Musculus deltoideus (Pars spinalis)",
            zone: .rearDelts,
            region: "Dorsales Schulterdach / Scapulaspina",
            primaryAction: "Retroversion (Rueckwaertsfuehrung), Aussenrotation und horizontale Abduktion des Humerus im Schultergelenk.",
            antagonist: "Musculus deltoideus (Pars clavicularis), Musculus pectoralis major.",
            synergists: "Musculus infraspinatus, Musculus teres minor, Musculus latissimus dorsi.",
            innervation: "Nervus axillaris (Fasciculus posterior, Plexus brachialis)",
            nerveRoots: "C5, C6",
            originInsertion: "Ursprung: Untere Lippe der Spina scapulae. Ansatz: Tuberositas deltoidea humeri.",
            functionalDescription: "Zieht den Arm horizontal nach hinten und aussen; essenziell fuer eine ausgewogene 3D-Schulteroptik und Scapula-Stabilitaet.",
            clinicalRelevance: "Einer der meistvernachlaessigten Muskeln im Kraftsport. Ein Defizit beguenstigt Schulter-Innenrotationsstellungen und subakromiale Enge.",
            recommendedExercises: ["Reverse Butterfly (Maschine / Kabel)", "Vorgebeugtes Seitheben mit Kurzhanteln", "Band Pull-Aparts", "Face Pulls auf Augenhoehe"]
        ),

        // 11. LATISSIMUS DORSI
        DetailedAnatomicalMuscle(
            id: "latissimus_dorsi",
            commonName: "Breiter Rueckenmuskel",
            latinName: "Musculus latissimus dorsi (Pars vertebralis, costalis, iliaca & scapularis)",
            zone: .lats,
            region: "Dorsaler Rumpf / Flanke (Oberer bis unterer Ruecken)",
            primaryAction: "Kraeftige Adduktion, Retroversion und Innenrotation des Armes im Glenohumeralgelenk. Bei fixierten Armen Zieht er den Rumpf nach oben (Klimmzug) oder nach vorn.",
            antagonist: "Musculus deltoideus (Pars clavicularis & acromialis), Musculus pectoralis major (obere Anteile).",
            synergists: "Musculus teres major ('kleiner Bruder des Lats'), Musculus triceps brachii (Caput longum), Musculi rhomboidei.",
            innervation: "Nervus thoracodorsalis (Fasciculus posterior, Plexus brachialis)",
            nerveRoots: "C6, C7, C8",
            originInsertion: "Ursprung: Dornfortsaetze Th7-L5, Fascia thoracolumbalis, Crista iliaca, Rippen 9-12. Ansatz: Crista tuberculi minoris humeri.",
            functionalDescription: "Flaechenmaessig groesster Muskel des menschlichen Koerpers; formt das V-Taper-Profil und uebertraegt Zugkraefte zwischen Becken und Armen.",
            clinicalRelevance: "Ein tonischer Latissimus zieht ueber die Crista tuberculi minoris den Humerus nach innen und kann ein anteriores Schulterkippen verstaerken.",
            recommendedExercises: ["Klimmzuege (Pull-Ups im weiten Obergriff)", "Latzug zur Brust", "Vorgebeugtes Langhantelrudern", "Einarmiges Kurzhantelrudern"]
        ),

        // 12. TRICEPS BRACHII
        DetailedAnatomicalMuscle(
            id: "triceps_brachii",
            commonName: "Dreikoepfiger Oberarmmuskel & Armstrecker",
            latinName: "Musculus triceps brachii (Caput longum, Caput laterale, Caput mediale)",
            zone: .triceps,
            region: "Hinteres Oberarmkompartiment (Compartimentum posterius)",
            primaryAction: "Einziger kraftvoller Strecker (Extension) im Ellenbogengelenk. Caput longum fuehrt zusaetzlich Adduktion und Retroversion des Humerus im Schultergelenk aus.",
            antagonist: "Musculus biceps brachii, Musculus brachialis, Musculus brachioradialis.",
            synergists: "Musculus anconeus.",
            innervation: "Nervus radialis (Fasciculus posterior, Plexus brachialis)",
            nerveRoots: "C6, C7, C8",
            originInsertion: "Ursprung: Tuberculum infraglenoidale scapulae (Caput longum), Dorsalflaeche des Humerus ober- und unterhalb des Sulcus nervi radialis (Caput laterale & mediale). Ansatz: Olecranon ulnae.",
            functionalDescription: "Macht ca. 60 Prozent der gesamten Oberarmmasse aus. Entscheidend fuer die Endstreckung bei allen Druckuebungen.",
            clinicalRelevance: "Der Nervus radialis verlaeuft im Sulcus direkt zwischen den Trizepskoepfen. Schwellungen oder Sehnenentzuendungen koennen zu Kribbeln fuehren.",
            recommendedExercises: ["Enges Bankdruecken (Close-Grip Bench Press)", "Dips am Barren mit aufrechtem Torso", "French Press / Skull Crushers", "Trizepsdruecken am Kabelzug"]
        ),

        // 13. LOWER BACK / ERECTOR SPINAE
        DetailedAnatomicalMuscle(
            id: "erector_spinae",
            commonName: "Rueckenstrecker & Autochthone Rueckenmuskulatur",
            latinName: "Musculus erector spinae (M. iliocostalis, M. longissimus, M. spinalis) & Mm. multifidi",
            zone: .lowerBack,
            region: "Wirbelsaeulenlaengsrinne / Lumbalbereich",
            primaryAction: "Beidseitig: Aufrichtung (Extension) der Lenden-, Brust- und Halswirbelsaeule, Haltungskontrolle gegen die Schwerkraft. Einseitig: Lateralflexion und Rotation.",
            antagonist: "Musculus rectus abdominis, Musculi obliqui externus et internus abdominis, Musculus psoas major.",
            synergists: "Musculus quadratus lumborum, Musculus gluteus maximus (synergistisch bei posteriorer Kettenstreckung).",
            innervation: "Rami posteriores (dorsales) der Spinalnerven (segmental C1-S3)",
            nerveRoots: "Segmental ueber alle zervikalen, thorakalen und lumbalen Spinalnerven",
            originInsertion: "Ursprung: Os sacrum, Crista iliaca, Processus spinosi lumbales. Ansatz: Rippenwinkel, Processus transversi und spinosi bis zum Hinterkopf.",
            functionalDescription: "Schuetzt die Bandscheiben bei Hebevorgaengen durch kontinuierliche isometrische Gegenspannung zur Last.",
            clinicalRelevance: "Schluesselstruktur bei lumbaler Instabilitaet. Erfordert kontrollierte, schmerzfreie Beanspruchung ohne unphysiologische Scherhebel.",
            recommendedExercises: ["Rumaenisches Kreuzheben (RDL)", "Hyperextensions / Rueckenstrecker 45 Grad", "Good Mornings mit moderatem Gewicht", "Bird-Dog Stabilisation"]
        ),

        // 14. GLUTEUS MAXIMUS & MEDIUS
        DetailedAnatomicalMuscle(
            id: "gluteus_maximus_medius",
            commonName: "Grosse und mittlere Gesaessmuskulatur",
            latinName: "Musculus gluteus maximus, Musculus gluteus medius & minimus",
            zone: .glutes,
            region: "Regio glutealis / Dorsales Becken",
            primaryAction: "Gluteus maximus: Kraftvollste Extension und Aussenrotation im Hueftgelenk; Stabilisierung des Beckens in der Sagittalebene. Gluteus medius: Haupt-Abduktor im Hueftgelenk, verhindert das Absinken des Beckens zur Spielbeinseite (Trendelenburg-Praevention).",
            antagonist: "Musculus iliopsoas, Musculus rectus femoris (Hueftbeuger) sowie Adduktorengruppe.",
            synergists: "Hamstrings (M. biceps femoris, M. semitendinosus), Musculus piriformis, Musculus tensor fasciae latae.",
            innervation: "Nervus gluteus inferior (L5-S2, fuer M. gluteus maximus) & Nervus gluteus superior (L4-S1, fuer M. gluteus medius/minimus)",
            nerveRoots: "L4, L5, S1, S2",
            originInsertion: "Ursprung: Ala ossis ilii, Facies dorsalis ossis sacri, Ligamentum sacrotuberale. Ansatz: Tuberositas glutea femoris & Tractus iliotibialis (Maximus); Trochanter major (Medius).",
            functionalDescription: "Kraftzentrum des Unterkoerpers; verantwortlich fuer Sprintantrieb, Kniebeugentiefe, Treppensteigen und aufrechten Gang.",
            clinicalRelevance: "Gesaessmuskel-Amnesie durch langes Sitzen fuehrt zu vorderem Beckenkipp und kompensatorischer LWS-Ueberlastung. Glute Bridges reaktivieren die neuromuskulaere Ansteuerung.",
            recommendedExercises: ["Hip Thrusts (Langhantel)", "Tiefe Kniebeugen", "Rumaenisches Kreuzheben", "Kabelzug-Kickbacks", "Bulgarian Split Squats"]
        ),

        // 15. HAMSTRINGS / ISCHIOCRURALE
        DetailedAnatomicalMuscle(
            id: "hamstrings_ischiocrural",
            commonName: "Hintere Oberschenkelmuskulatur (Ischiocrurale Muskeln)",
            latinName: "Mm. ischiocrurales (Musculus biceps femoris, Musculus semitendinosus, Musculus semimembranosus)",
            zone: .hamstrings,
            region: "Hinteres Oberschenkelkompartiment (Flexoren)",
            primaryAction: "Flexion (Beugung) und Innen-/Aussenrotation im Kniegelenk; kraftvolle Extension (Streckung) im Hueftgelenk.",
            antagonist: "Musculus quadriceps femoris (Beinstrecker).",
            synergists: "Musculus gluteus maximus (Hueftextension), Musculus gastrocnemius (Knieflexion), Musculus gracilis.",
            innervation: "Nervus tibialis (Semimembranosus, Semitendinosus, Caput longum Biceps femoris) & Nervus fibularis communis (Caput breve Biceps femoris)",
            nerveRoots: "L5, S1, S2",
            originInsertion: "Ursprung: Tuber ischiadicum (Sitzbeinhoecker) & Linea aspera femoris (Caput breve). Ansatz: Caput fibulae (Biceps) bzw. Pes anserinus und Condylus medialis tibiae.",
            functionalDescription: "Primaerer Bremsmechanismus beim Sprinten; schuetzt das vordere Kreuzband (VKB) vor anteriorer Tibiatranslation.",
            clinicalRelevance: "Verkuerzung fuehrt zu erhoehtem Zug am Tuber ischiadicum und Abflachung der Lendenlordose. Erfordert exzentrisches Krafttraining zur Faserverlaengerung.",
            recommendedExercises: ["Nordic Hamstring Curls", "Rumaenisches Kreuzheben (RDL)", "Liegende / Sitzende Beinbeuger", "Gleitscheiben-Beinbeuger"]
        ),

        // 16. CALVES POSTERIOR / TRICEPS SURAE
        DetailedAnatomicalMuscle(
            id: "calves_posterior_soleus",
            commonName: "Hintere Wadenmuskulatur & Schollenmuskel",
            latinName: "Musculus gastrocnemius (Caput mediale & laterale) & Musculus soleus",
            zone: .calvesPosterior,
            region: "Dorsales Unterschenkelkompartiment (Oberflaechliche Schicht)",
            primaryAction: "Plantarflexion des Fusses (Zehenstand); Inversion (Hebung des medialen Fussrandes). Gastrocnemius unterstuetzt Knieflexion.",
            antagonist: "Musculus tibialis anterior, Musculus extensor digitorum longus.",
            synergists: "Musculus plantaris, Musculus tibialis posterior, Musculus flexor hallucis longus.",
            innervation: "Nervus tibialis (Plexus sacralis)",
            nerveRoots: "S1, S2",
            originInsertion: "Ursprung: Condylus medialis/lateralis femoris (Gastrocnemius) bzw. Linea musculi solei der Tibia/Fibula (Soleus). Ansatz: Tuber calcanei ueber Achillessehne.",
            functionalDescription: "Tracer fuer Bodenreaktionskraefte; Soleus besteht ueberwiegend aus Typ-I-Ausdauerfasern, waehrend Gastrocnemius Typ-II-Schnellkraftfasern dominiert.",
            clinicalRelevance: "Soleus ist der primaere Muskel-Venen-Pumpenmotor fuer den venoesen Rueckstrom zum Herzen gegen die Schwerkraft.",
            recommendedExercises: ["Wadenheben stehend", "Wadenheben sitzend (Knie 90 Grad)", "Donkey Calf Raises", "Bergaufsprints"]
        )
    ]

    public static func muscle(for zone: AnatomicalZone) -> DetailedAnatomicalMuscle? {
        allMuscles.first { $0.zone == zone }
    }

    public static func muscle(byId id: String) -> DetailedAnatomicalMuscle? {
        allMuscles.first { $0.id == id }
    }

    public static func muscle(forMuscle muscle: Muscle) -> DetailedAnatomicalMuscle {
        switch muscle {
        case .upperBack:
            return DetailedAnatomicalMuscle(
                id: "latissimus_dorsi",
                commonName: "Breiter Rueckenmuskel",
                latinName: "Musculus latissimus dorsi (Pars vertebralis, costalis, iliaca & scapularis)",
                zone: .lats,
                region: "Dorsaler Rumpf / Flanke (Oberer bis unterer Ruecken)",
                primaryAction: "Kraeftige Adduktion, Retroversion und Innenrotation des Humerus im Glenohumeralgelenk. Bei fixierten Armen Zieht er den Rumpf nach oben (Klimmzug). Stabilisiert kontralateral beim Laufen via Posterior Oblique Sling.",
                antagonist: "Musculus deltoideus (Pars clavicularis & acromialis), Musculus pectoralis major (obere Anteile).",
                synergists: "Musculus teres major, Musculi rhomboidei, Musculus biceps brachii, Musculus triceps brachii (Caput longum).",
                innervation: "Nervus thoracodorsalis (Fasciculus posterior, Plexus brachialis)",
                nerveRoots: "C6, C7, C8",
                originInsertion: "Ursprung: Dornfortsaetze Th7-L5, Fascia thoracolumbalis, Crista iliaca, Rippen 9-12. Ansatz: Crista tuberculi minoris humeri.",
                functionalDescription: "Flaechenmaessig groesster Muskel des menschlichen Koerpers; formt das V-Taper-Profil und uebertraegt Zugkraefte zwischen Becken und Armen.",
                clinicalRelevance: "Ein tonischer Latissimus zieht ueber die Crista tuberculi minoris den Humerus nach innen und kann ein anteriores Schulterkippen verstaerken.",
                recommendedExercises: ["Klimmzuege (Pull-Ups im weiten Obergriff)", "Latzug zur Brust", "Vorgebeugtes Langhantelrudern", "Einarmiges Kurzhantelrudern"]
            )

        case .rhomboids:
            return DetailedAnatomicalMuscle(
                id: "rhomboids",
                commonName: "Rautenmuskeln",
                latinName: "Musculi rhomboidei (Musculus rhomboideus major & Musculus rhomboideus minor)",
                zone: .lats,
                region: "Interscapulaerer Raum (Mittlerer oberer Ruecken)",
                primaryAction: "Retraktion (Zusammenziehen) und Hebung der Scapula nach kranial-medial; presst das Schulterblatt flach an den Thorax (Verhinderung einer Scapula alata zusammen mit M. serratus anterior).",
                antagonist: "Musculus serratus anterior, Musculus pectoralis minor.",
                synergists: "Musculus trapezius (Pars transversa), Musculus levator scapulae, Musculus latissimus dorsi.",
                innervation: "Nervus dorsalis scapulae (Plexus brachialis)",
                nerveRoots: "C4, C5",
                originInsertion: "Ursprung: Dornfortsaetze C6-C7 (Minor) und Th1-Th4 (Major). Ansatz: Margo medialis scapulae.",
                functionalDescription: "Schluesselstruktur fuer eine aufrechte Haltung, Schulterblattstabilitaet bei Zuguebungen und Praevention des Geierhalses / Rundrueckens.",
                clinicalRelevance: "Schwaeche fuehrt zu Schulter-Protraktion und Schmerzen im interskapulaeren Bereich bei laengerem Sitzen.",
                recommendedExercises: ["Rudern am Kabelzug mit Schulterblattretraktion", "Face Pulls", "Chest-Supported Row", "Band Pull-Aparts"]
            )

        case .rotatorCuff:
            return DetailedAnatomicalMuscle(
                id: "rotator_cuff",
                commonName: "Rotatorenmanschette",
                latinName: "Musculus infraspinatus, Supraspinatus, Teres minor & Subscapularis",
                zone: .lats,
                region: "Dorsale Scapulafossa & Glenohumeralgelenk",
                primaryAction: "Dynamische Zentrierung des Humeruskopfes in der Fossa glenoidalis. Infraspinatus & Teres minor fuehren kraftvolle Aussenrotation aus; Supraspinatus initiiert Abduktion (0-15 Grad).",
                antagonist: "Musculus subscapularis, Musculus pectoralis major, Musculus latissimus dorsi (Innenrotatoren).",
                synergists: "Musculus deltoideus (Pars spinalis), Musculus teres major.",
                innervation: "Nervus suprascapularis (Infraspinatus/Supraspinatus) & Nervus axillaris (Teres minor)",
                nerveRoots: "C5, C6",
                originInsertion: "Ursprung: Fossa supraspinata & infraspinata scapulae. Ansatz: Tuberculum majus humeri.",
                functionalDescription: "Das dynamische Fuehrungsgelenk der Schulter; verhindert das Auskugeln (Luxation) und schuetzt den Gelenkknorpel bei Wurfbewegungen und Drucklasten.",
                clinicalRelevance: "Impingement-Gefahr der Supraspinatussehne unter dem Acromion; Aussenrotatoren-Training ist Pflicht fuer jeden Kraftsportler.",
                recommendedExercises: ["Kabelzug Aussenrotation", "L-Flyes mit Kurzhantel", "Face Pulls mit Endrotation", "Prone Y-T-W-L Heben"]
            )

        case .upperTrapezius:
            return DetailedAnatomicalMuscle(
                id: "trapezius_pars_descendens",
                commonName: "Oberer Nacken-Trapez",
                latinName: "Musculus trapezius (Pars descendens)",
                zone: .traps,
                region: "Dorsale Halswirbelsaeule & Kranialer Schulterguertel",
                primaryAction: "Hebung (Elevation) der Scapula, Drehung des Kopfes zur Gegenseite, Rumpf-HWS-Stabilisation.",
                antagonist: "Musculus trapezius (Pars ascendens), Musculus pectoralis minor, Schwerkraft.",
                synergists: "Musculus levator scapulae, Musculus rhomboideus major/minor.",
                innervation: "Nervus accessorius (Hirnnerv XI) & Rami anteriores C3-C4",
                nerveRoots: "CN XI, C3, C4",
                originInsertion: "Ursprung: Linea nuchalis superior, Os occipitale, Dornfortsaetze C1-C6. Ansatz: Laterales Drittel der Clavicula.",
                functionalDescription: "Reagiert extrem sensibel auf Stress und Schreibtischhaltung; traegt die Arme gegen die Schwerkraft.",
                clinicalRelevance: "Myogelosen und Triggerpunkte strahlen oft als Spannungskopfschmerz bis hinter die Augen.",
                recommendedExercises: ["Shrugs mit Kurzhanteln", "Farmer's Walk", "Scapular Pull-Ups"]
            )

        case .lowerTrapezius:
            return DetailedAnatomicalMuscle(
                id: "trapezius_pars_ascendens",
                commonName: "Unterer Trapezmuskel",
                latinName: "Musculus trapezius (Pars ascendens)",
                zone: .traps,
                region: "Thorakale Wirbelsaeulenrinne (Rueckenmitte)",
                primaryAction: "Depression (Herabziehen) und Aufwaertsrotation der Scapula; sichert das Schulterblatt gegen Hochziehen bei Ueberkopfbewegungen.",
                antagonist: "Musculus trapezius (Pars descendens), Musculus levator scapulae.",
                synergists: "Musculus serratus anterior, Musculus latissimus dorsi (untere Fasern).",
                innervation: "Nervus accessorius (Hirnnerv XI) & Plexus cervicalis",
                nerveRoots: "CN XI, C3, C4",
                originInsertion: "Ursprung: Dornfortsaetze Th5-Th12. Ansatz: Spina scapulae (mediales Ende).",
                functionalDescription: "Der wichtigste Haltungsmuskel gegen Schulterhochstand und Nackenverspannung.",
                clinicalRelevance: "Fast immer gehemmt und geschwaecht bei Schreibtischtätern; gezieltes Training loest chronische Nackenschmerzen.",
                recommendedExercises: ["Y-Raises am Schraegbank/Boden", "Trap 3 Raises", "Scapular Dips"]
            )

        case .upperChest:
            return DetailedAnatomicalMuscle(
                id: "pectoralis_clavicularis",
                commonName: "Obere Brustmuskulatur",
                latinName: "Musculus pectoralis major (Pars clavicularis)",
                zone: .chest,
                region: "Kraniale vordere Thoraxwand",
                primaryAction: "Horizontale Adduktion, schraege Anteversion (Armhebung bis 90 Grad) und Innenrotation des Humerus.",
                antagonist: "Musculus latissimus dorsi, Musculus deltoideus (Pars spinalis).",
                synergists: "Musculus deltoideus (Pars clavicularis), Musculus coracobrachialis.",
                innervation: "Nervus pectoralis lateralis (C5-C7)",
                nerveRoots: "C5, C6, C7",
                originInsertion: "Ursprung: Mediale Claviculahaelfte. Ansatz: Crista tuberculi majoris humeri.",
                functionalDescription: "Verantwortlich fuer Fuelle im oberen Brustbereich und Druckkraft bei Steigungswinkeln.",
                clinicalRelevance: "Entscheidend fuer die Aesthetik des Oberkoerpers und Schubsicherung des Sternoklavikulargelenks.",
                recommendedExercises: ["Schraegbankdruecken (30-45 Grad)", "Incline Dumbbell Press", "Kabelzug von unten nach oben"]
            )

        case .lowerChest:
            return DetailedAnatomicalMuscle(
                id: "pectoralis_sternocostalis",
                commonName: "Untere & Mittlere Brust",
                latinName: "Musculus pectoralis major (Pars sternocostalis & abdominalis)",
                zone: .chest,
                region: "Kaudale vordere Thoraxwand",
                primaryAction: "Adduktion des erhobenen Armes nach unten und innen, kraftvolle Vorwaertsdrueckbewegung.",
                antagonist: "Musculus deltoideus (Pars acromialis & clavicularis bei Ueberkopf).",
                synergists: "Musculus triceps brachii, Musculus deltoideus anterior.",
                innervation: "Nervus pectoralis medialis (C8-Th1)",
                nerveRoots: "C8, Th1",
                originInsertion: "Ursprung: Sternum, Rippenknorpel 1-6, Rektusscheide. Ansatz: Crista tuberculi majoris humeri.",
                functionalDescription: "Primaerer Motor fuer Dips, Flachbankdruecken und Liegestuetze.",
                clinicalRelevance: "Macht die Hauptmasse der Brustmuskulatur aus.",
                recommendedExercises: ["Dips an Barren", "Flachbankdruecken", "Decline Press", "Liegestuetze"]
            )

        case .upperAbs:
            return DetailedAnatomicalMuscle(
                id: "rectus_superior",
                commonName: "Obere Bauchmuskulatur",
                latinName: "Musculus rectus abdominis (Kraniale Segmente)",
                zone: .abdominals,
                region: "Oberbauch / Epigastrium",
                primaryAction: "Beugung (Flexion) der Brust- und Lendenwirbelsaeule gegen das fixierte Becken.",
                antagonist: "Musculus erector spinae (Thorakaler Anteil).",
                synergists: "Musculus obliquus internus/externus, Musculus transversus abdominis.",
                innervation: "Nervi intercostales (Th7-Th9)",
                nerveRoots: "Th7, Th8, Th9",
                originInsertion: "Ursprung: Cartilago costalis 5-7, Processus xiphoideus. Ansatz: Obere Intersectiones tendineae.",
                functionalDescription: "Zieht den Brustkorb in Richtung Beckenkamm.",
                clinicalRelevance: "Wichtig fuer statische Rumpfkontrolle ohne Lordose.",
                recommendedExercises: ["Unterarmstuetz (Plank)", "Kabelzug-Crunches (stehend)", "Hollow Body Hold"]
            )

        case .lowerAbs:
            return DetailedAnatomicalMuscle(
                id: "rectus_inferior_transversus",
                commonName: "Untere Bauchmuskulatur & Transversus",
                latinName: "Musculus rectus abdominis (Kaudales Segment) & Musculus transversus abdominis",
                zone: .abdominals,
                region: "Unterbauch / Hypogastrium & Beckenkamm",
                primaryAction: "Beckenaufrichtung (Posterior Pelvic Tilt), Einziehung der Bauchwand, Sicherung des Iliosakralgelenks gegen Scherkraefte.",
                antagonist: "Musculus erector spinae (lumbal), Musculus iliopsoas.",
                synergists: "Musculus obliquus internus abdominis, Beckenbodenmuskulatur.",
                innervation: "Nervi intercostales (Th10-Th12), Nervus iliohypogastricus, Nervus ilioinguinalis",
                nerveRoots: "Th10, Th11, Th12, L1",
                originInsertion: "Ursprung: Fascia thoracolumbalis, Crista iliaca, Ligamentum inguinale. Ansatz: Linea alba, Os pubis.",
                functionalDescription: "Das anatomische Korsett des Menschen. Unverzichtbar fuer einen flachen Bauch und Bandscheibenschutz.",
                clinicalRelevance: "Verhindert Bandscheibenvorfaelle in L4-S1 und entlastet post-OP die Anal- und Beckenregion.",
                recommendedExercises: ["Deadbugs mit LWS-Bodendruck", "Hanging Leg Raises / Knee Tucks", "McGill Curl-Ups (10s Holds)"]
            )

        case .serratus:
            return DetailedAnatomicalMuscle(
                id: "serratus_anterior",
                commonName: "Vorderer Saegemuskel",
                latinName: "Musculus serratus anterior",
                zone: .abdominals,
                region: "Laterale Thoraxwand (Rippen 1-9)",
                primaryAction: "Protraktion der Scapula nach lateral-ventral, Drehung des Angulus inferior nach aussen fuer Ueberkopfbewegungen; haelt das Schulterblatt am Thorax.",
                antagonist: "Musculi rhomboidei major et minor, Musculus trapezius (Pars transversa).",
                synergists: "Musculus pectoralis minor.",
                innervation: "Nervus thoracicus longus (Plexus brachialis)",
                nerveRoots: "C5, C6, C7",
                originInsertion: "Ursprung: 1.-9. Rippe. Ansatz: Margo medialis & Angulus inferior scapulae.",
                functionalDescription: "Der 'Boxermuskel'; formt die markanten 'Zacken' an den Rippen neben dem Sixpack.",
                clinicalRelevance: "Laesion des N. thoracicus longus fuehrt zur 'Engelsfluegel'-Stellung (Scapula alata).",
                recommendedExercises: ["Scapular Push-ups (Liegestuetz Plus)", "Ab-Wheel Rollouts", "Ueberzuege mit Kurzhantel"]
            )

        case .innerQuad:
            return DetailedAnatomicalMuscle(
                id: "vastus_medialis",
                commonName: "Innerer Oberschenkelmuskel (Teardrop)",
                latinName: "Musculus vastus medialis (VMO)",
                zone: .quads,
                region: "Mediales distales Oberschenkelkompartiment",
                primaryAction: "Extension im Kniegelenk, insbesondere die letzten 15 Grad der Endstreckung; mediale Fuehrung und Zentrierung der Patella.",
                antagonist: "Musculus biceps femoris (Caput breve & longum).",
                synergists: "Musculus vastus lateralis, Musculus rectus femoris, Musculus vastus intermedius.",
                innervation: "Nervus femoralis (Plexus lumbalis)",
                nerveRoots: "L2, L3, L4",
                originInsertion: "Ursprung: Mediale Lippe der Linea aspera femoris. Ansatz: Basis und medialer Rand der Patella, Tuberositas tibiae.",
                functionalDescription: "Formt die Tropfenform oberhalb des Knies; schuetzt vor Knieinstabilitaet und Kreuzbandstress.",
                clinicalRelevance: "Schwaeche fuehrt zu patellofemoralem Schmerzsyndrom (Verschleiss des Knorpels hinter der Kniescheibe).",
                recommendedExercises: ["Poliquin Step-Ups / Peterson Step-Ups", "Cyclist Squats mit Fersenerhoehung", "Ausfallschritte", "Leg Extensions"]
            )

        case .outerQuad:
            return DetailedAnatomicalMuscle(
                id: "vastus_lateralis",
                commonName: "Aeusserer Oberschenkelmuskel",
                latinName: "Musculus vastus lateralis",
                zone: .quads,
                region: "Laterales Oberschenkelkompartiment",
                primaryAction: "Kraftvollste Kniestreckung; bildet den massiven aeusseren Oberschenkelschwung (Quad Sweep).",
                antagonist: "Ischiocrurale Muskelgruppe (Hamstrings).",
                synergists: "Musculus vastus medialis, Musculus rectus femoris, Musculus vastus intermedius.",
                innervation: "Nervus femoralis (Plexus lumbalis)",
                nerveRoots: "L2, L3, L4",
                originInsertion: "Ursprung: Linea aspera (Labium laterale), Trochanter major femoris. Ansatz: Patella & Tuberositas tibiae.",
                functionalDescription: "Hauptkrafttraeger fuer maximale Beuge- und Strecklasten bei schweren Kniebeugen.",
                clinicalRelevance: "Haeufig hyperton; neigt zur Verklebung mit dem Tractus iliotibialis (Laeuferknie / ITBS).",
                recommendedExercises: ["Frontkniebeugen", "Beinpresse enger Stand", "Hackenschmidt Kniebeugen", "Walking Lunges"]
            )

        case .adductors:
            return DetailedAnatomicalMuscle(
                id: "adductores_femoris",
                commonName: "Adduktorengruppe",
                latinName: "Musculus adductor magnus, longus, brevis, pectineus & gracilis",
                zone: .quads,
                region: "Mediale Oberschenkelinnenseite",
                primaryAction: "Heranfuehren (Adduktion) des Beines zur Koerpermitte, Beckenstabilisation in der Frontalebene; assistiert bei Hueftbeugung und -streckung.",
                antagonist: "Musculus gluteus medius, Musculus gluteus minimus, Musculus tensor fasciae latae (Abduktoren).",
                synergists: "Musculus gracilis, Musculus pectineus.",
                innervation: "Nervus obturatorius (L2-L4) & Nervus tibialis (ischiokondylaerer Anteil des M. adductor magnus)",
                nerveRoots: "L2, L3, L4",
                originInsertion: "Ursprung: Ramus inferior ossis pubis & Tuber ischiadicum. Ansatz: Linea aspera femoris & Tuberculum adductorium.",
                functionalDescription: "Stabilisiert das Schambein und den Beckenring beim Sprinten, Richtungswechseln und Kniebeugen.",
                clinicalRelevance: "Schambeinentzuendung (Osteitis pubis) und Leistenzerrungen resultieren oft aus Dysbalancen zwischen Adduktoren und Abduktoren.",
                recommendedExercises: ["Copenhagen Planks", "Sumo Kniebeugen / Sumo Deadlifts", "Adduktorenmaschine", "Kosakensquats"]
            )

        case .rearDeltoid:
            return DetailedAnatomicalMuscle(
                id: "deltoideus_posterior",
                commonName: "Hintere Schulterportion",
                latinName: "Musculus deltoideus (Pars spinalis)",
                zone: .rearDelts,
                region: "Dorsale Schulterkappe / Spina scapulae",
                primaryAction: "Retroversion, Aussenrotation und horizontale Abduktion des Humerus im Schultergelenk.",
                antagonist: "Musculus deltoideus (Pars clavicularis), Musculus pectoralis major.",
                synergists: "Musculus infraspinatus, Musculus teres minor, Musculi rhomboidei.",
                innervation: "Nervus axillaris (Fasciculus posterior, Plexus brachialis)",
                nerveRoots: "C5, C6",
                originInsertion: "Ursprung: Unterlippe der Spina scapulae. Ansatz: Tuberositas deltoidea humeri.",
                functionalDescription: "Gleicht die dominierende Brust- und Vorderschulterkraft aus und zieht die Schulter nach hinten.",
                clinicalRelevance: "Schuetzt vor vorderem Impingement und anteriorer Humeruskopf-Translation.",
                recommendedExercises: ["Reverse Flys mit Kurzhanteln", "Face Pulls auf Stirnhoehe", "Band Pull-Aparts", "Rear Delt Flys am Kabel"]
            )

        case .frontDeltoid:
            return DetailedAnatomicalMuscle(
                id: "deltoideus_anterior",
                commonName: "Vordere Schulterportion",
                latinName: "Musculus deltoideus (Pars clavicularis)",
                zone: .frontDelts,
                region: "Vordere Schulterkappe / Clavicula",
                primaryAction: "Anteversion (Vorwaertsflexion), Innenrotation und horizontale Adduktion des Armes.",
                antagonist: "Musculus deltoideus (Pars spinalis), Musculus latissimus dorsi.",
                synergists: "Musculus pectoralis major (Pars clavicularis), Musculus biceps brachii.",
                innervation: "Nervus axillaris (C5, C6)",
                nerveRoots: "C5, C6",
                originInsertion: "Ursprung: Laterales Drittel der Clavicula. Ansatz: Tuberositas deltoidea humeri.",
                functionalDescription: "Hauptmotor fuer vertikales Druecken und Ueberkopfarbeit.",
                clinicalRelevance: "Wird bei fast allen Drueckuebungen mittrainiert; neigt zur Verkuerzung.",
                recommendedExercises: ["Militaerdruecken / OHP", "Schulterdruecken Kurzhantel", "Handstand Push-ups", "Frontheben"]
            )

        default:
            let z = AnatomicalMuscleMapView.resolveZone(for: muscle, on: .front)
            return Self.muscle(for: z) ?? allMuscles[0]
        }
    }
}
