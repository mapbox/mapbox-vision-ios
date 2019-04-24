import Foundation

final class FileRecorder {

    private let stream: OutputStream
    private var firstChunk = true

    init?(path: String) {
        guard let stream = OutputStream(toFileAtPath: path, append: true) else { return nil }
        self.stream = stream
        stream.open()
        stream.write(string: "[")
    }

    func record<T: Encodable>(_ info: T) {

        if firstChunk {
            firstChunk = false
        } else {
            stream.write(string: ",")
        }

        guard let encoded = try? JSONEncoder().encode(info)
            else { assertionFailure("Can't encode metainfo record to json data"); return }

        guard let jsonObject = try? JSONSerialization.jsonObject(with: encoded, options: [])
            else { assertionFailure("Can't convert encoded data to json object"); return }

        var error: NSError?
        JSONSerialization.writeJSONObject(jsonObject, to: self.stream, options: JSONSerialization.WritingOptions.prettyPrinted, error: &error)
        if let error = error { assertionFailure(error.localizedDescription); return }
    }

    deinit {
        stream.write(string: "]")
        stream.close()
    }
}

fileprivate extension OutputStream {
    func write(string: String) {
        let _ = string.data(using: .utf8)?.withUnsafeBytes { ptr in
            self.write(ptr, maxLength: string.lengthOfBytes(using: .utf8))
        }
    }
}
