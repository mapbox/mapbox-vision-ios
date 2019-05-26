enum LocationInDocumentDir: String {
    case currentRecordingDir = "CurrentRecording"
    case recordingsDir = "Recordings"
    case showcaseDir = "Showcase"
    case cacheDir = "Cache"
}

extension LocationInDocumentDir {
    var path: String {
        return FileManager.default.documentDirectoryURL().path.appendingPathComponent(rawValue, isDirectory: true)
    }
}
