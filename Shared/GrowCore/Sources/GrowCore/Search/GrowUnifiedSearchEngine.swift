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
        self.indexDefaultEcosystemEntities()
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

        var stemmed = cleanQuery
        if cleanQuery.hasSuffix("s") && cleanQuery.count > 3 {
            stemmed = String(cleanQuery.dropLast())
        } else if cleanQuery.hasSuffix("es") && cleanQuery.count > 4 {
            stemmed = String(cleanQuery.dropLast(2))
        }

        return db.performSync { dbPtr -> [SearchResultItem] in
            guard let dbPtr = dbPtr else { return [] }
            var results: [SearchResultItem] = []

            let sql = """
            SELECT entity_type, entity_id, title, subtitle, metadata_json
            FROM search_index
            WHERE keywords LIKE ? OR title LIKE ? OR keywords LIKE ? OR title LIKE ?
            ORDER BY
                CASE WHEN title LIKE ? THEN 1 WHEN title LIKE ? THEN 2 ELSE 3 END,
                title ASC
            LIMIT ?;
            """

            var stmt: OpaquePointer?
            if sqlite3_prepare_v2(dbPtr, sql, -1, &stmt, nil) == SQLITE_OK {
                let pattern1 = "%\(cleanQuery)%"
                let exactPrefix1 = "\(cleanQuery)%"
                let pattern2 = "%\(stemmed)%"
                let exactPrefix2 = "\(stemmed)%"

                sqlite3_bind_text(stmt, 1, (pattern1 as NSString).utf8String, -1, nil)
                sqlite3_bind_text(stmt, 2, (pattern1 as NSString).utf8String, -1, nil)
                sqlite3_bind_text(stmt, 3, (pattern2 as NSString).utf8String, -1, nil)
                sqlite3_bind_text(stmt, 4, (pattern2 as NSString).utf8String, -1, nil)
                sqlite3_bind_text(stmt, 5, (exactPrefix1 as NSString).utf8String, -1, nil)
                sqlite3_bind_text(stmt, 6, (exactPrefix2 as NSString).utf8String, -1, nil)
                sqlite3_bind_int(stmt, 7, Int32(limit))

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
                    case "EXERCISE": badge = "Kraft"
                    case "SUPPLEMENT": badge = "Supps"
                    case "TRANSACTION": badge = "Finanzen"
                    case "TASK": badge = "Aufgaben"
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

    // MARK: - Supabase Cloud Federated Search
    public func searchCloudExercises(query: String) async -> [SearchResultItem] {
        let clean = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard clean.count >= 2 else { return [] }

        var searchTerms = [clean]
        if clean.hasSuffix("s") && clean.count > 3 {
            searchTerms.append(String(clean.dropLast()))
        } else if clean.hasSuffix("es") && clean.count > 4 {
            searchTerms.append(String(clean.dropLast(2)))
        }

        let orFilter = searchTerms.map { term in
            guard let enc = term.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return "" }
            return "name.ilike.*\(enc)*,target.ilike.*\(enc)*,body_part.ilike.*\(enc)*,equipment.ilike.*\(enc)*"
        }.filter { !$0.isEmpty }.joined(separator: ",")

        guard !orFilter.isEmpty,
              let endpoint = URL(string: "https://oqhqpkayzkmnbcmbqkmm.supabase.co/rest/v1/exercises?or=(\(orFilter))&select=id,name,target,body_part,equipment&limit=25") else {
            return []
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "GET"
        let anonKey = "sb_publishable_Nd7hRD_Fp6no6X-NMnbuPQ_pLxJ-iNR"
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpRes = response as? HTTPURLResponse, httpRes.statusCode == 200 else {
                return []
            }
            guard let rows = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
                return []
            }

            return rows.compactMap { row -> SearchResultItem? in
                guard let name = row["name"] as? String, !name.isEmpty else { return nil }
                let id = row["id"] as? String ?? UUID().uuidString
                let bodyPart = row["body_part"] as? String ?? ""
                let target = row["target"] as? String ?? ""
                let equipment = row["equipment"] as? String ?? ""

                let formattedTitle = name.split(separator: " ").map { $0.capitalized }.joined(separator: " ")
                let subtitleParts = [bodyPart, target, equipment].filter { !$0.isEmpty }.map { $0.capitalized }
                let subtitle = subtitleParts.isEmpty ? "Supabase Cloud" : "\(subtitleParts.joined(separator: " • ")) [Cloud]"

                return SearchResultItem(
                    id: "CLOUD_\(id)",
                    entityType: "EXERCISE",
                    entityId: id,
                    title: formattedTitle,
                    subtitle: subtitle,
                    categoryBadge: "Kraft (Cloud)",
                    metadata: [
                        "source": "supabase",
                        "id": id,
                        "raw_name": name,
                        "equipment": equipment,
                        "target": target,
                        "body_part": bodyPart
                    ]
                )
            }
        } catch {
            return []
        }
    }

    // MARK: - Local Ecosystem Seed Population
    public func indexDefaultEcosystemEntities() {
        // 1. Core Kraftsport Exercises
        let coreExercises: [(id: String, title: String, sub: String, kw: [String])] = [
            ("ex_plank", "Unterarmstuetz / Plank", "Core • Bauch • Isometrisch", ["plank", "planks", "unterarmstuetz", "unterarmstütz", "core", "abs", "bauch"]),
            ("ex_bench", "Bankdruecken (Langhantel)", "Brust • Trizeps • Vordere Schulter", ["bench", "press", "brust", "chest", "bankdruecken", "bankdrücken"]),
            ("ex_squat", "Kniebeugen (Langhantel)", "Beine • Quads • Gluteus", ["squat", "squats", "beine", "quads", "kniebeugen"]),
            ("ex_deadlift", "Kreuzheben (Conventional)", "Ruecken • Posterior Chain • Beinbeuger", ["deadlift", "deadlifts", "kreuzheben", "ruecken", "rücken"]),
            ("ex_pullup", "Klimmzuege (BWK)", "Oberer Ruecken • Lats • Bizeps", ["pullup", "pullups", "chinup", "klimmzuege", "klimmzüge", "lats"]),
            ("ex_dip", "Dips (Barren)", "Trizeps • Untere Brust", ["dip", "dips", "barren", "trizeps"]),
            ("ex_row", "Rudern (Langhantel / Pendlay)", "Oberer Ruecken • Latissimus", ["row", "rows", "rudern", "latissimus"]),
            ("ex_ohp", "Schulterdruecken (Overhead Press)", "Schultern • Deltamuskel", ["ohp", "overhead", "press", "schulterdruecken", "schulterdrücken"]),
            ("ex_pushup", "Liegestuetze (BWK)", "Brust • Trizeps • Core", ["pushup", "pushups", "liegestuetze", "liegestütze"])
        ]
        for ex in coreExercises {
            indexEntity(type: "EXERCISE", entityId: ex.id, title: ex.title, subtitle: ex.sub, keywords: ex.kw, synchronous: true)
        }

        // 2. Circadian Supplements
        let supplements: [(id: String, title: String, sub: String, kw: [String])] = [
            ("sup_rhodiola", "Rhodiola Rosea (06:00 Uhr)", "500 mg (3 % Salidrosid) • ZNS-Fokus", ["rhodiola", "rosea", "salidrosid", "fokus", "morgen"]),
            ("sup_mag_malat", "Magnesium-Malat (06:30 Uhr)", "1.000 mg (150 mg elementar) • ATP-Synthese", ["magnesium", "malat", "energie", "atp"]),
            ("sup_vitd3k2", "Vitamin D3 (5.000 IE) + K2 MK-7", "200 mcg • Knochenstoffwechsel & Immunitaet", ["vitamin", "d3", "k2", "mk7", "sonne"]),
            ("sup_beetroot", "Rote Bete / Nitrat (16:00 Uhr)", "Pre-Workout • Vasodilatation & NO-Synthese", ["rote bete", "nitrat", "preworkout", "pump", "stickstoff"]),
            ("sup_omega3", "Omega-3 (16:45 Uhr)", "2.000 mg EPA/DHA • Anti-Inflammatorisch", ["omega", "omega3", "epa", "dha", "fischoel", "fischöl"]),
            ("sup_mag_glyc", "Magnesium-Bisglycinat (21:00 Uhr)", "1.500 mg (200 mg elementar) • ZNS-Downregulation", ["magnesium", "bisglycinat", "schlaf", "regeneration", "nacht"])
        ]
        for sup in supplements {
            indexEntity(type: "SUPPLEMENT", entityId: sup.id, title: sup.title, subtitle: sup.sub, keywords: sup.kw, synchronous: true)
        }

        // 3. Vorrat / Nutrition Staples
        let pantryItems: [(id: String, title: String, sub: String, kw: [String])] = [
            ("pan_hafer", "Haferflocken (Zartblatt)", "Kohlenhydrate • Beta-Glucan • 370 kcal", ["haferflocken", "oats", "hafer", "fruehstueck", "frühstück"]),
            ("pan_quark", "Magerquark (500g)", "Protein 60g • Casein • 340 kcal", ["magerquark", "quark", "protein", "casein"]),
            ("pan_eier", "Bio-Eier (Klasse A)", "Protein 36g • Cholin • Leucin", ["eier", "egg", "eggs", "protein"]),
            ("pan_reis", "Basmati-Reis", "Glykogen-Refill • Post-Workout", ["reis", "rice", "basmati", "carbs"])
        ]
        for pan in pantryItems {
            indexEntity(type: "PANTRY", entityId: pan.id, title: pan.title, subtitle: pan.sub, keywords: pan.kw, synchronous: true)
        }

        // 4. Finanzen & Pflichten
        let finances: [(id: String, title: String, sub: String, kw: [String])] = [
            ("fin_targo", "Targobank Entschuldung", "Monatliche Tilgung 574,70 EUR", ["targobank", "kredit", "schulden", "tilgung", "finanzen"]),
            ("fin_aok", "AOK Beitrags-Rueckstand", "Monatliche Tilgung 700,00 EUR", ["aok", "krankenkasse", "tilgung", "schulden"])
        ]
        for fin in finances {
            indexEntity(type: "TRANSACTION", entityId: fin.id, title: fin.title, subtitle: fin.sub, keywords: fin.kw, synchronous: true)
        }

        // 5. Aufgaben & Masterplan
        let tasks: [(id: String, title: String, sub: String, kw: [String])] = [
            ("tsk_fuehrerschein", "B-Fuehrerschein theorie24", "Strikte Pruefungsvorbereitung bis 23.10.", ["fuehrerschein", "führerschein", "theorie", "theorie24", "auto"]),
            ("tsk_hsh", "HsH Wirtschaftsinformatik B.Sc.", "Phase 0 Vorbereitung (Mathe, Python, SQL, Scrum)", ["wirtschaftsinformatik", "hsh", "studium", "phase 0", "mathe", "scrum"])
        ]
        for tsk in tasks {
            indexEntity(type: "TASK", entityId: tsk.id, title: tsk.title, subtitle: tsk.sub, keywords: tsk.kw, synchronous: true)
        }
    }
}
