import CoreMedia
import Foundation

private let internalSessionInterval: TimeInterval = 5 * 60
private let externalSessionInterval: TimeInterval = 0

final class SessionRecorder {
    struct Dependencies {
        let recorder: RecordCoordinator
        let sessionManager: SessionManager
        let videoSettings: VideoSettings
        let getSeconds: () -> Float
        let startSavingSession: (String) -> Void
        let stopSavingSession: () -> Void
    }

    weak var delegate: RecordCoordinatorDelegate?
    var currentMode: SessionRecordingMode = .internal

    private let dependencies: Dependencies
    private var hasPendingRecordingRequest = false

    init(dependencies: Dependencies) {
        self.dependencies = dependencies

        dependencies.sessionManager.delegate = self
        dependencies.recorder.delegate = self
    }

    func start(mode: SessionRecordingMode = .internal) {
        guard !dependencies.recorder.isRecording else { return }

        currentMode = mode
        dependencies.recorder.savesSourceVideo = mode.savesSourceVideo
        dependencies.sessionManager.startSession(interruptionInterval: mode.sessionInterval)
    }

    func stop(abort: Bool = false) {
        guard dependencies.recorder.isRecording else { return }

        dependencies.sessionManager.stopSession(abort: abort)
    }

    func handleFrame(_ sampleBuffer: CMSampleBuffer) {
        dependencies.recorder.handleFrame(sampleBuffer)
    }

    private func record() {
        do {
            try dependencies.recorder.startRecording(referenceTime: dependencies.getSeconds(),
                                                     directory: currentMode.path,
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

extension SessionRecorder: SessionRecorderProtocol {
    func stop() {
        stop(abort: false)
    }

    var isInternal: Bool {
        return currentMode.isInternal
    }

    var isExternal: Bool {
        return currentMode.isExternal
    }
}

private extension SessionRecordingMode {
    var sessionInterval: TimeInterval {
        switch self {
        case .internal:
            return internalSessionInterval
        case .external:
            return externalSessionInterval
        }
    }

    var isInternal: Bool {
        if case .internal = self { return true }
        return false
    }

    var isExternal: Bool {
        if case .external = self { return true }
        return false
    }

    var savesSourceVideo: Bool {
        switch self {
        case .internal:
            return false
        case .external:
            return true
        }
    }

    var path: String? {
        if case let .external(path) = self {
            return path
        }
        return nil
    }
}
