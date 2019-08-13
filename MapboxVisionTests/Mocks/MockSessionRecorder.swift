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

    func stop() {
        isInternal = true
        actionsLog.append(.stop)
        delegate?.recordingStopped(recordingPath: RecordingPath(basePath: .custom, settings: .highQuality))
    }

    func start(mode: SessionRecordingMode) {
        isInternal = mode == .internal

        if case let .external(path) = mode {
            actionsLog.append(.startExternal(withPath: path))
        } else {
            actionsLog.append(.startInternal)
        }
        delegate?.recordingStarted(path: "")
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
