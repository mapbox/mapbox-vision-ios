import Foundation
import MapboxVisionNative

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
    func sendTelemetry(name: String, entries: [TelemetryEntry]) {
        let entries = Dictionary(entries.map { ($0.key, $0.value) }) { first, _ in
            assertionFailure("Duplicated key in telemetry entries.")
            return first
        }

        dependencies.eventsManager.sendEvent(name: name, entries: entries)
    }

    func sendTelemetryFile(path: String, callback: @escaping SuccessCallback) {
        dependencies.eventsManager.upload(file: URL(fileURLWithPath: path),
                                          toFolder: "") { error in callback(error == nil) }
    }

    func startVideoRecording(filePath: String) {
        dependencies.recorder?.startRecording(to: filePath, settings: .lowQuality)
    }

    func stopVideoRecording() {
        dependencies.recorder?.stopRecording(completion: nil)
    }

    func makeVideoClips(inputFilePath: String, outputDirectoryPath: String, clips: [VideoClip], callback: @escaping SuccessCallback) {}

    func archiveFiles(filePaths: [String], archivePath: String, callback: @escaping SuccessCallback) {
        do {
            try dependencies.archiver?.archive(filePaths.map(URL.init(fileURLWithPath:)),
                                               destination: URL(fileURLWithPath: archivePath))
        } catch {
            assertionFailure("ERROR: archiving failed with error: \(error.localizedDescription)")
            callback(false)
            return
        }

        callback(true)
    }
}
