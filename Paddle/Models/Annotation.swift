//
//  Annotation.swift
//  Paddle
//
//  Created by Jack Finnis on 16/09/2022.
//

import Foundation
import MapKit

class Annotation: NSObject, MKAnnotation {
    let type: AnnotationType
    let title: String?
    let subtitle: String?
    let coordinate: CLLocationCoordinate2D
    
    init(type: AnnotationType, title: String?, subtitle: String?, coordinate: CLLocationCoordinate2D) {
        self.type = type
        self.title = title
        self.subtitle = subtitle
        self.coordinate = coordinate
    }
}

enum AnnotationType {
    case search
    case measure
}
