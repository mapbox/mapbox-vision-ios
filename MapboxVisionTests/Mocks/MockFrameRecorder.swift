import Foundation
@testable import MapboxVision

class MockFrameRecorder: NSObject, FrameRecordable {
    enum Action: Equatable {
        case startRecording
        case stopRecording
        case handleFrame
    }

    private(set) var actionLog: [Action] = []

    func startRecording(to path: String, settings: VideoSettings) {
        actionLog.append(.startRecording)
    }

    func stopRecording(completion: (() -> Void)?) {
        actionLog.append(.stopRecording)
    }

    func handle(frame: CMSampleBuffer) {
        actionLog.append(.handleFrame)
    }
}
