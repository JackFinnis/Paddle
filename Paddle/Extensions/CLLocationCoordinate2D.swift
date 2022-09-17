//
//  CLLocationCoordinate2D.swift
//  Paddle
//
//  Created by Jack Finnis on 11/09/2022.
//

import Foundation
import MapKit

extension CLLocationCoordinate2D: Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
    
    func distance(to nextCoord: CLLocationCoordinate2D) -> Double {
        getLocation().distance(from: nextCoord.getLocation())
    }
    
    func getLocation() -> CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }
}
