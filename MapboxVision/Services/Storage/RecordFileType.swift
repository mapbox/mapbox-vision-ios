//
// Created by Alexander Pristavko on 1/23/18.
// Copyright (c) 2018 Mapbox. All rights reserved.
//

import Foundation

enum RecordFileType: Int {
    case video
    case bin
    case json
    case archive

    var fileExtension: String {
        switch self {
        case .video:
            return "mp4"
        case .bin:
            return "bin"
        case .json:
            return "json"
        case .archive:
            return "zip"
        }
    }
}
