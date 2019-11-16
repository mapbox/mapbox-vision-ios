import Foundation
import MapboxVisionNative

private let visionVideoSettings: VideoSettings = .lowQuality

struct BaseDependencies {
    let native: VisionManagerBaseNativeProtocol
}

struct VisionDependencies {
    let native: VisionManagerNativeProtocol
    let recorder: FrameRecordable
    let dataProvider: DataProvider

    static func `default`() -> VisionDependencies {
        let recorder = VideoRecorder()

        let platform = Platform(dependencies: Platform.Dependencies(
            recorder: recorder,
            videoTrimmer: VideoTrimmer(),
            eventsManager: EventsManager(),
            archiver: RecordArchiver()
        ))

        let native = VisionManagerNative.create(withPlatform: platform)

        let dataProvider = RealtimeDataProvider(dependencies: RealtimeDataProvider.Dependencies(
            native: native,
            motionManager: MotionManager(),
            locationManager: LocationManager()
        ))

        return VisionDependencies(native: native,
                                  recorder: recorder,
                                  dataProvider: dataProvider)
    }
}

struct ReplayDependencies {
    let native: VisionReplayManagerNative
    let player: VideoPlayable

    static func `default`(recordPath: String) throws -> ReplayDependencies {
        guard let videoPath = RecordingPath(existing: recordPath, settings: .lowQuality)?.videoPath else {
            throw CocoaError(.fileNoSuchFile)
        }
        let player = try VideoPlayer(path: videoPath)

        let eventsManager = EventsManager()

        let platform = Platform(dependencies: Platform.Dependencies(
            recorder: nil,
            videoTrimmer: nil,
            eventsManager: eventsManager,
            archiver: RecordArchiver()
        ))

        let native = VisionReplayManagerNative.create(withPlatform: platform, recordPath: recordPath)

        return ReplayDependencies(native: native, player: player)
    }
}
