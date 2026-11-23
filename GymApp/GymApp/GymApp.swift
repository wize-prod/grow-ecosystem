import SwiftUI
import GrowCore

@main
struct GymApp: App {
    @StateObject private var store = GymStore.shared
    @StateObject private var calService = CalendarSyncService.shared
    @StateObject private var healthService = HealthKitService.shared
    @StateObject private var growceryService = GrowcerySyncService.shared

    init() {
        GrowPeerSyncService.shared.start()

        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = UIColor(red: 0.109, green: 0.109, blue: 0.118, alpha: 0.95) // #1C1C1E
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().unselectedItemTintColor = UIColor(red: 0.556, green: 0.556, blue: 0.576, alpha: 1.0) // #8E8E93
    }

    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .preferredColorScheme(.dark)
                .background(GymTheme.bg.ignoresSafeArea())
                .environmentObject(store)
                .onAppear {
                    healthService.checkAndRequestAuthorization()
                    calService.fetchUpcomingWorkouts()
                    healthService.fetchAllHealthData()
                    growceryService.refreshData()
                    processLaunchArguments()
                }
                .onChange(of: scenePhase) { newPhase in
                    if newPhase == .active {
                        growceryService.refreshData()
                        healthService.fetchAllHealthData()
                    }
                }
                .onOpenURL { url in
                    _ = growceryService.handleIncomingURL(url)
                    handleWorkoutURL(url)
                }
        }
    }

    private func handleWorkoutURL(_ url: URL) {
        guard url.scheme == "gym" || url.scheme == "grow" else { return }
        let host = url.host ?? ""
        let path = url.path
        let comps = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let query = comps?.queryItems ?? []

        if host == "workout" || host == "start" || path.contains("workout") {
            if path.contains("finish") || query.first(where: { $0.name == "action" })?.value == "finish" {
                let codeStr = query.first(where: { $0.name == "exitCode" })?.value ?? "0"
                let exitCode = Int(codeStr) ?? 0
                Task {
                    await store.finishWorkoutWithScalar(exitCode: exitCode)
                }
                return
            }

            if path.contains("completeSet") || query.first(where: { $0.name == "action" })?.value == "completeSet" {
                let exIdx = Int(query.first(where: { $0.name == "exerciseIndex" })?.value ?? "0") ?? 0
                let setIdx = Int(query.first(where: { $0.name == "setIndex" })?.value ?? "0") ?? 0
                let weight = Double(query.first(where: { $0.name == "weight" })?.value ?? "0") ?? 0.0
                let reps = Int(query.first(where: { $0.name == "reps" })?.value ?? "10") ?? 10

                if let session = store.activeSession, exIdx < session.exercises.count {
                    let exId = session.exercises[exIdx].id
                    if setIdx < session.exercises[exIdx].sets.count {
                        let setId = session.exercises[exIdx].sets[setIdx].id
                        store.updateSetWeight(exerciseId: exId, setId: setId, weight: weight)
                        store.updateSetReps(exerciseId: exId, setId: setId, reps: reps)
                        store.toggleSet(exerciseId: exId, setId: setId)
                    }
                }
                return
            }

            // Start workout by plannedId
            if let plannedIdStr = query.first(where: { $0.name == "plannedId" || $0.name == "id" })?.value,
               let plannedUUID = UUID(uuidString: plannedIdStr),
               let planned = store.plannedWorkouts.first(where: { $0.id == plannedUUID }) {
                store.startWorkout(from: planned)
                return
            }

            // Start workout by title
            if let title = query.first(where: { $0.name == "title" || $0.name == "name" })?.value {
                if let planned = store.plannedWorkouts.first(where: { $0.title.localizedCaseInsensitiveContains(title) && !$0.isCompleted }) {
                    store.startWorkout(from: planned)
                    return
                }
            }

            // Fallback: Start first uncompleted planned workout for today, or start free workout
            let todayPlanned = store.plannedWorkouts.first(where: {
                Calendar.current.isDateInToday($0.plannedDate) && !$0.isCompleted
            })
            if let todayPlanned = todayPlanned {
                store.startWorkout(from: todayPlanned)
            } else {
                store.startWorkout()
            }
        }
    }

    private func processLaunchArguments() {
        if CommandLine.arguments.contains("-StartTodayWorkout") {
            let todayPlanned = store.plannedWorkouts.first(where: {
                Calendar.current.isDateInToday($0.plannedDate) && !$0.isCompleted
            })
            if let planned = todayPlanned {
                store.startWorkout(from: planned)
            } else {
                store.startWorkout()
            }
        } else if let idx = CommandLine.arguments.firstIndex(of: "-StartWorkoutFromPlanned"), idx + 1 < CommandLine.arguments.count {
            let query = CommandLine.arguments[idx + 1]
            if let match = store.plannedWorkouts.first(where: { $0.title.localizedCaseInsensitiveContains(query) && !$0.isCompleted }) {
                store.startWorkout(from: match)
            }
        } else if CommandLine.arguments.contains("-StartFreeWorkout") {
            store.startWorkout()
        }

        if let idx = CommandLine.arguments.firstIndex(of: "-AddExercise"), idx + 1 < CommandLine.arguments.count {
            let exName = CommandLine.arguments[idx + 1]
            let resolved = store.exercises.first(where: { $0.name.localizedCaseInsensitiveContains(exName) })
                ?? ExerciseSearchEngine.shared.search(query: exName, in: store.exercises, store: store).first
            if let resolved = resolved {
                store.addExerciseToActiveWorkout(resolved)
            }
        }

        if CommandLine.arguments.contains("-AddSet") {
            if let session = store.activeSession, let firstEx = session.exercises.first {
                store.addSet(to: firstEx.id)
            }
        }

        if CommandLine.arguments.contains("-TogglePause") {
            store.toggleActiveWorkoutPause()
        }

        if CommandLine.arguments.contains("-OpenActiveWorkout") {
            store.isPresentingActiveWorkout = true
        }

        if CommandLine.arguments.contains("-CompleteAllSets") {
            store.isPresentingActiveWorkout = true
            if let session = store.activeSession {
                for ex in session.exercises {
                    let isCalisthenics = ex.exercise.equipment == .bodyweight || ex.exercise.equipment == .pullUpBar || ex.exercise.equipment == .dipStation || ex.exercise.equipment == .gymRings || ex.exercise.equipment == .matArea || ex.exercise.equipment == .stretchingMat || ex.exercise.categoryTypeEnum == .core || ex.exercise.categoryTypeEnum == .mobility || ex.exercise.targetMuscle == .functionalCore
                    let defaultWeight = isCalisthenics ? 0.0 : 60.0
                    for setRec in ex.sets {
                        let w = setRec.weightKg > 0 ? setRec.weightKg : (store.previousPerformance(for: ex.exercise.name, setIndex: setRec.setNumber - 1)?.weightKg ?? defaultWeight)
                        let r = setRec.reps > 0 ? setRec.reps : (ex.exercise.defaultReps > 0 ? ex.exercise.defaultReps : 10)
                        store.updateSetWeight(exerciseId: ex.id, setId: setRec.id, weight: w)
                        store.updateSetReps(exerciseId: ex.id, setId: setRec.id, reps: r)
                        if !setRec.isCompleted {
                            store.toggleSet(exerciseId: ex.id, setId: setRec.id)
                        }
                    }
                }
            }
        }

        if CommandLine.arguments.contains("-CancelWorkout") {
            store.cancelWorkout()
        }

        if let idx = CommandLine.arguments.firstIndex(of: "-FinishWithExitCode"), idx + 1 < CommandLine.arguments.count {
            let code = Int(CommandLine.arguments[idx + 1]) ?? 0
            Task {
                await store.finishWorkoutWithScalar(exitCode: code)
            }
        } else if CommandLine.arguments.contains("-FinishActiveWorkout") {
            Task {
                await store.finishWorkoutWithScalar(exitCode: 0)
            }
        }
        if let idx = CommandLine.arguments.firstIndex(of: "-SelectTab"), idx + 1 < CommandLine.arguments.count {
            if let tab = Int(CommandLine.arguments[idx + 1]) {
                UserDefaults.standard.set(tab, forKey: "main_selected_tab")
                NotificationCenter.default.post(name: NSNotification.Name("SwitchMainTab"), object: tab)
            }
        }

        if CommandLine.arguments.contains("-PreviewFirstPlanned") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if let planned = store.plannedWorkouts.first(where: { !$0.isCompleted }) {
                    NotificationCenter.default.post(name: NSNotification.Name("OpenWorkoutPreview"), object: planned)
                } else {
                    let firstTpl = store.templates.first
                    let item = PlannedWorkoutItem(
                        id: UUID(),
                        title: firstTpl?.name ?? "Push & Reha Stabilisation",
                        plannedDate: Date(),
                        isCompleted: false,
                        templateId: firstTpl?.id,
                        exerciseNames: firstTpl?.items.map { $0.exercise.name } ?? ["Bankdruecken", "Chest Supported Row"]
                    )
                    store.plannedWorkouts.append(item)
                    NotificationCenter.default.post(name: NSNotification.Name("OpenWorkoutPreview"), object: item)
                }
            }
        }

        if CommandLine.arguments.contains("-InspectFirstCompleted") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if store.sessions.isEmpty {
                    let sampleEx = store.exercises.first ?? Exercise(name: "Latziehen zur Brust", targetMuscle: .back, equipment: .latPulldownMachine)
                    let session = WorkoutSession(
                        id: UUID(),
                        title: "Oberkoerper Push & Pull",
                        startTime: Date().addingTimeInterval(-3600),
                        endTime: Date(),
                        exercises: [
                            WorkoutExerciseRecord(
                                id: UUID(),
                                exercise: sampleEx,
                                sets: [
                                    WorkoutSetRecord(setNumber: 1, weightKg: 65.0, reps: 10, isCompleted: true, rpe: 8.0),
                                    WorkoutSetRecord(setNumber: 2, weightKg: 70.0, reps: 8, isCompleted: true, rpe: 8.5)
                                ]
                            )
                        ]
                    )
                    store.sessions.insert(session, at: 0)
                }
                store.inspectingCompletedSession = store.sessions.first
            }
        }

        if CommandLine.arguments.contains("-TestIPCSync") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                runAutomatedIPCTest(store: store)
            }
        }
    }

    private func runAutomatedIPCTest(store: GymStore) {
        let startTime = CFAbsoluteTimeGetCurrent()
        var darwinEventCount = 0
        var coreEventCount = 0

        DarwinNotificationCenter.observe(DarwinNotificationCenter.workoutScheduleLedgerUpdated) {
            darwinEventCount += 1
        }

        GrowDarwinEventBus.shared.observe(.workoutStateUpdated) {
            coreEventCount += 1
        }

        let testWorkoutId = UUID()
        let testTitle = "Phase 5 IPC Synchronisations-Testeinheit"
        let plannedItem = PlannedWorkoutItem(
            id: testWorkoutId,
            title: testTitle,
            plannedDate: Date(),
            isCompleted: true,
            completedAt: Date(),
            notes: "Zero-Latency Dual-Bus Darwin IPC Test Payload",
            exerciseNames: ["Bankdruecken", "Latziehen zur Brust", "Kniebeugen"]
        )
        store.plannedWorkouts.removeAll(where: { $0.title == testTitle })
        store.plannedWorkouts.insert(plannedItem, at: 0)
        store.savePlannedWorkouts()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            let elapsedMs = (CFAbsoluteTimeGetCurrent() - startTime) * 1000.0
            let loadedLedger = GrowSuiteBridge.shared.loadWorkoutScheduleLedger()
            let foundInBridge = loadedLedger.items.first(where: { $0.title == testTitle }) != nil

            let verificationPayload: [String: Any] = [
                "timestamp": ISO8601DateFormatter().string(from: Date()),
                "darwinNotificationReceived": darwinEventCount > 0,
                "growCoreEventReceived": coreEventCount > 0,
                "bridgePayloadVerified": foundInBridge,
                "latencyMs": elapsedMs,
                "itemsCount": loadedLedger.items.count,
                "testTitle": testTitle,
                "status": (foundInBridge && darwinEventCount > 0 && coreEventCount > 0) ? "VERIFIED_SUCCESS" : (foundInBridge ? "VERIFIED_BRIDGE_SUCCESS" : "FAILED")
            ]

            if let jsonData = try? JSONSerialization.data(withJSONObject: verificationPayload, options: .prettyPrinted) {
                let jsonString = String(data: jsonData, encoding: .utf8) ?? ""
                print("[IPC_TEST_RESULT_BEGIN]\n\(jsonString)\n[IPC_TEST_RESULT_END]")
                if let docDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                    let outURL = docDir.appendingPathComponent("ipc_verification_receipt.json")
                    try? jsonData.write(to: outURL)
                }
            }
        }
    }
}
