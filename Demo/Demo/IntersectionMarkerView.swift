//
//  IntersectionMarkerView.swift
//  Demo
//
//  Created by Traci Mathieu on 6/25/18.
//  Copyright © 2018 Traci Mathieu. All rights reserved.
//

import Foundation
import MapKit

class IntersectionMarkerView: MKMarkerAnnotationView {
    override var annotation: MKAnnotation? {
        willSet {
            // 1
            guard let mapMarker = newValue as? IntersectionMapMarker else { return }
            canShowCallout = true
            calloutOffset = CGPoint(x: -5, y: 5)
            rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            // 2
            markerTintColor = mapMarker.markerTintColor
            if mapMarker.mode == "aqi mode" {
                glyphText = String("\(mapMarker.airQuality!)")
            }
            else if mapMarker.mode == "temp mode" {
                glyphText = String("\(mapMarker.temperature!)")
            }
            else {
                glyphText = String("\(mapMarker.humidity!)")
            }
            glyphTintColor = UIColor.black
        }
    }
}
