import Foundation
import CoreBluetooth
import SQLite3

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

public final class GrowBLEPeripheralManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate, @unchecked Sendable {
    public static let shared = GrowBLEPeripheralManager()

    // Standard Bluetooth SIG GATT Services
    public static let weightScaleServiceUUID = CBUUID(string: "181D")
    public static let bodyCompositionServiceUUID = CBUUID(string: "181B")
    public static let heartRateServiceUUID = CBUUID(string: "180D")

    // Renpho ES-26M-W / Qingniu (QN-Scale) Custom BLE Service & Characteristics
    public static let renphoScaleServiceUUID = CBUUID(string: "FFE0")
    public static let renphoNotifyCharUUID = CBUUID(string: "FFE1")
    public static let renphoWriteCharUUID = CBUUID(string: "FFE3")

    // Characteristics
    public static let weightMeasurementCharUUID = CBUUID(string: "2A9D")
    public static let bodyCompositionCharUUID = CBUUID(string: "2A9C")
    public static let heartRateMeasurementCharUUID = CBUUID(string: "2A37")

    private var centralManager: CBCentralManager!
    private var connectedPeripheral: CBPeripheral?
    private let db = GrowDatabase.shared

    public var onMeasurementReceived: ((BLEBiometricMeasurement) -> Void)?

    override private init() {
        super.init()
        self.centralManager = CBCentralManager(
            delegate: self,
            queue: DispatchQueue(label: "com.grow.core.ble", qos: .background),
            options: [CBCentralManagerOptionShowPowerAlertKey: true]
        )
    }

    public func startBackgroundScan() {
        guard centralManager.state == .poweredOn else { return }
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
        centralManager.stopScan()
    }

    // MARK: - CBCentralManagerDelegate
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            startBackgroundScan()
        }
    }

    public func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        // Automatically connect to standard health peripherals in range
        self.connectedPeripheral = peripheral
        peripheral.delegate = self
        centralManager.stopScan()
        centralManager.connect(peripheral, options: nil)
    }

    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices([
            Self.weightScaleServiceUUID,
            Self.bodyCompositionServiceUUID,
            Self.heartRateServiceUUID,
            Self.renphoScaleServiceUUID
        ])
    }

    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        self.connectedPeripheral = nil
        // Resume background scanning
        startBackgroundScan()
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
            if char.properties.contains(.notify) || char.properties.contains(.indicate) {
                peripheral.setNotifyValue(true, for: char)
            }
            if char.properties.contains(.read) {
                peripheral.readValue(for: char)
            }
        }
    }

    public func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        guard let data = characteristic.value, !data.isEmpty else { return }

        if characteristic.uuid == Self.weightMeasurementCharUUID {
            parseWeightMeasurement(data)
        } else if characteristic.uuid == Self.bodyCompositionCharUUID {
            parseBodyComposition(data)
        } else if characteristic.uuid == Self.heartRateMeasurementCharUUID {
            parseHeartRate(data)
        } else if characteristic.uuid == Self.renphoNotifyCharUUID {
            parseRenphoQingniuPayload(data)
        }
    }

    // MARK: - Parsing Renpho QN-Scale (ES-26M-W) Custom BLE Encodings
    private func parseRenphoQingniuPayload(_ data: Data) {
        let bytes = [UInt8](data)
        guard bytes.count >= 8 else { return }

        // Byte 1 & 2: Weight in units of 10g (Big-Endian)
        let rawWeight = (UInt16(bytes[1]) << 8) | UInt16(bytes[2])
        let weightKg = Double(rawWeight) / 100.0

        var impedance: Double? = nil
        var bodyFatPct: Double? = nil
        var muscleMassKg: Double? = nil

        // Byte 3 & 4: Impedance in Ohms
        if bytes.count >= 6 {
            let rawImpedance = (UInt16(bytes[3]) << 8) | UInt16(bytes[4])
            if rawImpedance > 200 && rawImpedance < 1500 {
                impedance = Double(rawImpedance)
                // Lukaski-Deurenberg Bioelectrical Impedance Analysis (BIA)
                // Baseline: Male, 24y, 182cm (or pulled from UserProfileContract)
                let heightCm = 182.0
                let ffm = (0.396 * (heightCm * heightCm) / Double(rawImpedance)) + (0.49 * weightKg) + (0.158 * heightCm) - 10.5
                let fatMass = max(0.0, weightKg - ffm)
                let fatPct = (fatMass / weightKg) * 100.0
                bodyFatPct = (fatPct * 10.0).rounded() / 10.0
                muscleMassKg = (ffm * 10.0).rounded() / 10.0
            }
        }

        guard weightKg > 30.0 && weightKg < 250.0 else { return }

        let measurement = BLEBiometricMeasurement(
            weightKg: (weightKg * 100.0).rounded() / 100.0,
            bodyFatPct: bodyFatPct,
            muscleMassKg: muscleMassKg,
            impedanceOhms: impedance
        )
        persistMeasurement(measurement, source: "BLE_Renpho_ES26M_0xFFE0")
        onMeasurementReceived?(measurement)
    }

    // MARK: - Parsing Standard Bluetooth GATT Encodings
    private func parseWeightMeasurement(_ data: Data) {
        // Flags: byte 0 (Bit 0: 0 = SI [kg], 1 = Imperial [lbs])
        let bytes = [UInt8](data)
        guard bytes.count >= 3 else { return }

        let isImperial = (bytes[0] & 0x01) != 0
        let rawWeight = UInt16(bytes[1]) | (UInt16(bytes[2]) << 8)
        let factor = isImperial ? 0.01 * 0.45359237 : 0.005
        let weightKg = Double(rawWeight) * factor

        let measurement = BLEBiometricMeasurement(weightKg: (weightKg * 100).rounded() / 100)
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
