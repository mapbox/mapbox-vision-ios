import AVFoundation

struct VideoSettings {
    let width: Int
    let height: Int
    let codec: AVVideoCodecType
    let fileType: AVFileType
    let fileExtension: String
    let bitRate: Int
    
    var sessionPreset: AVCaptureSession.Preset? {
        switch (width, height) {
        case (640, 480):
            return AVCaptureSession.Preset.vga640x480
        case (960, 540):
            return AVCaptureSession.Preset.iFrame960x540
        case (1280, 720):
            return AVCaptureSession.Preset.hd1280x720
        case (1920, 1080):
            return AVCaptureSession.Preset.hd1920x1080
        default:
            return nil
        }
    }
    
    static let lowQuality = VideoSettings(
        width: 960,
        height: 540,
        codec: .h264,
        fileType: .mp4,
        fileExtension: "mp4",
        bitRate: 6_000_000
    )
    
    static let highQuality = VideoSettings(
        width: 1920,
        height: 1080,
        codec: .h264,
        fileType: .mp4,
        fileExtension: "mp4",
        bitRate: 6_000_000
    )
}
