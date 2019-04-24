import Foundation
@testable import MapboxVision

final class MockArchiver: Archiver {

    var archives: [URL: [URL]] = [:]

    func archive(_ files: [URL], destination: URL) throws {
        archives[destination] = files
    }
}
