//
//  MapViewController.swift
//  
//  Created by Traci Mathieu on 6/22/18.
//

import UIKit
import MapKit
import CoreLocation
import SceneKit
import AlamofireImage

protocol MapViewDelegate {
    func addNavigationToScene(coordinates: [CLLocationCoordinate2D], steps: [MKRouteStep])
}

class MapViewController: UIViewController, FetchingDataDelegate {
     
    @IBOutlet weak var switchData: UISegmentedControl!
    
    // button for switching between the AR and Maps view
    @IBOutlet weak var switchView: UIButton!
     
    // buttons for the different data views
    @IBOutlet weak var aqiButton: UIButton!
    @IBOutlet weak var tempButton: UIButton!
    @IBOutlet weak var humButton: UIButton!
     
    // displays the gradient legend
    @IBOutlet weak var legend: UIImageView!
     
    // buttons for the different modes
    @IBOutlet weak var toggleMarkers: UIButton!
    @IBOutlet weak var toggleData: UIButton!
    @IBOutlet weak var toggleTraffic: UIButton!

     var gradientIsSet = false
     var markersOn = false
     var gradientOn = false
     var trafficOn = false
     var dataMode = "temp"
     
     // set up the images for the buttons
    let tempImage = UIImage(named: "temp")
    let shadedTempImage = UIImage(named: "temp shaded")
    let aqiImage = UIImage(named: "aqi")
    let shadedAqiImage = UIImage(named: "aqi shaded")
    let humImage = UIImage(named: "hum")
    let shadedHumImage = UIImage(named: "hum shaded")
    
    // for rendering the MKCircle overlays
    var gradientColors = [UIColor.green, UIColor.red]
    
    var delegate: MapViewDelegate!
    
    // dictionary of intersections with intersection coordinates as key and Intersection object as value
    var dictionary: [String: Intersection] = [:]
    
    // holds the intersections parsed from the JSON
    var intersections = [CLLocationCoordinate2D]()
     
     // Holds the coordinates of the centers of the grid
     var centers = [CLLocationCoordinate2D]()
     
    // holds the names of the intersections parsed
    var intersectionNames = [String]()
    
    // holds all the annotations for the intersections
    var annotations = [IntersectionMapMarker]()
     
    var markersInView = [IntersectionMapMarker]()
     
    var currentFillColor = UIColor.green
     
    var timer = Timer()
   
    // holds the circles representing the data
    var circles = [MKCircle]()
    var polygons = [MKPolygon]()
     
    var tempColors = [UIColor]()
    var humColors = [UIColor]()
    var aqiColors = [UIColor]()
     
     var temp: [[Double]]?
     var hum: [[Double]]?
     var aqi: [[Double]]?
    
    let dataHelper = FetchingDataHelper()
     
    var lowerBound = UITextField()
    var upperBound = UITextField()
    
    var currentLocation = CLLocationCoordinate2D(latitude: 40.3573, longitude: -74.6672)
    
    // the map view
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
     
