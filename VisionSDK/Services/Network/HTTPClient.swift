//
//  HTTPClient.swift
//  cv-assist-ios
//
//  Created by Alexander Pristavko on 1/23/18.
//  Copyright © 2018 Mapbox. All rights reserved.
//

import Foundation

final class HTTPClient: NetworkClient {
    private static let basePath = "http://94.130.19.91:5000"
    
    private var currentTasks = Set<URLSessionTask>()
    
    func upload(config: UploadNetworkConfig, completion: @escaping (Error?) -> Void) {
        let urlString = "\(HTTPClient.basePath)\(config.path.rendered)"
        guard let url = URL(string: urlString) else {
            assertionFailure("Failed to create url at \(urlString)")
            return
        }
        
        guard let data = try? Data(contentsOf: config.fileURL) else {
            assertionFailure("data failed")
            return
        }
        
        let fileName = config.path.components.joined(separator: "_")
        
        let request = createRequest(url: url, data: data, fileName: fileName)
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let response = response {
                print(response)
            }
            if let error = error {
                print(error)
            }
            completion(error)
        }
        
        currentTasks.insert(task)
        print("Start uploading \(config)")
        task.resume()
    }
    
    func cancelAll() {
        currentTasks.forEach { $0.cancel() }
        currentTasks.removeAll()
    }
    
    private func createRequest(url: URL, data: Data, fileName: String) -> URLRequest {
        let boundary = "Boundary-\(UUID().uuidString)"
        var request  = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        let params: [String: String] = [:]
        request.httpBody = createBody(parameters: params,
                                      boundary: boundary,
                                      data: data,
                                      filename: fileName)
        
        return request
    }
    
    private func createBody(parameters: [String: String],
                    boundary: String,
                    data: Data,
                    filename: String) -> Data {
        let body = NSMutableData()
        
        let boundaryPrefix = "--\(boundary)\r\n"
        
        for (key, value) in parameters {
            body.appendString(boundaryPrefix)
            body.appendString("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
            body.appendString("\(value)\r\n")
        }
        
        body.appendString(boundaryPrefix)
        body.appendString("Content-Disposition: form-data; name=\"upload\"; filename=\"\(filename)\"\r\n")
        body.appendString("Content-Type: application/octet-stream\r\n\r\n")
        body.append(data)
        body.appendString("\r\n")
        body.appendString("--".appending(boundary.appending("--")))
        
        return body as Data
    }
}

private extension NSMutableData {
    func appendString(_ string: String) {
        let data = string.data(using: String.Encoding.utf8, allowLossyConversion: true)
        append(data!)
    }
}
