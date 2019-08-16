import Foundation

enum DocumentsLocation: Equatable {
    case currentRecording
    case recordings(SyncRegion)
    case cache
    case custom

    private var directoryName: String {
        switch self {
        case .currentRecording:
            return "Current"
        case .cache:
            return "Cache"
        case let .recordings(region):
            return "Recording_\(region.rawValue)"
        case .custom:
            return ""
        }
    }

    var path: String {
        var basePath: String = NSTemporaryDirectory()

        if
            self != .custom,
            let cachesPath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first
        {
            basePath = cachesPath
        }

        if let bundleIdentifier = Bundle(for: BundleToken.self).bundleIdentifier {
            basePath = basePath.appendingPathComponent(bundleIdentifier, isDirectory: true)
        }

        return basePath.appendingPathComponent(directoryName, isDirectory: true)
    }
}

private final class BundleToken {
    private init() {}
}
