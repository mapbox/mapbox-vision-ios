import Foundation

final class Media: NSObject {
    private let recorder: FrameRecordable
    private let videoTrimmer: VideoTrimmer

    init(recorder: FrameRecordable, videoTrimmer: VideoTrimmer) {
        self.recorder = recorder
        self.videoTrimmer = videoTrimmer
    }
}

extension Media: MediaInterface {
    func startVideoRecording(filePath: String) {
        recorder.startRecording(to: filePath, settings: .lowQuality)
    }

    func stopVideoRecording() {
        recorder.stopRecording()
    }

    func makeVideoClips(inputFilePath: String, clips: [VideoClip], callback: @escaping SuccessCallback) {
        var success = true
        let group = DispatchGroup()

        for clip in clips {
            group.enter()
            videoTrimmer.trimVideo(source: inputFilePath, clip: clip) { error in
                if error != nil {
                    success = false
                }
                group.leave()
            }
        }

        group.notify(queue: DispatchQueue.global(qos: .utility)) {
            callback(success)
        }
    }
}
