//
//  ViewModel.swift
//  Paddle
//
//  Created by Jack Finnis on 11/09/2022.
//

import Foundation
import MapKit
import CoreData
import SwiftUI
import StoreKit

class ViewModel: NSObject, ObservableObject {
    // MARK: - Properties
    var features = [Feature]()
    var selectedFeature: Feature?
    @Published var showFeatureView = false { didSet {
        if showFeatureView {
            stopSearching()
            stopMeasuring()
            deselectPolyline()
        } else {
            selectedFeature = nil
        }
    }}
    
    var canals = [Canal]()
    var selectedCanals = [Canal]()
    @Published var selectedCanalId: String? { didSet {
        mapView?.removeOverlays(selectedCanals)
        selectedCanals = canals.filter { $0.id == selectedCanalId }
        mapView?.addOverlays(selectedCanals)
        
        resetPolylines()
        deselectPolyline()
    }}
    
    // Saved polylines
    var polylines = [Polyline]()
    @Published var selectedPolyline: Polyline?
    
    // Search Bar
    var searchBar: UISearchBar?
    var search: MKLocalSearch?
    var searchResults = [Annotation]()
    @Published var noResults = false
    @Published var isSearching = false
    
    // Measure distance
    var polyline: MKPolyline?
    @Published var annotations = [Annotation]()
    @Published var isMeasuring = false { didSet {
        if !isMeasuring {
            isCompleting = false
        }
    }}
    @Published var isCompleting = false
    @Published var showErrorMessage = false
    @Published var distance: Double?
    @Published var metric = UserDefaults.standard.bool(forKey: "metric") { didSet {
        UserDefaults.standard.set(metric, forKey: "metric")
    }}
    @Published var speed = Speed(rawValue: UserDefaults.standard.integer(forKey: "speed")) ?? .medium { didSet {
        UserDefaults.standard.set(speed.rawValue, forKey: "speed")
    }}
    
    // Record route
    var startedPaddling = Date()
    var startCoord = CLLocationCoordinate2D()
    var counter = 0
    var timer: Timer?
    var tripPolyline = MKPolyline()
    var duration = Double.zero
    @Published var tripError = false
    @Published var tripDistance = Double.zero
    @Published var isPaddling = false
    
    // Map View
    var zoomedIn = false
    var coord = CLLocationCoordinate2D()
    var mapView: MKMapView?
    @Published var userTrackingMode = MKUserTrackingMode.none
    @Published var mapType = MKMapType.standard
    
    // CLLocationManager
    let manager = CLLocationManager()
    var authStatus = CLAuthorizationStatus.notDetermined
    @Published var authError = false
    
    // Persistence
    let container = NSPersistentContainer(name: "Paddle")
    func save() {
        try? container.viewContext.save()
    }
    
    override init() {
        super.init()
        CLLocationManager().requestWhenInUseAuthorization()
    }
}

// MARK: - Load Data
extension ViewModel {
    func loadData() {
        loadCanals()
        container.loadPersistentStores { description, error in
            if let error = error {
                print("Core Data failed to load: ", error)
            } else {
                self.loadPolylines()
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
            canal.id = data.id
            canal.name = data.name
            canal.distance = data.dist
            return canal
        }
        
        mapView?.addOverlay(MKMultiPolyline(canals))
    }
    
    // Delete all given entities in core data
    func deleteAll(entityName: String) {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: entityName)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        do {
            try container.viewContext.execute(deleteRequest)
        } catch {
            debugPrint(error)
        }
    }
    
    func loadPolylines() {
//        deleteAll(entityName: "Polyline")
        
        polylines = (try? container.viewContext.fetch(Polyline.fetchRequest()) as? [Polyline]) ?? []
        mapView?.addOverlays(polylines)
    }
    
    func loadFeatures() {
//        deleteAll(entityName: "Feature")
        
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
                feature.lat = featureData.coord[0]
                feature.long = featureData.coord[1]
                features.append(feature)
            }
            save()
        }
        
        mapView?.addAnnotations(features)
    }
}

// MARK: - Saved Polylines
extension ViewModel {
    func startCompleting() {
        isCompleting = true
        isMeasuring = true
    }
    
