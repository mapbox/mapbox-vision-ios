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
        let searchDirectory: FileManager.SearchPathDirectory?

        switch self {
        case .currentRecording, .cache, .recordings:
            searchDirectory = .cachesDirectory
        case .custom:
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

        return basePath.appendingPathComponent(directoryName, isDirectory: true)
    }
}

private class BundleToken {
    private init() {}
}
