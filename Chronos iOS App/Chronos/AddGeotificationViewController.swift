
//
//  AddGeotificationViewController.swift
//  Chronos
//
//  Created by David Wallach on 5/16/17.
//  Copyright © 2017 David Wallach. All rights reserved.
//


import UIKit
import MapKit

protocol AddGeotificationsViewControllerDelegate {
  func addGeotificationViewController(controller: AddGeotificationViewController, didAddCoordinate coordinate: CLLocationCoordinate2D,
    radius: Double, identifier: String, note: String)
}

protocol HandleMapSearch: class {
  func dropPinZoomIn(_ placemark:MKPlacemark)
}

class AddGeotificationViewController: UITableViewController {

  @IBOutlet weak var mapView: MKMapView!

    
  var delegate: AddGeotificationsViewControllerDelegate?
  var resultSearchController: UISearchController! = nil
  var selectedPin: MKPlacemark?
    
    // images
    @IBOutlet weak var pref_sleep_hrs_img: UIImageView!
    @IBOutlet weak var max_wakeup_img: UIImageView!
    @IBOutlet weak var min_prep_img: UIImageView!
    @IBOutlet weak var pref_prep_img: UIImageView!
    
    
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let screenSize: CGRect = UIScreen.main.bounds
    let screenWidth = screenSize.width
    let DynamicView = UIView()
    DynamicView.frame = CGRect(x: 0, y: 0, width: screenWidth, height: 50)
    self.view.addSubview(DynamicView)
    
    let locationSearchTable = storyboard!.instantiateViewController(withIdentifier: "LocationSearchTable") as! LocationSearchTable
    resultSearchController = UISearchController(searchResultsController: locationSearchTable)
    resultSearchController.searchResultsUpdater = locationSearchTable
    let searchBar = resultSearchController!.searchBar
    searchBar.barTintColor = UIColor.white
    searchBar.sizeToFit()
    searchBar.placeholder = "Search for home address"
    DynamicView.addSubview((resultSearchController?.searchBar)!)
    resultSearchController.hidesNavigationBarDuringPresentation = false
    resultSearchController.dimsBackgroundDuringPresentation = true
    definesPresentationContext = true
    locationSearchTable.mapView = mapView
    locationSearchTable.handleMapSearchDelegate = self
    setImgs()
  }
    override func viewDidAppear(_ animated: Bool) {
        setImgs()
    }

    func setImgs() {
        if userPreferences.sharedInstance.prefered_sleep_hrs != "none" {
            pref_sleep_hrs_img.image = #imageLiteral(resourceName: "check-1-icon")
        } else { pref_sleep_hrs_img.image = #imageLiteral(resourceName: "x-icon@x1") }
        if userPreferences.sharedInstance.max_wakeup_time != "none" {
            max_wakeup_img.image = #imageLiteral(resourceName: "check-1-icon")
        } else { max_wakeup_img.image = #imageLiteral(resourceName: "x-icon@x1") }
        if userPreferences.sharedInstance.min_preptime != "none" {
            min_prep_img.image = #imageLiteral(resourceName: "check-1-icon")
        } else { min_prep_img.image = #imageLiteral(resourceName: "x-icon@x1") }
        if userPreferences.sharedInstance.prefered_preptime != "none" {
            pref_prep_img.image = #imageLiteral(resourceName: "check-1-icon")
        } else { pref_prep_img.image = #imageLiteral(resourceName: "x-icon@x1") }
    }
    
  @IBAction func onCancel(sender: AnyObject) {
    dismiss(animated: true, completion: nil)
  }

  @IBAction private func onAdd(sender: AnyObject) {
    let coordinate = mapView.centerCoordinate
    let radius = 10.0
    let identifier = NSUUID().uuidString
    let note = "Home"
    delegate?.addGeotificationViewController(controller: self, didAddCoordinate: coordinate, radius: radius, identifier: identifier, note: note)
  }
 
  @IBAction func UploadToCloud(_ sender: Any) {
        let dict = ["prefered_sleep_hrs": userPreferences.sharedInstance.prefered_sleep_hrs,
                    "prefered_preptime": userPreferences.sharedInstance.prefered_preptime,
                    "min_preptime": userPreferences.sharedInstance.min_preptime,
                    "max_wakeup_time": userPreferences.sharedInstance.max_wakeup_time
                    ] as [String: Any]
    
//        if let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted) {
    
            let port = userPreferences.sharedInstance.current_port
//            let url = NSURL(string: port+"/Prefs")!
//            let request = NSMutableURLRequest(url: url as URL)
            var request = URLRequest(url: URL(string: port + "/Prefs/")!)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            request.httpBody =  try! JSONSerialization.data(withJSONObject: dict, options: [])
            
            URLSession.shared.dataTask(with:request, completionHandler: {(data, response, error) in
                if error != nil {
                    print(error)
                } else {
                    do {
                        guard let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? [String: Any] else { return }
                        
                        guard let errors = json?["errors"] as? [[String: Any]] else { return }
                        if errors.count > 0 {
                            // show error
                            return
                        } else {
                            // show confirmation
                        }
                    }
                }
            }).resume()
    
//            let task = URLSession.shared.dataTask(with: request as URLRequest){ data,response,error in
//                if error != nil{
//                    print(error?.localizedDescription)
//                    return
//                }
//    
//                do {
//                    let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? NSDictionary
//    
//                    if let parseJSON = json {
//                        let resultValue:String = parseJSON["success"] as! String;
//                        print("result: \(resultValue)")
//                        print(parseJSON)
//                        }
//                    } catch let error as NSError {
//                        print(error)
//                    }
//                }
//                task.resume()
//            }
         dismiss(animated: true, completion: nil)
    }

  private func onZoomToCurrentLocation(sender: AnyObject) {
    mapView.zoomToUserLocation()
  }
    
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    
        switch segue.identifier! {
        case "prefered_sleep_hrs":
            userPreferences.sharedInstance.state = "prefered_sleep_hrs"
            break
        case "max_wakeup_time":
            userPreferences.sharedInstance.state = "max_wakeup_time"
            break
        case "prefered_preptime":
            userPreferences.sharedInstance.state =  "prefered_preptime"
            break
        case "min_prep_time":
            userPreferences.sharedInstance.state = "min_prep_time"
            break
        default:
            return
        }
    }
}

extension AddGeotificationViewController: HandleMapSearch {
  
  func dropPinZoomIn(_ placemark: MKPlacemark){
    // cache the pin
    selectedPin = placemark
    // clear existing pins
    mapView.removeAnnotations(mapView.annotations)
    let annotation = MKPointAnnotation()
    annotation.coordinate = placemark.coordinate
    annotation.title = placemark.name
    
    if let city = placemark.locality,
      let state = placemark.administrativeArea {
      annotation.subtitle = "\(city) \(state)"
    }
    
    mapView.addAnnotation(annotation)
    let span = MKCoordinateSpanMake(0.05, 0.05)
    let region = MKCoordinateRegionMake(placemark.coordinate, span)
    mapView.setRegion(region, animated: true)
  }
  
}

extension AddGeotificationViewController : MKMapViewDelegate {
  
  func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView?{
    
    guard !(annotation is MKUserLocation) else { return nil }
    let reuseId = "pin"
    var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
    if pinView == nil {
      pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
    }
    pinView?.pinTintColor = UIColor.orange
    pinView?.canShowCallout = true

    return pinView
  }
}
