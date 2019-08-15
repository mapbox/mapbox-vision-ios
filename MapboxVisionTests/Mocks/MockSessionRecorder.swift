import CoreMedia
import Foundation
@testable import MapboxVision

class MockSessionRecorder: SessionRecorderProtocol {
    enum Action: Equatable {
        case stop
        case startInternal
        case startExternal(withPath: String)
        case handleFrame(frame: CMSampleBuffer)
    }

    private(set) var actionsLog: [Action] = []
    private var currentRecoring: RecordingPath?

    func stop() {
        isInternal = true
        actionsLog.append(.stop)

        if let recording = currentRecoring {
            delegate?.recordingStopped(recordingPath: recording)
        }
    }

    func start(mode: SessionRecordingMode) {
        isInternal = mode == .internal

        let recordingPath: RecordingPath
        if case let .external(path) = mode {
            actionsLog.append(.startExternal(withPath: path))
            recordingPath = RecordingPath(basePath: .custom, directory: path, settings: .highQuality)
        } else {
            actionsLog.append(.startInternal)
            recordingPath = RecordingPath(basePath: .currentRecording, settings: .highQuality)
        }

        currentRecoring = recordingPath
        delegate?.recordingStarted(path: recordingPath.recordingPath)
    }

    func handleFrame(_ frame: CMSampleBuffer) {
        actionsLog.append(.handleFrame(frame: frame))
    }

    private(set) var isInternal: Bool = true

    var isExternal: Bool {
        return !isInternal
    }

    weak var delegate: RecordCoordinatorDelegate?
}
