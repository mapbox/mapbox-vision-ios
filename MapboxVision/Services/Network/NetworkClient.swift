//
//  Created by Alexander Pristavko on 1/21/18.
//  Copyright © 2018 Mapbox. All rights reserved.
//

import Foundation

protocol NetworkClient {

    func upload(file: URL, toFolder folderName: String, completion: @escaping (Error?) -> Void)
    func cancel()
}
