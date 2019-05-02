//
//  Created by Alexander Pristavko on 3/22/18.
//  Copyright © 2018 Mapbox. All rights reserved.
//

import Foundation
import MapboxCoreNavigation
import MapboxVision
import MapboxVisionARNative

/// :nodoc:
public protocol NavigationManagerDelegate: class {
    func navigationManager(_ navigationManager: NavigationManager, didUpdate route: Route)
    func navigationManagerArrivedAtDestination(_ navigationManager: NavigationManager)
}

/// :nodoc:
public final class NavigationManager {
    weak var delegate: NavigationManagerDelegate? {
        didSet {
            delegate?.navigationManager(self, didUpdate: Route(route: navigationService.routeProgress.route))
        }
    }
    
    private let navigationService: NavigationService
    private var routeHasChanged = true
    
    init(navigationService: NavigationService) {
        self.navigationService = navigationService
        
        NotificationCenter.default.addObserver(self, selector: #selector(progressDidChange), name: .routeControllerProgressDidChange, object: navigationService.router)
        NotificationCenter.default.addObserver(self, selector: #selector(didReroute), name: .routeControllerDidReroute, object: navigationService.router)
    }
    
    @objc private func progressDidChange(_ notification: NSNotification) {
        guard let routeProgress = notification.userInfo?[RouteControllerNotificationUserInfoKey.routeProgressKey] as? RouteProgress else { return }
        
        if routeHasChanged {
            routeHasChanged = false
            delegate?.navigationManager(self, didUpdate: Route(route: routeProgress.route))
        }
        
        if routeProgress.currentLegProgress.userHasArrivedAtWaypoint {
            routeHasChanged = true
            delegate?.navigationManagerArrivedAtDestination(self)
        }
    }
    
    @objc private func didReroute(_ notification: NSNotification) {
        routeHasChanged = true
    }
}
