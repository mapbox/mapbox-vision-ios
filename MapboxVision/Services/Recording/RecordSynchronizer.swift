//
//  RecordProvider.swift
//  cv-assist-ios
//
//  Created by Alexander Pristavko on 1/22/18.
//  Copyright © 2018 Mapbox. All rights reserved.
//

import Foundation

protocol SyncDelegate: class {
    func syncStarted()
    func syncStopped()
}

private let memoryLimit = 300.0 // mb
private let networkingMemoryLimit: Int64 = 30 * 1024 * 1024
private let updatingInterval: TimeInterval = 60 * 60

final class RecordSynchronizer {
    
    enum RecordSynchronizerError: LocalizedError {
        case syncFileCreationFail(URL)
        case noRequestedFiles([RecordFileType], URL)
    }
    
    struct Dependencies {
        let networkClient: NetworkClient
        let dataSource: RecordDataSource
        let deviceId: String
        let devicePlatformName: String
        let archiver: Archiver
        let fileManager: FileManagerProtocol
    }
    
    weak var delegate: SyncDelegate?
    
    private let dependencies: Dependencies
    private let queue = DispatchQueue(label: "com.mapbox.RecordSynchronizer")
    private let syncFileName = ".synced"
    private let telemetryFileName = "telemetry"
    private let quota = RecordingQuota(memoryLimit: networkingMemoryLimit, updatingInterval: updatingInterval)
    
    init(_ dependencies: Dependencies) {
        self.dependencies = dependencies
    }
    
    func sync() {
        DispatchQueue.global().async { [weak self] in
            self?.clean()
            DispatchQueue.main.async { self?.delegate?.syncStarted() }
            self?.uploadTelemetry {
                self?.uploadVideos {
                    DispatchQueue.main.async { self?.delegate?.syncStopped() }
                }
            }
        }
    }
    
    private func isMarkAsSynced(url: URL) -> Bool {
        guard let content = try? dependencies.fileManager.contentsOfDirectory(atPath: url.path) else {
            return false
        }
        return content.contains(syncFileName)
    }
    
    private func getFiles(_ url: URL, types: [RecordFileType]) throws -> [URL] {
        let extensions = types.map { $0.fileExtension }
        let files = try dependencies.fileManager.contentsOfDirectory(at: url)
            .filter { extensions.contains($0.pathExtension) }
        guard !files.isEmpty else { throw RecordSynchronizerError.noRequestedFiles(types, url) }
        
        return files
    }
    
    private func uploadTelemetry(completion: @escaping () -> Void) {
        let group = DispatchGroup()

        for dir in dependencies.dataSource.recordDirectories {
            group.enter()
            
            let destination = dir.appendingPathComponent(telemetryFileName).appendingPathExtension(RecordFileType.archive.fileExtension)
            
            do {
                if !dependencies.fileManager.fileExists(atPath: destination.path) {
                    let files = try getFiles(dir, types: [.bin, .json])
                    try dependencies.archiver.archive(files, destination: destination)
                    files.forEach(dependencies.dataSource.removeFile)
                }
                
                try self.quota.reserve(memory: dependencies.fileManager.fileSize(at: destination))
            } catch {
                print(error)
                group.leave()
                continue
            }
            
            let remoteDir = createRemoteDirName(dir)
            
            dependencies.networkClient.upload(file: destination, toFolder: remoteDir) { [weak self] error in
                if let error = error {
                    print(error)
                    group.leave()
                } else {
                    self?.dependencies.dataSource.removeFile(at: destination)
                    self?.markAsSynced(dir: dir, remoteDir: remoteDir) { error in
                        if let error = error {
                            print(error)
                        }
                        group.leave()
                    }
                }
            }
        }
        
        group.notify(queue: queue, execute: completion)
    }
    
    private func uploadVideos(completion: @escaping () -> Void) {
        let group = DispatchGroup()

        let fileSize = dependencies.fileManager.fileSize
        let sorted = dependencies.dataSource.recordDirectories
            .flatMap { (try? self.getFiles($0, types: [.video])) ?? [] }
            .sorted { fileSize($0) < fileSize($1) }
            
            
        for file in sorted {
            group.enter()
            
            do {
                try quota.reserve(memory: fileSize(file))
            } catch {
                print(error)
                group.leave()
                continue
            }
            
            let remoteDir = createRemoteDirName(file.deletingLastPathComponent())
            
            dependencies.networkClient.upload(file: file, toFolder: remoteDir) { [weak self] error in
                if let error = error {
                    print(error)
                } else {
                    self?.dependencies.dataSource.removeFile(at: file)
                }
                group.leave()
            }
        }
        
        group.notify(queue: queue, execute: completion)
    }
    
    private func clean() {
        dependencies.dataSource.recordDirectories
            .sortedByCreationDate
            .filter(isMarkAsSynced)
            .reduce((Array<URL>(), 0.0)) { base, url in
                let dirSize = Double(dependencies.fileManager.sizeOfDirectory(at: url)) / 1024.0 / 1024.0

                let size = base.1 + dirSize
                if size > memoryLimit || dirSize == 0 {
                    return (base.0 + [url], size)
                } else {
                    return (base.0, size)
                }
            }.0
            .forEach(dependencies.dataSource.removeFile)
    }
    
    private func markAsSynced(dir: URL, remoteDir: String, completion: @escaping (Error?) -> Void) {
        guard let _ = createSyncFile(in: dir) else {
            completion(RecordSynchronizerError.syncFileCreationFail(dir))
            return
        }
        completion(nil)
    }
    
    private func createRemoteDirName(_ dir: URL) -> String {
        return Path([
            dir.lastPathComponent,
            Locale.current.identifier,
            dependencies.deviceId,
            dependencies.devicePlatformName
        ]).components.joined(separator: "_")
    }
    
    private func createSyncFile(in url: URL) -> URL? {
        let syncFilePath = url.appendingPathComponent(syncFileName).path
        guard dependencies.fileManager.createFile(atPath: syncFilePath, contents: nil) else {
            return nil
        }
        return URL(fileURLWithPath: syncFilePath, relativeTo: url)
    }
    
    func stopSync() {
        dependencies.networkClient.cancel()
    }
}
