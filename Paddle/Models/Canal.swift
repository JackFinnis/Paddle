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
    var name = ""
    var distance = Double.zero
}

struct CanalData: Codable {
    let name: String
    let dist: Double
    let coords: [[Double]]
}

@objc
class Polyline: NSManagedObject {
    @NSManaged var name: String
    @NSManaged var coords: [[Double]]
    @NSManaged var type: PolylineType
}

@objc
enum PolylineType: Int16 {
    case feature
}
