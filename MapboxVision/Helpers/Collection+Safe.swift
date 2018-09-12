//
//  Collection+Safe.swift
//  cv-assist-ios
//
//  Created by Alexander Pristavko on 5/14/18.
//  Copyright © 2018 Mapbox. All rights reserved.
//

import Foundation

extension Collection {
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
