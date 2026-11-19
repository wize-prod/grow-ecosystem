import XCTest
@testable import GrowCore

final class GrowCoreTests: XCTestCase {
    func testDatabaseAndSearchIndex() {
        let db = GrowDatabase(customPath: ":memory:")
        let search = GrowUnifiedSearchEngine(database: db)

        search.indexEntity(
            type: "EXERCISE",
            entityId: "ex_bench_01",
            title: "Bankdrücken Langhantel",
            subtitle: "Brust / Trizeps • 100 kg PB",
            keywords: ["brust", "chest", "push", "bankdruecken"]
        )

        search.indexEntity(
            type: "SUPPLEMENT",
            entityId: "supp_creatine",
            title: "Kreatin Monohydrat",
            subtitle: "5g tägl. • Vorrat: 450g",
            keywords: ["kreatin", "creatine", "kraft", "pantry"]
        )

        let benchResults = search.search(query: "bankdrücken")
        XCTAssertFalse(benchResults.isEmpty, "Should find Bankdrücken")

        let creatinResults = search.search(query: "kreatin")
        XCTAssertFalse(creatinResults.isEmpty, "Should find Kreatin")
    }

    func testPokaYokeValidation() {
        // 1. Water Intake
        XCTAssertNoThrow(try PokaYokeValidator.validateWaterIntake(2500.0))
        XCTAssertThrowsError(try PokaYokeValidator.validateWaterIntake(15000.0))
        XCTAssertThrowsError(try PokaYokeValidator.validateWaterIntake(-100.0))

        // 2. Weight Delta (4kg max per 24h)
        XCTAssertNoThrow(try PokaYokeValidator.validateWeightChange(previousKg: 82.0, newKg: 83.2))
        XCTAssertThrowsError(try PokaYokeValidator.validateWeightChange(previousKg: 82.0, newKg: 90.0))

        // 3. Transactions
        XCTAssertNoThrow(try PokaYokeValidator.validateTransaction(amount: 45.99))
        XCTAssertThrowsError(try PokaYokeValidator.validateTransaction(amount: -10.0))
        XCTAssertThrowsError(try PokaYokeValidator.validateTransaction(amount: 0.0))

        // 4. Macro Discrepancy (Atwater factors)
        XCTAssertNoThrow(try PokaYokeValidator.validateNutritionMacros(calories: 500, proteinG: 40, carbsG: 50, fatG: 15)) // 40*4 + 50*4 + 15*9 = 160 + 200 + 135 = 495
        XCTAssertThrowsError(try PokaYokeValidator.validateNutritionMacros(calories: 1200, proteinG: 20, carbsG: 20, fatG: 5)) // 80 + 80 + 45 = 205 vs 1200
    }

    func testKaizenHealthCheck() {
        let db = GrowDatabase(customPath: ":memory:")
        let kaizen = KaizenHealthCheck(database: db)
        let report = kaizen.runHealthAudit()
        XCTAssertTrue(report.isHealthy, "In-memory database should pass health check")
    }

    func testBatchExecutionEngine() {
        let engine = BatchExecutionEngine.shared
        let res = engine.batchToggleTasks(taskIds: ["task_1", "task_2"], isCompleted: true)
        XCTAssertTrue(res.isSuccess, "Batch task toggle should succeed")
    }

    func testPokaYokeReconciler() {
        // Test hydration monotonic merge
        let localH2O = 1500.0
        let incomingH2O = 2200.0
        let mergedH2O = PokaYokeReconciler.reconcileHydration(localMl: localH2O, incomingMl: incomingH2O)
        XCTAssertEqual(mergedH2O, 2200.0)

        // Test supplement protection (taken state is never lost)
        let localDoses = [
            PokaYokeReconciler.ReconcilableDose(id: "d1", scheduledTime: "06:00", isTaken: true),
            PokaYokeReconciler.ReconcilableDose(id: "d2", scheduledTime: "12:00", isTaken: false)
        ]
        let incomingDoses = [
            PokaYokeReconciler.ReconcilableDose(id: "d1", scheduledTime: "06:00", isTaken: false), // Stale node thinks not taken
            PokaYokeReconciler.ReconcilableDose(id: "d2", scheduledTime: "12:00", isTaken: true)   // Node marked taken
        ]
        let merged = PokaYokeReconciler.reconcileDoses(localDoses, incomingDoses)
        let d1 = merged.first { $0.id == "d1" }
        let d2 = merged.first { $0.id == "d2" }
        XCTAssertEqual(d1?.isTaken, true, "Dose 1 must remain taken to prevent double dosing")
        XCTAssertEqual(d2?.isTaken, true, "Dose 2 must be taken")
    }

