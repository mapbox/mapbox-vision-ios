import Foundation
import UIKit
import AVFoundation

final class VideoStreamView: UIView {
    
    override class var layerClass: AnyClass {
        return AVSampleBufferDisplayLayer.self
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        displayLayer?.videoGravity = .resizeAspectFill
    }

    var displayLayer: AVSampleBufferDisplayLayer? {
        return layer as? AVSampleBufferDisplayLayer
    }
    
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
