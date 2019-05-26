extension Country {
    var allowsRecording: Bool {
        switch self {
        case .USA, .UK, .other, .unknown:
            return true
        case .china:
            return false
        }
    }
}
