import Foundation

public struct ProgramCatalogSeed {
    public static func defaultPrograms() -> [TrainingProgram] {
        return calisthenicsPrograms() + aestheticPrograms() + runningPrograms() + roomCalisthenicsPrograms()
    }

    // MARK: - 1. Calisthenics Disziplin-Block (5 Programme x 5 Workouts = 25 Workouts)
    public static func calisthenicsPrograms() -> [TrainingProgram] {
        return [
            // Calisthenics Programm 1: Apoll
            TrainingProgram(
                name: "Apoll",
                block: .calisthenicsGoetter,
                summary: "Gezielte neuromuskulaere Aktivierung und Hypertrophie der Rhomboiden, des mittleren/unteren Trapezius und des Serratus Anterior. Beseitigt Scapular Winging und obere Rueckenschwaeche.",
                methodology: "Jeff Nippard & Kelly Starrett Scapular-Protokoll",
                cycleType: .cyclicalRolling,
                totalWeeks: 6,
                targetDurationText: "6 Wochen (5 Workouts/Woche)",
                daysPerWeek: 5,
                difficulty: "Fortgeschritten",
                isBWKCoreCompliant: true,
                calisthenicArchetype: .apollo,
                phases: [
                    ProgramPhase(
                        phaseNumber: 1,
                        name: "Skapulaere Stabilisation & Hypertrophie",
                        focus: "Retraktion, Depression und Serratus-Aktivierung",
                        weeks: [
                            ProgramWeek(
                                weekNumber: 1,
                                title: "Woche 1: Basis-Spannung & Retraktion",
                                focus: "Saubere Ansteuerung ohne Schwung",
                                sessions: [
                                    ProgramSession(
                                        dayNumber: 1,
                                        title: "Scapular Pull & Rows",
                                        summary: "Fokus auf maximale Retraktion der Schulterblaetter am obersten Umkehrpunkt.",
                                        exercises: [
                                            ProgramExerciseItem(name: "Australische Ruderzuege (Inverted Rows)", targetSets: 4, targetReps: "10-12", rpeTarget: "RIR 2", restSeconds: 90, techniqueNotes: "Brust zur Stange ziehen, Schulterblaetter hinten aktiv zusammenpressen.", isBWKCoreRehaSafe: true),
                                            ProgramExerciseItem(name: "Scapular Pull-Ups (Stangenzug ohne Armbeugung)", targetSets: 4, targetReps: "8-10", rpeTarget: "RIR 2", restSeconds: 75, techniqueNotes: "Arme gestreckt halten. Nur Schulterblaetter nach unten und hinten ziehen.", isBWKCoreRehaSafe: true),
                                            ProgramExerciseItem(name: "Passive Bar Hang (Ausklingen mit Bauchspannung)", targetSets: 3, targetReps: "30-45s", rpeTarget: "RIR 1", restSeconds: 60, techniqueNotes: "Dekompression der BWS/LWS bei gleichzeitig aktivem Beckenboden.", isBWKCoreRehaSafe: true)
                                        ]
                                    ),
                                    ProgramSession(
                                        dayNumber: 2,
                                        title: "Serratus & Push-Up Plus",
                                        summary: "Staerkt den Serratus Anterior zur optimalen Fixierung des Schulterblatts am Brustkorb.",
                                        exercises: [
                                            ProgramExerciseItem(name: "Serratus Wall-Slides mit Miniband", targetSets: 4, targetReps: "12-15", rpeTarget: "RIR 2", restSeconds: 60, techniqueNotes: "Unterarme an der Wand hochgleiten lassen, Schulterblaetter proaktiv nach vorne schieben.", isBWKCoreRehaSafe: true),
                                            ProgramExerciseItem(name: "Push-Up Plus (Liegestuetz mit Scapular-Protraktion)", targetSets: 4, targetReps: "10-12", rpeTarget: "RIR 2", restSeconds: 75, techniqueNotes: "Oben angekommen den oberen Ruecken aktiv rund machen und rausdruecken.", isBWKCoreRehaSafe: true),
                                            ProgramExerciseItem(name: "Plank to Downward Dog Progression", targetSets: 3, targetReps: "8-10", rpeTarget: "RIR 2", restSeconds: 60, techniqueNotes: "Fliessender Uebergang zur Dehnung der Rueckseite und Aktivierung der Skapula.", isBWKCoreRehaSafe: true)
                                        ]
                                    ),
                                    ProgramSession(
                                        dayNumber: 3,
                                        title: "Y-T-W-L & Door Rows",
                                        summary: "Isolierte Staerkung der tiefen Skapulamuskeln in Bauchlage.",
                                        exercises: [
                                            ProgramExerciseItem(name: "Prone Y-T-W-L Sequenz (Bauchlage Matte)", targetSets: 3, targetReps: "8 pro Buchstabe", rpeTarget: "RIR 1", restSeconds: 90, techniqueNotes: "Daumen nach oben zur Decke. Bewegung kommt rein aus den Schulterblaettern.", isBWKCoreRehaSafe: true),
                                            ProgramExerciseItem(name: "Tuerrahmen-Ruderzuege einarmig (Kasernen-Setup)", targetSets: 4, targetReps: "10-12", rpeTarget: "RIR 2", restSeconds: 60, techniqueNotes: "Schulterblatt der arbeitenden Seite maximal nach hinten fuehren.", isBWKCoreRehaSafe: true),
                                            ProgramExerciseItem(name: "Bird-Dog mit 3s Scapular-Squeeze", targetSets: 3, targetReps: "10 pro Seite", rpeTarget: "RIR 2", restSeconds: 60, techniqueNotes: "Keine Beckenkippung. Diagonalen Arm und Bein strecken, Ruecken neutral.", isBWKCoreRehaSafe: true)
                                        ]
                                    ),
                                    ProgramSession(
                                        dayNumber: 4,
                                        title: "Facepulls & Rotators",
                                        summary: "Kombination aus oberer Rueckendichte und Stabilitaet der Rotatorenmanschette.",
                                        exercises: [
                                            ProgramExerciseItem(name: "Turnring-Facepulls mit Daumen nach hinten", targetSets: 4, targetReps: "12-15", rpeTarget: "RIR 2", restSeconds: 90, techniqueNotes: "Ringe zur Stirn fuehren und Haende nach hinten aufdrehen.", isBWKCoreRehaSafe: true),
                                            ProgramExerciseItem(name: "Band-Aussenrotation im 90-Grad-Winkel", targetSets: 3, targetReps: "15", rpeTarget: "RIR 2", restSeconds: 60, techniqueNotes: "Ellenbogen am Koerper fixieren, saubere Rotatorenbelastung.", isBWKCoreRehaSafe: true),
                                            ProgramExerciseItem(name: "Doorway Chest Stretch (Sanfte Pectoralis-Dehnung)", targetSets: 3, targetReps: "30s pro Seite", rpeTarget: "RIR 3", restSeconds: 45, techniqueNotes: "Oeffnet die Brustmuskulatur, um Vorwaertszug der Schultern zu beseitigen.", isBWKCoreRehaSafe: true)
                                        ]
                                    ),
                                    ProgramSession(
                                        dayNumber: 5,
                                        title: "Scapular Dips & Bands",
                                        summary: "Abschluss-Reiz fuer Unteren Trapezius und Schulterblatt-Depression.",
                                        exercises: [
                                            ProgramExerciseItem(name: "Scapular Dips am Barren (Nur Schulterabsenkung)", targetSets: 4, targetReps: "10-12", rpeTarget: "RIR 2", restSeconds: 75, techniqueNotes: "Arme gestreckt halten, Koerper aus den Schultern hochdruecken.", isBWKCoreRehaSafe: true),
                                            ProgramExerciseItem(name: "Banded Pull-Aparts auf Brusthoehe", targetSets: 4, targetReps: "20", rpeTarget: "RIR 1", restSeconds: 60, techniqueNotes: "Band zur Brust ziehen, Schulterblaetter hinten maximal beruehren.", isBWKCoreRehaSafe: true),
                                            ProgramExerciseItem(name: "Active Hang mit Schulterretraktion", targetSets: 3, targetReps: "30s", rpeTarget: "RIR 2", restSeconds: 60, techniqueNotes: "Aktiv die Schultern von den Ohren wegziehen.", isBWKCoreRehaSafe: true)
                                        ]
                                    )
                                ]
                            )
                        ]
                    )
                ]
            ),

            // Calisthenics Programm 2: Prometheus
            TrainingProgram(
                name: "Prometheus",
                block: .calisthenicsGoetter,
                summary: "Biomechanisch optimiert gegen Flankenschmerzen, Iliosakralgelenk-Blockaden (ISG) und Piriformis-Dysbalancen. Strikte BWK Ulm Reha-Doktrin ohne dynamische Wirbelsaeulenbeugung.",
                methodology: "McGill Big 3 & BWK Ulm Viszeral-Schutz",
                cycleType: .cyclicalRolling,
                totalWeeks: 6,
                targetDurationText: "6 Wochen (5 Workouts/Woche)",
                daysPerWeek: 5,
                difficulty: "Anfaenger bis Mittel",
                isBWKCoreCompliant: true,
                calisthenicArchetype: .prometheus,
                phases: [
                    ProgramPhase(
                        phaseNumber: 1,
                        name: "Lumbo-Pelvine Stabilisation & Dekompression",
                        focus: "Gluteus Medius, QL-Entlastung und ISG-Sicherung",
                        weeks: [
                            ProgramWeek(
                                weekNumber: 1,
                                title: "Woche 1: Fundamentale Rumpf-Zuggurtung",
                                focus: "Schmerzreduktion und isometrische Rumpfkontrolle",
                                sessions: [
                                    ProgramSession(
                                        dayNumber: 1,
                                        title: "McGill Big 3",
                                        summary: "Isometrische Rumpfstabilisation ohne Erhoehung des intraabdominalen Drucks.",
                                        exercises: [
                                            ProgramExerciseItem(name: "McGill Modifizierter Curl-Up (Haende unter LWS)", targetSets: 4, targetReps: "6x 8s Hold", rpeTarget: "RIR 2", restSeconds: 60, techniqueNotes: "Nur Kopf und Schulterguertel minimal anheben, LWS bleibt voellig neutral.", isBWKCoreRehaSafe: true),
                                            ProgramExerciseItem(name: "McGill Bird-Dog mit neutralem Becken", targetSets: 4, targetReps: "6x 8s Hold pro Seite", rpeTarget: "RIR 2", restSeconds: 60, techniqueNotes: "Bauch aktiv einziehen, kein Durchhaengen im Lendenbereich.", isBWKCoreRehaSafe: true),
                                            ProgramExerciseItem(name: "McGill Side Plank (Knie oder Fuesse)", targetSets: 3, targetReps: "4x 8s Hold pro Seite", rpeTarget: "RIR 2", restSeconds: 60, techniqueNotes: "Kopplung von Gluteus Medius und Quadratus Lumborum.", isBWKCoreRehaSafe: true)
                                        ]
                                    ),
                                    ProgramSession(
                                        dayNumber: 2,
                                        title: "Glute & Piriformis",
                                        summary: "Loest Spannungen an den lateralen Hueften und im Bereich zwischen Kreuzbein und Gesaess.",
                                        exercises: [
                                            ProgramExerciseItem(name: "Seitliches Beinheben (Side-Lying Hip Abduction)", targetSets: 4, targetReps: "15 pro Seite", rpeTarget: "RIR 2", restSeconds: 60, techniqueNotes: "Ferse leicht nach oben und hinten drehen, um isoliert Gluteus Medius zu treffen.", isBWKCoreRehaSafe: true),
                                            ProgramExerciseItem(name: "Clamshells mit Miniband", targetSets: 4, targetReps: "15 pro Seite", rpeTarget: "RIR 2", restSeconds: 60, techniqueNotes: "Becken bleibt exakt senkrecht, kein Nach-Hinten-Kippen.", isBWKCoreRehaSafe: true),
                                            ProgramExerciseItem(name: "Sitzendes Piriformis-Flossing (Sanfte Mobilisation)", targetSets: 3, targetReps: "10 Bewegungen pro Seite", rpeTarget: "RIR 3", restSeconds: 60, techniqueNotes: "Ischiasnerv sanft gleiten lassen, schmerzfreier Bereich.", isBWKCoreRehaSafe: true)
                                        ]
                                    ),
                                    ProgramSession(
                                        dayNumber: 3,
                                        title: "Bridge & Deadbug",
                                        summary: "Staerkt die hintere Muskelkette und transversale Rumpfwand ohne Wirbelsaeulenlast.",
                                        exercises: [
                                            ProgramExerciseItem(name: "Einbeinige Glute Bridge mit 3s Peak Hold", targetSets: 4, targetReps: "10 pro Seite", rpeTarget: "RIR 2", restSeconds: 75, techniqueNotes: "Vollstaendige Hueftstreckung aus dem Gesaessmuskel, nicht aus der LWS.", isBWKCoreRehaSafe: true),
                                            ProgramExerciseItem(name: "Deadbug mit Rueckendruck gegen Boden", targetSets: 4, targetReps: "8 pro Seite", rpeTarget: "RIR 2", restSeconds: 60, techniqueNotes: "Bauchnabel fest nach innen saugen, LWS hat stetigen Bodenkontakt.", isBWKCoreRehaSafe: true),
                                            ProgramExerciseItem(name: "Frosch-Gesaessbruecke (Froggers)", targetSets: 3, targetReps: "15", rpeTarget: "RIR 2", restSeconds: 60, techniqueNotes: "Fusssohlen zusammen, maximale externe Gesaesskontraktion.", isBWKCoreRehaSafe: true)
                                        ]
                                    ),
                                    ProgramSession(
                                        dayNumber: 4,
                                        title: "Suitcase Carry & QL",
                                        summary: "Beseitigt einseitige Zuege im Quadratus Lumborum und stabilisiert das Becken.",
                                        exercises: [
                                            ProgramExerciseItem(name: "Koffer-Tragen auf Stube (Suitcase Carry mit Rucksack)", targetSets: 4, targetReps: "60s pro Seite", rpeTarget: "RIR 2", restSeconds: 60, techniqueNotes: "Oberkoerper absolut aufrecht, keine seitliche Ausweichbewegung.", isBWKCoreRehaSafe: true),
                                            ProgramExerciseItem(name: "Copenhagen Plank (Knie auf Stuhl/Bett)", targetSets: 3, targetReps: "20s pro Seite", rpeTarget: "RIR 2", restSeconds: 60, techniqueNotes: "Aktiviert Adduktoren und schliesst das Becken seitlich ab.", isBWKCoreRehaSafe: true),
                                            ProgramExerciseItem(name: "Sanfter QL-Dehnungs-Reach in Rueckenlage", targetSets: 3, targetReps: "30s pro Seite", rpeTarget: "RIR 3", restSeconds: 45, techniqueNotes: "Laenge in der Flanke zwischen Rippen und Beckenkamm erzeugen.", isBWKCoreRehaSafe: true)
                                        ]
                                    ),
                                    ProgramSession(
                                        dayNumber: 5,
                                        title: "Pallof-Press & Reha",
                                        summary: "Schliesst die Woche mit kontrollierter Tiefenspannung ab.",
                                        exercises: [
                                            ProgramExerciseItem(name: "Pallof-Press mit Widerstandsband am Tueranker", targetSets: 4, targetReps: "12 mit 2s Hold", rpeTarget: "RIR 2", restSeconds: 60, techniqueNotes: "Anti-Rotation. Becken und Schultern parallel zur Wand halten.", isBWKCoreRehaSafe: true),
                                            ProgramExerciseItem(name: "Beckenboden-Aktivierung im Vierfueszler", targetSets: 3, targetReps: "10 Atemzyklen", rpeTarget: "RIR 3", restSeconds: 45, techniqueNotes: "Sanftes Anheben bei Ausatmung gemaess BWK-Ulm Standard.", isBWKCoreRehaSafe: true),
                                            ProgramExerciseItem(name: "Child's Pose mit tiefer Flankenatmung", targetSets: 2, targetReps: "60s", rpeTarget: "RIR 3", restSeconds: 45, techniqueNotes: "Entspannt die Rueckenstrecker und oeffnet das ISG.", isBWKCoreRehaSafe: true)
                                        ]
                                    )
                                ]
                            )
                        ]
                    )
                ]
            ),

            // Calisthenics Programm 3: Zeus
            TrainingProgram(
                name: "Zeus",
                block: .calisthenicsGoetter,
                summary: "Hypertrophie und Maximalkraft mit eigenem Koerpergewicht an Stangen und Ringen. Erfordert hohe Tiefenstabilitaet.",
                methodology: "Freeletics & Russische Turner-Methodik",
                cycleType: .cyclicalRolling,
                totalWeeks: 8,
                targetDurationText: "8 Wochen (5 Workouts/Woche)",
                daysPerWeek: 5,
                difficulty: "Fortgeschritten",
                isBWKCoreCompliant: true,
                calisthenicArchetype: .zeus,
                phases: [
                    ProgramPhase(
                        phaseNumber: 1,
                        name: "Relative Kraft & Oberkoerper-Masse",
                        focus: "Dips, Klimmzuege und statische Haltekraft",
                        weeks: [
                            ProgramWeek(
                                weekNumber: 1,
                                title: "Woche 1: Kraftaufbau an Holmen & Stange",
                                focus: "Saubere Range of Motion ohne Kipping",
                                sessions: [
                                    ProgramSession(dayNumber: 1, title: "Dips & Pike Push-Ups", summary: "Brust-, Schulter- und Trizeps-Fokus.", exercises: [
                                        ProgramExerciseItem(name: "Barren-Dips (Paralleles Dip-Geraet)", targetSets: 4, targetReps: "8-10", rpeTarget: "RIR 2", restSeconds: 90, techniqueNotes: "Leicht nach vorne beugen fuer Brustfokus, volle Tiefe.", isBWKCoreRehaSafe: true),
                                        ProgramExerciseItem(name: "Pike Push-Ups mit erhoehten Fuessen", targetSets: 4, targetReps: "8-10", rpeTarget: "RIR 2", restSeconds: 90, techniqueNotes: "V-Position, Kopf vor den Haenden absenken.", isBWKCoreRehaSafe: true),
                                        ProgramExerciseItem(name: "Diamant-Liegestuetz auf Knien oder Zehen", targetSets: 3, targetReps: "10-12", rpeTarget: "RIR 1", restSeconds: 60, techniqueNotes: "Fokus auf Trizepskontraktion.", isBWKCoreRehaSafe: true)
                                    ]),
                                    ProgramSession(dayNumber: 2, title: "Pull-Ups & Negatives", summary: "Latissimus- und Skapular-Zugkraft.", exercises: [
                                        ProgramExerciseItem(name: "Klimmzuege im Obergriff (Proniert)", targetSets: 4, targetReps: "6-8", rpeTarget: "RIR 2", restSeconds: 120, techniqueNotes: "Aus dem Dead-Hang starten, Kinn ueber die Stange.", isBWKCoreRehaSafe: true),
                                        ProgramExerciseItem(name: "Negative Klimmzuege (5s Absenken)", targetSets: 3, targetReps: "5", rpeTarget: "RIR 1", restSeconds: 90, techniqueNotes: "Oben anspringen und ultra-langsam exzentrisch ablassen.", isBWKCoreRehaSafe: true),
                                        ProgramExerciseItem(name: "Klimmzug-Halten im 90-Grad-Winkel", targetSets: 3, targetReps: "20s", rpeTarget: "RIR 1", restSeconds: 60, techniqueNotes: "Isometrische Bizeps- und Lat-Spannung.", isBWKCoreRehaSafe: true)
                                    ]),
                                    ProgramSession(dayNumber: 3, title: "Sissy Squats & Calves", summary: "Unterkoerper-Hypertrophie ohne Rueckenstauchung.", exercises: [
                                        ProgramExerciseItem(name: "Sissy Squats mit Festhalten", targetSets: 4, targetReps: "10-12", rpeTarget: "RIR 2", restSeconds: 75, techniqueNotes: "Knie weit nach vorne schieben, Huefte gestreckt halten (Quad-Fokus).", isBWKCoreRehaSafe: true),
                                        ProgramExerciseItem(name: "Einbeinige Wadenheben an Stufe", targetSets: 4, targetReps: "15 pro Seite", rpeTarget: "RIR 1", restSeconds: 60, techniqueNotes: "2s Dehnung unten, 1s Peak Contraction oben.", isBWKCoreRehaSafe: true),
                                        ProgramExerciseItem(name: "Wall Sit mit geradem Ruecken", targetSets: 3, targetReps: "45s", rpeTarget: "RIR 1", restSeconds: 60, techniqueNotes: "90 Grad im Kniegelenk, Ruecken an die Wand gepresst.", isBWKCoreRehaSafe: true)
                                    ]),
                                    ProgramSession(dayNumber: 4, title: "Ring Push-Ups & Hollow", summary: "Instabilitaetsschulung an Turnringen mit Rumpffixierung.", exercises: [
                                        ProgramExerciseItem(name: "Liegestuetz an Turnringen", targetSets: 4, targetReps: "10-12", rpeTarget: "RIR 2", restSeconds: 90, techniqueNotes: "Ringe oben leicht nach aussen aufdrehen.", isBWKCoreRehaSafe: true),
                                        ProgramExerciseItem(name: "Hollow Body Hold (Schiffchen mit gebeugten Knien)", targetSets: 4, targetReps: "30s", rpeTarget: "RIR 2", restSeconds: 60, techniqueNotes: "LWS flach in den Boden druecken, Bauch brennt.", isBWKCoreRehaSafe: true),
                                        ProgramExerciseItem(name: "Ring Dips Support Hold", targetSets: 3, targetReps: "25s", rpeTarget: "RIR 2", restSeconds: 60, techniqueNotes: "Ringe am Koerper halten, Schultern stabilisieren.", isBWKCoreRehaSafe: true)
                                    ]),
                                    ProgramSession(dayNumber: 5, title: "Archer Rows & L-Sit", summary: "Asymmetrische Zugkraft und Hueftbeuger-Tiefenrumpf.", exercises: [
                                        ProgramExerciseItem(name: "Archer Rows an Stange oder Ringen", targetSets: 4, targetReps: "6-8 pro Seite", rpeTarget: "RIR 2", restSeconds: 90, techniqueNotes: "Ein Arm zieht gebeugt, der andere bleibt fast gestreckt.", isBWKCoreRehaSafe: true),
                                        ProgramExerciseItem(name: "Tuck L-Sit auf Parallettes oder Stuehlen", targetSets: 4, targetReps: "15-20s", rpeTarget: "RIR 1", restSeconds: 75, techniqueNotes: "Knie an die Brust ziehen, Schultern nach unten druecken.", isBWKCoreRehaSafe: true),
                                        ProgramExerciseItem(name: "Ausfallschritte im Rueckwaertsgang", targetSets: 3, targetReps: "12 pro Seite", rpeTarget: "RIR 2", restSeconds: 60, techniqueNotes: "Schont die Knie und aktiviert den Gluteus.", isBWKCoreRehaSafe: true)
                                    ])
                                ]
                            )
                        ]
                    )
                ]
            ),

            // Calisthenics Programm 4: MilFit Tactical
            TrainingProgram(
                name: "MilFit Tactical",
                block: .calisthenicsGoetter,
                summary: "Optimaler Stuben-Trainingsplan fuer Bundeswehr-Soldaten. Maximale Ausbeute auf engstem Raum ohne Gewichte.",
                methodology: "Bundeswehr ZDv 3/10 & Navy SEAL Bodyweight",
                cycleType: .cyclicalRolling,
                totalWeeks: 6,
                targetDurationText: "6 Wochen (5 Workouts/Woche)",
                daysPerWeek: 5,
                difficulty: "Mittel",
                isBWKCoreCompliant: true,
                calisthenicArchetype: .ares,
                phases: [
                    ProgramPhase(
                        phaseNumber: 1,
                        name: "Diensttaugliche Grundfitness",
                        focus: "Kraftausdauer, Stoßkraft und Rumpfpanzerung",
                        weeks: [
                            ProgramWeek(
                                weekNumber: 1,
                                title: "Woche 1: BFT-spezifische Grundlagen",
                                focus: "Wiederholungszahlen und Haltekraft",
                                sessions: [
                                    ProgramSession(dayNumber: 1, title: "BFT Push-Up Pyramide", summary: "Pyramidentraining zur Steigerung der Wiederholungen.", exercises: [
                                        ProgramExerciseItem(name: "Standard-Liegestuetz (Tempo 2-0-1)", targetSets: 5, targetReps: "15-20", rpeTarget: "RIR 2", restSeconds: 60, techniqueNotes: "Vollstaendige Streckung, Brust beruehrt fast den Boden.", isBWKCoreRehaSafe: true),
                                        ProgramExerciseItem(name: "Kniebeugen mit 2s Pause unten (Air Squats)", targetSets: 4, targetReps: "20", rpeTarget: "RIR 2", restSeconds: 60, techniqueNotes: "Fersen am Boden, Knie folgen den Zehen.", isBWKCoreRehaSafe: true),
                                        ProgramExerciseItem(name: "Plank im Liegestuetz-Stellungswechsel", targetSets: 3, targetReps: "10 Wechsel", rpeTarget: "RIR 2", restSeconds: 60, techniqueNotes: "Becken bleibt absolut waagerecht.", isBWKCoreRehaSafe: true)
                                    ]),
                                    ProgramSession(dayNumber: 2, title: "Klimmhang & Griffkraft", summary: "Spezifisch fuer den BFT Klimmhang-Test.", exercises: [
                                        ProgramExerciseItem(name: "Isometrischer Klimmhang (Kinn ueber Stange)", targetSets: 4, targetReps: "Maximalzeit (Ziel >45s)", rpeTarget: "RIR 0", restSeconds: 120, techniqueNotes: "Untergriff, Schultern aktiv heruntergezogen.", isBWKCoreRehaSafe: true),
                                        ProgramExerciseItem(name: "Handtuch-Hangs (Handtuch ueber Stange geworfen)", targetSets: 3, targetReps: "25-35s", rpeTarget: "RIR 1", restSeconds: 90, techniqueNotes: "Extreme Schulung der Unterarmflexoren.", isBWKCoreRehaSafe: true),
                                        ProgramExerciseItem(name: "Doorframe Rows (Tuerrahmen-Rudern)", targetSets: 4, targetReps: "12 pro Seite", rpeTarget: "RIR 2", restSeconds: 60, techniqueNotes: "Fuehrt den Ellbogen eng am Rumpf vorbei.", isBWKCoreRehaSafe: true)
                                    ]),
                                    ProgramSession(dayNumber: 3, title: "Beinachse & Agilitaet", summary: "Schuetzt Knie und Hueften bei Maerschen und Gelaendeläufen.", exercises: [
                                        ProgramExerciseItem(name: "Bulgarische Split Squats mit Stuhl", targetSets: 4, targetReps: "10 pro Seite", rpeTarget: "RIR 2", restSeconds: 75, techniqueNotes: "Hinterer Fuss auf Stuhl, Vorderfuss stabil.", isBWKCoreRehaSafe: true),
                                        ProgramExerciseItem(name: "Einbeiniges Standwaage-Halten", targetSets: 3, targetReps: "30s pro Seite", rpeTarget: "RIR 2", restSeconds: 60, techniqueNotes: "Staerkt Fussgewoelbe und Gluteus Medius.", isBWKCoreRehaSafe: true),
                                        ProgramExerciseItem(name: "Wadenheben beidbeinig mit Gewichtsweste/Rucksack", targetSets: 4, targetReps: "20", rpeTarget: "RIR 1", restSeconds: 60, techniqueNotes: "Praevention von Schienbeinkantensyndrom (Shin Splints).", isBWKCoreRehaSafe: true)
                                    ]),
                                    ProgramSession(dayNumber: 4, title: "Schulter & Rueckenausdauer", summary: "Verhindert Ermuedung beim Tragen von Rucksack und Weste.", exercises: [
                                        ProgramExerciseItem(name: "Pike Push-Ups am Bettkasten", targetSets: 4, targetReps: "10", rpeTarget: "RIR 2", restSeconds: 75, techniqueNotes: "Saubere Schulterbelastung.", isBWKCoreRehaSafe: true),
                                        ProgramExerciseItem(name: "Banded Face-Pulls an Schrankgriff verankert", targetSets: 4, targetReps: "20", rpeTarget: "RIR 1", restSeconds: 60, techniqueNotes: "Daumen zeigen am Ende nach hinten.", isBWKCoreRehaSafe: true),
                                        ProgramExerciseItem(name: "Prone Cobra (Bauchlage Schulterblatt-Retraktion)", targetSets: 3, targetReps: "45s Hold", rpeTarget: "RIR 2", restSeconds: 60, techniqueNotes: "Arme neben Koerper, Handflaechen nach aussen gedreht.", isBWKCoreRehaSafe: true)
                                    ]),
                                    ProgramSession(dayNumber: 5, title: "Marsch & Kernstabilitaet", summary: "Rumpfkontrolle unter statischer Dauerlast.", exercises: [
                                        ProgramExerciseItem(name: "Rucksack-Suitcase Carry auf Stube", targetSets: 4, targetReps: "60s pro Seite", rpeTarget: "RIR 2", restSeconds: 60, techniqueNotes: "Gefaelltes Gewicht im Rucksack einseitig tragen.", isBWKCoreRehaSafe: true),
                                        ProgramExerciseItem(name: "Unterarmstuetz (Plank) mit Vor- und Zurueckwippen", targetSets: 4, targetReps: "40s", rpeTarget: "RIR 2", restSeconds: 60, techniqueNotes: "Bauch und Gesaess maximal angespannt.", isBWKCoreRehaSafe: true),
                                        ProgramExerciseItem(name: "Hueftbeuger-Dehnung im Halbknien", targetSets: 3, targetReps: "45s pro Seite", rpeTarget: "RIR 3", restSeconds: 45, techniqueNotes: "Gesaess anspannen, um den Psoas aufzudehnen.", isBWKCoreRehaSafe: true)
                                    ])
                                ]
                            )
                        ]
                    )
                ]
            ),

            // Calisthenics Programm 5: Hermes
            TrainingProgram(
                name: "Hermes",
                block: .calisthenicsGoetter,
                summary: "Gezielte Schmerzreduktion, Gelenkschmiere und Dekompression fuer LWS, Becken und Schulterguertel.",
                methodology: "Dr. Kelly Starrett & Somatische Dekompression",
                cycleType: .cyclicalRolling,
                totalWeeks: 4,
                targetDurationText: "4 Wochen (5 Workouts/Woche)",
                daysPerWeek: 5,
                difficulty: "Anfaenger",
                isBWKCoreCompliant: true,
                calisthenicArchetype: .hermes,
                phases: [
                    ProgramPhase(
                        phaseNumber: 1,
                        name: "Gelenk- & Faszien-Reset",
                        focus: "Schmerzfreie Mobilitaet und Vagusnerv-Aktivierung",
                        weeks: [
                            ProgramWeek(
                                weekNumber: 1,
                                title: "Woche 1: Entlastung der Schmerzachsen",
                                focus: "Flanken, Huefte und BWS",
                                sessions: [
                                    ProgramSession(dayNumber: 1, title: "Piriformis Release", summary: "Entlastet Nervenbahnen und Loest Verspannungen am Kreuzbein.", exercises: [
                                        ProgramExerciseItem(name: "Sitzende Piriformis-Dehnung auf Stuhl", targetSets: 3, targetReps: "60s pro Seite", rpeTarget: "RIR 3", restSeconds: 45, techniqueNotes: "Knoechel auf Knie legen, gerader Oberkoerper nach vorne neigen.", isBWKCoreRehaSafe: true),
                                        ProgramExerciseItem(name: "Liegende 90/90 Hueft-Rotation", targetSets: 3, targetReps: "10 Wechsel", rpeTarget: "RIR 3", restSeconds: 45, techniqueNotes: "Knie kontrolliert von Seite zu Seite kippen.", isBWKCoreRehaSafe: true),
                                        ProgramExerciseItem(name: "Beckenkippen in Rueckenlage (Pelvic Tilts)", targetSets: 3, targetReps: "15", rpeTarget: "RIR 3", restSeconds: 45, techniqueNotes: "Sanftes Vor- und Zurueckrollen des Beckens.", isBWKCoreRehaSafe: true)
                                    ]),
                                    ProgramSession(dayNumber: 2, title: "BWS Mobilisation", summary: "Befreit die Brustwirbelsaeule und laesst die Schulterblaetter gleiten.", exercises: [
                                        ProgramExerciseItem(name: "Open-Book Mobilisation in Seitenlage", targetSets: 3, targetReps: "10 pro Seite", rpeTarget: "RIR 3", restSeconds: 45, techniqueNotes: "Oberen Arm weit nach hinten aufdrehen, Blick folgt der Hand.", isBWKCoreRehaSafe: true),
                                        ProgramExerciseItem(name: "Latissimus-Dehnung an Tuerrahmen", targetSets: 3, targetReps: "45s pro Seite", rpeTarget: "RIR 3", restSeconds: 45, techniqueNotes: "Tuerrahmen greifen, Huefte nach hinten schieben, Flanke oeffnen.", isBWKCoreRehaSafe: true),
                                        ProgramExerciseItem(name: "Katze-Kuh im Vierfueszler (Sanft)", targetSets: 3, targetReps: "10 Zyklen", rpeTarget: "RIR 3", restSeconds: 45, techniqueNotes: "Wirbel fuer Wirbel bewegen, keine Extreme.", isBWKCoreRehaSafe: true)
                                    ]),
                                    ProgramSession(dayNumber: 3, title: "Psoas Release", summary: "Nimmt Zug von der Lendenwirbelsaeule nach langem Sitzen.", exercises: [
                                        ProgramExerciseItem(name: "Couch Stretch (Knie an die Wand/Bett)", targetSets: 3, targetReps: "45s pro Seite", rpeTarget: "RIR 3", restSeconds: 60, techniqueNotes: "Bauch anspannen, aufrechte Huefte.", isBWKCoreRehaSafe: true),
                                        ProgramExerciseItem(name: "Hamstring-Mobilisation mit Band in Rueckenlage", targetSets: 3, targetReps: "45s pro Seite", rpeTarget: "RIR 3", restSeconds: 45, techniqueNotes: "Knie leicht gebeugt, Faszienzug spueren.", isBWKCoreRehaSafe: true),
                                        ProgramExerciseItem(name: "Waden-Dehnung an Wand", targetSets: 3, targetReps: "45s pro Seite", rpeTarget: "RIR 3", restSeconds: 45, techniqueNotes: "Ferse bleibt fest am Boden.", isBWKCoreRehaSafe: true)
                                    ]),
                                    ProgramSession(dayNumber: 4, title: "Schulterblatt & Nacken", summary: "Befreit den oberen Trapezius und Levator Scapulae.", exercises: [
                                        ProgramExerciseItem(name: "Trapezius-Dehnung mit Hand hinter Ruecken", targetSets: 3, targetReps: "45s pro Seite", rpeTarget: "RIR 3", restSeconds: 45, techniqueNotes: "Kopf sanft zur Gegenseite neigen.", isBWKCoreRehaSafe: true),
                                        ProgramExerciseItem(name: "Levator Scapulae Stretch (Blick zur Achselhoehle)", targetSets: 3, targetReps: "45s pro Seite", rpeTarget: "RIR 3", restSeconds: 45, techniqueNotes: "Schulter aktiv tief halten.", isBWKCoreRehaSafe: true),
                                        ProgramExerciseItem(name: "Brustkorb-Dehnung ueber Schaumstoffrolle oder Kissen", targetSets: 2, targetReps: "60s", rpeTarget: "RIR 3", restSeconds: 45, techniqueNotes: "Tiefe Zwerchfellatmung im Liegen.", isBWKCoreRehaSafe: true)
                                    ]),
                                    ProgramSession(dayNumber: 5, title: "Deep Squat & Vagus", summary: "Vollstaendige Entlastung fuer LWS und Beckenboden.", exercises: [
                                        ProgramExerciseItem(name: "Tiefe Hocke mit Festhalten (Deep Squat Rest)", targetSets: 3, targetReps: "60s", rpeTarget: "RIR 3", restSeconds: 60, techniqueNotes: "Fersen flach, Brust aufgerichtet, entspannte Beckenbodenatmung.", isBWKCoreRehaSafe: true),
                                        ProgramExerciseItem(name: "Beine hoch an die Wand (Viparita Karani)", targetSets: 1, targetReps: "5 Minuten", rpeTarget: "RIR 3", restSeconds: 0, techniqueNotes: "Fasst venoes Rueckfluss und aktiviert den Parasympathikus.", isBWKCoreRehaSafe: true)
                                    ])
                                ]
                            )
                        ]
                    )
                ]
            )
        ]
    }

