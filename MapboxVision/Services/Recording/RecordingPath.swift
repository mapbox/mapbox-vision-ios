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
        return (documentsPath as NSString).appendingPathComponent(rawValue).appending("/")
    }
}

struct RecordingPath {
    
    static var basePath: String {
        return DocumentsLocation.recordings.path
    }
    
    static func generatePath() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = NSLocale.current
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let currentDateString = dateFormatter.string(from: Date())
        
        return (basePath as NSString).appendingPathComponent(currentDateString).appending("/")
    }
    
    static func clearBasePath() {
        let directoryPath = basePath
        do {
            try FileManager.default.removeItem(atPath: directoryPath)
        } catch {
            print("Error: can't remove directory at \(directoryPath)")
        }
    }
    
    let recordingPath: String
    let settings: VideoSettings
    
    init(settings: VideoSettings) {
        self.settings = settings
        recordingPath = RecordingPath.generatePath()
    }
    
    init(path: String, settings: VideoSettings) {
        self.settings = settings
        recordingPath = path
    }
    
    init?(showPath: String, settings: VideoSettings) {
        self.settings = settings
        recordingPath = (DocumentsLocation.showcase.path as NSString).appendingPathComponent(showPath).appending("/")
        var isDirectory = ObjCBool(false)
        guard FileManager.default.fileExists(atPath: recordingPath, isDirectory: &isDirectory), isDirectory.boolValue else {
            return nil
        }
    }
    
    var videoPath: String {
        return (recordingPath as NSString).appendingPathComponent("video.\(settings.fileExtension)")
    }
    
    var videosLogPath: String {
        return (recordingPath as NSString).appendingPathComponent("videos.json")
    }
}
