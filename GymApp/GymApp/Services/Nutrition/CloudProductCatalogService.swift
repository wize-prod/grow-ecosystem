import Foundation
import Combine
import UIKit

// MARK: - Cloud Data Transfer Objects (DTOs)
public struct CloudProductRecord: Codable {
    public let barcode: String
    public let name: String
    public let brand: String?
    public let category: String?
    public let pack_qty: Double?
    public let unit: String?
    public let price_reference: Double?
    public let kcal_100g: Double?
    public let protein_100g: Double?
    public let carbs_100g: Double?
    public let fat_100g: Double?
    public let fiber_100g: Double?
    public let nutriscore: String?
    public let reha_score: Int?
    public let source: String?
    public let is_verified: Bool?
    public let store_prices: [CloudStorePriceRecord]?

    public func asPantryItem() -> PantryItem {
        var pricesMap: [String: Double] = [:]
        if let prices = store_prices {
            for p in prices {
                pricesMap[p.store_chain] = p.price_eur
            }
        }

        return PantryItem(
            name: name,
            brand: brand ?? "",
            barcode: barcode,
            defaultPackQty: pack_qty ?? 1.0,
            defaultPrice: price_reference ?? 0.0,
            currentStockQty: 0.0,
            unit: unit ?? "g",
            kcal100g: kcal_100g ?? 0.0,
            protein100g: protein_100g ?? 0.0,
            carbs100g: carbs_100g ?? 0.0,
            fat100g: fat_100g ?? 0.0,
            fiber100g: fiber_100g ?? 0.0,
            nutriscore: nutriscore ?? "c",
            store: store_prices?.first?.store_chain ?? "SUPERMARKT",
            storageLocation: StorageLocation.defaultLocation(forProductName: name),
            storePrices: pricesMap.isEmpty ? nil : pricesMap
        )
    }
}

public struct CloudStorePriceRecord: Codable, Identifiable {
    public var id: String?
    public let barcode: String
    public let store_chain: String
    public let branch_name: String?
    public let price_eur: Double
    public let recorded_at: String?
    public let recorded_by: String?
    public let receipt_line_raw: String?
}

// MARK: - CloudProductCatalogService
public final class CloudProductCatalogService: ObservableObject {
    public static let shared = CloudProductCatalogService()

    @Published public var supabaseURL: String = ""
    @Published public var supabaseAnonKey: String = ""
    @Published public var lastSyncMessage: String = ""

    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 4.0
        config.timeoutIntervalForResource = 6.0
        self.session = URLSession(configuration: config)

        // Load configuration from UserDefaults with project defaults
        let defaultURL = "https://oqhqpkayzkmnbcmbqkmm.supabase.co"
        let defaultKey = "sb_publishable_Nd7hRD_Fp6no6X-NMnbuPQ_pLxJ-iNR"

