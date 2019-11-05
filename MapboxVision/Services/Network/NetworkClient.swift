import Foundation
import MapboxVisionNative

protocol NetworkClient {
    func set(baseURL: URL?)
    func upload(file: URL, toFolder folderName: String, completion: @escaping (Error?) -> Void)
    func upload(file: String, metadata: TelemetryFileMetadata, completion: @escaping (Error?) -> Void)
    func cancel()
}
