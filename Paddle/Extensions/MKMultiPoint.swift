//
//  MKMultiPoint.swift
//  Paddle
//
//  Created by Jack Finnis on 11/09/2022.
//

import Foundation
import MapKit

extension MKMultiPoint {
    var coordinates: [CLLocationCoordinate2D] {
        var coords = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid, count: pointCount)
        getCoordinates(&coords, range: NSRange(location: 0, length: pointCount))
        return coords
    }
    
    func getDistance() -> Double {
        guard coordinates.count >= 2 else { return 0 }
        var distance = Double.zero
        
        for i in 0..<coordinates.count - 1 {
            let coord = coordinates[i]
            let nextCoord = coordinates[i+1]
            distance += coord.distance(to: nextCoord)
        }
        
        return distance
    }
}
