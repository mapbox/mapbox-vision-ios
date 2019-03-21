//
//  FileVideoSource.swift
//  ExternalCameraSample
//
//  Copyright © 2019 Mapbox. All rights reserved.
//

import Foundation
import MapboxVision

class FileVideoSource: VideoSource {
    
    private struct Observation {
        weak var observer: VideoSourceObserver?
    }
    
    private let reader: AVAssetReader
    private var observations = [ObjectIdentifier : Observation]()
    private let queue = DispatchQueue(label: "FileVideoSourceQueue")
    
    init(url: URL) {
        let asset = AVAsset(url: url)
        reader = try! AVAssetReader(asset: asset)
        
        let videoTrack = asset.tracks(withMediaType: .video).first!
        let output = AVAssetReaderTrackOutput(
            track: videoTrack,
            outputSettings: [String(kCVPixelBufferPixelFormatTypeKey): NSNumber(value: kCVPixelFormatType_32BGRA)]
        )
        reader.add(output)
    }
    
    var isExternal: Bool {
        return true
    }
    
    func add(observer: VideoSourceObserver) {
        let id = ObjectIdentifier(observer)
        observations[id] = Observation(observer: observer)
    }
    
    func remove(observer: VideoSourceObserver) {
        let id = ObjectIdentifier(observer)
        observations.removeValue(forKey: id)
    }
    
    func start() {
        self.reader.startReading()
        
        queue.async { [unowned self] in
            while let buffer = self.reader.outputs.first?.copyNextSampleBuffer() {
                self.notify { observer in
                    let videoSample = VideoSample(buffer: buffer, format: .BGRA)
                    observer.videoSource(self, didOutput: videoSample)
                }
            }
        }
    }
    
    private func notify(closure: (VideoSourceObserver) -> Void) {
        observations.forEach { (id, observation) in
            guard let observer = observation.observer else {
                observations.removeValue(forKey: id)
                return
            }
            closure(observer)
        }
    }
}
