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
    @Published var showFeatureView = false { didSet {
        if showFeatureView {
            isSearching = false
        } else {
            selectedFeature = nil
        }
    }}
    
    var canals = [Canal]()
    @Published var selectedCanalName: String?
    var selectedCanals: [Canal] {
        guard let name = selectedCanalName else { return [] }
        return canals.filter { $0.name == name }
    }
    
    // Search Bar
    var searchBar: UISearchBar?
    var search: MKLocalSearch?
    var searchResults = [MKPointAnnotation]()
    @Published var noResults = false
    @Published var isSearching = false { didSet {
        resetSearch()
    }}
    
    // Map View
    var zoomedIn = false
    var coord = CLLocationCoordinate2D()
    var mapView: MKMapView?
    @Published var userTrackingMode = MKUserTrackingMode.none
    @Published var mapType = MKMapType.standard
    
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
            canal.distance = data.dist
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
        
        features = (try? container.viewContext.fetch(Feature.fetchRequest()) as? [Feature]) ?? []
        
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
        for annotation in mapView?.selectedAnnotations ?? [] {
            mapView?.deselectAnnotation(annotation, animated: true)
        }
        
        let rect = MKMultiPolyline(selectedCanals).boundingMapRect
        let padding = UIEdgeInsets(top: 20, left: 20, bottom: 80, right: 20)
        mapView?.setVisibleMapRect(rect, edgePadding: padding, animated: true)
    }
}

extension ViewModel: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let canal = overlay as? Canal {
            let renderer = MKPolylineRenderer(polyline: canal)
            renderer.lineWidth = 3
            renderer.strokeColor = UIColor(.orange)
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
        } else if let searchResult = annotation as? MKPointAnnotation {
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: MKMarkerAnnotationView.id, for: searchResult)
            view.clusteringIdentifier = MKMarkerAnnotationView.id
            return view
        }
        return nil
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let coord = view.annotation?.coordinate else { return }
        
        if view.annotation is MKUserLocation {
            mapView.deselectAnnotation(view.annotation, animated: false)
            self.coord = coord
            showFeatureView = true
        }
    }
    
    func setRegion(center: CLLocationCoordinate2D, delta: CLLocationDegrees, animated: Bool) {
        let span = MKCoordinateSpan(latitudeDelta: delta, longitudeDelta: delta)
        let region = MKCoordinateRegion(center: center, span: span)
        mapView?.setRegion(region, animated: animated)
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
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if let feature = view.annotation as? Feature {
            if control == view.leftCalloutAccessoryView {
                selectedFeature = feature
                showFeatureView = true
            } else {
                openInMaps(name: feature.title ?? feature.name, coord: feature.coordinate)
            }
        }
    }
    
    func openInMaps(name: String, coord: CLLocationCoordinate2D) {
        CLGeocoder().reverseGeocodeLocation(coord.getLocation()) { placemarks, error in
            if let placemark = placemarks?.first {
                let mapItem = MKMapItem(placemark: MKPlacemark(placemark: placemark))
                mapItem.name = name
                mapItem.openInMaps()
            }
        }
    }
    
    @objc
    func handleLongPress(_ tap: UITapGestureRecognizer) {
        guard let mapView = mapView else { return }
        let pressPoint = tap.location(in: mapView)
        coord = mapView.convert(pressPoint, toCoordinateFrom: mapView)
        showFeatureView = true
    }
    
    @objc
    func handleTap(_ tap: UITapGestureRecognizer) {
        guard let mapView = mapView else { return }
        let tapPoint = tap.location(in: mapView)
        let tapCoord = mapView.convert(tapPoint, toCoordinateFrom: mapView)
        selectClosestCanal(to: tapCoord)
    }
    
    func selectClosestCanal(to targetCoord: CLLocationCoordinate2D) {
        var shortestDistance = Double.infinity
        var closestCanal: Canal?
        
        for canal in canals {
            // Only check every 5 coords
            let filteredCoords = canal.coordinates.enumerated().compactMap { index, element in
                index % 5 == 0 ? element : nil
            }
            
            for coord in filteredCoords {
                let delta = targetCoord.distance(to: coord)
                
                if delta < shortestDistance && delta < 1000 {
                    shortestDistance = delta
                    closestCanal = canal
                }
            }
        }
        
        selectedCanalName = closestCanal?.name
    }
}

extension ViewModel: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchBar.text, text.isNotEmpty else { return }
        search(text: text) { success in
            if success {
                searchBar.resignFirstResponder()
            } else {
                Haptics.error()
                self.noResults = true
            }
        }
    }
    
    func resetSearch() {
        selectedCanalName = nil
        mapView?.removeAnnotations(searchResults)
        searchResults = []
    }
    
    // Return whether a result is found
    func search(text: String, completion: @escaping (Bool) -> Void) {
        resetSearch()
        
        // Search canals
        for canal in canals where canal.name.localizedCaseInsensitiveContains(text) {
            selectedCanalName = canal.name
            setSelectedRegion()
            completion(true)
            return
        }
        
        // Search features
        for feature in features where feature.name.localizedCaseInsensitiveContains(text) {
            selectClosestCanal(to: feature.coordinate)
            
            selectedFeature = feature
            setRegion(center: feature.coordinate, delta: 0.05, animated: false)
            mapView?.selectAnnotation(feature, animated: true)
            completion(true)
            return
        }
        
        // Search locations
        mapSearch(text: text, completion: completion)
    }
    
    func mapSearch(text: String, completion: @escaping (Bool) -> Void) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = text
        // Set request region to the UK
        let centre = CLLocationCoordinate2D(latitude: 54.093409, longitude: -2.89479)
        let span = MKCoordinateSpan(latitudeDelta: 14.83, longitudeDelta: 12.22)
        let region = MKCoordinateRegion(center: centre, span: span)
        request.region = region
        
        search?.cancel()
        search = MKLocalSearch(request: request)
        search?.start { response, error in
            guard let response = response else { completion(false); return }
            self.searchResults = response.mapItems.map { item -> MKPointAnnotation in
                let annotation = MKPointAnnotation()
                annotation.coordinate = item.placemark.coordinate
                annotation.title = item.name
                annotation.subtitle = item.placemark.title
                return annotation
            }
            DispatchQueue.main.async {
                self.mapView?.addAnnotations(self.searchResults)
                self.mapView?.setRegion(response.boundingRegion, animated: true)
                completion(true)
            }
        }
    }
}
