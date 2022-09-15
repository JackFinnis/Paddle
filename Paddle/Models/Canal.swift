//
//  Canal.swift
//  Paddle
//
//  Created by Jack Finnis on 11/09/2022.
//

import Foundation
import MapKit

class Canal: MKPolyline {
    var name = ""
    var distance = Double.zero
}

struct CanalData: Codable {
    let name: String
    let dist: Double
    let coords: [[Double]]
}
