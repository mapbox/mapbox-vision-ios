import Foundation

extension String {
    var nsString: NSString {
        self as NSString
    }

    func appendingPathComponent(_ str: String, isDirectory: Bool = false) -> String {
        let string = nsString.appendingPathComponent(str)
        if isDirectory {
            return string.appending("/")
        }
        return string
    }

    var lastPathComponent: String {
        nsString.lastPathComponent
    }

    var deletingLastPathComponent: String {
        nsString.deletingLastPathComponent
    }

    var deletingPathExtension: String {
        nsString.deletingPathExtension
    }
}
