//
//  DetectionsView.swift
//  cv-assist-ios
//
//  Created by Maksim on 5/22/18.
//  Copyright © 2018 Mapbox. All rights reserved.
//

import Foundation
import MapboxVisionNative

struct BasicDetection {
    let boundingBox: CGRect
    let objectType: DetectionClass
}

final class DetectionsView: UIImageView {
    
    private static let labelHeight = CGFloat(18)
    private static let labelSidePadding = CGFloat(5)
    
    func present(detections: [BasicDetection], at image: UIImage) {
        
        self.subviews.forEach { $0.removeFromSuperview() }
        
        self.image = image
        self.contentMode = .scaleAspectFill
        
        detections.forEach {
            let view = UIView(frame: $0.boundingBox)
            view.backgroundColor = .clear
            view.layer.borderWidth = 3
            
            let color = $0.objectType.color
            
            let title = $0.objectType.title.uppercased() as NSString
            let font = UIFont(name: "AvenirNextCondensed-Bold", size: 11)!
            let size: CGSize = title.size(withAttributes: [NSAttributedString.Key.font: font])
            let label = UILabel(frame: CGRect(
                x: view.frame.origin.x,
                y: view.frame.origin.y - DetectionsView.labelHeight,
                width: size.width + DetectionsView.labelSidePadding * 2,
                height: DetectionsView.labelHeight
            ))
            label.text = title as String
            label.font = font
            label.textAlignment = .center
            label.textColor = color
            label.backgroundColor = UIColor.black.withAlphaComponent(0.53)
            self.addSubview(label)
            
            self.layer.masksToBounds = false
    
            view.layer.borderColor = color.cgColor
            self.addSubview(view)
        }
        
        self.setNeedsDisplay()
    }
}

private extension DetectionClass {
    
    var color: UIColor {
        switch self {
        case .trafficLight:
            return UIColor(red: 6.0/255.0, green: 241.0/255.0, blue: 255.0/255.0, alpha: 1.0)
        case .trafficSign:
            return UIColor(red: 255.0/255.0, green: 204.0/255.0, blue: 22.0/255.0, alpha: 1.0)
        case .car:
            return UIColor(red: 144.0/255.0, green: 255.0/255.0, blue: 22.0/255.0, alpha: 1.0)
        case .person:
            return UIColor(red: 239.0/255.0, green: 6.0/255.0, blue: 255.0/255.0, alpha: 1.0)
        case .bicycle:
            return UIColor(red: 0, green: 165.0/255.0, blue: 1.0, alpha: 1.0)
        }
    }
    
    var title: String {
        switch self {
        case .trafficLight:
            return "Lights"
        case .trafficSign:
            return "Sign"
        case .car:
            return "Car"
        case .person:
            return "Person"
        case .bicycle:
            return "Bicycle"
        }
    }
}
