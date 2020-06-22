import Foundation
import MapboxMobileEvents

final class Telemetry: NSObject, TelemetryInterface {
    private let manager = MMEEventsManager()

    func setSyncUrl(_: String, isChina: Bool) {
        UserDefaults.mme_configuration().mme_isCNRegion = isChina
        manager.sendTurnstileEvent()
    }

    func sendTelemetry(name: String, entries: [TelemetryEntry]) {
        let attributes = Dictionary(entries.map { ($0.key, $0.value) }) { first, _ in
            assertionFailure("Duplicated key in telemetry entries.")
            return first
        }

        manager.enqueueEvent(withName: name, attributes: attributes)
    }

    func sendTelemetryFile(path: String, metadata: [String: String], callback: @escaping SuccessCallback) {
        manager.postMetadata([metadata], filePaths: [path]) { error in callback(error == nil) }
    }
}
