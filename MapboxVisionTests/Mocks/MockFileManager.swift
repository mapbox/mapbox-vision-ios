//
//  MockFileManager.swift
//  MapboxVisionTests
//
//  Created by Maksim on 10/2/18.
//  Copyright © 2018 Mapbox. All rights reserved.
//

import Foundation
@testable import MapboxVision

final class MockFileManager: FileManagerProtocol {
    
    struct File {
        let url: URL
        let size: Int64
    }
    
    var data: [URL: [File]] = [:]
    
    func contentsOfDirectory(atPath path: String) throws -> [String] {
        return try contentsOfDirectory(at: URL(fileURLWithPath: path, isDirectory: true)).map { $0.lastPathComponent }
    }
    
    func contentsOfDirectory(at url: URL) throws -> [URL] {
        return data[url]?.map { $0.url } ?? []
    }
    
    func fileExists(atPath path: String) -> Bool {
        let url = URL(fileURLWithPath: path)
        return data.values.flatMap { $0 }.map { $0.url }.filter { $0 == url }.first != nil
    }
    
    func createFile(atPath path: String, contents: Data?) -> Bool {
        let fileUrl = URL(fileURLWithPath: path)
        let file = File(url: fileUrl, size: fileSize(at: fileUrl))
        let dirUrl = fileUrl.deletingLastPathComponent()
        data[dirUrl]?.append(file)
        return true
    }
    
    func fileSize(at url: URL) -> Int64 {
        let dirUrl = url.deletingLastPathComponent()
        return data[dirUrl]?.filter { $0.url == url }.map { $0.size }.first ?? 0
    }
}
