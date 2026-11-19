import Foundation

public struct ExerciseCatalogSeed {
    public static func defaultExercises() -> [Exercise] {
        var list: [Exercise] = [
            // 1. Schulterdrück-Maschine
            Exercise(
                name: "Schulterdruecken (Maschine)",
                targetMuscle: .shoulders,
                equipment: .shoulderPressMachine,
                isBWKRehaSafe: true,
                executionNotes: "Gefuehrte Schulterpresse im Bundeswehr Kraftraum. Sitzhoehe so einstellen, dass Griffe auf Schulterhoehe starten.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 90
            ),

            // 2. 3D Rudermaschine
            Exercise(
                name: "3D Rudern beidarmig",
                targetMuscle: .back,
                equipment: .rowMachine3D,
                isBWKRehaSafe: true,
                executionNotes: "Dynamische 3D-Trajektorie. Schulterblaetter kontrolliert nach hinten unten ziehen, Rumpf stabilisieren.",
                defaultSets: 4, defaultReps: 10, defaultRestSeconds: 90
            ),
            Exercise(
                name: "3D Rudern einarmig",
                targetMuscle: .back,
                equipment: .rowMachine3D,
                isBWKRehaSafe: true,
                executionNotes: "Einarmige Ausfuehrung fuer gezielte Latissimus- und Rhomboiden-Aktivierung ohne Rumpfrotation.",
                defaultSets: 3, defaultReps: 12, defaultRestSeconds: 75
            ),

            // 3. Klimmzüge- & Dips-Maschine
            Exercise(
                name: "Unterstuetzte Klimmzuege (Maschine)",
                targetMuscle: .back,
                equipment: .assistedChinDipMachine,
                isBWKRehaSafe: true,
                executionNotes: "Gegengewichtsplattform waehlen. Volle Streckung im Latissimus, kontrollierter Zug zur Brust.",
                defaultSets: 3, defaultReps: 8, defaultRestSeconds: 90
            ),
            Exercise(
                name: "Unterstuetzte Dips (Maschine)",
                targetMuscle: .arms,
                equipment: .assistedChinDipMachine,
                isBWKRehaSafe: true,
                executionNotes: "Ellbogen eng fuehren zur Trizeps-Fokussierung. Keine Ueberstreckung in der Schulter.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 90
            ),

            // 4. Rhomboideus-Maschine
            Exercise(
                name: "Rhomboideus-Maschine",
                targetMuscle: .back,
                equipment: .rhomboideusMachine,
                isBWKRehaSafe: true,
                executionNotes: "Reine Scapula-Retraktion. Brustpolster stabilisiert den Oberkoerper; Schultern bewusst nach hinten fixieren.",
                defaultSets: 3, defaultReps: 12, defaultRestSeconds: 75
            ),

            // 5. Beinpress-Maschine
            Exercise(
                name: "Beinpresse 45-Grad",
                targetMuscle: .legs,
                equipment: .legPressMachine,
                isBWKRehaSafe: true,
                executionNotes: "Fuesse schulterbreit. Ruecken und Gesaess fest an der Lehne lassen, kein Einrunden des unteren Rueckens.",
                defaultSets: 4, defaultReps: 10, defaultRestSeconds: 120
            ),
            Exercise(
                name: "Einbeinige Beinpresse",
                targetMuscle: .legs,
                equipment: .legPressMachine,
                isBWKRehaSafe: true,
                executionNotes: "Unilaterale Kraftentwicklung zur Ausgleichung von Dysbalancen.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 90
            ),

            // 6. Hip-Thrust / Glute-Drive-Maschine
            Exercise(
                name: "Glute Drive / Hip Thrust Maschine",
                targetMuscle: .glutesPosterior,
                equipment: .hipThrustGluteDrive,
                isBWKRehaSafe: true,
                executionNotes: "Gurt fest ueber Becken anlegen. Gluteus oben 2 Sekunden maximal kontrahieren. Reha-Safe fuer Beckenboden.",
                defaultSets: 4, defaultReps: 12, defaultRestSeconds: 90
            ),

            // 7. Neunstöckige-Maschine
            Exercise(
                name: "Kabelrudern (Neunstoeckig)",
                targetMuscle: .back,
                equipment: .nineStationTower,
                isBWKRehaSafe: true,
                executionNotes: "Am Multifunktionsturm mit V-Griff. Aufrechter Oberkoerper, Zug zur unteren Bauchwand.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Trizepsdruecken am Seil (Neunstoeckig)",
                targetMuscle: .arms,
                equipment: .nineStationTower,
                isBWKRehaSafe: true,
                executionNotes: "Tau-Aufsatz am Seilzug. Am Ende die Handgelenke leicht nach aussen spreizen.",
                defaultSets: 3, defaultReps: 12, defaultRestSeconds: 60
            ),
            Exercise(
                name: "Kabel-Curls (Neunstoeckig)",
                targetMuscle: .arms,
                equipment: .nineStationTower,
                isBWKRehaSafe: true,
                executionNotes: "Gerade Stange von unten. Ellbogen fixieren.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 60
            ),

            // 8. Beinbeuge-Maschine
            Exercise(
                name: "Beinbeugen liegend (Maschine)",
                targetMuscle: .glutesPosterior,
                equipment: .legCurlMachine,
                isBWKRehaSafe: true,
                executionNotes: "Ischiokrurale Muskulatur isoliert ansteuern. Becken bleibt flach auf dem Polster.",
                defaultSets: 3, defaultReps: 12, defaultRestSeconds: 75
            ),

            // 9. Adduktions-Maschine
            Exercise(
                name: "Adduktion (Maschine)",
                targetMuscle: .legs,
                equipment: .adductionMachine,
                isBWKRehaSafe: true,
                executionNotes: "Beckenboden- und Innenschenkelstabilisation. Gleichmaessige Bewegung ohne Schwung.",
                defaultSets: 3, defaultReps: 15, defaultRestSeconds: 60
            ),

            // 10. Oberkörper-Ergometer
            Exercise(
                name: "Oberkoerper-Ergometer (Armkurbel)",
                targetMuscle: .cardioConditioning,
                equipment: .upperBodyErgometer,
                isBWKRehaSafe: true,
                executionNotes: "Handkurbel-Cardio zur Vagus-Regulation und aeroben Oberkoerper-Durchblutung.",
                defaultSets: 1, defaultReps: 15, defaultRestSeconds: 60
            ),

            // 11. Abduktions-Maschine
            Exercise(
                name: "Abduktion (Maschine)",
                targetMuscle: .glutesPosterior,
                equipment: .abductionMachine,
                isBWKRehaSafe: true,
                executionNotes: "Glaetteus Medius Kraeftigung. Unterstuetzt Beckenstabilitaet beim Gehen und Laufen.",
                defaultSets: 3, defaultReps: 15, defaultRestSeconds: 60
            ),

            // 12. Rumpfdrehmaschine
            Exercise(
                name: "Rumpfdrehung (Rotary Torso)",
                targetMuscle: .functionalCore,
                equipment: .rotaryTorsoMachine,
                isBWKRehaSafe: true,
                executionNotes: "Sehr kontrollierte Drehbewegung. Keine ruckartigen Endstellungen.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 60
            ),

            // 13. Seitneige-Maschine
            Exercise(
                name: "Seitneigen (Maschine)",
                targetMuscle: .functionalCore,
                equipment: .lateralFlexionMachine,
                isBWKRehaSafe: true,
                executionNotes: "Seitliche Rumpfmuskulatur auf der Fuehrungsschiene. Reha-konform dosiert.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 60
            ),

            // 14. Rücken-Maschine
            Exercise(
                name: "Rueckenstrecker (Maschine)",
                targetMuscle: .lowerBack,
                equipment: .backExtensionMachine,
                isBWKRehaSafe: true,
                executionNotes: "Gefuehrte Streckung der erector spinae. Gleichmaessige Kraftentfaltung.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),

            // 15. Butterfly-Maschine (Pec-Deck)
            Exercise(
                name: "Butterfly / Pec-Deck",
                targetMuscle: .chest,
                equipment: .butterflyPecDeck,
                isBWKRehaSafe: true,
                executionNotes: "Brustmuskel-Isolation. Ellbogen leicht gebeugt, Schulterblaetter hinten fixiert.",
                defaultSets: 3, defaultReps: 12, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Reverse Butterfly (Pec-Deck)",
                targetMuscle: .back,
                equipment: .butterflyPecDeck,
                isBWKRehaSafe: true,
                executionNotes: "Rueckwaertige Schulter und Rhomboiden. Optimale Haltungskorrektur.",
                defaultSets: 3, defaultReps: 12, defaultRestSeconds: 60
            ),

            // 16. Pullover-Maschine
            Exercise(
                name: "Pullover / Ueberzuege (Maschine)",
                targetMuscle: .back,
                equipment: .pulloverMachine,
                isBWKRehaSafe: true,
                executionNotes: "Latissimus-Isolation ueber den vollen Bewegungsradius ohne Griffkraft-Limitierung.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),

            // 17. Bruststück-Maschine
            Exercise(
                name: "Brustdruecken (Maschine)",
                targetMuscle: .chest,
                equipment: .chestPressMachine,
                isBWKRehaSafe: true,
                executionNotes: "Gefuehrte Brustpresse. Gleichmaessig ausatmen beim Vorschieben.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 90
            ),

            // 18. Kurzhanteln (1kg bis 37.5kg)
            Exercise(
                name: "Kurzhantel Bankdruecken",
                targetMuscle: .chest,
                equipment: .dumbBells,
                isBWKRehaSafe: true,
                executionNotes: "Freie Kurzhanteln auf der Flachbank. Kontrollierte Dehnung.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 90
            ),
            Exercise(
                name: "Kurzhantel Schulterdruecken sitzend",
                targetMuscle: .shoulders,
                equipment: .dumbBells,
                isBWKRehaSafe: true,
                executionNotes: "Auf 80-Grad-Bank sitzend. Saubere vertikale Drucklinie.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 90
            ),
            Exercise(
                name: "Seitheben (Kurzhanteln)",
                targetMuscle: .shoulders,
                equipment: .dumbBells,
                isBWKRehaSafe: true,
                executionNotes: "Leichte Kurzhanteln (6-12 kg). Seitliche Schulter fuehren.",
                defaultSets: 3, defaultReps: 12, defaultRestSeconds: 60
            ),
            Exercise(
                name: "Bizepscurls (Kurzhanteln)",
                targetMuscle: .arms,
                equipment: .dumbBells,
                isBWKRehaSafe: true,
                executionNotes: "Alternierende oder parallele Curls mit Supination.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 60
            ),

            // 19. Flachbank mit Langhantel
            Exercise(
                name: "Bankdruecken (Langhantel)",
                targetMuscle: .chest,
                equipment: .flatBenchBarbell,
                isBWKRehaSafe: true,
                executionNotes: "Klassische Flachbank-Station. Fester Stand, Schulterblaetter zusammengezogen.",
                defaultSets: 4, defaultReps: 8, defaultRestSeconds: 120
            ),
            Exercise(
                name: "Enges Bankdruecken (Langhantel)",
                targetMuscle: .arms,
                equipment: .flatBenchBarbell,
                isBWKRehaSafe: true,
                executionNotes: "Griffbreite ca. 30 cm. Fokus auf den Trizeps.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 90
            ),

            // 20. Verstellbare Hantelbank
            Exercise(
                name: "Incline Bench Press (Schraegbank)",
                targetMuscle: .chest,
                equipment: .adjustableBench,
                isBWKRehaSafe: true,
                executionNotes: "Einstellung ca. 30 Grad. Oberer Anteil des grossen Brustmuskels.",
                defaultSets: 3, defaultReps: 8, defaultRestSeconds: 90
            ),
            Exercise(
                name: "Schraegbank Curls (Kurzhanteln)",
                targetMuscle: .arms,
                equipment: .adjustableBench,
                isBWKRehaSafe: true,
                executionNotes: "Bank auf 45-60 Grad. Starke Dehnung des langen Bizepskopfes.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 60
            ),

            // 21. Zugapparat (Cable-Crossover / Kabelzugturm)
            Exercise(
                name: "Cable Crossover / Flys",
                targetMuscle: .chest,
                equipment: .cableCrossoverTower,
                isBWKRehaSafe: true,
                executionNotes: "Konstante Spannung am Kabelturm ueber den gesamten Bewegungsweg.",
                defaultSets: 3, defaultReps: 12, defaultRestSeconds: 60
            ),
            Exercise(
                name: "Pallof Press (Kabelzug)",
                targetMuscle: .functionalCore,
                equipment: .cableCrossoverTower,
                isBWKRehaSafe: true,
                executionNotes: "Goldstandard BWK Ulm Reha: Antirotatorische Rumpfstabilisation. Keine Bauchwand-Kompression.",
                defaultSets: 3, defaultReps: 12, defaultRestSeconds: 60
            ),
            Exercise(
                name: "Face Pulls (Kabelzug)",
                targetMuscle: .shoulders,
                equipment: .cableCrossoverTower,
                isBWKRehaSafe: true,
                executionNotes: "Zug zu Stirn/Augenhoehe mit Aussenrotation. Schultergesundheit pur.",
                defaultSets: 3, defaultReps: 15, defaultRestSeconds: 60
            ),

            // 22. Zugapparat: Einzel-Variante
            Exercise(
                name: "Einarmiges Seitheben am Kabel",
                targetMuscle: .shoulders,
                equipment: .singleCableTower,
                isBWKRehaSafe: true,
                executionNotes: "Single Tower Kabelzug. Kontinuierlicher Zugwiderstand.",
                defaultSets: 3, defaultReps: 12, defaultRestSeconds: 60
            ),
            Exercise(
                name: "Einarmiges Trizepsdruecken am Kabel",
                targetMuscle: .arms,
                equipment: .singleCableTower,
                isBWKRehaSafe: true,
                executionNotes: "Einzel-Kabelzug ohne Griffaufsatz (am Ballen).",
                defaultSets: 3, defaultReps: 12, defaultRestSeconds: 60
            ),

            // 23. Scott-Curl-Bank (Preacher Curl)
            Exercise(
                name: "Preacher Curls (SZ-Stange / KH)",
                targetMuscle: .arms,
                equipment: .preacherCurlBench,
                isBWKRehaSafe: true,
                executionNotes: "Oberarme auf Scott-Polster fixiert. Absolute Isolation ohne Abfaelschen.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),

            // 24. Latzug-Maschine (Lat Pulldown)
            Exercise(
                name: "Latzug zur Brust (breit)",
                targetMuscle: .back,
                equipment: .latPulldownMachine,
                isBWKRehaSafe: true,
                executionNotes: "Breite Latzugstange. Zug zur oberen Brust, Rumpf leicht nach hinten geneigt.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 90
            ),
            Exercise(
                name: "Latzug enger Parallelgriff",
                targetMuscle: .back,
                equipment: .latPulldownMachine,
                isBWKRehaSafe: true,
                executionNotes: "V-Griff. Tiefes Ziehen zum Brustbein fuer maximalen Lat-Stretch.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 90
            ),

            // 25. Smith Machine (Multipresse)
            Exercise(
                name: "Multipresse Kniebeugen",
                targetMuscle: .legs,
                equipment: .smithMachine,
                isBWKRehaSafe: true,
                executionNotes: "Gefuehrte Kniebeuge. Fuesse leicht nach vorne versetzt fuer aufrechten Oberkoerper.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 90
            ),
            Exercise(
                name: "Multipresse Schulterdruecken",
                targetMuscle: .shoulders,
                equipment: .smithMachine,
                isBWKRehaSafe: true,
                executionNotes: "Gefuehrtes Schulterdruecken an der Multipresse auf Hantelbank.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 90
            ),

            // 26. Römische Bank / Hyperextensionsbank
            Exercise(
                name: "Roemische Bank Hyperextension",
                targetMuscle: .lowerBack,
                equipment: .romanChairBackExtension,
                isBWKRehaSafe: true,
                executionNotes: "Becken am Polster anlegen. Oberkoerper kontrolliert senken und in Gerade aufrichten.",
                defaultSets: 3, defaultReps: 12, defaultRestSeconds: 60
            ),

            // 27. Römische Bank für Bauchtraining
            Exercise(
                name: "Seitstuetz / Oblique Hold (Roemische Bank)",
                targetMuscle: .functionalCore,
                equipment: .romanChairOblique,
                isBWKRehaSafe: true,
                isContraindicated: false,
                executionNotes: "Reha-konform: Isometrisches Halten der seitlichen Bauchwand ohne Beugung oder Druck.",
                defaultSets: 3, defaultReps: 30, defaultRestSeconds: 60
            ),
            Exercise(
                name: "Crunches / Sit-ups auf Roemischer Bank",
                targetMuscle: .functionalCore,
                equipment: .romanChairOblique,
                isBWKRehaSafe: false,
                isContraindicated: true,
                executionNotes: "BWK ULM REHA SPERRE: Klassische Crunches/Sit-ups sind strikt verboten (erhoeht intraabdominalen Druck).",
                defaultSets: 0, defaultReps: 0, defaultRestSeconds: 0
            ),

            // 28. Hyperextensionsbank (45°-Variante)
            Exercise(
                name: "45-Grad Rueckenstrecken mit Gluteus-Fokus",
                targetMuscle: .lowerBack,
                equipment: .hyperextension45,
                isBWKRehaSafe: true,
                executionNotes: "Fuesse leicht nach aussen rotiert. Gluteus oben 2 Sekunden maximal anspannen.",
                defaultSets: 3, defaultReps: 12, defaultRestSeconds: 60
            ),

            // 29. Prowler / Sled (Schlitten)
            Exercise(
                name: "Prowler Push (Schlitten schieben)",
                targetMuscle: .cardioConditioning,
                equipment: .prowlerSled,
                isBWKRehaSafe: true,
                executionNotes: "Konditions- und Kraftuebung auf dem Kunstrasenstreifen. Fester Rumpf, kraftvoller Beinvortrieb.",
                defaultSets: 4, defaultReps: 20, defaultRestSeconds: 90
            ),
            Exercise(
                name: "Sled Pull rueckwaerts",
                targetMuscle: .legs,
                equipment: .prowlerSled,
                isBWKRehaSafe: true,
                executionNotes: "Rueckwaertiges Ziehen zur VMO-Staerke (Kniegesundheit) und Beinkraft.",
                defaultSets: 3, defaultReps: 20, defaultRestSeconds: 90
            ),

            // 30. Kettlebells (4kg bis 32kg)
            Exercise(
                name: "Kettlebell Deadlift (Kreuzheben)",
                targetMuscle: .glutesPosterior,
                equipment: .kettlebells,
                isBWKRehaSafe: true,
                executionNotes: "Saubere Hueftbeugung (Hinge). Ruecken gerade, Beine leicht gebeugt.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Kettlebell Farmers Walk",
                targetMuscle: .functionalCore,
                equipment: .kettlebells,
                isBWKRehaSafe: true,
                executionNotes: "Schwere Kettlebells tragen. Schultern zurueck, aufrechter Gang, Rumpfspannung.",
                defaultSets: 3, defaultReps: 40, defaultRestSeconds: 60
            ),

            // 31. Campusboard / Hangboard
            Exercise(
                name: "Hangboard Dead Hang (Fingerkraft)",
                targetMuscle: .back,
                equipment: .campusHangboard,
                isBWKRehaSafe: true,
                executionNotes: "Grip- und Unterarmkraft. Schultern aktiv herunterziehen (kein passives Haengen).",
                defaultSets: 4, defaultReps: 15, defaultRestSeconds: 90
            ),

            // 32. Turnringe (Gym Rings)
            Exercise(
                name: "Turnringe Rudern (Ring Rows)",
                targetMuscle: .back,
                equipment: .gymRings,
                isBWKRehaSafe: true,
                executionNotes: "Schraeger Koerperwinkel am Ringgestell. Kontrolliertes Heranziehen zur Brust.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 60
            ),
            Exercise(
                name: "Ring Support Hold",
                targetMuscle: .functionalCore,
                equipment: .gymRings,
                isBWKRehaSafe: true,
                executionNotes: "Statische Stuetzposition in den Ringen. Arme gestreckt, Schultern tief.",
                defaultSets: 3, defaultReps: 20, defaultRestSeconds: 60
            ),

            // 33. Klimmzugstange
            Exercise(
                name: "Klimmzuege Obergriff (Pull-ups)",
                targetMuscle: .back,
                equipment: .pullUpBar,
                isBWKRehaSafe: true,
                executionNotes: "Klassische Bundeswehr-Klimmzuege. Volle Streckung und Kinn ueber die Stange.",
                defaultSets: 3, defaultReps: 8, defaultRestSeconds: 90
            ),
            Exercise(
                name: "Klimmzuege Untergriff (Chin-ups)",
                targetMuscle: .arms,
                equipment: .pullUpBar,
                isBWKRehaSafe: true,
                executionNotes: "Handflaechen zum Gesicht. Hohe Bizeps- und Latissimus-Beteiligung.",
                defaultSets: 3, defaultReps: 8, defaultRestSeconds: 90
            ),

            // 34. Dipsstation
            Exercise(
                name: "Barren-Dips (Frei)",
                targetMuscle: .arms,
                equipment: .dipStation,
                isBWKRehaSafe: true,
                executionNotes: "Freie Dips an der Holmen-Station. Kontrollierte Beugung bis 90 Grad.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 90
            ),

            // 35. Wadenmaschine für sitzendes Wadenheben
            Exercise(
                name: "Wadenheben sitzend (Maschine)",
                targetMuscle: .legs,
                equipment: .seatedCalfRaise,
                isBWKRehaSafe: true,
                executionNotes: "Isoliertes Training des Soleus-Muskels. Unten dehnen, oben 1 Sekunde halten.",
                defaultSets: 4, defaultReps: 15, defaultRestSeconds: 60
            ),

            // 36. Squat Rack / Kniebeugenständer
            Exercise(
                name: "Langhantel Kniebeugen (Squat Rack)",
                targetMuscle: .legs,
                equipment: .squatRack,
                isBWKRehaSafe: true,
                executionNotes: "Sicherheitsablagen passend einstellen. Fester Rumpf, parallele Tiefe.",
                defaultSets: 4, defaultReps: 8, defaultRestSeconds: 120
            ),
            Exercise(
                name: "Militaer-Schulterdruecken stehend (OHP)",
                targetMuscle: .shoulders,
                equipment: .squatRack,
                isBWKRehaSafe: true,
                executionNotes: "Aus dem Squat Rack heraus. Fester Stand, Gluteus angespannt.",
                defaultSets: 3, defaultReps: 8, defaultRestSeconds: 90
            ),

            // 37. Stationäres Fahrrad-Ergometer
            Exercise(
                name: "Fahrrad-Ergometer Grundlagenausdauer",
                targetMuscle: .cardioConditioning,
                equipment: .stationaryBike,
                isBWKRehaSafe: true,
                executionNotes: "Regeneratives Radfahren GA1 (Pulsbereich ca. 110-130 bpm).",
                defaultSets: 1, defaultReps: 25, defaultRestSeconds: 60
            ),

            // 38. Ruderergometer (Concept2 RowErg)
            Exercise(
                name: "Concept2 RowErg Rudern",
                targetMuscle: .cardioConditioning,
                equipment: .concept2RowErg,
                isBWKRehaSafe: true,
                executionNotes: "Beine - Rumpf - Arme Sequenz einhalten. Schlagzahl 22-26 s/m.",
                defaultSets: 1, defaultReps: 20, defaultRestSeconds: 90
            ),

            // 39. Assault Bike (Air Bike)
            Exercise(
                name: "Assault AirBike Intervalle",
                targetMuscle: .cardioConditioning,
                equipment: .assaultBike,
                isBWKRehaSafe: true,
                executionNotes: "High-Intensity Conditioning. Beine und Arme simultan im Einsatz.",
                defaultSets: 5, defaultReps: 1, defaultRestSeconds: 60
            ),

            // 40. Laufband (Treadmill)
            Exercise(
                name: "Laufband Steigungswalking",
                targetMuscle: .cardioConditioning,
                equipment: .treadmill,
                isBWKRehaSafe: true,
                executionNotes: "Steigung 8-12 % bei 5.0 km/h. Hohe Fettverbrennung, gelenkschonend.",
                defaultSets: 1, defaultReps: 25, defaultRestSeconds: 60
            ),
            Exercise(
                name: "Laufband Tempodauerlauf",
                targetMuscle: .cardioConditioning,
                equipment: .treadmill,
                isBWKRehaSafe: true,
                executionNotes: "Gleichmaessiges Tempo zur Vorbereitung auf Bundeswehr-Leistungspruefungen.",
                defaultSets: 1, defaultReps: 20, defaultRestSeconds: 60
            ),

            // 41. Große Mattenfläche
            Exercise(
                name: "Unterarmstuetz / Plank",
                targetMuscle: .functionalCore,
                equipment: .matArea,
                isBWKRehaSafe: true,
                executionNotes: "Reha-Grundpfeiler: Statische Ganzkoerperspannung ohne Quetschung der Eingeweide.",
                defaultSets: 3, defaultReps: 45, defaultRestSeconds: 60
            ),
            Exercise(
                name: "Bird-Dog (Vierfuesslerstand)",
                targetMuscle: .functionalCore,
                equipment: .matArea,
                isBWKRehaSafe: true,
                executionNotes: "Diagonales Heben von Arm und Bein. Rumpf und Becken bleiben absolut waagerecht.",
                defaultSets: 3, defaultReps: 12, defaultRestSeconds: 60
            ),
            Exercise(
                name: "Klassische Crunches (Matte)",
                targetMuscle: .functionalCore,
                equipment: .matArea,
                isBWKRehaSafe: false,
                isContraindicated: true,
                executionNotes: "BWK ULM REHA SPERRE: Crunches sind postoperativ strikt kontraindiziert.",
                defaultSets: 0, defaultReps: 0, defaultRestSeconds: 0
            ),
            Exercise(
                name: "Faszienrolle Beine & Ruecken",
                targetMuscle: .cardioConditioning,
                equipment: .matArea,
                isBWKRehaSafe: true,
                executionNotes: "Myofasziale Selbstmassage zur Entspannung und Regeneration nach Dienstschluss.",
                defaultSets: 1, defaultReps: 10, defaultRestSeconds: 30
            ),
            Exercise(
                name: "Einarmige Liegestuetze",
                targetMuscle: .chest,
                secondaryMuscles: [.arms, .functionalCore, .shoulders],
                equipment: .bodyweight,
                isBWKRehaSafe: true,
                executionNotes: "Elite Calisthenics: Dreiecks-Stand fuer Anti-Rotationsstabilitaet. Freie Hand am Ruecken. Becken parallel zum Boden halten. 10 Wdh pro Arm.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 90
            ),
            Exercise(
                name: "Liegestuetze (BWK-konform kontrolliert)",
                targetMuscle: .chest,
                secondaryMuscles: [.shoulders, .arms, .functionalCore],
                equipment: .matArea,
                isBWKRehaSafe: true,
                executionNotes: "Saubere Koerperspannung. Brust absenken, gleichmaessig ausatmen beim Druecken. Kein Pressen.",
                defaultSets: 3, defaultReps: 12, defaultRestSeconds: 60
            ),
            Exercise(
                name: "Ausfallschritte im Stand (Bodyweight)",
                targetMuscle: .legs,
                secondaryMuscles: [.glutesPosterior],
                equipment: .matArea,
                isBWKRehaSafe: true,
                executionNotes: "Aufrechter Oberkoerper, stabiler Stand. Knie sanft absenken ohne Bodenkontakt.",
                defaultSets: 3, defaultReps: 12, defaultRestSeconds: 60
            ),
            Exercise(
                name: "Glute Bridge am Boden (Beckenheben)",
                targetMuscle: .glutesPosterior,
                secondaryMuscles: [.functionalCore, .lowerBack],
                equipment: .matArea,
                isBWKRehaSafe: true,
                executionNotes: "Fersen fest in den Boden druecken, Gesaess am obersten Punkt fuer 2 Sekunden anspannen.",
                defaultSets: 3, defaultReps: 15, defaultRestSeconds: 60
            ),
            Exercise(
                name: "Kurzhantel Floor Press",
                targetMuscle: .chest,
                secondaryMuscles: [.shoulders, .arms],
                equipment: .dumbBells,
                isBWKRehaSafe: true,
                executionNotes: "Bodendruecken mit Kurzhanteln auf der Matte. Schont Schultern, ideal fuer die Stube.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Kurzhantel Rudern einarmig (Stube)",
                targetMuscle: .back,
                secondaryMuscles: [.arms, .shoulders],
                equipment: .dumbBells,
                isBWKRehaSafe: true,
                executionNotes: "Abgestuetzt auf Bettkante oder Stuhl. Ellenbogen eng am Koerper nach hinten oben fuehren.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Goblet Squat (Kurzhantel)",
                targetMuscle: .legs,
                secondaryMuscles: [.glutesPosterior, .functionalCore],
                equipment: .dumbBells,
                isBWKRehaSafe: true,
                executionNotes: "Hantel vor der Brust halten. Tiefe, kontrollierte Kniebeuge mit geradem Ruecken.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 90
            ),


            // 42. Crosstrainer / Ellipsentrainer
            Exercise(
                name: "Crosstrainer Ausdauer",
                targetMuscle: .cardioConditioning,
                equipment: .crossTrainer,
                isBWKRehaSafe: true,
                executionNotes: "Gelenkschonende Ganzkoerperbewegung mit Armstangen.",
                defaultSets: 1, defaultReps: 20, defaultRestSeconds: 60
            ),

            // 43. Gymnastikball
            Exercise(
                name: "Gymnastikball Glute Bridge",
                targetMuscle: .functionalCore,
                equipment: .swissBall,
                isBWKRehaSafe: true,
                executionNotes: "Fersen auf den Ball legen, Becken anheben. Hervorragend fuer Ischios und Rumpf.",
                defaultSets: 3, defaultReps: 12, defaultRestSeconds: 60
            ),
            Exercise(
                name: "Gymnastikball Wall Squat",
                targetMuscle: .legs,
                equipment: .swissBall,
                isBWKRehaSafe: true,
                executionNotes: "Ball im Lendenwirbelbereich gegen die Wand stuetzen. Kniebeuge mit Rueckensupport.",
                defaultSets: 3, defaultReps: 12, defaultRestSeconds: 60
            ),

            // 44. Medizinbälle (Leder 3-5 kg)
            Exercise(
                name: "Medizinball Brustpass (Wurfwand)",
                targetMuscle: .chest,
                equipment: .medicineBalls,
                isBWKRehaSafe: true,
                executionNotes: "Klassischer 3-5 kg Lederball. Explosiver Stoss aus der Brust gegen die Prallwand.",
                defaultSets: 3, defaultReps: 12, defaultRestSeconds: 60
            ),

            // 45. BOSU-Ball
            Exercise(
                name: "BOSU Einbeinstand (Gleichgewicht)",
                targetMuscle: .functionalCore,
                equipment: .bosuBall,
                isBWKRehaSafe: true,
                executionNotes: "Propriozeption und Fussgelenksstabilitaet auf der halben Ballkuppel.",
                defaultSets: 3, defaultReps: 30, defaultRestSeconds: 60
            ),
            Exercise(
                name: "BOSU Kniebeugen",
                targetMuscle: .legs,
                equipment: .bosuBall,
                isBWKRehaSafe: true,
                executionNotes: "Tiefe Kniebeuge auf der instabilen Plattform.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 60
            ),

            // 46. Stab (für Kampfkunst und Dehnübungen)
            Exercise(
                name: "Stab Schultermobilisation & Dislocates",
                targetMuscle: .shoulders,
                equipment: .mobilityStaff,
                isBWKRehaSafe: true,
                executionNotes: "Holzstab mit weitem Griff ueber den Kopf nach hinten fuehren. Oeffnet die Brust.",
                defaultSets: 2, defaultReps: 15, defaultRestSeconds: 30
            ),
            Exercise(
                name: "Stab Good Mornings (Hingemuster)",
                targetMuscle: .back,
                equipment: .mobilityStaff,
                isBWKRehaSafe: true,
                executionNotes: "Stab an Kopf, Brustwirbelsaeule und Kreuzbein anlegen. Perfekte Wirbelsaeulenhaltung ueben.",
                defaultSets: 3, defaultReps: 12, defaultRestSeconds: 45
            ),

            // 47. Draußen Laufen
            Exercise(
                name: "20 min MVPA Morgenlauf Kaserne",
                targetMuscle: .cardioConditioning,
                equipment: .outdoorRunning,
                isBWKRehaSafe: true,
                executionNotes: "Morgendlicher 20 min MVPA Pflichtblock gemaess Lebensordnungs-Doktrin. Zirkadianer Reset.",
                defaultSets: 1, defaultReps: 20, defaultRestSeconds: 60
            ),
            Exercise(
                name: "Gelaendelauf / Waldlauf Kaserne",
                targetMuscle: .cardioConditioning,
                equipment: .outdoorRunning,
                isBWKRehaSafe: true,
                executionNotes: "Ausdauerlauf im Kasernenumfeld. Ausdaueraufbau fuer Marsch- und Dienstfaehigkeit.",
                defaultSets: 1, defaultReps: 35, defaultRestSeconds: 60
            ),

            // MARK: - Lower Back & LWS-Biomechanik Uebungen
            Exercise(
                name: "Kreuzheben (Langhantel Deadlift)",
                targetMuscle: .lowerBack,
                equipment: .flatBenchBarbell,
                isBWKRehaSafe: true,
                executionNotes: "Fundamentale Leituebung fuer den unteren Ruecken. Huftbreiter Stand, Stange eng am Koerper fuehren, Wirbelsaeule neutral verriegeln.",
                defaultSets: 4, defaultReps: 6, defaultRestSeconds: 120
            ),
            Exercise(
                name: "Rumaenisches Kreuzheben (Langhantel RDL)",
                targetMuscle: .lowerBack,
                equipment: .flatBenchBarbell,
                isBWKRehaSafe: true,
                executionNotes: "Hinge-Pattern: Feste LWS-Spannung, Huefte nach hinten schieben, Knie leicht gebeugt. Volle Dehnung der hinteren Kette.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 90
            ),
            Exercise(
                name: "Good Mornings (Langhantel)",
                targetMuscle: .lowerBack,
                equipment: .squatRack,
                isBWKRehaSafe: true,
                executionNotes: "Gezielte Isolation der Rueckenstrecker. Hantel auf dem oberen Ruecken, Oberkoerper kontrolliert aus der Huefte nach vorn beugen.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 90
            ),
            Exercise(
                name: "Rack Pulls (Langhantel)",
                targetMuscle: .lowerBack,
                equipment: .squatRack,
                isBWKRehaSafe: true,
                executionNotes: "Teilhub-Kreuzheben ab Kniehoehe. Maximale Kraeftigung der Lendenstrecker und des oberen Rueckens bei reduziertem Hebelarm.",
                defaultSets: 3, defaultReps: 8, defaultRestSeconds: 90
            ),
            Exercise(
                name: "Kurzhantel Rumaenisches Kreuzheben (DB RDL)",
                targetMuscle: .lowerBack,
                equipment: .dumbBells,
                isBWKRehaSafe: true,
                executionNotes: "Kurzhantel-Hinge: Natuerlicher Griffverlauf schont die Handgelenke und aktiviert gezielt den unteren Ruecken und Hamstrings.",
                defaultSets: 3, defaultReps: 12, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Kurzhantel Goblet Good Morning",
                targetMuscle: .lowerBack,
                equipment: .dumbBells,
                isBWKRehaSafe: true,
                executionNotes: "Hinge-Uebung mit Gewicht vor der Brust. Perfekt zur Haltungsschulung und axialen LWS-Entlastung.",
                defaultSets: 3, defaultReps: 12, defaultRestSeconds: 60
            ),
            Exercise(
                name: "Kurzhantel Superman (Boden)",
                targetMuscle: .lowerBack,
                equipment: .dumbBells,
                isBWKRehaSafe: true,
                executionNotes: "LWS-Kraeftigung: Flach auf dem Bauch liegend mit leichten Kurzhanteln Arme und Beine kontrolliert anheben.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 60
            ),
            Exercise(
                name: "45-Grad Rueckenstrecken (Hyperextension)",
                targetMuscle: .lowerBack,
                equipment: .hyperextension45,
                isBWKRehaSafe: true,
                executionNotes: "Standardgeraet fuer den unteren Ruecken. Becken frei, kontrolliert heben bis zur neutralen Koerperachse, kein Hohlkreuz.",
                defaultSets: 3, defaultReps: 12, defaultRestSeconds: 60
            ),
            Exercise(
                name: "Kabelzug Pull-Through",
                targetMuscle: .lowerBack,
                equipment: .cableCrossoverTower,
                isBWKRehaSafe: true,
                executionNotes: "Seilzug-Hinge durch die Beine. Gleichmaessige Lastverteilung ohne axiale Wirbelsaeulenkompression.",
                defaultSets: 3, defaultReps: 12, defaultRestSeconds: 60
            ),
            Exercise(
                name: "Supermans (Boden-Rueckenstrecken)",
                targetMuscle: .lowerBack,
                equipment: .matArea,
                isBWKRehaSafe: true,
                executionNotes: "Koerpergewichtsklassiker: Bauchlage, Arme und Beine gleichzeitig 2 bis 3 Sekunden isometrisch anheben.",
                defaultSets: 3, defaultReps: 12, defaultRestSeconds: 45
            ),
            Exercise(
                name: "Skydiver (Bauchlage Streckung)",
                targetMuscle: .lowerBack,
                equipment: .matArea,
                isBWKRehaSafe: true,
                executionNotes: "LWS- und Schulterblattaktivierung in Bauchlage mit 90-Grad angewinkelten Gliedmassen fuer tiefenwirksame Stabilitaet.",
                defaultSets: 3, defaultReps: 12, defaultRestSeconds: 45
            ),
            Exercise(
                name: "Kobra-Haltung (Cobra Stretch - LWS Mobilitaet)",
                targetMuscle: .lowerBack,
                equipment: .matArea,
                isBWKRehaSafe: true,
                executionNotes: "Mobilitaet & Dekompression: Sanfte Streckung der Lendenwirbelsaeule in Bauchlage, Becken bleibt am Boden verankert.",
                defaultSets: 3, defaultReps: 30, defaultRestSeconds: 30
            ),
            Exercise(
                name: "Lendenwirbelsaeulen-Rotation (Lumbar Rotation Stretch)",
                targetMuscle: .lowerBack,
                equipment: .matArea,
                isBWKRehaSafe: true,
                executionNotes: "Rotationsdehnung: Rueckenlage, Knie seitlich ablegen, Schulterkontakt halten zur Mobilisation der Facettengelenke.",
                defaultSets: 3, defaultReps: 30, defaultRestSeconds: 30
            ),
            Exercise(
                name: "Kindeshaltung / Prayer Stretch (LWS Dekompression)",
                targetMuscle: .lowerBack,
                equipment: .matArea,
                isBWKRehaSafe: true,
                executionNotes: "Entlastungsdehnung: Fersensitz mit nach vorn gestreckten Armen zur maximalen axialen LWS-Entlastung.",
                defaultSets: 3, defaultReps: 45, defaultRestSeconds: 30
            ),
            Exercise(
                name: "Katze-Kuh Dehnung (Cat-Cow Mobility)",
                targetMuscle: .lowerBack,
                equipment: .matArea,
                isBWKRehaSafe: true,
                executionNotes: "Wirbelsaeulen-Mobilisation im Vierfuesslerstand. Fliessender Wechsel zwischen LWS-Lordose und segmentaler Rumpfkruemmung.",
                defaultSets: 3, defaultReps: 12, defaultRestSeconds: 30
            ),

            // MARK: - Stuben- & Zimmer-Uebungen (Minimal-Raum, kein Gym)
            Exercise(
                name: "Stuben Liegestuetze am Schreibtisch / Bett",
                targetMuscle: .chest,
                secondaryMuscles: [.arms, .shoulders, .functionalCore],
                equipment: .roomFurniture,
                isBWKRehaSafe: true,
                executionNotes: "Haende auf Schreibtischkante oder stabiles Bett stuetzen. Kontrollierte Exzentrik, kein Hohlkreuz.",
                defaultSets: 3, defaultReps: 12, defaultRestSeconds: 60
            ),
            Exercise(
                name: "Bettkanten Bulgarian Split Squats",
                targetMuscle: .legs,
                secondaryMuscles: [.glutesPosterior, .functionalCore],
                equipment: .roomFurniture,
                isBWKRehaSafe: true,
                executionNotes: "Hinterer Fuss auf der Bettkante oder Stuhl abgelegt. Tief absenken, vorderes Knie stabil halten.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Tuerrahmen Isometrisches Rudern",
                targetMuscle: .back,
                secondaryMuscles: [.arms, .functionalCore],
                equipment: .roomFurniture,
                isBWKRehaSafe: true,
                executionNotes: "Fester Griff an die Tuerzarge. Oberkoerper zuruecklehnen und mit Latissimus und Ruecken heranziehen.",
                defaultSets: 4, defaultReps: 12, defaultRestSeconds: 60
            ),
            Exercise(
                name: "Bettkanten Trizeps-Extension (Schulter-sicher)",
                targetMuscle: .arms,
                secondaryMuscles: [.chest, .functionalCore],
                equipment: .roomFurniture,
                isBWKRehaSafe: true,
                executionNotes: "Schulter-sichere Alternative zu Stuhl-Dips: Haende auf Bettkante, Koerper in Plank. Stirn zur Bettkante absenken (reine Ellbogenbeugung), kraftvoll ueber Trizeps strecken. Keine Schulter-Hyperextension.",
                defaultSets: 4, defaultReps: 12, defaultRestSeconds: 60
            ),
            Exercise(
                name: "Bettkanten Reverse Hyperextensions (LWS & Gesaess)",
                targetMuscle: .lowerBack,
                secondaryMuscles: [.glutesPosterior, .functionalCore],
                equipment: .roomFurniture,
                isBWKRehaSafe: true,
                executionNotes: "Bauchlage quer ueber das Bett, Becken an der Bettkante. Haende greifen Bettrahmen. Beine geschlossen durch Kraft von LWS-Strecker und Gesaess horizontal anheben, 3 Sekunden Peak-Hold, 3 Sekunden kontrolliert absenken. Schont ermuedete Knie und Oberschenkel vollstaendig.",
                defaultSets: 4, defaultReps: 15, defaultRestSeconds: 60
            ),
            Exercise(
                name: "Handtuch-Isometrie Bizepszug",
                targetMuscle: .arms,
                secondaryMuscles: [.back],
                equipment: .roomFurniture,
                isBWKRehaSafe: true,
                executionNotes: "Handtuch unter die Oberschenkel oder Tuergriff spannen und 10 Sekunden mit voller Kraft isometrisch ziehen.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 60
            ),
            Exercise(
                name: "Stuben Pike Push-ups (Schultern)",
                targetMuscle: .shoulders,
                secondaryMuscles: [.arms, .functionalCore],
                equipment: .roomFurniture,
                isBWKRehaSafe: true,
                executionNotes: "Gesaess nach oben geschoben (Dachform). Kopf kontrolliert nach vorn unten absenken zur Ueberkopflast.",
                defaultSets: 3, defaultReps: 8, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Wandsitz Isometrisch (Wall Sit)",
                targetMuscle: .legs,
                secondaryMuscles: [.glutesPosterior],
                equipment: .roomFurniture,
                isBWKRehaSafe: true,
                executionNotes: "90-Grad Knie- und Hueftwinkel an der Stubenwand. Ruecken komplett flach an die Wand pressen.",
                defaultSets: 3, defaultReps: 45, defaultRestSeconds: 60
            ),
            Exercise(
                name: "Teppich Unterarmstuetz (Plank)",
                targetMuscle: .functionalCore,
                secondaryMuscles: [.lowerBack],
                equipment: .roomFurniture,
                isBWKRehaSafe: true,
                executionNotes: "Direkt auf dem Zimmerboden oder Teppich. Rumpf und Gesaess wie ein Brett spannen, ruhig atmen.",
                defaultSets: 3, defaultReps: 45, defaultRestSeconds: 60
            ),

            // MARK: - Reines Calisthenics (Ohne Gewichte, reines Bodyweight)
            Exercise(
                name: "Diamant-Liegestuetze (Calisthenics)",
                targetMuscle: .arms,
                secondaryMuscles: [.chest, .shoulders],
                equipment: .bodyweight,
                isBWKRehaSafe: true,
                executionNotes: "Daumen und Zeigefinger beruehren sich zur Raute. Maximaler Fokus auf Trizeps und sternale Brust.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Breite Liegestuetze (Wide Grip)",
                targetMuscle: .chest,
                secondaryMuscles: [.shoulders, .arms],
                equipment: .bodyweight,
                isBWKRehaSafe: true,
                executionNotes: "Haende deutlich ueber schulterbreit. Tiefe Dehnung der Brustmuskulatur, kontrollierte Ausfuehrung.",
                defaultSets: 3, defaultReps: 12, defaultRestSeconds: 60
            ),
            Exercise(
                name: "Klimmzuege im Obergriff (Pull-ups)",
                targetMuscle: .back,
                secondaryMuscles: [.arms, .shoulders],
                equipment: .pullUpBar,
                isBWKRehaSafe: true,
                executionNotes: "Pronierter weiter Griff. Volle Streckung im Latissimus, Kinn kontrolliert ueber die Stange ziehen.",
                defaultSets: 4, defaultReps: 8, defaultRestSeconds: 90
            ),
            Exercise(
                name: "Klimmzuege im Untergriff (Chin-ups)",
                targetMuscle: .arms,
                secondaryMuscles: [.back],
                equipment: .pullUpBar,
                isBWKRehaSafe: true,
                executionNotes: "Supinierter schulterbreiter Griff. Hoher Bizeps- und unterer Latissimus-Fokus ohne Schwung.",
                defaultSets: 3, defaultReps: 8, defaultRestSeconds: 90
            ),
            Exercise(
                name: "Barren-Dips (Parallel Bars)",
                targetMuscle: .arms,
                secondaryMuscles: [.chest, .shoulders],
                equipment: .dipStation,
                isBWKRehaSafe: true,
                executionNotes: "Aufrechter Koerper fuer Trizeps, leichte Vorneigung fuer Brust. Schultern nicht unter Ellenbogenhoehe ueberdehnen.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 90
            ),
            Exercise(
                name: "Pistol Squat Progression (Einbeinkniebeuge)",
                targetMuscle: .legs,
                secondaryMuscles: [.glutesPosterior, .functionalCore],
                equipment: .bodyweight,
                isBWKRehaSafe: true,
                executionNotes: "Einbeinig absenken, freies Bein nach vorn gestreckt. Alternativ auf Stuhlbox oder mit leichter Handfuehrung.",
                defaultSets: 3, defaultReps: 6, defaultRestSeconds: 90
            ),
            Exercise(
                name: "Air Squats mit Tempokontrolle (3-1-1-0)",
                targetMuscle: .legs,
                secondaryMuscles: [.glutesPosterior],
                equipment: .bodyweight,
                isBWKRehaSafe: true,
                executionNotes: "3 Sekunden exzentrisch absenken, 1 Sekunde im tiefsten Punkt pausieren, dynamisch aufstehen.",
                defaultSets: 4, defaultReps: 15, defaultRestSeconds: 60
            ),
            Exercise(
                name: "Walking Lunges (Dynamische Ausfallschritte)",
                targetMuscle: .legs,
                secondaryMuscles: [.glutesPosterior],
                equipment: .bodyweight,
                isBWKRehaSafe: true,
                executionNotes: "Schrittfolge durch den Raum. Oberkoerper lotrecht, Knie beruehrt sanft fast den Boden.",
                defaultSets: 3, defaultReps: 16, defaultRestSeconds: 60
            ),
            Exercise(
                name: "Hollow Body Hold (Statisch, BWK-sicher)",
                targetMuscle: .functionalCore,
                secondaryMuscles: [.lowerBack],
                equipment: .bodyweight,
                isBWKRehaSafe: true,
                executionNotes: "Rueckenlage, Lendenwirbelsaeule aktiv in den Boden pressen. Beine und Arme leicht anheben, keine Beugung.",
                defaultSets: 3, defaultReps: 30, defaultRestSeconds: 45
            ),
            Exercise(
                name: "L-Sit Progression (Boden / Parallettes)",
                targetMuscle: .functionalCore,
                secondaryMuscles: [.arms, .shoulders],
                equipment: .bodyweight,
                isBWKRehaSafe: true,
                executionNotes: "Haende neben der Huefte in den Boden stemmen, Gesaess anheben. Zunaechst mit angewinkelten Knien (Tuck L-Sit).",
                defaultSets: 3, defaultReps: 15, defaultRestSeconds: 60
            ),
            Exercise(
                name: "Glute Bridge einbeinig (Single Leg Bridge)",
                targetMuscle: .glutesPosterior,
                secondaryMuscles: [.lowerBack, .functionalCore],
                equipment: .bodyweight,
                isBWKRehaSafe: true,
                executionNotes: "Ein Bein gestreckt, ueber die Ferse des Standbeins das Becken bis zur Neutralen heben. 2s Halten.",
                defaultSets: 3, defaultReps: 12, defaultRestSeconds: 45
            ),

            // MARK: - Dehnungs-, Mobility- & Rest-Day-Uebungen (Flexibilitaet & Regeneration)
            Exercise(
                name: "World's Greatest Stretch (Huefte & BWS)",
                targetMuscle: .mobilityFlexibility,
                secondaryMuscles: [.legs, .glutesPosterior, .back],
                equipment: .stretchingMat,
                isBWKRehaSafe: true,
                executionNotes: "Ausfallschritt mit Ellenbogen zur Fussaussenseite und weitem Aufdrehen des Brustkorbs zur Decke.",
                defaultSets: 3, defaultReps: 6, defaultRestSeconds: 30
            ),
            Exercise(
                name: "Kniende Psoas- & Hueftbeugerdehnung",
                targetMuscle: .mobilityFlexibility,
                secondaryMuscles: [.glutesPosterior, .lowerBack],
                equipment: .stretchingMat,
                isBWKRehaSafe: true,
                executionNotes: "Halbknieend, Gesaess anspannen und Becken nach vorn kippen. Oeffnet verkuerzte Hueftbeuger vom Sitzen.",
                defaultSets: 3, defaultReps: 45, defaultRestSeconds: 30
            ),
            Exercise(
                name: "Liegende Beinbeugerdehnung mit Handtuch",
                targetMuscle: .mobilityFlexibility,
                secondaryMuscles: [.glutesPosterior, .lowerBack],
                equipment: .stretchingMat,
                isBWKRehaSafe: true,
                executionNotes: "Handtuch um den Fussballen schlingen. Knie gestreckt sanft zur Brust fuehren ohne LWS-Kruemmung.",
                defaultSets: 3, defaultReps: 45, defaultRestSeconds: 30
            ),
            Exercise(
                name: "Tauben-Haltung (Pigeon Pose / Piriformis)",
                targetMuscle: .mobilityFlexibility,
                secondaryMuscles: [.glutesPosterior],
                equipment: .stretchingMat,
                isBWKRehaSafe: true,
                executionNotes: "Vorderes Bein angewinkelt am Boden ablegen, hinteres Bein strecken. Sanfter Zug im Gesaessmuskel.",
                defaultSets: 3, defaultReps: 45, defaultRestSeconds: 30
            ),
            Exercise(
                name: "90/90 Hueftrotations-Mobilisation",
                targetMuscle: .mobilityFlexibility,
                secondaryMuscles: [.glutesPosterior, .legs],
                equipment: .stretchingMat,
                isBWKRehaSafe: true,
                executionNotes: "Im Sitzen beide Beine in 90-Grad-Winkeln positionieren. Wechsel der Innen- und Aussenrotation.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 30
            ),
            Exercise(
                name: "Schulter- & Brustoeffner an der Wand",
                targetMuscle: .mobilityFlexibility,
                secondaryMuscles: [.chest, .shoulders],
                equipment: .stretchingMat,
                isBWKRehaSafe: true,
                executionNotes: "Unterarm im 90-Grad-Winkel an die Wand legen und den Oberkoerper sanft wegdrehen. Oeffnet den Pectoralis Minor.",
                defaultSets: 3, defaultReps: 45, defaultRestSeconds: 30
            ),
            Exercise(
                name: "Thorakale Rotation im Vierfuessler (Open Book)",
                targetMuscle: .mobilityFlexibility,
                secondaryMuscles: [.back, .shoulders],
                equipment: .stretchingMat,
                isBWKRehaSafe: true,
                executionNotes: "Hand an den Hinterkopf. Ellenbogen fuehrt die Drehung der Brustwirbelsaeule maximal nach oben.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 30
            ),
            Exercise(
                name: "McGill Big 3 Entlastungs-Sequenz",
                targetMuscle: .mobilityFlexibility,
                secondaryMuscles: [.functionalCore, .lowerBack],
                equipment: .stretchingMat,
                isBWKRehaSafe: true,
                executionNotes: "Goldstandard fuer Wirbelsaeulenstabilitaet und Entlastung: Bird-Dog, modifizierter Curl-Up (statischer Halt) und Side-Bridge.",
                defaultSets: 3, defaultReps: 30, defaultRestSeconds: 45
            ),
            Exercise(
                name: "Australische Ruderzuege (Inverted Rows)",
                targetMuscle: .back,
                equipment: .bodyweight,
                isBWKRehaSafe: true,
                executionNotes: "Brust zur Stange ziehen, Schulterblaetter hinten aktiv zusammenpressen.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Scapular Pull-Ups (Stangenzug ohne Armbeugung)",
                targetMuscle: .back,
                equipment: .pullUpBar,
                isBWKRehaSafe: true,
                executionNotes: "Arme gestreckt halten. Nur Schulterblaetter nach unten und hinten ziehen.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Passive Bar Hang (Ausklingen mit Bauchspannung)",
                targetMuscle: .back,
                equipment: .pullUpBar,
                isBWKRehaSafe: true,
                executionNotes: "Dekompression der BWS/LWS bei gleichzeitig aktivem Beckenboden.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Serratus Wall-Slides mit Miniband",
                targetMuscle: .shoulders,
                equipment: .bodyweight,
                isBWKRehaSafe: true,
                executionNotes: "Unterarme an der Wand hochgleiten lassen, Schulterblaetter proaktiv nach vorne schieben.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Push-Up Plus (Liegestuetz mit Scapular-Protraktion)",
                targetMuscle: .chest,
                equipment: .bodyweight,
                isBWKRehaSafe: true,
                executionNotes: "Oben angekommen den oberen Ruecken aktiv rund machen und rausdruecken.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Plank to Downward Dog Progression",
                targetMuscle: .functionalCore,
                equipment: .bodyweight,
                isBWKRehaSafe: true,
                executionNotes: "Fliessender Uebergang zur Dehnung der Rueckseite und Aktivierung der Skapula.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Prone Y-T-W-L Sequenz (Bauchlage Matte)",
                targetMuscle: .mobilityFlexibility,
                equipment: .stretchingMat,
                isBWKRehaSafe: true,
                executionNotes: "Daumen nach oben zur Decke. Bewegung kommt rein aus den Schulterblaettern.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Tuerrahmen-Ruderzuege einarmig (Kasernen-Setup)",
                targetMuscle: .back,
                equipment: .roomFurniture,
                isBWKRehaSafe: true,
                executionNotes: "Schulterblatt der arbeitenden Seite maximal nach hinten fuehren.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Bird-Dog mit 3s Scapular-Squeeze",
                targetMuscle: .functionalCore,
                equipment: .bodyweight,
                isBWKRehaSafe: true,
                executionNotes: "Keine Beckenkippung. Diagonalen Arm und Bein strecken, Ruecken neutral.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Turnring-Facepulls mit Daumen nach hinten",
                targetMuscle: .shoulders,
                equipment: .gymRings,
                isBWKRehaSafe: true,
                executionNotes: "Ringe zur Stirn fuehren und Haende nach hinten aufdrehen.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Band-Aussenrotation im 90-Grad-Winkel",
                targetMuscle: .mobilityFlexibility,
                equipment: .bodyweight,
                isBWKRehaSafe: true,
                executionNotes: "Ellenbogen am Koerper fixieren, saubere Rotatorenbelastung.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Doorway Chest Stretch (Sanfte Pectoralis-Dehnung)",
                targetMuscle: .chest,
                equipment: .stretchingMat,
                isBWKRehaSafe: true,
                executionNotes: "Oeffnet die Brustmuskulatur, um Vorwaertszug der Schultern zu beseitigen.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Scapular Dips am Barren (Nur Schulterabsenkung)",
                targetMuscle: .shoulders,
                equipment: .dipStation,
                isBWKRehaSafe: true,
                executionNotes: "Arme gestreckt halten, Koerper aus den Schultern hochdruecken.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Banded Pull-Aparts auf Brusthoehe",
                targetMuscle: .chest,
                equipment: .bodyweight,
                isBWKRehaSafe: true,
                executionNotes: "Band zur Brust ziehen, Schulterblaetter hinten maximal beruehren.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Active Hang mit Schulterretraktion",
                targetMuscle: .back,
                equipment: .bodyweight,
                isBWKRehaSafe: true,
                executionNotes: "Aktiv die Schultern von den Ohren wegziehen.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "McGill Modifizierter Curl-Up (Haende unter LWS)",
                targetMuscle: .functionalCore,
                equipment: .bodyweight,
                isBWKRehaSafe: true,
                executionNotes: "Reha-Goldstandard nach Prof. Stuart McGill: Haende unter die LWS zur Erhaltung der natuerlichen Lordose. Ein Bein gebeugt, ein Bein gestreckt. Nur Kopf und Brustguertel minimal anheben (10s isometrischer Halt pro Satz/Wiederholung).",
                defaultSets: 4, defaultReps: 10, defaultRestSeconds: 60,
                youtubeVideoId: "I_drRVYlHbc",
                isExplicitlyTimeBased: true
            ),
            Exercise(
                name: "McGill Bird-Dog mit neutralem Becken",
                targetMuscle: .functionalCore,
                equipment: .bodyweight,
                isBWKRehaSafe: true,
                executionNotes: "Bauch aktiv einziehen, kein Durchhaengen im Lendenbereich.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "McGill Side Plank (Knie oder Fuesse)",
                targetMuscle: .functionalCore,
                equipment: .bodyweight,
                isBWKRehaSafe: true,
                executionNotes: "Kopplung von Gluteus Medius und Quadratus Lumborum.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Seitliches Beinheben (Side-Lying Hip Abduction)",
                targetMuscle: .glutesPosterior,
                equipment: .bodyweight,
                isBWKRehaSafe: true,
                executionNotes: "Ferse leicht nach oben und hinten drehen, um isoliert Gluteus Medius zu treffen.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Clamshells mit Miniband",
                targetMuscle: .glutesPosterior,
                equipment: .bodyweight,
                isBWKRehaSafe: true,
                executionNotes: "Becken bleibt exakt senkrecht, kein Nach-Hinten-Kippen.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Sitzendes Piriformis-Flossing (Sanfte Mobilisation)",
                targetMuscle: .glutesPosterior,
                equipment: .bodyweight,
                isBWKRehaSafe: true,
                executionNotes: "Ischiasnerv sanft gleiten lassen, schmerzfreier Bereich.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Einbeinige Glute Bridge mit 3s Peak Hold",
                targetMuscle: .glutesPosterior,
                equipment: .bodyweight,
                isBWKRehaSafe: true,
                executionNotes: "Vollstaendige Hueftstreckung aus dem Gesaessmuskel, nicht aus der LWS.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Deadbug mit Rueckendruck gegen Boden",
                targetMuscle: .functionalCore,
                equipment: .bodyweight,
                isBWKRehaSafe: true,
                executionNotes: "Bauchnabel fest nach innen saugen, LWS hat stetigen Bodenkontakt.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Frosch-Gesaessbruecke (Froggers)",
                targetMuscle: .glutesPosterior,
                equipment: .bodyweight,
                isBWKRehaSafe: true,
                executionNotes: "Fusssohlen zusammen, maximale externe Gesaesskontraktion.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Koffer-Tragen auf Stube (Suitcase Carry mit Rucksack)",
                targetMuscle: .mobilityFlexibility,
                equipment: .roomFurniture,
                isBWKRehaSafe: true,
                executionNotes: "Oberkoerper absolut aufrecht, keine seitliche Ausweichbewegung.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Copenhagen Plank (Knie auf Stuhl/Bett)",
                targetMuscle: .functionalCore,
                equipment: .roomFurniture,
                isBWKRehaSafe: true,
                executionNotes: "Aktiviert Adduktoren und schliesst das Becken seitlich ab.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Sanfter QL-Dehnungs-Reach in Rueckenlage",
                targetMuscle: .mobilityFlexibility,
                equipment: .stretchingMat,
                isBWKRehaSafe: true,
                executionNotes: "Laenge in der Flanke zwischen Rippen und Beckenkamm erzeugen.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Pallof-Press mit Widerstandsband am Tueranker",
                targetMuscle: .functionalCore,
                equipment: .roomFurniture,
                isBWKRehaSafe: true,
                executionNotes: "Anti-Rotation. Becken und Schultern parallel zur Wand halten.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Beckenboden-Aktivierung im Vierfueszler",
                targetMuscle: .functionalCore,
                equipment: .flatBenchBarbell,
                isBWKRehaSafe: true,
                executionNotes: "Sanftes Anheben bei Ausatmung gemaess BWK-Ulm Standard.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Child's Pose mit tiefer Flankenatmung",
                targetMuscle: .mobilityFlexibility,
                equipment: .stretchingMat,
                isBWKRehaSafe: true,
                executionNotes: "Entspannt die Rueckenstrecker und oeffnet das ISG.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Barren-Dips (Paralleles Dip-Geraet)",
                targetMuscle: .arms,
                equipment: .dipStation,
                isBWKRehaSafe: true,
                executionNotes: "Leicht nach vorne beugen fuer Brustfokus, volle Tiefe.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Pike Push-Ups mit erhoehten Fuessen",
                targetMuscle: .chest,
                equipment: .bodyweight,
                isBWKRehaSafe: true,
                executionNotes: "V-Position, Kopf vor den Haenden absenken.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Diamant-Liegestuetz auf Knien oder Zehen",
                targetMuscle: .chest,
                equipment: .bodyweight,
                isBWKRehaSafe: true,
                executionNotes: "Fokus auf Trizepskontraktion.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Klimmzuege im Obergriff (Proniert)",
                targetMuscle: .back,
                equipment: .bodyweight,
                isBWKRehaSafe: true,
                executionNotes: "Aus dem Dead-Hang starten, Kinn ueber die Stange.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Negative Klimmzuege (5s Absenken)",
                targetMuscle: .back,
                equipment: .bodyweight,
                isBWKRehaSafe: true,
                executionNotes: "Oben anspringen und ultra-langsam exzentrisch ablassen.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Klimmzug-Halten im 90-Grad-Winkel",
                targetMuscle: .back,
                equipment: .pullUpBar,
                isBWKRehaSafe: true,
                executionNotes: "Isometrische Bizeps- und Lat-Spannung.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Sissy Squats mit Festhalten",
                targetMuscle: .legs,
                equipment: .bodyweight,
                isBWKRehaSafe: true,
                executionNotes: "Knie weit nach vorne schieben, Huefte gestreckt halten (Quad-Fokus).",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Einbeinige Wadenheben an Stufe",
                targetMuscle: .legs,
                equipment: .roomFurniture,
                isBWKRehaSafe: true,
                executionNotes: "2s Dehnung unten, 1s Peak Contraction oben.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Wall Sit mit geradem Ruecken",
                targetMuscle: .mobilityFlexibility,
                equipment: .bodyweight,
                isBWKRehaSafe: true,
                executionNotes: "90 Grad im Kniegelenk, Ruecken an die Wand gepresst.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Liegestuetz an Turnringen",
                targetMuscle: .chest,
                equipment: .gymRings,
                isBWKRehaSafe: true,
                executionNotes: "Ringe oben leicht nach aussen aufdrehen.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Hollow Body Hold (Schiffchen mit gebeugten Knien)",
                targetMuscle: .functionalCore,
                equipment: .bodyweight,
                isBWKRehaSafe: true,
                executionNotes: "LWS flach in den Boden druecken, Bauch brennt.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Ring Dips Support Hold",
                targetMuscle: .arms,
                equipment: .gymRings,
                isBWKRehaSafe: true,
                executionNotes: "Ringe am Koerper halten, Schultern stabilisieren.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Archer Rows an Stange oder Ringen",
                targetMuscle: .back,
                equipment: .gymRings,
                isBWKRehaSafe: true,
                executionNotes: "Ein Arm zieht gebeugt, der andere bleibt fast gestreckt.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Tuck L-Sit auf Parallettes oder Stuehlen",
                targetMuscle: .mobilityFlexibility,
                equipment: .bodyweight,
                isBWKRehaSafe: true,
                executionNotes: "Knie an die Brust ziehen, Schultern nach unten druecken.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Ausfallschritte im Rueckwaertsgang",
                targetMuscle: .legs,
                equipment: .bodyweight,
                isBWKRehaSafe: true,
                executionNotes: "Schont die Knie und aktiviert den Gluteus.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Standard-Liegestuetz (Tempo 2-0-1)",
                targetMuscle: .chest,
                equipment: .bodyweight,
                isBWKRehaSafe: true,
                executionNotes: "Vollstaendige Streckung, Brust beruehrt fast den Boden.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Kniebeugen mit 2s Pause unten (Air Squats)",
                targetMuscle: .legs,
                equipment: .bodyweight,
                isBWKRehaSafe: true,
                executionNotes: "Fersen am Boden, Knie folgen den Zehen.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Plank im Liegestuetz-Stellungswechsel",
                targetMuscle: .functionalCore,
                equipment: .bodyweight,
                isBWKRehaSafe: true,
                executionNotes: "Becken bleibt absolut waagerecht.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Handtuch-Hangs (Handtuch ueber Stange geworfen)",
                targetMuscle: .back,
                equipment: .pullUpBar,
                isBWKRehaSafe: true,
                executionNotes: "Extreme Schulung der Unterarmflexoren.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Doorframe Rows (Tuerrahmen-Rudern)",
                targetMuscle: .back,
                equipment: .roomFurniture,
                isBWKRehaSafe: true,
                executionNotes: "Fuehrt den Ellbogen eng am Rumpf vorbei.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Bulgarische Split Squats mit Stuhl",
                targetMuscle: .legs,
                equipment: .roomFurniture,
                isBWKRehaSafe: true,
                executionNotes: "Hinterer Fuss auf Stuhl, Vorderfuss stabil.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Einbeiniges Standwaage-Halten",
                targetMuscle: .legs,
                equipment: .bodyweight,
                isBWKRehaSafe: true,
                executionNotes: "Staerkt Fussgewoelbe und Gluteus Medius.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Wadenheben beidbeinig mit Gewichtsweste/Rucksack",
                targetMuscle: .legs,
                equipment: .bodyweight,
                isBWKRehaSafe: true,
                executionNotes: "Praevention von Schienbeinkantensyndrom (Shin Splints).",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Pike Push-Ups am Bettkasten",
                targetMuscle: .chest,
                equipment: .roomFurniture,
                isBWKRehaSafe: true,
                executionNotes: "Saubere Schulterbelastung.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Banded Face-Pulls an Schrankgriff verankert",
                targetMuscle: .shoulders,
                equipment: .bodyweight,
                isBWKRehaSafe: true,
                executionNotes: "Daumen zeigen am Ende nach hinten.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Prone Cobra (Bauchlage Schulterblatt-Retraktion)",
                targetMuscle: .back,
                equipment: .bodyweight,
                isBWKRehaSafe: true,
                executionNotes: "Arme neben Koerper, Handflaechen nach aussen gedreht.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Rucksack-Suitcase Carry auf Stube",
                targetMuscle: .mobilityFlexibility,
                equipment: .roomFurniture,
                isBWKRehaSafe: true,
                executionNotes: "Gefaelltes Gewicht im Rucksack einseitig tragen.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Unterarmstuetz (Plank) mit Vor- und Zurueckwippen",
                targetMuscle: .functionalCore,
                equipment: .bodyweight,
                isBWKRehaSafe: true,
                executionNotes: "Bauch und Gesaess maximal angespannt.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Hueftbeuger-Dehnung im Halbknien",
                targetMuscle: .mobilityFlexibility,
                equipment: .stretchingMat,
                isBWKRehaSafe: true,
                executionNotes: "Gesaess anspannen, um den Psoas aufzudehnen.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Sitzende Piriformis-Dehnung auf Stuhl",
                targetMuscle: .glutesPosterior,
                equipment: .roomFurniture,
                isBWKRehaSafe: true,
                executionNotes: "Knoechel auf Knie legen, gerader Oberkoerper nach vorne neigen.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Liegende 90/90 Hueft-Rotation",
                targetMuscle: .mobilityFlexibility,
                equipment: .bodyweight,
                isBWKRehaSafe: true,
                executionNotes: "Knie kontrolliert von Seite zu Seite kippen.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Beckenkippen in Rueckenlage (Pelvic Tilts)",
                targetMuscle: .functionalCore,
                equipment: .bodyweight,
                isBWKRehaSafe: true,
                executionNotes: "Sanftes Vor- und Zurueckrollen des Beckens.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Open-Book Mobilisation in Seitenlage",
                targetMuscle: .mobilityFlexibility,
                equipment: .bodyweight,
                isBWKRehaSafe: true,
                executionNotes: "Oberen Arm weit nach hinten aufdrehen, Blick folgt der Hand.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Latissimus-Dehnung an Tuerrahmen",
                targetMuscle: .back,
                equipment: .roomFurniture,
                isBWKRehaSafe: true,
                executionNotes: "Tuerrahmen greifen, Huefte nach hinten schieben, Flanke oeffnen.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Katze-Kuh im Vierfueszler (Sanft)",
                targetMuscle: .mobilityFlexibility,
                equipment: .flatBenchBarbell,
                isBWKRehaSafe: true,
                executionNotes: "Wirbel fuer Wirbel bewegen, keine Extreme.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Couch Stretch (Knie an die Wand/Bett)",
                targetMuscle: .mobilityFlexibility,
                equipment: .roomFurniture,
                isBWKRehaSafe: true,
                executionNotes: "Bauch anspannen, aufrechte Huefte.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Hamstring-Mobilisation mit Band in Rueckenlage",
                targetMuscle: .mobilityFlexibility,
                equipment: .gymRings,
                isBWKRehaSafe: true,
                executionNotes: "Knie leicht gebeugt, Faszienzug spueren.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Waden-Dehnung an Wand",
                targetMuscle: .legs,
                equipment: .roomFurniture,
                isBWKRehaSafe: true,
                executionNotes: "Ferse bleibt fest am Boden.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Trapezius-Dehnung mit Hand hinter Ruecken",
                targetMuscle: .mobilityFlexibility,
                equipment: .stretchingMat,
                isBWKRehaSafe: true,
                executionNotes: "Kopf sanft zur Gegenseite neigen.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Levator Scapulae Stretch (Blick zur Achselhoehle)",
                targetMuscle: .shoulders,
                equipment: .stretchingMat,
                isBWKRehaSafe: true,
                executionNotes: "Schulter aktiv tief halten.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Brustkorb-Dehnung ueber Schaumstoffrolle oder Kissen",
                targetMuscle: .chest,
                equipment: .stretchingMat,
                isBWKRehaSafe: true,
                executionNotes: "Tiefe Zwerchfellatmung im Liegen.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Tiefe Hocke mit Festhalten (Deep Squat Rest)",
                targetMuscle: .legs,
                equipment: .bodyweight,
                isBWKRehaSafe: true,
                executionNotes: "Fersen flach, Brust aufgerichtet, entspannte Beckenbodenatmung.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Beine hoch an die Wand (Viparita Karani)",
                targetMuscle: .legs,
                equipment: .roomFurniture,
                isBWKRehaSafe: true,
                executionNotes: "Fasst venoes Rueckfluss und aktiviert den Parasympathikus.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Schraegbankdruecken Kurzhanteln (30 Grad)",
                targetMuscle: .chest,
                equipment: .dumbBells,
                isBWKRehaSafe: true,
                executionNotes: "Volle Dehnung unten, kein Zusammenschlagen der Hanteln.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Kabelzug-Seitheben (Hinter dem Ruecken)",
                targetMuscle: .shoulders,
                equipment: .cableCrossoverTower,
                isBWKRehaSafe: true,
                executionNotes: "Konstanter Zug auf den mittleren Delt, Handgelenk neutral.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Kabel-Flys zur oberen Brust (Tiefer Zug)",
                targetMuscle: .chest,
                equipment: .cableCrossoverTower,
                isBWKRehaSafe: true,
                executionNotes: "Haende auf Schluesselbeinhoehe zusammenfuehren.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Trizepsdruecken am Tau (Ueberkopf)",
                targetMuscle: .arms,
                equipment: .cableCrossoverTower,
                isBWKRehaSafe: true,
                executionNotes: "Langer Kopf des Trizeps fuer Armbreite.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Brustgestuetztes T-Bar Rudern",
                targetMuscle: .back,
                equipment: .flatBenchBarbell,
                isBWKRehaSafe: true,
                executionNotes: "Schont die LWS komplett, maximaler Fokus auf Schulterblaetter.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Latzug im breiten Parallelgriff",
                targetMuscle: .back,
                equipment: .cableCrossoverTower,
                isBWKRehaSafe: true,
                executionNotes: "Zur oberen Brust ziehen, Schulterblaetter aktiv nach unten fuehren.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Face Pulls mit Aussenrotation",
                targetMuscle: .shoulders,
                equipment: .bodyweight,
                isBWKRehaSafe: true,
                executionNotes: "Hintere Schulter und Infraspinatus gegen Haltungsdefizit.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Incline Dumbbell Biceps Curls",
                targetMuscle: .arms,
                equipment: .dumbBells,
                isBWKRehaSafe: true,
                executionNotes: "Volle Dehnung fuer den langen Bizepskopf (Peak).",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Beinpresse 45 Grad (Schulterbreiter Stand)",
                targetMuscle: .legs,
                equipment: .legPressMachine,
                isBWKRehaSafe: true,
                executionNotes: "Kein Rundwerden des unteren Rueckens in der tiefsten Position.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Sitzende Beinbeuger (Hamstring-Isolation)",
                targetMuscle: .legs,
                equipment: .legPressMachine,
                isBWKRehaSafe: true,
                executionNotes: "2s Pause am Punkt maximaler Kontraktion.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Stehendes Wadenheben (Schwere Last)",
                targetMuscle: .legs,
                equipment: .bodyweight,
                isBWKRehaSafe: true,
                executionNotes: "3s Dehnung unten, 1s Halten oben (Grecian Ideal Wadenumfang).",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Beinstrecker an Maschine",
                targetMuscle: .legs,
                equipment: .legPressMachine,
                isBWKRehaSafe: true,
                executionNotes: "Vastus Medialis und Quad-Definition.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Kurzhantel-Schulterdruecken sitzend",
                targetMuscle: .shoulders,
                equipment: .dumbBells,
                isBWKRehaSafe: true,
                executionNotes: "Leicht schraege Bank (75 Grad) schont die Schultergelenke.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Lu Raises mit leichten Hanteln",
                targetMuscle: .shoulders,
                equipment: .bodyweight,
                isBWKRehaSafe: true,
                executionNotes: "Ueberkopf-Seitheben fuer gesamte Schulterkappe und Serratus.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Dips mit Koerpergewicht (Kontrolliert)",
                targetMuscle: .arms,
                equipment: .dipStation,
                isBWKRehaSafe: true,
                executionNotes: "Saubere untere Brust- und Trizepskontur.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Kabel-Trizepsdruecken einarmig",
                targetMuscle: .arms,
                equipment: .cableCrossoverTower,
                isBWKRehaSafe: true,
                executionNotes: "Isolierte Auspraegung des lateralen Trizepskopfes.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Rumaenisches Kreuzheben Kurzhanteln",
                targetMuscle: .mobilityFlexibility,
                equipment: .dumbBells,
                isBWKRehaSafe: true,
                executionNotes: "Nur Hueftbeugung, Schienbeine vertikal, Ruecken neutral.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Brustgestuetztes Rudern im Obergriff (Rear Delt)",
                targetMuscle: .back,
                equipment: .bodyweight,
                isBWKRehaSafe: true,
                executionNotes: "Ellenbogen 45-60 Grad abspreizen fuer oberen Ruecken.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Pallof-Press am Kabelzug",
                targetMuscle: .functionalCore,
                equipment: .cableCrossoverTower,
                isBWKRehaSafe: true,
                executionNotes: "Haelt die Taille schmal, null Taillenverbreiterung.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Schraege Bank Hammer Curls",
                targetMuscle: .arms,
                equipment: .bodyweight,
                isBWKRehaSafe: true,
                executionNotes: "Brachialis-Entwicklung fuer messbar dickere Oberarme.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Kelso Shrugs auf Schraegbank (Kurzhanteln)",
                targetMuscle: .back,
                equipment: .dumbBells,
                isBWKRehaSafe: true,
                executionNotes: "Arme haengen gestreckt. Nur die Schulterblaetter 2s zusammenpressen.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Seal Rows (Kurzhanteln auf Flachbank erhoeht)",
                targetMuscle: .back,
                equipment: .dumbBells,
                isBWKRehaSafe: true,
                executionNotes: "Ruecken voellig lastfrei, volle Kontraktion im Rhomboid.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Reverse Pec Deck (Hintere Schulter)",
                targetMuscle: .chest,
                equipment: .bodyweight,
                isBWKRehaSafe: true,
                executionNotes: "Daumen nach innen, Bewegung rein aus hinterem Delt.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Sitzendes Kabelrudern breiter Griff zum Sternum",
                targetMuscle: .back,
                equipment: .cableCrossoverTower,
                isBWKRehaSafe: true,
                executionNotes: "Schulterblaetter zuerst zurueckziehen, dann die Ellenbogen beugen.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Kabel-Facepulls mit Seil hoch zur Stirn",
                targetMuscle: .shoulders,
                equipment: .cableCrossoverTower,
                isBWKRehaSafe: true,
                executionNotes: "Aussenrotation am Ende der Bewegung halten.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Banded Y-Raises im Stehen",
                targetMuscle: .shoulders,
                equipment: .bodyweight,
                isBWKRehaSafe: true,
                executionNotes: "Untere Trapeziusaktivierung.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Einarmiges Kurzhantelrudern auf Bank gestuetzt",
                targetMuscle: .back,
                equipment: .dumbBells,
                isBWKRehaSafe: true,
                executionNotes: "Unten Schulterblatt nach vorne gleiten lassen, oben voll retrahieren.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Straight-Arm Pulldown am Kabelzug",
                targetMuscle: .mobilityFlexibility,
                equipment: .cableCrossoverTower,
                isBWKRehaSafe: true,
                executionNotes: "Isoliert den Latissimus ohne Ellenbogenbeugung.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Farmer's Walk mit schweren Kurzhanteln",
                targetMuscle: .mobilityFlexibility,
                equipment: .dumbBells,
                isBWKRehaSafe: true,
                executionNotes: "Schultern zurueckgezogen, stolze Brust.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Latzug im schulterbreiten Untergriff (Supiniert)",
                targetMuscle: .back,
                equipment: .cableCrossoverTower,
                isBWKRehaSafe: true,
                executionNotes: "Starke Vordehnung oben, Zug fuehrt zum Schluesselbein.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Batwing Rows auf Schraegbank (3s Hold oben)",
                targetMuscle: .back,
                equipment: .bodyweight,
                isBWKRehaSafe: true,
                executionNotes: "Schulterblaetter oben 3 Sekunden eisern zusammenbeissen.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Incline Hammer Curls",
                targetMuscle: .arms,
                equipment: .bodyweight,
                isBWKRehaSafe: true,
                executionNotes: "Unterstuetzt Rueckenzugkraft.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Langhantel-Shrugs (Leicht vorgebeugt)",
                targetMuscle: .back,
                equipment: .flatBenchBarbell,
                isBWKRehaSafe: true,
                executionNotes: "Leicht nach vorne neigen trifft den mittleren Trapezius besser.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Banded Pull-Aparts im Supinationsgriff",
                targetMuscle: .mobilityFlexibility,
                equipment: .bodyweight,
                isBWKRehaSafe: true,
                executionNotes: "Handflaechen zur Decke, Zug zur Brust.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Toter Kaefer (Deadbug) mit Miniband",
                targetMuscle: .functionalCore,
                equipment: .bodyweight,
                isBWKRehaSafe: true,
                executionNotes: "Rumpf-Ausgleich nach schwerer Zugbelastung.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Bulgarische Split Squats (Kurzhanteln seitlich)",
                targetMuscle: .legs,
                equipment: .dumbBells,
                isBWKRehaSafe: true,
                executionNotes: "Oberkoerper aufrecht halten, schont die Lendenwirbel komplett.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Kabelzug-Hueftabduktion im Stehen",
                targetMuscle: .glutesPosterior,
                equipment: .cableCrossoverTower,
                isBWKRehaSafe: true,
                executionNotes: "Direkte Staerkung des Gluteus Medius gegen Flankenschmerzen.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Beinstrecker an der Maschine (2s Hold)",
                targetMuscle: .legs,
                equipment: .legPressMachine,
                isBWKRehaSafe: true,
                executionNotes: "Schmerzfreie Quad-Hypertrophie.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Hip Thrusts / Glute Bridges mit Kurzhantel",
                targetMuscle: .glutesPosterior,
                equipment: .dumbBells,
                isBWKRehaSafe: true,
                executionNotes: "Kinn auf die Brust geheftet, LWS bleibt vollkommen neutral.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Abduktoren-Maschine sitzend (Leicht vorgebeugt)",
                targetMuscle: .glutesPosterior,
                equipment: .shoulderPressMachine,
                isBWKRehaSafe: true,
                executionNotes: "Brennt den oberen Gesaessbereich sauber aus.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Einbeiniges Beckenheben am Boden",
                targetMuscle: .functionalCore,
                equipment: .bodyweight,
                isBWKRehaSafe: true,
                executionNotes: "Gleicht Kraftunterschiede zwischen links und rechts aus.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "45-Grad Hyperextensions (Runder oberer Ruecken)",
                targetMuscle: .glutesPosterior,
                equipment: .bodyweight,
                isBWKRehaSafe: true,
                executionNotes: "Oberen Ruecken absichtlich rund halten; Streckung kommt rein aus Huefte/Gluteus.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Liegende Beinbeuger-Maschine",
                targetMuscle: .legs,
                equipment: .legPressMachine,
                isBWKRehaSafe: true,
                executionNotes: "Becken fest ins Polster pressen, kein Hohlkreuz.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Stehendes Wadenheben",
                targetMuscle: .legs,
                equipment: .bodyweight,
                isBWKRehaSafe: true,
                executionNotes: "Symmetrischer Wadenschwung.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Sitzende Beinbeuger an der Maschine",
                targetMuscle: .legs,
                equipment: .legPressMachine,
                isBWKRehaSafe: true,
                executionNotes: "Volle Dehnung in der Hueftbeugung.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Copenhagen Plank am Polster",
                targetMuscle: .functionalCore,
                equipment: .roomFurniture,
                isBWKRehaSafe: true,
                executionNotes: "Staerkt die Adduktoren und stabilisiert das Schambein.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Seitstuetz mit Beinhochfuehren",
                targetMuscle: .legs,
                equipment: .bodyweight,
                isBWKRehaSafe: true,
                executionNotes: "Staerkt Flanke und Gluteus Medius simultan.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Einbeiniges Rumaenisches Kreuzheben (Single Leg RDL)",
                targetMuscle: .legs,
                equipment: .bodyweight,
                isBWKRehaSafe: true,
                executionNotes: "Standbein minimal gebeugt, Huefte parallel zum Boden halten.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Kabel-Glute-Kickbacks",
                targetMuscle: .glutesPosterior,
                equipment: .cableCrossoverTower,
                isBWKRehaSafe: true,
                executionNotes: "Diagonale Abspreizung fuer maximalen Muskelreiz.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "McGill Bird-Dog",
                targetMuscle: .functionalCore,
                equipment: .bodyweight,
                isBWKRehaSafe: true,
                executionNotes: "Regenerativer Abschluss fuer die Wirbelsaeule.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Kabelzug-Seitheben einarmig hinter Koerper",
                targetMuscle: .shoulders,
                equipment: .cableCrossoverTower,
                isBWKRehaSafe: true,
                executionNotes: "Spannung verlaesst den seitlichen Delt zu keinem Zeitpunkt.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Kurzhantel-Schraegbankdruecken 30 Grad",
                targetMuscle: .chest,
                equipment: .dumbBells,
                isBWKRehaSafe: true,
                executionNotes: "Ellenbogen ca. 45 Grad zum Oberkoerper.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Dumbbell Lateral Raise (Teilwiederholungen)",
                targetMuscle: .back,
                equipment: .dumbBells,
                isBWKRehaSafe: true,
                executionNotes: "Schweres Gewicht, saubere Teilausfuehrung.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Incline Dumbbell Curls (45 Grad Bank)",
                targetMuscle: .arms,
                equipment: .dumbBells,
                isBWKRehaSafe: true,
                executionNotes: "Oberarme senkrecht nach unten haengen lassen.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Kabel-Trizepsdruecken ueber Kopf mit Seil",
                targetMuscle: .arms,
                equipment: .cableCrossoverTower,
                isBWKRehaSafe: true,
                executionNotes: "Volle Dehnung im langen Trizepskopf.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Konzentrations-Curls auf Oberschenkel",
                targetMuscle: .arms,
                equipment: .bodyweight,
                isBWKRehaSafe: true,
                executionNotes: "Maximale Bizepskuppe am obersten Punkt.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Kurzhantel-Schulterdruecken im Sitzen",
                targetMuscle: .shoulders,
                equipment: .dumbBells,
                isBWKRehaSafe: true,
                executionNotes: "Unten 90 Grad, oben zusammendruecken ohne Ellenbogenueberstreckung.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Vorgebeugtes Seitheben auf Schraegbank",
                targetMuscle: .shoulders,
                equipment: .bodyweight,
                isBWKRehaSafe: true,
                executionNotes: "Brust liegt auf Bank, keine Schwungbewegung.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Barren-Dips mit Fokus auf Trizeps",
                targetMuscle: .arms,
                equipment: .dipStation,
                isBWKRehaSafe: true,
                executionNotes: "Oberkoerper aufrecht halten.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Hammer Curls mit Kurzhanteln stehend",
                targetMuscle: .arms,
                equipment: .dumbBells,
                isBWKRehaSafe: true,
                executionNotes: "Daumen zeigen die gesamte Zeit nach oben.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Trizepsdruecken an gerader Kabelstange",
                targetMuscle: .arms,
                equipment: .cableCrossoverTower,
                isBWKRehaSafe: true,
                executionNotes: "Ellenbogen am Rumpf einbetonieren.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Reverse Curls mit SZ-Stange (Unterarme)",
                targetMuscle: .arms,
                equipment: .flatBenchBarbell,
                isBWKRehaSafe: true,
                executionNotes: "Obergriff staerkt den Brachioradialis.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Lu Raises mit Hanteln ueber Kopf",
                targetMuscle: .shoulders,
                equipment: .bodyweight,
                isBWKRehaSafe: true,
                executionNotes: "Grosser Bogen, kontrollierte Bewegung.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Facepulls mit doppelter Aussenrotation",
                targetMuscle: .shoulders,
                equipment: .bodyweight,
                isBWKRehaSafe: true,
                executionNotes: "Staerkt Haltung und Schultergesundheit.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Seitstuetz mit Abduktion",
                targetMuscle: .glutesPosterior,
                equipment: .bodyweight,
                isBWKRehaSafe: true,
                executionNotes: "Taille schlank halten.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Kabelzug-Pallof-Press im schulterbreiten Stand",
                targetMuscle: .functionalCore,
                equipment: .cableCrossoverTower,
                isBWKRehaSafe: true,
                executionNotes: "Kabel versucht den Koerper zu drehen; Bauch haelt eisern dagegen.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Einarmiges Koffer-Tragen (Suitcase Carry mit KH)",
                targetMuscle: .mobilityFlexibility,
                equipment: .dumbBells,
                isBWKRehaSafe: true,
                executionNotes: "Schultern absolut waagerecht halten.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Deadbug mit Druck gegen die Knie",
                targetMuscle: .functionalCore,
                equipment: .bodyweight,
                isBWKRehaSafe: true,
                executionNotes: "Maximale diagonale Rumpfspannung ohne Wirbelsaeulenkruemmung.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Latzug im breiten Obergriff zur oberen Brust",
                targetMuscle: .back,
                equipment: .cableCrossoverTower,
                isBWKRehaSafe: true,
                executionNotes: "Leichte Ruecklage (10 Grad), kein Reissen aus dem unteren Ruecken.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Reverse Hyperextensions auf Bank",
                targetMuscle: .glutesPosterior,
                equipment: .bodyweight,
                isBWKRehaSafe: true,
                executionNotes: "Oberkoerper liegt auf der Bank, Beine werden durch Gesaesskraft angehoben.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Kabel-Ueberzuege mit Seil (Straight-Arm)",
                targetMuscle: .mobilityFlexibility,
                equipment: .cableCrossoverTower,
                isBWKRehaSafe: true,
                executionNotes: "Aktiviert den Serratus fuer die Rippenkontur.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Stir-the-Pot auf Gymnastikball (Kreisende Unterarme)",
                targetMuscle: .functionalCore,
                equipment: .bodyweight,
                isBWKRehaSafe: true,
                executionNotes: "Beste Uebung fuer Tiefenrumpf gemaess Prof. Stuart McGill.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Seitstuetz (Side Plank) mit erhoehten Fuessen",
                targetMuscle: .functionalCore,
                equipment: .bodyweight,
                isBWKRehaSafe: true,
                executionNotes: "Gluteus Medius und innere schraege Bauchmuskeln.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Bird-Dog mit Daumen nach oben",
                targetMuscle: .functionalCore,
                equipment: .bodyweight,
                isBWKRehaSafe: true,
                executionNotes: "Multifidi-Aktivierung.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Brustgestuetztes Kurzhantelrudern neutral",
                targetMuscle: .back,
                equipment: .dumbBells,
                isBWKRehaSafe: true,
                executionNotes: "Schulterblaetter maximal zusammenziehen.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Einarmiges Waiter's Walk (Hantel ueber Kopf tragen)",
                targetMuscle: .mobilityFlexibility,
                equipment: .bodyweight,
                isBWKRehaSafe: true,
                executionNotes: "Fixiert das Schulterblatt und fordert die Schraege Bauchwand.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Face Pulls mit 2s Pause",
                targetMuscle: .shoulders,
                equipment: .bodyweight,
                isBWKRehaSafe: true,
                executionNotes: "Haltungsausgleich.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Farmer's Walk beidbeinig mit schweren Hanteln",
                targetMuscle: .legs,
                equipment: .bodyweight,
                isBWKRehaSafe: true,
                executionNotes: "Aufrechte Haltung, strammer Schritt.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Gesaessbruecke mit Ball zwischen Knien (Adduktoren)",
                targetMuscle: .mobilityFlexibility,
                equipment: .bodyweight,
                isBWKRehaSafe: true,
                executionNotes: "Schliesst das Becken und aktiviert den Beckenboden.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Passive Bar Hang mit tiefer Ausatmung",
                targetMuscle: .back,
                equipment: .pullUpBar,
                isBWKRehaSafe: true,
                executionNotes: "Dekompression der gesamten Wirbelsaeule.",
                defaultSets: 3, defaultReps: 10, defaultRestSeconds: 75
            ),

            // MARK: - Spezifische Lauf- & Ausdauer-Uebungen (Daniels, 80/20, Maffetone)
            Exercise(
                name: "Zone 2 Grundlagenausdauerlauf (E-Pace)",
                targetMuscle: .cardioConditioning,
                equipment: .outdoorRunning,
                isBWKRehaSafe: true,
                executionNotes: "Jack Daniels E-Pace (Easy Run). Laktat unter 2.0 mmol/L, reine aerobe Fettverbrennung, Sprechtest problemlos moeglich.",
                defaultSets: 1, defaultReps: 45, defaultRestSeconds: 60
            ),
            Exercise(
                name: "Laktatschwellen-Tempolauf (T-Pace)",
                targetMuscle: .cardioConditioning,
                equipment: .outdoorRunning,
                isBWKRehaSafe: true,
                executionNotes: "Jack Daniels T-Pace (Threshold). Aerob-anaerober Uebergangsbereich zur Anhebung der Laktatclearance.",
                defaultSets: 1, defaultReps: 25, defaultRestSeconds: 90
            ),
            Exercise(
                name: "VO2max 4x4-Minuten-Intervalle (I-Pace)",
                targetMuscle: .cardioConditioning,
                equipment: .outdoorRunning,
                isBWKRehaSafe: true,
                executionNotes: "Jack Daniels I-Pace (Interval). 4x4 Minuten bei 90-95% HFmax mit 3 Minuten aktiver Gehpause zur Maximierung der Sauerstoffaufnahme.",
                defaultSets: 4, defaultReps: 4, defaultRestSeconds: 180
            ),
            Exercise(
                name: "12-Minuten Cooper-Test All-Out",
                targetMuscle: .cardioConditioning,
                equipment: .outdoorRunning,
                isBWKRehaSafe: true,
                executionNotes: "Standardisierter Militaer- und Sportwissenschaftstest. Maximal moegliche Distanz in exakt 12 Minuten.",
                defaultSets: 1, defaultReps: 12, defaultRestSeconds: 120
            ),
            Exercise(
                name: "Bundeswehr 1000m-Sprint-Simulation",
                targetMuscle: .cardioConditioning,
                equipment: .outdoorRunning,
                isBWKRehaSafe: true,
                executionNotes: "Basis-Fitness-Test (BFT) Disziplin. Maximale anaerobe Laktattoleranz unter 3:45 Minuten.",
                defaultSets: 2, defaultReps: 1, defaultRestSeconds: 240
            ),
            Exercise(
                name: "MAF-180 Herzfrequenz-Lauf",
                targetMuscle: .cardioConditioning,
                equipment: .outdoorRunning,
                isBWKRehaSafe: true,
                executionNotes: "Dr. Phil Maffetone Methode: Maximale Herzfrequenz = 180 minus Lebensalter. Baut mitochondriale Dichte ohne Stresshormone auf.",
                defaultSets: 1, defaultReps: 40, defaultRestSeconds: 60
            ),

            // MARK: - Spezifische Stuben- & Zimmer-Uebungen (No Weights)
            Exercise(
                name: "Tischkanten-Inverted-Rows (Unter Tisch liegend)",
                targetMuscle: .back,
                equipment: .roomFurniture,
                isBWKRehaSafe: true,
                executionNotes: "Unter den stabilen Stubentisch legen, Tischkante im Obergriff greifen, Koerper wie ein Brett zur Tischkante hochziehen.",
                defaultSets: 4, defaultReps: 10, defaultRestSeconds: 75
            ),
            Exercise(
                name: "Bettkanten-Liegestuetz (Fuesse auf Bett erhoeht)",
                targetMuscle: .chest,
                equipment: .roomFurniture,
                isBWKRehaSafe: true,
                executionNotes: "Fuesse auf die Bettkante, Haende schulterbreit am Boden. Erhoeht die Last auf die obere Brustmuskulatur.",
                defaultSets: 4, defaultReps: 12, defaultRestSeconds: 60
            ),
            Exercise(
                name: "Bettkanten Trizeps-Druecken (Bodyweight Triceps Extension)",
                targetMuscle: .arms,
                equipment: .roomFurniture,
                isBWKRehaSafe: true,
                executionNotes: "Haende auf Bett- oder Tischkante schulterbreit abstuetzen. Koerper steif wie ein Brett. Stirn kontrolliert absenken und rein aus dem Trizeps strecken. Schulterschonend.",
                defaultSets: 3, defaultReps: 12, defaultRestSeconds: 60
            ),
            Exercise(
                name: "Bulgarische Split Squats (Hinterer Fuss auf Bettkante)",
                targetMuscle: .legs,
                equipment: .roomFurniture,
                isBWKRehaSafe: true,
                executionNotes: "Hinterer Fuss ruht auf Bett- oder Stuhlkante. Vorderes Knie beugt bis 90 Grad. Maximaler Quad- und Gluteusreiz ohne Zusatzgewicht.",
                defaultSets: 4, defaultReps: 10, defaultRestSeconds: 60
            ),
            Exercise(
                name: "Chair Step-ups (Auf Stuhl im Sekundentakt)",
                targetMuscle: .legs,
                equipment: .roomFurniture,
                isBWKRehaSafe: true,
                executionNotes: "Kontrolliertes rhythmisches Auf- und Absteigen auf den Stuhl. Fuehrungsbein minuetlich wechseln.",
                defaultSets: 3, defaultReps: 15, defaultRestSeconds: 45
            ),
            Exercise(
                name: "Shadow Boxing & Fast-Marching (Stuben-Konditionierung)",
                targetMuscle: .cardioConditioning,
                equipment: .roomFurniture,
                isBWKRehaSafe: true,
                executionNotes: "Rhythmische Schlagkombinationen gekoppelt mit schnellem Kniehebelauf auf der Stelle. Erzeugt Zone-2/HIIT-Puls im Zimmer.",
                defaultSets: 4, defaultReps: 3, defaultRestSeconds: 60
            ),
        ]

        for i in 0..<list.count {
            enrichExercise(&list[i])
        }
        return list
    }

    public static func enrichExercise(_ ex: inout Exercise) {
        let name = ex.name.lowercased()

        // 0. Einarmige Liegestütze (Elite Calisthenics Anti-Rotation Push)
        if name.contains("einarmige liegestuetz") || name.contains("one arm push") {
            ex.difficulty = "Elite"
            ex.categoryType = "Push"
            ex.mechanics = "Compound"
            ex.movementPattern = "Horizontal Push"
            ex.force = "Push"
            ex.primaryMusclesDetailed = ["Pectoralis Major Sternal Head", "Pectoralis Major Clavicular Head"]
            ex.secondaryMusclesDetailed = ["Triceps Brachii Lateral Head", "Triceps Brachii Medial Head", "Deltoid Anterior Head"]
            ex.stabilizersDetailed = ["Obliques Internus & Externus", "Transversus Abdominis", "Gluteus Medius", "Serratus Anterior"]
            ex.setup = "Fuesse schulterbreit oder weiter spreizen (Dreiecks-Basis fuer maximale Anti-Rotations-Stabilitaet). Die arbeitende Hand unter der Brustmitte platzieren. Die freie Hand auf den Ruecken oder an den Oberschenkel legen. Bauch, Gluteus und Beine unter maximale Koerperspannung bringen."
            ex.execution = "Oberkoerper als starre Einheit kontrolliert absenken, bis die Brust ca. 5-10 cm ueber dem Boden ist. Huefte parallel zum Boden halten (Rotation aktiv bekaempfen). Kraftvoll aus Brust und Trizeps wieder nach oben in die vollstaendige Streckung druecken."
            ex.commonMistakes = [
                "Starke Rotation des Beckens zur Seite (Ausweichbewegung bei mangelnder Rumpfspannung)",
                "Durchhaengen der Huefte / LWS-Hohlkreuz",
                "Zu enger Fussstand mit Verlust des Gleichgewichts"
            ]
            ex.cues = [
                "Anti-Rotation: Beckenknochen zeigen wie Scheinwerfer senkrecht zum Boden",
                "Koerper wie eine Stahlstange spannen",
                "Ellbogen 45 Grad am Koerper fuehren, nicht nach aussen spreizen"
            ]
            ex.easierOptions = [
                "Einarmige Liegestuetze erhoeht an einer Bank oder Wand",
                "Archer Push-Ups (unterstuetzte einarmige Liegestuetze)",
                "Diamant-Liegestuetze mit enger Handstellung"
            ]
            ex.harderOptions = [
                "Einarmige Liegestuetze mit geschlossenen Beinen",
                "Einarmige Liegestuetze mit erhoeht platzierten Fuessen",
                "Einarmige Liegestuetze mit 2 Sekunden Pause am Tiefpunkt"
            ]
            ex.programmingGuidance = "3-4 Saetze x 5-10 Wdh pro Arm, 90-120s Pause, RIR 1-2. Frequenz: 2x woechentlich."
            return
        }

        // 1. Back / Pull
        if ex.targetMuscle == .back || name.contains("ruder") || name.contains("latzug") || name.contains("klimmzug") || name.contains("pull-up") || name.contains("chin-up") || name.contains("pullover") || name.contains("rhomboideus") {
            ex.difficulty = (name.contains("klimmzug") || name.contains("pull-up")) ? "Fortgeschritten" : "Mittelstufe"
            ex.categoryType = "Pull"
            ex.mechanics = name.contains("pullover") ? "Isolation" : "Compound"
            ex.movementPattern = (name.contains("latzug") || name.contains("klimmzug") || name.contains("pull-up")) ? "Vertical Pull" : "Horizontal Pull"
            ex.force = "Pull"
            ex.primaryMusclesDetailed = ["Latissimus Dorsi", "Trapezius"]
            ex.secondaryMusclesDetailed = ["Biceps Brachii Long Head", "Biceps Brachii Short Head", "Deltoid Posterior Head", "Brachioradialis"]
            ex.stabilizersDetailed = ["Rectus Abdominis", "Obliques Upper", "Serratus Anterior"]
            ex.setup = "Griffe oder Stange mit festem Griff fassen. Brustbein anheben, Schulterblaetter nach hinten unten ziehen und den Rumpf stabilisieren."
            ex.execution = "Aus dem Ruecken heraus die Ellbogen kraftvoll nach hinten bzw. unten fuehren. Am Endpunkt der Bewegung die Schulterblaetter fest zusammenpressen und 1 Sekunde halten. Kontrolliert ueber 2-3 Sekunden in die Dehnung zurueckkehren."
            ex.commonMistakes = [
                "Schultern zu den Ohren hochziehen (Trapezius Pars Descendens Dominanz)",
                "Schwungholen mit dem Oberkoerper aus der Lendenwirbelsaeule",
                "Verkuerzter Bewegungsumfang ohne volle Streckung im Latissimus"
            ]
            ex.cues = [
                "Ellbogen fuehren die Bewegung, Haende sind nur Haken",
                "Brustbein aktiv zum Griff oder zur Stange schieben",
                "Schulterblaetter bewusst in die Gesaesstaschen ziehen"
            ]
            ex.easierOptions = [
                "Unterstuetzte Klimmzug-Maschine mit Gegengewicht",
                "Latzug am Kabel mit moderatem Gewicht",
                "Kabelrudern mit Parallelgriff (V-Griff)"
            ]
            ex.harderOptions = [
                "Zusatzgewicht am Guertel",
                "1.5 Wiederholungen (halbe Wiederholung im kontrahierten Zustand)",
                "3 Sekunden Pause am Peak-Kontraktionspunkt"
            ]
            ex.programmingGuidance = "3-4 Saetze x 8-12 Wiederholungen, 90-120 Sekunden Pause, RIR 1-2. Frequenz: 2x woechentlich."
            return
        }

        // 2. Chest / Push
        if ex.targetMuscle == .chest || name.contains("bankdrueck") || name.contains("bench") || name.contains("butterfly") || name.contains("pec-deck") || name.contains("flys") || name.contains("brustdrueck") {
            ex.difficulty = (name.contains("langhantel") || name.contains("kurzhantel")) ? "Mittelstufe" : "Anfaenger"
            ex.categoryType = "Push"
            ex.mechanics = (name.contains("butterfly") || name.contains("flys") || name.contains("pec-deck")) ? "Isolation" : "Compound"
            ex.movementPattern = name.contains("schraeg") ? "Incline Push" : "Horizontal Push"
            ex.force = "Push"
            ex.primaryMusclesDetailed = ["Pectoralis Major Sternal Head", "Pectoralis Major Clavicular Head"]
            ex.secondaryMusclesDetailed = ["Deltoid Anterior Head", "Triceps Brachii Lateral Head", "Triceps Brachii Long Head"]
            ex.stabilizersDetailed = ["Serratus Anterior", "Rotator Cuff (Infraspinatus)", "Rectus Abdominis"]
            ex.setup = "Auf der Bank positionieren, Augen unter der Hantelstange oder Sitzhoehe auf Brustwarzenhoehe einstellen. Fuesse fest in den Boden druecken (Leg Drive). Schulterblaetter zusammenziehen und fest in die Bank graben."
            ex.execution = "Gewicht kontrolliert zur mittleren/unteren Brust absenken. Ellbogen in einem 45-60 Grad Winkel zum Koerper fuehren. Tiefe Dehnung spueren, danach kraftvoll nach oben herausdruecken ohne die Schulterblaetter zu oeffnen."
            ex.commonMistakes = [
                "Ellbogen 90 Grad nach aussen abspreizen (Gefahr fuer Schulter-Impingement)",
                "Abfedern des Gewichts auf dem Brustkorb",
                "Schultern waehrend des Drueckens vom Polster nach vorn schieben"
            ]
            ex.cues = [
                "Boden ueber die Fersen in den Raum druecken",
                "Stange in den Haenden gedanklich zusammenbiegen",
                "Brustbein stolz aufgerichtet lassen"
            ]
            ex.easierOptions = [
                "Brustpresse-Maschine (fuehrte Trajektorie entlastet Stabilisatoren)",
                "Kurzhantel-Bankdruecken mit freiem Gelenkwinkel",
                "Erhoehte Liegestuetze an einer Bank"
            ]
            ex.harderOptions = [
                "Pausiertes Bankdruecken (2 Sekunden Stopp auf der Brust)",
                "Schraegbankdruecken mit Kurzhanteln",
                "Dips mit Zusatzgewicht"
            ]
            ex.programmingGuidance = "3-4 Saetze x 6-10 Wiederholungen, 120-150 Sekunden Pause, RIR 1-2. Progression: +2.5 kg bei Erreichen des oberen Rep-Limits."
            return
        }

        // 3. Shoulders
        if ex.targetMuscle == .shoulders || name.contains("schulterdrueck") || name.contains("overhead") || name.contains("ohp") || name.contains("seitheben") || name.contains("face pull") {
            ex.difficulty = name.contains("overhead") ? "Mittelstufe" : "Anfaenger"
            ex.categoryType = "Push"
            ex.mechanics = (name.contains("seitheben") || name.contains("face pull")) ? "Isolation" : "Compound"
            ex.movementPattern = name.contains("seitheben") ? "Lateral Abduction" : (name.contains("face pull") ? "Horizontal Retraction" : "Vertical Push")
            ex.force = name.contains("face pull") ? "Pull" : "Push"
            ex.primaryMusclesDetailed = ["Deltoid Lateral Head", "Deltoid Anterior Head"]
            ex.secondaryMusclesDetailed = ["Triceps Brachii", "Trapezius Upper", "Supraspinatus"]
            ex.stabilizersDetailed = ["Core (Transversus Abdominis)", "Serratus Anterior", "Erector Spinae"]
            ex.setup = "Stabile Sitz- oder Standposition. Rumpf unter maximale isometrische Spannung setzen. Handgelenke gerade ueber den Ellbogen ausrichten."
            ex.execution = "Gewicht entlang der Scapular-Ebene (Ellbogen ca. 30 Grad vor dem Koerper) kontrolliert nach oben druecken oder seitlich bis Schulterhoehe anheben. Schultern tief halten, Nacken nicht unnoetig verkuerzen."
            ex.commonMistakes = [
                "Extremes Ausweichen in ein Hohlkreuz zur Kompensation",
                "Ellbogen waehrend des Seithebens hinter die Schulterachse fuehren",
                "Hochziehen der Schultern ueber den oberen Trapezius"
            ]
            ex.cues = [
                "Ellbogen fuehren die Bewegung nach aussen",
                "Rippenbogen unten halten und Bauch fest anspannen",
                "Gewicht in den Himmel schieben, nicht nach hinten werfen"
            ]
            ex.easierOptions = [
                "Schulterdruecken an der gefuehrten Maschine",
                "Kabel-Seitheben mit Einzelgriff",
                "Sitzendes Kurzhanteldruecken mit 80-Grad Rueckenlehne"
            ]
            ex.harderOptions = [
                "Stehendes Langhantel-Schulterdruecken (Military Press)",
                "Seitheben mit 3 Sekunden exzentrischer Phase",
                "Face Pulls mit 2 Sekunden Aussenrotations-Pause"
            ]
            ex.programmingGuidance = "3-4 Saetze x 8-12 Wiederholungen, 90 Sekunden Pause, RIR 2. Bei Seitheben 12-15 Wiederholungen."
            return
        }

        // 4. Glutes & Posterior Chain / Lower Back
        if ex.targetMuscle == .glutesPosterior || ex.targetMuscle == .lowerBack || name.contains("kreuzheben") || name.contains("deadlift") || name.contains("rdl") || name.contains("hip thrust") || name.contains("glute drive") || name.contains("good morning") || name.contains("hyperextension") {
            ex.difficulty = (name.contains("kreuzheben") || name.contains("deadlift")) ? "Fortgeschritten" : "Mittelstufe"
            ex.categoryType = "Legs"
            ex.mechanics = name.contains("hyperextension") ? "Isolation" : "Compound"
            ex.movementPattern = name.contains("hip thrust") ? "Hip Extension" : "Hinge / Posterior Chain"
            ex.force = "Pull"
            ex.primaryMusclesDetailed = ["Gluteus Maximus", "Biceps Femoris", "Semitendinosus"]
            ex.secondaryMusclesDetailed = ["Erector Spinae", "Adductor Magnus", "Latissimus Dorsi", "Trapezius"]
            ex.stabilizersDetailed = ["Transversus Abdominis", "Multifidi", "Quadratus Lumborum"]
            ex.setup = "Huftbreiter Stand vor der Stange oder Positionierung im Hip-Thrust-Polster. Knie minimal entriegelt. Schulterblaetter nach hinten fixieren, LWS neutral verriegeln."
            ex.execution = "Huefte weit nach hinten schieben (Hip Hinge). Oberkoerper neigt sich kontrolliert nach vorn bis spuerbare Dehnung in den Hamstrings eintritt. Stange eng am Schienbein fuehren. Durch kraftvolle Gesaessstreckung die Huefte wieder nach vorn bringen."
            ex.commonMistakes = [
                "Einrunden der Lendenwirbelsaeule unter Last (strikte Reha-Kontraindikation)",
                "Stange driftet vom Koerper weg nach vorn",
                "Ueberstreckung ins Hohlkreuz am oberen Endpunkt"
            ]
            ex.cues = [
                "Eine Tuer mit dem Gesaess nach hinten zuschlagen",
                "Stange streift dauerhaft Oberschenkel und Schienbeine",
                "Nacken neutral halten, Blick 2 Meter vor sich auf den Boden"
            ]
            ex.easierOptions = [
                "Hyperextensions 45 Grad mit Eigengewicht",
                "Kabel-Pull-Through (minimiert axiale Wirbelsaeulenkompression)",
                "Kurzhantel RDL mit moderater Last"
            ]
            ex.harderOptions = [
                "Langhantel RDL mit 3 Sekunden Stopp in maximaler Dehnung",
                "Glute Drive mit hohem Arbeitsgewicht und 2s Spitzenkontraktion",
                "Einbeiniges rumaenisches Kreuzheben"
            ]
            ex.programmingGuidance = "3-4 Saetze x 8-10 Wiederholungen, 120 Sekunden Pause, RIR 2. BWK Reha: Keine Maximalversuche, strikte Neutralitaet der Wirbelsaeule."
            return
        }

        // 5. Legs / Quads
        if ex.targetMuscle == .legs || name.contains("kniebeuge") || name.contains("squat") || name.contains("beinpresse") || name.contains("leg press") || name.contains("ausfallschritt") || name.contains("lunge") || name.contains("waden") {
            ex.difficulty = name.contains("kniebeuge") ? "Fortgeschritten" : "Anfaenger"
            ex.categoryType = "Legs"
            ex.mechanics = name.contains("waden") ? "Isolation" : "Compound"
            ex.movementPattern = name.contains("waden") ? "Plantarflexion" : "Squat / Quad Dominant"
            ex.force = "Push"
            ex.primaryMusclesDetailed = ["Quadriceps Femoris (Rectus Femoris, Vastus Lateralis, Vastus Medialis)"]
            ex.secondaryMusclesDetailed = ["Gluteus Maximus", "Adductor Magnus", "Soleus", "Gastrocnemius"]
            ex.stabilizersDetailed = ["Rectus Abdominis", "Erector Spinae", "Gluteus Medius"]
            ex.setup = "Fuesse schulterbreit platzieren, Zehen ca. 15 Grad nach aussen gedreht. Bei der Beinpresse Becken fest an die Rueckenlehne pressen (kein Butt-Wink). Rumpf versteifen."
            ex.execution = "Gleichzeitig Knie und Huefte beugen. Knie fuehren praezise ueber die zweite Zehe. Absenken bis mindestens 90 Grad Kniebeugung. Ueber die gesamte Fusssohle kraftvoll aufrichten, Knie am Umkehrpunkt nicht durchschlagen."
            ex.commonMistakes = [
                "Kollabieren der Knie nach innen (Knievalgus)",
                "Becken rollt sich von der Rueckenlehne ein (Butt Wink)",
                "Fersen heben vom Trittbrett ab"
            ]
            ex.cues = [
                "Boden mit den Fuessen nach aussen spreizen",
                "Brustbein stolz nach oben richten",
                "Druck gleichmaessig ueber Fersen und Grosszehenballen verteilen"
            ]
            ex.easierOptions = [
                "Beinpresse 45 Grad mit moderater Tiefe",
                "Goblet Squat mit leichter Kurzhantel vor der Brust",
                "Ausfallschritte auf der Stelle ohne Zusatzgewicht"
            ]
            ex.harderOptions = [
                "Pausierte Kniebeugen (2s Stopp im tiefsten Punkt)",
                "Bulgarian Split Squats mit Kurzhanteln",
                "Einbeinige Beinpresse zur Beseitigung von Dysbalancen"
            ]
            ex.programmingGuidance = "3-4 Saetze x 8-12 Wiederholungen, 90-120 Sekunden Pause, RIR 1-2. Wadenheben: 3 Saetze x 12-15 Reps mit 2s Dehnung."
            return
        }

        // 6. Arms / Biceps & Triceps
        if ex.targetMuscle == .arms || name.contains("curl") || name.contains("bizeps") || name.contains("trizeps") || name.contains("dip") {
            let isBiceps = name.contains("curl") || name.contains("bizeps")
            ex.difficulty = "Anfaenger"
            ex.categoryType = isBiceps ? "Pull" : "Push"
            ex.mechanics = "Isolation"
            ex.movementPattern = isBiceps ? "Elbow Flexion" : "Elbow Extension"
            ex.force = isBiceps ? "Pull" : "Push"
            ex.primaryMusclesDetailed = isBiceps ? ["Biceps Brachii Long Head", "Biceps Brachii Short Head"] : ["Triceps Brachii Lateral Head", "Triceps Brachii Long Head", "Triceps Brachii Medial Head"]
            ex.secondaryMusclesDetailed = isBiceps ? ["Brachialis", "Brachioradialis"] : ["Anconeus"]
            ex.stabilizersDetailed = ["Rotator Cuff", "Forearm Flexors", "Core"]
            ex.setup = "Aufrechter Stand oder stabiler Sitz. Ellbogen eng an den Rippen fixieren und waehrend des gesamten Satzes unbeweglich halten."
            ex.execution = isBiceps ?
                "Unterarme kontrolliert nach oben beugen. Am Endpunkt maximale Spitzenkontraktion fuer 1-2 Sekunden halten. Kontrolliert ueber 2-3 Sekunden absenken bis zur vollen Streckung." :
                "Unterarme kraftvoll nach unten strecken. Am Endpunkt den Trizeps 1 Sekunde maximal kontrahieren. Kontrolliert bis zu einem 90-Grad Ellbogenwinkel zurueckfuehren."
            ex.commonMistakes = [
                "Vor- und Zurueckschwingen des Oberkoerpers mit Schwung",
                "Ellbogen wandern nach vorn waehrend des Curls",
                "Handgelenke knicken unter Last ab"
            ]
            ex.cues = [
                "Ellbogen sind an der Koerperseite festgetackert",
                "Nur die Unterarme bewegen sich durch den Raum",
                "Volle Dehnung am Umkehrpunkt zulassen"
            ]
            ex.easierOptions = isBiceps ? [
                "Kabelcurls mit gerader Stange",
                "Kurzhantelcurls sitzend mit Rueckenlehne"
            ] : [
                "Trizepsdruecken am Kabelzug mit V-Griff",
                "Dips an der unterstuetzten Maschine mit Gegengewicht"
            ]
            ex.harderOptions = isBiceps ? [
                "Incline Dumbbell Curls (maximaler Stretch des langen Bizepskopfs)",
                "Scott-Bank Curls mit 3 Sekunden Exzentrik"
            ] : [
                "Schaedelzertruemmerer (Skull Crushers) mit SZ-Stange",
                "Trizepsdruecken ueber Kopf am Kabelzug"
            ]
            ex.programmingGuidance = "3 Saetze x 10-14 Wiederholungen, 60-75 Sekunden Pause, RIR 1-2."
            return
        }

        // 7. Core / Functional / Reha
        if ex.targetMuscle == .functionalCore || name.contains("plank") || name.contains("pallof") || name.contains("bird-dog") {
            ex.difficulty = "Anfaenger"
            ex.categoryType = "Core"
            ex.mechanics = "Isolation"
            ex.movementPattern = "Anti-Extension / Isometric Stability"
            ex.force = "Static"
            ex.primaryMusclesDetailed = ["Transversus Abdominis", "Multifidi"]
            ex.secondaryMusclesDetailed = ["Rectus Abdominis", "Obliques Internus & Externus"]
            ex.stabilizersDetailed = ["Gluteus Medius", "Quadratus Lumborum", "Diaphragma"]
            ex.setup = "Auf der Matte in Bauch- oder Rueckenlage positionieren. Wirbelsaeule in eine vollstaendig neutrale Position bringen. Beckenboden aktivieren."
            ex.execution = "Isometrische Rumpfspannung aufbauen. Sanft und kontinuierlich in den Brustkorb weiteratmen. Die Bauchdecke nicht nach aussen pressen (keine Druckspitzen im Beckenboden)."
            ex.commonMistakes = [
                "Pressatmung (Valsalva-Manover) erhoeht gefaehrlich den intraabdominalen Druck",
                "Durchhaengen der Lendenwirbelsaeule ins Hohlkreuz",
                "Schultern verkrampfen nach oben"
            ]
            ex.cues = [
                "Bauchnabel sanft nach innen oben saugen",
                "Rumpf stabilisieren wie ein solides Korsett",
                "Gleichmaessig und kontrolliert weiteratmen"
            ]
            ex.easierOptions = [
                "Unterarmstuetz auf den Knien",
                "Bird-Dog mit kuerzerer Haltezeit (1-2 Sekunden)"
            ]
            ex.harderOptions = [
                "Pallof Press mit Vor- und Rueckschritten",
                "Plank mit alternierendem Armheben",
                "Bird-Dog mit Gewichtsmanschetten"
            ]
            ex.programmingGuidance = "3-4 Durchgaenge x 30-45 Sekunden isometrisch, 45 Sekunden Pause. BWK Ulm Reha: Goldstandard fuer postoperative Bauchwand- und LWS-Stabilitaet."
            return
        }

        // 8. Mobility / Stretching / Dehnungs- und Regeneration
        ex.difficulty = "Anfaenger"
        ex.categoryType = "Mobility"
        ex.mechanics = "Flexibility"
        ex.movementPattern = "Decompression / Passive & Dynamic Stretch"
        ex.force = "Static"
        ex.primaryMusclesDetailed = ["Erector Spinae", "Hamstrings", "Iliopsoas", "Piriformis"]
        ex.secondaryMusclesDetailed = ["Latissimus Dorsi", "Gluteus Maximus", "Pectoralis Major", "Thoracic Spine"]
        ex.stabilizersDetailed = ["Diaphragma", "Transversus Abdominis", "Multifidi"]
        ex.setup = "Bodenmatte ausbreiten. Ruhige Atmung etablieren (4 Sekunden einatmen, 6 Sekunden ausatmen zur Aktivierung des Vagusnervs). Gelenke in eine schmerzfreie Dehnposition bringen."
        ex.execution = "Langsam und ohne Federn in die Dehnung hineinsinken. Die Dehnspannung auf einer Skala von 1-10 bei maximal 6-7 halten. Mit jeder Ausatmung Spannung loslassen und Dehnung vertiefen."
        ex.commonMistakes = [
            "Ruckartiges Federn oder Wippen (loest Schutzreflex der Muskelspindeln aus)",
            "Luftanhalten waehrend der Dehnung",
            "Aggressives Rundruecken der LWS unter Dehnungszug"
        ]
        ex.cues = [
            "Mit jeder langen Ausatmung tiefer entspannen",
            "Kein stechender Schmerz, nur wohltuende Gewebelaengung",
            "Wirbelsaeule lang und dekomprimiert halten"
        ]
        ex.easierOptions = [
            "Verkuerzte Haltedauer (20-30 Sekunden)",
            "Verwendung eines Handtuchs als Hilfsmittel",
            "Geringere Bewegungstiefe"
        ]
        ex.harderOptions = [
            "PNF-Dehnung (5s sanft anspannen, dann tiefer dehnen)",
            "Verlaengerte Haltedauer auf 60-90 Sekunden",
            "Kombination mit aktiver Endgrad-Mobilisation"
        ]
        ex.programmingGuidance = "2-3 Durchgaenge x 30-60 Sekunden pro Seite. Ideal am Rest-Day, vor dem Schlafen oder als Cooldown."
    }

    public static func defaultTemplates() -> [WorkoutTemplate] {
        let all = defaultExercises()
        let byName = Dictionary(uniqueKeysWithValues: all.map { ($0.name, $0) })

        let upperItems: [WorkoutTemplateItem] = [
            WorkoutTemplateItem(exercise: byName["Bankdruecken (Langhantel)"] ?? all[0], targetSets: 4, targetReps: 8, targetWeightKg: 60),
            WorkoutTemplateItem(exercise: byName["Latzug zur Brust (breit)"] ?? all[1], targetSets: 4, targetReps: 10, targetWeightKg: 55),
            WorkoutTemplateItem(exercise: byName["Schulterdruecken (Maschine)"] ?? all[2], targetSets: 3, targetReps: 10, targetWeightKg: 40),
            WorkoutTemplateItem(exercise: byName["3D Rudern beidarmig"] ?? all[3], targetSets: 3, targetReps: 10, targetWeightKg: 50),
            WorkoutTemplateItem(exercise: byName["Trizepsdruecken am Seil (Neunstoeckig)"] ?? all[4], targetSets: 3, targetReps: 12, targetWeightKg: 25),
            WorkoutTemplateItem(exercise: byName["Preacher Curls (SZ-Stange / KH)"] ?? all[5], targetSets: 3, targetReps: 10, targetWeightKg: 25)
        ]

        let legItems: [WorkoutTemplateItem] = [
            WorkoutTemplateItem(exercise: byName["Beinpresse 45-Grad"] ?? all[0], targetSets: 4, targetReps: 10, targetWeightKg: 120),
            WorkoutTemplateItem(exercise: byName["Glute Drive / Hip Thrust Maschine"] ?? all[1], targetSets: 4, targetReps: 12, targetWeightKg: 60),
            WorkoutTemplateItem(exercise: byName["Beinbeugen liegend (Maschine)"] ?? all[2], targetSets: 3, targetReps: 12, targetWeightKg: 40),
            WorkoutTemplateItem(exercise: byName["Wadenheben sitzend (Maschine)"] ?? all[3], targetSets: 4, targetReps: 15, targetWeightKg: 35)
        ]

        let rehaItems: [WorkoutTemplateItem] = [
            WorkoutTemplateItem(exercise: byName["Unterarmstuetz / Plank"] ?? all[0], targetSets: 3, targetReps: 45, targetWeightKg: 0),
            WorkoutTemplateItem(exercise: byName["Bird-Dog (Vierfuesslerstand)"] ?? all[1], targetSets: 3, targetReps: 12, targetWeightKg: 0),
            WorkoutTemplateItem(exercise: byName["Pallof Press (Kabelzug)"] ?? all[2], targetSets: 3, targetReps: 12, targetWeightKg: 15),
            WorkoutTemplateItem(exercise: byName["45-Grad Rueckenstrecken mit Gluteus-Fokus"] ?? all[3], targetSets: 3, targetReps: 12, targetWeightKg: 0),
            WorkoutTemplateItem(exercise: byName["Oberkoerper-Ergometer (Armkurbel)"] ?? all[4], targetSets: 1, targetReps: 15, targetWeightKg: 0)
        ]

        let lowerBackItems: [WorkoutTemplateItem] = [
            WorkoutTemplateItem(exercise: byName["45-Grad Rueckenstrecken (Hyperextension)"] ?? byName["Roemische Bank Hyperextension"] ?? all[0], targetSets: 3, targetReps: 12, targetWeightKg: 0),
            WorkoutTemplateItem(exercise: byName["Rumaenisches Kreuzheben (Langhantel RDL)"] ?? byName["Kurzhantel Rumaenisches Kreuzheben (DB RDL)"] ?? all[0], targetSets: 3, targetReps: 10, targetWeightKg: 40),
            WorkoutTemplateItem(exercise: byName["Bird-Dog (Vierfuesslerstand)"] ?? all[0], targetSets: 3, targetReps: 12, targetWeightKg: 0),
            WorkoutTemplateItem(exercise: byName["Supermans (Boden-Rueckenstrecken)"] ?? all[0], targetSets: 3, targetReps: 12, targetWeightKg: 0),
            WorkoutTemplateItem(exercise: byName["Kindeshaltung / Prayer Stretch (LWS Dekompression)"] ?? all[0], targetSets: 3, targetReps: 45, targetWeightKg: 0)
        ]

        let barracksItems: [WorkoutTemplateItem] = [
            WorkoutTemplateItem(exercise: byName["Kurzhantel Floor Press"] ?? all[0], targetSets: 4, targetReps: 10, targetWeightKg: 20),
            WorkoutTemplateItem(exercise: byName["Kurzhantel Rudern einarmig (Stube)"] ?? all[0], targetSets: 4, targetReps: 10, targetWeightKg: 18),
            WorkoutTemplateItem(exercise: byName["Goblet Squat (Kurzhantel)"] ?? all[0], targetSets: 3, targetReps: 10, targetWeightKg: 22),
            WorkoutTemplateItem(exercise: byName["Unterarmstuetz / Plank"] ?? all[0], targetSets: 3, targetReps: 45, targetWeightKg: 0),
            WorkoutTemplateItem(exercise: byName["Supermans (Boden-Rueckenstrecken)"] ?? all[0], targetSets: 3, targetReps: 12, targetWeightKg: 0)
        ]

        let fieldItems: [WorkoutTemplateItem] = [
            WorkoutTemplateItem(exercise: byName["Liegestuetze (BWK-konform kontrolliert)"] ?? all[0], targetSets: 4, targetReps: 15, targetWeightKg: 0),
            WorkoutTemplateItem(exercise: byName["Ausfallschritte im Stand (Bodyweight)"] ?? all[0], targetSets: 3, targetReps: 12, targetWeightKg: 0),
            WorkoutTemplateItem(exercise: byName["Glute Bridge am Boden (Beckenheben)"] ?? all[0], targetSets: 3, targetReps: 15, targetWeightKg: 0),
            WorkoutTemplateItem(exercise: byName["Bird-Dog (Vierfuesslerstand)"] ?? all[0], targetSets: 3, targetReps: 12, targetWeightKg: 0),
            WorkoutTemplateItem(exercise: byName["Unterarmstuetz / Plank"] ?? all[0], targetSets: 3, targetReps: 45, targetWeightKg: 0),
            WorkoutTemplateItem(exercise: byName["Kindeshaltung / Prayer Stretch (LWS Dekompression)"] ?? all[0], targetSets: 2, targetReps: 45, targetWeightKg: 0)
        ]

        let expressItems: [WorkoutTemplateItem] = [
            WorkoutTemplateItem(exercise: byName["Bird-Dog (Vierfuesslerstand)"] ?? all[0], targetSets: 3, targetReps: 10, targetWeightKg: 0),
            WorkoutTemplateItem(exercise: byName["Supermans (Boden-Rueckenstrecken)"] ?? all[0], targetSets: 3, targetReps: 10, targetWeightKg: 0),
            WorkoutTemplateItem(exercise: byName["Unterarmstuetz / Plank"] ?? all[0], targetSets: 2, targetReps: 40, targetWeightKg: 0),
            WorkoutTemplateItem(exercise: byName["Kindeshaltung / Prayer Stretch (LWS Dekompression)"] ?? all[0], targetSets: 2, targetReps: 45, targetWeightKg: 0)
        ]

        let hotelItems: [WorkoutTemplateItem] = [
            WorkoutTemplateItem(exercise: byName["Liegestuetze (BWK-konform kontrolliert)"] ?? all[0], targetSets: 3, targetReps: 12, targetWeightKg: 0),
            WorkoutTemplateItem(exercise: byName["Ausfallschritte im Stand (Bodyweight)"] ?? all[0], targetSets: 3, targetReps: 12, targetWeightKg: 0),
            WorkoutTemplateItem(exercise: byName["Glute Bridge am Boden (Beckenheben)"] ?? all[0], targetSets: 3, targetReps: 12, targetWeightKg: 0),
            WorkoutTemplateItem(exercise: byName["Bird-Dog (Vierfuesslerstand)"] ?? all[0], targetSets: 3, targetReps: 12, targetWeightKg: 0),
            WorkoutTemplateItem(exercise: byName["Supermans (Boden-Rueckenstrecken)"] ?? all[0], targetSets: 3, targetReps: 12, targetWeightKg: 0)
        ]

        // 1. Stuben- & Zimmer-Workout (Minimal-Raum, kein Gym)
        let roomWorkoutItems: [WorkoutTemplateItem] = [
            WorkoutTemplateItem(exercise: byName["Stuben Liegestuetze am Schreibtisch / Bett"] ?? all[0], targetSets: 3, targetReps: 12, targetWeightKg: 0),
            WorkoutTemplateItem(exercise: byName["Tuerrahmen Isometrisches Rudern"] ?? all[0], targetSets: 4, targetReps: 12, targetWeightKg: 0),
            WorkoutTemplateItem(exercise: byName["Bettkanten Bulgarian Split Squats"] ?? all[0], targetSets: 3, targetReps: 10, targetWeightKg: 0),
            WorkoutTemplateItem(exercise: byName["Bettkanten Trizeps-Extension (Schulter-sicher)"] ?? all[0], targetSets: 3, targetReps: 12, targetWeightKg: 0),
            WorkoutTemplateItem(exercise: byName["Handtuch-Isometrie Bizepszug"] ?? all[0], targetSets: 3, targetReps: 10, targetWeightKg: 0),
            WorkoutTemplateItem(exercise: byName["Wandsitz Isometrisch (Wall Sit)"] ?? all[0], targetSets: 3, targetReps: 45, targetWeightKg: 0),
            WorkoutTemplateItem(exercise: byName["Teppich Unterarmstuetz (Plank)"] ?? all[0], targetSets: 3, targetReps: 45, targetWeightKg: 0)
        ]

        // 2. Reines Calisthenics Bodyweight-Workout (Keine Gewichte)
        let calisthenicsItems: [WorkoutTemplateItem] = [
            WorkoutTemplateItem(exercise: byName["Klimmzuege im Obergriff (Pull-ups)"] ?? all[0], targetSets: 4, targetReps: 8, targetWeightKg: 0),
            WorkoutTemplateItem(exercise: byName["Barren-Dips (Parallel Bars)"] ?? all[0], targetSets: 3, targetReps: 10, targetWeightKg: 0),
            WorkoutTemplateItem(exercise: byName["Breite Liegestuetze (Wide Grip)"] ?? all[0], targetSets: 3, targetReps: 12, targetWeightKg: 0),
            WorkoutTemplateItem(exercise: byName["Air Squats mit Tempokontrolle (3-1-1-0)"] ?? all[0], targetSets: 4, targetReps: 15, targetWeightKg: 0),
            WorkoutTemplateItem(exercise: byName["Walking Lunges (Dynamische Ausfallschritte)"] ?? all[0], targetSets: 3, targetReps: 16, targetWeightKg: 0),
            WorkoutTemplateItem(exercise: byName["Diamant-Liegestuetze (Calisthenics)"] ?? all[0], targetSets: 3, targetReps: 10, targetWeightKg: 0),
            WorkoutTemplateItem(exercise: byName["Hollow Body Hold (Statisch, BWK-sicher)"] ?? all[0], targetSets: 3, targetReps: 30, targetWeightKg: 0)
        ]

        // 3. Mobility, Dehnung & Aktive Regeneration (Rest Day)
        let mobilityStretchItems: [WorkoutTemplateItem] = [
            WorkoutTemplateItem(exercise: byName["Katze-Kuh Dehnung (Cat-Cow Mobility)"] ?? all[0], targetSets: 3, targetReps: 12, targetWeightKg: 0),
            WorkoutTemplateItem(exercise: byName["Kindeshaltung / Prayer Stretch (LWS Dekompression)"] ?? all[0], targetSets: 3, targetReps: 45, targetWeightKg: 0),
            WorkoutTemplateItem(exercise: byName["World's Greatest Stretch (Huefte & BWS)"] ?? all[0], targetSets: 3, targetReps: 6, targetWeightKg: 0),
            WorkoutTemplateItem(exercise: byName["Kniende Psoas- & Hueftbeugerdehnung"] ?? all[0], targetSets: 3, targetReps: 45, targetWeightKg: 0),
            WorkoutTemplateItem(exercise: byName["Liegende Beinbeugerdehnung mit Handtuch"] ?? all[0], targetSets: 3, targetReps: 45, targetWeightKg: 0),
            WorkoutTemplateItem(exercise: byName["Tauben-Haltung (Pigeon Pose / Piriformis)"] ?? all[0], targetSets: 3, targetReps: 45, targetWeightKg: 0),
            WorkoutTemplateItem(exercise: byName["90/90 Hueftrotations-Mobilisation"] ?? all[0], targetSets: 3, targetReps: 10, targetWeightKg: 0),
            WorkoutTemplateItem(exercise: byName["McGill Big 3 Entlastungs-Sequenz"] ?? all[0], targetSets: 3, targetReps: 30, targetWeightKg: 0)
        ]

        // 4. Stuben-Workout: Sixpack & Liegestuetze (Ohne Geraete)
        let sixpackPushItems: [WorkoutTemplateItem] = [
            WorkoutTemplateItem(exercise: byName["Einarmige Liegestuetze"] ?? all[0], targetSets: 3, targetReps: 10, targetWeightKg: 0, restSeconds: 90),
            WorkoutTemplateItem(exercise: byName["Diamant-Liegestuetze (Calisthenics)"] ?? all[0], targetSets: 4, targetReps: 15, targetWeightKg: 0, restSeconds: 60),
            WorkoutTemplateItem(exercise: byName["Bettkanten Trizeps-Extension (Schulter-sicher)"] ?? all[0], targetSets: 4, targetReps: 12, targetWeightKg: 0, restSeconds: 60),
            WorkoutTemplateItem(exercise: byName["Unterarmstuetz / Plank"] ?? all[0], targetSets: 3, targetReps: 300, targetSeconds: 300, isTimeBased: true, targetWeightKg: 0, restSeconds: 90),
            WorkoutTemplateItem(exercise: byName["Deadbug mit Druck gegen die Knie"] ?? all[0], targetSets: 4, targetReps: 15, targetWeightKg: 0, restSeconds: 30),
            WorkoutTemplateItem(exercise: byName["McGill Modifizierter Curl-Up (Haende unter LWS)"] ?? all[0], targetSets: 4, targetReps: 10, targetSeconds: 10, isTimeBased: true, targetWeightKg: 0, restSeconds: 25),
            WorkoutTemplateItem(exercise: byName["McGill Side Plank (Knie oder Fuesse)"] ?? all[0], targetSets: 4, targetReps: 45, targetSeconds: 45, isTimeBased: true, targetWeightKg: 0, restSeconds: 25)
        ]

        // 5. Stuben-Workout: Core & Lumbale Tiefenstabilität (Olympic Coach Post-25km Triage)
        let coreLwsItems: [WorkoutTemplateItem] = [
            WorkoutTemplateItem(
                exercise: byName["McGill Modifizierter Curl-Up (Haende unter LWS)"] ?? all[0],
                targetSets: 4,
                targetReps: 4,
                targetSeconds: 10,
                isTimeBased: true,
                targetWeightKg: 0,
                restSeconds: 25
            ),
            WorkoutTemplateItem(
                exercise: byName["Deadbug mit Rueckendruck gegen Boden"] ?? byName["Deadbug mit Druck gegen die Knie"] ?? all[0],
                targetSets: 4,
                targetReps: 12,
                targetSeconds: nil,
                isTimeBased: false,
                targetWeightKg: 0,
                restSeconds: 25
            ),
            WorkoutTemplateItem(
                exercise: byName["McGill Side Plank (Knie oder Fuesse)"] ?? all[0],
                targetSets: 4,
                targetReps: 45,
                targetSeconds: 45,
                isTimeBased: true,
                targetWeightKg: 0,
                restSeconds: 25
            ),
            WorkoutTemplateItem(
                exercise: byName["Unterarmstuetz / Plank"] ?? all[0],
                targetSets: 3,
                targetReps: 75,
                targetSeconds: 75,
                isTimeBased: true,
                targetWeightKg: 0,
                restSeconds: 60
            ),
            WorkoutTemplateItem(
                exercise: byName["Glute Bridge am Boden (Beckenheben)"] ?? all[0],
                targetSets: 3,
                targetReps: 15,
                targetSeconds: nil,
                isTimeBased: false,
                targetWeightKg: 0,
                restSeconds: 45
            ),
            WorkoutTemplateItem(
                exercise: byName["Kindeshaltung / Prayer Stretch (LWS Dekompression)"] ?? all[0],
                targetSets: 3,
                targetReps: 60,
                targetSeconds: 60,
                isTimeBased: true,
                targetWeightKg: 0,
                restSeconds: 30
            )
        ]

        return [
            WorkoutTemplate(
                name: "Stuben-Workout: Core & Lumbale Tiefenstabilität",
                folderName: "Fixed Schedule",
                category: "Calisthenics (Stube / Ohne Geraete)",
                summary: "Olympic Coach Triage-Workout: Schont schmerzende Quadrizeps, schmerzenden Nacken/Trapez und ueberlastete autochthone Rueckenstrecker nach 25km Lauf. 100% stützende Rumpf- und Sixpack-Aktivierung: McGill Curl-Up (4x 10s Holds mit LWS-Handunterlage, Nacken entlastet), Deadbug mit LWS-Bodendruck, McGill Side Plank, Hollow-Body Plank (Becken posterior gekippt), Glute Bridge und lumbale Dekompression (Kindeshaltung). Strikt BWK-konform.",
                items: coreLwsItems,
                estimatedMinutes: 38,
                targetTimeSlot: "20:30 - 21:10",
                isBWKRehaFocused: true
            ),
            WorkoutTemplate(
                name: "Stuben-Workout: Sixpack & Liegestuetze (Ohne Geraete)",
                folderName: "Fixed Schedule",
                category: "Calisthenics (Stube / Ohne Geraete)",
                summary: "Intensives Stuben-Workout ohne Geraete (0 kg): Einarmige Liegestuetze, Diamant-Liegestuetze, Bettkanten Trizeps-Extension (schulter-sicher), 5-Minuten-Planks, Deadbugs und McGill Curl-Ups (10s Holds). Voller Rumpf- und Oberkoerper-Fokus, Beine geschont fuer den morgigen Lauf.",
                items: sixpackPushItems,
                estimatedMinutes: 45,
                targetTimeSlot: "19:30 - 20:15",
                isBWKRehaFocused: true
            ),
            WorkoutTemplate(
                name: "Aerobe Grundlagenausdauer (7-20 km Dauerlauf)",
                folderName: "Fixed Schedule",
                category: "Cardio",
                summary: "GA1-Dauerlauf (7 bis max. 20 km) zur mitochondrialen Dichte, Fettstoffwechsel-Optimierung & Sixpack-KFA-Reduktion. Schrittfrequenz ~170-180 spm.",
                items: [
                    WorkoutTemplateItem(exercise: byName["MAF-180 Herzfrequenz-Lauf"] ?? byName["Gelaendelauf / Waldlauf Kaserne"] ?? all[0], targetSets: 1, targetReps: 60, targetWeightKg: 0),
                    WorkoutTemplateItem(exercise: byName["Kindeshaltung / Prayer Stretch (LWS Dekompression)"] ?? all[0], targetSets: 3, targetReps: 45, targetWeightKg: 0)
                ],
                estimatedMinutes: 60,
                targetTimeSlot: "14:00 - 15:30",
                isBWKRehaFocused: true
            ),
            WorkoutTemplate(
                name: "Oberkoerper Kraft & Hypertrophie",
                folderName: "Kraft & Hypertrophie",
                category: "Oberkoerper",
                summary: "Bundeswehr Kraftraum Fokus: Brust, Ruecken, Schultern und Arme.",
                items: upperItems,
                estimatedMinutes: 55,
                targetTimeSlot: "17:00 - 18:00"
            ),
            WorkoutTemplate(
                name: "Unterkoerper & Posterior Chain",
                folderName: "Kraft & Hypertrophie",
                category: "Beine / Gluteus",
                summary: "Beinpresse, Glute Drive und Waden.",
                items: legItems,
                estimatedMinutes: 45,
                targetTimeSlot: "17:00 - 17:45"
            ),
            WorkoutTemplate(
                name: "Stuben- & Zimmer-Workout (Minimal-Raum)",
                folderName: "Calisthenics & Goetter-Module",
                category: "Stube / Zero Gym",
                summary: "Volles Training direkt auf der Stube oder im Hotelzimmer ohne Geraete. Nutzt Tuerrahmen, Bettkante, Stuhl und Teppich.",
                items: roomWorkoutItems,
                estimatedMinutes: 30,
                targetTimeSlot: "17:00 - 17:30",
                isBWKRehaFocused: true
            ),
            WorkoutTemplate(
                name: "Reines Calisthenics Bodyweight-Workout",
                folderName: "Calisthenics & Goetter-Module",
                category: "Calisthenics",
                summary: "100 % freies Koerpergewicht ohne Hanteln oder Maschinen: Klimmzuege, Dips, Liegestuetzvarianten und Tempokontrolle.",
                items: calisthenicsItems,
                estimatedMinutes: 40,
                targetTimeSlot: "17:00 - 17:40",
                isBWKRehaFocused: true
            ),
            WorkoutTemplate(
                name: "Mobility, Dehnung & Aktive Regeneration",
                folderName: "Mobilitaet, Prehab & Dekompression",
                category: "Rest Day / Dehnung",
                summary: "Entlastungs- und Flexibilitaetsprotokoll fuer Pausentage. Dekomprimiert die LWS, oeffnet Hueftbeuger und senkt den Muskeltonus.",
                items: mobilityStretchItems,
                estimatedMinutes: 25,
                targetTimeSlot: "20:00 - 20:25",
                isBWKRehaFocused: true
            ),
            WorkoutTemplate(
                name: "Stube & Kaserne (Minimal-Equipment)",
                folderName: "MilFit & Bundeswehr-Dienstsport",
                category: "Stube / Kurzhanteln",
                summary: "Bodendruecken, einarmiges Rudern, Goblet Squat und Rumpf. Kein Geraetezugang erforderlich.",
                items: barracksItems,
                estimatedMinutes: 40,
                targetTimeSlot: "17:00 - 17:40"
            ),
            WorkoutTemplate(
                name: "Truppenuebungsplatz & Feld (Zero-Equipment)",
                folderName: "MilFit & Bundeswehr-Dienstsport",
                category: "Feld / Bodyweight",
                summary: "100 % Eigengewicht: Liegestuetze, Ausfallschritte, Glute Bridge und Plank. Vollstaendig BWK-sicher.",
                items: fieldItems,
                estimatedMinutes: 30,
                targetTimeSlot: "17:00 - 17:30",
                isBWKRehaFocused: true
            ),
            WorkoutTemplate(
                name: "Express 20 min (Somatic Reset)",
                folderName: "Mobilitaet, Prehab & Dekompression",
                category: "Regeneration",
                summary: "Schnelle Dekompression nach anstrengendem Dienstbetrieb. Sanfte Rumpfaktivierung ohne ZNS-Erschoepfung.",
                items: expressItems,
                estimatedMinutes: 20,
                targetTimeSlot: "17:00 - 17:20",
                isBWKRehaFocused: true
            ),
            WorkoutTemplate(
                name: "Unterwegs & Hotel (Calisthenics)",
                folderName: "Calisthenics & Goetter-Module",
                category: "Reise / Hotel",
                summary: "Ganzkoerper-Erhalt fuer Dienstreisen und Hotelzimmer ohne Sportraum.",
                items: hotelItems,
                estimatedMinutes: 35,
                targetTimeSlot: "17:00 - 17:35"
            ),
            WorkoutTemplate(
                name: "Reha Rumpf & Vagus Balance",
                folderName: "Mobilitaet, Prehab & Dekompression",
                category: "Reha / Stabilisation",
                summary: "BWK Ulm konforme funktionelle Bauchwand- und Beckenboden-Stabilisation.",
                items: rehaItems,
                estimatedMinutes: 35,
                targetTimeSlot: "17:00 - 17:45",
                isBWKRehaFocused: true
            ),
            WorkoutTemplate(
                name: "LWS-Reha & Unterer Ruecken (Biomechanik)",
                folderName: "Mobilitaet, Prehab & Dekompression",
                category: "Unterer Ruecken",
                summary: "Evidenzbasierte Lendenwirbelsaeulen- und Posterior-Chain-Einheit. Staerkt Erector Spinae, dekomprimiert Bandscheiben und schuetzt den Beckenboden.",
                items: lowerBackItems,
                estimatedMinutes: 35,
                targetTimeSlot: "17:00 - 17:35",
                isBWKRehaFocused: true
            ),
            WorkoutTemplate(
                name: "Ganzkoerper Basisplan",
                folderName: "Kraft & Hypertrophie",
                category: "Krafttraining",
                summary: "Ausgewogener Ganzkoerperplan fuer den Regeldienstbetrieb.",
                items: upperItems,
                estimatedMinutes: 50,
                targetTimeSlot: "17:00 - 18:00"
            )
        ]

    }

    public static func seedHistorySessions(exercises: [Exercise]) -> [WorkoutSession] {
        let byName = Dictionary(uniqueKeysWithValues: exercises.map { ($0.name, $0) })
        let cal = Calendar.current

        var comp1 = DateComponents()
        comp1.year = 2025
        comp1.month = 4
        comp1.day = 4
        comp1.hour = 17
        comp1.minute = 15
        let start1 = cal.date(from: comp1) ?? Date()
        let end1 = start1.addingTimeInterval(7440)

        let exList1: [WorkoutExerciseRecord] = [
            WorkoutExerciseRecord(exercise: byName["Incline Bench Press (Schraegbank)"] ?? exercises[0], sets: [
                WorkoutSetRecord(setNumber: 1, weightKg: 27, reps: 8, isCompleted: true, isPR: true),
                WorkoutSetRecord(setNumber: 2, weightKg: 27, reps: 8, isCompleted: true, isPR: true)
            ]),
            WorkoutExerciseRecord(exercise: byName["Butterfly / Pec-Deck"] ?? exercises[1], sets: [
                WorkoutSetRecord(setNumber: 1, weightKg: 70, reps: 8, isCompleted: true, isPR: true),
                WorkoutSetRecord(setNumber: 2, weightKg: 70, reps: 8, isCompleted: true, isPR: true)
            ]),
            WorkoutExerciseRecord(exercise: byName["Bizepscurls (Kurzhanteln)"] ?? exercises[2], sets: [
                WorkoutSetRecord(setNumber: 1, weightKg: 18.5, reps: 6, isCompleted: true, isPR: true),
                WorkoutSetRecord(setNumber: 2, weightKg: 18.5, reps: 6, isCompleted: true, isPR: true)
            ]),
            WorkoutExerciseRecord(exercise: byName["Trizepsdruecken am Seil (Neunstoeckig)"] ?? exercises[3], sets: [
                WorkoutSetRecord(setNumber: 1, weightKg: 40, reps: 8, isCompleted: true, isPR: true),
                WorkoutSetRecord(setNumber: 2, weightKg: 40, reps: 8, isCompleted: true, isPR: true)
            ]),
            WorkoutExerciseRecord(exercise: byName["Latzug zur Brust (breit)"] ?? exercises[4], sets: [
                WorkoutSetRecord(setNumber: 1, weightKg: 75, reps: 10, isCompleted: true, isPR: true),
                WorkoutSetRecord(setNumber: 2, weightKg: 75, reps: 10, isCompleted: true, isPR: true)
            ]),
            WorkoutExerciseRecord(exercise: byName["Schulterdruecken (Maschine)"] ?? exercises[5], sets: [
                WorkoutSetRecord(setNumber: 1, weightKg: 50, reps: 10, isCompleted: true, isPR: false),
                WorkoutSetRecord(setNumber: 2, weightKg: 50, reps: 10, isCompleted: true, isPR: false)
            ])
        ]

        let session1 = WorkoutSession(
            title: "Oberkoerper Bundeswehr",
            startTime: start1,
            endTime: end1,
            exercises: exList1,
            perceivedExertionRPE: 7,
            somaticNotes: "Kraftraum Einheit absolviert. Reha-Vorgaben stabil eingehalten.",
            estimatedCaloriesBurned: 520,
            prCount: 8,
            isSyncedToCalendar: true,
            isSyncedToHealthKit: true
        )

        return [session1]
    }

    public static func seedMeasurements() -> [BodyMeasurementEntry] {
        return [
            BodyMeasurementEntry(type: .weight, value: 78.5),
            BodyMeasurementEntry(type: .bodyFat, value: 13.8),
            BodyMeasurementEntry(type: .caloricIntake, value: 1950),
            BodyMeasurementEntry(type: .neck, value: 39.5),
            BodyMeasurementEntry(type: .shoulders, value: 122.0),
            BodyMeasurementEntry(type: .chest, value: 104.5),
            BodyMeasurementEntry(type: .leftBicep, value: 38.0),
            BodyMeasurementEntry(type: .rightBicep, value: 38.5),
            BodyMeasurementEntry(type: .leftForearm, value: 30.5),
            BodyMeasurementEntry(type: .rightForearm, value: 31.0),
            BodyMeasurementEntry(type: .upperAbs, value: 81.0),
            BodyMeasurementEntry(type: .waist, value: 82.0),
            BodyMeasurementEntry(type: .lowerAbs, value: 84.0),
            BodyMeasurementEntry(type: .hips, value: 96.0)
        ]
    }
}