        self.supabaseURL = UserDefaults.standard.string(forKey: "grow_supabase_url") ?? defaultURL
        self.supabaseAnonKey = UserDefaults.standard.string(forKey: "grow_supabase_anon_key") ?? defaultKey
    }

    public var isCloudConfigured: Bool {
        !supabaseURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !supabaseAnonKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    public func configure(url: String, anonKey: String) {
        let cleanURL = url.trimmingCharacters(in: .whitespacesAndNewlines).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let cleanKey = anonKey.trimmingCharacters(in: .whitespacesAndNewlines)
        self.supabaseURL = cleanURL
        self.supabaseAnonKey = cleanKey
        UserDefaults.standard.set(cleanURL, forKey: "grow_supabase_url")
        UserDefaults.standard.set(cleanKey, forKey: "grow_supabase_anon_key")
    }

    // MARK: - 2-Stufen-Lookup (Cloud-DB -> Open Food Facts Fallback -> Auto-Persist)
    public func lookupProduct(barcode: String) async -> PantryItem? {
        let cleanCode = barcode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanCode.isEmpty else { return nil }

        // Stufe 1: Abfrage der Cloud-Datenbank (Supabase)
        if isCloudConfigured {
            if let cloudItem = await querySupabase(barcode: cleanCode) {
                await MainActor.run {
                    self.lastSyncMessage = "Aus Cloud-DB geladen (\(cloudItem.name))"
                }
                return cloudItem
            }
        }

        // Stufe 2: Fallback auf Open Food Facts & globale Aggregatoren
        if let offItem = await OpenFoodFactsService.shared.fetchProduct(barcode: cleanCode) {
            await MainActor.run {
                self.lastSyncMessage = "Aus Open Food Facts bezogen (\(offItem.name))"
            }

            // Asynchrone Auto-Persistierung in Cloud-DB (Write-Through Caching)
            if isCloudConfigured {
                Task {
                    _ = await upsertProductToCloud(item: offItem)
                }
            }

            return offItem
        }

        return nil
    }

    // MARK: - Volltext-/Fuzzy-Suche in der Cloud-Datenbank
    public func searchProducts(query: String) async -> [PantryItem] {
        let clean = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isCloudConfigured, clean.count >= 2 else { return [] }

        guard let encodedTerm = clean.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let endpoint = URL(string: "\(supabaseURL)/rest/v1/products?or=(name.ilike.*\(encodedTerm)*,brand.ilike.*\(encodedTerm)*,barcode.ilike.*\(encodedTerm)*)&select=*,store_prices(*)") else {
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
            let records = try JSONDecoder().decode([CloudProductRecord].self, from: data)
            return records.map { $0.asPantryItem() }
        } catch {
            return []
        }
    }

    // MARK: - Supabase Query Operation
    private func querySupabase(barcode: String) async -> PantryItem? {
        guard isCloudConfigured, let endpoint = URL(string: "\(supabaseURL)/rest/v1/products?barcode=eq.\(barcode)&select=*,store_prices(*)") else {
            return nil
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "GET"
        request.setValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await session.data(for: request)
            guard let httpRes = response as? HTTPURLResponse, httpRes.statusCode == 200 else {
                return nil
            }

            let records = try JSONDecoder().decode([CloudProductRecord].self, from: data)
            if let record = records.first {
                return record.asPantryItem()
            }
        } catch {
            // Offline oder Timeout: Stiller Fallback
        }

        return nil
    }

    // MARK: - Write-Through Caching: Produkt in Cloud-DB sichern
    public func upsertProductToCloud(item: PantryItem) async -> Bool {
        guard isCloudConfigured, let endpoint = URL(string: "\(supabaseURL)/rest/v1/products?on_conflict=barcode") else {
            return false
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("resolution=merge-duplicates", forHTTPHeaderField: "Prefer")

        let payload: [String: Any] = [
            "barcode": item.barcode,
            "name": item.name,
            "brand": item.brand,
            "pack_qty": item.defaultPackQty,
            "unit": item.unit,
            "price_reference": item.defaultPrice,
            "kcal_100g": item.kcal100g,
            "protein_100g": item.protein100g,
            "carbs_100g": item.carbs100g,
            "fat_100g": item.fat100g,
            "fiber_100g": item.fiber100g,
            "nutriscore": item.nutriscore,
            "source": "openfoodfacts_app"
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            let (_, response) = try await session.data(for: request)
            if let httpRes = response as? HTTPURLResponse, (200...299).contains(httpRes.statusCode) {
                return true
            }
        } catch {
            return false
        }

        return false
    }

    // MARK: - Filialpreis & Standort registrieren
    public func recordStorePrice(
        barcode: String,
        storeChain: String,
        branchName: String = "",
        priceEur: Double,
        receiptLineRaw: String = ""
    ) async -> Bool {
        guard isCloudConfigured, let endpoint = URL(string: "\(supabaseURL)/rest/v1/store_prices") else {
            return false
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let deviceID = UIDevice.current.identifierForVendor?.uuidString ?? "mac_client"
        let payload: [String: Any] = [
            "barcode": barcode,
            "store_chain": storeChain.uppercased(),
            "branch_name": branchName,
            "price_eur": priceEur,
            "recorded_by": deviceID,
            "receipt_line_raw": receiptLineRaw
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            let (_, response) = try await session.data(for: request)
            if let httpRes = response as? HTTPURLResponse, (200...299).contains(httpRes.statusCode) {
                await MainActor.run {
                    self.lastSyncMessage = "Preis \(priceEur) € fuer \(storeChain) gespeichert"
                }
                return true
            }
        } catch {
            return false
        }

        return false
    }

    // MARK: - Filialpreis-Historie abfragen
    public func fetchPriceComparison(barcode: String) async -> [CloudStorePriceRecord] {
        guard isCloudConfigured, let endpoint = URL(string: "\(supabaseURL)/rest/v1/store_prices?barcode=eq.\(barcode)&order=recorded_at.desc") else {
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
            return try JSONDecoder().decode([CloudStorePriceRecord].self, from: data)
        } catch {
            return []
        }
    }

    // MARK: - Beleg-Komprimierung (150-250 KB) & Supabase Storage Upload (receipt_images)
    #if canImport(UIKit)
    public func compressReceiptImage(_ image: UIImage, maxDimension: CGFloat = 1600, targetMaxBytes: Int = 250_000) -> Data? {
        let size = image.size
        let maxSide = max(size.width, size.height)
        let scale = maxSide > maxDimension ? (maxDimension / maxSide) : 1.0
        let targetSize = CGSize(width: floor(size.width * scale), height: floor(size.height * scale))

        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }

        var quality: CGFloat = 0.65
        var data = resized.jpegData(compressionQuality: quality)
        while let current = data, current.count > targetMaxBytes, quality > 0.35 {
            quality -= 0.08
            data = resized.jpegData(compressionQuality: quality)
        }
        return data
    }

    public func uploadCompressedReceiptImage(_ image: UIImage, receiptId: String, date: Date = Date()) async -> String? {
        guard isCloudConfigured, let jpegData = compressReceiptImage(image) else {
            return nil
        }

        let df = DateFormatter()
        df.dateFormat = "yyyy-MM"
        let monthFolder = df.string(from: date)
        let cleanId = receiptId.replacingOccurrences(of: " ", with: "_")
        let objectPath = "\(monthFolder)/bon_\(cleanId).jpg"

        guard let endpoint = URL(string: "\(supabaseURL)/storage/v1/object/receipt_images/\(objectPath)") else {
            return nil
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        request.setValue("true", forHTTPHeaderField: "x-upsert")
        request.httpBody = jpegData

        do {
            let (_, response) = try await session.data(for: request)
            if let httpRes = response as? HTTPURLResponse, (200...299).contains(httpRes.statusCode) {
                let kb = jpegData.count / 1024
                await MainActor.run {
                    self.lastSyncMessage = "Beleg komprimiert (\(kb) KB) in receipt_images/\(objectPath) archiviert"
                }
                return "receipt_images/\(objectPath)"
            }
        } catch {
            return nil
        }
        return nil
    }
    #endif
}
