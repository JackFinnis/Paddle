//
//  Haptics.swift
//  Paddle
//
//  Created by Jack Finnis on 12/09/2022.
//

import UIKit

struct Haptics {
    static let generator = UINotificationFeedbackGenerator()
    
    static func success() {
        generator.notificationOccurred(.success)
    }
    
    static func error() {
        generator.notificationOccurred(.error)
    }
}
