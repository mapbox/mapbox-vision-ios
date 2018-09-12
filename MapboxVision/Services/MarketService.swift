//
//  MarketService.swift
//  cv-assist-ios
//
//  Created by Alexander Pristavko on 4/19/18.
//  Copyright © 2018 Mapbox. All rights reserved.
//

import Foundation
import VisionCore

protocol MarketService {
    typealias UpdateHandler = (Market) -> Void
    typealias Disposable = Int
    
    var currentMarket: Market { get }
    
    func subscribe(handler: @escaping UpdateHandler) -> Disposable
    func unsubscribe(_ disposable: Disposable)
}

final class MarketProvider: NSObject, MarketService {
    
    private(set) var currentMarket: Market = .us {
        didSet {
            guard currentMarket == oldValue else { return }
            handlers.values.forEach { $0(currentMarket) }
        }
    }
    private var observer: NSKeyValueObservation?
    private var handlers: [Disposable : UpdateHandler] = [:]
    private var handlersCount = 0
    
    override init() {
        super.init()
        let defaults = UserDefaults.standard
        observer = defaults.observe(\.chinaMarket, options: [.initial, .new]) { [weak self] (defaults, change) in
            guard let isChina = change.newValue else { return }
            self?.currentMarket = isChina ? .china : .us
        }
    }
    
    func subscribe(handler: @escaping MarketService.UpdateHandler) -> Disposable {
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
    @objc dynamic var chinaMarket: Bool {
        return bool(forKey: VisionSettings.chinaMarket)
    }
}
