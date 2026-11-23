import Foundation
import SwiftUI

// MARK: - Enterprise Multi-Token & Synonym-Aware Exercise Search Engine
@MainActor
public struct ExerciseSearchEngine {
    public static let shared = ExerciseSearchEngine()

    public struct SearchMatchResult {
        public let isMatch: Bool
        public let score: Int
        public let matchedRanges: [Range<String.Index>]
    }

    // Comprehensive synonym dictionary mapping common abbreviations, colloquial terms, English and German terminology
    private static let synonymMap: [String: [String]] = [
        "bench": ["bankdrücken", "bankdruecken", "brust", "chest", "flachbank", "schrägbank"],
        "bank": ["bankdrücken", "bankdruecken", "flachbank", "schrägbank"],
        "press": ["bankdrücken", "schulterdrücken", "military press", "overhead press", "push"],
        "squat": ["kniebeuge", "kniebeugen", "beine", "quads", "quadriceps", "frontkniebeuge"],
        "beuge": ["kniebeuge", "kniebeugen", "box squat"],
        "deadlift": ["kreuzheben", "rücken", "ruecken", "hamstrings", "hebe", "gluteus"],
        "heben": ["kreuzheben", "wadenheben", "seitheben", "frontheben"],
        "pushup": ["liegestütz", "liegestütze", "liegestuetze", "pushup", "push-up", "einarmige liegestütze"],
        "liegestütz": ["liegestütz", "liegestütze", "liegestuetze", "pushup", "push-up", "einarmige liegestütze"],
        "liegestuetze": ["liegestütz", "liegestütze", "pushup", "push-up", "einarmige liegestütze"],
        "pullup": ["klimmzug", "klimmzüge", "klimmzuege", "pullup", "pull-up", "chinup", "latissimus"],
        "klimmzug": ["klimmzug", "klimmzüge", "klimmzuege", "pullup", "pull-up", "chinup"],
        "chinup": ["klimmzug", "untergriff klimmzug"],
        "dip": ["dips", "barren", "trizeps", "brust"],
        "dips": ["dip", "barren", "trizeps"],
        "plank": ["unterarmstütz", "unterarmstuetz", "plank", "rumpf", "bauch", "core", "tiefenstabilität"],
        "stütz": ["unterarmstütz", "unterarmstuetz", "plank", "stange"],
        "abs": ["bauch", "core", "rumpf", "rectus abdominis", "plank", "tiefenmuskel", "crunches"],
        "bauch": ["abs", "core", "rumpf", "plank", "rectus abdominis", "tiefenstabilität"],
        "core": ["rumpf", "bauch", "unterarmstütz", "plank", "tiefenstabilität", "functional core"],
        "rumpf": ["core", "bauch", "plank", "unterarmstütz", "functional core"],
        "shoulder": ["schulter", "military press", "schulterdrücken", "overhead", "deltoid", "seitheben"],
        "schulter": ["shoulder", "deltoid", "schulterdrücken", "military press", "overhead press", "seitheben"],
        "ohp": ["schulterdrücken", "military press", "overhead press", "schulter"],
        "bicep": ["bizeps", "curl", "hammer", "armbeuger"],
        "bizeps": ["bicep", "curl", "hammer curl", "sz-curl", "kurzhantel curl"],
        "curl": ["bizeps", "hammer curl", "konzentrationscurl", "beinbeuger"],
        "tricep": ["trizeps", "pushdown", "extension", "french press", "kickback"],
        "trizeps": ["tricep", "pushdown", "barren", "dips", "french press", "trizepsdrücken"],
        "lat": ["latissimus", "latzug", "klimmzug", "rudern", "breiter rücken"],
        "lats": ["latissimus", "latzug", "klimmzug", "rudern"],
        "latissimus": ["lat", "latzug", "klimmzug", "breiter rücken"],
        "row": ["rudern", "latissimus", "kabelrudern", "langhantelrudern", "t-bar"],
        "rudern": ["row", "latissimus", "kabelrudern", "langhantelrudern", "t-bar"],
        "calf": ["wade", "waden", "wadenheben", "soleus", "gastrocnemius"],
        "wade": ["calf", "waden", "wadenheben"],
        "hamstring": ["beinbeuger", "hamstrings", "glute ham", "kreuzheben"],
        "glute": ["gluteus", "gesäss", "gesaess", "hip thrust", "glute bridge", "po"],
        "po": ["gluteus", "gesäss", "hip thrust", "glute bridge"],
        "chest": ["brust", "pectoralis", "bankdrücken", "dips", "fliegende"],
        "brust": ["chest", "pectoralis", "bankdrücken", "fliegende", "dips"],
        "back": ["rücken", "ruecken", "latissimus", "trapez", "rudern", "kreuzheben"],
        "rücken": ["back", "latissimus", "trapez", "rudern", "kreuzheben"],
        "leg": ["bein", "beine", "quads", "hamstrings", "waden", "kniebeuge"],
        "beine": ["leg", "legs", "quads", "kniebeuge", "beinpresse"]
    ]