    func testGrowMMKVFastStorage() {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_mmkv_\(UUID().uuidString).bin")
        let mmkv = GrowMMKV(customURL: tempURL)

        mmkv.set("Kreatin Monohydrat", forKey: "supp_name")
        mmkv.set(2500.0, forKey: "target_h2o")
        mmkv.set(160, forKey: "protein_target")
        mmkv.set(true, forKey: "is_fasting")

        XCTAssertEqual(mmkv.string(forKey: "supp_name"), "Kreatin Monohydrat")
        XCTAssertEqual(mmkv.double(forKey: "target_h2o"), 2500.0)
        XCTAssertEqual(mmkv.int(forKey: "protein_target"), 160)
        XCTAssertEqual(mmkv.bool(forKey: "is_fasting"), true)

        mmkv.removeValue(forKey: "supp_name")
        XCTAssertNil(mmkv.string(forKey: "supp_name"))
        try? FileManager.default.removeItem(at: tempURL)
    }

    func testFeliCaTransactionLedger() {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_felica_\(UUID().uuidString).bin")
        let mmkv = GrowMMKV(customURL: tempURL)
        let ledger = FeliCaTransactionLedger(mmkv: mmkv)

        // Execute transactions and verify latency < 50ms
        let r1 = ledger.executeTransaction(domain: "FINANCE", operation: "EXPENSE_5GATE", amountOrValue: 42.50, payloadJson: "{\"store\":\"Rewe\"}")
        XCTAssertTrue(r1.isSuccess, "Transaction 1 must complete within hard deadline")
        XCTAssertEqual(r1.sequenceNumber, 1)

        let r2 = ledger.executeTransaction(domain: "NUTRITION", operation: "WATER_LOG", amountOrValue: 500.0, payloadJson: "{\"ml\":500}")
        XCTAssertTrue(r2.isSuccess, "Transaction 2 must complete within hard deadline")
        XCTAssertEqual(r2.sequenceNumber, 2)

        // Verify cryptographic SHA-256 chain integrity
        let integrity = ledger.verifyChainIntegrity()
        XCTAssertTrue(integrity.isValid, "Cryptographic block chain must be tamper-proof")
        XCTAssertEqual(integrity.verifiedBlocks, 2)

        try? FileManager.default.removeItem(at: tempURL)
    }

    func testPokaYokeStateMachine() {
        // 1. Dose State Machine (Terminal Ingestion)
        let scheduled = DoseLifecycle.scheduled(timeString: "06:00")
        XCTAssertFalse(scheduled.isTaken)

        let ingested = scheduled.transition(to: .sealedTaken(takenAt: Date(), sourceNode: "iPhone"))
        XCTAssertTrue(ingested.isTaken)

        // Attempt invalid regression
        let regressionAttempt = ingested.transition(to: .scheduled(timeString: "06:00"))
        XCTAssertTrue(regressionAttempt.isTaken, "Poka-Yoke: Dose must remain taken, regression rejected")

        // 2. Expense Gate State Machine
        let pending = ExpenseGateLifecycle.pendingAudit(amountEur: 120.0)
        XCTAssertFalse(pending.isApproved)

        let approved = ExpenseGateLifecycle.fullyApproved(approvalDate: Date(), safeBalanceRemaining: 85.0)
        XCTAssertTrue(approved.isApproved)
    }

    func testClinicalContraindicationGate() {
        // 1. Amlodipine (Blood pressure) + Rhodiola / Nitrate must be BLOCKED
        let codeRhodiola = grow_core_screen_contraindication("Amlodipine", "Rhodiola_Rosea")
        XCTAssertEqual(codeRhodiola, GROW_BLOCKED_HYPERTENSIVE_INTERACTION)

        let codeNitrate = grow_core_screen_contraindication("Ramipril", "Rote_Bete_Nitrat")
        XCTAssertEqual(codeNitrate, GROW_BLOCKED_HYPERTENSIVE_INTERACTION)

        // 2. Vitamin D3 + K2 and Magnesium must be CLEARED
        let codeD3 = grow_core_screen_contraindication("Amlodipine", "Vitamin D3 + K2")
        XCTAssertEqual(codeD3, GROW_STATUS_CLEARED)

        let codeMag = grow_core_screen_contraindication("Amlodipine", "Magnesium_Bisglycinat")
        XCTAssertEqual(codeMag, GROW_STATUS_CLEARED)

        // 3. SSRI + St. John's Wort / 5-HTP must trigger Serotonin Syndrome Veto
        let codeSSRI = grow_core_screen_contraindication("Sertraline", "St_Johns_Wort")
        XCTAssertEqual(codeSSRI, GROW_BLOCKED_SEROTONIN_SYNDROME)

        let code5HTP = grow_core_screen_contraindication("Escitalopram", "5_HTP")
        XCTAssertEqual(code5HTP, GROW_BLOCKED_SEROTONIN_SYNDROME)

        // 4. Anticoagulant + Ginkgo must trigger Bleeding Veto
        let codeGinkgo = grow_core_screen_contraindication("Warfarin", "Ginkgo_Biloba")
        XCTAssertEqual(codeGinkgo, GROW_BLOCKED_BLEEDING_RISK)
    }

