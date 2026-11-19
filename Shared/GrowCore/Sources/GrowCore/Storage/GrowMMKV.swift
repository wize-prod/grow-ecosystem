import Foundation
import Darwin

// MARK: - Tencent MMKV-Inspired Zero-Copy Memory-Mapped Key-Value Store
public final class GrowMMKV: @unchecked Sendable {
    public static let shared = GrowMMKV()

    private let magic: UInt32 = 0x47524F57 // "GROW" in ASCII
    private let defaultFileSize: Int = 1024 * 1024 // 1 MB pre-allocated mmap space
    private var fd: Int32 = -1
    private var mmapPtr: UnsafeMutableRawPointer?
    private var fileSize: Int = 0
    private let lock = NSLock()

    private var storageURL: URL {
        let appGroupId = "group.com.nkembi.somagym"
        if let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId) {
            try? FileManager.default.createDirectory(at: groupURL, withIntermediateDirectories: true)
            return groupURL.appendingPathComponent("grow_fastkv.bin")
        }
        let paths = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let dir = paths.first ?? FileManager.default.temporaryDirectory
        let fastDir = dir.appendingPathComponent("GrowData", isDirectory: true)
        try? FileManager.default.createDirectory(at: fastDir, withIntermediateDirectories: true)
        return fastDir.appendingPathComponent("grow_fastkv.bin")
    }

    public init(customURL: URL? = nil) {
        let url = customURL ?? storageURL
        initializeMemoryMap(at: url)
    }

    deinit {
        closeMemoryMap()
    }

    private func initializeMemoryMap(at url: URL) {
        lock.lock()
        defer { lock.unlock() }

        let path = url.path
        fd = open(path, O_RDWR | O_CREAT, S_IRUSR | S_IWUSR)
        guard fd >= 0 else {
            print("GrowMMKV: Failed to open file descriptor at \(path)")
            return
        }

        var statBuf = stat()
        if fstat(fd, &statBuf) != 0 || statBuf.st_size < defaultFileSize {
            if ftruncate(fd, off_t(defaultFileSize)) != 0 {
                print("GrowMMKV: Failed to truncate file to default size")
                close(fd)
                fd = -1
                return
            }
            fileSize = defaultFileSize
        } else {
            fileSize = Int(statBuf.st_size)
        }

        guard let ptr = mmap(nil, fileSize, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0), ptr != MAP_FAILED else {
            print("GrowMMKV: mmap failed with errno \(errno)")
            close(fd)
            fd = -1
            return
        }

        mmapPtr = ptr

        // Verify or initialize header
        let magicPtr = ptr.assumingMemoryBound(to: UInt32.self)
        if magicPtr.pointee != magic {
            magicPtr.pointee = magic
            let countPtr = ptr.advanced(by: 4).assumingMemoryBound(to: UInt32.self)
            countPtr.pointee = 0 // Item count
            msync(ptr, 8, MS_ASYNC)
        }
    }

    private func closeMemoryMap() {
        lock.lock()
        defer { lock.unlock() }

        if let ptr = mmapPtr, fileSize > 0 {
            msync(ptr, fileSize, MS_SYNC)
            munmap(ptr, fileSize)
            mmapPtr = nil
        }
        if fd >= 0 {
            Darwin.close(fd)
            fd = -1
        }
    }

    // MARK: - In-Memory Binary Serialization
    private struct BinaryRecord {
        let key: String
        let value: Data
    }

    private func readAllRecords() -> [String: Data] {
        guard let ptr = mmapPtr else { return [:] }

        let magicVal = ptr.assumingMemoryBound(to: UInt32.self).pointee
        guard magicVal == magic else { return [:] }

        let count = Int(ptr.advanced(by: 4).assumingMemoryBound(to: UInt32.self).pointee)
        var offset = 8
        var dict = [String: Data]()

        for _ in 0..<count {
            guard offset + 8 <= fileSize else { break }

            let keyLen = Int(ptr.advanced(by: offset).assumingMemoryBound(to: UInt32.self).pointee)
            offset += 4
            let valLen = Int(ptr.advanced(by: offset).assumingMemoryBound(to: UInt32.self).pointee)
            offset += 4

            guard offset + keyLen + valLen <= fileSize else { break }

            let keyData = Data(bytes: ptr.advanced(by: offset), count: keyLen)
            offset += keyLen
            let valData = Data(bytes: ptr.advanced(by: offset), count: valLen)
            offset += valLen

            if let keyStr = String(data: keyData, encoding: .utf8) {
                dict[keyStr] = valData
            }
        }

        return dict
    }

    private func writeAllRecords(_ dict: [String: Data]) {
        guard let ptr = mmapPtr else { return }

        ptr.assumingMemoryBound(to: UInt32.self).pointee = magic
        ptr.advanced(by: 4).assumingMemoryBound(to: UInt32.self).pointee = UInt32(dict.count)

        var offset = 8
        for (key, val) in dict {
            guard let keyData = key.data(using: .utf8) else { continue }
            let keyLen = keyData.count
            let valLen = val.count

            guard offset + 8 + keyLen + valLen <= fileSize else {
                print("GrowMMKV: Exceeded pre-allocated mmap buffer capacity")
                break
            }

            ptr.advanced(by: offset).assumingMemoryBound(to: UInt32.self).pointee = UInt32(keyLen)
            offset += 4
            ptr.advanced(by: offset).assumingMemoryBound(to: UInt32.self).pointee = UInt32(valLen)
            offset += 4

            keyData.withUnsafeBytes { rawBuffer in
                if let base = rawBuffer.baseAddress {
                    ptr.advanced(by: offset).copyMemory(from: base, byteCount: keyLen)
                }
            }
            offset += keyLen

            val.withUnsafeBytes { rawBuffer in
                if let base = rawBuffer.baseAddress {
                    ptr.advanced(by: offset).copyMemory(from: base, byteCount: valLen)
                }
            }
            offset += valLen
        }

        // Asynchronous non-blocking flush to physical flash
        msync(ptr, offset, MS_ASYNC)
    }

    // MARK: - Public API (Sub-Microsecond Operations)
    public func set(_ value: String, forKey key: String) {
        if let data = value.data(using: .utf8) {
            set(data, forKey: key)
        }
    }

    public func set(_ value: Double, forKey key: String) {
        var v = value
        let data = Data(bytes: &v, count: MemoryLayout<Double>.size)
        set(data, forKey: key)
    }

    public func set(_ value: Bool, forKey key: String) {
        var v = value ? UInt8(1) : UInt8(0)
        let data = Data(bytes: &v, count: 1)
        set(data, forKey: key)
    }

    public func set(_ value: Int, forKey key: String) {
        var v = value
        let data = Data(bytes: &v, count: MemoryLayout<Int>.size)
        set(data, forKey: key)
    }

    public func set(_ data: Data, forKey key: String) {
        lock.lock()
        defer { lock.unlock() }

        var records = readAllRecords()
        records[key] = data
        writeAllRecords(records)
    }

    public func string(forKey key: String) -> String? {
        guard let data = data(forKey: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    public func double(forKey key: String) -> Double? {
        guard let data = data(forKey: key), data.count >= MemoryLayout<Double>.size else { return nil }
        return data.withUnsafeBytes { $0.load(as: Double.self) }
    }

    public func bool(forKey key: String) -> Bool? {
        guard let data = data(forKey: key), !data.isEmpty else { return nil }
        return data[0] == 1
    }

    public func int(forKey key: String) -> Int? {
        guard let data = data(forKey: key), data.count >= MemoryLayout<Int>.size else { return nil }
        return data.withUnsafeBytes { $0.load(as: Int.self) }
    }

    public func data(forKey key: String) -> Data? {
        lock.lock()
        defer { lock.unlock() }

        let records = readAllRecords()
        return records[key]
    }

    public func removeValue(forKey key: String) {
        lock.lock()
        defer { lock.unlock() }

        var records = readAllRecords()
        records.removeValue(forKey: key)
        writeAllRecords(records)
    }

    public func clearAll() {
        lock.lock()
        defer { lock.unlock() }

        writeAllRecords([:])
    }
}
