extension DetectionClass {

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
