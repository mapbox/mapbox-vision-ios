//
//  DateFormatter.swift
//  MapboxVision
//
//  Created by Alexander Pristavko on 1/9/19.
//  Copyright © 2019 Mapbox. All rights reserved.
//

import Foundation

extension DateFormatter {
    static func createRecordingFormatter() -> DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = NSLocale.current
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ssZZZZZ"
        return dateFormatter
    }
}
