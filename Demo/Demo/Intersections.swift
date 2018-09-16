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
    
    let coordinate: CLLocationCoordinate2D
    
    func coord() -> CLLocationCoordinate2D {
        return coordinate
    }
    
    init(coordinate: CLLocationCoordinate2D) {
        
        self.coordinate = coordinate
        
    }
    
    init?(json: [Any]) {
        
        if let latitude = Double(json[0] as! String),
            let longitude = Double(json[1] as! String) {
            self.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
        else {
            self.coordinate = CLLocationCoordinate2D()
        }
    }
    
}
