import Foundation
import MapboxVisionNative

typealias TelemetryFileMetadata = [String: String]

final class Platform: NSObject {
    struct Dependencies {
        let recorder: VideoRecorder?
        let eventsManager: EventsManager
        let archiver: Archiver?
    }

    private let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }
}

extension Platform: PlatformInterface {
    func setSyncUrl(_ url: String) {
        dependencies.eventsManager.set(baseURL: URL(string: url))
    }

    func sendTelemetry(name: String, entries: [TelemetryEntry]) {
        let entries = Dictionary(entries.map { ($0.key, $0.value) }) { first, _ in
            assertionFailure("Duplicated key in telemetry entries.")
            return first
        }

        dependencies.eventsManager.sendEvent(name: name, entries: entries)
    }

    func sendTelemetryFile(path: String, metadata: TelemetryFileMetadata, callback: @escaping SuccessCallback) {
        dependencies.eventsManager.upload(file: path, metadata: metadata) { error in callback(error == nil) }
    }

    func startVideoRecording(filePath: String) {
        dependencies.recorder?.startRecording(to: filePath, settings: .lowQuality)
    }

    func stopVideoRecording() {
        dependencies.recorder?.stopRecording(completion: nil)
    }

    func makeVideoClips(inputFilePath: String, outputDirectoryPath: String, clips: [VideoClip], callback: @escaping SuccessCallback) {}

    func archiveFiles(filePaths: [String], archivePath: String, callback: @escaping SuccessCallback) {
        DispatchQueue.global(qos: .utility).async {
            do {
                try self.dependencies.archiver?.archive(filePaths.map(URL.init(fileURLWithPath:)),
                                                   destination: URL(fileURLWithPath: archivePath))
            } catch {
                assertionFailure("ERROR: archiving failed with error: \(error.localizedDescription)")
                callback(false)
                return
            }

            callback(true)
        }
    }
}
