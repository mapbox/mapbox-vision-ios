import Foundation

// Path represents absolute path consisted of components
struct Path {

    // MARK: Properties

    var components: [String]

    var basePath: String {
        return "/" + components.dropLast().joined(separator: "/")
    }

    var rendered: String {
        return "/" + components.joined(separator: "/")
    }

    var subpaths: [String] {
        var paths = [String]()
        var currentPath = ""
        for component in components {
            currentPath += "/\(component)"
            paths.append(currentPath)
        }
        return paths
    }

    // MARK: Lifecycle

    init(_ components: [String]) {
        self.components = components
    }

    // MARK: Public properties

    func appending(_ component: String) -> Path {
        return Path(components + [component])
    }
    
    func prepending(base: String) -> Path {
        return Path([base] + components)
    }
}

extension Path: CustomStringConvertible {
    var description: String {
        return rendered
    }
}
