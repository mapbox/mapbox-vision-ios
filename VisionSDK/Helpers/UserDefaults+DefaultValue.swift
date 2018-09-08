//
//  UserDefaults+DefaultValue.swift
//  cv-assist-ios
//
//  Created by Alexander Pristavko on 4/24/18.
//  Copyright © 2018 Mapbox. All rights reserved.
//

import Foundation

extension UserDefaults {
    func setDefaultValue(_ value: Any?, forKey: String) {
        if object(forKey: forKey) == nil {
            setValue(value, forKey: forKey)
        }
    }
}
