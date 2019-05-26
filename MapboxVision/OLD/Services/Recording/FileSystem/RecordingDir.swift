import Foundation

typealias DirectoryPath = String

struct RecordingDir {

    // MARK: - Properties

    var videoPath: String {
        return fullPath.appendingPathComponent("video.\(fileExtension)")
    }

    func videoClipPath(start: Float, end: Float) -> String {
        return fullPath.appendingPathComponent("\(String(format: "%.2f", start))-\(String(format: "%.2f", end)).\(fileExtension)")
    }

    var videosLogPath: String {
        return fullPath.appendingPathComponent(FileManagerConstant.videoLogFile)
    }

    var imagesDirectoryPath: String {
        return fullPath.appendingPathComponent("images", isDirectory: true)
    }

    // MARK: - Private properties

    private(set) var basePath: LocationInDocumentDir?
    private(set) var fullPath: DirectoryPath
    private(set) var fileExtension: String
    private(set) var isInCustomDirectory: Bool

    // MARK: - Lifecycle

    /**
     // TODO: write doc
     */
    init(basePathInDocumentDir: LocationInDocumentDir = LocationInDocumentDir.recordingsDir,
         directoryPath: DirectoryPath?,
         shouldRecordIntoCustomDir: Bool,
         fileExtension: String) {
        let recordingDirectoryPath = directoryPath ?? RecordingDir.generateDirectoryName()
        self.fileExtension = fileExtension

        if shouldRecordIntoCustomDir {
            self.basePath = nil
            self.fullPath = recordingDirectoryPath
        } else {
            self.basePath = basePathInDocumentDir
            self.fullPath = basePathInDocumentDir.path.appendingPathComponent(recordingDirectoryPath, isDirectory: true)
        }

        createStructure()
    }

    init(directoryFullPath: DirectoryPath, fileExtension: String) {
        self.init(directoryPath: directoryFullPath, shouldRecordIntoCustomDir: true, fileExtension: fileExtension)
    }

    init(basePathInDocumentDir: LocationInDocumentDir = LocationInDocumentDir.recordingsDir,
         directoryPath: DirectoryPath,
         fileExtension: String) {
        self.init(basePathInDocumentDir: basePathInDocumentDir,
                  directoryPath: directoryPath,
                  shouldRecordIntoCustomDir: false,
                  fileExtension: fileExtension)
    }

    init(basePathInDocumentDir: LocationInDocumentDir = LocationInDocumentDir.recordingsDir, fileExtension: String) {
        self.init(basePathInDocumentDir: basePathInDocumentDir,
                  directoryPath: nil,
                  shouldRecordIntoCustomDir: false,
                  fileExtension: fileExtension)
    }

    init?(existing recordingPath: DirectoryPath, fileExtension: String) {
        self.init(directoryFullPath: recordingPath, fileExtension: fileExtension)

//        guard exists() else { return nil }
    }

    // MARK: - Internal functions

//    @discardableResult
//    func move(to newBasePath: LocationInDocumentDir) throws -> RecordingDir {
//        let newPath = fullPath.replacingOccurrences(of: self.basePath!.path, with: newBasePath.path)
//
//        try FileManager.default.moveItem(atPath: fullPath, toPath: newPath)
//
//        let directory = fullPath.lastPathComponent
//        return RecordingDir(basePath: newBasePath, directory: directory, settings: settings)
//    }

//    func delete() throws {
//        if exists() {
//            try FileManager.default.removeItem(atPath: fullPath)
//        }
//    }

    // MARK: - Private functions

//    private func createStructure() {
//        do {
//            try delete()
//            try FileManager.default.createDirectory(atPath: imagesDirectoryPath, withIntermediateDirectories: true, attributes: nil)
//        } catch {
//            print("ERROR: failure during creating structure. Error: \(error)")
//        }
//    }

//    private func exists() -> Bool {
//        var fileIsDirectory: ObjCBool = false
//        let fileExists =  FileManager.default.fileExists(atPath: fullPath, isDirectory: &fileIsDirectory)
//        return fileExists && fileIsDirectory.boolValue
//    }

    // MARK: - Static functions

    static func generateDirectoryName() -> String {
        return DateFormatter.createRecordingFormatter().string(from: Date())
    }
    
    static func clear(basePath: LocationInDocumentDir) {
        let directoryPath = basePath.path
        do {
            try FileManager.default.removeItem(atPath: directoryPath)
        } catch {
            print("Error: can't remove directory at \(directoryPath)")
        }
    }
}
