import Foundation
import MapboxVisionNative

protocol NetworkClient {
    func set(baseURL: URL?)
    func upload(file: String, metadata: TelemetryFileMetadata, completion: @escaping (Error?) -> Void)
    func cancel()
}
