//
//  FeatureVM.swift
//  Rivers
//
//  Created by Jack Finnis on 31/05/2022.
//

import Foundation
import CoreLocation
import MapKit

class FeatureVM: NSObject, ObservableObject {
    @Published var type: FeatureType
    @Published var name: String
    @Published var angle: Double
    var coord: CLLocationCoordinate2D
    
    let feature: Feature?
    
    init(feature: Feature?, coordinate: CLLocationCoordinate2D) {
        coord = coordinate
        type = feature?.type ?? .feature
        name = feature?.name ?? ""
        angle = feature?.angle ?? 0
        self.feature = feature
    }
}

// MARK: - MKMapView Delegate
extension FeatureVM: MKMapViewDelegate {
    func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
        coord = mapView.region.center
    }
}
