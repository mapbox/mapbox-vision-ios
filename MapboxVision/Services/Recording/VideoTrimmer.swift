//
//  VideoTrimmer.swift
//  MapboxVision
//
//  Created by Alexander Pristavko on 7/25/18.
//  Copyright © 2018 Mapbox. All rights reserved.
//

import Foundation
import AVFoundation

private let timeScale: CMTimeScale = 600

enum VideoTrimmerError: LocalizedError {
    case sourceIsNotExportable
}

final class VideoTrimmer {
    typealias TrimCompletion = (Error?) -> ()
    typealias TrimPoints = (startTime: CMTime, endTime: CMTime)
    
    func trimVideo(sourceURL: URL, destinationURL: URL, from start: TimeInterval, to end: TimeInterval, settings: VideoSettings, completion: TrimCompletion?) {
        print("log_t: trim source: \(sourceURL.path), dest: \(destinationURL.path) from \(start) to \(end)")
        let startTime = CMTime(seconds: start, preferredTimescale: timeScale)
        let endTime = CMTime(seconds: end, preferredTimescale: timeScale)
        
        let options = [
            AVURLAssetPreferPreciseDurationAndTimingKey: true
        ]
        
        let asset = AVURLAsset(url: sourceURL, options: options)
        guard asset.isExportable else {
            completion?(VideoTrimmerError.sourceIsNotExportable)
            return
        }
        
        let preferredPreset = AVAssetExportPresetPassthrough
        
        let composition = AVMutableComposition()
        guard
            let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: CMPersistentTrackID())
        else {
            assertionFailure("Unable to add video track to composition \(composition).")
            return
        }
        
        guard let videoAssetTrack: AVAssetTrack = asset.tracks(withMediaType: .video).first else {
            assertionFailure("Unable to obtain video track from asset \(asset).")
            return
        }
        
        let durationOfCurrentSlice = CMTimeSubtract(endTime, startTime)
        let timeRangeForCurrentSlice = CMTimeRangeMake(startTime, durationOfCurrentSlice)
        
        do {
            try videoTrack.insertTimeRange(timeRangeForCurrentSlice, of: videoAssetTrack, at: CMTime())
        }
        catch {
            completion?(error)
        }
        
        guard let exportSession = AVAssetExportSession(asset: composition, presetName: preferredPreset) else { return }
        
        exportSession.outputURL = destinationURL
        exportSession.outputFileType = settings.fileType
        exportSession.shouldOptimizeForNetworkUse = true
        
        exportSession.exportAsynchronously {
            completion?(exportSession.error)
        }
    }
}
