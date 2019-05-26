import Foundation
import MapboxVisionNative

protocol DetectionsImageViewInput {
    func display(detectionViewModels: [DetectionViewModel], with imageViewModel: ImageViewModel)
}

final class DetectionsImageView: UIImageView {
    var input: DetectionsImageViewInput!
}

extension DetectionsImageView: DetectionsImageViewInput {
    func display(detectionViewModels: [DetectionViewModel], with imageViewModel: ImageViewModel) {
        self.image = imageViewModel.image
        self.contentMode = .scaleAspectFill

        self.subviews.forEach { $0.removeFromSuperview() }
        detectionViewModels.forEach {
            let detectionView = UIView(frame: $0.boundingBox.frame)

            detectionView.backgroundColor = $0.boundingBox.backgroundColor
            detectionView.layer.borderWidth = $0.boundingBox.borderWidth
            detectionView.layer.borderColor = $0.boundingBox.borderColor

            let label = UILabel(frame: $0.label.frame)
            label.text = $0.label.text
            label.font = $0.label.textFont
            label.textAlignment = $0.label.textAlignment
            label.textColor = $0.label.textColor
            label.backgroundColor = $0.label.backgroundColor
            self.addSubview(label)

            self.layer.masksToBounds = false
            self.addSubview(detectionView)
        }

        self.setNeedsDisplay()
    }
}



final class DetectionsView: UIImageView {

    private static let labelHeight = CGFloat(18)
    private static let labelSidePadding = CGFloat(5)
    
    func present(detections: [BasicDetection], at image: UIImage) {
        self.subviews.forEach { $0.removeFromSuperview() }
        
        self.image = image
        self.contentMode = .scaleAspectFill
        
        detections.forEach {
            let view = UIView(frame: $0.boundingBox)//
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
