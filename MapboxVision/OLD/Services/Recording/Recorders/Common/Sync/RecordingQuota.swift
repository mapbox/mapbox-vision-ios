import Foundation

typealias Byte = Int64

final class RecordingQuota {

    // MARK: Private properties

    private struct Keys {
        static let hasStoredRecordingQuotaKey = "hasStoredRecordingQuota"
        static let recordingMemoryQuotaKey = "recordingMemoryQuota"
        static let lastResetTimeKey = "lastResetTimeKey"
    }
    
    private let memoryQuota: Byte
    private let updatingInterval: TimeInterval

    private var lastResetTime: Date {
        get {
            if let time = UserDefaults.standard.object(forKey: Keys.lastResetTimeKey) as? Date {
                return time
            } else {
                let time = Date()
                UserDefaults.standard.set(time, forKey: Keys.lastResetTimeKey)
                return time
            }
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.lastResetTimeKey)
        }
    }

    private var currentMemoryQuota: Int64 {
        get {
            let defaults = UserDefaults.standard
            if defaults.bool(forKey: Keys.hasStoredRecordingQuotaKey) {
                return Byte(defaults.integer(forKey: Keys.recordingMemoryQuotaKey))
            } else {
                let quota = memoryQuota
                defaults.set(quota, forKey: Keys.recordingMemoryQuotaKey)
                defaults.set(true, forKey: Keys.hasStoredRecordingQuotaKey)
                return quota
            }
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.recordingMemoryQuotaKey)
        }
    }

    // MARK: Lifecycle

    init(memoryQuota: Byte, updatingInterval: TimeInterval) {
        self.memoryQuota = memoryQuota
        self.updatingInterval = updatingInterval
    }

    // MARK: Public functions
    
    func reserve(memoryToReserve: Byte) throws {
        var currentQuota = currentMemoryQuota // 30mb, 1day
        let now = Date()
        if now.timeIntervalSince(lastResetTime) >= updatingInterval {
            currentQuota = memoryQuota
            lastResetTime = now
        }
        
        let memoryAbleToReserve = currentQuota - memoryToReserve
        guard memoryAbleToReserve >= 0 else { throw RecordingQuotaError.memoryQuotaExceeded }
        currentMemoryQuota = memoryAbleToReserve
    }
}
