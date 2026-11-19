import Foundation
import SQLite3

public final class GrowDatabase: @unchecked Sendable {
    public static let shared = GrowDatabase()

    private var db: OpaquePointer?
    private let queue = DispatchQueue(label: "com.grow.core.database", qos: .userInitiated)
    private let fileManager = FileManager.default

    public init(customPath: String? = nil) {
        let dbPath: String
        if let customPath = customPath {
            dbPath = customPath
        } else {
            // Shared App Group container if available, fallback to Application Support / Documents
            let appGroupId = "group.com.nkembi.somagym"
            if let groupURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroupId) {
                try? fileManager.createDirectory(at: groupURL, withIntermediateDirectories: true)
                dbPath = groupURL.appendingPathComponent("grow_unified.sqlite").path
            } else {
                let paths = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)
                let appSupport = paths.first ?? fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let baseDir = appSupport.appendingPathComponent("GrowData", isDirectory: true)
                try? fileManager.createDirectory(at: baseDir, withIntermediateDirectories: true)
                dbPath = baseDir.appendingPathComponent("grow_unified.sqlite").path
            }
        }
        openDatabase(at: dbPath)
    }

    deinit {
        if let db = db {
            sqlite3_close(db)
        }
    }

    private func openDatabase(at path: String) {
        if sqlite3_open_v2(path, &db, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX, nil) != SQLITE_OK {
            let error = String(cString: sqlite3_errmsg(db))
            print("GrowDatabase: Failed to open SQLite database at \(path): \(error)")
            return
        }

        // Configure SQLite for high-throughput, low-latency concurrent performance
        if path != ":memory:" {
            executePragma("PRAGMA journal_mode = WAL;")
            executePragma("PRAGMA synchronous = NORMAL;")
            executePragma("PRAGMA mmap_size = 268435456;") // 256 MB memory-mapped I/O
        }
        executePragma("PRAGMA cache_size = -64000;") // 64 MB in-memory cache
        executePragma("PRAGMA temp_store = MEMORY;")
        executePragma("PRAGMA foreign_keys = ON;")

        createSchema()
    }

    private func executePragma(_ pragma: String) {
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, pragma, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_step(stmt)
        }
        sqlite3_finalize(stmt)
    }

    private func createSchema() {
        let schema = """
        -- 1. Health & Biometrics
        CREATE TABLE IF NOT EXISTS health_measurements (
            id TEXT PRIMARY KEY,
            timestamp REAL NOT NULL,
            weight_kg REAL NOT NULL,
            body_fat_pct REAL,
            muscle_mass_kg REAL,
            impedance_ohms REAL,
            source TEXT NOT NULL
        );
        CREATE INDEX IF NOT EXISTS idx_health_measurements_ts ON health_measurements(timestamp DESC);

        -- 2. Workouts & Sets
        CREATE TABLE IF NOT EXISTS workouts (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            start_time REAL NOT NULL,
            end_time REAL,
            duration_sec INTEGER NOT NULL DEFAULT 0,
            tonnage_kg REAL NOT NULL DEFAULT 0,
            notes TEXT
        );
        CREATE INDEX IF NOT EXISTS idx_workouts_start ON workouts(start_time DESC);

        CREATE TABLE IF NOT EXISTS workout_sets (
            id TEXT PRIMARY KEY,
            workout_id TEXT NOT NULL,
            exercise_name TEXT NOT NULL,
            set_index INTEGER NOT NULL,
            weight_kg REAL NOT NULL,
            reps INTEGER NOT NULL,
            rpe REAL,
            is_warmup INTEGER NOT NULL DEFAULT 0,
            FOREIGN KEY(workout_id) REFERENCES workouts(id) ON DELETE CASCADE
        );
        CREATE INDEX IF NOT EXISTS idx_sets_exercise ON workout_sets(exercise_name, weight_kg DESC);

        -- 3. Nutrition & Hydration
        CREATE TABLE IF NOT EXISTS meals (
            id TEXT PRIMARY KEY,
            date_key TEXT NOT NULL,
            timestamp REAL NOT NULL,
            name TEXT NOT NULL,
            calories REAL NOT NULL,
            protein_g REAL NOT NULL,
            carbs_g REAL NOT NULL,
            fat_g REAL NOT NULL,
            meal_type TEXT NOT NULL
        );
        CREATE INDEX IF NOT EXISTS idx_meals_date ON meals(date_key);

        CREATE TABLE IF NOT EXISTS hydration (
            date_key TEXT PRIMARY KEY,
            total_ml REAL NOT NULL,
            target_ml REAL NOT NULL,
            last_updated REAL NOT NULL
        );

        CREATE TABLE IF NOT EXISTS supplements (
            id TEXT PRIMARY KEY,
            dose_id TEXT NOT NULL,
            name TEXT NOT NULL,
            scheduled_time TEXT NOT NULL,
            is_taken INTEGER NOT NULL DEFAULT 0,
            date_key TEXT NOT NULL
        );
        CREATE INDEX IF NOT EXISTS idx_supplements_date ON supplements(date_key);

        -- 4. Tasks & Academic Progress (HsH & BFD)
        CREATE TABLE IF NOT EXISTS tasks (
            id TEXT PRIMARY KEY,
            track TEXT NOT NULL,
            phase TEXT NOT NULL,
            title TEXT NOT NULL,
            is_completed INTEGER NOT NULL DEFAULT 0,
            planned_date REAL,
            priority INTEGER NOT NULL DEFAULT 1,
            estimated_minutes INTEGER NOT NULL DEFAULT 25,
            notes TEXT
        );
        CREATE INDEX IF NOT EXISTS idx_tasks_track_phase ON tasks(track, phase);
        CREATE INDEX IF NOT EXISTS idx_tasks_planned ON tasks(planned_date);

        -- 5. Finance Ledger & 5-Gate Audits
        CREATE TABLE IF NOT EXISTS transactions (
            id TEXT PRIMARY KEY,
            date REAL NOT NULL,
            amount REAL NOT NULL,
            currency TEXT NOT NULL DEFAULT 'EUR',
            recipient TEXT NOT NULL,
            category TEXT NOT NULL,
            is_fixed INTEGER NOT NULL DEFAULT 0,
            gate_status TEXT NOT NULL DEFAULT 'PASSED',
            quarantine_release_date REAL
        );
        CREATE INDEX IF NOT EXISTS idx_trans_date ON transactions(date DESC);
        CREATE INDEX IF NOT EXISTS idx_trans_cat ON transactions(category);

        -- 6. High-Performance Unified Search Index
        CREATE TABLE IF NOT EXISTS search_index (
            id TEXT PRIMARY KEY,
            entity_type TEXT NOT NULL, -- 'EXERCISE', 'SUPPLEMENT', 'TRANSACTION', 'TASK', 'PANTRY'
            entity_id TEXT NOT NULL,
            title TEXT NOT NULL,
            subtitle TEXT NOT NULL,
            keywords TEXT NOT NULL,
            metadata_json TEXT
        );
        CREATE INDEX IF NOT EXISTS idx_search_keywords ON search_index(keywords);
        CREATE INDEX IF NOT EXISTS idx_search_title ON search_index(title);
        """

        var err: UnsafeMutablePointer<CChar>?
        if sqlite3_exec(db, schema, nil, nil, &err) != SQLITE_OK {
            let errorMsg = err != nil ? String(cString: err!) : "Unknown error"
            print("GrowDatabase: Schema migration failure: \(errorMsg)")
            sqlite3_free(err)
        }
    }

    // MARK: - Synchronous & Asynchronous Safe Execution
    public func performSync<T>(_ block: (OpaquePointer?) throws -> T) rethrows -> T {
        return try queue.sync {
            return try block(self.db)
        }
    }

    public func performAsync(_ block: @escaping (OpaquePointer?) -> Void) {
        queue.async {
            block(self.db)
        }
    }
}
