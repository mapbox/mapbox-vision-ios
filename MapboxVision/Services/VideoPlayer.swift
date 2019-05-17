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
    func start()
    func stop()
}

final class VideoPlayer: VideoPlayable {
    private let observers = ObservableVideoSource()
    private var playerItemVideoOutput: AVPlayerItemVideoOutput?

    init(path: String) {

    }

    func start() {

    }

    func stop() {

    }


    private func sampleBuffer(from pixelBuffer: CVPixelBuffer, timestamp: CMTime) -> CMSampleBuffer {
        var info = CMSampleTimingInfo()
        info.presentationTimeStamp = CMTime.zero
        info.duration = CMTime.invalid
        info.decodeTimeStamp = timestamp

        var formatDesc: CMFormatDescription? = nil
        CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault,
                                                     imageBuffer: pixelBuffer,
                                                     formatDescriptionOut: &formatDesc)

        var sampleBuffer: CMSampleBuffer? = nil

        CMSampleBufferCreateReadyWithImageBuffer(allocator: kCFAllocatorDefault,
                                                 imageBuffer: pixelBuffer,
                                                 formatDescription: formatDesc!,
                                                 sampleTiming: &info,
                                                 sampleBufferOut: &sampleBuffer)

        return sampleBuffer!
    }

    @objc func updateOnDisplayLink(displaylink: CADisplayLink) {
        if let playerItemVideoOutput = playerItemVideoOutput {
            var currentTime = CMTime.invalid
            let nextVSync = displaylink.timestamp + displaylink.duration
            currentTime = playerItemVideoOutput.itemTime(forHostTime: nextVSync)

            if playerItemVideoOutput.hasNewPixelBuffer(forItemTime: currentTime), let pixelBuffer = playerItemVideoOutput.copyPixelBuffer(forItemTime: currentTime, itemTimeForDisplay: nil) {
                let nextSampleBuffer = sampleBuffer(from: pixelBuffer, timestamp: currentTime)

                observers.notify { (observer) in
                    observer.videoSource(self, didOutput: VideoSample(buffer: nextSampleBuffer, format: .BGRA))
                }
            }
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
