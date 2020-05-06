import Foundation

struct RecordingPath {
    enum Error: LocalizedError {
        case movedRecordingNotExist(String, String)

        var errorDescription: String? {
            switch self {
            case let .movedRecordingNotExist(oldPath, newPath):
                return "Recording moved from \(oldPath) doesn't exist at expected path \(newPath)"
            }
        }
    }

    static func generateDirectoryName() -> String {
        DateFormatter.createRecordingFormatter().string(from: Date())
    }

    static func clear(basePath: DocumentsLocation) {
        let directoryPath = basePath.path
        do {
            try FileManager.default.removeItem(atPath: directoryPath)
        } catch {
            print("Error: can't remove directory at \(directoryPath)")
        }
    }

    let recordingPath: String
    let settings: VideoSettings

    let basePath: DocumentsLocation

    init(basePath: DocumentsLocation, directory: String? = nil, settings: VideoSettings) {
        self.settings = settings
        self.basePath = basePath
        let dir = directory ?? RecordingPath.generateDirectoryName()
        if basePath == .custom {
            recordingPath = "\(dir)/"
        } else {
            recordingPath = basePath.path.appendingPathComponent(dir, isDirectory: true)
        }

        createStructure()
    }

    init?(existing path: String, settings: VideoSettings) {
        self.basePath = .custom

        self.settings = settings
        self.recordingPath = path

        guard exists else { return nil }
    }

    var videoPath: String {
        recordingPath.appendingPathComponent("video.\(settings.fileExtension)")
    }

    func videoClipPath(start: Float, end: Float) -> String {
        recordingPath.appendingPathComponent("\(String(format: "%.2f", start))-\(String(format: "%.2f", end)).\(settings.fileExtension)")
    }

    var videosLogPath: String {
        recordingPath.appendingPathComponent("videos.json")
    }

    var imagesDirectoryPath: String {
        recordingPath.appendingPathComponent("images", isDirectory: true)
    }

    @discardableResult
    func move(to newBasePath: DocumentsLocation) throws -> RecordingPath {
        let newPath = recordingPath.replacingOccurrences(of: self.basePath.path, with: newBasePath.path)
        let fileManager = FileManager.default

        if !fileManager.fileExists(atPath: newBasePath.path) {
            try fileManager.createDirectory(atPath: newBasePath.path, withIntermediateDirectories: true, attributes: nil)
        }

        try fileManager.moveItem(atPath: recordingPath, toPath: newPath)

        guard let path = RecordingPath(existing: newPath, settings: settings) else {
            throw Error.movedRecordingNotExist(recordingPath, newPath)
        }
        return path
    }

    func delete() throws {
        if exists {
            try FileManager.default.removeItem(atPath: recordingPath)
        }
    }

    private func createStructure() {
        do {
            try delete()
            try FileManager.default.createDirectory(atPath: imagesDirectoryPath, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("ERROR: failure during creating structure. Error: \(error)")
        }
    }

    private var exists: Bool {
        var isDirectory = ObjCBool(false)
        return FileManager.default.fileExists(atPath: recordingPath, isDirectory: &isDirectory) && isDirectory.boolValue
    }
}
