import Foundation

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

extension FileManager: FileManagerProtocol {
    
    func createFile(atPath path: String, contents: Data?) -> Bool {
        return createFile(atPath: path, contents: contents, attributes: nil)
    }
    
    func contentsOfDirectory(at url: URL) throws -> [URL] {
        return try contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: [])
    }
    
    func fileSize(at url: URL) -> Int64 {
        guard let attributes = try? attributesOfItem(atPath: url.path) else { return 0 }
        return attributes[FileAttributeKey.size] as? Int64 ?? 0
    }
}
