import AVFoundation
import MapboxVision
import UIKit

/**
 * "External camera" example demonstrates how to create a custom source of video stream and pass it to `VisionManager`.
 */

// Example of custom video source is a simple video file reader
class FileVideoSource: ObservableVideoSource {
    private let reader: AVAssetReader
    private let queue = DispatchQueue(label: "FileVideoSourceQueue")
    private lazy var timer: CADisplayLink = {
        let displayLink = CADisplayLink(target: self, selector: #selector(update))
        displayLink.preferredFramesPerSecond = 30
        return displayLink
    }()

    init(url: URL) {
        let asset = AVAsset(url: url)
        reader = try! AVAssetReader(asset: asset)

        super.init()

        let videoTrack = asset.tracks(withMediaType: .video).first!
        let output = AVAssetReaderTrackOutput(
            track: videoTrack,
            outputSettings: [
                String(kCVPixelBufferPixelFormatTypeKey): NSNumber(value: kCVPixelFormatType_32BGRA),
            ]
        )
        reader.add(output)
    }

    func start() {
        queue.async { [unowned self] in
            self.reader.startReading()
            self.timer.add(to: .main, forMode: .default)
        }
    }

    func stop() {
        queue.async { [unowned self] in
            self.stopReading()
        }
    }

    @objc
    func update() {
        queue.async { [unowned self] in
            if let buffer = self.reader.outputs.first?.copyNextSampleBuffer() {
                // notify all abservers about new sample buffer availability
                self.notify { observer in
                    // construct `VideoSample` specifying the format of image contained in a sample buffer
                    let videoSample = VideoSample(buffer: buffer, format: .BGRA)
                    observer.videoSource(self, didOutput: videoSample)
                }
            } else {
                self.stopReading()
            }
        }
    }

    private func stopReading() {
        timer.invalidate()
        reader.cancelReading()
    }
}

class ExternalCameraViewController: UIViewController, VisionManagerDelegate {
    private var fileVideoSource: FileVideoSource!
    private var visionManager: VisionManager!
    private let visionViewController = VisionPresentationViewController()

    override func viewDidLoad() {
        super.viewDidLoad()

        addVisionView()

        // create a custom video source and subscribe to receiving new video samples
        fileVideoSource = FileVideoSource(url: Bundle.main.url(forResource: "video", withExtension: "mp4")!)
        fileVideoSource.add(observer: self)

        // create VisionManager with a custom video source
        visionManager = VisionManager.create(videoSource: fileVideoSource)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        visionManager.start(delegate: self)
        fileVideoSource.start()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        fileVideoSource.stop()
        visionManager.stop()
    }

    private func addVisionView() {
        addChild(visionViewController)
        view.addSubview(visionViewController.view)
        visionViewController.didMove(toParent: self)
    }
}

extension ExternalCameraViewController: VideoSourceObserver {
    func videoSource(_ videoSource: VideoSource, didOutput videoSample: VideoSample) {
        DispatchQueue.main.async { [weak self] in
            // display received sample buffer by passing it to presentation controller
            self?.visionViewController.present(sampleBuffer: videoSample.buffer)
        }
    }
}
