//
//  String.swift
//  MapboxVision
//
//  Created by Alexander Pristavko on 10/22/18.
//  Copyright © 2018 Mapbox. All rights reserved.
//

import Foundation

extension String {
    var nsString: NSString {
        return self as NSString
    }
    
    func appendingPathComponent(_ str: String, isDirectory: Bool = false) -> String {
        let string = nsString.appendingPathComponent(str)
        if isDirectory {
            return string.appending("/")
        }
        return string
    }
    
    var lastPathComponent: String {
        return nsString.lastPathComponent
    }
    
    var deletingLastPathComponent: String {
        return nsString.deletingLastPathComponent
    }
    
    var deletingPathExtension: String {
        return nsString.deletingPathExtension
    }
}
