//
//  Double.swift
//  Paddle
//
//  Created by Jack Finnis on 25/09/2022.
//

import Foundation

extension Double {
    func formattedInterval() -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .short
        return formatter.string(from: self) ?? ""
    }
}
