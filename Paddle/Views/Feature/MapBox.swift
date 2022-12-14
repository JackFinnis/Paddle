//
//  MapBox.swift
//  MyMap
//
//  Created by Finnis on 14/02/2021.
//

import SwiftUI
import MapKit

struct MapBox: UIViewRepresentable {
    @ObservedObject var editFeatureVM: EditFeatureVM
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = editFeatureVM
        
        let spanDelta = 0.00054
        let span = MKCoordinateSpan(latitudeDelta: spanDelta, longitudeDelta: spanDelta)
        let region = MKCoordinateRegion(center: editFeatureVM.coord, span: span)
        mapView.region = region
        
        mapView.mapType = .hybrid
        mapView.showsUserLocation = true
        mapView.showsScale = false
        mapView.isRotateEnabled = false
        mapView.isPitchEnabled = false
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {}
}