    /// Normalize text by stripping diacritics and converting German umlauts to standard phonetic ASCII
    public static func normalize(_ text: String) -> String {
        var lower = text.lowercased()
        lower = lower.replacingOccurrences(of: "ä", with: "ae")
        lower = lower.replacingOccurrences(of: "ö", with: "oe")
        lower = lower.replacingOccurrences(of: "ü", with: "ue")
        lower = lower.replacingOccurrences(of: "ß", with: "ss")
        return lower.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Evaluates if an exercise matches the search query and returns a ranking score with matched ranges
    public func evaluate(query: String, exercise: Exercise, store: GymStore? = nil) -> SearchMatchResult {
        let cleanQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanQuery.isEmpty {
            let baseScore = (store?.isFavorite(exerciseName: exercise.name) == true ? 200 : 0) + (store?.exercisePopularityScore(exercise) ?? 0)
            return SearchMatchResult(isMatch: true, score: baseScore, matchedRanges: [])
        }

        let normQuery = Self.normalize(cleanQuery)
        let origName = exercise.name
        let lowerName = origName.lowercased()
        let normName = Self.normalize(origName)

        var totalScore = 0
        var matchedRanges: [Range<String.Index>] = []
        var hasMatch = false

        // 1. Direct exact or prefix match on exercise name
        if normName == normQuery {
            totalScore += 1200
            hasMatch = true
            matchedRanges.append(origName.startIndex..<origName.endIndex)
        } else if normName.hasPrefix(normQuery) {
            totalScore += 700
            hasMatch = true
            if let r = lowerName.range(of: cleanQuery.lowercased()) {
                matchedRanges.append(r)
            }
        } else if let r = lowerName.range(of: cleanQuery.lowercased()) {
            totalScore += 450
            hasMatch = true
            matchedRanges.append(r)
        } else if normName.contains(normQuery) {
            totalScore += 380
            hasMatch = true
        }

        // 2. Multi-token decomposition
        let queryTokens = normQuery.split(separator: " ").map(String.init).filter { !$0.isEmpty }
        if queryTokens.count > 1 {
            var allTokensHit = true
            var tokenScore = 0

            for token in queryTokens {
                var tokenMatched = false
                if let r = lowerName.range(of: token) {
                    tokenMatched = true
                    tokenScore += 120
                    matchedRanges.append(r)
                } else if normName.contains(token) {
                    tokenMatched = true
                    tokenScore += 100
                } else {
                    // Check synonyms for this token
                    if let syns = Self.synonymMap[token] {
                        for syn in syns {
                            let normSyn = Self.normalize(syn)
                            if normName.contains(normSyn) {
                                tokenMatched = true
                                tokenScore += 80
                                break
                            }
                        }
                    }
                }

                if !tokenMatched {
                    allTokensHit = false
                    break
                }
            }

            if allTokensHit {
                hasMatch = true
                totalScore += tokenScore + 300
            }
        }

        // 3. Synonym matching for single token query
        if !hasMatch {
            if let synonyms = Self.synonymMap[normQuery] {
                for syn in synonyms {
                    let normSyn = Self.normalize(syn)
                    if normName.contains(normSyn) {
                        hasMatch = true
                        totalScore += 260
                        if let r = lowerName.range(of: syn) {
                            matchedRanges.append(r)
                        }
                        break
                    }
                }
            }
        }

        // 4. Target Muscle, Secondary Muscles, and Anatomical Roles
        let targetMuscleNorm = Self.normalize(exercise.targetMuscle.rawValue)
        if targetMuscleNorm.contains(normQuery) {
            hasMatch = true
            totalScore += 160
        }
        for sec in exercise.secondaryMuscles {
            if Self.normalize(sec.rawValue).contains(normQuery) {
                hasMatch = true
                totalScore += 90
            }
        }

        // 5. Equipment matching
        let eqNorm = Self.normalize(exercise.equipment.rawValue)
        if eqNorm.contains(normQuery) {
            hasMatch = true
            totalScore += 70
        }

        // 6. Category matching
        let catNorm = Self.normalize(exercise.categoryTypeEnum.rawValue)
        if catNorm.contains(normQuery) {
            hasMatch = true
            totalScore += 60
        }

        // 7. Subsequence fuzzy match fallback on name
        if !hasMatch {
            var qIdx = normQuery.startIndex
            var tIdx = normName.startIndex
            while qIdx < normQuery.endIndex && tIdx < normName.endIndex {
                if normQuery[qIdx] == normName[tIdx] {
                    qIdx = normQuery.index(after: qIdx)
                }
                tIdx = normName.index(after: tIdx)
            }
            if qIdx == normQuery.endIndex {
                hasMatch = true
                totalScore += 110
            }
        }

        guard hasMatch else {
            return SearchMatchResult(isMatch: false, score: 0, matchedRanges: [])
        }

        // Apply personal popularity & favorite weighting
        if let store = store {
            if store.isFavorite(exerciseName: exercise.name) {
                totalScore += 250
            }
            let popularity = store.exercisePopularityScore(exercise)
            totalScore += min(150, popularity * 3)
        }

        return SearchMatchResult(isMatch: true, score: totalScore, matchedRanges: matchedRanges)
    }

    /// Searches and sorts an array of exercises based on relevance and user frequency
    public func search(query: String, in exercises: [Exercise], store: GymStore? = nil) -> [Exercise] {
        let cleanQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanQuery.isEmpty {
            return exercises
        }

        var scoredList: [(exercise: Exercise, score: Int)] = []
        for ex in exercises {
            let res = evaluate(query: cleanQuery, exercise: ex, store: store)
            if res.isMatch {
                scoredList.append((ex, res.score))
            }
        }

        return scoredList.sorted { a, b in
            if a.score != b.score {
                return a.score > b.score
            }
            return a.exercise.name.localizedStandardCompare(b.exercise.name) == .orderedAscending
        }.map { $0.exercise }
    }
}

// MARK: - Supabase Cloud Exercise Catalog Service
public final class CloudExerciseCatalogService: ObservableObject {
    public static let shared = CloudExerciseCatalogService()

