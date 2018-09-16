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
import Alamofire
import Foundation
import AlamofireImage
import ReplayKit

class ViewController: UIViewController, CLLocationManagerDelegate, RPPreviewViewControllerDelegate, MapViewDelegate {
    
    // dictionary of intersections with intersection coordinates as key and Intersection object as value
    var dictionary: [String: Intersection] = [:]
    
    var mapViewController: MapViewController?
    var webViewController = WebViewController()
    
    // for decoding the JSON for the nearestIntersections API
    private var intersections: [IntersectingStreets] = []
    
    // variable to hold the current mode; air quality mode by default
    private var mode = "air quality mode"
    
    // label for information about the intersection
    var label = UILabel()
    
    var currentInfo = UILabel()
    
    // switch to hide or show buttons
    // let hideButtons = UISwitch()
    
    private var isRecording = false
    let recorder = RPScreenRecorder.shared()
    var cameraImageScaled = UIImage()
    var shadedCameraImageScaled = UIImage()
    
    var tempImageScaled = UIImage()
    var shadedTempImageScaled = UIImage()
    var humImageScaled = UIImage()
    var shadedHumImageScaled = UIImage()
    var mapImageScaled = UIImage()
    var shadedMapImageScaled = UIImage()
    var aqiImageScaled = UIImage()
    var shadedAqiImageScaled = UIImage()
    
    // buttons for the different modes
    let tempButton = UIButton(type: UIButtonType.custom)
    let aqiButton = UIButton(type: UIButtonType.custom)
    let humButton = UIButton(type: UIButtonType.custom)
    let cameraButton = UIButton(type: UIButtonType.custom)
    let mapButton = UIButton(type: UIButtonType.custom)
    let infoButton = UIButton(type: UIButtonType.custom)
    
    // set up the images for the buttons
    let tempImage = UIImage(named: "temp")
    let shadedTempImage = UIImage(named: "temp shaded")
    let aqiImage = UIImage(named: "aqi")
    let shadedAqiImage = UIImage(named: "aqi shaded")
    let humImage = UIImage(named: "hum")
    let shadedHumImage = UIImage(named: "hum shaded")
    let cameraImage = UIImage(named: "camera")
    let shadedCameraImage = UIImage(named: "cam shaded")
    let mapImage = UIImage(named: "map")
    let shadedMapImage = UIImage(named: "map shaded")
    let infoImage = UIImage(named: "information")
    
    // elapsed time
    var start = Date()
    
    // Holds the coordinates of the centers of the grid
    var centers = [CLLocationCoordinate2D]()
    
    var temp: [[Double]]?
    var aqi: [[Double]]?
    var hum: [[Double]]?
    var temp1D = [Double]()
    var aqi1D = [Double]()
    var hum1D = [Double]()
    
    var locationManager: CLLocationManager!
    var sceneLocationView = SceneLocationView()
    let dataHelper = FetchingDataHelper()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // fetch the Firebase data
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
            
