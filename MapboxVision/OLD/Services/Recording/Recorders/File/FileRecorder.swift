import Foundation

private let startOfMessageSymbol = "["
private let chunkDelimeter = ","
private let endOfMessageSymbol = "]"

final class FileRecorder: NSObject {
    // MARK: Private functions

    private let outputStream: OutputStream
    private var firstChunkIsBeingRecorded = true

    // MARK: Lifecycle

    init?(path: String) {
        guard let stream = OutputStream(toFileAtPath: path, append: true) else { return nil }
        self.outputStream = stream
        stream.open()
    }

    deinit {
        writeEndOfMessageSymbol()
        outputStream.close()
    }

    // MARK: Public functions

    func record<T: Encodable>(_ info: T) {
        writeChunkDelimeterIfNeeded()
        
        guard let encodedData = try? JSONEncoder().encode(info)
            else { assertionFailure("Can't encode metainfo record to json data"); return }
        
        guard let jsonObject = try? JSONSerialization.jsonObject(with: encodedData, options: [])
            else { assertionFailure("Can't convert encoded data to json object"); return }
        
        var error: NSError?
        JSONSerialization.writeJSONObject(jsonObject,
                                          to: self.outputStream,
                                          options: JSONSerialization.WritingOptions.prettyPrinted,
                                          error: &error)
        if let error = error { assertionFailure(error.localizedDescription); return }
    }

    // MARK: Private properties

    private func writeChunkDelimeterIfNeeded() {
        if !firstChunkIsBeingRecorded {
            outputStream.write(string: chunkDelimeter)
        } else {
            firstChunkIsBeingRecorded = false
        }
    }

    private func writeStartOfMessageSymbol() {
        outputStream.write(string: startOfMessageSymbol)
    }

    private func writeEndOfMessageSymbol() {
        outputStream.write(string: endOfMessageSymbol)
    }
}

extension FileRecorder: StreamDelegate {
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        switch eventCode {
        case .openCompleted:
            writeStartOfMessageSymbol()
        default:
            break
        }
    }
}
