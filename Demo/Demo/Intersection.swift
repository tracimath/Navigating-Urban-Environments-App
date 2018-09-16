//
//  Intersections.swift
//  Demo
//
//  Created by Traci Mathieu on 6/5/18.
//  Copyright © 2018 Traci Mathieu. All rights reserved.
//

import Foundation
import MapKit

class Intersection {
    
    var name: String?
    var coordinate: CLLocationCoordinate2D?
    var distance: Double?
    var elevation: Double?
    var humidity: Double?
    var temperature: Double?
    var airQuality: Double?
    var label: UILabel?
    
    // returns the coordinates of the intersection
    func returnCoordinate() -> CLLocationCoordinate2D {
        return coordinate!
    }
    
    // returns the distance of the intersection from the user's position
    func returnDistance() -> Double {
        // potentially need to be able to get and set distance because user's position changes
        return distance!
    }
    
    init(name: String, coordinate: CLLocationCoordinate2D, distance: Double) {
        self.name = name
        self.coordinate = coordinate
        self.distance = distance
    }
    
}