    // MARK: - 2. Aesthetic Disziplin-Block (5 Programme x 5 Workouts = 25 Workouts)
    public static func aestheticPrograms() -> [TrainingProgram] {
        return [
            // Aesthetic Programm 1: Grecian Ideal
            TrainingProgram(
                name: "Grecian Ideal",
                block: .aesthetikSymmetrie,
                summary: "Strikt nach den Proportionen des Goldenen Schnitts (1:1.618). Priorisiert obere Brust, seitliche Schultern und V-Taper bei schmaler Taille.",
                methodology: "Beyond Bigger Leaner Stronger & BBLS Double Progression",
                cycleType: .cyclicalRolling,
                totalWeeks: 8,
                targetDurationText: "8 Wochen (5 Workouts/Woche)",
                daysPerWeek: 5,
                difficulty: "Fortgeschritten",
                isBWKCoreCompliant: true,
                phases: [
                    ProgramPhase(
                        phaseNumber: 1,
                        name: "Klassische Hypertrophie & V-Taper Skulptur",
                        focus: "Obere Brust, Seitheben und Rueckenbreite",
                        weeks: [
                            ProgramWeek(
                                weekNumber: 1,
                                title: "Woche 1: Double Progression Einstieg",
                                focus: "4-6 Reps bei Grunduebungen, 8-10 Reps bei Isolation",
                                sessions: [
                                    ProgramSession(dayNumber: 1, title: "Upper V-Taper", summary: "Fokus auf die Clavicular Head der Brust und seitliche Deltoide.", exercises: [
                                        ProgramExerciseItem(name: "Schraegbankdruecken Kurzhanteln (30 Grad)", targetSets: 3, targetReps: "4-6", targetWeightKg: 24.0, rpeTarget: "RPE 8", restSeconds: 180, techniqueNotes: "Volle Dehnung unten, kein Zusammenschlagen der Hanteln.", isBWKCoreRehaSafe: true),
                                        ProgramExerciseItem(name: "Kabelzug-Seitheben (Hinter dem Ruecken)", targetSets: 4, targetReps: "10-12", targetWeightKg: 7.5, rpeTarget: "RPE 8.5", restSeconds: 90, techniqueNotes: "Konstanter Zug auf den mittleren Delt, Handgelenk neutral.", isBWKCoreRehaSafe: true),
                                        ProgramExerciseItem(name: "Kabel-Flys zur oberen Brust (Tiefer Zug)", targetSets: 3, targetReps: "10-12", targetWeightKg: 10.0, rpeTarget: "RPE 8", restSeconds: 90, techniqueNotes: "Haende auf Schluesselbeinhoehe zusammenfuehren.", isBWKCoreRehaSafe: true),
                                        ProgramExerciseItem(name: "Trizepsdruecken am Tau (Ueberkopf)", targetSets: 3, targetReps: "8-10", targetWeightKg: 20.0, rpeTarget: "RPE 8", restSeconds: 90, techniqueNotes: "Langer Kopf des Trizeps fuer Armbreite.", isBWKCoreRehaSafe: true)
                                    ]),
                                    ProgramSession(dayNumber: 2, title: "Back & Biceps", summary: "Breiter oberer Latissimus und dichte Rhomboiden.", exercises: [
                                        ProgramExerciseItem(name: "Brustgestuetztes T-Bar Rudern", targetSets: 3, targetReps: "4-6", targetWeightKg: 40.0, rpeTarget: "RPE 8", restSeconds: 180, techniqueNotes: "Schont die LWS komplett, maximaler Fokus auf Schulterblaetter.", isBWKCoreRehaSafe: true),
                                        ProgramExerciseItem(name: "Latzug im breiten Parallelgriff", targetSets: 3, targetReps: "6-8", targetWeightKg: 55.0, rpeTarget: "RPE 8", restSeconds: 120, techniqueNotes: "Zur oberen Brust ziehen, Schulterblaetter aktiv nach unten fuehren.", isBWKCoreRehaSafe: true),
                                        ProgramExerciseItem(name: "Face Pulls mit Aussenrotation", targetSets: 4, targetReps: "12-15", targetWeightKg: 17.5, rpeTarget: "RPE 8.5", restSeconds: 75, techniqueNotes: "Hintere Schulter und Infraspinatus gegen Haltungsdefizit.", isBWKCoreRehaSafe: true),
                                        ProgramExerciseItem(name: "Incline Dumbbell Biceps Curls", targetSets: 3, targetReps: "8-10", targetWeightKg: 12.0, rpeTarget: "RPE 8", restSeconds: 90, techniqueNotes: "Volle Dehnung fuer den langen Bizepskopf (Peak).", isBWKCoreRehaSafe: true)
                                    ]),
                                    ProgramSession(dayNumber: 3, title: "Legs & Calves", summary: "Quad-Sweep und Wadenumfang nach Grecian Ideal Formel.", exercises: [
                                        ProgramExerciseItem(name: "Beinpresse 45 Grad (Schulterbreiter Stand)", targetSets: 3, targetReps: "6-8", targetWeightKg: 140.0, rpeTarget: "RPE 8", restSeconds: 180, techniqueNotes: "Kein Rundwerden des unteren Rueckens in der tiefsten Position.", isBWKCoreRehaSafe: true),
                                        ProgramExerciseItem(name: "Sitzende Beinbeuger (Hamstring-Isolation)", targetSets: 3, targetReps: "8-10", targetWeightKg: 45.0, rpeTarget: "RPE 8", restSeconds: 90, techniqueNotes: "2s Pause am Punkt maximaler Kontraktion.", isBWKCoreRehaSafe: true),
                                        ProgramExerciseItem(name: "Stehendes Wadenheben (Schwere Last)", targetSets: 4, targetReps: "6-8", targetWeightKg: 70.0, rpeTarget: "RPE 8", restSeconds: 90, techniqueNotes: "3s Dehnung unten, 1s Halten oben (Grecian Ideal Wadenumfang).", isBWKCoreRehaSafe: true),
                                        ProgramExerciseItem(name: "Beinstrecker an Maschine", targetSets: 3, targetReps: "10-12", targetWeightKg: 50.0, rpeTarget: "RPE 8", restSeconds: 75, techniqueNotes: "Vastus Medialis und Quad-Definition.", isBWKCoreRehaSafe: true)
                                    ]),
                                    ProgramSession(dayNumber: 4, title: "Chest & Delts", summary: "Zweiter Schulter-Reiz der Woche zur Maximierung des V-Verhaeltnisses.", exercises: [
                                        ProgramExerciseItem(name: "Kurzhantel-Schulterdruecken sitzend", targetSets: 3, targetReps: "4-6", targetWeightKg: 20.0, rpeTarget: "RPE 8", restSeconds: 180, techniqueNotes: "Leicht schraege Bank (75 Grad) schont die Schultergelenke.", isBWKCoreRehaSafe: true),
                                        ProgramExerciseItem(name: "Lu Raises mit leichten Hanteln", targetSets: 4, targetReps: "12", targetWeightKg: 6.0, rpeTarget: "RPE 8.5", restSeconds: 75, techniqueNotes: "Ueberkopf-Seitheben fuer gesamte Schulterkappe und Serratus.", isBWKCoreRehaSafe: true),
                                        ProgramExerciseItem(name: "Dips mit Koerpergewicht (Kontrolliert)", targetSets: 3, targetReps: "8-10", targetWeightKg: 0.0, rpeTarget: "RPE 8", restSeconds: 90, techniqueNotes: "Saubere untere Brust- und Trizepskontur.", isBWKCoreRehaSafe: true),
                                        ProgramExerciseItem(name: "Kabel-Trizepsdruecken einarmig", targetSets: 3, targetReps: "10-12 pro Seite", targetWeightKg: 10.0, rpeTarget: "RPE 8", restSeconds: 60, techniqueNotes: "Isolierte Auspraegung des lateralen Trizepskopfes.", isBWKCoreRehaSafe: true)
                                    ]),
                                    ProgramSession(dayNumber: 5, title: "Core Armor", summary: "Hintere Muskelkette und isometrische Rumpfstabilisation.", exercises: [
                                        ProgramExerciseItem(name: "Rumaenisches Kreuzheben Kurzhanteln", targetSets: 3, targetReps: "6-8", targetWeightKg: 26.0, rpeTarget: "RPE 8", restSeconds: 180, techniqueNotes: "Nur Hueftbeugung, Schienbeine vertikal, Ruecken neutral.", isBWKCoreRehaSafe: true),
                                        ProgramExerciseItem(name: "Brustgestuetztes Rudern im Obergriff (Rear Delt)", targetSets: 3, targetReps: "8-10", targetWeightKg: 35.0, rpeTarget: "RPE 8", restSeconds: 90, techniqueNotes: "Ellenbogen 45-60 Grad abspreizen fuer oberen Ruecken.", isBWKCoreRehaSafe: true),
                                        ProgramExerciseItem(name: "Pallof-Press am Kabelzug", targetSets: 4, targetReps: "10 mit 2s Hold", targetWeightKg: 15.0, rpeTarget: "RPE 8", restSeconds: 60, techniqueNotes: "Haelt die Taille schmal, null Taillenverbreiterung.", isBWKCoreRehaSafe: true),
                                        ProgramExerciseItem(name: "Schraege Bank Hammer Curls", targetSets: 3, targetReps: "8-10", targetWeightKg: 14.0, rpeTarget: "RPE 8", restSeconds: 90, techniqueNotes: "Brachialis-Entwicklung fuer messbar dickere Oberarme.", isBWKCoreRehaSafe: true)
                                    ])
                                ]
                            )
                        ]
                    )
                ]
            ),

            // Aesthetic Programm 2: Scapular Armor
            TrainingProgram(
                name: "Scapular Armor",
                block: .aesthetikSymmetrie,
                summary: "Entwickelt massive Dichte zwischen den Schulterblaettern (Rhomboiden, mittlerer/unterer Trapezius). Loest Verspannungen und Haltungsschwaechen nachhaltig.",
                methodology: "Mike Israetel & Meadows Back Specialization",
                cycleType: .cyclicalRolling,
                totalWeeks: 6,
                targetDurationText: "6 Wochen (5 Workouts/Woche)",
                daysPerWeek: 5,
                difficulty: "Fortgeschritten",
                isBWKCoreCompliant: true,
                phases: [
                    ProgramPhase(
                        phaseNumber: 1,
                        name: "Skapulaere Retraktion & Tiefenhypertrophie",
                        focus: "Kelso Shrugs, Seal Rows und Hintere Kette",
                        weeks: [
                            ProgramWeek(
                                weekNumber: 1,
                                title: "Woche 1: Isolierte Schulterblatt-Kontraktion",
                                focus: "Retraktion ohne Bizeps-Uebernahme",
                                sessions: [
                                    ProgramSession(dayNumber: 1, title: "Kelso & Seal Rows", summary: "Brustgestuetzte Skapulakontraktion unter hoher Last.", exercises: [
                                        ProgramExerciseItem(name: "Kelso Shrugs auf Schraegbank (Kurzhanteln)", targetSets: 4, targetReps: "10-12", targetWeightKg: 16.0, rpeTarget: "RPE 8.5", restSeconds: 90, techniqueNotes: "Arme haengen gestreckt. Nur die Schulterblaetter 2s zusammenpressen.", isBWKCoreRehaSafe: true),
                                        ProgramExerciseItem(name: "Seal Rows (Kurzhanteln auf Flachbank erhoeht)", targetSets: 4, targetReps: "8-10", targetWeightKg: 20.0, rpeTarget: "RPE 8", restSeconds: 120, techniqueNotes: "Ruecken voellig lastfrei, volle Kontraktion im Rhomboid.", isBWKCoreRehaSafe: true),
                                        ProgramExerciseItem(name: "Reverse Pec Deck (Hintere Schulter)", targetSets: 4, targetReps: "12-15", targetWeightKg: 35.0, rpeTarget: "RPE 8.5", restSeconds: 60, techniqueNotes: "Daumen nach innen, Bewegung rein aus hinterem Delt.", isBWKCoreRehaSafe: true)
                                    ]),
                                    ProgramSession(dayNumber: 2, title: "Sternum Rows & Facepulls", summary: "Horizontale Zugvektoren fuer mittlere Trapeziusfasern.", exercises: [
                                        ProgramExerciseItem(name: "Sitzendes Kabelrudern breiter Griff zum Sternum", targetSets: 4, targetReps: "8-10", targetWeightKg: 50.0, rpeTarget: "RPE 8", restSeconds: 90, techniqueNotes: "Schulterblaetter zuerst zurueckziehen, dann die Ellenbogen beugen.", isBWKCoreRehaSafe: true),
                                        ProgramExerciseItem(name: "Kabel-Facepulls mit Seil hoch zur Stirn", targetSets: 4, targetReps: "12-15", targetWeightKg: 20.0, rpeTarget: "RPE 8", restSeconds: 75, techniqueNotes: "Aussenrotation am Ende der Bewegung halten.", isBWKCoreRehaSafe: true),
                                        ProgramExerciseItem(name: "Banded Y-Raises im Stehen", targetSets: 3, targetReps: "15", targetWeightKg: 0.0, rpeTarget: "RPE 8", restSeconds: 60, techniqueNotes: "Untere Trapeziusaktivierung.", isBWKCoreRehaSafe: true)
                                    ]),
                                    ProgramSession(dayNumber: 3, title: "Dumbbell Rows & Pulldowns", summary: "Maximale Dehnung und Kontraktion der Einzelhaelfte.", exercises: [
                                        ProgramExerciseItem(name: "Einarmiges Kurzhantelrudern auf Bank gestuetzt", targetSets: 4, targetReps: "8-10 pro Seite", targetWeightKg: 26.0, rpeTarget: "RPE 8", restSeconds: 90, techniqueNotes: "Unten Schulterblatt nach vorne gleiten lassen, oben voll retrahieren.", isBWKCoreRehaSafe: true),
                                        ProgramExerciseItem(name: "Straight-Arm Pulldown am Kabelzug", targetSets: 3, targetReps: "12-15", targetWeightKg: 25.0, rpeTarget: "RPE 8", restSeconds: 60, techniqueNotes: "Isoliert den Latissimus ohne Ellenbogenbeugung.", isBWKCoreRehaSafe: true),
                                        ProgramExerciseItem(name: "Farmer's Walk mit schweren Kurzhanteln", targetSets: 3, targetReps: "45s", targetWeightKg: 28.0, rpeTarget: "RPE 8", restSeconds: 90, techniqueNotes: "Schultern zurueckgezogen, stolze Brust.", isBWKCoreRehaSafe: true)
                                    ]),
                                    ProgramSession(dayNumber: 4, title: "Batwing & Underhand Lat", summary: "Bizepsintegration und isometrische Tiefenspannung.", exercises: [
                                        ProgramExerciseItem(name: "Latzug im schulterbreiten Untergriff (Supiniert)", targetSets: 4, targetReps: "6-8", targetWeightKg: 60.0, rpeTarget: "RPE 8", restSeconds: 120, techniqueNotes: "Starke Vordehnung oben, Zug fuehrt zum Schluesselbein.", isBWKCoreRehaSafe: true),
                                        ProgramExerciseItem(name: "Batwing Rows auf Schraegbank (3s Hold oben)", targetSets: 4, targetReps: "8", targetWeightKg: 16.0, rpeTarget: "RPE 8.5", restSeconds: 90, techniqueNotes: "Schulterblaetter oben 3 Sekunden eisern zusammenbeissen.", isBWKCoreRehaSafe: true),
                                        ProgramExerciseItem(name: "Incline Hammer Curls", targetSets: 3, targetReps: "10", targetWeightKg: 12.0, rpeTarget: "RPE 8", restSeconds: 75, techniqueNotes: "Unterstuetzt Rueckenzugkraft.", isBWKCoreRehaSafe: true)
                                    ]),
                                    ProgramSession(dayNumber: 5, title: "Shrugs & Pull-Aparts", summary: "Abschluss fuer den oberen und mittleren Nackenbereich.", exercises: [
                                        ProgramExerciseItem(name: "Langhantel-Shrugs (Leicht vorgebeugt)", targetSets: 4, targetReps: "10-12", targetWeightKg: 60.0, rpeTarget: "RPE 8", restSeconds: 90, techniqueNotes: "Leicht nach vorne neigen trifft den mittleren Trapezius besser.", isBWKCoreRehaSafe: true),
                                        ProgramExerciseItem(name: "Banded Pull-Aparts im Supinationsgriff", targetSets: 4, targetReps: "20", targetWeightKg: 0.0, rpeTarget: "RPE 8", restSeconds: 60, techniqueNotes: "Handflaechen zur Decke, Zug zur Brust.", isBWKCoreRehaSafe: true),
                                        ProgramExerciseItem(name: "Toter Kaefer (Deadbug) mit Miniband", targetSets: 3, targetReps: "10 pro Seite", targetWeightKg: 0.0, rpeTarget: "RPE 8", restSeconds: 60, techniqueNotes: "Rumpf-Ausgleich nach schwerer Zugbelastung.", isBWKCoreRehaSafe: true)
                                    ])
                                ]
                            )
                        ]
                    )
                ]
            ),

            // Aesthetic Programm 3: Pelvic Shield
            TrainingProgram(
                name: "Pelvic Shield",
                block: .aesthetikSymmetrie,
                summary: "Beseitigt Dysbalancen und Schmerzen zwischen LWS und Gesaessbacken. Vollstaendige Schonung des Rueckens bei maximalem Hypertrophie-Reiz fuer Gluteus Medius/Maximus.",
                methodology: "Functional Training & Biomechanische Entlastung",
                cycleType: .cyclicalRolling,
                totalWeeks: 6,
                targetDurationText: "6 Wochen (5 Workouts/Woche)",
                daysPerWeek: 5,
                difficulty: "Mittel",
                isBWKCoreCompliant: true,
                phases: [
                    ProgramPhase(
                        phaseNumber: 1,
                        name: "Lumbo-Pelvine Symmetrie & Gesaesshypertrophie",
                        focus: "Gluteus Medius, Einbein-Stabilitaet und ISG-Entlastung",
                        weeks: [
                            ProgramWeek(
                                weekNumber: 1,
                                title: "Woche 1: Asymmetrie-Ausgleich & Hueftoeffnung",
                                focus: "Keine LWS-Kompression, maximale Gesaessansteuerung",
                                sessions: [
                                    ProgramSession(dayNumber: 1, title: "Split Squats & Abduction", summary: "Isolierter Beinstrecker- und Gesaessaufbau ohne Wirbelsaeulenstauchung.", exercises: [
                                        ProgramExerciseItem(name: "Bulgarische Split Squats (Kurzhanteln seitlich)", targetSets: 4, targetReps: "8-10 pro Seite", targetWeightKg: 14.0, rpeTarget: "RPE 8", restSeconds: 90, techniqueNotes: "Oberkoerper aufrecht halten, schont die Lendenwirbel komplett.", isBWKCoreRehaSafe: true),
                                        ProgramExerciseItem(name: "Kabelzug-Hueftabduktion im Stehen", targetSets: 4, targetReps: "12-15 pro Seite", targetWeightKg: 10.0, rpeTarget: "RPE 8.5", restSeconds: 60, techniqueNotes: "Direkte Staerkung des Gluteus Medius gegen Flankenschmerzen.", isBWKCoreRehaSafe: true),
                                        ProgramExerciseItem(name: "Beinstrecker an der Maschine (2s Hold)", targetSets: 3, targetReps: "12", targetWeightKg: 40.0, rpeTarget: "RPE 8", restSeconds: 60, techniqueNotes: "Schmerzfreie Quad-Hypertrophie.", isBWKCoreRehaSafe: true)
                                    ]),
                                    ProgramSession(dayNumber: 2, title: "Hip Thrusts & Bridges", summary: "Horizontale Krafteinleitung zur Schonung der Bandscheiben.", exercises: [
                                        ProgramExerciseItem(name: "Hip Thrusts / Glute Bridges mit Kurzhantel", targetSets: 4, targetReps: "10-12", targetWeightKg: 24.0, rpeTarget: "RPE 8", restSeconds: 90, techniqueNotes: "Kinn auf die Brust geheftet, LWS bleibt vollkommen neutral.", isBWKCoreRehaSafe: true),
                                        ProgramExerciseItem(name: "Abduktoren-Maschine sitzend (Leicht vorgebeugt)", targetSets: 4, targetReps: "15-20", targetWeightKg: 45.0, rpeTarget: "RPE 8.5", restSeconds: 60, techniqueNotes: "Brennt den oberen Gesaessbereich sauber aus.", isBWKCoreRehaSafe: true),
                                        ProgramExerciseItem(name: "Einbeiniges Beckenheben am Boden", targetSets: 3, targetReps: "10 pro Seite", targetWeightKg: 0.0, rpeTarget: "RPE 8", restSeconds: 60, techniqueNotes: "Gleicht Kraftunterschiede zwischen links und rechts aus.", isBWKCoreRehaSafe: true)
                                    ]),
                                    ProgramSession(dayNumber: 3, title: "Hyperextensions & Curls", summary: "Spezielle Ausfuehrung fuer Gesaess und Hamstrings ohne Rueckenueberstreckung.", exercises: [
                                        ProgramExerciseItem(name: "45-Grad Hyperextensions (Runder oberer Ruecken)", targetSets: 4, targetReps: "10-12", targetWeightKg: 10.0, rpeTarget: "RPE 8", restSeconds: 90, techniqueNotes: "Oberen Ruecken absichtlich rund halten; Streckung kommt rein aus Huefte/Gluteus.", isBWKCoreRehaSafe: true),
                                        ProgramExerciseItem(name: "Liegende Beinbeuger-Maschine", targetSets: 4, targetReps: "8-10", targetWeightKg: 40.0, rpeTarget: "RPE 8", restSeconds: 75, techniqueNotes: "Becken fest ins Polster pressen, kein Hohlkreuz.", isBWKCoreRehaSafe: true),
                                        ProgramExerciseItem(name: "Stehendes Wadenheben", targetSets: 4, targetReps: "12", targetWeightKg: 60.0, rpeTarget: "RPE 8", restSeconds: 60, techniqueNotes: "Symmetrischer Wadenschwung.", isBWKCoreRehaSafe: true)
                                    ]),
                                    ProgramSession(dayNumber: 4, title: "Leg Curls & Copenhagen", summary: "Kombination aus Oberschenkel-Rueckseite und Leistenstabilitaet.", exercises: [
                                        ProgramExerciseItem(name: "Sitzende Beinbeuger an der Maschine", targetSets: 4, targetReps: "10-12", targetWeightKg: 45.0, rpeTarget: "RPE 8", restSeconds: 75, techniqueNotes: "Volle Dehnung in der Hueftbeugung.", isBWKCoreRehaSafe: true),
                                        ProgramExerciseItem(name: "Copenhagen Plank am Polster", targetSets: 3, targetReps: "20s pro Seite", targetWeightKg: 0.0, rpeTarget: "RPE 8", restSeconds: 60, techniqueNotes: "Staerkt die Adduktoren und stabilisiert das Schambein.", isBWKCoreRehaSafe: true),
                                        ProgramExerciseItem(name: "Seitstuetz mit Beinhochfuehren", targetSets: 3, targetReps: "10 pro Seite", targetWeightKg: 0.0, rpeTarget: "RPE 8", restSeconds: 60, techniqueNotes: "Staerkt Flanke und Gluteus Medius simultan.", isBWKCoreRehaSafe: true)
                                    ]),
                                    ProgramSession(dayNumber: 5, title: "Single-Leg RDL & Kickbacks", summary: "Koordination, Hueftstabilitaet und ISG-Sicherung.", exercises: [
                                        ProgramExerciseItem(name: "Einbeiniges Rumaenisches Kreuzheben (Single Leg RDL)", targetSets: 4, targetReps: "8 pro Seite", targetWeightKg: 12.0, rpeTarget: "RPE 8", restSeconds: 90, techniqueNotes: "Standbein minimal gebeugt, Huefte parallel zum Boden halten.", isBWKCoreRehaSafe: true),
                                        ProgramExerciseItem(name: "Kabel-Glute-Kickbacks", targetSets: 3, targetReps: "12 pro Seite", targetWeightKg: 12.5, rpeTarget: "RPE 8", restSeconds: 60, techniqueNotes: "Diagonale Abspreizung fuer maximalen Muskelreiz.", isBWKCoreRehaSafe: true),
                                        ProgramExerciseItem(name: "McGill Bird-Dog", targetSets: 3, targetReps: "6x 8s Hold", targetWeightKg: 0.0, rpeTarget: "RPE 8", restSeconds: 60, techniqueNotes: "Regenerativer Abschluss fuer die Wirbelsaeule.", isBWKCoreRehaSafe: true)
                                    ])
                                ]
                            )
                        ]
                    )
                ]
            ),

            // Aesthetic Programm 4: 3D Delts & Arms
            TrainingProgram(
                name: "3D Delts & Arms",
                block: .aesthetikSymmetrie,
                summary: "Fokussiertes Schulter- und Arm-Spezialprogramm zur Verwirklichung des Goldenen Schnitts (Oberarmumfang = 2.5x Handgelenk).",
                methodology: "Hypertrophy Specific Training (HST) & BBLS",
                cycleType: .cyclicalRolling,
                totalWeeks: 6,
                targetDurationText: "6 Wochen (5 Workouts/Woche)",
                daysPerWeek: 5,
                difficulty: "Fortgeschritten",
                isBWKCoreCompliant: true,
                phases: [
                    ProgramPhase(
                        phaseNumber: 1,
                        name: "Schulter-Kugelkopf & Armdichte",
                        focus: "Seitlicher Delt, Brachialis und Trizeps-Hufeisen",
                        weeks: [
                            ProgramWeek(
                                weekNumber: 1,
                                title: "Woche 1: Deltoid-Volumen & Bi-Tri Kopplung",
                                focus: "Progressive Overload an Kabeln und Kurzhanteln",
                                sessions: [
                                    ProgramSession(dayNumber: 1, title: "Cable Laterals & Incline", summary: "Maximale Schulterbreite.", exercises: [
                                        ProgramExerciseItem(name: "Kabelzug-Seitheben einarmig hinter Koerper", targetSets: 4, targetReps: "10-12 pro Seite", targetWeightKg: 7.5, rpeTarget: "RPE 8.5", restSeconds: 75, techniqueNotes: "Spannung verlaesst den seitlichen Delt zu keinem Zeitpunkt.", isBWKCoreRehaSafe: true),
                                        ProgramExerciseItem(name: "Kurzhantel-Schraegbankdruecken 30 Grad", targetSets: 3, targetReps: "6-8", targetWeightKg: 24.0, rpeTarget: "RPE 8", restSeconds: 120, techniqueNotes: "Ellenbogen ca. 45 Grad zum Oberkoerper.", isBWKCoreRehaSafe: true),
                                        ProgramExerciseItem(name: "Dumbbell Lateral Raise (Teilwiederholungen)", targetSets: 3, targetReps: "15", targetWeightKg: 10.0, rpeTarget: "RPE 9", restSeconds: 60, techniqueNotes: "Schweres Gewicht, saubere Teilausfuehrung.", isBWKCoreRehaSafe: true)
                                    ]),
                                    ProgramSession(dayNumber: 2, title: "Incline Curls & Rope Extensions", summary: "Maximale Dehnung fuer Bizeps und Trizeps.", exercises: [
                                        ProgramExerciseItem(name: "Incline Dumbbell Curls (45 Grad Bank)", targetSets: 4, targetReps: "8-10", targetWeightKg: 12.0, rpeTarget: "RPE 8", restSeconds: 90, techniqueNotes: "Oberarme senkrecht nach unten haengen lassen.", isBWKCoreRehaSafe: true),
                                        ProgramExerciseItem(name: "Kabel-Trizepsdruecken ueber Kopf mit Seil", targetSets: 4, targetReps: "10-12", targetWeightKg: 22.5, rpeTarget: "RPE 8", restSeconds: 90, techniqueNotes: "Volle Dehnung im langen Trizepskopf.", isBWKCoreRehaSafe: true),
                                        ProgramExerciseItem(name: "Konzentrations-Curls auf Oberschenkel", targetSets: 3, targetReps: "10 pro Seite", targetWeightKg: 12.0, rpeTarget: "RPE 8.5", restSeconds: 60, techniqueNotes: "Maximale Bizepskuppe am obersten Punkt.", isBWKCoreRehaSafe: true)
                                    ]),
                                    ProgramSession(dayNumber: 3, title: "Shoulder Press & Rear Flyes", summary: "Vordere und hintere Schulterkappe.", exercises: [
                                        ProgramExerciseItem(name: "Kurzhantel-Schulterdruecken im Sitzen", targetSets: 4, targetReps: "6-8", targetWeightKg: 22.0, rpeTarget: "RPE 8", restSeconds: 120, techniqueNotes: "Unten 90 Grad, oben zusammendruecken ohne Ellenbogenueberstreckung.", isBWKCoreRehaSafe: true),
                                        ProgramExerciseItem(name: "Vorgebeugtes Seitheben auf Schraegbank", targetSets: 4, targetReps: "12-15", targetWeightKg: 8.0, rpeTarget: "RPE 8.5", restSeconds: 60, techniqueNotes: "Brust liegt auf Bank, keine Schwungbewegung.", isBWKCoreRehaSafe: true),
                                        ProgramExerciseItem(name: "Barren-Dips mit Fokus auf Trizeps", targetSets: 3, targetReps: "8-10", targetWeightKg: 0.0, rpeTarget: "RPE 8", restSeconds: 90, techniqueNotes: "Oberkoerper aufrecht halten.", isBWKCoreRehaSafe: true)
                                    ]),
                                    ProgramSession(dayNumber: 4, title: "Hammer Curls & Pushdowns", summary: "Dicke Oberarme durch Brachialis-Hypertrophie.", exercises: [
                                        ProgramExerciseItem(name: "Hammer Curls mit Kurzhanteln stehend", targetSets: 4, targetReps: "8-10", targetWeightKg: 16.0, rpeTarget: "RPE 8", restSeconds: 90, techniqueNotes: "Daumen zeigen die gesamte Zeit nach oben.", isBWKCoreRehaSafe: true),
                                        ProgramExerciseItem(name: "Trizepsdruecken an gerader Kabelstange", targetSets: 4, targetReps: "10-12", targetWeightKg: 30.0, rpeTarget: "RPE 8", restSeconds: 75, techniqueNotes: "Ellenbogen am Rumpf einbetonieren.", isBWKCoreRehaSafe: true),
                                        ProgramExerciseItem(name: "Reverse Curls mit SZ-Stange (Unterarme)", targetSets: 3, targetReps: "12", targetWeightKg: 20.0, rpeTarget: "RPE 8", restSeconds: 60, techniqueNotes: "Obergriff staerkt den Brachioradialis.", isBWKCoreRehaSafe: true)
                                    ]),
                                    ProgramSession(dayNumber: 5, title: "Lu Raises & Facepulls", summary: "Metabolische Ausbelastung der gesamten Schulterkapsel.", exercises: [
                                        ProgramExerciseItem(name: "Lu Raises mit Hanteln ueber Kopf", targetSets: 4, targetReps: "12", targetWeightKg: 6.0, rpeTarget: "RPE 8.5", restSeconds: 60, techniqueNotes: "Grosser Bogen, kontrollierte Bewegung.", isBWKCoreRehaSafe: true),
                                        ProgramExerciseItem(name: "Facepulls mit doppelter Aussenrotation", targetSets: 4, targetReps: "15", targetWeightKg: 17.5, rpeTarget: "RPE 8", restSeconds: 60, techniqueNotes: "Staerkt Haltung und Schultergesundheit.", isBWKCoreRehaSafe: true),
                                        ProgramExerciseItem(name: "Seitstuetz mit Abduktion", targetSets: 3, targetReps: "30s pro Seite", targetWeightKg: 0.0, rpeTarget: "RPE 8", restSeconds: 45, techniqueNotes: "Taille schlank halten.", isBWKCoreRehaSafe: true)
                                    ])
                                ]
                            )
                        ]
                    )
                ]
            ),

            // Aesthetic Programm 5: V-Taper Core
            TrainingProgram(
                name: "V-Taper Core",
                block: .aesthetikSymmetrie,
                summary: "Rumpfstabilisation und Rueckendichte ohne Taillenverbreiterung. Strikte Vermeidung von Crunches und Sit-ups gemaess BWK-Ulm Vorgaben.",
                methodology: "Spine Biomechanics & Anti-Flexion Engine",
                cycleType: .cyclicalRolling,
                totalWeeks: 6,
                targetDurationText: "6 Wochen (5 Workouts/Woche)",
                daysPerWeek: 5,
                difficulty: "Mittel",
                isBWKCoreCompliant: true,
                phases: [
                    ProgramPhase(
                        phaseNumber: 1,
                        name: "Anti-Rotations-Panzerung & Rueckenlinie",
                        focus: "Transversus Abdominis, Multifidi und Latissimus",
                        weeks: [
                            ProgramWeek(
                                weekNumber: 1,
                                title: "Woche 1: Isometrische Zuggurtung",
                                focus: "Strikte Rumpfsteifigkeit ohne Bauchmuskelverkürzung",
                                sessions: [
                                    ProgramSession(dayNumber: 1, title: "Pallof-Press & Suitcase", summary: "Anti-Rotation und Anti-Lateralflexion.", exercises: [
                                        ProgramExerciseItem(name: "Kabelzug-Pallof-Press im schulterbreiten Stand", targetSets: 4, targetReps: "10 mit 3s Hold", targetWeightKg: 15.0, rpeTarget: "RPE 8", restSeconds: 60, techniqueNotes: "Kabel versucht den Koerper zu drehen; Bauch haelt eisern dagegen.", isBWKCoreRehaSafe: true),
                                        ProgramExerciseItem(name: "Einarmiges Koffer-Tragen (Suitcase Carry mit KH)", targetSets: 4, targetReps: "45s pro Seite", targetWeightKg: 22.0, rpeTarget: "RPE 8", restSeconds: 60, techniqueNotes: "Schultern absolut waagerecht halten.", isBWKCoreRehaSafe: true),
                                        ProgramExerciseItem(name: "Deadbug mit Druck gegen die Knie", targetSets: 3, targetReps: "8 pro Seite", targetWeightKg: 0.0, rpeTarget: "RPE 8", restSeconds: 60, techniqueNotes: "Maximale diagonale Rumpfspannung ohne Wirbelsaeulenkruemmung.", isBWKCoreRehaSafe: true)
                                    ]),
                                    ProgramSession(dayNumber: 2, title: "Lat Pulldown & Reverse Hyper", summary: "V-Taper Rueckenbreite und schmerzfreie Gesaessstreckung.", exercises: [
                                        ProgramExerciseItem(name: "Latzug im breiten Obergriff zur oberen Brust", targetSets: 4, targetReps: "8-10", targetWeightKg: 55.0, rpeTarget: "RPE 8", restSeconds: 90, techniqueNotes: "Leichte Ruecklage (10 Grad), kein Reissen aus dem unteren Ruecken.", isBWKCoreRehaSafe: true),
                                        ProgramExerciseItem(name: "Reverse Hyperextensions auf Bank", targetSets: 4, targetReps: "12-15", targetWeightKg: 0.0, rpeTarget: "RPE 8", restSeconds: 60, techniqueNotes: "Oberkoerper liegt auf der Bank, Beine werden durch Gesaesskraft angehoben.", isBWKCoreRehaSafe: true),
                                        ProgramExerciseItem(name: "Kabel-Ueberzuege mit Seil (Straight-Arm)", targetSets: 3, targetReps: "12", targetWeightKg: 22.5, rpeTarget: "RPE 8", restSeconds: 60, techniqueNotes: "Aktiviert den Serratus fuer die Rippenkontur.", isBWKCoreRehaSafe: true)
                                    ]),
                                    ProgramSession(dayNumber: 3, title: "Stir-the-Pot & Side Plank", summary: "Dynmische Stabilisation fuer tiefe Bauchwandschichten.", exercises: [
                                        ProgramExerciseItem(name: "Stir-the-Pot auf Gymnastikball (Kreisende Unterarme)", targetSets: 4, targetReps: "8 Kreise pro Richtung", targetWeightKg: 0.0, rpeTarget: "RPE 8.5", restSeconds: 75, techniqueNotes: "Beste Uebung fuer Tiefenrumpf gemaess Prof. Stuart McGill.", isBWKCoreRehaSafe: true),
                                        ProgramExerciseItem(name: "Seitstuetz (Side Plank) mit erhoehten Fuessen", targetSets: 4, targetReps: "35s pro Seite", targetWeightKg: 0.0, rpeTarget: "RPE 8", restSeconds: 60, techniqueNotes: "Gluteus Medius und innere schraege Bauchmuskeln.", isBWKCoreRehaSafe: true),
                                        ProgramExerciseItem(name: "Bird-Dog mit Daumen nach oben", targetSets: 3, targetReps: "10 pro Seite", targetWeightKg: 0.0, rpeTarget: "RPE 8", restSeconds: 60, techniqueNotes: "Multifidi-Aktivierung.", isBWKCoreRehaSafe: true)
                                    ]),
                                    ProgramSession(dayNumber: 4, title: "Chest Row & Waiter's Walk", summary: "Schulterblatt-Retraktion und Rumpfpanzerung im Gehen.", exercises: [
                                        ProgramExerciseItem(name: "Brustgestuetztes Kurzhantelrudern neutral", targetSets: 4, targetReps: "8-10", targetWeightKg: 20.0, rpeTarget: "RPE 8", restSeconds: 90, techniqueNotes: "Schulterblaetter maximal zusammenziehen.", isBWKCoreRehaSafe: true),
                                        ProgramExerciseItem(name: "Einarmiges Waiter's Walk (Hantel ueber Kopf tragen)", targetSets: 3, targetReps: "30s pro Seite", targetWeightKg: 12.0, rpeTarget: "RPE 8", restSeconds: 60, techniqueNotes: "Fixiert das Schulterblatt und fordert die Schraege Bauchwand.", isBWKCoreRehaSafe: true),
                                        ProgramExerciseItem(name: "Face Pulls mit 2s Pause", targetSets: 4, targetReps: "12", targetWeightKg: 17.5, rpeTarget: "RPE 8", restSeconds: 60, techniqueNotes: "Haltungsausgleich.", isBWKCoreRehaSafe: true)
                                    ]),
                                    ProgramSession(dayNumber: 5, title: "Farmer's Walk & Adductor Bridge", summary: "Kraftvoller Wochenabschluss ohne Rueckenschmerz.", exercises: [
                                        ProgramExerciseItem(name: "Farmer's Walk beidbeinig mit schweren Hanteln", targetSets: 4, targetReps: "60s", targetWeightKg: 28.0, rpeTarget: "RPE 8.5", restSeconds: 90, techniqueNotes: "Aufrechte Haltung, strammer Schritt.", isBWKCoreRehaSafe: true),
                                        ProgramExerciseItem(name: "Gesaessbruecke mit Ball zwischen Knien (Adduktoren)", targetSets: 4, targetReps: "12 mit 3s Hold", targetWeightKg: 0.0, rpeTarget: "RPE 8", restSeconds: 60, techniqueNotes: "Schliesst das Becken und aktiviert den Beckenboden.", isBWKCoreRehaSafe: true),
                                        ProgramExerciseItem(name: "Passive Bar Hang mit tiefer Ausatmung", targetSets: 2, targetReps: "45s", targetWeightKg: 0.0, rpeTarget: "RPE 8", restSeconds: 45, techniqueNotes: "Dekompression der gesamten Wirbelsaeule.", isBWKCoreRehaSafe: true)
                                    ])
                                ]
                            )
                        ]
                    )
                ]
            )
        ]
    }

