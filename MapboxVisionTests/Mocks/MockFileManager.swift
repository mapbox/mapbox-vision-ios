import Foundation
@testable import MapboxVision

final class MockFileManager: FileManagerProtocol {
    struct File {
        let url: URL
        let size: Int64
    }

    var data: [File] = []

    func contentsOfDirectory(atPath path: String) throws -> [String] {
        return try contentsOfDirectory(at: URL(fileURLWithPath: path, isDirectory: true)).map { $0.lastPathComponent }
    }

    func contentsOfDirectory(at url: URL) throws -> [URL] {
        return data.filter { $0.url.deletingLastPathComponent() == url }.map { $0.url }
    }

    func fileExists(atPath path: String) -> Bool {
        let url = URL(fileURLWithPath: path)
        return data.contains { $0.url == url }
    }

    func createFile(atPath path: String, contents _: Data?) -> Bool {
        let fileUrl = URL(fileURLWithPath: path)
        let file = File(url: fileUrl, size: fileSize(at: fileUrl))
        data.append(file)
        return true
    }

    func fileSize(at url: URL) -> Int64 {
        return data.first { $0.url == url }?.size ?? 0
    }
}
