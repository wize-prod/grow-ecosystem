import Foundation
import CoreBluetooth
import SQLite3
import Combine

public struct BLEBiometricMeasurement: Sendable {
    public let weightKg: Double
    public let bodyFatPct: Double?
    public let muscleMassKg: Double?
    public let impedanceOhms: Double?
    public let heartRateBpm: Int?
    public let timestamp: Date

    public init(
        weightKg: Double,
        bodyFatPct: Double? = nil,
        muscleMassKg: Double? = nil,
        impedanceOhms: Double? = nil,
        heartRateBpm: Int? = nil,
        timestamp: Date = Date()
    ) {
        self.weightKg = weightKg
        self.bodyFatPct = bodyFatPct
        self.muscleMassKg = muscleMassKg
        self.impedanceOhms = impedanceOhms
        self.heartRateBpm = heartRateBpm
        self.timestamp = timestamp
    }
}

public enum BLEScaleStatus: String, Sendable {
    case bluetoothOff = "Bluetooth Deaktiviert"
    case unauthorized = "Keine Bluetooth-Berechtigung"
    case scanning = "Suche Renpho-Waage..."
    case connecting = "Verbinde..."
    case connected = "Renpho-Waage Verbunden"
    case measuring = "Pendelt ein (Bitte stillstehen)..."
    case received = "Messung synchronisiert & fixiert"
}

public final class GrowBLEPeripheralManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate, @unchecked Sendable {
    public static let shared = GrowBLEPeripheralManager()

    // Standard Bluetooth SIG GATT Services
    public static let weightScaleServiceUUID = CBUUID(string: "181D")
    public static let bodyCompositionServiceUUID = CBUUID(string: "181B")
    public static let heartRateServiceUUID = CBUUID(string: "180D")

    // Renpho ES-26M-W / Qingniu (QN-Scale) Custom BLE Service & Characteristics
    public static let renphoScaleServiceUUID = CBUUID(string: "FFE0")
    public static let renphoNotifyCharUUID = CBUUID(string: "FFE1")
    public static let renphoWriteCharUUID = CBUUID(string: "FFE3")
    public static let renphoWriteChar2UUID = CBUUID(string: "FFE4")

    // Characteristics
    public static let weightMeasurementCharUUID = CBUUID(string: "2A9D")
    public static let bodyCompositionCharUUID = CBUUID(string: "2A9C")
    public static let heartRateMeasurementCharUUID = CBUUID(string: "2A37")

    // MARK: - Published Observables for Live UI Feedback
    @Published public var status: BLEScaleStatus = .scanning
    @Published public var connectedDeviceName: String = "Renpho ES-26M-W"
    @Published public var liveWeightKg: Double? = nil
    @Published public var lastMeasurementSummary: String? = nil
    @Published public var lastMeasurementTimestamp: Date? = nil

    private var centralManager: CBCentralManager!
    private var connectedPeripheral: CBPeripheral?
    private let db = GrowDatabase.shared

    // MARK: - Settling & Stabilization Engine State
    private var recentSamples: [Double] = []
    private var firstSampleTime: Date? = nil
    private var isMeasurementLocked: Bool = false

    public var onMeasurementReceived: ((BLEBiometricMeasurement) -> Void)?

    override private init() {
        super.init()
        self.centralManager = CBCentralManager(
            delegate: self,
            queue: DispatchQueue(label: "com.grow.core.ble", qos: .userInitiated),
            options: [
                CBCentralManagerOptionShowPowerAlertKey: true
            ]
        )
    }

    public func triggerManualScan() {
        stopScan()
        if let p = connectedPeripheral {
            centralManager.cancelPeripheralConnection(p)
            connectedPeripheral = nil
        }
        resetMeasurementState()
        startActiveScan()
    }

    private func resetMeasurementState() {
        recentSamples.removeAll()
        firstSampleTime = nil
        isMeasurementLocked = false
        liveWeightKg = nil
    }