    @Published public var supabaseURL: String = "https://oqhqpkayzkmnbcmbqkmm.supabase.co"
    @Published public var supabaseAnonKey: String = "sb_publishable_Nd7hRD_Fp6no6X-NMnbuPQ_pLxJ-iNR"

    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 4.0
        config.timeoutIntervalForResource = 6.0
        self.session = URLSession(configuration: config)

        if let savedURL = UserDefaults.standard.string(forKey: "grow_supabase_url"), !savedURL.isEmpty {
            self.supabaseURL = savedURL
        }
        if let savedKey = UserDefaults.standard.string(forKey: "grow_supabase_anon_key"), !savedKey.isEmpty {
            self.supabaseAnonKey = savedKey
        }
    }

    public func searchExercises(query: String) async -> [Exercise] {
        let clean = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard clean.count >= 2 else { return [] }

        guard let encodedTerm = clean.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let endpoint = URL(string: "\(supabaseURL)/rest/v1/exercises?or=(name.ilike.*\(encodedTerm)*,target.ilike.*\(encodedTerm)*,body_part.ilike.*\(encodedTerm)*,equipment.ilike.*\(encodedTerm)*)&select=*&limit=15") else {
            return []
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "GET"
        request.setValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await session.data(for: request)
            guard let httpRes = response as? HTTPURLResponse, httpRes.statusCode == 200 else {
                return []
            }
            guard let rows = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
                return []
            }
            return rows.compactMap { Self.mapRowToExercise($0) }
        } catch {
            return []
        }
    }

    public static func mapRowToExercise(_ dict: [String: Any]) -> Exercise? {
        guard let name = dict["name"] as? String, !name.isEmpty else { return nil }
        let rawId = dict["id"] as? String ?? ""
        let idUUID = UUID(uuidString: "00000000-0000-0000-0000-" + rawId.padding(toLength: 12, withPad: "0", startingAt: 0)) ?? UUID()

        let bodyPart = (dict["body_part"] as? String ?? "").lowercased()
        let target = (dict["target"] as? String ?? "").lowercased()
        let equipStr = (dict["equipment"] as? String ?? "").lowercased()

        let targetMuscle: MuscleGroup
        if target.contains("chest") || bodyPart.contains("chest") {
            targetMuscle = .chest
        } else if target.contains("back") || bodyPart.contains("back") || target.contains("lats") {
            targetMuscle = .back
        } else if target.contains("abs") || target.contains("waist") || bodyPart.contains("waist") {
            targetMuscle = .functionalCore
        } else if target.contains("spine") || target.contains("lower back") {
            targetMuscle = .lowerBack
        } else if target.contains("shoulder") || target.contains("delts") || bodyPart.contains("shoulder") {
            targetMuscle = .shoulders
        } else if target.contains("glute") || target.contains("hamstring") {
            targetMuscle = .glutesPosterior
        } else if target.contains("quad") || target.contains("calf") || target.contains("calves") || bodyPart.contains("upper legs") || bodyPart.contains("lower legs") {
            targetMuscle = .legs
        } else if target.contains("bicep") || target.contains("tricep") || bodyPart.contains("upper arms") {
            targetMuscle = .arms
        } else if target.contains("cardio") || bodyPart.contains("cardio") {
            targetMuscle = .cardioConditioning
        } else {
            targetMuscle = .functionalCore
        }

        let equipment: EquipmentType
        if equipStr.contains("dumbbell") {
            equipment = .dumbBells
        } else if equipStr.contains("barbell") {
            equipment = .flatBenchBarbell
        } else if equipStr.contains("cable") {
            equipment = .cableCrossoverTower
        } else if equipStr.contains("kettlebell") {
            equipment = .kettlebells
        } else if equipStr.contains("leverage machine") || equipStr.contains("machine") {
            equipment = .nineStationTower
        } else if equipStr.contains("roller") || equipStr.contains("mat") {
            equipment = .matArea
        } else if equipStr.contains("band") {
            equipment = .mobilityStaff
        } else {
            equipment = .bodyweight
        }

        let notes = dict["general_execution_notes"] as? String ?? ""
        let setup = dict["setup_and_starting_position"] as? String ?? ""
        let mistakes = dict["common_mistakes"] as? [String] ?? []
        let cues = dict["mental_cues"] as? [String] ?? []
        let primary = dict["primary_muscles"] as? [String] ?? []
        let secondary = dict["secondary_muscles"] as? [String] ?? []
        let stabilizers = dict["stabilizers"] as? [String] ?? []

        return Exercise(
            id: idUUID,
            name: name.capitalized,
            targetMuscle: targetMuscle,
            secondaryMuscles: [],
            equipment: equipment,
            isBWKRehaSafe: true,
            executionNotes: notes,
            defaultSets: 3,
            defaultReps: 10,
            defaultRestSeconds: dict["default_rest_seconds"] as? Int ?? 90,
            difficulty: dict["difficulty_tier"] as? String ?? "Intermediate",
            categoryType: dict["force_type"] as? String ?? "Pull",
            mechanics: dict["mechanics_type"] as? String ?? "Compound",
            movementPattern: dict["movement_pattern"] as? String ?? "Vertical Pull",
            force: dict["force_type"] as? String ?? "Pull",
            primaryMusclesDetailed: primary,
            secondaryMusclesDetailed: secondary,
            stabilizersDetailed: stabilizers,
            setup: setup,
            execution: notes,
            commonMistakes: mistakes,
            cues: cues,
            isCustom: false
        )
    }
}
