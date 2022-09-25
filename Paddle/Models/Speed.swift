//
//  Speed.swift
//  Paddle
//
//  Created by Jack Finnis on 17/09/2022.
//

import Foundation

enum Speed: Int {
    static let sorted: [Speed] = [.average, .slow, .medium]
    
    // Default
    case medium
    case average
    
    // Other cases
    case slow
    
    var name: String {
        switch self {
        case .slow:
            return "Leisurely"
        case .medium:
            return "Brisk"
        case .average:
            return "Average"
        }
    }
    
    var speed: Double {
        switch self {
        case .slow:
            return 0.5
        case .medium:
            return 1.0
        case .average:
            let speed = UserDefaults.standard.double(forKey: "totalDistance") / UserDefaults.standard.double(forKey: "totalDuration")
            guard !speed.isNaN else { return Speed.medium.speed }
            return speed
        }
    }
    
    var image: String {
        switch self {
        case .medium:
            return "hare"
        case .slow:
            return "tortoise"
        case .average:
            return "chart.xyaxis.line"
        }
    }
}
