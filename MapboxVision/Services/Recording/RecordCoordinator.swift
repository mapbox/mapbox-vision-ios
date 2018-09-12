//
//  RecordCoordinator.swift
//  cv-assist-ios
//
//  Created by Alexander Pristavko on 1/9/18.
//  Copyright © 2018 Mapbox. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit
import MapboxVisionCore

protocol RecordCoordinatorDelegate: class {
    func recordingStarted(path: String)
    func recordingStopped()
}

private let chunkLength: Float = 5 * 60
private let chunkLimit = 3
private let videoLogFile = "videos.json"

final class RecordCoordinator {
    
    private struct VideoTrimRequest {
        let sourcePath: String
        let destinationPath: String
        let clipStart: Float
        let clipEnd: Float
        let log: VideoLog
    }
    
    private struct VideoLog: Codable {
        let name: String
        let start: Float
        let end: Float
    }
    
    private var trimRequestCache = [Int : [VideoTrimRequest]]()
    
    private(set) var isRecording: Bool = false
    private var isReady: Bool = true
    weak var delegate: RecordCoordinatorDelegate?
    
    private let videoRecorder: VideoBuffer
    private let videoTrimmer: VideoTrimmer
    private let videoSettings: VideoSettings

    private var jsonWriter: FileRecorder?
    private let processingQueue = DispatchQueue(label: "com.mapbox.RecordCoordinator.Processing")
    
    private var currentReferenceTime: Float?
    private var currentRecordingPath: RecordingPath?
    
    private var stopRecordingInBackgroundTask = UIBackgroundTaskInvalid
    
    init(settings: VideoSettings) {
        self.videoSettings = settings
        self.videoRecorder = VideoBuffer(chunkLength: chunkLength, chunkLimit: chunkLimit, settings: settings)
        self.videoTrimmer = VideoTrimmer(videoSettings: settings)
        videoRecorder.delegate = self
    }
    
