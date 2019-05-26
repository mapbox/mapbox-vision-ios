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
