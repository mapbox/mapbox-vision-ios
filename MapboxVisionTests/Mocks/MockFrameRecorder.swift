import Foundation
@testable import MapboxVision

class MockFrameRecorder: NSObject, FrameRecorder {
    func stopRecording() {
        actionLog.append(.stopRecording)
    }

    enum Action: Equatable {
        case startRecording
        case stopRecording
        case handleFrame
    }

    private(set) var actionLog: [Action] = []

    func startRecording(to path: String, settings: VideoSettings) {
        actionLog.append(.startRecording)
    }

    func handle(frame: CMSampleBuffer) {
        actionLog.append(.handleFrame)
    }
}
