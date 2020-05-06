import AVFoundation
import MapboxVision
import UIKit

/**
 * "External camera" example demonstrates how to create a custom source of a video stream
 * and pass it to `VisionManager`.
 * **Important:** To enable most of the features of Vision SDK like world description, AR and Safety, the object
 * implementing the `VideoSource` protocol should also provide `CameraParameters`.
 * Reading a file is an example of implementing `VideoSource` protocol. Do not feed recorded videos in production
 * as the video will not match other realtime data (GPS, motion sensors) causing incorrect values
 * for most of the features.
 */

// Example of custom video source is a simple video file reader
class FileVideoSource: ObservableVideoSource {
    private let reader: AVAssetReader?
    private let queue = DispatchQueue(label: "FileVideoSourceQueue")
    private lazy var timer: CADisplayLink = {
        let displayLink = CADisplayLink(target: self, selector: #selector(update))
        displayLink.preferredFramesPerSecond = 30
        return displayLink
    }()

    init(url: URL) {
        let asset = AVAsset(url: url)
        reader = try? AVAssetReader(asset: asset)

        super.init()

        let videoTrack = asset.tracks(withMediaType: .video).first!
        let output = AVAssetReaderTrackOutput(
            track: videoTrack,
            outputSettings: [
                String(kCVPixelBufferPixelFormatTypeKey): NSNumber(value: kCVPixelFormatType_32BGRA),
            ]
        )
        reader?.add(output)
    }

    func start() {
        queue.async { [unowned self] in
            self.reader?.startReading()
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
            if let buffer = self.reader?.outputs.first?.copyNextSampleBuffer() {
                // notify all abservers about new sample buffer availability
                self.notify { observer in
                    // construct `VideoSample` specifying the format of image contained in a sample buffer
                    let videoSample = VideoSample(buffer: buffer, format: .BGRA)
                    observer.videoSource(self, didOutput: videoSample)

                    // Obtain camera parameters and set them each time they change
                    // let cameraParameters = CameraParameters(width: width, height: height,
                    //                                         focalXPixels: focalPixelX, focalYPixels: focalPixelY)
                    // observer.videoSource(self, didOutput: cameraParameters)
                }
            } else {
                self.stopReading()
            }
        }
    }

    private func stopReading() {
        timer.invalidate()
        reader?.cancelReading()
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

        // create VisionManager with a custom video source
        visionManager = VisionManager.create(videoSource: fileVideoSource)
        visionManager.delegate = self

        // configure view to display sample buffers from video source
        visionViewController.set(visionManager: visionManager)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        visionManager.start()
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

    deinit {
        // free up VisionManager's resources
        visionManager.destroy()
    }
}
