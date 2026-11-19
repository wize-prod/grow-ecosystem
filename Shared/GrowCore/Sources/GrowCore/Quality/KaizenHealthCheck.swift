import Foundation
import SQLite3

public struct DatabaseHealthReport: Sendable {
    public let isHealthy: Bool
    public let integrityResult: String
    public let pageCount: Int
    public let pageSizeBytes: Int
    public let walSizeBytes: Int64
    public let totalSizeBytes: Int64

    public init(
        isHealthy: Bool,
        integrityResult: String,
        pageCount: Int,
        pageSizeBytes: Int,
        walSizeBytes: Int64,
        totalSizeBytes: Int64
    ) {
        self.isHealthy = isHealthy
        self.integrityResult = integrityResult
        self.pageCount = pageCount
        self.pageSizeBytes = pageSizeBytes
        self.walSizeBytes = walSizeBytes
        self.totalSizeBytes = totalSizeBytes
    }
}

public final class KaizenHealthCheck: @unchecked Sendable {
    public static let shared = KaizenHealthCheck()
    private let db: GrowDatabase

    public init(database: GrowDatabase = .shared) {
        self.db = database
    }

    public func runHealthAudit() -> DatabaseHealthReport {
        return db.performSync { dbPtr -> DatabaseHealthReport in
            guard let dbPtr = dbPtr else {
                return DatabaseHealthReport(
                    isHealthy: false,
                    integrityResult: "DB pointer is null",
                    pageCount: 0,
                    pageSizeBytes: 0,
                    walSizeBytes: 0,
                    totalSizeBytes: 0
                )
            }

            var resultString = "unknown"
            var stmt: OpaquePointer?
            if sqlite3_prepare_v2(dbPtr, "PRAGMA quick_check;", -1, &stmt, nil) == SQLITE_OK {
                if sqlite3_step(stmt) == SQLITE_ROW {
                    if let text = sqlite3_column_text(stmt, 0) {
                        resultString = String(cString: text)
                    }
                }
            }
            sqlite3_finalize(stmt)

            var pageCount = 0
            if sqlite3_prepare_v2(dbPtr, "PRAGMA page_count;", -1, &stmt, nil) == SQLITE_OK {
                if sqlite3_step(stmt) == SQLITE_ROW {
                    pageCount = Int(sqlite3_column_int(stmt, 0))
                }
            }
            sqlite3_finalize(stmt)

            var pageSize = 4096
            if sqlite3_prepare_v2(dbPtr, "PRAGMA page_size;", -1, &stmt, nil) == SQLITE_OK {
                if sqlite3_step(stmt) == SQLITE_ROW {
                    pageSize = Int(sqlite3_column_int(stmt, 0))
                }
            }
            sqlite3_finalize(stmt)

            let isHealthy = (resultString == "ok")

            // Kaizen: Truncate checkpoint to prevent WAL explosion if healthy
            if isHealthy {
                sqlite3_exec(dbPtr, "PRAGMA wal_checkpoint(TRUNCATE);", nil, nil, nil)
            }

            let totalBytes = Int64(pageCount * pageSize)

            return DatabaseHealthReport(
                isHealthy: isHealthy,
                integrityResult: resultString,
                pageCount: pageCount,
                pageSizeBytes: pageSize,
                walSizeBytes: 0,
                totalSizeBytes: totalBytes
            )
        }
    }
}
