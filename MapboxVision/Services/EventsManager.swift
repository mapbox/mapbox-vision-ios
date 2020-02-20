import Foundation
import MapboxMobileEvents
import MapboxVisionNative

final class EventsManager {
    private let manager = MMEEventsManager()
    private let recorder: FileRecorder

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

        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let formatter = DateFormatter()
        formatter.dateFormat = "y-MM-dd_HH-mm-ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let path = documentsPath.appending("/vision_log-\(formatter.string(from: Date())).json")

        recorder = FileRecorder(path: path)!

        recorder.record(Log("Initialize: name: \(name), version: \(version)"))
        manager.initialize(
            withAccessToken: accessToken,
            userAgentBase: name,
            hostSDKVersion: version
        )
        manager.isDebugLoggingEnabled = true

        recorder.record(Log("Send turnstile event"))
        manager.sendTurnstileEvent()
        manager.isMetricsEnabled = true
    }
}

extension EventsManager: NetworkClient {
    func set(baseURL: URL?) {
        recorder.record(Log("Set base url: \(baseURL.debugDescription)"))
        manager.baseURL = baseURL
        recorder.record(Log("Send turnstile event after set base url: \(baseURL.debugDescription)"))
        manager.sendTurnstileEvent()
    }

    func sendEvent(name: String, entries: [String: Any]) {
        recorder.record(Log("Send event: name: \(name), entries: \(entries)"))
        manager.enqueueEvent(withName: name, attributes: entries)
    }

    func upload(file: String, metadata: TelemetryFileMetadata, completion: @escaping (Error?) -> Void) {
        recorder.record(Log("Post metadata: file: \(file), metadata: \(metadata)"))
        manager.postMetadata([metadata], filePaths: [file], completionHandler: completion)
    }

    func cancel() {}
}

struct Log: Codable {
    let date: String
    let message: String

    init(_ message: String) {
        self.date = iso8601DateFormatter.string(from: Date())
        self.message = message
    }
}

final class FileRecorder {
    private let stream: OutputStream
    private var firstChunk = true

    init?(path: String) {
        guard let stream = OutputStream(toFileAtPath: path, append: true) else { return nil }
        self.stream = stream
        stream.open()
    }

    func record<T: Encodable>(_ info: T) {
        if firstChunk {
            firstChunk = false
        } else {
            stream.write(string: ",")
        }

        guard let encoded = try? JSONEncoder().encode(info)
        else { assertionFailure("Can't encode metainfo record to json data"); return }

        guard let jsonObject = try? JSONSerialization.jsonObject(with: encoded, options: [])
        else { assertionFailure("Can't convert encoded data to json object"); return }

        var error: NSError?
        JSONSerialization.writeJSONObject(jsonObject, to: self.stream, options: JSONSerialization.WritingOptions.prettyPrinted, error: &error)
        if let error = error { assertionFailure(error.localizedDescription); return }
    }

    deinit {
        stream.close()
    }
}

private extension OutputStream {
    func write(string: String) {
        _ = string.data(using: .utf8)?.withUnsafeBytes { ptr in
            self.write(ptr, maxLength: string.lengthOfBytes(using: .utf8))
        }
    }
}

let iso8601DateFormatter: DateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.locale = Locale(identifier: "en_US_POSIX")
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
    dateFormatter.timeZone = TimeZone(identifier: "UTC")
    return dateFormatter
}()