    func testBiomechanicalExerciseSafetyGate() {
        // 1. Axial spinal loading filter
        XCTAssertFalse(grow_core_is_exercise_safe("NO_AXIAL_SPINAL_LOADING", "Barbell_Squat"))
        XCTAssertFalse(grow_core_is_exercise_safe("NO_AXIAL_SPINAL_LOADING", "Conventional_Deadlift"))
        XCTAssertTrue(grow_core_is_exercise_safe("NO_AXIAL_SPINAL_LOADING", "Seated_Cable_Row"))
        XCTAssertTrue(grow_core_is_exercise_safe("NO_AXIAL_SPINAL_LOADING", "Glute_Bridge_Mat"))

        // 2. High impact plyometric filter for Osteopenia
        XCTAssertFalse(grow_core_is_exercise_safe("OSTEOPENIA", "Box_Jump"))
        XCTAssertFalse(grow_core_is_exercise_safe("OSTEOPENIA", "Burpee"))
        XCTAssertTrue(grow_core_is_exercise_safe("OSTEOPENIA", "Controlled_Leg_Press"))
    }

    func testUserProfileContractAssemblyAndJSONRoundtrip() throws {
        let identity = UserProfileContract.ContractIdentity(
            userId: "usr_mama_test",
            displayName: "Mama",
            biologicalSex: .female,
            age: 58,
            heightCm: 165.0,
            weightKg: 68.0
        )

        let candidateSupplements = [
            ("08:00", "Vitamin D3 + K2", "2000 IE", "Knochendichte"),
            ("08:00", "Rhodiola_Rosea", "500 mg", "Energie"), // Must be dropped due to Amlodipine
            ("21:00", "Magnesium_Bisglycinat", "300 mg", "Entspannung")
        ]

        let candidateExercises = [
            "Barbell_Squat", // Must be dropped due to Osteopenia
            "Conventional_Deadlift", // Must be dropped
            "Seated_Cable_Row",
            "Glute_Bridge_Mat",
            "Controlled_Leg_Press"
        ]

        let contract = UserProfileContractAssembler.assembleProfile(
            identity: identity,
            conditions: ["HYPERTENSION", "OSTEOPENIA"],
            medications: ["AMLODIPINE"],
            candidateSupplements: candidateSupplements,
            candidateExercises: candidateExercises,
            activityMultiplier: 1.30
        )

        // Verifications
        XCTAssertTrue(contract.nutritionTargets.dailyCaloriesKcal >= 1500 && contract.nutritionTargets.dailyCaloriesKcal <= 1700)
        XCTAssertEqual(contract.nutritionTargets.dailyProteinG, 92) // 68 kg * 1.35 g/kg = 91.8 -> 92 g
        XCTAssertEqual(contract.circadianSupplementSchedule.count, 2, "Rhodiola must be filtered out by Poka-Yoke gate")
        XCTAssertFalse(contract.circadianSupplementSchedule.contains { $0.substance.contains("Rhodiola") })

        XCTAssertEqual(contract.trainingCadence.allowedModalities.count, 3, "Axial exercises must be filtered out")
        XCTAssertFalse(contract.trainingCadence.allowedModalities.contains("Barbell_Squat"))
        XCTAssertFalse(contract.trainingCadence.allowedModalities.contains("Conventional_Deadlift"))

        // JSON Roundtrip verification
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let jsonData = try encoder.encode(contract)
        XCTAssertFalse(jsonData.isEmpty)

        let decoded = try JSONDecoder().decode(UserProfileContract.self, from: jsonData)
        XCTAssertEqual(contract, decoded, "Contract must survive lossless JSON serialization")
    }
}
