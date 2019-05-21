import Foundation

final class RecordingQuota {
    private struct Keys {
        static let hasStoredRecordingQuotaKey = "hasStoredRecordingQuota"
        static let recordingMemoryQuotaKey = "recordingMemoryQuota"
        static let lastResetTimeKey = "lastResetTimeKey"
    }
    
    private enum RecordingQuotaError: LocalizedError {
        case memoryLimitOverflowed
    }
    
    private let memoryLimit: Int64
    private let updatingInterval: TimeInterval
    
    init(memoryLimit: Int64, updatingInterval: TimeInterval) {
        self.memoryLimit = memoryLimit
        self.updatingInterval = updatingInterval
    }
    
    func reserve(memory: Int64) throws {
        var quota = currentQuota
        let now = Date()
        if now.timeIntervalSince(lastResetTime) >= updatingInterval {
            quota = memoryLimit
            lastResetTime = now
        }
        
        let reminder = quota - memory
        guard reminder >= 0 else { throw RecordingQuotaError.memoryLimitOverflowed }
        currentQuota = reminder
    }
    
    private var lastResetTime: Date {
        get {
            let defaults = UserDefaults.standard
            if let time = defaults.object(forKey: Keys.lastResetTimeKey) as? Date {
                return time
            } else {
                let time = Date()
                defaults.set(time, forKey: Keys.lastResetTimeKey)
                return time
            }
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.lastResetTimeKey)
        }
    }
    
    private var currentQuota: Int64 {
        get {
            let defaults = UserDefaults.standard
            if defaults.bool(forKey: Keys.hasStoredRecordingQuotaKey) {
                return Int64(defaults.integer(forKey: Keys.recordingMemoryQuotaKey))
            } else {
                let quota = memoryLimit
                defaults.set(quota, forKey: Keys.recordingMemoryQuotaKey)
                defaults.set(true, forKey: Keys.hasStoredRecordingQuotaKey)
                return quota
            }
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.recordingMemoryQuotaKey)
        }
    }
}
