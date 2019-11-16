import AVFoundation
import Foundation

enum VideoTrimmerError: LocalizedError {
    case notSuitableSource
    case incorrectConfiguration
}

final class VideoTrimmer {
    typealias TrimCompletion = (Error?) -> Void

    private enum Constants {
        static let timeScale: CMTimeScale = 600
        static let fileType: AVFileType = .mp4
    }

    func trimVideo(source: String, clip: VideoClip, completion: @escaping TrimCompletion) {
        let sourceURL = URL(fileURLWithPath: source)
        let options = [
            AVURLAssetPreferPreciseDurationAndTimingKey: true,
        ]

        let asset = AVURLAsset(url: sourceURL, options: options)
        guard
            asset.isExportable,
            let videoAssetTrack = asset.tracks(withMediaType: .video).first
        else {
            assertionFailure("Source asset is not exportable or doesn't contain a video track. Asset: \(asset).")
            completion(VideoTrimmerError.notSuitableSource)
            return
        }

        let composition = AVMutableComposition()
        guard
            let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: CMPersistentTrackID())
        else {
            assertionFailure("Unable to add video track to composition \(composition).")
            completion(VideoTrimmerError.incorrectConfiguration)
            return
        }

        let startTime = CMTime(seconds: Double(clip.startTime), preferredTimescale: Constants.timeScale)
        let endTime = CMTime(seconds: Double(clip.stopTime), preferredTimescale: Constants.timeScale)

        let durationOfCurrentSlice = CMTimeSubtract(endTime, startTime)
        let timeRangeForCurrentSlice = CMTimeRangeMake(start: startTime, duration: durationOfCurrentSlice)

        do {
            try videoTrack.insertTimeRange(timeRangeForCurrentSlice, of: videoAssetTrack, at: CMTime())
        } catch {
            completion(error)
            return
        }

        guard
            let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetPassthrough)
        else {
            assertionFailure("Unable to create an export session with composition \(composition).")
            completion(VideoTrimmerError.incorrectConfiguration)
            return
        }

        exportSession.outputURL = URL(fileURLWithPath: clip.path)
        exportSession.outputFileType = Constants.fileType
        exportSession.shouldOptimizeForNetworkUse = true

        exportSession.exportAsynchronously {
            completion(exportSession.error)
        }
    }
}
