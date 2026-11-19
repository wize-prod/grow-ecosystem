import Foundation
import SQLite3

public struct SearchResultItem: Identifiable, Equatable, Sendable {
    public let id: String
    public let entityType: String // "EXERCISE", "SUPPLEMENT", "TRANSACTION", "TASK", "PANTRY"
    public let entityId: String
    public let title: String
    public let subtitle: String
    public let categoryBadge: String
    public let metadata: [String: String]

    public init(
        id: String = UUID().uuidString,
        entityType: String,
        entityId: String,
        title: String,
        subtitle: String,
        categoryBadge: String,
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.entityType = entityType
        self.entityId = entityId
        self.title = title
        self.subtitle = subtitle
        self.categoryBadge = categoryBadge
        self.metadata = metadata
    }
}

public final class GrowUnifiedSearchEngine: @unchecked Sendable {
    public static let shared = GrowUnifiedSearchEngine()
    private let db: GrowDatabase

    public init(database: GrowDatabase = .shared) {
        self.db = database
    }

    public func indexEntity(
        type: String,
        entityId: String,
        title: String,
        subtitle: String,
        keywords: [String],
        metadataJson: String? = nil,
        synchronous: Bool = true
    ) {
        let joinedKeywords = (keywords + [title, subtitle, type]).joined(separator: " ").lowercased()
        let id = "\(type)_\(entityId)"

        let block: (OpaquePointer?) -> Void = { dbPtr in
            guard let dbPtr = dbPtr else { return }
            let sql = """
            INSERT INTO search_index (id, entity_type, entity_id, title, subtitle, keywords, metadata_json)
            VALUES (?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(id) DO UPDATE SET
                title = excluded.title,
                subtitle = excluded.subtitle,
                keywords = excluded.keywords,
                metadata_json = excluded.metadata_json;
            """
            var stmt: OpaquePointer?
            if sqlite3_prepare_v2(dbPtr, sql, -1, &stmt, nil) == SQLITE_OK {
                sqlite3_bind_text(stmt, 1, (id as NSString).utf8String, -1, nil)
                sqlite3_bind_text(stmt, 2, (type as NSString).utf8String, -1, nil)
                sqlite3_bind_text(stmt, 3, (entityId as NSString).utf8String, -1, nil)
                sqlite3_bind_text(stmt, 4, (title as NSString).utf8String, -1, nil)
                sqlite3_bind_text(stmt, 5, (subtitle as NSString).utf8String, -1, nil)
                sqlite3_bind_text(stmt, 6, (joinedKeywords as NSString).utf8String, -1, nil)
                if let meta = metadataJson {
                    sqlite3_bind_text(stmt, 7, (meta as NSString).utf8String, -1, nil)
                } else {
                    sqlite3_bind_null(stmt, 7)
                }
                sqlite3_step(stmt)
            }
            sqlite3_finalize(stmt)
        }

        if synchronous {
            db.performSync(block)
        } else {
            db.performAsync(block)
        }
    }

    public func search(query: String, limit: Int = 30) -> [SearchResultItem] {
        let cleanQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if cleanQuery.isEmpty { return [] }

        return db.performSync { dbPtr -> [SearchResultItem] in
            guard let dbPtr = dbPtr else { return [] }
            var results: [SearchResultItem] = []

            let sql = """
            SELECT entity_type, entity_id, title, subtitle, metadata_json
            FROM search_index
            WHERE keywords LIKE ? OR title LIKE ?
            ORDER BY
                CASE WHEN title LIKE ? THEN 1 ELSE 2 END,
                title ASC
            LIMIT ?;
            """

            var stmt: OpaquePointer?
            if sqlite3_prepare_v2(dbPtr, sql, -1, &stmt, nil) == SQLITE_OK {
                let pattern = "%\(cleanQuery)%"
                let exactPrefix = "\(cleanQuery)%"
                sqlite3_bind_text(stmt, 1, (pattern as NSString).utf8String, -1, nil)
                sqlite3_bind_text(stmt, 2, (pattern as NSString).utf8String, -1, nil)
                sqlite3_bind_text(stmt, 3, (exactPrefix as NSString).utf8String, -1, nil)
                sqlite3_bind_int(stmt, 4, Int32(limit))

                while sqlite3_step(stmt) == SQLITE_ROW {
                    let type = String(cString: sqlite3_column_text(stmt, 0))
                    let entityId = String(cString: sqlite3_column_text(stmt, 1))
                    let title = String(cString: sqlite3_column_text(stmt, 2))
                    let subtitle = String(cString: sqlite3_column_text(stmt, 3))

                    var metadataDict: [String: String] = [:]
                    if let metaPtr = sqlite3_column_text(stmt, 4) {
                        let metaStr = String(cString: metaPtr)
                        if let data = metaStr.data(using: .utf8),
                           let dict = try? JSONDecoder().decode([String: String].self, from: data) {
                            metadataDict = dict
                        }
                    }

                    let badge: String
                    switch type {
                    case "EXERCISE": badge = "Kraftsport"
                    case "SUPPLEMENT": badge = "Supplement"
                    case "TRANSACTION": badge = "Finanzen"
                    case "TASK": badge = "Aufgabe"
                    case "PANTRY": badge = "Vorrat"
                    default: badge = "Allgemein"
                    }

                    results.append(SearchResultItem(
                        entityType: type,
                        entityId: entityId,
                        title: title,
                        subtitle: subtitle,
                        categoryBadge: badge,
                        metadata: metadataDict
                    ))
                }
            }
            sqlite3_finalize(stmt)
            return results
        }
    }
}
