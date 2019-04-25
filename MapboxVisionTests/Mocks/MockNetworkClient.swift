import Foundation
@testable import MapboxVision

final class MockNetworkClient: NetworkClient {
    var error: Error?
    var uploaded: [URL: String] = [:]

    func upload(file: URL, toFolder folderName: String, completion: @escaping (Error?) -> Void) {
        uploaded[file] = folderName
        completion(error)
    }

    func cancel() { }
}
