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
            stopSearching()
            stopMeasuring()
        } else {
            selectedFeature = nil
        }
    }}
    
    var canals = [Canal]()
    var selectedCanals = [Canal]()
    @Published var selectedCanalName: String? { didSet {
        mapView?.removeOverlays(selectedCanals)
        selectedCanals = canals.filter { $0.name == selectedCanalName }
        mapView?.addOverlays(selectedCanals)
        
        UIView.animate(withDuration: 0.35) {
            let padding = UIEdgeInsets(top: self.selectedCanalName == nil ? 0 : 50, left: 0, bottom: 0, right: 0)
            self.mapView?.layoutMargins = padding
        }
    }}
    
    // Search Bar
    var searchBar: UISearchBar?
    var search: MKLocalSearch?
    var searchResults = [Annotation]()
    @Published var noResults = false
    @Published var isSearching = false
    
    // Measure distance
    @Published var annotations = [Annotation]()
    @Published var isMeasuring = false
    @Published var distance: Double?
    var polyline = MKPolyline()
    let speed = 1.5
    var time: String {
        guard let distance = distance else { return "" }
        let time = distance / speed
        
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .short
        return formatter.string(from: time) ?? ""
    }
    
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
        } else if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.lineWidth = 3
            renderer.strokeColor = UIColor(.red)
            return renderer
        }
        
        return MKOverlayRenderer(overlay: overlay)
    }
    
    func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
        coord = mapView.region.center
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let feature = annotation as? Feature {
            return mapView.dequeueReusableAnnotationView(withIdentifier: FeatureView.id, for: feature)
        } else if let annotation = annotation as? Annotation {
            if annotation.type == .search {
                let marker = mapView.dequeueReusableAnnotationView(withIdentifier: MKMarkerAnnotationView.id, for: annotation) as? MKMarkerAnnotationView
                marker?.clusteringIdentifier = MKMarkerAnnotationView.id
                marker?.animatesWhenAdded = true
                return marker
            } else if annotation.type == .measure {
                let pin = mapView.dequeueReusableAnnotationView(withIdentifier: MKPinAnnotationView.id, for: annotation) as? MKPinAnnotationView
                pin?.displayPriority = .required
                pin?.animatesDrop = true
                return pin
            }
        }
        return nil
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let user = view.annotation as? MKUserLocation {
            mapView.deselectAnnotation(user, animated: false)
            self.coord = user.coordinate
            showFeatureView = true
        } else if let cluster = view.annotation as? MKClusterAnnotation {
            zoomTo(cluster.memberAnnotations)
        }
    }
    
    func zoomTo(_ annotations: [MKAnnotation]) {
        var zoomRect: MKMapRect?
        for annotation in annotations {
            let point = MKMapPoint(annotation.coordinate)
            let rect = MKMapRect(origin: point, size: MKMapSize(width: 0.1, height: 0.1))
            if let oldZoomRect = zoomRect {
                zoomRect = oldZoomRect.union(rect)
            } else {
                zoomRect = rect
            }
        }
        if let zoomRect = zoomRect {
            let padding = UIEdgeInsets(top: 50, left: 50, bottom: 100, right: 50)
            mapView?.setVisibleMapRect(zoomRect, edgePadding: padding, animated: true)
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
        
        if isMeasuring {
            newCoord(tapCoord)
        } else {
            selectClosestCanal(to: tapCoord)
        }
    }
    
    func newCoord(_ coord: CLLocationCoordinate2D) {
        for annotation in annotations where annotation.coordinate.distance(to: coord) < 500 {
            mapView?.removeAnnotation(annotation)
            annotations.removeAll { $0.coordinate == annotation.coordinate }
            resetMeasuring()
            return
        }
        
        if annotations.count < 2 {
            let annotation = Annotation(type: .measure, title: nil, subtitle: nil, coordinate: coord)
            annotations.append(annotation)
            mapView?.addAnnotation(annotation)
            
            if annotations.count == 2 {
                calculateDistance(from: annotations[0].coordinate, to: annotations[1].coordinate)
            }
        }
    }
    
    func stopMeasuring() {
        mapView?.removeAnnotations(annotations)
        annotations = []
        isMeasuring = false
        resetMeasuring()
    }
    
    func resetMeasuring() {
        distance = nil
        mapView?.removeOverlay(polyline)
    }
    
    func calculateDistance(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) {
        guard let (startCoord, startPolyline) = getClosestCoordPolyline(to: start),
              let (endCoord, endPolyline) = getClosestCoordPolyline(to: end),
              startPolyline == endPolyline,
              let startIndex = startPolyline.coordinates.firstIndex(of: startCoord),
              let endIndex = startPolyline.coordinates.firstIndex(of: endCoord)
        else { noResults = true; return }
        
        let min = min(startIndex, endIndex)
        let max = max(startIndex, endIndex)
        let coords = Array(startPolyline.coordinates[min...max])
        
        polyline = MKPolyline(coordinates: coords, count: coords.count)
        mapView?.addOverlay(polyline)
        distance = coords.getDistance()
    }
    
    func getClosestCoordPolyline(to targetCoord: CLLocationCoordinate2D, skipEvery: Int = 1) -> (CLLocationCoordinate2D, Canal)? {
        var shortestDistance = Double.infinity
        var closestCanal: Canal?
        var closestCoord: CLLocationCoordinate2D?
        
        for canal in canals {
            // Only check every 5 coords
            let filteredCoords = canal.coordinates.enumerated().compactMap { index, element in
                index % skipEvery == 0 ? element : nil
            }
            
            for coord in filteredCoords {
                let delta = targetCoord.distance(to: coord)
                
                if delta < shortestDistance && delta < 1000 {
                    shortestDistance = delta
                    closestCoord = coord
                    closestCanal = canal
                }
            }
        }
        
        if let closestCanal = closestCanal, let closestCoord = closestCoord {
            return (closestCoord, closestCanal)
        } else {
            return nil
        }
    }
    
    func selectClosestCanal(to coord: CLLocationCoordinate2D) {
        let (_, closestCanal) = getClosestCoordPolyline(to: coord, skipEvery: 5) ?? (nil, nil)
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
                self.noResults = true
            }
        }
    }
    
    func stopSearching() {
        isSearching = false
        resetSearching()
    }
    
    func resetSearching() {
        mapView?.removeAnnotations(searchResults)
        searchResults = []
    }
    
    // Return whether a result is found
    func search(text: String, completion: @escaping (Bool) -> Void) {
        resetSearching()
        
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
        let centre = CLLocationCoordinate2D(latitude: 54.5, longitude: -3)
        let span = MKCoordinateSpan(latitudeDelta: 4.5, longitudeDelta: 5)
        let region = MKCoordinateRegion(center: centre, span: span)
        request.region = region
        
        search?.cancel()
        search = MKLocalSearch(request: request)
        search?.start { response, error in
            guard let response = response else { completion(false); return }
            let filteredResults = response.mapItems.filter { $0.placemark.countryCode == "GB" }
            guard filteredResults.isNotEmpty else { completion(false); return }
            
            self.searchResults = response.mapItems.map { item in
                Annotation(type: .search, title: item.name, subtitle: item.placemark.title, coordinate: item.placemark.coordinate)
            }
            DispatchQueue.main.async {
                self.mapView?.addAnnotations(self.searchResults)
                self.mapView?.setRegion(response.boundingRegion, animated: true)
                self.selectClosestCanal(to: response.mapItems.first?.placemark.coordinate ?? response.boundingRegion.center)
                completion(true)
            }
        }
    }
}
