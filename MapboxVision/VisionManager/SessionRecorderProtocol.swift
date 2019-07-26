import CoreMedia
import Foundation

protocol SessionRecorderProtocol: AnyObject {
    func stop()
    func start(mode: SessionRecordingMode)

    func handleFrame(_ sampleBuffer: CMSampleBuffer)

    var isInternal: Bool { get }
    var isExternal: Bool { get }

    var delegate: RecordCoordinatorDelegate? { get set }
}

enum SessionRecordingMode: Equatable {
    case `internal`
    case external(path: String)
}
