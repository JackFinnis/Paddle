//
//  Canal.swift
//  Paddle
//
//  Created by Jack Finnis on 11/09/2022.
//

import Foundation
import MapKit
import CoreData

class Canal: MKPolyline {
    var id = ""
    var name = ""
    var distance = 0
}

struct CanalData: Codable {
    let id: String
    let name: String
    let dist: Int
    let coords: [[Double]]
}
