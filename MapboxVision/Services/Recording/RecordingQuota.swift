import Foundation

final class RecordingQuota {
    private enum Keys {
        static let recordingMemoryQuotaKey = "recordingMemoryQuota"
        static let lastResetTimeKey = "lastResetTimeKey"
    }

    private enum RecordingQuotaError: LocalizedError {
        case memoryQuotaExceeded
    }

    // MARK: - Properties

    private let memoryQuota: Byte
    private let refreshInterval: TimeInterval

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

    private var cachedCurrentQuota: Byte {
        get {
            if let quota = UserDefaults.standard.object(forKey: Keys.recordingMemoryQuotaKey) as? Byte {
                return quota
            } else {
                let quota = memoryQuota
                UserDefaults.standard.set(quota, forKey: Keys.recordingMemoryQuotaKey)
                return quota
            }
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.recordingMemoryQuotaKey)
        }
    }

    // MARK: - Lifecycle

    init(memoryQuota: Byte, refreshInterval: TimeInterval) {
        self.memoryQuota = memoryQuota
        self.refreshInterval = refreshInterval
    }

    // MARK: - Functions

    func reserve(memoryToReserve: Byte) throws {
        var quota = cachedCurrentQuota

        let now = Date()
        if now.timeIntervalSince(lastResetTime) >= refreshInterval {
            quota = memoryQuota
            lastResetTime = now
        }

        let quotaRemainder = quota - memoryToReserve
        guard quotaRemainder >= 0 else { throw RecordingQuotaError.memoryQuotaExceeded }
        cachedCurrentQuota = quotaRemainder
    }
}
