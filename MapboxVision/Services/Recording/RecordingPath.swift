//
//  RecordingPath.swift
//  cv-assist-ios
//
//  Created by Alexander Pristavko on 1/18/18.
//  Copyright © 2018 Mapbox. All rights reserved.
//

import Foundation

enum DocumentsLocation: String {
    case currentRecording = "Current"
    case recordings = "Recordings"
    case showcase = "Showcase"
    case cache = "Cache"
    
    var path: String {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        return documentsPath.appendingPathComponent(rawValue, isDirectory: true)
    }
}

struct RecordingPath {
    static func generateDirectoryName() -> String {
        return DateFormatter.createRecordingFormatter().string(from: Date())
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
    
    private let basePath: DocumentsLocation
    
    init(basePath: DocumentsLocation = DocumentsLocation.recordings, directory: String? = nil, settings: VideoSettings) {
        self.settings = settings
        self.basePath = basePath
        let dir = directory ?? RecordingPath.generateDirectoryName()
        recordingPath = basePath.path.appendingPathComponent(dir, isDirectory: true)
        
        createStructure()
    }
    
    init?(existing path: String, settings: VideoSettings) {
        guard let basePath = DocumentsLocation(rawValue: path.deletingLastPathComponent.lastPathComponent) else { return nil }
        self.basePath = basePath
        
        self.settings = settings
        self.recordingPath = path
        
        guard exists else { return nil }
    }
    
    var videoPath: String {
        return recordingPath.appendingPathComponent("video.\(settings.fileExtension)")
    }
    
    func videoClipPath(start: Float, end: Float) -> String {
        return recordingPath.appendingPathComponent("\(String(format: "%.2f", start))-\(String(format: "%.2f", end)).\(settings.fileExtension)")
    }
    
    var videosLogPath: String {
        return recordingPath.appendingPathComponent("videos.json")
    }
    
    var imagesDirectoryPath: String {
        return recordingPath.appendingPathComponent("images", isDirectory: true)
    }
    
    @discardableResult
    func move(to newBasePath: DocumentsLocation) throws -> RecordingPath {
        let newPath = recordingPath.replacingOccurrences(of: self.basePath.path, with: newBasePath.path)
        
        try FileManager.default.moveItem(atPath: recordingPath, toPath: newPath)
        
        let directory = recordingPath.lastPathComponent
        return RecordingPath(basePath: newBasePath, directory: directory, settings: settings)
    }
    
    func delete() throws {
        try FileManager.default.removeItem(atPath: self.basePath.path)
    }
    
    private func createStructure() {
        do {
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
