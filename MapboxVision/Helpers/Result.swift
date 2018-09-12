//
//  Result.swift
//  cv-assist-ios
//
//  Created by Alexander Pristavko on 1/18/18.
//  Copyright © 2018 Mapbox. All rights reserved.
//

import Foundation

enum Result<T, E> {
    case value(T)
    case error(E)
}
