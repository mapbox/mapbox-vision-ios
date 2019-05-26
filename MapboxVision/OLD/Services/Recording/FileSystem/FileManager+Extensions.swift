enum FileManagerConstant {
    static let videoLogFile = "videos.json"
}

extension FileManager {
    func documentDirectoryURL() -> URL {
        return urls(for: .documentDirectory, in: .userDomainMask).first!
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


protocol FileManagerWithDirectoryPath {
    func createStructure(in recordingDir: RecordingDir)
    func dirExists(at: DirectoryPath) -> Bool
    func removeDir(at: DirectoryPath) throws
    func move(recordingDir: RecordingDir, to newBasePath: LocationInDocumentDir) throws -> RecordingDir
}

extension FileManager: FileManagerWithDirectoryPath {
    func createStructure(in recordingDir: RecordingDir) {

    }

    // TODO: implement
//    func createStructure(at dirPath: DirectoryPath) {
//        do {
//            try removeDir(at: dirPath)
//            try FileManager.default.createDirectory(atPath: imagesDirectoryPath, withIntermediateDirectories: true, attributes: nil)
//        } catch {
//            print("ERROR: failure during creating structure. Error: \(error)")
//        }
//    }

    func dirExists(at dirPath: DirectoryPath) -> Bool {
        var fileIsDirectory: ObjCBool = false
        let fileExists =  FileManager.default.fileExists(atPath: dirPath, isDirectory: &fileIsDirectory)
        return fileExists && fileIsDirectory.boolValue
    }

    func removeDir(at dirPath: DirectoryPath) throws {
        if dirExists(at: dirPath) {
            try FileManager.default.removeItem(atPath: dirPath)
        }
    }

    @discardableResult
    func move(recordingDir: RecordingDir, to newBasePath: LocationInDocumentDir) throws -> RecordingDir {
        if recordingDir.isInCustomDirectory {
            let newFullPath = newBasePath.path.appendingPathComponent(recordingDir.fullPath)
            try FileManager.default.moveItem(atPath: recordingDir.fullPath, toPath: newFullPath)
            let directory = recordingDir.fullPath.lastPathComponent
            return RecordingDir(basePathInDocumentDir: newBasePath,
                                directoryPath: directory,
                                fileExtension: recordingDir.fileExtension)
        } else {
            let newFullPath = recordingDir.fullPath.replacingOccurrences(of: recordingDir.basePath!.path,
                                                                         with: newBasePath.path)
            try FileManager.default.moveItem(atPath: recordingDir.fullPath, toPath: newFullPath)
            let directory = recordingDir.fullPath.lastPathComponent
            return RecordingDir(basePathInDocumentDir: newBasePath,
                                directoryPath: directory,
                                fileExtension: recordingDir.fileExtension)
        }
    }
}
