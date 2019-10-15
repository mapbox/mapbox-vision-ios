import AVFoundation
import Foundation
import MapboxVisionNative
import UIKit

protocol RecordCoordinatorDelegate: AnyObject {
    func recordingStarted(path: String)
    func recordingStopped(recordingPath: RecordingPath)
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

    private var trimRequestCache = [Int: [VideoTrimRequest]]()
    var isRecording: Bool {
        return processingQueue.sync {
            isRecordingInternal
        }
    }
    private var isRecordingInternal: Bool = false
    private var isReady: Bool = true
    weak var delegate: RecordCoordinatorDelegate?

    private let videoRecorder: VideoBuffer
    private let videoTrimmer = VideoTrimmer()

    private var jsonWriter: FileRecorder?
    private var imageWriter = ImageRecorder()
    private let processingQueue = DispatchQueue(label: "com.mapbox.RecordCoordinator.Processing")

    private var currentVideoSettings: VideoSettings?
    private var currentReferenceTime: Float?
    private var currentRecordingPath: RecordingPath?
    private var currentStartTime: DispatchTime?
    private var currentEndTime: DispatchTime?
    private var currentVideoIsFull = false

    private var stopRecordingInBackgroundTask = UIBackgroundTaskIdentifier.invalid

    // determines if the source video is saved
    var savesSourceVideo: Bool = false

    init() {
        self.videoRecorder = VideoBuffer(chunkLength: defaultChunkLength, chunkLimit: defaultChunkLimit)
        videoRecorder.delegate = self
    }

    func startRecording(referenceTime: Float, directory: String? = nil, videoSettings: VideoSettings, onFail: @escaping () -> Void) {
        processingQueue.async { [weak self] in
            guard let self = self, !self.isRecordingInternal, self.isReady else {
                onFail()
                return
            }

            self.currentVideoSettings = videoSettings

            self.isRecordingInternal = true
            self.currentReferenceTime = referenceTime
            self.currentVideoIsFull = self.savesSourceVideo

            let cachePath = DocumentsLocation.cache.path
            self.recreateFolder(path: DocumentsLocation.currentRecording.path)
            self.recreateFolder(path: cachePath)

            let basePath: DocumentsLocation = directory != nil ? .custom : .currentRecording
            let recordingPath = RecordingPath(basePath: basePath, directory: directory, settings: videoSettings)
            self.currentRecordingPath = recordingPath

            self.jsonWriter = FileRecorder(path: recordingPath.videosLogPath)

            self.currentStartTime = DispatchTime.now()
            self.currentEndTime = nil

            self.videoRecorder.chunkLength = self.savesSourceVideo ? 0 : defaultChunkLength
            self.videoRecorder.chunkLimit = self.savesSourceVideo ? 1 : defaultChunkLimit
            self.videoRecorder.startRecording(to: cachePath, settings: videoSettings)

            self.delegate?.recordingStarted(path: recordingPath.recordingPath)
        }
    }

    func stopRecording() {
        processingQueue.async { [weak self] in
            guard let self = self, self.isRecordingInternal, self.isReady else { return }

            self.stopRecordingInBackgroundTask = UIApplication.shared.beginBackgroundTask()

            self.isRecordingInternal = false
            self.isReady = false
            self.currentEndTime = DispatchTime.now()
            self.videoRecorder.stopRecording()
        }
    }

    func handleFrame(_ sampleBuffer: CMSampleBuffer) {
        processingQueue.async { [weak self] in
            guard let self = self, self.isRecordingInternal else { return }
            self.videoRecorder.handleFrame(sampleBuffer)
        }
    }

    func makeClip(from startTime: Float, to endTime: Float) {
        processingQueue.async { [weak self] in
            guard
                let self = self,
                let referenceTime = self.currentReferenceTime
            else { return }

            let relativeStart = startTime - referenceTime
            let relativeEnd = endTime - referenceTime
            let chunkLength = self.videoRecorder.chunkLength

            let startChunk = chunkLength == 0 ? 0 : Int(floor(relativeStart / chunkLength))
            let endChunk = chunkLength == 0 ? 0 : Int(floor(relativeEnd / chunkLength))

            if startChunk != endChunk {
                self.clipFrom(startChunk: startChunk, endChunk: endChunk, from: startTime, to: endTime, relativeStart: relativeStart, relativeEnd: relativeEnd)
            } else {
                self.clipFrom(chunk: startChunk, from: startTime, to: endTime, relativeStart: relativeStart, relativeEnd: relativeEnd)
            }
        }
    }

    func saveImage(image: Image, path: String) {
        processingQueue.async { [weak self] in
            guard let self = self else { return }
            guard let recordingPath = self.currentRecordingPath else { return }

            guard let uiImage = image.getUIImage() else {
                assertionFailure("ERROR: Unable to convert image to UIImage")
                return
            }
            let imagePath = recordingPath.imagesDirectoryPath
                .appendingPathComponent(path)
                .appending(".\(RecordFileType.image.fileExtension)")

            self.imageWriter.record(image: uiImage, to: imagePath)
        }
    }