    // MARK: - 3. Ausdauer & Running Disziplin-Block (Daniels, 80/20 & Maffetone)
    public static func runningPrograms() -> [TrainingProgram] {
        return [
            // Ausdauer Programm 1: VDOT Threshold
            TrainingProgram(
                name: "VDOT Threshold",
                block: .ausdauerRunning,
                summary: "Evidenzbasierte Trainingssteuerung nach Jack Daniels Running Formula. Steigert VDOT-Wert und Sauerstoffaufnahme durch strukturierte E-Pace (Easy Zone 2), T-Pace (Laktatschwelle) und I-Pace (VO2max 4x4-Minuten-Intervalle).",
                methodology: "Jack Daniels Running Formula (VDOT 49.5+)",
                cycleType: .cyclicalRolling,
                totalWeeks: 4,
                targetDurationText: "4 Wochen (4 Laeufe/Woche)",
                daysPerWeek: 4,
                difficulty: "Fortgeschritten",
                isBWKCoreCompliant: true,
                calisthenicArchetype: .hermes,
                phases: [
                    ProgramPhase(
                        phaseNumber: 1,
                        name: "Aerobe Basis & Schwellen-Steuerung",
                        focus: "Mitochondriendichte, Laktatschwelle und VO2max",
                        weeks: [
                            ProgramWeek(
                                weekNumber: 1,
                                title: "Woche 1: Grundlagenausdauer & Intervallstart",
                                focus: "E-Pace, T-Pace und 4x4-Minuten-Intervalle",
                                sessions: [
                                    ProgramSession(
                                        dayNumber: 1,
                                        title: "E-Pace Zone 2 Run",
                                        summary: "45 Min. aerobe Fettverbrennung im FatMax-Bereich gemaess Daniels E-Pace.",
                                        exercises: [
                                            ProgramExerciseItem(name: "Zone 2 Grundlagenausdauerlauf (E-Pace)", targetSets: 1, targetReps: "45 min", rpeTarget: "RIR 3", restSeconds: 60, techniqueNotes: "Sprechtest problemlos moeglich. Laktat unter 2.0 mmol/L.", isBWKCoreRehaSafe: true),
                                            ProgramExerciseItem(name: "Hamstring-Mobilisation mit Band in Rueckenlage", targetSets: 3, targetReps: "45s pro Bein", rpeTarget: "RIR 3", restSeconds: 45, techniqueNotes: "Sanfte Sehnen-Dekompression nach dem Lauf.", isBWKCoreRehaSafe: true)
                                        ],
                                        runningIntervals: [
                                            ProgramRunningInterval(id: UUID(), title: "E-Pace Zone 2 Dauerlauf", durationSeconds: 2700, targetPaceMinKm: "6:00-6:30", heartRateZone: "Zone 2 (130-145 bpm)")
                                        ]
                                    ),
                                    ProgramSession(
                                        dayNumber: 2,
                                        title: "T-Pace Schwellenlauf",
                                        summary: "Schwellentraining zur Verschiebung der aeroben Kapazitaet nach rechts.",
                                        exercises: [
                                            ProgramExerciseItem(name: "Laktatschwellen-Tempolauf (T-Pace)", targetSets: 1, targetReps: "25 min", rpeTarget: "RPE 8", restSeconds: 90, techniqueNotes: "Gleichmaessige anaerobe Schwelle, nur kurze Saetze sprechbar.", isBWKCoreRehaSafe: true),
                                            ProgramExerciseItem(name: "Child's Pose mit tiefer Flankenatmung", targetSets: 2, targetReps: "60s", rpeTarget: "RIR 3", restSeconds: 45, techniqueNotes: "Zwerchfell- und Beckenentspannung.", isBWKCoreRehaSafe: true)
                                        ],
                                        runningIntervals: [
                                            ProgramRunningInterval(id: UUID(), title: "Warm-up E-Pace", durationSeconds: 600, targetPaceMinKm: "6:15", heartRateZone: "Zone 2"),
                                            ProgramRunningInterval(id: UUID(), title: "T-Pace Schwellenlauf", durationSeconds: 1200, targetPaceMinKm: "4:50-5:10", heartRateZone: "Zone 4 (165-175 bpm)"),
                                            ProgramRunningInterval(id: UUID(), title: "Cool-down Walk", durationSeconds: 300, targetPaceMinKm: "Gehen", heartRateZone: "Zone 1")
                                        ]
                                    ),
                                    ProgramSession(
                                        dayNumber: 3,
                                        title: "I-Pace 4x4 Intervalle",
                                        summary: "Goldstandard-Intervallprotokoll zur Maximierung des Schlagvolumens des Herzens.",
                                        exercises: [
                                            ProgramExerciseItem(name: "VO2max 4x4-Minuten-Intervalle (I-Pace)", targetSets: 4, targetReps: "4 min @ 4:05-4:15", rpeTarget: "RPE 9", restSeconds: 180, techniqueNotes: "3 Min. Gehpause zwischen Intervallen. Harter Atemrhythmus.", isBWKCoreRehaSafe: true),
                                            ProgramExerciseItem(name: "McGill Bird-Dog mit neutralem Becken", targetSets: 3, targetReps: "6x 8s Hold pro Seite", rpeTarget: "RIR 2", restSeconds: 60, techniqueNotes: "Stabilisiert das Becken nach hohen Schockkraeften.", isBWKCoreRehaSafe: true)
                                        ],
                                        runningIntervals: [
                                            ProgramRunningInterval(id: UUID(), title: "4x 4 Min. High-Intensity Intervalle", durationSeconds: 1680, targetPaceMinKm: "4:05-4:20", heartRateZone: "Zone 5 (>175 bpm)")
                                        ]
                                    ),
                                    ProgramSession(
                                        dayNumber: 4,
                                        title: "Cooper- & 1000m-Test",
                                        summary: "Pruefung der aeroben Kapazitaet nach Bundeswehr- und Cooper-Standard.",
                                        exercises: [
                                            ProgramExerciseItem(name: "12-Minuten Cooper-Test All-Out", targetSets: 1, targetReps: "12 min All-Out", rpeTarget: "RPE 9.5", restSeconds: 300, techniqueNotes: "Maximaldistanz halten (Ziel >2.800m).", isBWKCoreRehaSafe: true),
                                            ProgramExerciseItem(name: "Bundeswehr 1000m-Sprint-Simulation", targetSets: 1, targetReps: "1000m", rpeTarget: "RPE 9", restSeconds: 180, techniqueNotes: "Ziel unter 3:45 Minuten.", isBWKCoreRehaSafe: true)
                                        ],
                                        runningIntervals: [
                                            ProgramRunningInterval(id: UUID(), title: "12-Minuten Cooper Testlauf", durationSeconds: 720, targetPaceMinKm: "4:05-4:15", heartRateZone: "Zone 5"),
                                            ProgramRunningInterval(id: UUID(), title: "BFT 1000m Sprint", distanceMeters: 1000, targetPaceMinKm: "3:40", heartRateZone: "Zone 5")
                                        ]
                                    )
                                ]
                            )
                        ]
                    )
                ]
            ),

            // Ausdauer Programm 2: 80/20 Endurance
            TrainingProgram(
                name: "80/20 Endurance",
                block: .ausdauerRunning,
                summary: "Strikte 80/20-Intensitaetsverteilung nach Matt Fitzgerald. 80% schonende aerobe Zone-2-Fettverbrennung zur Schonung des ZNS gepaart mit 20% anaeroben Spitzenreizen.",
                methodology: "Matt Fitzgerald 80/20 Running & FGOE-Standard",
                cycleType: .cyclicalRolling,
                totalWeeks: 6,
                targetDurationText: "6 Wochen (4 Laeufe/Woche)",
                daysPerWeek: 4,
                difficulty: "Mittel",
                isBWKCoreCompliant: true,
                calisthenicArchetype: .hermes,
                phases: [
                    ProgramPhase(
                        phaseNumber: 1,
                        name: "Polarisierte Kapillarisierung",
                        focus: "FatMax-Effizienz und orthopaedische Resilienz",
                        weeks: [
                            ProgramWeek(
                                weekNumber: 1,
                                title: "Woche 1: Polarisierte Basis",
                                focus: "80% Low-Intensity, 20% Schwellenbelastung",
                                sessions: [
                                    ProgramSession(dayNumber: 1, title: "Zone 2 FatMax Run", summary: "Niedrige Herzfrequenz, reiner Fettstoffwechsel.", exercises: [
                                        ProgramExerciseItem(name: "Zone 2 Grundlagenausdauerlauf (E-Pace)", targetSets: 1, targetReps: "45 min", rpeTarget: "RIR 3", restSeconds: 60, techniqueNotes: "Sprechen problemlos moeglich, Singen nicht mehr.", isBWKCoreRehaSafe: true)
                                    ]),
                                    ProgramSession(dayNumber: 2, title: "Zone 2 Long Run", summary: "Langer aerober Dauerlauf fuer Sehnenadaption.", exercises: [
                                        ProgramExerciseItem(name: "Zone 2 Grundlagenausdauerlauf (E-Pace)", targetSets: 1, targetReps: "60 min", rpeTarget: "RIR 3", restSeconds: 60, techniqueNotes: "Puls strikt unter 145 bpm halten.", isBWKCoreRehaSafe: true)
                                    ]),
                                    ProgramSession(dayNumber: 3, title: "High-Intensity Sprints", summary: "Anaerober Reiz fuer die oberen 20% der Wochenintensitaet.", exercises: [
                                        ProgramExerciseItem(name: "VO2max 4x4-Minuten-Intervalle (I-Pace)", targetSets: 4, targetReps: "4 min", rpeTarget: "RPE 9", restSeconds: 180, techniqueNotes: "Hartes Durchziehen, 3 Min. lockere Gehpause.", isBWKCoreRehaSafe: true)
                                    ]),
                                    ProgramSession(dayNumber: 4, title: "Regenerationslauf", summary: "Lockeres Auslaufen zur Laktatbeseitigung.", exercises: [
                                        ProgramExerciseItem(name: "Zone 2 Grundlagenausdauerlauf (E-Pace)", targetSets: 1, targetReps: "30 min", rpeTarget: "RIR 4", restSeconds: 60, techniqueNotes: "Ultraleichtes Tempo, Vagus-Aktivierung.", isBWKCoreRehaSafe: true)
                                    ])
                                ]
                            )
                        ]
                    )
                ]
            ),

            // Ausdauer Programm 3: MAF-180 Engine
            TrainingProgram(
                name: "MAF-180 Engine",
                block: .ausdauerRunning,
                summary: "Herzfrequenz-Gedeckeltes Grundlagentraining nach Dr. Phil Maffetone (MAF = 180 - Alter = 150 bpm). Maximale Mitochondriendichte und Fettstoffwechsel ohne sympathischen Stress.",
                methodology: "Phil Maffetone MAF-180 Methode",
                cycleType: .cyclicalRolling,
                totalWeeks: 8,
                targetDurationText: "8 Wochen (3 Laeufe/Woche)",
                daysPerWeek: 3,
                difficulty: "Einsteiger",
                isBWKCoreCompliant: true,
                calisthenicArchetype: .hermes,
                phases: [
                    ProgramPhase(
                        phaseNumber: 1,
                        name: "MAF Aerobic Engine",
                        focus: "Mitochondrien-Biogenese bei strikter Herzfrequenz-Obergrenze",
                        weeks: [
                            ProgramWeek(
                                weekNumber: 1,
                                title: "Woche 1: MAF-Grenzfrequenz Einhaltung",
                                focus: "Strikte Begrenzung auf maximal 150 bpm",
                                sessions: [
                                    ProgramSession(dayNumber: 1, title: "MAF-180 Base Run", summary: "Strikte Pulskontrolle bei 140-150 bpm.", exercises: [
                                        ProgramExerciseItem(name: "MAF-180 Herzfrequenz-Lauf", targetSets: 1, targetReps: "40 min @ <150 bpm", rpeTarget: "RIR 3", restSeconds: 60, techniqueNotes: "Sobald Puls 150 ueberschreitet, Tempo sofort drosseln.", isBWKCoreRehaSafe: true)
                                    ]),
                                    ProgramSession(dayNumber: 2, title: "MAF-180 Pace Test", summary: "Erfassen der Geschwindigkeit bei exakt MAF-Puls.", exercises: [
                                        ProgramExerciseItem(name: "MAF-180 Herzfrequenz-Lauf", targetSets: 1, targetReps: "45 min", rpeTarget: "RIR 3", restSeconds: 60, techniqueNotes: "Pace dokumentieren fuer Monatstrend.", isBWKCoreRehaSafe: true)
                                    ]),
                                    ProgramSession(dayNumber: 3, title: "MAF-180 Long Run", summary: "Langer aerober Reiz fuer maximale Fettverbrennungsenzyme.", exercises: [
                                        ProgramExerciseItem(name: "MAF-180 Herzfrequenz-Lauf", targetSets: 1, targetReps: "55 min", rpeTarget: "RIR 3", restSeconds: 60, techniqueNotes: "Vollstaendig stressfreie Atmung durch die Nase anstreben.", isBWKCoreRehaSafe: true)
                                    ])
                                ]
                            )
                        ]
                    )
                ]
            )
        ]
    }

