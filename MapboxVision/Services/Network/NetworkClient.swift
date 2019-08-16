import Foundation

protocol NetworkClient {
    func set(baseURL: URL?)
    func upload(file: URL, toFolder folderName: String, completion: @escaping (Error?) -> Void)
    func cancel()
}
