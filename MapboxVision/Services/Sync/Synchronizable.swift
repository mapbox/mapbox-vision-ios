//
//  Synchronizable.swift
//  MapboxVision
//
//  Created by Alexander Pristavko on 5/13/19.
//  Copyright © 2019 Mapbox. All rights reserved.
//

import Foundation

protocol SyncDelegate: AnyObject {
    func syncStarted()
    func syncStopped()
}

protocol Synchronizable: AnyObject {
    var delegate: SyncDelegate? { get set }
    
    func sync()
    func stopSync()
}
