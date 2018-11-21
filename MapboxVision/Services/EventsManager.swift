//
//  EventsManager.swift
//  MapboxVision
//
//  Created by Maksim on 8/3/18.
//  Copyright © 2018 Mapbox. All rights reserved.
//

import Foundation
import MapboxMobileEvents
import MapboxVisionCore

final class EventsManager {
    
    private let manager = MMEEventsManager()
    
    private lazy var accessToken: String = {
        guard
            let dict = Bundle.main.infoDictionary,
            let token = dict["MGLMapboxAccessToken"] as? String
        else {
            assertionFailure("accessToken must be set in the Info.plist as MGLMapboxAccessToken.")
            return ""
        }
        return token
    }()
    
    private let formatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        let enUSPosixLocale = Locale(identifier: "en_US_POSIX")
        dateFormatter.locale = enUSPosixLocale
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        return dateFormatter
    }()
    
    init() {
        let bundle = Bundle(for: type(of: self))
        let name = bundle.infoDictionary!["CFBundleName"] as! String
        let version = bundle.infoDictionary!["CFBundleShortVersionString"] as! String
        
        manager.initialize(
            withAccessToken: accessToken,
            userAgentBase: name,
            hostSDKVersion: version
        )
        manager.sendTurnstileEvent()
        manager.isMetricsEnabled = true
        manager.isDebugLoggingEnabled = true
    }
    
    func sendEvent(name: String, entries: [String: Any]) {
        manager.enqueueEvent(withName: name, attributes: entries)
    }
}

extension EventsManager: NetworkClient {
    
    func upload(file: URL, toFolder folderName: String, completion: @escaping (Error?) -> Void) {
        
        let contentType: String
        switch file.pathExtension {
        case "zip": contentType = "zip"
        case "mp4": contentType = "video"
        case "jpg": contentType = "image"
        default:
            assertionFailure("EventsManager: post unsupported content type")
            contentType = ""
        }
        
        let name = file.lastPathComponent
        let folder = file.deletingLastPathComponent().lastPathComponent

        let created = file.creationDate.map(formatter.string) ?? ""

        var metadata = [
            "name": file.lastPathComponent,
            "fileId": folder + "/" + name,
            "sessionId": folderName,
            "format": file.pathExtension,
            "created": created,
            "type": contentType,
        ]
        
        if contentType == "video" {
            metadata["startTime"] = created
            metadata["endTime"] = created
        }
        
        manager.postMetadata([metadata], filePaths: [file.path], completionHandler: completion)
    }
    
    func cancel() {
        
    }
}
