//
//  Feature.swift
//  Paddle
//
//  Created by Jack Finnis on 11/09/2022.
//

import Foundation
import MapKit
import SwiftUI
import CoreData

@objc(Feature)
class Feature: NSManagedObject {
    @NSManaged var type: FeatureType
    @NSManaged var coord: [Double]
    @NSManaged var name: String
    @NSManaged var angle: Double
    @NSManaged var id: String
}

extension Feature: MKAnnotation {
    var title: String? { name.isEmpty ? type.name : name }
    var subtitle: String? { name.isEmpty ? "" : type.name }
    var coordinate: CLLocationCoordinate2D { .init(latitude: coord[0], longitude: coord[1]) }
}

@objc
enum FeatureType: Int16, CaseIterable, Codable {
    case feature
    case lock
    case weir
    case launchPoint
    case obstruction
    
    init?(string: String) {
        for type in FeatureType.allCases where type.value == string {
            self = type
            return
        }
        return nil
    }
    
    var value: String {
        switch self {
        case .lock:
            return "lock"
        case .weir:
            return "weir"
        case .launchPoint:
            return "launchPoint"
        case .obstruction:
            return "obstruction"
        case .feature:
            return "feature"
        }
    }
    
    var name: String {
        switch self {
        case .lock:
            return "Lock"
        case .weir:
            return "Weir"
        case .launchPoint:
            return "Launch Point"
        case .obstruction:
            return "Obstruction"
        case .feature:
            return "Feature"
        }
    }
    
    var fileName: String? {
        switch self {
        case .lock:
            return "Locks"
        case .weir:
            return "Weirs"
        default:
            return nil
        }
    }
    
    var color: Color {
        switch self {
        case .lock:
            return .black
        case .weir:
            return .orange
        case .launchPoint:
            return .red
        case .obstruction:
            return .yellow
        case .feature:
            return .accentColor
        }
    }
}

struct FeatureData: Codable {
    let id: String
    let angle: Double?
    let name: String
    let coord: [Double]
    let type: String
}
