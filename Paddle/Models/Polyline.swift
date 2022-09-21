//
//  Polyline.swift
//  Paddle
//
//  Created by Jack Finnis on 21/09/2022.
//

import Foundation
import CoreData
import MapKit

@objc(Polyline)
class Polyline: NSManagedObject {
    @NSManaged var canalId: String
    @NSManaged var coords: [[Double]]
    @NSManaged var type: PolylineType
    
    var mkPolyline: MKPolyline {
        let coordinates = coords.map { CLLocationCoordinate2DMake($0[0], $0[1]) }
        return MKPolyline(coordinates: coordinates, count: coordinates.count)
    }
}

extension Polyline: MKOverlay {
    var coordinate: CLLocationCoordinate2D {
        mkPolyline.coordinates.first ?? CLLocationCoordinate2D()
    }
    var boundingMapRect: MKMapRect {
        mkPolyline.boundingMapRect
    }
}

@objc
enum PolylineType: Int16 {
    case completed
}
