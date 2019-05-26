protocol FileManagerProtocol {
    func contentsOfDirectory(atPath path: String) throws -> [String]
    func contentsOfDirectory(at url: URL) throws -> [URL]
    func fileExists(atPath path: String) -> Bool
    func createFile(atPath path: String, contents: Data?) -> Bool
    func fileSize(at url: URL) -> Int64
}

extension FileManagerProtocol {
    func sizeOfDirectory(at url: URL) -> Int64 {
        guard let contents = try? self.contentsOfDirectory(at: url) else {
            return 0
        }

        return contents.map(fileSize).reduce(0, +)
    }
}
