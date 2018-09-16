//
//  IntersectionMapMarker.swift
//  Demo
//
//  Created by Traci Mathieu on 7/3/18.
//  Copyright © 2018 Traci Mathieu. All rights reserved.
//

import Foundation
import MapKit

class IntersectionMapMarker: NSObject, MKAnnotation {
    
    let title: String?
    let locationName: String?
    let coordinate: CLLocationCoordinate2D
    let distance: Double?
    let airQuality: Int?
    let humidity: Int?
    let temperature: Int?
    let aqiColor: UIColor?
    let humColor: UIColor?
    let tempColor: UIColor?
    
    var mode = "aqi mode"
    
    init(title: String, locationName: String, coordinate: CLLocationCoordinate2D, distance: Double, airQuality: Double, humidity: Double, temperature: Double, aqiColor: UIColor, humColor: UIColor, tempColor: UIColor) {
        self.title = title
        self.locationName = locationName
        self.coordinate = coordinate
        self.distance = distance
        self.airQuality = Int(airQuality)
        self.humidity = Int(humidity)
        self.temperature = Int(temperature)
        self.aqiColor = aqiColor
        self.humColor = humColor
        self.tempColor = tempColor
        
        super.init()
    }
    
    // markerTintColor for AQI
    var markerTintColor: UIColor  {
        
        if (mode == "aqi mode") {
            return aqiColor!.withAlphaComponent(1.0)
        }
        else if (mode == "hum mode") {
            return humColor!.withAlphaComponent(1.0)
        }
        else {
            return tempColor!.withAlphaComponent(1.0)
        }
        
//        if airQuality != nil {
//        if airQuality! < 51 {
//            return UIColor.green
//    }
//        else if airQuality! < 101 {
//            return UIColor.yellow
//    }
//        else if airQuality! < 151 {
//            return UIColor.orange
//    }
//        else if airQuality! < 201 {
//            return UIColor.red
//    }
//        else if airQuality! < 301 {
//            return UIColor.purple
//    }
//        else {
//            // maroon color
//            return UIColor(red: (128/255.0), green: (0/255.0), blue: (0/255.0), alpha: 1.0)
//    }
//  }
//        else {
//            return UIColor.red
//        }
}
    
    var subtitle: String? {
        return locationName
    }
}
