import Foundation
import MapboxVisionNative

private let visionVideoSettings: VideoSettings = .lowQuality

struct BaseDependencies {
    let native: VisionManagerBaseNativeProtocol
}

struct VisionDependencies {
    let native: VisionManagerNativeProtocol
    let recorder: FrameRecorder
    let dataProvider: DataProvider

    static func `default`() -> VisionDependencies {
        let recorder = VideoRecorder()

        let platform = Platform(
            telemetry: Telemetry(),
            fileSystem: FileSystem(archiver: RecordArchiver()),
            media: Media(recorder: recorder, videoTrimmer: VideoTrimmer())
        )

        let native = VisionManagerNative.create(with: platform)

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
        let native = VisionReplayManagerNative.create(withRecordPath: recordPath, videoPlayer: player)

        return ReplayDependencies(native: native, player: player)
    }
}
