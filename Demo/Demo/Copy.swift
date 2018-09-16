//
//  ViewController.swift
//  Demo
//
//  Created by Traci Mathieu on 6/4/18.
//  Copyright © 2018 Traci Mathieu. All rights reserved.
//

import UIKit
import SceneKit
import MapKit
import ARCL
import CoreLocation

class ViewController: UIViewController {    
    
    var sceneLocationView = SceneLocationView()
    
    // dictionary of intersections with intersection name as key and object as value
    var intersections = [String: Intersection]()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        sceneLocationView.run()
        view.addSubview(sceneLocationView)
        
        loadNearbyStreets()
        
//        let coordinate = CLLocationCoordinate2D(latitude: 40.3468, longitude: 74.6602)
//
//        let location = CLLocation(coordinate: coordinate, altitude: 300)
//
//        // change image of the pin if necessary
//        let image = UIImage(named: "Pin.png")!
        
//
//        let annotationNode = LocationAnnotationNode(location: location, image: image)
//
//       // annotations scale relative to their distance
//         annotationNode.scaleRelativeToDistance = true
//    sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: annotationNode)
        
        
    }
    
    func loadNearbyStreets() {
        
        // fetch the current location and use the current location to load the nearby street names
        // call this every time the location of the user updates
        // probably need to have some caching in mind
        
        let firstPart = "http://api.geonames.org/findNearbyStreetsJSON?"
        let lastPart = "&username=tmathieu"
        let lat = 40.35
        let lng = -74.66
        let urlString = "\(firstPart)lat=\(lat)&lng=\(lng)\(lastPart)"
        print(urlString)
        let url = URL(string: urlString)
        let task = URLSession.shared.dataTask(with: url!)
        { (data, response, error) in
            if error != nil {
                print(error!)
            } else {
                if let urlContent = data {
                    do {
                        let jsonResult = try JSONSerialization.jsonObject(with: urlContent, options: JSONSerialization.ReadingOptions.mutableContainers) as? [String: Any]
                        let streets = jsonResult!["streetSegment"] as? [[String: Any]]
                        for index in 0...streets!.count-1 {
                            let entry = streets![index]
                            let streetname = entry["name"]! as! String
                            let coordinates = entry["line"]! as! String
                            let distance = Double(entry["distance"]! as! String)!
                            let startingCoordinate = coordinates.split(separator: ",")[0]
                            let arrayCoordinate = startingCoordinate.split(separator: " ")
                            let latitude = Double(arrayCoordinate[1])!
                            let longitude = Double(arrayCoordinate[0])!
                            print("streetname: \(streetname) coordinates: \(latitude) \(longitude)")
                            print("distance: \(distance)")
                            
                            // create an intersection object and add it to the dictionary
                            self.intersections[streetname] = Intersection(name: streetname, coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude), distance: distance)
                            
                        }
                        
                    } catch {
                        print("Json Processing Failed")
                    }
                }
            }
            
        }
        task.resume()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        sceneLocationView.frame = view.bounds
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

