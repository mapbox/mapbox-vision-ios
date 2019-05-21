import Foundation

enum Result<T, E> {
    case value(T)
    case error(E)
}
