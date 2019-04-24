import Foundation
import CoreLocation

final class LocationManager: NSObject, CLLocationManagerDelegate {

    var locationHandler: ((CLLocation) -> Void)?
    var headingHandler: ((CLHeading) -> Void)?

    private let locationManager = CLLocationManager()
    private var isReady = false
    private var isStarted = false

    override init() {
        super.init()

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation

        switch CLLocationManager.authorizationStatus() {
        case .notDetermined:
            locationManager.requestAlwaysAuthorization()
        case .restricted, .denied:
            isReady = false
        case .authorizedAlways, .authorizedWhenInUse:
            isReady = true
        }

        NotificationCenter.default.addObserver(self, selector: #selector(updateOrientation), name: UIDevice.orientationDidChangeNotification, object: nil)
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined, .restricted, .denied:
            isReady = false
        case .authorizedWhenInUse, .authorizedAlways:
            let oldReady = isReady
            isReady = true
            if isStarted, !oldReady {
                start()
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let handler = locationHandler else { return }
        locations.forEach(handler)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        headingHandler?(newHeading)
    }

    func start() {
        isStarted = true
        guard isReady else { return }
        self.locationManager.startUpdatingLocation()
        self.locationManager.startUpdatingHeading()
    }

    func stop() {
        isStarted = false
        self.locationManager.stopUpdatingLocation()
        self.locationManager.stopUpdatingHeading()
    }

    @objc private func updateOrientation() {
        locationManager.headingOrientation = UIDevice.current.orientation.clDeviceOrientation
    }
}

fileprivate extension UIDeviceOrientation {
    var clDeviceOrientation: CLDeviceOrientation {
        switch self {
        case .unknown:            return .unknown
        case .portrait:           return .portrait
        case .portraitUpsideDown: return .portraitUpsideDown
        case .landscapeLeft:      return .landscapeLeft
        case .landscapeRight:     return .landscapeRight
        case .faceUp:             return .faceUp
        case .faceDown:           return .faceDown
        }
    }
}
