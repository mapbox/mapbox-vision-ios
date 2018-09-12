//
//  MetaInfo.swift
//  cv-assist-ios
//
//  Created by Maksim on 1/15/18.
//  Copyright © 2018 Mapbox. All rights reserved.
//

import Foundation

struct MetaInfo: Encodable {
    let timestamp: String
    let latitude: String
    let longitude: String
    let speed: String
    let altitude: String
}

extension MetaInfo {
    static func empty(with timestamp: String) -> MetaInfo {
        return MetaInfo(
            timestamp: timestamp,
            latitude: "",
            longitude: "",
            speed: "",
            altitude: ""
        )
    }
}
