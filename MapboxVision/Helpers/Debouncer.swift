//
//  Debouncer.swift
//  cv-assist-ios
//
//  Created by Alexander Pristavko on 4/23/18.
//  Copyright © 2018 Mapbox. All rights reserved.
//

import Foundation

final class Debouncer {
    private var workItem = DispatchWorkItem {}
    private let queue: DispatchQueue
    private let delay: TimeInterval
    
    init(delay: TimeInterval, queue: DispatchQueue = DispatchQueue.main) {
        self.delay = delay
        self.queue = queue
    }
    
    func debounce(_ closure: @escaping () -> Void) {
        workItem.cancel()
        workItem = DispatchWorkItem(block: closure)
        queue.asyncAfter(deadline: .now() + delay, execute: workItem)
    }
}
