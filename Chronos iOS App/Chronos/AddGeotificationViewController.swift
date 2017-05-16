
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
    
  // self.datePicker.datePickerMode = .Time

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
//    searchBar.layer.borderColor = UIColor.blue.cgColor
    searchBar.barTintColor = UIColor.white
//    searchBar.barStyle = UIBarStyle.blackTranslucent
//    searchBar.layer.cornerRadius = 3.0
//    searchBar.clipsToBounds = true as! Bool
//    searchBar.layer.borderWidth = 1
    searchBar.sizeToFit()
    searchBar.placeholder = "Search for home address"
    DynamicView.addSubview((resultSearchController?.searchBar)!)
    resultSearchController.hidesNavigationBarDuringPresentation = false
    resultSearchController.dimsBackgroundDuringPresentation = true
    definesPresentationContext = true
    locationSearchTable.mapView = mapView
    locationSearchTable.handleMapSearchDelegate = self
    
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

  @IBAction private func onZoomToCurrentLocation(sender: AnyObject) {
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