        // set up the delegates
        dataHelper.delegate = self
        mapView.delegate = self
     
    }
     
    override func viewWillAppear(_ animated: Bool) {
     
     let size = CGSize(width: 50.0, height: 50.0)
     
     switchView.addTarget(self, action: #selector(self.tapButton(_:)), for: .touchUpInside)
     
     toggleMarkers.addTarget(self, action: #selector(self.tapButton(_:)), for: .touchUpInside)
     toggleData.addTarget(self, action: #selector(self.tapButton(_:)), for: .touchUpInside)
     toggleTraffic.addTarget(self, action: #selector(self.tapButton(_:)), for: .touchUpInside)
     
//     switchData.setBackgroundImage(tempImage, for: UIControlState(rawValue: 2), barMetrics: UIBarMetrics(rawValue: 0)!)\

     toggleMarkers.layer.borderWidth = 1
     toggleMarkers.layer.borderColor = UIColor.black.cgColor
     toggleData.layer.borderWidth = 1
     toggleData.layer.borderColor = UIColor.black.cgColor
     toggleTraffic.layer.borderWidth = 1
     toggleTraffic.layer.borderColor = UIColor.black.cgColor
     
     switchData.tintColor = UIColor.black
     switchView.layer.borderWidth = 1
     switchView.layer.borderColor = UIColor.black.cgColor
     
     mapView.userTrackingMode = .follow
     mapView.mapType = MKMapType.hybrid
     mapView.isZoomEnabled = true
     mapView.isScrollEnabled = true
     
     mapView.showsTraffic = true
     
     mapView.register(IntersectionMarkerView.self,
                          forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
        
        if intersections.count == 0 {
            
            if let url = Bundle.main.url(forResource:"princeton_intersections", withExtension: "txt") {
                do {
                    let data = try Data(contentsOf: url)
                    let attibutedString = try NSAttributedString(data: data, documentAttributes: nil)
                    let fullText = attibutedString.string
                    let readings = fullText.components(separatedBy: CharacterSet.newlines)
                    for line in readings {
                        let result1 = String(line.dropFirst())
                        let result2 = String(result1.dropLast())
                        let result3 = result2.split(separator: ",")
                        if result3.count == 2 {
                           let result4 = result3[1].split(separator: " ")
                           let latitude = Double(result4[0])
                           let longitude = Double(result3[0])
                            let intersection = CLLocationCoordinate2D(latitude: latitude!, longitude: longitude!)
                           intersections.append(intersection)
                        }
                    }
                } catch {
                    print(error)
                }
            }
          
          if let url = Bundle.main.url(forResource: "intersection_names", withExtension: "txt") {
               do {
                    let data = try Data(contentsOf: url)
                    let attributedString = try NSAttributedString(data: data, documentAttributes: nil)
                    let fullText = attributedString.string
                    let readings = fullText.components(separatedBy: CharacterSet.newlines)
                    for line in readings {
                         var intersectionName = String(line)
                         if intersectionName == "None" {
                            intersectionName = "N/A"
                         }
                         intersectionNames.append(intersectionName)
                    }
               } catch {
                    print(error)
               }
          }
          
          
          // Fetches the processed data from Firebase, move to the ViewController.swift
          
          let url = URL(string: "http://site.princeton.edu/interpolate.cgi")!
          var request = URLRequest(url: url)
          request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
          request.httpMethod = "POST"
          let postString = "bound1_lon=-74.66738129&bound2_lon=-74.63986206&bound1_lat=40.34480667&bound2_lat=40.36558533"
          request.httpBody = postString.data(using: .utf8)
          let task = URLSession.shared.dataTask(with: request) { data, response, error in
               guard let data = data, error == nil else {                                                 // check for fundamental networking error
                    print("error=\(error)")
                    return
               }
               
               if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {           // check for http errors
                    print("statusCode should be 200, but is \(httpStatus.statusCode)")
                    print("response = \(response)")
               }
               
               let responseString = String(data: data, encoding: .utf8)
               // print("responseString = \(responseString)")
               if var response = responseString {
                    response.removeFirst(13)
                    response.removeLast(2)
                    self.decodeData(response: response)
               }
          }
          
          task.resume()

            // createAnnotations()
    
            var coordinates = [CLLocationCoordinate2D]()
            var airQuality = [Double]()
        
            for intersection in intersections  {
                coordinates.append(intersection)
                airQuality.append(dictionary.values.first!.airQuality!)
            }
    }
        else {
            for annotation in self.mapView.annotations {
                mapView.view(for: annotation)?.isHidden = false
            }
        }
}
     
     // converts data value to a number
     func numberToColor(value: Double, min: Double, max: Double, gradientColors: [UIColor]) -> UIColor {
          
          var val = value
          var maxValue = max
          var minValue = min
          
          // Ensure value is in range
          if (val < min) {
               val = min
          }
          if (val > max) {
               val = max
          }
          
          // Normalize min-max range to [0, positive-value]
          maxValue -= minValue
          val -= minValue
          minValue = 0
          
          // Calculate distance from min to max in [0, 1]
          var distanceFromMin = val / maxValue
          
          var startColor = UIColor.green
          var endColor = UIColor.red
          
          // Define start and end color
          if (gradientColors.count == 0 || gradientColors.count == 1) {
               let gradient = [UIColor.green, UIColor.yellow, UIColor.orange, UIColor.red]
               return numberToColor(value: val, min: minValue, max: maxValue, gradientColors: gradient)
          }
          else if (gradientColors.count == 2) {
               startColor = gradientColors[0]
               endColor = gradientColors[1]
          }
          else {
               startColor = gradientColors[Int(floor(distanceFromMin * Double((gradientColors.count - 1))))]
               endColor = gradientColors[Int(ceil(distanceFromMin * Double((gradientColors.count - 1))))]
               distanceFromMin *= Double(gradientColors.count - 1)
               while (distanceFromMin > 1) {
                    distanceFromMin = distanceFromMin - 1
               }
          }
          
          let ra = startColor.redValue * 255
          let ga = startColor.greenValue * 255
          let ba = startColor.blueValue * 255
          let rz = endColor.redValue * 255
          let gz = endColor.greenValue * 255
          let bz = endColor.blueValue * 255
          
          // Get rgb based on
          let distDiff = 1 - distanceFromMin
          
          var r = Double((Double(rz) * distanceFromMin) + (Double(ra) * distDiff))
          r = Swift.min(Swift.max(0, r), 255)
          var g = Double((Double(gz) * distanceFromMin) + (Double(ga) * distDiff))
          g = Swift.min(Swift.max(0, g), 255)
          var b = Double((Double(bz) * distanceFromMin) + (Double(ba) * distDiff))
          b = Swift.min(Swift.max(0, b), 255)
          
          return UIColor(red: CGFloat(r/255.0), green: CGFloat(g/255.0), blue: CGFloat(b/255.0), alpha: 0.25)
     }
     
     func decodeData(response: String) {
          let decoder = JSONDecoder()
          do {
               let correctedJsonStr = response.replacingOccurrences(of: "NaN", with: "-0.01")
               let decodedData = try decoder.decode(FirebaseData.self, from: correctedJsonStr.data(using: .utf8)!)
               
               createGrid()
               
               print(polygons.count)
               
               print("grid created")
               
               temp = decodedData.processed.temp
               hum = decodedData.processed.hum
               aqi = decodedData.processed.P25
               
               for i in 0...temp!.count-1 {
                    for j in 0...temp!.count-1 {
                         if temp![i][j] != -0.01 {
//                              temp![i][j] = -Double.infinity
//                              hum![i][j] = -Double.infinity
//                              aqi![i][j] = -Double.infinity
                              temp![i][j] = (temp![i][j] * (9/5)) + 32
                              aqi![i][j] = (AQIPM25(dustVal: aqi![i][j]))
                         }
                    }
               }
               
               // print(temp!)
               
               tempColors = generateGradient(data: temp!)
               humColors = generateGradient(data: hum!)
               aqiColors = generateGradient(data: aqi!)
               
               createAnnotations()
          
          }
          catch let err {
               print("Error parsing from Firebase")
               print(err)
          }
     }
     
     struct FirebaseData: Decodable {
          let original: AQData
          let processed: AQProcessedData
     }
     
     struct AQData: Decodable {
          let temp: [Double]
          let hum: [Double]
          let P25: [Double]
     }
     struct AQProcessedData: Decodable {
          let temp: [[Double]]
          let hum: [[Double]]
          let P25: [[Double]]
     }
     
     func createGrid() {
          let region = mapView.region
          
          let boundary = (north: region.center.latitude + region.span.latitudeDelta / 2.0, south: region.center.latitude - region.span.latitudeDelta / 2.0, east: region.center.longitude + region.span.longitudeDelta / 2.0, west: region.center.longitude - region.span.longitudeDelta / 2.0)
          
          let mapBounds = (north: 40.36558533, south: 40.34480667, east: -74.63986206, west: -74.66738129)
          
          var north = mapBounds.north
          var south = 0.0
          var east = mapBounds.east
          var west = 0.0
          
          let n = 80
          
          for _ in 0...n-1 {
               west = east - (mapBounds.east - mapBounds.west)/Double(n)
               
               for _ in 0...n-1 {
                    
                    south = north - (mapBounds.north - mapBounds.south)/Double(n)
                    
                    var coord = [CLLocationCoordinate2D]()
                    
                    let coord1 = CLLocationCoordinate2D(latitude: north, longitude: east)
                    let coord2 = CLLocationCoordinate2D(latitude: north, longitude: west)
                    let coord3 = CLLocationCoordinate2D(latitude: south, longitude: west)
                    let coord4 = CLLocationCoordinate2D(latitude: south, longitude: east)
                    coord.append(coord1)
                    coord.append(coord2)
                    coord.append(coord3)
                    coord.append(coord4)
                    
                    polygons.append(MKPolygon(coordinates: coord, count: 4))
                    
                    let center = CLLocationCoordinate2D(latitude: south + (north - south) / 2, longitude: west + (east - west) / 2)
                    
                    centers.append(center)
                    
                    north = south
               }
               north = mapBounds.north
               east = west
          }
          polygons.reverse()
          centers.reverse()
     }
     
     func generateGradient(data: [[Double]]) -> ([UIColor]) {
          
          var processedData = [Double]()
          
          let n = 80
          
          for i in 0...n-1 {
               for j in 0...n-1 {
                    if (data[i][j] != -0.01) {
                         processedData.append(data[i][j])
                    }
               }
          }
          
          var max = processedData.max()
          var min = processedData.min()
          
          if (data == aqi) {
               max = 500
               min = 0
          }
          
          var dataColors = [UIColor]()
          
          for i in 0...n-1 {
               for j in 0...n-1 {
                    // skip the NaNs
                    if (data[i][j] == -0.01) {
                         dataColors.append(UIColor(red: CGFloat(0.0), green: CGFloat(0.0), blue: CGFloat(0.0), alpha: 0.0))
                         continue;
                    }
                    
                    // /34,139,34
                    
                    let darkGreen = UIColor(red: CGFloat(34.0/255.0), green: CGFloat(139.0/255.0), blue: CGFloat(34.0/255.0), alpha: 1.0)
               
                    let color = numberToColor(value: data[i][j], min: min!, max: max!, gradientColors: [UIColor.green, UIColor.yellow, UIColor.orange, UIColor.red])
                    
                    dataColors.append(color)
               }
          }
          return dataColors
     }
     
     // colors the data
     func colorData(value: Double, min: Double, max: Double) -> UIColor {
          
          let newMin = 0.0
          let newMax = 1.0
          
          // let min = min
          // let max = max
          
          let oldRange = (max - min)
          let newRange = newMax - newMin
          
          let newValue = (((value - min) * newRange) / oldRange) + newMin
          let red = 1 - newValue
          let green = newValue
          
          // create color based on the height
          let newColor = UIColor(red: (CGFloat(red)), green: (CGFloat(green)), blue: (0.00), alpha: 0.50)
          
          return newColor
     }
     
//     func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
//          print("mapview region changed")
//
//          // mapView.checkSpan()
//
//          let nePoint = CGPoint(x: self.mapView.bounds.origin.x + mapView.bounds.size.width, y: mapView.bounds.origin.y)
//          let swPoint = CGPoint(x: self.mapView.bounds.origin.x, y: mapView.bounds.origin.y + mapView.bounds.size.height)
//
//          let neCoord = mapView.convert(nePoint, toCoordinateFrom: mapView)
//          let swCoord = mapView.convert(swPoint, toCoordinateFrom: mapView)
//
//
//          // createCircles()
//
//          if mapView.overlays.count == polygons.count {
//
//               // remove the old overlays
//               let allOverlays = self.mapView.overlays
//               self.mapView.removeOverlays(allOverlays)
//
//               // add the new overlays
//               for index in 0...polygons.count-1 {
//                    currentFillColor = fillColors[index]
//                    mapView.add(polygons[index])
//               }
//          }
//
//     }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func addRoutes(polyline: MKPolyline, coordinates: [CLLocationCoordinate2D], steps: [MKRouteStep]) {
        
//         self.mapView.add(polyline)
//         self.mapView.setVisibleMapRect(polyline.boundingMapRect, animated: true)
    
//         self.delegate.addNavigationToScene(coordinates: coordinates, steps: steps)
    }
    
     func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        if overlay is ImageOverlay {
            return ImageOverlayRenderer(overlay: overlay)
        }
        else if overlay is MKPolygon {
          let square = MKPolygonRenderer(overlay: overlay)
          square.fillColor = currentFillColor
          return square

        }
        
      let renderer = MKPolylineRenderer(polyline: overlay as! MKPolyline)
      renderer.strokeColor = UIColor.blue
      return renderer
    
    }
    
    func refreshMapView() {
        
    }
    
    func getColor(airQuality: Double) -> UIColor {
        
        if airQuality < 51.0 {
            return UIColor.green
        }
        else if airQuality < 101.0 {
            return UIColor.yellow
        }
        else if airQuality < 151.0 {
            return UIColor.orange
        }
        else if airQuality < 201.0 {
            return UIColor.red
        }
        else if airQuality < 301.0 {
            return UIColor.purple
        }
        else {
            // maroon color
            return UIColor(red: (128/255.0), green: (0/255.0), blue: (0/255.0), alpha: 1.0)
        }
    }
    
    // when the user clicks on the info button, show more information about the intersection
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView,
                 calloutAccessoryControlTapped control: UIControl) {
          if control == view.rightCalloutAccessoryView {
               print("button tapped")
               if let mapMarker = view.annotation as? IntersectionMapMarker {
                    let alert = UIAlertController(title: mapMarker.title!, message: "AQI: \(mapMarker.airQuality!) / 500\n Temperature: \(mapMarker.temperature! - 54)°F\n Humidity: \(mapMarker.humidity! / 2)%", preferredStyle: .alert)
                    // alert.addAction(deleteAction)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: { action in
                         // do something like...
                         print("cancel")
                         return
                    }))
                    self.present(alert, animated: true, completion: nil)
               }
          }
    }
    
     func createAnnotations() {
        var count = 0
        for index in 0...intersections.count-1 {
          
          let coordinate = CLLocationCoordinate2D(latitude: intersections[index].latitude, longitude: intersections[index].longitude)
          
          let latitude = coordinate.latitude
          let longitude = coordinate.longitude
          
          let north = 40.36558533
          let south = 40.34480667
          let east = -74.63986206
          let west = -74.66738129
          
          // check if intersection is within bounds
          if (latitude > north || latitude < south || longitude < west || longitude > east) {
               continue
          }
     
          
          var distance = Double.infinity
          
          var champion = 0
          
          for i in 0...centers.count-1 {
               let center = centers[i]
               if (coordinate.distance(from: center) < distance) {
                    // need to avoid the NaN values
                    if (temp![i / 80][i % 80] == -0.01) {
                         continue
                    }
                    distance = coordinate.distance(from: center)
                    champion = i
               }
          }
          let i = champion / 80
          let j = champion % 80
          
          // print(aqi![i][j], hum![i][j], temp![i][j])
          
          let mapMarker = IntersectionMapMarker(title: intersectionNames[index], locationName: "Princeton", coordinate: intersections[index], distance: 54.0, airQuality: round(aqi![i][j]), humidity: round(hum![i][j] * 10) / 10, temperature: round(temp![i][j] * 100) / 100, aqiColor: aqiColors[champion], humColor: humColors[champion], tempColor: tempColors[champion])
          annotations.append(mapMarker)
          count = count + 1
        }
    }
     
     func AQIPM25(dustVal: Double) -> Double {
          // for PM25
          var I_low = 0.0
          var I_high = 0.0
          var C_low = 0.0
          var C_high = 0.0
          
          if (dustVal <= 12.0)
          {
               I_low = 0.0
               I_high = 50.0
               C_low = 0.0
               C_high = 12.0
          }
          else if (dustVal > 12.0 && dustVal <= 35.4)
          {
               I_low = 51.0
               I_high = 100.0
               C_low = 12.1
               C_high = 35.4
          }
          else if (dustVal > 35.4 && dustVal <= 55.4)
          {
               I_low = 101.0
               I_high = 150.0
               C_low = 35.5
               C_high = 55.4
          }
          else if (dustVal > 55.4 && dustVal <= 150.4)
          {
               I_low = 151.0
               I_high = 200.0
               C_low = 55.5
               C_high = 150.4
          }
          else if (dustVal > 150.4 && dustVal <= 250.4)
          {
               I_low = 201.0
               I_high = 300.0
               C_low = 150.5
               C_high = 250.5
          }
          else
          {
               I_low = 301.0
               I_high = 500.0
               C_low = 250.5
               C_high = 500.4
          }
          
          let C = dustVal
          let AQIPM25Value = (I_high - I_low) * (C - C_low) / (C_high - C_low) + I_low
          return AQIPM25Value
     }
    
    
    @IBAction func dataSegmentSelected(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
            
            case 0:
                if (polygons.count == 0) {
                    return
                }
                
                dataMode = "aqi"
                
                lowerBound.removeFromSuperview()
                upperBound.removeFromSuperview()
                
                lowerBound.text = " 0"
                upperBound.text = "500"
                
                legend.addSubview(lowerBound)
                legend.addSubview(upperBound)
                
                // update the gradient
                
                let gradientOverlay = mapView.overlays
                mapView.removeOverlays(gradientOverlay)
                
                print(polygons.count)
                
                if (gradientOn == true && aqiColors.count != 0) {
                    for i in 0...polygons.count-1 {
                        currentFillColor = aqiColors[i]
                        if (currentFillColor.alphaValue == 0) {
                            continue
                        }
                        mapView.add(polygons[i])
                    }
                }
                
                // update the annotations
                
                let mapMarkers = mapView.annotations
                mapView.removeAnnotations(mapMarkers)
                
                markersInView.removeAll()
                
                for annotation in annotations {
                    if let mapMarker = annotation as? IntersectionMapMarker {
                        mapMarker.mode = "aqi mode"
                        markersInView.append(mapMarker)
                    }
                }
                
                if markersOn {
                    mapView.addAnnotations(markersInView)
                }
                
                toggleData.isEnabled = true
                toggleMarkers.isEnabled = true
                toggleTraffic.isEnabled = true
                print("AQI")
            case 1:
                if (polygons.count == 0) {
                    return
                }
                
                print("humidity mode")
                // let annotations = mapView.annotations
                
                dataMode = "hum"
                
                lowerBound.removeFromSuperview()
                upperBound.removeFromSuperview()
                
                lowerBound.text = " 0%"
                upperBound.text = "100%"
                
                legend.addSubview(lowerBound)
                legend.addSubview(upperBound)
                
                // update the gradient
                
                let gradientOverlay = mapView.overlays
                mapView.removeOverlays(gradientOverlay)
                
                if (gradientOn == true && humColors.count != 0) {
                    for i in 0...polygons.count-1 {
                        currentFillColor = humColors[i]
                        if (currentFillColor.alphaValue == 0) {
                            continue
                        }
                        mapView.add(polygons[i])
                    }
                }
                
                // update the markers
                
                let mapMarkers = mapView.annotations
                mapView.removeAnnotations(mapMarkers)
                
                markersInView.removeAll()
                
                for annotation in annotations {
                    if let mapMarker = annotation as? IntersectionMapMarker {
                        mapMarker.mode = "hum mode"
                        markersInView.append(mapMarker)
                    }
                }
                
                if markersOn {
                    mapView.addAnnotations(markersInView)
                }
                
                toggleData.isEnabled = true
                toggleMarkers.isEnabled = true
                toggleTraffic.isEnabled = true
                print("Hum")
            default:
               if (polygons.count == 0) {
                    return
               }
               
               dataMode = "temp"
               
               // update the legend
               lowerBound.removeFromSuperview()
               upperBound.removeFromSuperview()
               
               lowerBound.text = " -20°F"
               upperBound.text = "120°F"
               
               legend.addSubview(lowerBound)
               legend.addSubview(upperBound)
               
               // update the gradient
               
               let gradientOverlay = mapView.overlays
               mapView.removeOverlays(gradientOverlay)
               
               if (gradientOn == true && tempColors.count != 0) {
                    for i in 0...polygons.count-1 {
                         currentFillColor = tempColors[i]
                         if (currentFillColor.alphaValue == 0) {
                              continue
                         }
                         mapView.add(polygons[i])
                    }
               }
               
               // update the markers
               
               let mapMarkers = mapView.annotations
               mapView.removeAnnotations(mapMarkers)
               
               markersInView.removeAll()
               
               for annotation in annotations {
                    if let mapMarker = annotation as? IntersectionMapMarker {
                         mapMarker.mode = "temp mode"
                         markersInView.append(mapMarker)
                    }
               }
               
               if markersOn {
                    mapView.addAnnotations(markersInView)
               }
               
                toggleData.isEnabled = true
                toggleMarkers.isEnabled = true
                toggleTraffic.isEnabled = true
                print("Temp")
        }
    }
    
    @objc func tapButton(_ sender: UIButton) {
     
     if sender != switchView && gradientIsSet == false {
          let gradient = CAGradientLayer()
          
          gradient.frame = legend.bounds
          // gradient.transform = CATransform3DMakeRotation(CGFloat.pi / 2, 0, 0, 1)
          gradient.colors = [UIColor.green.cgColor, UIColor.yellow.cgColor, UIColor.orange.cgColor, UIColor.red.cgColor]
          
          gradient.startPoint = CGPoint(x: 0.0, y: 0.0)
          gradient.endPoint = CGPoint(x: 1.0, y: 0.0)
          
          legend.backgroundColor = UIColor(white: 1, alpha: 0.0)
          
          legend.layer.insertSublayer(gradient, at: 0)
          
          legend.addSubview(lowerBound)
          lowerBound.frame = legend.bounds
          
          legend.addSubview(upperBound)
          upperBound.frame = legend.bounds
          upperBound.textAlignment = NSTextAlignment.right
          gradientIsSet = true
     }
     
     upperBound.font = UIFont.boldSystemFont(ofSize: 14)
     lowerBound.font = UIFont.boldSystemFont(ofSize: 14)
     
     if (sender != switchView) {
          toggleData.isEnabled = true
          toggleMarkers.isEnabled = true
          toggleTraffic.isEnabled = true
     }
     
        switch sender {
        case switchView:
            // switch back to the AR view and removes the annotations and circle overlays
               self.mapView.removeAnnotations(mapView.annotations)
               self.mapView.removeOverlays(mapView.overlays)
               markersOn = false
               gradientOn = false
               print("switch to AR view")
               self.dismiss(animated: true, completion: nil)
        
        case toggleMarkers:
          if (markersOn) {
               // remove the markers
               let allMarkers = self.mapView.annotations
               self.mapView.removeAnnotations(allMarkers)
               markersOn = false
               toggleMarkers.backgroundColor = UIColor.white
               toggleMarkers.tintColor = UIColor.black
          }
          else {
               // add the markers
               mapView.addAnnotations(annotations)
               markersOn = true
               toggleMarkers.backgroundColor = UIColor.black
               toggleMarkers.tintColor = UIColor.white
          }
          print("Markers")
        case toggleData:
          if (gradientOn) {
               // remove the gradient
               let allOverlays = self.mapView.overlays
               self.mapView.removeOverlays(allOverlays)
               gradientOn = false
               toggleData.backgroundColor = UIColor.white
               toggleData.tintColor = UIColor.black
          }
          else {
               for i in 0...polygons.count - 1 {
                    if dataMode == "temp" {
                         currentFillColor = tempColors[i]
                    }
                    else if dataMode == "aqi" {
                         currentFillColor = aqiColors[i]
                    }
                    else {
                         currentFillColor = humColors[i]
                    }
                    
                    if (currentFillColor.alphaValue == 0) {
                         continue
                    }
                    mapView.add(polygons[i])
               }
               print(mapView.overlays.count)
               toggleData.backgroundColor = UIColor.black
               toggleData.tintColor = UIColor.white
               gradientOn = true
          }
          print("Data")
        case toggleTraffic:
          if trafficOn {
               mapView.showsTraffic = false
               trafficOn = false
               toggleTraffic.backgroundColor = UIColor.white
               toggleTraffic.tintColor = UIColor.black
          }
          else {
               mapView.showsTraffic = true
               trafficOn = true
               toggleTraffic.backgroundColor = UIColor.black
               toggleTraffic.tintColor = UIColor.white
          }
          print("Traffic")
        default:
            print("")
        }
    }
}