            self.addNearestIntersectionsHelper()
        }
        
        task.resume()
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.rotated), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
    
        initLocationManager()
        
        mapButton.isEnabled = false

        // set up label for the information about the intersection
        label.font = UIFont.systemFont(ofSize: 14)
        label.textAlignment = .left
        label.textColor = UIColor.white
        label.numberOfLines = 4
        label.translatesAutoresizingMaskIntoConstraints = false
        sceneLocationView.addSubview(label)
        label.layer.masksToBounds = true;
        // label.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.25)
        sceneLocationView.addConstraint(NSLayoutConstraint(item: label, attribute: .bottom, relatedBy: .equal, toItem: sceneLocationView, attribute: .bottom, multiplier: 1, constant: -10))
        sceneLocationView.addConstraint(NSLayoutConstraint(item: label, attribute: .leading, relatedBy: .equal, toItem: sceneLocationView, attribute: .leading, multiplier: 1, constant: 20))
        
        // set up buttons for the different modes
        tempButton.setTitle("temp", for: [])
        aqiButton.setTitle("AQI", for: [])
        humButton.setTitle("hum", for: [])
        cameraButton.setTitle("cam", for: [])
        mapButton.setTitle("map", for: [])
        infoButton.setTitle("info", for: [])
        
        // set up the currentInfo label
        currentInfo.text = ""
        currentInfo.textColor = UIColor.white
        sceneLocationView.addSubview(currentInfo)
        currentInfo.translatesAutoresizingMaskIntoConstraints = false
        sceneLocationView.addConstraint(NSLayoutConstraint(item: currentInfo, attribute: .top, relatedBy: .equal, toItem: sceneLocationView, attribute: .top, multiplier: 1, constant: 20))
        sceneLocationView.addConstraint(NSLayoutConstraint(item: currentInfo, attribute: .centerX, relatedBy: .equal, toItem: sceneLocationView, attribute: .centerX, multiplier: 1, constant: 0))
        
        // hide the button titles clear
        tempButton.setTitleColor(UIColor.clear, for: [])
        aqiButton.setTitleColor(UIColor.clear, for: [])
        cameraButton.setTitleColor(UIColor.clear, for: [])
        humButton.setTitleColor(UIColor.clear, for: [])
        mapButton.setTitleColor(UIColor.clear, for: [])
        infoButton.setTitleColor(UIColor.clear, for: [])
        
        tempButton.showsTouchWhenHighlighted = true
        aqiButton.showsTouchWhenHighlighted = true
        cameraButton.showsTouchWhenHighlighted = true
        humButton.showsTouchWhenHighlighted = true
        mapButton.showsTouchWhenHighlighted = true
        infoButton.showsTouchWhenHighlighted = true
        
        // implement action for tapping on a button
        tempButton.addTarget(self, action: #selector(self.tapButton(_:)), for: .touchUpInside)
        aqiButton.addTarget(self, action: #selector(self.tapButton(_:)), for: .touchUpInside)
        humButton.addTarget(self, action: #selector(self.tapButton(_:)), for: .touchUpInside)
        cameraButton.addTarget(self, action: #selector(self.tapButton(_:)), for: .touchUpInside)
        mapButton.addTarget(self, action: #selector(self.tapButton(_:)), for: .touchUpInside)
        infoButton.addTarget(self, action: #selector(self.tapButton(_:)), for: .touchUpInside)
        
        // create a horizontal UI stack view for the buttons
        
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.addArrangedSubview(cameraButton)
        stackView.addArrangedSubview(mapButton)
        stackView.addArrangedSubview(aqiButton)
        stackView.addArrangedSubview(humButton)
        stackView.addArrangedSubview(tempButton)
        stackView.addArrangedSubview(infoButton)
        stackView.distribution = .fillEqually
        stackView.alignment = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        sceneLocationView.addSubview(stackView)
        
        // add constraints for the horizontal stack view
        sceneLocationView.addConstraint(NSLayoutConstraint(item: stackView, attribute: .trailing, relatedBy: .equal, toItem: sceneLocationView, attribute: .trailing, multiplier: 1, constant: 20))
        sceneLocationView.addConstraint(NSLayoutConstraint(item: stackView, attribute: .leading, relatedBy: .equal, toItem: sceneLocationView, attribute: .leading, multiplier: 1, constant: 20))
        sceneLocationView.addConstraint(NSLayoutConstraint(item: stackView, attribute: .top, relatedBy: .equal, toItem: sceneLocationView, attribute: .top, multiplier: 1, constant: 45))
        
        sceneLocationView.run()
        
        let singleTap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.handleSingleTap(_:)))
        singleTap.numberOfTapsRequired = 1
        singleTap.numberOfTouchesRequired = 1
        self.sceneLocationView.addGestureRecognizer(singleTap)
        
        self.sceneLocationView.isUserInteractionEnabled = true

        view.addSubview(sceneLocationView)
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
    
    func useFirebaseData() {
        
        createGrid(tempData: temp!, aqiData: aqi!, humData: hum!)
        
        for intersection in dictionary {
            let key = intersection.key.split(separator: " ")
            let coordinate = CLLocationCoordinate2D(latitude: Double(key[0])!, longitude: Double(key[1])!)
            
            var distance = Double.infinity
            
            var champion = 0
            
            for i in 0...centers.count-1 {
                let center = centers[i]
                if (coordinate.distance(from: center) < distance) {
                    // need to avoid the NaN values
                    if (temp![i / 80][i % 80] == -Double.infinity) {
                        continue
                    }
                    distance = coordinate.distance(from: center)
                    champion = i
                }
            }
            let i = champion / 80
            let j = champion % 80
            
            let intersection = intersection.value
            intersection.airQuality = round(aqi![i][j])
            intersection.humidity = round(hum![i][j] * 10) / 10
            intersection.temperature = round(temp![i][j] * 10) / 10
            // print(aqi![i][j], hum![i][j], temp![i][j])
        }
    }
    
    func decodeData(response: String) {
        let decoder = JSONDecoder()
        do {
            let correctedJsonStr = response.replacingOccurrences(of: "NaN", with: "-0.01")
            let decodedData = try decoder.decode(FirebaseData.self, from: correctedJsonStr.data(using: .utf8)!)
            
            let processed = decodedData.processed
            // let original = decodedData.original
            
            temp = processed.temp
            hum = processed.hum
            aqi = processed.P25
            
            let n = 80
            
            for i in 0...temp!.count-1 {
                for j in 0...temp!.count-1 {
                    if temp![i][j] == -0.01 {
                        temp![i][j] = -Double.infinity
                        hum![i][j] = -Double.infinity
                        aqi![i][j] = -Double.infinity
                    }
                    temp![i][j] = (temp![i][j] * 9/5) + 32
                    aqi![i][j] = (AQIPM25(dustVal: aqi![i][j]))
                }
            }
            
            for i in 0...n-1 {
                for j in 0...n-1 {
                    if (aqi![i][j] != -Double.infinity) {
                        aqi1D.append(aqi![i][j])
                        temp1D.append(temp![i][j])
                        hum1D.append(hum![i][j])
                    }
                }
                // print(aqi1D)
            }
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
    
    func createGrid(tempData: [[Double]], aqiData: [[Double]], humData: [[Double]]) {
        
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
                
                let center = CLLocationCoordinate2D(latitude: south + (north - south) / 2, longitude: west + (east - west) / 2)
                
                centers.append(center)
                
                north = south
            }
            north = mapBounds.north
            east = west
        }
        centers.reverse()
    }
    
    func setUpButtons(size: CGSize) {
        
        // scale the images for the buttons
        tempImageScaled = tempImage!.af_imageAspectScaled(toFit: size)
        shadedTempImageScaled = shadedTempImage!.af_imageAspectScaled(toFit: size)
        humImageScaled = humImage!.af_imageAspectScaled(toFit: size)
        shadedHumImageScaled = shadedHumImage!.af_imageAspectScaled(toFit: size)
        cameraImageScaled = cameraImage!.af_imageAspectScaled(toFit: size)
        shadedCameraImageScaled = shadedCameraImage!.af_imageAspectScaled(toFit: size)
        mapImageScaled = mapImage!.af_imageAspectScaled(toFit: size)
        shadedMapImageScaled = shadedMapImage!.af_imageAspectScaled(toFit: size)
        aqiImageScaled = aqiImage!.af_imageAspectScaled(toFit: size)
        shadedAqiImageScaled = shadedAqiImage!.af_imageAspectScaled(toFit: size)
        let infoImageScaled = infoImage!.af_imageScaled(to: size)
        
        // turn the scaled images into buttons        
        tempButton.setImage(tempImageScaled, for: [])
        aqiButton.setImage(aqiImageScaled, for: [])
        humButton.setImage(humImageScaled, for: [])
        cameraButton.setImage(cameraImageScaled, for: [])
        mapButton.setImage(mapImageScaled, for: [])
        infoButton.setImage(infoImageScaled, for: [])
    
    }
    
    func degreesToRadians(degrees: Double) -> Double { return degrees * .pi / 180.0 }
    func radiansToDegrees(radians: Double) -> Double { return radians * 180.0 / .pi }
    
    func getBearingBetweenTwoPoints(point1 : CLLocation, point2 : CLLocation) -> Double {
        
        let lat1 = degreesToRadians(degrees: point1.coordinate.latitude)
        let lon1 = degreesToRadians(degrees: point1.coordinate.longitude)
        
        let lat2 = degreesToRadians(degrees: point2.coordinate.latitude)
        let lon2 = degreesToRadians(degrees: point2.coordinate.longitude)
        
        let dLon = lon2 - lon1
        
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let radiansBearing = atan2(y, x)
        
        return radiansToDegrees(radians: radiansBearing)
    }
    
    // Citation: https://stackoverflow.com/questions/26998029/calculating-bearing-between-two-cllocation-points-in-swift
    
    func addNavigationToScene(coordinates: [CLLocationCoordinate2D], steps: [MKRouteStep]) {
        // Needs to be implemented. //
    }
    
    // change the size of the buttons based on the rotation
    @objc func rotated() {
        if UIDevice.current.orientation.isLandscape {
            print("Landscape")
            // change the size of the buttons, 60x60
            setUpButtons(size: CGSize(width: 60.0, height: 60.0))
        } else {
            print("Portrait")
            // change the size of the buttons, 40x40 or 50x50
            setUpButtons(size: CGSize(width: 40.0, height: 40.0))
        }
    }
    
    @objc func tapButton(_ sender: UIButton) {
        
        switch sender {
        case tempButton:
            mode = "temperature mode"
            updateAnnotationInfo()
            tempButton.setImage(shadedTempImageScaled, for: [])
            aqiButton.setImage(aqiImageScaled, for: [])
            humButton.setImage(humImageScaled, for: [])
        case mapButton:
            mode = "map mode"
            if let mapView = mapViewController {
                mapView.delegate = self
                self.present(mapView, animated: true, completion: nil)
                mapView.dictionary = dictionary
                if let userLocation = locationManager.location {
                mapView.currentLocation = userLocation.coordinate
                }
            }
            print("map mode")
        case humButton:
            mode = "humidity mode"
            updateAnnotationInfo()
            tempButton.setImage(tempImageScaled, for: [])
            aqiButton.setImage(aqiImageScaled, for: [])
            humButton.setImage(shadedHumImageScaled, for: [])
        case cameraButton:
            if isRecording == false {
                cameraButton.setImage(shadedCameraImageScaled, for: .normal)
                startRecording()
            }
            else {
                stopRecording()
            }
            print("recording footage of AR view")
        case aqiButton:
            mode = "air quality mode"
            updateAnnotationInfo()
            tempButton.setImage(tempImageScaled, for: [])
            aqiButton.setImage(shadedAqiImageScaled, for: [])
            humButton.setImage(humImageScaled, for: [])
        case infoButton:
            print("info mode")
                // webViewController.delegate = self
                self.present(webViewController, animated: true, completion: nil)
        default:
            print("")
        }
    }
    
    // start recording
    func startRecording() {
        guard recorder.isAvailable else {
            print("Recording is not available at this time.")
            return
        }
        
        recorder.startRecording { [unowned self] (error) in
            
            guard error == nil else {
                print("There was an error starting the recording.")
                return
            }
            
            print("Started Recording Successfully")
            // self.micToggle.isEnabled = false
            self.isRecording = true
        }
    }
    
    // save footage and stop recording
    func stopRecording() {
        
        // call function to stop recording
        recorder.stopRecording { [unowned self] (preview, error) in
            print("Stopped recording")
            
            guard preview != nil else {
                print("Preview controller is not available.")
                return
            }
            
            let alert = UIAlertController(title: "Recording Finished", message: "Would you like to edit or delete your recording?", preferredStyle: .alert)
            
            let deleteAction = UIAlertAction(title: "Delete", style: .destructive, handler: { (action: UIAlertAction) in
                self.recorder.discardRecording(handler: { () -> Void in
                    print("Recording deleted.")
                })
            })
            
            let editAction = UIAlertAction(title: "Edit", style: .default, handler: { (action: UIAlertAction) -> Void in
                preview?.previewControllerDelegate = self
                self.present(preview!, animated: true, completion: nil)
            })
            
            alert.addAction(editAction)
            alert.addAction(deleteAction)
            self.present(alert, animated: true, completion: nil)
            
            self.isRecording = false
            self.cameraButton.setImage(self.cameraImageScaled, for: [])
            
        }
    }
    
    // dismisses the preview controller after user edits the footage
    func previewControllerDidFinish(_ previewController: RPPreviewViewController) {
        dismiss(animated: true)
    }

    // determines the color of the text based on the parameter
    func pickColor(parameter: Double) -> UIColor {
        let color: UIColor
        switch mode {
        case "air quality mode":
        if parameter < 51.0 {
            // color = UIColor.green
            color = UIColor(red: (76/255.0), green: (217/255.0), blue: (100/255.0), alpha: 1.0)
        }
        else if parameter < 101.0 {
            // color = UIColor.yellow
            color = UIColor(red: (255/255.0), green: (204/255.0), blue: (0/255.0), alpha: 1.0)
        }
        else if parameter < 151.0 {
            // color = UIColor.orange
            color = UIColor(red: (255/255.0), green: (149/255.0), blue: (0/255.0), alpha: 1.0)
        }
        else if parameter < 201.0 {
            color = UIColor(red: (255/255.0), green: (59/255.0), blue: (48/255.0), alpha: 1.0)
            // color = UIColor.red
        }
        else if parameter < 301.0 {
            // color = UIColor.purple
            color = UIColor(red: (88/255.0), green: (86/255.0), blue: (214/255.0), alpha: 1.0)
        }
        else {
            // maroon color
            color = UIColor(red: (128/255.0), green: (0/255.0), blue: (0/255.0), alpha: 1.0)
        }
        case "temperature mode":
            if parameter < 25 {
                // color = UIColor.purple
                color = UIColor(red: (88/255.0), green: (86/255.0), blue: (214/255.0), alpha: 1.0)
            }
            else if parameter < 50 {
                // color = UIColor.blue
                color = UIColor(red: (0/255.0), green: (122/255.0), blue: (255/255.0), alpha: 1.0)
            }
            else if parameter < 75 {
                // yellow
                color = UIColor(red: (255/255.0), green: (204/255.0), blue: (0/255.0), alpha: 1.0)
            }
            else if parameter < 100 {
                // orange
                color = UIColor(red: (255/255.0), green: (149/255.0), blue: (0/255.0), alpha: 1.0)
            }
            else {
                color = UIColor(red: (255/255.0), green: (59/255.0), blue: (48/255.0), alpha: 1.0)
                // color = UIColor.red
            }
        case "humidity mode":
            if parameter < 25 {
                // 0-191-255
                color = UIColor(red: (197/255.0), green: (239/255.0), blue: (247/255.0), alpha: 1.0)
            }
            else if parameter < 50 {
                color = UIColor(red: (30/255.0), green: (144/255.0), blue: (255/255.0), alpha: 1.0)
            }
            else if parameter < 75 {
                color = UIColor(red: (0/255.0), green: (122/255.0), blue: (255/255.0), alpha: 1.0)
            }
            else {
                color = UIColor(red: (31/255.0), green: (58/255.0), blue: (147/255.0), alpha: 1.0)
            }
        default:
            color = UIColor.white
    }
        return color
}
    
    // updates annotations when the mode changes
    func updateAnnotationInfo() {
        sceneLocationView.scene.rootNode.enumerateChildNodes { (node, stop) in
            if let annotationNode = node as? LocationAnnotationNode {
                let intersection = dictionary[annotationNode.name!]!
                let newLabel = intersection.label!
                if mode == "temperature mode" {
                    var color = pickColor(parameter: intersection.temperature!)
                    color = numberToColor(value: intersection.temperature!, min: temp1D.min()!, max: temp1D.max()!, gradientColors: [UIColor.green, UIColor.yellow, UIColor.orange, UIColor.red])
                    newLabel.backgroundColor = color.withAlphaComponent(0.75)
                     newLabel.text = "\(intersection.name!)\n\(intersection.temperature!)°F"
                    let attributes = [NSAttributedStringKey.font : UIFont.boldSystemFont(ofSize: 22)]
                    let string1 = NSMutableAttributedString(string: "\(intersection.name!)\n")
                    let string2 = NSMutableAttributedString(string:"\(intersection.temperature!)°F", attributes: attributes)
                    string1.append(string2)
                    newLabel.attributedText! = string1
                }
                else if mode == "humidity mode" {
                    var color = pickColor(parameter: intersection.humidity!)
                    color = numberToColor(value: intersection.humidity!, min: hum1D.min()!, max: hum1D.max()!, gradientColors: [UIColor.green, UIColor.yellow, UIColor.orange, UIColor.red])
                    newLabel.backgroundColor = color.withAlphaComponent(0.75)
                    // newLabel.text = "\(intersection.name!)\n\(intersection.humidity!)%"
                    let attributes = [NSAttributedStringKey.font : UIFont.boldSystemFont(ofSize: 22)]
                    let string1 = NSMutableAttributedString(string: "\(intersection.name!)\n")
                    let string2 = NSMutableAttributedString(string:"\(intersection.humidity!)%", attributes: attributes)
                    string1.append(string2)
                    newLabel.attributedText! = string1
                }
                else {
                    var color = pickColor(parameter: intersection.airQuality!)
                    color = numberToColor(value: intersection.airQuality!, min: aqi1D.min()!, max: aqi1D.max()!, gradientColors: [UIColor.green, UIColor.yellow, UIColor.orange, UIColor.red])
                    newLabel.backgroundColor = color.withAlphaComponent(0.75)
                    // newLabel.text = "\(intersection.name!)\n\(intersection.airQuality!)/500"
                    let attributes = [NSAttributedStringKey.font : UIFont.boldSystemFont(ofSize: 22)]
                    let string1 = NSMutableAttributedString(string: "\(intersection.name!)\n")
                    let string2 = NSMutableAttributedString(string:"\(intersection.airQuality!)/500", attributes: attributes)
                    string1.append(string2)
                    newLabel.attributedText! = string1
                    
                }
                UIGraphicsBeginImageContextWithOptions(newLabel.bounds.size, false, 0)
                newLabel.drawHierarchy(in: newLabel.bounds, afterScreenUpdates: true)
                let newImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                let newAnnotationNode = LocationAnnotationNode(location: annotationNode.location!, image: newImage!)
                // name the LocationAnnotationNode with the name of the intersection
                newAnnotationNode.name = annotationNode.name!
                // newAnnotationNode.scaleRelativeToDistance = true
                self.sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: newAnnotationNode)
                annotationNode.removeFromParentNode()
            }
        }
    }
    
    func addNearestIntersectionsHelper() {
        
        let userLocation: CLLocation? = locationManager.location
        loadNearestIntersections() { listOfIntersections in
            let array = listOfIntersections
            for index in 0...array.count-1 {
                let street1 = array[index].street1
                let street2 = array[index].street2
                let latitude = Double(array[index].lat)!
                let longitude = Double(array[index].lng)!
                var streetName = "\(street1)-\(street2)"
                streetName = streetName.replacingOccurrences(of: "Street", with: "St.")
                streetName = streetName.replacingOccurrences(of: "Avenue", with: "Ave.")
                streetName = streetName.replacingOccurrences(of: "Lane", with: "Ln.")
                var distance = Double(array[index].distance)!
                let coordinateString = "\(latitude) \(longitude)"
                if userLocation != nil {
                    distance = userLocation!.distance(from: CLLocation(latitude: latitude, longitude: longitude)) / 1000
                    distance = Double(floor(100*distance)/100)
                }
                let coordinates = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                self.dictionary[coordinateString] = Intersection(name: streetName, coordinate: coordinates, distance: distance)
            }
            
            // call Firebase data
            // if Firebase data does not exist, call the APIs
            if self.temp != nil {
                self.useFirebaseData()
                self.addIntersectionsToScene(dictionary: self.dictionary)
            }
            else {
            print("no Firebase data")
            var count = 0
            for (_, intersection) in self.dictionary {
                let coordinates = intersection.returnCoordinate()
                let latitude = coordinates.latitude
                let longitude = coordinates.longitude
                self.dataHelper.getElevation(latitude: latitude, longitude: longitude) { response in
                    intersection.elevation = response
                    self.dataHelper.getAQI(latitude: latitude, longitude: longitude) { response in
                        intersection.airQuality = response
                        self.dataHelper.getWeather(latitude: latitude, longitude: longitude) { humidity, temperature  in
                            intersection.humidity = humidity
                            intersection.temperature = temperature
                            count = count + 1
                            // call function to add the annotations to the scene
                            if count == self.dictionary.count {
                                // dictionary is complete, add annotations to scene
                                self.addIntersectionsToScene(dictionary: self.dictionary)
                            }
                        }
                    }
                }
            }
        }
    }
}
    
    func addIntersectionsToScene(dictionary: [String: Intersection]) {
        
        for (_, intersection) in dictionary {
            
            let coordinates = intersection.returnCoordinate()
            let latitude = coordinates.latitude
            let longitude = coordinates.longitude
            var elevation = intersection.elevation
            // let elevation = locationManager.location?.altitude
            if elevation == nil {
                elevation = locationManager.location?.altitude
            }
            let location = CLLocation(coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude), altitude: elevation! - 9.0)
            let streetName = intersection.name!
            print(streetName)
            
            self.mapButton.isEnabled = true
        
            let annotation = UILabel(frame: CGRect(origin: .zero, size: CGSize(width: 180, height: 60)))
            intersection.label = annotation
            annotation.numberOfLines = 4
            annotation.layer.cornerRadius = 4;
            annotation.layer.masksToBounds = true
            annotation.adjustsFontSizeToFitWidth = true
            // annotation.text = "\(streetName)\n \(intersection.airQuality!)/500"
            
            let attributes = [NSAttributedStringKey.font : UIFont.boldSystemFont(ofSize: 22)]
            let string1 = NSMutableAttributedString(string: "\(streetName)\n")
            if intersection.airQuality == nil {
                intersection.airQuality = 34.0
            }
            let string2 = NSMutableAttributedString(string:"\(intersection.airQuality!)/500", attributes: attributes)
            string1.append(string2)
            annotation.attributedText = string1
            
//            var processedData = [Double]()
//
//            let n = 80
//
//            for i in 0...n-1 {
//                for j in 0...n-1 {
//                    if (aqi![i][j] != -Double.infinity) {
//                        processedData.append(aqi![i][j])
//                    }
//                }
//            }
            
            // annotation.backgroundColor = pickColor(parameter: intersection.airQuality!).withAlphaComponent(0.75)
            let color = numberToColor(value: intersection.airQuality!, min: aqi1D.min()!, max: aqi1D.max()!, gradientColors: [UIColor.green, UIColor.yellow, UIColor.orange, UIColor.red]).withAlphaComponent(0.75)
            annotation.backgroundColor = color
            annotation.textColor = UIColor.black.withAlphaComponent(0.8)
            annotation.textAlignment = .center
            // annotation.font = UIFont.boldSystemFont(ofSize: 14)
        
            UIGraphicsBeginImageContextWithOptions(annotation.bounds.size, false, 0)
            annotation.drawHierarchy(in: annotation.bounds, afterScreenUpdates: true)
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
        
            let annotationNode = LocationAnnotationNode(location: location, image: newImage!)
            // name the LocationAnnotationNode with the name of the intersection
            annotationNode.name = "\(latitude) \(longitude)"
            annotationNode.scaleRelativeToDistance = false
            self.sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: annotationNode)
            
            
            // update the currentInfo label
            let currentInfoAttributes = [NSAttributedStringKey.font: UIFont.boldSystemFont(ofSize: 14)]
            let aqiAttributes = [NSAttributedStringKey.font: UIFont.boldSystemFont(ofSize: 14), NSAttributedStringKey.foregroundColor: UIColor.green]
            let humAttributes = [NSAttributedStringKey.font: UIFont.boldSystemFont(ofSize: 14), NSAttributedStringKey.foregroundColor: UIColor.blue]
            let tempAttributes = [NSAttributedStringKey.font: UIFont.boldSystemFont(ofSize: 14), NSAttributedStringKey.foregroundColor: UIColor.orange]
            let currentInfoString = NSMutableAttributedString(string: "Current Info:  ", attributes: currentInfoAttributes)
            
            // change color of string based on condition
            var aqiString = NSMutableAttributedString(string: "Good", attributes: aqiAttributes)
            if intersection.airQuality! > 50.0 {
               aqiString = NSMutableAttributedString(string: "Moderate", attributes: aqiAttributes)
            }
            else if intersection.airQuality! > 100.0 {
                aqiString = NSMutableAttributedString(string: "Unhealthy for Sensitive Groups", attributes: aqiAttributes)
            }
            else if intersection.airQuality! > 150.0 {
                aqiString = NSMutableAttributedString(string: "Unhealthy", attributes: aqiAttributes)
            }
            else if intersection.airQuality! > 200.0 {
                aqiString = NSMutableAttributedString(string: "Very Unhealthy", attributes: aqiAttributes)
            }
            else if intersection.airQuality! > 300.0 {
                aqiString = NSMutableAttributedString(string: "Hazardous", attributes: aqiAttributes)
            }
            
            var temperature = 0.0
            var humidity = 0.0
            if intersection.temperature == nil {
                temperature = 74.0
            }
            else {
                temperature = intersection.temperature!
            }
            if intersection.humidity == nil {
                 humidity = 74.0
            }
            else {
                humidity = intersection.humidity!
            }
            let tempString = NSMutableAttributedString(string: "  \(temperature)°F", attributes: tempAttributes)
            let humString = NSMutableAttributedString(string: "  \(humidity)%", attributes: humAttributes)
            currentInfoString.append(aqiString)
            currentInfoString.append(tempString)
            currentInfoString.append(humString)
            currentInfo.attributedText = currentInfoString
        }
        mapViewController = MapViewController()
    }
    
    // initializes the location manager
    func initLocationManager() {
        locationManager = CLLocationManager()
        locationManager.requestAlwaysAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 100
        locationManager.delegate = self
        locationManager.startUpdatingLocation()
    }
    
    // updates the annotations in the AR view
    func locationManager(_: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Only have annotations removed and updated once every five minutes
        if start.timeIntervalSinceNow >= 300 {
            print("annotations in AR view updated")
        sceneLocationView.scene.rootNode.enumerateChildNodes { (node, stop) in
            // remove all the nodes in the sceneView
            node.removeFromParentNode()
    }
            dictionary.removeAll()
            addNearestIntersectionsHelper()
            // reset the elapsed time counter
            start = Date()
  }
}
    
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
    
    func locationManager(_: CLLocationManager, didFailWithError error: Error) {
        // tell user what went wrong and try again
        print("location of user cannot be fetched")
    }
    
    // function for recognizing whether a LocationAnnotationNode was tapped
    @objc func handleSingleTap(_ gestureRecognizer : UITapGestureRecognizer) {
        guard gestureRecognizer.view != nil else { return }
        
        let point = gestureRecognizer.location(in: sceneLocationView)
        let hitResults = sceneLocationView.hitTest(point, options: [:])
        label.isHidden = true
        
        // update camera button if necessary
        if isRecording == false {
            cameraButton.setImage(cameraImageScaled, for: [])
        }
        
        for hit in hitResults {
            if let pin = hit.node.parent as? LocationAnnotationNode {
                if gestureRecognizer.state == .ended {
                    let intersection = dictionary[pin.name!]!
                    label.text = "\(intersection.name!) \(intersection.distance! * 1000) m\nAQI: \(Int(intersection.airQuality!)) / 500 \nHumidity: \(intersection.humidity!)% \nTemperature: \(intersection.temperature!)°F"
                    label.font = UIFont.boldSystemFont(ofSize: 14)
                    label.isHidden = false
                    print(pin.name!)
                }
        }
    }
}
    // structures to decode the JSON for the nearest intersections
    struct IntersectingStreets: Decodable {
        let street1: String
        let street2: String
        let distance: String
        let lat: String
        let lng: String
    }
    
    struct RawServerResponse: Decodable {
        let intersection: [IntersectingStreets]
    }
    
    // uses the GeoNames API to load the nearest intersections
    func loadNearestIntersections(completion: @escaping ([IntersectingStreets]) -> Void) {
        
        // var count = 0
        
        // while count != 5 {
        
        let firstURL = "http://api.geonames.org/findNearestIntersectionOSMJSON?lat="
        let secondURL = "&maxRows=5&radius=1&username=tmathieu"
        let locationOfUser = locationManager.location
        
        var lat: Double = 0.0
        var lng: Double = 0.0

        if locationOfUser != nil, locationOfUser != nil {
           lat = locationOfUser!.coordinate.latitude
           lng = locationOfUser!.coordinate.longitude
        }
        else {
            // defaults to Princeton
            lat = 40.350373
            lng = -74.651603
        }
            
        let urlString = "\(firstURL)\(lat)&lng=\(lng)\(secondURL)"
    
        Alamofire.request(urlString).responseJSON { response in
            let json = response.data
            do {
                //created the json decoder
                let decoder = JSONDecoder()
                
                //using the array to put values
                let decodedData = try decoder.decode(RawServerResponse.self, from: json!)
                let array = decodedData.intersection
                completion(array)
            } catch let err {
                print("Error parsing the coordinates for the intersections.")
                print(err)
            }
        }
    // }
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

extension CLLocationCoordinate2D {
    //distance in meters, as explained in CLLoactionDistance definition
    func distance(from: CLLocationCoordinate2D) -> CLLocationDistance {
        let destination=CLLocation(latitude:from.latitude,longitude:from.longitude)
        return CLLocation(latitude: latitude, longitude: longitude).distance(from: destination)
    }
}
