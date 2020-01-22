import Foundation
import MapboxMobileEvents
import MapboxVisionNative

final class EventsManager {
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

    init() {
        let bundle = Bundle(for: type(of: self))
        let name = bundle.infoDictionary!["CFBundleName"] as! String
        let version = bundle.infoDictionary!["CFBundleShortVersionString"] as! String

        manager.initialize(
            withAccessToken: accessToken,
            userAgentBase: name,
            hostSDKVersion: version
        )
        manager.sendTurnstileEvent()
        UserDefaults.mme_configuration().mme_isCollectionEnabled = true
    }
}

extension EventsManager: NetworkClient {
    func set(baseURL: URL?) {
        let isChina: Bool
        if let baseURLString = baseURL?.absoluteString, baseURLString == Constants.URL.chinaEventsEndpoint {
            isChina = true
        } else {
            isChina = false
        }

        UserDefaults.mme_configuration().mme_isCNRegion = isChina
        manager.sendTurnstileEvent()
    }

    func sendEvent(name: String, entries: [String: Any]) {
        manager.enqueueEvent(withName: name, attributes: entries)
    }

    func upload(file: String, metadata: TelemetryFileMetadata, completion: @escaping (Error?) -> Void) {
        manager.postMetadata([metadata], filePaths: [file], completionHandler: completion)
    }

    func cancel() {}
}
