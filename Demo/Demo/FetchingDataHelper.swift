//
//  FetchingDataHelper.swift
//  Demo
//
//  Created by Traci Mathieu on 6/11/18.
//  Copyright © 2018 Traci Mathieu. All rights reserved.
//

import Foundation
import Alamofire
import MapKit

protocol FetchingDataDelegate {
    func addRoutes(polyline: MKPolyline, coordinates: [CLLocationCoordinate2D], steps: [MKRouteStep])
}

class FetchingDataHelper {
    
    var delegate: FetchingDataDelegate!
    
    // uses Navigation API to create vectors for navigation to each intersection
    func getNavigation(originLat: Double, originLng: Double, destinLat: Double, destinLng: Double) {
        
        // Citation: https://www.hackingwithswift.com/example-code/location/how-to-find-directions-using-mkmapview-and-mkdirectionsrequest
        
        let request: MKDirectionsRequest = MKDirectionsRequest()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: originLat, longitude: originLng), addressDictionary: nil))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: destinLat, longitude: destinLng), addressDictionary: nil))
        request.requestsAlternateRoutes = true
        request.transportType = .walking
        
        let directions = MKDirections(request: request)
        
        directions.calculate { response, error in
            guard let unwrappedResponse = response else { return }
            
            for route in unwrappedResponse.routes {
                self.delegate.addRoutes(polyline: route.polyline, coordinates: route.polyline.coordinates, steps: route.steps)
                for index in 0...route.steps.count-1 {
                    // print(route.steps[index].instructions)

                }
            }
        }
    }

    // uses GeoNames API to fetch the altitude based on the coordinates
    func getElevation(latitude: Double, longitude: Double, completion: @escaping (Double) -> Void) {
        
        // get the elevation based on the coordinates
        let firstPartOfURL = "http://api.geonames.org/srtm1JSON?"
        let secondPartOfURL = "&username=tmathieu"
        let fullElevationURL = "\(firstPartOfURL)lat=\(latitude)&lng=\(longitude)\(secondPartOfURL)"
        
        var elevation: Double = 0.0
        
        Alamofire.request(fullElevationURL).responseJSON { response in
            let json = response.data
            do {
                let jsonResult = try JSONSerialization.jsonObject(with: json!, options: JSONSerialization.ReadingOptions.mutableContainers) as? [String: Double]
                elevation = jsonResult!["srtm1"]!
                completion(elevation)
            } catch let err {
                completion(elevation)
                print("Error parsing the elevation")
                print(err)
            }
        }
    }
    
    struct RawServerResponse : Decodable {
        let main: Weather
    }
    
    struct Weather : Decodable {
        let temp: Double
        let humidity: Double
    }
    
    // uses OpenWeatherMap API to fetch the humidity and temperature
    func getWeather(latitude: Double, longitude: Double, completion: @escaping (Double, Double) -> Void) {
        // API key: 9decf0315af7bc339d292d8c6967bf3d
        // URL: http://api.openweathermap.org/data/2.5/weather?lat=35&lon=139&units=imperial&APPID=9decf0315af7bc339d292d8c6967bf3d
        let firstPartOfURL = "http://api.openweathermap.org/data/2.5/weather?"
        let secondPartOfURL = "&units=imperial&APPID=9decf0315af7bc339d292d8c6967bf3d"
        let fullURL = "\(firstPartOfURL)lat=\(latitude)&lon=\(longitude)\(secondPartOfURL)"
        
        var humidity: Double = 34.0
        var temperature: Double = 88.0
        
        Alamofire.request(fullURL).responseJSON { response in
            let json = response.data
            do {
                // let jsonResult = try JSONSerialization.jsonObject(with: json!, options: JSONSerialization.ReadingOptions.mutableContainers) as? [String: Any]
                let decoder = JSONDecoder()
                let decodedData = try decoder.decode(RawServerResponse.self, from: json!)
                humidity = decodedData.main.humidity
                temperature = decodedData.main.temp
                completion(humidity, temperature)
            } catch let err {
                print("Error parsing from the OpenWeatherAPI")
                print(err)
                completion(humidity, temperature)
            }
            
        }
        
    }
    
    // GIVING ME SO MANY PROBLEMS
    // uses Worldwide Air Quality to fetch the air quality
    func getAQI(latitude: Double, longitude: Double, completion: @escaping (Double) -> Void) {
        
        // token: be2e6a4cd9a6f847aa5d678fb4b4ea6172596929
        // https://api.waqi.info/feed/geo:10.3;20.7/?token=demo
        // /feed/geo::lat;:lng/?token=:token
        
        let firstPartOfURL = "https://api.waqi.info/feed/geo:"
        let secondPartOfURL = "/?token=be2e6a4cd9a6f847aa5d678fb4b4ea6172596929"
        let fullURL = "\(firstPartOfURL)\(latitude);\(longitude)\(secondPartOfURL)"
        
        var airQuality: Double = 34.0
        
        completion(airQuality)
        
        Alamofire.request(fullURL).responseJSON { response in
            let json = response.data
            do {
                let jsonResult = try JSONSerialization.jsonObject(with: json!, options: JSONSerialization.ReadingOptions.mutableContainers) as? [String: Any]
                if let data = jsonResult!["data"] as? [String: Any] {
                    airQuality = (data["aqi"] as? Double)!
                    print(airQuality)
                    completion(airQuality)
                }
            } catch let err {
                completion(airQuality)
                print("Error parsing the air quality information.")
                print(err)
            }
        }
        
    }
}

// Citation: https://gist.github.com/freak4pc/98c813d8adb8feb8aee3a11d2da1373f
public extension MKPolyline {
    public var coordinates: [CLLocationCoordinate2D] {
        var coords = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid,
                                              count: self.pointCount)
        
        self.getCoordinates(&coords, range: NSRange(location: 0, length: self.pointCount))
        
        return coords
    }
}


