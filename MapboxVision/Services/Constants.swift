import Foundation

enum Constants {
    static let motionUpdateInterval: TimeInterval = 1 / 30.0
    static let millisecondsInSecond: Double = 1000
    static let frameDuration: TimeInterval = 1 / 30.0
    static let preferredTimescale: Int32 = 600

    enum URL {
        static let defaultEventsEndpoint = "https://events.mapbox.com"
        static let chinaEventsEndpoint = "https://events.mapbox.cn"
    }
}
