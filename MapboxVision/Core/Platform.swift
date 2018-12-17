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

protocol PlatformDelegate: class {
    func countryChanged(_ country: Country)
}

final class Platform: NSObject, PlatformInterface {

    struct Dependencies {
        let recordCoordinator: RecordCoordinator
        let eventsManager: EventsManager
    }
    
    weak var delegate: PlatformDelegate?
    
    private let dependencies: Dependencies
    
    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }
    
    func httpRequest(_ url: String, method: String, body: Data?, completion: @escaping HttpRequestCompletion) {
        guard let url = URL(string: url) else {
            assertionFailure("Can't create URL")
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
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
    
    func update(_ country: Country) {
        delegate?.countryChanged(country)
    }
}
