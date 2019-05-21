import Foundation

extension URL {
    var isDirectory: Bool {
        return (try? resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
    }
    
    var subDirectories: [URL] {
        guard isDirectory else { return [] }
        return (try? FileManager.default.contentsOfDirectory(at: self, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]).filter{ $0.isDirectory }) ?? []
    }
    
    var creationDate: Date? {
        return (try? resourceValues(forKeys: [.creationDateKey])).flatMap { $0.creationDate }
    }
}

extension Array where Element == URL {
    
    var sortedByCreationDate: [URL] {
        return self.sorted { url1, url2 in
            switch (url1.creationDate, url2.creationDate) {
            case (_, .none): return true
            case (.none, _): return false
            case let (.some(date1), .some(date2)): return date1 < date2
            }
        }
    }
}