    func startRecording(referenceTime: Float) {
        isRecording = true
        currentReferenceTime = referenceTime
        
        guard isReady else { return }
        
        do {
            try FileManager.default.createDirectory(atPath: DocumentsLocation.recordings.path, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print(error)
        }
        
        let recordingPath = DocumentsLocation.currentRecording.path
        let cachePath = DocumentsLocation.cache.path
        
        recreateFolder(path: recordingPath)
        
        guard let currentRecording = RecordingPath(settings: videoSettings) else { isRecording = false; return }
        currentRecordingPath = currentRecording
        
        jsonWriter = FileRecorder(path: recordingPath.appending(videoLogFile))
        
        recreateFolder(path: cachePath)
        videoRecorder.startRecording(to: cachePath)
        
        delegate?.recordingStarted(path: recordingPath)
    }
    
    func stopRecording() {
        isRecording = false
        isReady = false
        
        stopRecordingInBackgroundTask = UIApplication.shared.beginBackgroundTask()
        videoRecorder.stopRecording()
    }
    
    func handleFrame(_ sampleBuffer: CMSampleBuffer) -> Void {
        guard isRecording else { return }
        videoRecorder.handleFrame(sampleBuffer)
    }
    
    func makeClip(from startTime: Float, to endTime: Float) {
        guard
            let referenceTime = currentReferenceTime
        else { return }
        
        let recordingPath = DocumentsLocation.currentRecording.path
        
        let relativeStart = startTime - referenceTime
        let relativeEnd = endTime - referenceTime
    
        let startChunk = Int(floor(relativeStart / chunkLength))
        let endChunk = Int(floor(relativeEnd / chunkLength))
        
        let clipStartTime = relativeStart - Float(startChunk) * chunkLength
        let clipEndTime = relativeEnd - Float(endChunk) * chunkLength
        
        if startChunk != endChunk {
            // trim start clip
            let startJointTime = Float(startChunk + 1) * chunkLength
            let startName = destinationPath(basePath: recordingPath, relativeStart, startJointTime)
            let startLog = VideoLog(name: (startName as NSString).lastPathComponent,
                                    start: startTime,
                                    end: referenceTime + startJointTime)
            let trimRequest = VideoTrimRequest(sourcePath: chunkPath(for: startChunk),
                                               destinationPath: startName,
                                               clipStart: clipStartTime,
                                               clipEnd: chunkLength,
                                               log: startLog)
            trimClip(chunk: startChunk, request: trimRequest)
            
            // copy all in-between clips
            for chunk in (startChunk + 1) ..< endChunk {
                let clipStart = Float(chunk) * chunkLength
                let clipEnd = Float(chunk + 1) * chunkLength
                let clipName = destinationPath(basePath: recordingPath, clipStart, clipEnd)
                let clipLog = VideoLog(name: (clipName as NSString).lastPathComponent,
                                       start: referenceTime + clipStart,
                                       end: referenceTime + clipEnd)
                copyClip(sourcePath: chunkPath(for: chunk), destinationPath: clipName, log: clipLog)
            }
            
            // trim end clip
            let endJointTime = Float(endChunk) * chunkLength
            let endName = destinationPath(basePath: recordingPath, endJointTime, relativeEnd)
            let endLog = VideoLog(name: (endName as NSString).lastPathComponent,
                                  start: referenceTime + endJointTime,
                                  end: endTime)
            let endTrimRequest = VideoTrimRequest(sourcePath: chunkPath(for: endChunk),
                                                  destinationPath: endName,
                                                  clipStart: 0,
                                                  clipEnd: clipEndTime,
                                                  log: endLog)
            trimClip(chunk: endChunk, request: endTrimRequest)
        } else {
            let path = destinationPath(basePath: recordingPath, relativeStart, relativeEnd)
            let log = VideoLog(name: (path as NSString).lastPathComponent,
                               start: startTime,
                               end: endTime)
            let trimRequest = VideoTrimRequest(sourcePath: chunkPath(for: startChunk),
                                               destinationPath: path,
                                               clipStart: clipStartTime,
                                               clipEnd: clipEndTime,
                                               log: log)
            trimClip(chunk: startChunk, request: trimRequest)
        }
    }
    
    func clearCache() {
        RecordingPath.clearBasePath()
    }
    
    private func recordingStopped() {
        trimRequestCache.removeAll()
        jsonWriter = nil
        
        if let path = currentRecordingPath?.recordingPath {
            do {
                try FileManager.default.moveItem(atPath: DocumentsLocation.currentRecording.path, toPath: path)
            } catch {
                print("RecordCoordinator: moving current recording to \(path) failed. Error: \(error)")
            }
        }
        
        endBackgroundTask()
        isReady = true
        
        delegate?.recordingStopped()
    }
    
    private func trimClip(chunk: Int, request: VideoTrimRequest, completion: (() -> Void)? = nil) {
        guard FileManager.default.fileExists(atPath: request.sourcePath) else { return }
        
        let sourceURL = URL(fileURLWithPath: request.sourcePath)
        let destinationURL = URL(fileURLWithPath: request.destinationPath)
        videoTrimmer.trimVideo(sourceURL: sourceURL,
                               destinationURL: destinationURL,
                               from: TimeInterval(request.clipStart),
                               to: TimeInterval(request.clipEnd)) { [jsonWriter, weak self] error in
            
            guard let `self` = self else { return }
            if let trimError = (error as? VideoTrimmerError), case VideoTrimmerError.sourceIsNotExportable = trimError {
                if self.trimRequestCache[chunk] != nil {
                    self.trimRequestCache[chunk]?.append(request)
                } else {
                    self.trimRequestCache[chunk] = [request]
                }
            }
            if error == nil {
                self.processingQueue.async { [jsonWriter] in
                    jsonWriter?.record(request.log)
                    completion?()
                }
            } else {
                completion?()
            }
        }
    }
    
    private func copyClip(sourcePath: String, destinationPath: String, log: VideoLog) {
        processingQueue.async { [jsonWriter] in
            do {
                try FileManager.default.copyItem(atPath: sourcePath, toPath: destinationPath)
                jsonWriter?.record(log)
            } catch {
                assertionFailure("Copy failed. Error: \(error.localizedDescription)")
            }
        }
    }
    
    private func destinationPath(basePath: String, _ start: Float, _ end: Float) -> String {
        return "\(basePath)\(String(format: "%.2f", start))-\(String(format: "%.2f", end)).\(self.videoSettings.fileExtension)"
    }
    
    private func chunkPath(for number: Int) -> String {
        return "\(DocumentsLocation.cache.path)/\(number).\(videoSettings.fileExtension)"
    }
    
    private func recreateFolder(path: String) {
        let fileManager = FileManager.default
        do {
            if fileManager.fileExists(atPath: path) {
                try fileManager.removeItem(atPath: path)
            }
            try fileManager.createDirectory(atPath: path,
                                            withIntermediateDirectories: true,
                                            attributes: nil)
        } catch {
            assertionFailure("Folder recreation has failed. Error: \(error.localizedDescription)")
        }
    }
}

extension RecordCoordinator: VideoBufferDelegate {
    func chunkCut(number: Int, finished: Bool) {
        let group = DispatchGroup()
        if let requests = trimRequestCache.removeValue(forKey: number) {
            for request in requests {
                group.enter()
                trimClip(chunk: number, request: request) {
                    group.leave()
                }
            }
        }
        
        group.notify(queue: processingQueue) { [weak self] in
            guard let `self` = self else { return }
            if finished {
                self.recordingStopped()
                if self.isRecording, let referenceTime = self.currentReferenceTime {
                    self.startRecording(referenceTime: referenceTime)
                }
            }
        }
    }
    
    private func endBackgroundTask() {
        UIApplication.shared.endBackgroundTask(stopRecordingInBackgroundTask)
        stopRecordingInBackgroundTask = UIBackgroundTaskInvalid
    }
}
