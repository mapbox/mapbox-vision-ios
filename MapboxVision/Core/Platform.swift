import Foundation
import MapboxVisionNative
import CoreMotion

final class Platform: NSObject, PlatformInterface {

    struct Dependencies {
        let recordCoordinator: RecordCoordinator?
        let eventsManager: EventsManager
    }

    private let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    func getMotionReferenceFrame() -> CMAttitudeReferenceFrame {
        return .xArbitraryZVertical
    }

    func makeVideoClip(_ startTime: Float, end endTime: Float) {
        dependencies.recordCoordinator?.makeClip(from: startTime, to: endTime)
    }

    func sendTelemetry(_ name: String, entries: [TelemetryEntry]) {
        let entries = Dictionary(entries.map { ($0.key, $0.value) }) { first, _ in
            assertionFailure("Duplicated key in telemetry entries.")
            return first
        }

        dependencies.eventsManager.sendEvent(name: name, entries: entries)
    }

    func save(image: Image, path: String) {
        dependencies.recordCoordinator?.saveImage(image: image, path: path)
    }
}
