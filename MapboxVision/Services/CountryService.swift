//
//  CountryService.swift
//  cv-assist-ios
//
//  Created by Alexander Pristavko on 4/19/18.
//  Copyright © 2018 Mapbox. All rights reserved.
//

import Foundation
import MapboxVisionCore

protocol CountryService {
    typealias UpdateHandler = (Country) -> Void
    typealias Disposable = Int
    
    var currentCountry: Country { get }
    
    func subscribe(handler: @escaping UpdateHandler) -> Disposable
    func unsubscribe(_ disposable: Disposable)
}

final class CountryProvider: NSObject, CountryService {
    
    private(set) var currentCountry: Country = .USA {
        didSet {
            guard currentCountry == oldValue else { return }
            handlers.values.forEach { $0(currentCountry) }
        }
    }
    private var observer: NSKeyValueObservation?
    private var handlers: [Disposable : UpdateHandler] = [:]
    private var handlersCount = 0
    
    override init() {
        super.init()
        let defaults = UserDefaults.standard
        observer = defaults.observe(\.isChina, options: [.initial, .new]) { [weak self] (defaults, change) in
            guard let isChina = change.newValue else { return }
            self?.currentCountry = isChina ? .china : .USA
        }
    }
    
    func subscribe(handler: @escaping CountryService.UpdateHandler) -> Disposable {
        handlers[handlersCount] = handler
        let disposable = handlersCount
        handlersCount += 1
        return disposable
    }
    
    func unsubscribe(_ disposable: Disposable) {
        let _ = handlers.removeValue(forKey: disposable)
    }
    
    deinit {
        handlers.removeAll()
        observer?.invalidate()
    }
}

private extension UserDefaults {
    @objc dynamic var isChina: Bool {
        return bool(forKey: VisionSettings.isChina)
    }
}