    func resetPolylines() {
        mapView?.removeOverlays(polylines)
        mapView?.addOverlays(polylines)
    }
    
    func resetPolyline(_ polyline: Polyline?) {
        if let polyline = polyline {
            mapView?.removeOverlay(polyline)
            mapView?.addOverlay(polyline)
        }
    }
    
    func deselectPolyline() {
        let polyline = selectedPolyline
        selectedPolyline = nil
        resetPolyline(polyline)
    }
    
    func deletePolyline() {
        if let polyline = selectedPolyline {
            polylines.removeAll { $0 == polyline }
            mapView?.removeOverlay(polyline)
            
            container.viewContext.delete(polyline)
            save()
            
            selectedPolyline = nil
            Haptics.success()
        }
    }
    
    func selectClosestPolyline(to targetCoord: CLLocationCoordinate2D, canalId: String) {
        var shortestDistance = Double.infinity
        var closestPolyline: Polyline?
        
        for polyline in polylines.filter({ $0.canalId == canalId }) {
            // Only check every 5 coords
            let filteredCoords = polyline.mkPolyline.coordinates.enumerated().compactMap { index, element in
                index % 2 == 0 ? element : nil
            }
            
            for coord in filteredCoords {
                let delta = targetCoord.distance(to: coord)
                
                if delta < shortestDistance && delta < 200 {
                    shortestDistance = delta
                    closestPolyline = polyline
                }
            }
        }
        
        let oldPolyline = selectedPolyline
        selectedPolyline = closestPolyline
        resetPolyline(oldPolyline)
        resetPolyline(selectedPolyline)
    }
    
    func zoomToSelectedPolyline() {
        if let polyline = selectedPolyline {
            setRect(polyline.boundingMapRect, extraPadding: true)
        }
    }
    
    func requestReview() {
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }
}

// MARK: - Helper Functions
extension ViewModel {
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
            setRect(zoomRect, extraPadding: true)
        }
    }
    
    func setRegion(center: CLLocationCoordinate2D, delta: CLLocationDegrees, animated: Bool) {
        let span = MKCoordinateSpan(latitudeDelta: delta, longitudeDelta: delta)
        let region = MKCoordinateRegion(center: center, span: span)
        mapView?.setRegion(region, animated: animated)
    }
    
    func setRect(_ rect: MKMapRect, extraPadding: Bool = false) {
        let padding: UIEdgeInsets
        if extraPadding {
            padding = UIEdgeInsets(top: 50, left: 50, bottom: 100, right: 50)
        } else {
            padding = UIEdgeInsets(top: 20, left: 20, bottom: 80, right: 20)
        }
        mapView?.setVisibleMapRect(rect, edgePadding: padding, animated: true)
    }
    
    func openInMaps(name: String?, coord: CLLocationCoordinate2D) {
        CLGeocoder().reverseGeocodeLocation(coord.location) { placemarks, error in
            if let placemark = placemarks?.first {
                let mapItem = MKMapItem(placemark: MKPlacemark(placemark: placemark))
                mapItem.name = name ?? placemark.name
                mapItem.openInMaps()
            }
        }
    }
    
    func getClosestCoordCanal(to targetCoord: CLLocationCoordinate2D, outOf canals: [Canal]? = nil, skipEvery: Int = 1) -> (CLLocationCoordinate2D, Canal)? {
        var shortestDistance = Double.infinity
        var closestCanal: Canal?
        var closestCoord: CLLocationCoordinate2D?
        
        for canal in canals ?? self.canals {
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
        let (_, closestCanal) = getClosestCoordCanal(to: coord, skipEvery: 5) ?? (nil, nil)
        selectedCanalId = closestCanal?.id
    }
    
    func setSelectedRegion() {
        for annotation in mapView?.selectedAnnotations ?? [] {
            mapView?.deselectAnnotation(annotation, animated: true)
        }
        setRect(MKMultiPolyline(selectedCanals).boundingMapRect)
    }
}

