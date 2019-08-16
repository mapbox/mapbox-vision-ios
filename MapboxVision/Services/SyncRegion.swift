import Foundation

enum SyncRegion: String {
    case china = "China"
    case other = "Other"
}

extension SyncRegion {
    var baseURL: URL? {
        let urlString: String
        switch self {
        case .other:
            urlString = Constants.URL.defaultEventsEndpoint
        case .china:
            urlString = Constants.URL.chinaEventsEndpoint
        }

        return URL(string: urlString)
    }
}
