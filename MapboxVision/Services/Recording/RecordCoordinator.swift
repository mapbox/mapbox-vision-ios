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

enum RecordCoordinatorError: LocalizedError {
    case cantStartAlreadyRecording
    case cantStartNotReady
}

private let defaultChunkLength: Float = 5 * 60
private let defaultChunkLimit = 3
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
    private var imageWriter: ImageRecorder = ImageRecorder()
    private let processingQueue = DispatchQueue(label: "com.mapbox.RecordCoordinator.Processing")
    
    private var currentReferenceTime: Float?
    private var currentRecordingPath: RecordingPath?
    private var currentStartTime: DispatchTime?
    private var currentEndTime: DispatchTime?
    
    private var stopRecordingInBackgroundTask = UIBackgroundTaskInvalid
    
    // determines if the source video is saved
    var savesSourceVideo: Bool = false
    
    init(settings: VideoSettings) {
        self.videoSettings = settings
        self.videoRecorder = VideoBuffer(chunkLength: defaultChunkLength, chunkLimit: defaultChunkLimit, settings: settings)
        self.videoTrimmer = VideoTrimmer(videoSettings: settings)
        videoRecorder.delegate = self
    }
    
    func startRecording(referenceTime: Float) throws {
        guard !isRecording else { throw RecordCoordinatorError.cantStartAlreadyRecording }
        guard isReady else { throw RecordCoordinatorError.cantStartNotReady }
        
        isRecording = true
        currentReferenceTime = referenceTime
        
        let cachePath = DocumentsLocation.cache.path
        recreateFolder(path: DocumentsLocation.currentRecording.path)
        recreateFolder(path: cachePath)
        
        let recordingPath = RecordingPath(basePath: .currentRecording, settings: videoSettings)
        currentRecordingPath = recordingPath
        
        jsonWriter = FileRecorder(path: recordingPath.videosLogPath)
        
        currentStartTime = DispatchTime.now()
        currentEndTime = nil
        
        videoRecorder.chunkLength = savesSourceVideo ? 0 : defaultChunkLength
        videoRecorder.chunkLimit = savesSourceVideo ? 1 : defaultChunkLimit
        videoRecorder.startRecording(to: cachePath)
        
        delegate?.recordingStarted(path: recordingPath.recordingPath)
    }
    
    func stopRecording() {
        guard isRecording else { return }
        
        isRecording = false
        isReady = false
        currentEndTime = DispatchTime.now()
        
        stopRecordingInBackgroundTask = UIApplication.shared.beginBackgroundTask()
        videoRecorder.stopRecording()
    }
    
    func handleFrame(_ sampleBuffer: CMSampleBuffer) -> Void {
        guard isRecording else { return }
        videoRecorder.handleFrame(sampleBuffer)
    }
    
    func makeClip(from startTime: Float, to endTime: Float) {
        guard
            let referenceTime = currentReferenceTime,
            let recordingPath = currentRecordingPath?.recordingPath
        else { return }
        
        let relativeStart = startTime - referenceTime
        let relativeEnd = endTime - referenceTime
        let chunkLength = videoRecorder.chunkLength
    
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
                copyClip(chunk: chunk, clipStart: clipStart, clipEnd: clipEnd)
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
    
    func saveImage(image: Image, path: String) {
        guard let recordingPath = currentRecordingPath else { return }
        
        guard let uiimage = image.getUIImage() else {
            assertionFailure("ERROR: Unable to convert image to UIImage")
            return
        }
        let imagePath = recordingPath.imagesDirectoryPath
            .appendingPathComponent(path)
            .appending(".\(RecordFileType.image.fileExtension)")
        
        imageWriter.record(image: uiimage, to: imagePath)
    }
    
    func clearCache() {
        RecordingPath.clear(basePath: .recordings)
    }
    
    private func recordingStopped() {
        trimRequestCache.removeAll()
        jsonWriter = nil
        
        if let path = currentRecordingPath {
            do {
                try path.move(to: .recordings)
            } catch {
                print("RecordCoordinator: moving current recording to \(path) failed. Error: \(error)")
            }
        }
        
        currentRecordingPath = nil
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
    
    private func copyClip(chunk: Int, clipStart: Float, clipEnd: Float) {
        guard
            let referenceTime = currentReferenceTime,
            let recordingPath = currentRecordingPath
        else { return }
        
        let sourcePath = chunkPath(for: chunk)
        let destinationPath = self.destinationPath(basePath: recordingPath.recordingPath, clipStart, clipEnd)
        let log = VideoLog(name: (destinationPath as NSString).lastPathComponent,
                           start: referenceTime + clipStart,
                           end: referenceTime + clipEnd)
        
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
        if savesSourceVideo, let startTime = currentStartTime {
            let clipStart = Float(number) * videoRecorder.chunkLength
            let clipEnd: Float
            
            if finished, let endTime = currentEndTime {
                let sessionDuration = Float(endTime.uptimeNanoseconds - startTime.uptimeNanoseconds) / 1_000_000_000
                clipEnd = sessionDuration - clipStart
            } else {
                clipEnd = Float(number + 1) * videoRecorder.chunkLength
            }
            
            copyClip(chunk: number, clipStart: clipStart, clipEnd: clipEnd)
        }
        
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
            }
        }
    }
    
    private func endBackgroundTask() {
        UIApplication.shared.endBackgroundTask(stopRecordingInBackgroundTask)
        stopRecordingInBackgroundTask = UIBackgroundTaskInvalid
    }
}
