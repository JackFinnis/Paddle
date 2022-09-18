//
//  Speed.swift
//  Paddle
//
//  Created by Jack Finnis on 17/09/2022.
//

import Foundation

enum Speed: Int, CaseIterable {
    static let sorted: [Speed] = [.slow, .medium]
    
    case medium
    case slow
    
    var name: String {
        switch self {
        case .slow:
            return "Leisurely"
        case .medium:
            return "Brisk"
        }
    }
    
    var speed: Double {
        switch self {
        case .slow:
            return 0.5
        case .medium:
            return 1.0
        }
    }
    
    var image: String {
        switch self {
        case .medium:
            return "hare"
        case .slow:
            return "tortoise"
        }
    }
}