// MARK: - Gesture Recogniser
extension ViewModel {
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
        } else if let oldCanalId = selectedCanalId {
            selectClosestCanal(to: tapCoord)
            if let canalId = selectedCanalId, canalId == oldCanalId {
                selectClosestPolyline(to: tapCoord, canalId: canalId)
            }
        } else {
            selectClosestCanal(to: tapCoord)
        }
    }
}

// MARK: - Measuring
extension ViewModel {
    func newCoord(_ coord: CLLocationCoordinate2D) {
        for annotation in annotations where annotation.coordinate.distance(to: coord) < 500 {
            mapView?.removeAnnotation(annotation)
            annotations.removeAll { $0.coordinate == annotation.coordinate }
            resetPolyline()
            distance = nil
            return
        }
        
        if annotations.count < 2 {
            let annotation = Annotation(type: .measure, title: nil, subtitle: nil, coordinate: coord)
            annotations.append(annotation)
            mapView?.addAnnotation(annotation)
            
            if annotations.count == 2 {
                let coords = calculateRoute(from: annotations[0].coordinate, to: annotations[1].coordinate)
                polyline = MKPolyline(coordinates: coords, count: coords.count)
                mapView?.addOverlay(polyline!)
                distance = coords.getDistance()
                zoomToPolyline()
            }
        }
    }
    
    func stopMeasuring() {
        isMeasuring = false
        resetMeasuring()
    }
    
    func resetMeasuring() {
        mapView?.removeAnnotations(annotations)
        annotations = []
        distance = nil
        resetPolyline()
    }
    
    func resetPolyline() {
        if let polyline = polyline {
            mapView?.removeOverlay(polyline)
        }
        polyline = nil
    }
    
    func calculateRoute(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) -> [CLLocationCoordinate2D] {
        func fail() {
            noResults = true
            showErrorMessage = true
        }
        
        guard let (startCoord, startCanal) = getClosestCoordCanal(to: start) else { fail(); return [] }
        selectedCanalId = startCanal.id
        guard let (endCoord, _) = getClosestCoordCanal(to: end, outOf: selectedCanals) else { fail(); return [] }
        
        // Need to get a list of all the coords along this line
        var coordinates = [CLLocationCoordinate2D]()
        coordinates.append(contentsOf: startCanal.coordinates)
        var canals = [Canal]()
        canals.append(contentsOf: selectedCanals)
        canals.removeAll { $0 == startCanal }
        var changesMade = true
        
        while changesMade {
            changesMade = false
            for canal in canals {
                let coords = canal.coordinates
                if coords.first == coordinates.first {
                    coordinates.reverse()
                    coordinates.append(contentsOf: coords)
                    changesMade = true
                    canals.removeAll { $0 == canal }
                } else if coords.first == coordinates.last {
                    coordinates.append(contentsOf: coords)
                    changesMade = true
                    canals.removeAll { $0 == canal }
                } else if coords.last == coordinates.first {
                    coordinates.insert(contentsOf: coords, at: 0)
                    changesMade = true
                    canals.removeAll { $0 == canal }
                } else if coords.last ==  coordinates.last {
                    coordinates.reverse()
                    coordinates.insert(contentsOf: coords, at: 0)
                    changesMade = true
                    canals.removeAll { $0 == canal }
                }
            }
        }
        
        guard let startIndex = coordinates.firstIndex(of: startCoord),
              let endIndex = coordinates.firstIndex(of: endCoord)
        else { fail(); return [] }
        
        let min = min(startIndex, endIndex)
        let max = max(startIndex, endIndex)
        let coords = Array(coordinates[min...max])
        
        showErrorMessage = false
        return coords
    }
    
    func zoomToPolyline() {
        if polyline?.coordinates.isNotEmpty ?? false {
            setRect(polyline!.boundingMapRect, extraPadding: true)
        }
    }
    
    func savePolyline() {
        let polyline = Polyline(context: container.viewContext)
        polyline.type = .completed
        polyline.canalId = selectedCanalId ?? ""
        polyline.distance = distance ?? 0
        polyline.duration = duration
        polyline.coords = (self.polyline?.coordinates ?? []).map { coord in
            [coord.latitude, coord.longitude]
        }
        
        duration = 0
        save()
        polylines.append(polyline)
        mapView?.addOverlay(polyline)
        stopMeasuring()
        Haptics.success()
    }
}

