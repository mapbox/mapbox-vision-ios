import CoreLocation
@testable import MapboxVisionNative

class MockSensors: NSObject, SensorsInterface {
    func setVideoSample(_ videoSample: VideoSample) {}

    func setCameraParameters(_ cameraParameters: CameraParameters) {}

    func setGPS(_ location: CLLocation) {}

    func setHeading(_ heading: CLHeading) {}

    func setDeviceMotion(_ motion: CMDeviceMotion, with frame: CMAttitudeReferenceFrame) {}
}
