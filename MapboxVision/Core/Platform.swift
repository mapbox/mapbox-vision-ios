//
//  Platform.swift
//  cv-assist-ios
//
//  Created by Alexander Pristavko on 2/22/18.
//  Copyright © 2018 Mapbox. All rights reserved.
//

import Foundation
import MapboxVisionCore
import CoreMotion

final class Platform: PlatformInterface {
    
    struct Dependencies {
        let recordCoordinator: RecordCoordinator
        let eventsManager: EventsManager
    }
    
    private let dependencies: Dependencies
    
    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }
    
    func httpRequest(_ url: String, completion: @escaping HttpRequestCompletion) {
        guard let url = URL(string: url) else {
            assertionFailure("Can't create URL")
            return
        }
        
        let request = URLRequest(url: url)
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, let responseString = String(data: data, encoding: .utf8), error == nil else { return }
            completion(responseString)
        }
        task.resume()
    }
    
    func getMotionReferenceFrame() -> CMAttitudeReferenceFrame {
        return .xArbitraryZVertical
    }
    
    func makeVideoClip(_ startTime: Float, end endTime: Float) {
        dependencies.recordCoordinator.makeClip(from: startTime, to: endTime)
    }
    
    func getFilesDirectory() -> String {
        return NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
    }
    
    func sendTelemetry(_ name: String, entries: [TelemetryEntry]) {
        let entries = Dictionary(entries.map { ($0.key, $0.value) }) { first, _ in
            assertionFailure("Duplicated key in telemetry entries.")
            return first
        }
        
        dependencies.eventsManager.sendEvent(name: name, entries: entries)
    }
    
    func save(image: Image, path: String) {
        dependencies.recordCoordinator.saveImage(image: image, path: path)
    }
}