// MARK: - Record Trip
extension ViewModel {
    func startPaddling() {
        if validateAuth() {
            tripDistance = 0
            startedPaddling = Date.now
            startCoord = mapView?.userLocation.coordinate ?? CLLocationCoordinate2D()
            isPaddling = true
            counter = 0
            timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                self.handleTimer()
            }
            selectClosestCanal(to: startCoord)
            zoomTo(mapView?.userLocation == nil ? [] : [mapView!.userLocation])
            userTrackingMode = .followWithHeading
            mapView?.setUserTrackingMode(.followWithHeading, animated: true)
        }
    }
    
    func handleTimer() {
        objectWillChange.send()
        
        counter += 1
        if counter == 20 {
            counter = 0
            
            let coords = self.calculateRoute(from: self.startCoord, to: self.mapView?.userLocation.coordinate ?? self.startCoord)
            tripPolyline = MKPolyline(coordinates: coords, count: coords.count)
            mapView?.addOverlay(tripPolyline)
            tripDistance = coords.getDistance()
        }
    }
    
    func stopPaddling() {
        timer?.invalidate()
        mapView?.removeOverlay(tripPolyline)
        isPaddling = false
        duration = startedPaddling.distance(to: .now)
        
        let coords = self.calculateRoute(from: self.startCoord, to: self.mapView?.userLocation.coordinate ?? self.startCoord)
        showErrorMessage = false
        guard coords.isNotEmpty else { tripError = true; return }
        
        selectClosestCanal(to: startCoord)
        distance = coords.getDistance()
        tripPolyline = MKPolyline(coordinates: coords, count: coords.count)
        savePolyline()
        requestReview()
        
        var totalDistance = UserDefaults.standard.double(forKey: "totalDistance")
        totalDistance += distance ?? 0
        UserDefaults.standard.set(totalDistance, forKey: "totalDistance")
        
        var totalDuration = UserDefaults.standard.double(forKey: "totalDuration")
        totalDuration += duration
        UserDefaults.standard.set(totalDuration, forKey: "totalDuration")
    }
}

// MARK: - CLLocationManagerDelegate
extension ViewModel: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authStatus = manager.authorizationStatus
        if authStatus == .denied {
            authError = true
        }
    }
    
    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
    func validateAuth() -> Bool {
        if authStatus == .denied {
            authError = true
            return false
        } else {
            return true
        }
    }
}

// MARK: - MKMapViewDelegate
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
        } else if let polyline = overlay as? Polyline {
            let renderer = MKPolylineRenderer(polyline: polyline.mkPolyline)
            renderer.lineWidth = 3
            let color: Color
            if selectedPolyline == polyline {
                color = .red
            } else if let canalId = selectedCanalId, polyline.canalId == canalId {
                color = .yellow
            } else {
                color = .green
            }
            renderer.strokeColor = UIColor(color)
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
                marker?.displayPriority = .required
                marker?.animatesWhenAdded = true
                return marker
            } else if annotation.type == .measure {
                let pin = mapView.dequeueReusableAnnotationView(withIdentifier: MKPinAnnotationView.id, for: annotation) as? MKPinAnnotationView
                pin?.displayPriority = .required
                pin?.animatesDrop = true
                return pin
            }
        } else if let cluster = annotation as? MKClusterAnnotation {
            let marker = mapView.dequeueReusableAnnotationView(withIdentifier: MKMarkerAnnotationView.id, for: cluster) as? MKMarkerAnnotationView
            marker?.clusteringIdentifier = MKMarkerAnnotationView.id
            marker?.displayPriority = .required
            return marker
        }
        return nil
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let user = view.annotation as? MKUserLocation {
            mapView.deselectAnnotation(user, animated: false)
            coord = user.coordinate
            showFeatureView = true
        } else if let cluster = view.annotation as? MKClusterAnnotation {
            zoomTo(cluster.memberAnnotations)
        } else if isMeasuring {
            mapView.deselectAnnotation(view.annotation, animated: false)
        }
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
}

// MARK: - UISearchBarDelegate
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
            selectedCanalId = canal.id
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
