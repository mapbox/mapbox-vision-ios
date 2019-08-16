import Foundation
@testable import MapboxVision

final class MockNetworkClient: NetworkClient {
    var baseURL: URL?
    var error: Error?
    var uploaded: [URL: String] = [:]

    func set(baseURL: URL?) {
        self.baseURL = baseURL
    }

    func upload(file: URL, toFolder folderName: String, completion: @escaping (Error?) -> Void) {
        uploaded[file] = folderName
        completion(error)
    }

    func cancel() {}
}