    public func startActiveScan() {
        guard centralManager != nil else { return }
        guard centralManager.state == .poweredOn else {
            DispatchQueue.main.async {
                if self.centralManager.state == .unauthorized {
                    self.status = .unauthorized
                } else if self.centralManager.state == .poweredOff {
                    self.status = .bluetoothOff
                } else {
                    self.status = .scanning
                }
            }
            return
        }

        resetMeasurementState()

        DispatchQueue.main.async {
            self.status = .scanning
        }

        print("[BLE] Starte aktiven Foreground-Scan nach Renpho-Waagen...")
        centralManager.scanForPeripherals(
            withServices: nil,
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )
    }

    public func startBackgroundScan() {
        guard centralManager != nil, centralManager.state == .poweredOn else { return }
        centralManager.scanForPeripherals(
            withServices: [
                Self.weightScaleServiceUUID,
                Self.bodyCompositionServiceUUID,
                Self.heartRateServiceUUID,
                Self.renphoScaleServiceUUID
            ],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )
    }

    public func stopScan() {
        centralManager?.stopScan()
    }

    // MARK: - CBCentralManagerDelegate
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("[BLE] CBCentralManager State: \(central.state.rawValue)")
        switch central.state {
        case .poweredOn:
            startActiveScan()
        case .poweredOff:
            DispatchQueue.main.async { self.status = .bluetoothOff }
        case .unauthorized:
            DispatchQueue.main.async { self.status = .unauthorized }
        default:
            DispatchQueue.main.async { self.status = .scanning }
        }
    }

    public func centralManager(_ central: CBCentralManager, willRestoreState dict: [String: Any]) {
        if let peripherals = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral], let first = peripherals.first {
            self.connectedPeripheral = first
            first.delegate = self
            DispatchQueue.main.async {
                self.status = .connected
                self.connectedDeviceName = first.name ?? "Renpho ES-26M"
            }
        }
    }

    public func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        let rawName = peripheral.name ?? (advertisementData[CBAdvertisementDataLocalNameKey] as? String) ?? ""
        let name = rawName.lowercased()
        let serviceUUIDs = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] ?? []
        let mfgData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data

        let hasMatchingService = serviceUUIDs.contains(where: {
            $0 == Self.weightScaleServiceUUID ||
            $0 == Self.bodyCompositionServiceUUID ||
            $0 == Self.heartRateServiceUUID ||
            $0 == Self.renphoScaleServiceUUID ||
            $0.uuidString.contains("FFE0") ||
            $0.uuidString.contains("FEE7")
        })

        let hasScaleName = name.contains("scale") || name.contains("renpho") || name.contains("qn-") || name.contains("chipsea") || name.contains("es-26") || name.contains("yolanda")

        var hasMfgSignature = false
        if let data = mfgData, data.count >= 2 {
            let b0 = data[0]
            let b1 = data[1]
            // Yolanda / Qingniu Company ID 0x51 0x4E ('QN') or 0x02 0x1B
            if (b0 == 0x51 && b1 == 0x4E) || (b0 == 0x02 && b1 == 0x1B) {
                hasMfgSignature = true
            }
        }

        // Filter out unrelated Bluetooth devices strictly
        guard hasMatchingService || hasScaleName || hasMfgSignature else {
            return
        }

        print("[BLE] Waage verifiziert: '\(rawName)' (RSSI: \(RSSI)). Baue GATT-Verbindung auf...")
        DispatchQueue.main.async {
            self.status = .connecting
            self.connectedDeviceName = rawName.isEmpty ? "Renpho ES-26M" : rawName
        }

        self.connectedPeripheral = peripheral
        peripheral.delegate = self
        centralManager.stopScan()
        centralManager.connect(peripheral, options: [
            CBConnectPeripheralOptionNotifyOnDisconnectionKey: true
        ])
    }

    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        let name = peripheral.name ?? "Renpho ES-26M-W"
        print("[BLE] Erfolgreich verbunden mit: \(name)")
        resetMeasurementState()
        DispatchQueue.main.async {
            self.status = .connected
            self.connectedDeviceName = name
        }
        peripheral.discoverServices(nil)
    }

    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("[BLE] Verbindung zu Waage getrennt. Bereite naechste Session vor.")
        self.connectedPeripheral = nil
        DispatchQueue.main.async {
            self.status = .scanning
            self.liveWeightKg = nil
        }
        startActiveScan()
    }

    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("[BLE] Verbindung fehlgeschlagen: \(error?.localizedDescription ?? "Unbekannt")")
        self.connectedPeripheral = nil
        startActiveScan()
    }

    // MARK: - CBPeripheralDelegate
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    public func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: Error?
    ) {
        guard let characteristics = service.characteristics else { return }
        for char in characteristics {
            let uuid = char.uuid.uuidString.uppercased()

            // 1. Notify aktivieren fuer Messdaten
            if char.properties.contains(.notify) || char.properties.contains(.indicate) {
                peripheral.setNotifyValue(true, for: char)
                print("[BLE] Notify aktiviert auf: \(uuid)")
            }

            // 2. Renpho Handshake auf FFE3 / FFE4
            if uuid.contains("FFE3") || uuid.contains("FFE4") {
                let handshakeCmd: [UInt8] = [0x13, 0x09, 0x15, 0x01, 0x10, 0x00, 0x00, 0x00, 0x42]
                let writeType: CBCharacteristicWriteType = char.properties.contains(.writeWithoutResponse) ? .withoutResponse : .withResponse
                peripheral.writeValue(Data(handshakeCmd), for: char, type: writeType)
                print("[BLE] Renpho Handshake an \(uuid) gesendet.")
            }
        }
    }

    public func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        guard let data = characteristic.value, !data.isEmpty else { return }
        let uuid = characteristic.uuid.uuidString.uppercased()

        if uuid.contains("2A9D") {
            parseWeightMeasurement(data)
        } else if uuid.contains("2A9C") {
            parseBodyComposition(data)
        } else if uuid.contains("2A37") {
            parseHeartRate(data)
        } else {
            // Renpho FFE1 Custom BIA Stream
            parseRenphoQingniuPayload(data)
        }
    }

    // MARK: - Parsing Renpho QN-Scale with Settling & Hysteresis Filter
    private func parseRenphoQingniuPayload(_ data: Data) {
        let bytes = [UInt8](data)
        guard bytes.count >= 4 else { return }

        let hexDump = bytes.map { String(format: "%02X", $0) }.joined(separator: " ")
        print("[BLE RX FFE1] Laenge \(bytes.count): \(hexDump)")

        let opcode = bytes[0]
        let isOfficialStableFrame = (opcode == 0x11 || opcode == 0xB1 || (bytes.count >= 6 && (bytes[1] & 0x20 != 0)))

        var parsedKg: Double? = nil
        var detectedImpedance: Double? = nil

        // 1. Standard 20-Byte QN-Scale / Yolanda Protokoll (ES-26M, ES-30M, ES-CS20M)
        // Byte 0: 0x10 / 0x11 (Opcode)
        // Bytes 1..14: Status, MAC, User-Index
        // Bytes 15 & 16: Gewicht in Big-Endian (/ 100.0)
        // Bytes 17 & 18: Impedanz in Ohm (Big-Endian)
        if bytes.count >= 17 {
            let wStd = Double((UInt16(bytes[15]) << 8) | UInt16(bytes[16])) / 100.0
            if wStd >= 35.0 && wStd <= 220.0 {
                parsedKg = wStd
                if bytes.count >= 19 {
                    let imp = Double((UInt16(bytes[17]) << 8) | UInt16(bytes[18]))
                    if imp >= 250 && imp <= 1500 {
                        detectedImpedance = imp
                    }
                }
            }
        }

        // 2. 19-Byte Dialekt (ES-26M Extended Variant, Gewicht an Bytes 10 & 11)
        if parsedKg == nil && bytes.count >= 12 {
            let w10 = Double((UInt16(bytes[10]) << 8) | UInt16(bytes[11])) / 100.0
            if w10 >= 35.0 && w10 <= 220.0 {
                parsedKg = w10
                if bytes.count >= 14 {
                    let imp = Double((UInt16(bytes[12]) << 8) | UInt16(bytes[13]))
                    if imp >= 250 && imp <= 1500 {
                        detectedImpedance = imp
                    }
                }
            }
        }

        // 3. Fallback fuer kurze Broadcast-Frames (Bytes 2 & 3 nur bei Paketlaenge < 14)
        if parsedKg == nil && bytes.count < 14 && bytes.count >= 4 {
            let wShort = Double((UInt16(bytes[2]) << 8) | UInt16(bytes[3])) / 100.0
            if wShort >= 35.0 && wShort <= 220.0 {
                parsedKg = wShort
            }
        }

        guard let weightKg = parsedKg else {
            print("[BLE] FFE1 Frame ignoriert (kein valides Gewicht an QN-Offsets 15-16 / 10-11): \(hexDump)")
            return
        }

        // Live-Anzeige aktualisieren waehrend des Einpendelns
        DispatchQueue.main.async {
            self.liveWeightKg = (weightKg * 100.0).rounded() / 100.0
            if !self.isMeasurementLocked {
                self.status = .measuring
            }
        }

        if isMeasurementLocked {
            return
        }

        // Settling-Filter: Aufzeichnung der Proben ueber Zeit
        let now = Date()
        if firstSampleTime == nil {
            firstSampleTime = now
        }
        recentSamples.append(weightKg)
        if recentSamples.count > 10 {
            recentSamples.removeFirst()
        }

        let elapsedSeconds = now.timeIntervalSince(firstSampleTime ?? now)

        // Stabilitaets-Kriterium:
        // Entweder meldet die Waage explizit Frame 0x11/0xB1,
        // ODER mindestens 4 Messwerte liegen vor, die seit mindestens 1.5 Sekunden um weniger als 0.1 kg schwanken.
        var isPhysicallyStabilized = false
        if isOfficialStableFrame {
            isPhysicallyStabilized = true
        } else if recentSamples.count >= 4 && elapsedSeconds >= 1.5 {
            let minVal = recentSamples.suffix(4).min() ?? 0
            let maxVal = recentSamples.suffix(4).max() ?? 0
            if (maxVal - minVal) <= 0.15 {
                isPhysicallyStabilized = true
            }
        }

        guard isPhysicallyStabilized else {
            return
        }

        // Messung fixieren
        isMeasurementLocked = true
        let finalWeight = (weightKg * 100.0).rounded() / 100.0

        var bodyFatPct: Double? = nil
        var muscleMassKg: Double? = nil

        if let imp = detectedImpedance {
            let heightCm = 182.0
            let ffm = (0.396 * (heightCm * heightCm) / imp) + (0.49 * finalWeight) + (0.158 * heightCm) - 10.5
            let fatMass = max(0.0, finalWeight - ffm)
            bodyFatPct = ((fatMass / finalWeight) * 1000.0).rounded() / 10.0
            muscleMassKg = (ffm * 10.0).rounded() / 10.0
        }

        let measurement = BLEBiometricMeasurement(
            weightKg: finalWeight,
            bodyFatPct: bodyFatPct,
            muscleMassKg: muscleMassKg,
            impedanceOhms: detectedImpedance
        )

        DispatchQueue.main.async {
            self.status = .received
            let summary = String(format: "%.2f kg%@", measurement.weightKg, measurement.bodyFatPct.map { String(format: " • %.1f %% KFA", $0) } ?? "")
            self.lastMeasurementSummary = summary
            self.lastMeasurementTimestamp = Date()
            self.liveWeightKg = finalWeight
        }

        persistMeasurement(measurement, source: "BLE_Renpho_ES26M_0xFFE0")
        onMeasurementReceived?(measurement)
    }

    // MARK: - Parsing Standard Bluetooth GATT Encodings
    private func parseWeightMeasurement(_ data: Data) {
        let bytes = [UInt8](data)
        guard bytes.count >= 3 else { return }

        let isImperial = (bytes[0] & 0x01) != 0
        let rawWeight = UInt16(bytes[1]) | (UInt16(bytes[2]) << 8)
        let factor = isImperial ? 0.01 * 0.45359237 : 0.005
        let weightKg = Double(rawWeight) * factor

        let measurement = BLEBiometricMeasurement(weightKg: (weightKg * 100).rounded() / 100)
        DispatchQueue.main.async {
            self.status = .received
            self.lastMeasurementSummary = String(format: "%.2f kg", measurement.weightKg)
            self.lastMeasurementTimestamp = Date()
        }
        persistMeasurement(measurement, source: "BLE_Scale_0x181D")
        onMeasurementReceived?(measurement)
    }

    private func parseBodyComposition(_ data: Data) {
        let bytes = [UInt8](data)
        guard bytes.count >= 4 else { return }

        let rawFat = UInt16(bytes[2]) | (UInt16(bytes[3]) << 8)
        let bodyFatPct = Double(rawFat) * 0.1

        let measurement = BLEBiometricMeasurement(
            weightKg: 0.0,
            bodyFatPct: (bodyFatPct * 10).rounded() / 10
        )
        persistMeasurement(measurement, source: "BLE_BodyComp_0x181B")
        onMeasurementReceived?(measurement)
    }

    private func parseHeartRate(_ data: Data) {
        let bytes = [UInt8](data)
        guard bytes.count >= 2 else { return }

        let isUInt16 = (bytes[0] & 0x01) != 0
        let bpm = isUInt16 ? (Int(bytes[1]) | (Int(bytes[2]) << 8)) : Int(bytes[1])

        let measurement = BLEBiometricMeasurement(
            weightKg: 0.0,
            heartRateBpm: bpm
        )
        onMeasurementReceived?(measurement)
    }

    private func persistMeasurement(_ m: BLEBiometricMeasurement, source: String) {
        let id = UUID().uuidString
        let ts = m.timestamp.timeIntervalSince1970

        db.performAsync { dbPtr in
            guard let dbPtr = dbPtr else { return }
            let sql = """
            INSERT INTO health_measurements (id, timestamp, weight_kg, body_fat_pct, muscle_mass_kg, impedance_ohms, source)
            VALUES (?, ?, ?, ?, ?, ?, ?);
            """
            var stmt: OpaquePointer?
            if sqlite3_prepare_v2(dbPtr, sql, -1, &stmt, nil) == SQLITE_OK {
                sqlite3_bind_text(stmt, 1, (id as NSString).utf8String, -1, nil)
                sqlite3_bind_double(stmt, 2, ts)
                sqlite3_bind_double(stmt, 3, m.weightKg)
                if let fat = m.bodyFatPct { sqlite3_bind_double(stmt, 4, fat) } else { sqlite3_bind_null(stmt, 4) }
                if let muscle = m.muscleMassKg { sqlite3_bind_double(stmt, 5, muscle) } else { sqlite3_bind_null(stmt, 5) }
                if let imp = m.impedanceOhms { sqlite3_bind_double(stmt, 6, imp) } else { sqlite3_bind_null(stmt, 6) }
                sqlite3_bind_text(stmt, 7, (source as NSString).utf8String, -1, nil)
                sqlite3_step(stmt)
            }
            sqlite3_finalize(stmt)
        }
    }
}
