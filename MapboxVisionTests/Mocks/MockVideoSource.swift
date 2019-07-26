import Foundation
@testable import MapboxVision

class MockVideoSource: VideoSource {
    var isExternal: Bool = true

    func add(observer: VideoSourceObserver) {}

    func remove(observer: VideoSourceObserver) {}
}
