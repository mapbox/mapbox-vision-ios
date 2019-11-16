import Foundation
import MapboxVisionNative

protocol NetworkClient {
    func set(baseURL: URL?)
    func sendEvent(name: String, entries: [String: Any])
    func upload(file: String, metadata: TelemetryFileMetadata, completion: @escaping (Error?) -> Void)
    func cancel()
}
