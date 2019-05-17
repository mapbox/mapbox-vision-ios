//
//  VideoPlayer.swift
//  MapboxVision
//
//  Created by Alexander Pristavko on 5/17/19.
//  Copyright © 2019 Mapbox. All rights reserved.
//

import Foundation
import CoreMedia
import AVFoundation

protocol VideoPlayable: VideoSource {
    var delegate: VideoPlayerDelegate? { get set }

    func start()
    func stop()
}

protocol VideoPlayerDelegate: AnyObject {
    func playbackDidFinish()
}

private enum PlaybackConstants {
    static let frameDuration: TimeInterval = 0.03
}

final class VideoPlayer: NSObject, VideoPlayable {
    weak var delegate: VideoPlayerDelegate?

    private var isPlaying = false
    private let player: AVPlayer
    private let videoOutput: AVPlayerItemVideoOutput
    private var displayLink: CADisplayLink!

    private let observers = ObservableVideoSource()
    private var notificationToken: NSObjectProtocol?

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

        let attributes = [String(kCVPixelBufferPixelFormatTypeKey) : Int(kCVPixelFormatType_32BGRA)]
        videoOutput = AVPlayerItemVideoOutput(pixelBufferAttributes: attributes)

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
            self?.delegate?.playbackDidFinish()
        }
    }

    func start() {
        guard !isPlaying else { return }
        videoOutput.requestNotificationOfMediaDataChange(withAdvanceInterval: PlaybackConstants.frameDuration)
        player.play()
        isPlaying = true
    }

    func stop() {
        guard isPlaying else { return }
        isPlaying = false

        player.pause()
        displayLink?.isPaused = true

        player.currentItem?.seek(to: .zero, completionHandler: nil)
    }

    private func sampleBuffer(from pixelBuffer: CVPixelBuffer, timestamp: CMTime) -> CMSampleBuffer? {
        var info = CMSampleTimingInfo(duration: .invalid, presentationTimeStamp: .zero, decodeTimeStamp: timestamp)

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

    @objc
    private func updateOnDisplayLink(displaylink: CADisplayLink) {
        let nextVSync = displaylink.timestamp + displaylink.duration
        let time = videoOutput.itemTime(forHostTime: nextVSync)

        guard
            videoOutput.hasNewPixelBuffer(forItemTime: time),
            let pixelBuffer = videoOutput.copyPixelBuffer(forItemTime: time, itemTimeForDisplay: nil),
            let sampleBuffer = sampleBuffer(from: pixelBuffer, timestamp: time)
        else { return }

        observers.notify { (observer) in
            observer.videoSource(self, didOutput: VideoSample(buffer: sampleBuffer, format: .BGRA))
        }
    }
}

extension VideoPlayer: VideoSource {
    var isExternal: Bool {
        return false
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

