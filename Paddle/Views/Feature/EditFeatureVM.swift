//
//  FeatureVM.swift
//  Rivers
//
//  Created by Jack Finnis on 31/05/2022.
//

import Foundation
import CoreLocation
import MapKit

class EditFeatureVM: NSObject, ObservableObject {
    @Published var type: FeatureType
    @Published var name: String
    @Published var angle: Double
    var coord: CLLocationCoordinate2D
    
    let feature: Feature?
    
    init(feature: Feature?, coordinate: CLLocationCoordinate2D) {
        coord = coordinate
        type = feature?.type ?? .lock
        name = feature?.name ?? ""
        angle = feature?.angle ?? 0
        self.feature = feature
    }
}

// MARK: - MKMapView Delegate
extension EditFeatureVM: MKMapViewDelegate {
    func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
        coord = mapView.region.center
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        mapView.deselectAnnotation(view.annotation, animated: false)
    }
}