    private func clipFrom(startChunk: Int, endChunk: Int, from startTime: Float, to endTime: Float, relativeStart: Float, relativeEnd: Float) {
        guard
            let referenceTime = self.currentReferenceTime,
            let recordingPath = self.currentRecordingPath,
            let videoSettings = self.currentVideoSettings
        else { return }
        let chunkLength = self.videoRecorder.chunkLength
        let clipStartTime = relativeStart - Float(startChunk) * chunkLength
        let clipEndTime = relativeEnd - Float(endChunk) * chunkLength

        // trim start clip
        let startJointTime = Float(startChunk + 1) * chunkLength
        let startSourcePath = self.chunkPath(for: startChunk, fileExtension: videoSettings.fileExtension)
        let startName = recordingPath.videoClipPath(start: relativeStart, end: relativeEnd)
        let startLog = VideoLog(name: startName.lastPathComponent,
                                start: startTime,
                                end: referenceTime + startJointTime)
        let trimRequest = VideoTrimRequest(sourcePath: startSourcePath,
                                           destinationPath: startName,
                                           clipStart: clipStartTime,
                                           clipEnd: chunkLength,
                                           log: startLog)
        self.trimClip(chunk: startChunk, request: trimRequest)

        // copy all in-between clips
        for chunk in (startChunk + 1)..<endChunk {
            let clipStart = Float(chunk) * chunkLength
            let clipEnd = Float(chunk + 1) * chunkLength
            self.copyClip(chunk: chunk, clipStart: clipStart, clipEnd: clipEnd)
        }

        // trim end clip
        let endJointTime = Float(endChunk) * chunkLength
        let endSourcePath = self.chunkPath(for: endChunk, fileExtension: videoSettings.fileExtension)
        let endName = recordingPath.videoClipPath(start: endJointTime, end: relativeEnd)
        let endLog = VideoLog(name: endName.lastPathComponent,
                              start: referenceTime + endJointTime,
                              end: endTime)
        let endTrimRequest = VideoTrimRequest(sourcePath: endSourcePath,
                                              destinationPath: endName,
                                              clipStart: 0,
                                              clipEnd: clipEndTime,
                                              log: endLog)
        self.trimClip(chunk: endChunk, request: endTrimRequest)
    }

    private func clipFrom(chunk: Int, from startTime: Float, to endTime: Float, relativeStart: Float, relativeEnd: Float) {
        guard
            let recordingPath = self.currentRecordingPath,
            let videoSettings = self.currentVideoSettings
        else { return }
        let chunkLength = self.videoRecorder.chunkLength
        let clipStartTime = relativeStart - Float(chunk) * chunkLength
        let clipEndTime = relativeEnd - Float(chunk) * chunkLength

        let sourcePath = self.chunkPath(for: chunk, fileExtension: videoSettings.fileExtension)
        let path = recordingPath.videoClipPath(start: relativeStart, end: relativeEnd)
        let log = VideoLog(name: path.lastPathComponent,
                           start: startTime,
                           end: endTime)
        let trimRequest = VideoTrimRequest(sourcePath: sourcePath,
                                           destinationPath: path,
                                           clipStart: clipStartTime,
                                           clipEnd: clipEndTime,
                                           log: log)
        self.trimClip(chunk: chunk, request: trimRequest)
    }

    private func recordingStopped() {
        trimRequestCache.removeAll()
        jsonWriter = nil

        currentVideoSettings = nil
        currentVideoIsFull = false
        endBackgroundTask()
        isReady = true

        if let path = currentRecordingPath {
            delegate?.recordingStopped(recordingPath: path)
            currentRecordingPath = nil
        }
    }

    private func trimClip(chunk: Int, request: VideoTrimRequest, completion: (() -> Void)? = nil) {
        guard FileManager.default.fileExists(atPath: request.sourcePath) else { return }
        guard let settings = currentVideoSettings else { return }

        let sourceURL = URL(fileURLWithPath: request.sourcePath)
        let destinationURL = URL(fileURLWithPath: request.destinationPath)
        videoTrimmer.trimVideo(sourceURL: sourceURL,
                               destinationURL: destinationURL,
                               from: TimeInterval(request.clipStart),
                               to: TimeInterval(request.clipEnd),
                               settings: settings) { [jsonWriter, weak self] error in
            guard let self = self else { return }
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
            let recordingPath = currentRecordingPath,
            let videoSettings = currentVideoSettings
        else { return }

        let sourcePath = chunkPath(for: chunk, fileExtension: videoSettings.fileExtension)
        let destinationPath = currentVideoIsFull
            ? recordingPath.videoPath
            : recordingPath.videoClipPath(start: clipStart, end: clipEnd)

        let log = VideoLog(name: destinationPath.lastPathComponent,
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

    private func chunkPath(for number: Int, fileExtension: String) -> String {
        return "\(DocumentsLocation.cache.path)/\(number).\(fileExtension)"
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
        processingQueue.async { [weak self] in
            guard let self = self else { return }
            if self.currentVideoIsFull, let startTime = self.currentStartTime {
                let clipStart = Float(number) * self.videoRecorder.chunkLength
                let clipEnd: Float

                if finished, let endTime = self.currentEndTime {
                    let sessionDuration = Float(endTime.uptimeNanoseconds - startTime.uptimeNanoseconds) / 1_000_000_000
                    clipEnd = sessionDuration - clipStart
                } else {
                    clipEnd = Float(number + 1) * self.videoRecorder.chunkLength
                }

                self.copyClip(chunk: number, clipStart: clipStart, clipEnd: clipEnd)
            }

            let group = DispatchGroup()
            if let requests = self.trimRequestCache.removeValue(forKey: number) {
                for request in requests {
                    group.enter()
                    self.trimClip(chunk: number, request: request) {
                        group.leave()
                    }
                }
            }

            group.notify(queue: self.processingQueue) { [weak self] in
                guard let self = self else { return }
                if finished {
                    self.recordingStopped()
                }
            }
        }
    }

    private func endBackgroundTask() {
        UIApplication.shared.endBackgroundTask(stopRecordingInBackgroundTask)
        stopRecordingInBackgroundTask = UIBackgroundTaskIdentifier.invalid
    }
}
