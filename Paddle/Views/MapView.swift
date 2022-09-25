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
        
        mapView.register(FeatureView.self, forAnnotationViewWithReuseIdentifier: FeatureView.id)
        mapView.register(MKPinAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKPinAnnotationView.id)
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMarkerAnnotationView.id)
        
        let tapRecognizer = UITapGestureRecognizer(target: vm, action: #selector(ViewModel.handleTap))
        let longPressRecognizer = UILongPressGestureRecognizer(target: vm, action: #selector(ViewModel.handleLongPress))
        mapView.addGestureRecognizer(tapRecognizer)
        mapView.addGestureRecognizer(longPressRecognizer)
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        UIView.animate(withDuration: 0.35) {
            var top = CGFloat.zero
            if self.vm.selectedCanalId != nil {
                top += 50
            }
            if self.vm.isPaddling {
                top += 60
            }
            let padding = UIEdgeInsets(top: top, left: 0, bottom: 0, right: 0)
            mapView.layoutMargins = padding
        }
    }
}
