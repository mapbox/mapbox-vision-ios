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
    var assetVideoTrackReader: AVAssetReaderTrackOutput?
    var displayLink: CADisplayLink?
    var lastUpdateInterval: TimeInterval = 0
    var didCaptureFrame: Handler?

    init(pathToRecording: String) {
        super.init()
        assetPath = pathToRecording
    }

    func recordedAsset() -> AVAsset? {
        guard let assetPath = assetPath else { return nil }
        let movieFileURL = URL(fileURLWithPath: assetPath)
        let asset = AVAsset(url: movieFileURL)

        return asset
    }

    func setupAsset() -> AVAssetReaderTrackOutput? {
        guard let asset = recordedAsset() else { return nil }

        if let firstVideoTrack = asset.tracks(withMediaType: AVMediaType.video).first {
            print("found at least one video track")

            let outputSettings = [(kCVPixelBufferPixelFormatTypeKey as String) : NSNumber(value: kCVPixelFormatType_32BGRA)]
            let assetVideoTrackReader = AVAssetReaderTrackOutput(track: firstVideoTrack, outputSettings: outputSettings)

            //avic now do something with the samples
            // i'll try a repeating times
            return assetVideoTrackReader
        }
        return nil
    }

    @objc func update() {
        print("Updating!")

        if let nextSampleBuffer = assetVideoTrackReader?.copyNextSampleBuffer() {

            let now = Date.timeIntervalSinceReferenceDate
            let timeElapsed = now - lastUpdateInterval

            // avic - add some kind of tolerance over 60fps?
            if (timeElapsed <= 1.0 / 60.0) {
                didCaptureFrame?(nextSampleBuffer)
            }
        }

        lastUpdateInterval = Date.timeIntervalSinceReferenceDate
    }

    func start() {
        // begin reading from the file and sending frames to the delegate
        print("start()")
        if let reader = setupAsset() {
            print("setup asset worked")
            assetVideoTrackReader = reader

            // setup a repeating read of the asset

            displayLink = CADisplayLink(target: self, selector: #selector(update))
            
            if let displayLink = displayLink {
                displayLink.add(to: .current, forMode: .commonModes)
            }
        } else {
            print("setup asset did not work")
        }
    }

    func stop() {
        // stop reading
    }

    var focalLength: Float {
        return iPhoneXBackFacingCameraFocalLength
    }

    var fieldOfView: Float {
        return iPhoneXBackFacingCameraFoV
    }

    // avic - call this
    // didCaptureFrame?(sampleBuffer)
    // with sampleBuffer: CMSampleBuffer
}
