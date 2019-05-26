import Foundation
import UIKit
import AVFoundation

protocol VideoStreamViewInput {
    func enqueue(_ sampleBuffer: CMSampleBuffer)
}

final class VideoStreamView: UIView {

    // MARK: Properties

    override class var layerClass: AnyClass {
        return AVSampleBufferDisplayLayer.self
    }

    var displayLayer: AVSampleBufferDisplayLayer? {
        return layer as? AVSampleBufferDisplayLayer
    }

    // MARK: Lifecycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonViewInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonViewInit()
    }

    // MARK: Private functions

    private func commonViewInit() {
        displayLayer?.videoGravity = .resizeAspectFill
        self.translatesAutoresizingMaskIntoConstraints = false
        self.isHidden = true
    }
}

extension VideoStreamView: VideoStreamViewInput {
    func enqueue(_ sampleBuffer: CMSampleBuffer) {
        if let attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, createIfNecessary: false) {
            let dict = unsafeBitCast(CFArrayGetValueAtIndex(attachments, 0), to: CFMutableDictionary.self)
            let doNotDisplayKey = Unmanaged.passUnretained(kCMSampleAttachmentKey_DoNotDisplay).toOpaque()
            let doNotDisplayValue = Unmanaged.passUnretained(kCFBooleanFalse).toOpaque()
            CFDictionarySetValue(dict, doNotDisplayKey, doNotDisplayValue)
        }

        displayLayer?.flush()
        displayLayer?.enqueue(sampleBuffer)
    }
}
