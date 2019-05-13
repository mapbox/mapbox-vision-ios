//
//  SessionRecorder.swift
//  MapboxVision
//
//  Created by Alexander Pristavko on 5/13/19.
//  Copyright © 2019 Mapbox. All rights reserved.
//

import Foundation
import CoreMedia

final class SessionRecorder {
    struct Dependencies {
        let recorder: RecordCoordinator
        let sessionManager: SessionManager
        let videoSettings: VideoSettings
        let sessionInterval: TimeInterval
        let getSeconds: () -> Float
        let startSavingSession: (String) -> Void
        let stopSavingSession: () -> Void
    }
    
    weak var delegate: RecordCoordinatorDelegate?
    
    private let dependencies: Dependencies
    private var hasPendingRecordingRequest = false
    
    init(dependencies: Dependencies) {
        self.dependencies = dependencies
        
        dependencies.sessionManager.delegate = self
        dependencies.recorder.delegate = self
    }
    
    func start() {
        dependencies.sessionManager.startSession(interruptionInterval: dependencies.sessionInterval)
    }
    
    func stop(abort: Bool = false) {
        dependencies.sessionManager.stopSession(abort: abort)
    }
    
    func handleFrame(_ sampleBuffer: CMSampleBuffer) {
        dependencies.recorder.handleFrame(sampleBuffer)
    }
    
    private func record() {
        do {
            try dependencies.recorder.startRecording(referenceTime: dependencies.getSeconds(),
                                                     videoSettings: dependencies.videoSettings)
        } catch RecordCoordinatorError.cantStartNotReady {
            hasPendingRecordingRequest = true
        } catch {}
    }
}

extension SessionRecorder: SessionDelegate {
    func sessionStarted() {
        record()
    }
    
    func sessionStopped(abort: Bool) {
        dependencies.stopSavingSession()
        dependencies.recorder.stopRecording(abort: abort)
    }
}

extension SessionRecorder: RecordCoordinatorDelegate {
    func recordingStarted(path: String) {
        delegate?.recordingStarted(path: path)
        dependencies.startSavingSession(path)
    }
    
    func recordingStopped() {
        delegate?.recordingStopped()
        
        if hasPendingRecordingRequest {
            hasPendingRecordingRequest = false
            record()
        }
    }
}

