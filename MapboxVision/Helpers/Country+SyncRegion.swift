import Foundation

extension Country {
    var syncRegion: SyncRegion? {
        switch self {
        case .USA, .UK, .other:
            return .other
        case .china:
            return .china
        case .unknown:
            return nil
        }
    }
}
