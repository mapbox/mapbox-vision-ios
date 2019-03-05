//
//  RecordedVideoSampler.swift
//  MapboxVision
//
//  Created by Avi Cieplinski on 2/14/19.
//  Copyright © 2019 Mapbox. All rights reserved.
//

import UIKit
import AVFoundation
import ModelIO

class RecordedVideoSampler: NSObject, Streamable {

    typealias Handler = (CMSampleBuffer) -> Void

    let iPhoneXBackFacingCameraFoV: Float = Float(65.576)
    let iPhoneXBackFacingCameraFocalLength: Float = Float(23.551327)

    var assetPath: String?
    var assetFrameRate: Float = 30.0
    var updateFrequence: Float = 1.0 / 30.0
    var assetVideoTrackReader: AVAssetReaderTrackOutput?
    var playerItemVideoOutput: AVPlayerItemVideoOutput?
    var player: AVPlayer?
    var assetReader: AVAssetReader?
    var displayLink: CADisplayLink?
    var lastUpdateInterval: TimeInterval = Date.timeIntervalSinceReferenceDate
    var didCaptureFrame: Handler?
    var frameUpdateTimer: Timer?
    var startTimestamp: TimeInterval = 0

    init(pathToRecording: String) {
        super.init()
        assetPath = pathToRecording
    }

    func setupAsset(url: URL) {
        let asset = AVAsset(url: url)

        // load the asset tracks so we can read from the video track
        asset.loadValuesAsynchronously(forKeys: ["tracks"]) { [weak self] in
            print("loadValuesAsynchronously worked")

            var error: NSError?
            guard asset.statusOfValue(forKey: "tracks", error: &error) == AVKeyValueStatus.loaded
                else {
                    print("\(String(describing: error))")
                    return
            }

            if let firstVideoTrack = asset.tracks(withMediaType: AVMediaType.video).first {
                print("found at least one video track")

                if let self = self {
                    // use the framerate of the video file to control the rate of sending frames to the callback
                    self.assetFrameRate = firstVideoTrack.nominalFrameRate
                    self.updateFrequence = 1.0 / self.assetFrameRate
                    self.assetReader = try! AVAssetReader(asset: asset)
                    let outputSettings = [(kCVPixelBufferPixelFormatTypeKey as String) : NSNumber(value: kCVPixelFormatType_32BGRA)]

                    self.assetVideoTrackReader = AVAssetReaderTrackOutput(track: firstVideoTrack, outputSettings: outputSettings)
                    self.assetReader?.add(self.assetVideoTrackReader!)
                    self.assetReader?.startReading()
                }
            }
        }
    }

    func setupPlayer(url: URL) {
        let asset = AVAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)

        player = AVPlayer(playerItem: playerItem)

        let attributes = [kCVPixelBufferPixelFormatTypeKey as String : Int(kCVPixelFormatType_32BGRA)]
        playerItemVideoOutput = AVPlayerItemVideoOutput(pixelBufferAttributes: attributes)

        if let playerItemVideoOutput = playerItemVideoOutput {
            playerItem.add(playerItemVideoOutput)
            player!.play()
        }
    }

    func start() {
        let fileURL = URL(fileURLWithPath: assetPath!)
//        setupAsset(url: fileURL)
        setupPlayer(url: fileURL)
        startTimestamp = Date.timeIntervalSinceReferenceDate
        #if UPDATE_FRAMES_ON_TIMER
        if frameUpdateTimer == nil {
            frameUpdateTimer = Timer.scheduledTimer(timeInterval: TimeInterval(self.updateFrequence), target: self, selector: #selector(updateOnTimer), userInfo: nil, repeats: true)
        }
        #else
        if displayLink == nil {
            displayLink = CADisplayLink(target: self, selector: #selector(self.updateOnDisplayLink))
            displayLink!.add(to: .main, forMode: .defaultRunLoopMode)
        }
        #endif
    }

    func stop() {
        // stop reading
    }

    var focalLength: Float {
        //avic -- pull this from the recorded camera info
        return iPhoneXBackFacingCameraFocalLength
    }

    var fieldOfView: Float {
        //avic -- pull this from the recorded camera info
        return iPhoneXBackFacingCameraFoV
    }

    private func sampleBuffer(from pixelBuffer: CVPixelBuffer) -> CMSampleBuffer {
            var info = CMSampleTimingInfo()
            info.presentationTimeStamp = kCMTimeZero
            info.duration = kCMTimeInvalid
            info.decodeTimeStamp = kCMTimeInvalid

            var formatDesc: CMFormatDescription? = nil
            CMVideoFormatDescriptionCreateForImageBuffer(kCFAllocatorDefault, pixelBuffer, &formatDesc)

            var sampleBuffer: CMSampleBuffer? = nil

            CMSampleBufferCreateReadyWithImageBuffer(kCFAllocatorDefault,
                                                     pixelBuffer,
                                                     formatDesc!,
                                                     &info,
                                                     &sampleBuffer);

            return sampleBuffer!
    }

    private func updateFrameIfNeeded() {
        let assetReadingFailed = !(assetReader?.status == AVAssetReaderStatus.unknown || assetReader?.status == AVAssetReaderStatus.reading)
        guard assetReadingFailed == false else {
            if self.assetReader?.status == AVAssetReaderStatus.failed {
                print("RecordedViewSampler - Video asset read error!")
            } else if self.assetReader?.status == AVAssetReaderStatus.completed {
                print("RecordedViewSampler - Video asset read completed.")
            }

            // stop updates
            if frameUpdateTimer != nil {
                frameUpdateTimer!.invalidate()
                frameUpdateTimer = nil
            }

            if displayLink != nil {
                displayLink!.isPaused = true
                displayLink!.remove(from: .main, forMode: .defaultRunLoopMode)
                displayLink!.invalidate()
                displayLink = nil
            }

            return
        }

        if let displayLink = displayLink, let playerItemVideoOutput = playerItemVideoOutput {
            var currentTime = kCMTimeInvalid
            let nextVSync = displayLink.timestamp + displayLink.duration
            currentTime = playerItemVideoOutput.itemTime(forHostTime: nextVSync)

            if playerItemVideoOutput.hasNewPixelBuffer(forItemTime: currentTime), let pixelBuffer = playerItemVideoOutput.copyPixelBuffer(forItemTime: currentTime, itemTimeForDisplay: nil) {
                let nextSampleBuffer = sampleBuffer(from: pixelBuffer)
                self.didCaptureFrame?(nextSampleBuffer)
                print("bla")
            }
        }
        #if false
        let shouldSendNewFrame = assetReader?.status == AVAssetReaderStatus.reading
        if shouldSendNewFrame {
            if let nextSampleBuffer = self.assetVideoTrackReader?.copyNextSampleBuffer() {
                DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                    guard let self = self else {
                        return
                    }
                    self.didCaptureFrame?(nextSampleBuffer)
                }
            }
        }
        #endif
    }

    @objc func updateOnDisplayLink(displaylink: CADisplayLink) {
        let now = Date.timeIntervalSinceReferenceDate
        let timeSinceLastFrameSent = Float(now - lastUpdateInterval)

        // send a video frame at no faster than the video file framerate. We should match it identically
        let shouldSendNewFrame = timeSinceLastFrameSent >= self.updateFrequence
        if shouldSendNewFrame {
            updateFrameIfNeeded()
            lastUpdateInterval = Date.timeIntervalSinceReferenceDate
        }

    }

    @objc func updateOnTimer() {
        updateFrameIfNeeded()
    }
}
