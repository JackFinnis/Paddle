//
//  MapView.swift
//  Paddle
//
//  Created by Jack Finnis on 11/09/2022.
//

import SwiftUI
import MapKit

struct MapView: UIViewRepresentable {
    @EnvironmentObject var vm: ViewModel
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = vm
        vm.mapView = mapView
        
        mapView.showsUserLocation = true
        mapView.showsScale = true
        mapView.showsCompass = true
        mapView.isPitchEnabled = false
        mapView.mapType = MKMapType(rawValue: UInt(UserDefaults.standard.integer(forKey: "mapType")))!
        
        mapView.register(AnnotationView.self, forAnnotationViewWithReuseIdentifier: AnnotationView.id)
        
        let tapRecognizer = UITapGestureRecognizer(target: vm, action: #selector(ViewModel.handleTap))
        let longPressRecognizer = UILongPressGestureRecognizer(target: vm, action: #selector(ViewModel.handleLongPress))
        mapView.addGestureRecognizer(tapRecognizer)
        mapView.addGestureRecognizer(longPressRecognizer)
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Selected canal polylines
        mapView.removeOverlays(mapView.overlays.filter { !($0 is MKMultiPolyline) })
        mapView.addOverlays(vm.selectedCanals)
    }
}
