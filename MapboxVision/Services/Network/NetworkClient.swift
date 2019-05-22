import Foundation

protocol NetworkClient {

    func upload(file: URL, toFolder folderName: String, completion: @escaping (Error?) -> Void)
    func cancel()
}
