import CoreMedia
import Foundation

protocol VideoBufferDelegate: AnyObject {
    func chunkCut(number: Int, finished: Bool)
}

final class VideoBuffer {
    private(set) var isRecording: Bool = false
    weak var delegate: VideoBufferDelegate?

    // make it 0 to prevent cutting video in chunks
    var chunkLength: Float

    var chunkLimit: Int

    private let recorder = VideoRecorder()
    private var chunkCounter: Int = 0
    private var currentTimer: Timer?
    private var currentBasePath: String?

    private var settings: VideoSettings?

    init(chunkLength: Float, chunkLimit: Int) {
        self.chunkLength = chunkLength
        self.chunkLimit = chunkLimit
    }

    func startRecording(to path: String, settings: VideoSettings) {
        self.settings = settings
        isRecording = true
        chunkCounter = 0
        currentBasePath = path
        if chunkLength > 0 {
            currentTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(chunkLength), repeats: true) { [weak self] _ in
                self?.cutChunk(true)
            }
        }
        startChunk()
    }

    func stopRecording() {
        currentTimer?.invalidate()
        isRecording = false
        cutChunk(false)
        settings = nil
    }

    func handleFrame(_ sampleBuffer: CMSampleBuffer) {
        guard isRecording, recorder.isRecording else { return }

        recorder.handleFrame(sampleBuffer) { [weak self] result in
            guard let `self` = self, self.isRecording, self.recorder.isRecording else { return }

            switch result {
            case .value:
                break
            case .error(.notReadyForData):
                break
            case .error(.notRecording):
                assertionFailure("Video buffer is recording while video is not recording")
                fallthrough
            case .error(.recordingFailed):
                self.cutChunk(false)
            }
        }
    }

    private func startChunk() {
        if isRecording, let basePath = currentBasePath, let settings = settings {
            cleanupBuffer()
            recorder.startRecording(to: "\(basePath)/\(chunkCounter).\(settings.fileExtension)", settings: settings)
        }
    }

    private func cutChunk(_ shouldContinue: Bool) {
        let isCurrentlyRecording = isRecording

        recorder.stopRecording { [weak self] in
            guard let `self` = self else { return }
            DispatchQueue.main.async {
                self.delegate?.chunkCut(number: self.chunkCounter, finished: !isCurrentlyRecording)
                if shouldContinue {
                    self.chunkCounter += 1
                    self.startChunk()
                }
            }
        }
    }

    private func cleanupBuffer() {
        guard let basePath = currentBasePath else { return }

        let fileManager = FileManager.default
        if let contents = try? fileManager.contentsOfDirectory(atPath: basePath),
            contents.count >= chunkLimit {
            contents.sorted().prefix(contents.count - chunkLimit).forEach {
                try? fileManager.removeItem(atPath: "\(basePath)/\($0)")
            }
        }
    }
}
