//
//  AlertPlayer.swift
//  cv-assist-ios
//
//  Created by Alexander Pristavko on 4/2/18.
//  Copyright © 2018 Mapbox. All rights reserved.
//

import Foundation
import AVFoundation

enum AlertSound {
    private static let type = "wav"
    
    case criticalCollisionAlert
    
    private var path: String {
        switch self {
        case .criticalCollisionAlert:
            return "critical_collision_alert"
        }
    }
    
    private var url: URL? {
        guard let url = Bundle.main.url(forResource: path, withExtension: AlertSound.type) else {
            assertionFailure("Alert for name \(path).\(AlertSound.type) is not found")
            return nil
        }
        return url
    }
    
    var soundID: SystemSoundID? {
        guard let url = url else { return nil }
        var soundID: SystemSoundID = 0
        AudioServicesCreateSystemSoundID(url as CFURL, &soundID)
        return soundID
    }
}

final class AlertPlayer {
    private var isPlaying = false
    
    func play(_ sound: AlertSound) {
        guard !isPlaying, let soundID = sound.soundID else { return }
        
        isPlaying = true
        AudioServicesPlaySystemSoundWithCompletion(soundID) { [weak self] in
            self?.isPlaying = false
            AudioServicesDisposeSystemSoundID(soundID)
        }
    }
}
