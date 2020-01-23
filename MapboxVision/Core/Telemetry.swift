import Foundation

typealias TelemetryFileMetadata = [String: String]

final class Telemetry: NSObject {
    private let networkClient: NetworkClient

    init(networkClient: NetworkClient) {
        self.networkClient = networkClient
    }
}

extension Telemetry: TelemetryInterface {
    func setSyncUrl(_ url: String) {
        networkClient.set(baseURL: URL(string: url))
    }

    func sendTelemetry(name: String, entries: [TelemetryEntry]) {
        let entries = Dictionary(entries.map { ($0.key, $0.value) }) { first, _ in
            assertionFailure("Duplicated key in telemetry entries.")
            return first
        }

        networkClient.sendEvent(name: name, entries: entries)
    }

    func sendTelemetryFile(path: String, metadata: TelemetryFileMetadata, callback: @escaping SuccessCallback) {
        networkClient.upload(file: path, metadata: metadata) { error in callback(error == nil) }
    }
}
