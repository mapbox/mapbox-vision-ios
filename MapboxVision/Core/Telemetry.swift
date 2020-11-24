import Foundation
import MapboxMobileEvents

final class Telemetry: NSObject, TelemetryInterface {
    private let manager = MMEEventsManager()

    private lazy var accessToken: String = {
        guard
            let dict = Bundle.main.infoDictionary,
            let token = dict["MGLMapboxAccessToken"] as? String
        else {
            assertionFailure("accessToken must be set in the Info.plist as MGLMapboxAccessToken.")
            return ""
        }
        return token
    }()

    override init() {
        super.init()

        let bundle = Bundle(for: type(of: self))
        let name = bundle.infoDictionary!["CFBundleName"] as! String
        let version = bundle.infoDictionary!["CFBundleShortVersionString"] as! String

        manager.initialize(
            withAccessToken: accessToken,
            userAgentBase: name,
            hostSDKVersion: version
        )
        manager.sendTurnstileEvent()
    }

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
