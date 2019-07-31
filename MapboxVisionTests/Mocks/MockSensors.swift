import CoreLocation
@testable import MapboxVisionNative

class MockSensors: NSObject, SensorsInterface {
    func setImage(_ image: CVPixelBuffer) {}

    func setCameraParameters(_ cameraParameters: CameraParameters) {}

    func setGPS(_ location: CLLocation) {}

    func setHeading(_ heading: CLHeading) {}

    func setDeviceMotion(_ motion: CMDeviceMotion, with frame: CMAttitudeReferenceFrame) {}
}
