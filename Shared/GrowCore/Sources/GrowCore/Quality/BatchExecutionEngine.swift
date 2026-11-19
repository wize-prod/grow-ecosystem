import Foundation
import SQLite3

public struct BatchExecutionResult: Sendable {
    public let affectedCount: Int
    public let executionTimeMs: Double
    public let isSuccess: Bool
    public let errorMessage: String?

    public init(affectedCount: Int, executionTimeMs: Double, isSuccess: Bool, errorMessage: String? = nil) {
        self.affectedCount = affectedCount
        self.executionTimeMs = executionTimeMs
        self.isSuccess = isSuccess
        self.errorMessage = errorMessage
    }
}

public final class BatchExecutionEngine: @unchecked Sendable {
    public static let shared = BatchExecutionEngine()
    private let db = GrowDatabase.shared

    public init() {}

    public func batchMarkSupplementsTaken(doseIds: [String], isTaken: Bool = true, dateKey: String) -> BatchExecutionResult {
        guard !doseIds.isEmpty else {
            return BatchExecutionResult(affectedCount: 0, executionTimeMs: 0.0, isSuccess: true)
        }

        let start = CFAbsoluteTimeGetCurrent()
        return db.performSync { dbPtr -> BatchExecutionResult in
            guard let dbPtr = dbPtr else {
                return BatchExecutionResult(affectedCount: 0, executionTimeMs: 0.0, isSuccess: false, errorMessage: "DB null")
            }

            sqlite3_exec(dbPtr, "BEGIN IMMEDIATE TRANSACTION;", nil, nil, nil)

            let sql = """
            UPDATE supplements
            SET is_taken = ?
            WHERE dose_id = ? AND date_key = ?;
            """

            var stmt: OpaquePointer?
            var affected = 0
            if sqlite3_prepare_v2(dbPtr, sql, -1, &stmt, nil) == SQLITE_OK {
                for doseId in doseIds {
                    sqlite3_reset(stmt)
                    sqlite3_bind_int(stmt, 1, isTaken ? 1 : 0)
                    sqlite3_bind_text(stmt, 2, (doseId as NSString).utf8String, -1, nil)
                    sqlite3_bind_text(stmt, 3, (dateKey as NSString).utf8String, -1, nil)
                    if sqlite3_step(stmt) == SQLITE_DONE {
                        affected += 1
                    }
                }
            }
            sqlite3_finalize(stmt)

            sqlite3_exec(dbPtr, "COMMIT;", nil, nil, nil)
            let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000.0

            return BatchExecutionResult(affectedCount: affected, executionTimeMs: elapsed, isSuccess: true)
        }
    }

    public func batchToggleTasks(taskIds: [String], isCompleted: Bool) -> BatchExecutionResult {
        guard !taskIds.isEmpty else {
            return BatchExecutionResult(affectedCount: 0, executionTimeMs: 0.0, isSuccess: true)
        }

        let start = CFAbsoluteTimeGetCurrent()
        return db.performSync { dbPtr -> BatchExecutionResult in
            guard let dbPtr = dbPtr else {
                return BatchExecutionResult(affectedCount: 0, executionTimeMs: 0.0, isSuccess: false, errorMessage: "DB null")
            }

            sqlite3_exec(dbPtr, "BEGIN IMMEDIATE TRANSACTION;", nil, nil, nil)

            let sql = "UPDATE tasks SET is_completed = ? WHERE id = ?;"
            var stmt: OpaquePointer?
            var affected = 0
            if sqlite3_prepare_v2(dbPtr, sql, -1, &stmt, nil) == SQLITE_OK {
                for id in taskIds {
                    sqlite3_reset(stmt)
                    sqlite3_bind_int(stmt, 1, isCompleted ? 1 : 0)
                    sqlite3_bind_text(stmt, 2, (id as NSString).utf8String, -1, nil)
                    if sqlite3_step(stmt) == SQLITE_DONE {
                        affected += 1
                    }
                }
            }
            sqlite3_finalize(stmt)

            sqlite3_exec(dbPtr, "COMMIT;", nil, nil, nil)
            let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000.0

            return BatchExecutionResult(affectedCount: affected, executionTimeMs: elapsed, isSuccess: true)
        }
    }
}