    // MARK: - 4. Stuben-Athletik Disziplin-Block (100% Zimmer-Calisthenics No Weights)
    public static func roomCalisthenicsPrograms() -> [TrainingProgram] {
        return [
            TrainingProgram(
                name: "Stuben-Athletik",
                block: .calisthenicsGoetter,
                summary: "Autarkes Hypertrophie- und Konditionierungsprogramm direkt im Kasernen- oder Hotelzimmer ohne Hanteln. Nutzt Stubentisch fuer Inverted Rows, Bundeswehr-Hocker fuer Dips, Bettkante fuer erhoehte Liegestuetz und Split Squats. 100% konform mit der Viszeral-Reha des BWK Ulm (Null Crunches/Sit-ups).",
                methodology: "Kasernen- & Stuben-Doktrin (Bett, Tisch, Stuhl, Boden)",
                cycleType: .cyclicalRolling,
                totalWeeks: 6,
                targetDurationText: "6 Wochen (3 Workouts/Woche)",
                daysPerWeek: 3,
                difficulty: "Alle Stufen",
                isBWKCoreCompliant: true,
                calisthenicArchetype: .ares,
                phases: [
                    ProgramPhase(
                        phaseNumber: 1,
                        name: "Stuben-Autarkie & Hypertrophie",
                        focus: "Volle Muskelaktivierung mit Zimmer-Moebeln und Eigengewicht",
                        weeks: [
                            ProgramWeek(
                                weekNumber: 1,
                                title: "Woche 1: Stuben-Grundlagen",
                                focus: "Zug- und Druckmuster an Tisch, Bett und Stuhl",
                                sessions: [
                                    ProgramSession(
                                        dayNumber: 1,
                                        title: "Stuben-Oberkoerper",
                                        summary: "Brust, Ruecken, Trizeps und Schulterblatt-Retraktion ohne Gym-Geraete.",
                                        exercises: [
                                            ProgramExerciseItem(name: "Bettkanten-Liegestuetz (Fuesse auf Bett erhoeht)", targetSets: 4, targetReps: "10-12", rpeTarget: "RIR 2", restSeconds: 60, techniqueNotes: "Fuesse auf die Bettkante, Rumpf wie ein Brett anspannen.", isBWKCoreRehaSafe: true),
                                            ProgramExerciseItem(name: "Tischkanten-Inverted-Rows (Unter Tisch liegend)", targetSets: 4, targetReps: "8-10", rpeTarget: "RIR 2", restSeconds: 75, techniqueNotes: "Unter den stabilen Tisch legen, Kante greifen, Brust zur Kante ziehen.", isBWKCoreRehaSafe: true),
                                            ProgramExerciseItem(name: "Stuhl-Dips (Haende auf Bundeswehr-Hocker)", targetSets: 3, targetReps: "10-12", rpeTarget: "RIR 2", restSeconds: 60, techniqueNotes: "Fokus auf Trizeps, aufrechte Haltung.", isBWKCoreRehaSafe: true),
                                            ProgramExerciseItem(name: "Prone Cobra (Bauchlage Schulterblatt-Retraktion)", targetSets: 3, targetReps: "12 mit 3s Hold", rpeTarget: "RIR 2", restSeconds: 45, techniqueNotes: "Schulterblaetter nach hinten unten pressen.", isBWKCoreRehaSafe: true),
                                            ProgramExerciseItem(name: "Tuerrahmen-Ruderzuege einarmig (Kasernen-Setup)", targetSets: 3, targetReps: "10 pro Seite", rpeTarget: "RIR 2", restSeconds: 45, techniqueNotes: "Schulterblatt der arbeitenden Seite maximal nach hinten fuehren.", isBWKCoreRehaSafe: true)
                                        ]
                                    ),
                                    ProgramSession(
                                        dayNumber: 2,
                                        title: "Stuben-Unterkoerper",
                                        summary: "Quadrizeps, Gesaess und Waden ohne schwere Langhanteln.",
                                        exercises: [
                                            ProgramExerciseItem(name: "Bulgarische Split Squats (Hinterer Fuss auf Bettkante)", targetSets: 4, targetReps: "10 pro Seite", rpeTarget: "RIR 2", restSeconds: 60, techniqueNotes: "Hinterer Fuss auf Bett oder Stuhl; tiefe Hocke im vorderen Bein.", isBWKCoreRehaSafe: true),
                                            ProgramExerciseItem(name: "Einbeinige Glute Bridge mit 3s Peak Hold", targetSets: 4, targetReps: "10 pro Seite", rpeTarget: "RIR 2", restSeconds: 60, techniqueNotes: "Volle Hueftstreckung aus dem Gesaess ohne LWS-Kruemmung.", isBWKCoreRehaSafe: true),
                                            ProgramExerciseItem(name: "Chair Step-ups (Auf Stuhl im Sekundentakt)", targetSets: 3, targetReps: "15 pro Seite", rpeTarget: "RIR 2", restSeconds: 45, techniqueNotes: "Kraftvoll aus dem Oberschenkel aufsteigen, Fuehrungsbein wechseln.", isBWKCoreRehaSafe: true),
                                            ProgramExerciseItem(name: "Sissy Squats mit Festhalten", targetSets: 3, targetReps: "10-12", rpeTarget: "RIR 2", restSeconds: 60, techniqueNotes: "An Tuerrahmen festhalten, Knie nach vorne schieben (reine Quad-Spannung).", isBWKCoreRehaSafe: true),
                                            ProgramExerciseItem(name: "Einbeinige Wadenheben an Stufe", targetSets: 4, targetReps: "15 pro Seite", rpeTarget: "RIR 1", restSeconds: 45, techniqueNotes: "Volle Dehnung unten, 1s Peak Contraction oben.", isBWKCoreRehaSafe: true)
                                        ]
                                    ),
                                    ProgramSession(
                                        dayNumber: 3,
                                        title: "Stuben-Konditionierung",
                                        summary: "Anti-flexorische Rumpfpanzerung (Stuart McGill Standard) und Indoor-Konditionierung.",
                                        exercises: [
                                            ProgramExerciseItem(name: "McGill Modifizierter Curl-Up (Haende unter LWS)", targetSets: 4, targetReps: "6x 8s Hold", rpeTarget: "RIR 2", restSeconds: 60, techniqueNotes: "Nur Kopf/Schultern 2cm anheben, LWS bleibt voellig unbewegt.", isBWKCoreRehaSafe: true),
                                            ProgramExerciseItem(name: "McGill Bird-Dog mit neutralem Becken", targetSets: 4, targetReps: "6x 8s Hold pro Seite", rpeTarget: "RIR 2", restSeconds: 60, techniqueNotes: "Bauch aktiv einziehen, kein Durchhaengen.", isBWKCoreRehaSafe: true),
                                            ProgramExerciseItem(name: "Copenhagen Plank (Knie auf Stuhl/Bett)", targetSets: 3, targetReps: "20s pro Seite", rpeTarget: "RIR 2", restSeconds: 60, techniqueNotes: "Schliesst das Becken seitlich ab und schuetzt die Leiste.", isBWKCoreRehaSafe: true),
                                            ProgramExerciseItem(name: "Deadbug mit Rueckendruck gegen Boden", targetSets: 4, targetReps: "8 pro Seite", rpeTarget: "RIR 2", restSeconds: 60, techniqueNotes: "Bauchnabel fest nach innen saugen, Ruecken flach am Boden.", isBWKCoreRehaSafe: true),
                                            ProgramExerciseItem(name: "Shadow Boxing & Fast-Marching (Stuben-Konditionierung)", targetSets: 4, targetReps: "3 min", rpeTarget: "RPE 8", restSeconds: 60, techniqueNotes: "Zone-2 bis HIIT Herzfrequenz im Zimmer erzeugen.", isBWKCoreRehaSafe: true)
                                        ]
                                    )
                                ]
                            )
                        ]
                    )
                ]
            )
        ]
    }

}
