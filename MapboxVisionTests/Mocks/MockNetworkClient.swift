//
//  Created by Maksim on 10/2/18.
//  Copyright © 2018 Mapbox. All rights reserved.
//

import Foundation
@testable import MapboxVision

final class MockNetworkClient: NetworkClient {
    
    var error: Error? = nil
    var uploaded: [URL: String] = [:]
    
    func upload(file: URL, toFolder folderName: String, completion: @escaping (Error?) -> Void) {
        uploaded[file] = folderName
        completion(error)
    }
    
    func cancel() { }
}
