import Foundation
import MapboxVisionNative

protocol DataProvider: AnyObject {
    func start()
    func update()
    func stop()
}

final class RecordedDataProvider {
    struct Dependencies {
        let recordingPath: RecordingDir
        let startTime: UInt
    }

    // MARK: - Properties

    let dependencies: Dependencies
    let telemetryPlayer: TelemetryPlayer

    // MARK: - Private properties

    private var startTime = DispatchTime.now().uptimeMilliseconds

    // MARK: - Lifecycle

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
        self.telemetryPlayer = TelemetryPlayer()
        telemetryPlayer.read(fromFolder: dependencies.recordingPath.fullPath)
    }
}

extension RecordedDataProvider: DataProvider {
    func start() {
        startTime = DispatchTime.now().uptimeMilliseconds
        telemetryPlayer.scrollData(dependencies.startTime)
    }

    func update() {
        let settings = dependencies.recordingPath.settings
        let frameSize = CGSize(width: settings.width, height: settings.height)
        let currentTimeMS = DispatchTime.now().uptimeMilliseconds - startTime + dependencies.startTime
        telemetryPlayer.setCurrentTime(currentTimeMS)
        telemetryPlayer.updateData(withFrameSize: frameSize, srcSize: frameSize)
    }

    func stop() {}
}

private extension DispatchTime {
    var uptimeMilliseconds: UInt {
        return UInt(DispatchTime.now().uptimeNanoseconds / 1_000_000)
    }
}
