import Foundation

enum DocumentsLocation: Equatable {
    case currentRecording
    case recordings(SyncRegion)
    case cache
    case custom

    private var value: String {
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
        let searchDirectory: FileManager.SearchPathDirectory?

        switch self {
        case .currentRecording, .cache:
            searchDirectory = .cachesDirectory
        case .recordings:
            searchDirectory = .applicationSupportDirectory
        default:
            searchDirectory = nil
        }

        var basePath: String

        if
            let searchDirectory = searchDirectory,
            let baseDirectory = NSSearchPathForDirectoriesInDomains(searchDirectory, .userDomainMask, true).first
        {
            basePath = baseDirectory
        } else {
            basePath = NSTemporaryDirectory()
        }

        if let bundleIdentifier = Bundle(for: BundleToken.self).bundleIdentifier {
            basePath = basePath.appendingPathComponent(bundleIdentifier, isDirectory: true)
        }

        return basePath.appendingPathComponent(value, isDirectory: true)
    }
}

private class BundleToken {
    private init() {}
}
