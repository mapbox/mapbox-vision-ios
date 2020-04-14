import AVFoundation
import CoreMedia
import Foundation

protocol VideoPlayable: VideoSource {
    func start()
    func stop()
}

final class VideoPlayer: NSObject {
    private var isPlaying = false
    private let player: AVPlayer
    private let videoOutput: AVPlayerItemVideoOutput
    private var displayLink: CADisplayLink!

    private let observers = ObservableVideoSource()
    private let nativeObservers: MBVVideoSource
    private var notificationToken: NSObjectProtocol!
    private let queue = DispatchQueue(label: "com.mapbox.VideoPlayer")

    init(path: String) throws {
        guard FileManager.default.fileExists(atPath: path) else {
            throw CocoaError(.fileNoSuchFile)
        }

        let url = URL(fileURLWithPath: path)
        let asset = AVAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)

        player = AVPlayer(playerItem: playerItem)
        player.actionAtItemEnd = .none

        let attributes = [String(kCVPixelBufferPixelFormatTypeKey): Int(kCVPixelFormatType_32BGRA)]
        videoOutput = AVPlayerItemVideoOutput(pixelBufferAttributes: attributes)
        nativeObservers = VideoSourceObserverProxy(withVideoSource: observers)

        super.init()

        videoOutput.setDelegate(self, queue: queue)
        playerItem.add(videoOutput)

        self.displayLink = CADisplayLink(target: self, selector: #selector(updateOnDisplayLink))
        displayLink.add(to: RunLoop.current, forMode: RunLoop.Mode.default)
        displayLink.isPaused = true

        notificationToken = NotificationCenter.default.addObserver(
            forName: Notification.Name.AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak self] _ in
            self?.stop()
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(notificationToken)
    }

    @objc
    private func updateOnDisplayLink(displaylink: CADisplayLink) {
        let nextVSync = displaylink.timestamp + displaylink.duration
        let time = videoOutput.itemTime(forHostTime: nextVSync)

        guard
            videoOutput.hasNewPixelBuffer(forItemTime: time),
            let pixelBuffer = videoOutput.copyPixelBuffer(forItemTime: time, itemTimeForDisplay: nil),
            let sampleBuffer = CMSampleBuffer.sampleBuffer(from: pixelBuffer, timeStamp: time)
        else { return }

        observers.notify { observer in
            observer.videoSource(self, didOutput: VideoSample(buffer: sampleBuffer, format: .BGRA))
        }
    }
}

extension VideoPlayer: VideoPlayable {
    func start() {
        guard !isPlaying else { return }
        videoOutput.requestNotificationOfMediaDataChange(withAdvanceInterval: Constants.frameDuration)
        player.play()
        isPlaying = true
    }

    func stop() {
        guard isPlaying else { return }
        isPlaying = false

        player.pause()
        displayLink?.isPaused = true
    }
}

extension VideoPlayer: VideoSource {
    var isExternal: Bool {
        false
    }

    func add(observer: VideoSourceObserver) {
        observers.add(observer: observer)
    }

    func remove(observer: VideoSourceObserver) {
        observers.remove(observer: observer)
    }
}

extension VideoPlayer: AVPlayerItemOutputPullDelegate {
    func outputMediaDataWillChange(_ sender: AVPlayerItemOutput) {
        displayLink.isPaused = false
    }
}

private extension CMSampleBuffer {
    static func sampleBuffer(from pixelBuffer: CVPixelBuffer, timeStamp: CMTime) -> CMSampleBuffer? {
        var info = CMSampleTimingInfo(duration: .invalid, presentationTimeStamp: .zero, decodeTimeStamp: timeStamp)

        var formatDescription: CMFormatDescription?
        let status = CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault,
                                                                  imageBuffer: pixelBuffer,
                                                                  formatDescriptionOut: &formatDescription)

        guard status == noErr, let format = formatDescription else { return nil }

        var sampleBuffer: CMSampleBuffer?
        CMSampleBufferCreateReadyWithImageBuffer(allocator: kCFAllocatorDefault,
                                                 imageBuffer: pixelBuffer,
                                                 formatDescription: format,
                                                 sampleTiming: &info,
                                                 sampleBufferOut: &sampleBuffer)
        return sampleBuffer
    }
}

extension VideoPlayer: VideoPlayerProtocol {
    func addListener(_ listener: MBVVideoSourceObserver) {
        nativeObservers.add(observer: listener)
    }

    func removeListener(_ listener: MBVVideoSourceObserver) {
        nativeObservers.remove(observer: listener)
    }

    var progress: Float {
        get {
            Float(CMTimeGetSeconds(player.currentTime()))
        }
        set(progress) {
            player.seek(to: CMTimeMakeWithSeconds(Double(progress), preferredTimescale: Constants.preferredTimescale))
        }
    }

    var duration: Float {
        guard let cmTime = player.currentItem?.duration else { return 0.0 }
        return Float(CMTimeGetSeconds(cmTime))
    }
}
