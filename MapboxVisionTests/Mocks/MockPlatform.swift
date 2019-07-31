@testable import MapboxVision

class MockPlatform: NSObject, PlatformInterface {
    func makeVideoClip(_ startTime: Float, end endTime: Float) {}

    func sendTelemetry(_ name: String, entries: [TelemetryEntry]) {}

    func save(image: Image, path: String) {}
}
