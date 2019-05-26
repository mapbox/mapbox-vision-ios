struct LabelViewModel {
    let frame: CGRect// = CGRect.zero
    let text: String// = ""
    let textFont: UIFont// = UIFont(name: "AvenirNextCondensed-Bold", size: 11)!
    let textAlignment: NSTextAlignment// = .center
    let backgroundColor: UIColor// = UIColor.black.withAlphaComponent(0.53)
    let textColor: UIColor// = UIColor(red: 144.0/255.0, green: 255.0/255.0, blue: 22.0/255.0, alpha: 1.0)
}

struct BoundingBoxViewModel {
    let frame: CGRect //= CGRect.zero
    let borderWidth: CGFloat //= 3.0
    let backgroundColor: UIColor //= .clear
    let borderColor: CGColor //= UIColor(red: 144.0/255.0, green: 255.0/255.0, blue: 22.0/255.0, alpha: 1.0).cgColor
}

struct DetectionViewModel {
    let label: LabelViewModel
    let boundingBox: BoundingBoxViewModel
}
