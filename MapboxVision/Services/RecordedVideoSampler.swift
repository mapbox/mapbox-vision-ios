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
        setupPlayer(url: fileURL)
        startTimestamp = Date.timeIntervalSinceReferenceDate

        if displayLink == nil {
            displayLink = CADisplayLink(target: self, selector: #selector(self.updateOnDisplayLink))
            displayLink!.add(to: .main, forMode: .defaultRunLoopMode)
        } else {
            displayLink?.isPaused = false
        }
    }

    func stop() {
        // stop reading
        displayLink?.isPaused = true
    }

    var focalLength: Float {
        //avic -- pull this from the recorded camera info
        return iPhoneXBackFacingCameraFocalLength
    }

    var fieldOfView: Float {
        //avic -- pull this from the recorded camera info
        return iPhoneXBackFacingCameraFoV
    }

    private func sampleBuffer(from pixelBuffer: CVPixelBuffer, timestamp: CMTime) -> CMSampleBuffer {
            var info = CMSampleTimingInfo()
            info.presentationTimeStamp = kCMTimeZero
            info.duration = kCMTimeInvalid
            info.decodeTimeStamp = timestamp

            var formatDesc: CMFormatDescription? = nil
            CMVideoFormatDescriptionCreateForImageBuffer(kCFAllocatorDefault, pixelBuffer, &formatDesc)

            var sampleBuffer: CMSampleBuffer? = nil

            CMSampleBufferCreateReadyWithImageBuffer(kCFAllocatorDefault, pixelBuffer, formatDesc!, &info, &sampleBuffer);

            return sampleBuffer!
    }

    @objc func updateOnDisplayLink(displaylink: CADisplayLink) {
        if let playerItemVideoOutput = playerItemVideoOutput {
            var currentTime = kCMTimeInvalid
            let nextVSync = displaylink.timestamp + displaylink.duration
            currentTime = playerItemVideoOutput.itemTime(forHostTime: nextVSync)

            if playerItemVideoOutput.hasNewPixelBuffer(forItemTime: currentTime), let pixelBuffer = playerItemVideoOutput.copyPixelBuffer(forItemTime: currentTime, itemTimeForDisplay: nil) {
                let nextSampleBuffer = sampleBuffer(from: pixelBuffer, timestamp: currentTime)
                self.didCaptureFrame?(nextSampleBuffer)
            }
        }
    }
}
