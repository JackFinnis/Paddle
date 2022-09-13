//
//  ViewModel.swift
//  Paddle
//
//  Created by Jack Finnis on 11/09/2022.
//

import Foundation
import MapKit
import CoreData

class ViewModel: NSObject, ObservableObject {
    var features = [Feature]()
    var selectedFeature: Feature?
    @Published var showFeatureView = false
    
    var canals = [Canal]()
    @Published var selectedCanalName: String?
    var selectedCanals: [Canal] {
        guard let name = selectedCanalName else { return [] }
        return canals.filter { $0.name == name }
    }
    
    @Published var userTrackingMode = MKUserTrackingMode.none
    @Published var mapType = MKMapType.standard
    
    // MKMapViewDelegate
    var zoomedIn = false
    var coord = CLLocationCoordinate2D()
    var mapView: MKMapView?
    
    // Persistence
    let container = NSPersistentContainer(name: "Paddle")
    func save() {
        try? container.viewContext.save()
    }
    
    override init() {
        super.init()
        CLLocationManager().requestWhenInUseAuthorization()
    }
    
    func loadData() {
        loadCanals()
        container.loadPersistentStores { description, error in
            if let error = error {
                print("Core Data failed to load: ", error)
            } else {
                self.loadFeatures()
            }
        }
    }
    
    func loadCanals() {
        let url = Bundle.main.url(forResource: "Canals", withExtension: "json")!
        let data = try! Data(contentsOf: url)
        let canalsData = try! JSONDecoder().decode([CanalData].self, from: data)
        
        canals = canalsData.map { data -> Canal in
            let coordinates = data.coords.map { coord in
                CLLocationCoordinate2D(latitude: coord[0], longitude: coord[1])
            }
            let canal = Canal(coordinates: coordinates, count: coordinates.count)
            canal.name = data.name
            return canal
        }
        
        mapView?.addOverlay(MKMultiPolyline(canals))
    }
    
    func loadFeatures() {
        // Delete all features in core data
//        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Feature")
//        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
//
//        do {
//            try container.viewContext.execute(deleteRequest)
//        } catch {
//            print(error)
//        }
        
        var features = (try? container.viewContext.fetch(Feature.fetchRequest()) as? [Feature]) ?? []
        
        // If first app launch, load features from JSON to Core Data
        if features.isEmpty {
            var featuresData = [FeatureData]()
            
            for type in FeatureType.allCases {
                guard let fileName = type.fileName else { continue }
                let url = Bundle.main.url(forResource: fileName, withExtension: "json")!
                let data = try! Data(contentsOf: url)
                featuresData.append(contentsOf: try! JSONDecoder().decode([FeatureData].self, from: data))
            }
            
            for featureData in featuresData {
                let feature = Feature(context: container.viewContext)
                feature.id = featureData.id
                feature.angle = featureData.angle ?? 0
                feature.name = featureData.name
                feature.type = FeatureType(string: featureData.type) ?? .feature
                debugPrint((FeatureType(string: featureData.type) ?? .feature).rawValue)
                feature.coord = featureData.coord
                features.append(feature)
            }
            save()
        }
        
        mapView?.addAnnotations(features)
    }
    
    func setSelectedRegion() {
        mapView?.setVisibleMapRect(MKMultiPolyline(selectedCanals).boundingMapRect, edgePadding: UIEdgeInsets(top: 20, left: 20, bottom: 80, right: 20), animated: true)
    }
}

extension ViewModel: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let canal = overlay as? Canal {
            let renderer = MKPolylineRenderer(polyline: canal)
            renderer.lineWidth = 3
            renderer.strokeColor = .orange
            return renderer
        } else if let canals = overlay as? MKMultiPolyline {
            let renderer = MKMultiPolylineRenderer(multiPolyline: canals)
            renderer.lineWidth = 2
            renderer.strokeColor = UIColor(.accentColor)
            return renderer
        }
        
        return MKOverlayRenderer(overlay: overlay)
    }
    
    func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
        coord = mapView.region.center
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let feature = annotation as? Feature {
            return mapView.dequeueReusableAnnotationView(withIdentifier: AnnotationView.id, for: feature)
        }
        return nil
    }
    
    func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
        if !zoomedIn {
            zoomedIn = true
            mapView.setUserTrackingMode(.follow, animated: false)
        }
    }
    
    func mapView(_ mapView: MKMapView, didChange mode: MKUserTrackingMode, animated: Bool) {
        if !animated {
            userTrackingMode = .none
        }
    }
    
    @objc func handleTap(_ tap: UITapGestureRecognizer) {
        guard let mapView = mapView else { return }
        let tapPoint = tap.location(in: mapView)
        let tapCoord = mapView.convert(tapPoint, toCoordinateFrom: mapView)
        
        var shortestDistance = Double.infinity
        var closestCanal: Canal?
        
        for canal in canals {
            // Only check every 5 coords
            let filteredCoords = canal.coordinates.enumerated().compactMap { index, element in
                index % 5 == 0 ? element : nil
            }
            
            for coord in filteredCoords {
                let delta = tapCoord.distance(to: coord)
                
                if delta < shortestDistance && delta < 1000 {
                    shortestDistance = delta
                    closestCanal = canal
                }
            }
        }
        
        selectedCanalName = closestCanal?.name
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if let feature = view.annotation as? Feature {
            if control == view.leftCalloutAccessoryView {
                selectedFeature = feature
                showFeatureView = true
            } else {
                openInMaps(coord: feature.coordinate)
            }
        }
    }
    
    func openInMaps(coord: CLLocationCoordinate2D) {
        CLGeocoder().reverseGeocodeLocation(coord.getLocation()) { placemarks, error in
            if let placemark = placemarks?.first {
                let options: [String: Any] = [
                    MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: self.mapView?.region.span ?? MKCoordinateSpan()),
                    MKLaunchOptionsMapTypeKey: self.mapType.rawValue,
                    MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDefault
                ]
                MKMapItem(placemark: MKPlacemark(placemark: placemark)).openInMaps(launchOptions: options)
            }
        }
    }
}