class ImageOverlay : NSObject, MKOverlay {
    let image: UIImage
    let boundingMapRect: MKMapRect
    let coordinate: CLLocationCoordinate2D
    
    init(image: UIImage, rect: MKMapRect) {
        self.image = image
        self.boundingMapRect = rect
        self.coordinate = CLLocationCoordinate2D(latitude: 40.3573, longitude: -74.6672)
    }
}

class ImageOverlayRenderer : MKOverlayRenderer {
    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        guard let overlay = self.overlay as? ImageOverlay else {
            return
        }
        
        let rect = self.rect(for: overlay.boundingMapRect)
        UIGraphicsPushContext(context)
        overlay.image.draw(in: rect)
        UIGraphicsPopContext()
    }
}

extension MapViewController: MKMapViewDelegate {

//    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
//        guard let annotation = annotation as? IntersectionMapMarker else { return nil }
//        let identifier = "marker"
//        var view: MKMarkerAnnotationView
//        if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
//            as? MKMarkerAnnotationView {
//            dequeuedView.annotation = annotation
//            view = dequeuedView
//        } else {
//            view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
//            view.canShowCallout = true
//            view.calloutOffset = CGPoint(x: -5, y: 5)
//            view.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
//        }
//        return view
//    }
}

extension MKMapView {
     func northEastCoordinate() -> CLLocationCoordinate2D {
          let nePoint = CGPoint(x: self.bounds.origin.x + self.bounds.size.width, y: self.bounds.origin.y)
          return self.convert(nePoint, toCoordinateFrom: self)
     }
     
     func southWestCoordinate() -> CLLocationCoordinate2D {
          let swPoint = CGPoint(x: self.bounds.origin.x, y: self.bounds.origin.y + self.bounds.size.height)
          return self.convert(swPoint, toCoordinateFrom: self)
     }
     func zoom() {
          let region = MKCoordinateRegionMakeWithDistance(userLocation.coordinate, 200000, 200000)
          setRegion(region, animated: true)
     }
     func checkSpan() {
          let rect = visibleMapRect
          let westMapPoint = MKMapPointMake(MKMapRectGetMinX(rect), MKMapRectGetMidY(rect))
          let eastMapPoint = MKMapPointMake(MKMapRectGetMaxX(rect), MKMapRectGetMidY(rect))
          
          let distanceInMeter = MKMetersBetweenMapPoints(westMapPoint, eastMapPoint)
          
          if distanceInMeter > 210000 {
               zoom()
          }
     }
}

extension UIColor {
     var redValue: CGFloat { return CIColor(color: self).red }
     var greenValue: CGFloat { return CIColor(color: self).green }
     var blueValue: CGFloat { return CIColor(color: self).blue }
     var alphaValue: CGFloat { return CIColor(color: self).alpha }
}
