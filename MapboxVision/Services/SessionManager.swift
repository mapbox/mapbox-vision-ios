//
//  SessionManager.swift
//  MapboxVision
//
//  Created by Alexander Pristavko on 7/30/18.
//  Copyright © 2018 Mapbox. All rights reserved.
//

import Foundation

protocol SessionDelegate: class {
    func sessionStarted()
    func sessionStopped(abort: Bool)
}

final class SessionManager {
    weak var listener: SessionDelegate?
    
    private var notificationObservers = [Any]()
    private var interruptionInterval: TimeInterval = 0
    private var interruptionTimer: Timer?
    
    private var isStarted = false
    
    func startSession(interruptionInterval: TimeInterval) {
        guard !isStarted else { return }
        isStarted.toggle()
        
        notificationObservers.append(
            NotificationCenter.default.addObserver(forName: .UIApplicationWillTerminate, object: nil, queue: .main) { [weak self] _ in
            self?.stopSession()
        })
        
        if interruptionInterval > 0 {
            interruptionTimer = Timer.scheduledTimer(withTimeInterval: interruptionInterval, repeats: true) { [weak self] _ in
                self?.stopInterval()
                self?.startInterval()
            }
        }
        startInterval()
    }
    
    func stopSession(abort: Bool = false) {
        guard isStarted else { return }
        isStarted.toggle()
        
        notificationObservers.forEach(NotificationCenter.default.removeObserver)
        interruptionTimer?.invalidate()
        stopInterval(abort: abort)
    }
    
    private func startInterval() {
        listener?.sessionStarted()
    }
    
    private func stopInterval(abort: Bool = false) {
        listener?.sessionStopped(abort: abort)
    }
}
