
//
//  GeotificationsViewController.swift
//  Chronos
//
//  Created by David Wallach on 5/16/17.
//  Copyright © 2017 David Wallach. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

struct PreferencesKeys {
  static let savedItems = "savedItems"
}

class GeotificationsViewController: UIViewController {
  
  @IBOutlet weak var mapView: MKMapView!
    
  @IBOutlet weak var navigateButton: UIButton!
  @IBOutlet weak var homeButton: UIButton!
  @IBOutlet weak var settingsButton: UIButton!
  
  var homeLocation: Geotification? = nil
  var locationManager = CLLocationManager()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    locationManager.delegate = self
    locationManager.requestAlwaysAuthorization()
    locationManager.desiredAccuracy = kCLLocationAccuracyBest
    loadHomeLocation()
    mapView.zoomToUserLocation()
  }
    override func viewDidAppear(_ animated: Bool) {
         mapView.zoomToUserLocation()
    }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "addGeotification" {
      let navigationController = segue.destination as! UINavigationController
      let vc = navigationController.viewControllers.first as! AddGeotificationViewController
      vc.delegate = self
    }
  }
  
    
    @IBAction func navButtonTouched(_ sender: Any) {
        mapView.zoomToUserLocation()
    }
    
    @IBAction func settingsButtonTouched(_ sender: Any) {
        
    }
 
    @IBAction func homeButtonTouched(_ sender: Any) {
        if homeLocation == nil { return }
        var region = MKCoordinateRegion(center: (homeLocation?.coordinate)!, span: MKCoordinateSpan(latitudeDelta: 0.001, longitudeDelta: 0.001))
        region = mapView.regionThatFits(region)
        mapView.setRegion(region, animated: true)
    }
 
  // MARK: Loading and saving functions

  func loadHomeLocation() {
    guard let savedHomeLocation = UserDefaults.standard.data(forKey: PreferencesKeys.savedItems) else { return }
    guard let home = NSKeyedUnarchiver.unarchiveObject(with: savedHomeLocation ) as? Geotification else { return }
    homeLocation = home
    print("loading home... location is : \(String(describing: homeLocation?.coordinate))")
    addRadiusOverlay(forGeotification: homeLocation!)
    mapView.addAnnotation(homeLocation!)
    mapView.zoomToUserLocation()
  }
  
  func saveHomeLocation() {
    let home = NSKeyedArchiver.archivedData(withRootObject: homeLocation)
    UserDefaults.standard.set(home, forKey: PreferencesKeys.savedItems)
    print("saving home... location is : \(String(describing: homeLocation?.coordinate))")
  }
  
  // MARK: Functions that update the model/associated views with geotification changes
  
  func setHome(geotification: Geotification) {
    if homeLocation != nil {
      stopMonitoring(geotification: homeLocation!)
      mapView.removeOverlays(mapView.overlays)
    }
    homeLocation = geotification
    //remove current annotations
    self.mapView.annotations.forEach {
      if !($0 is MKUserLocation) {
        self.mapView.removeAnnotation($0)
      }
    }
    
    addRadiusOverlay(forGeotification: geotification)
    mapView.addAnnotation(geotification)
    print("home is now \(String(describing: homeLocation?.coordinate))")
  }
    
  func addRadiusOverlay(forGeotification geotification: Geotification) {
        mapView?.add(MKCircle(center: geotification.coordinate, radius: 20))
    }
    
  
  // MARK: Other mapview functions
  @IBAction func zoomToCurrentLocation(sender: AnyObject) {
    mapView.zoomToUserLocation()
  }
  
  func region(withGeotification geotification: Geotification) -> CLCircularRegion {
    let region = CLCircularRegion(center: geotification.coordinate, radius: geotification.radius, identifier: geotification.identifier)
    region.notifyOnEntry = true
    region.notifyOnExit = true
    return region
  }
  
  func startMonitoring(geotification: Geotification) {
    if !CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
      showAlert(withTitle:"Error", message: "Wally is unable to save home location is not supported on this device!")
      return
    }
  
    if CLLocationManager.authorizationStatus() != .authorizedAlways {
      showAlert(withTitle:"Warning", message: "Your home location is saved but will only be activated once you grant Wally permission to access the device location.")
    }
    let region = self.region(withGeotification: geotification)
    locationManager.startMonitoring(for: region)
  }
  
  func stopMonitoring(geotification: Geotification) {
   for region in locationManager.monitoredRegions {
      guard let circularRegion = region as? CLCircularRegion, circularRegion.identifier == geotification.identifier else { continue }
      locationManager.stopMonitoring(for: circularRegion)
    }
  }
}

// MARK: AddGeotificationViewControllerDelegate
extension GeotificationsViewController: AddGeotificationsViewControllerDelegate {
  
  func addGeotificationViewController(controller: AddGeotificationViewController, didAddCoordinate coordinate: CLLocationCoordinate2D, radius: Double, identifier: String, note: String) {
    print("in add func")
    controller.dismiss(animated: true, completion: nil)
    let clampedRadius = min(radius, locationManager.maximumRegionMonitoringDistance)
    let geotification = Geotification(coordinate: coordinate, radius: clampedRadius, identifier: identifier, note: note)
    setHome(geotification: geotification)
    startMonitoring(geotification: geotification)
    saveHomeLocation()
    
  }

}

// MARK: - Location Manager Delegate
extension GeotificationsViewController: CLLocationManagerDelegate {
  
  func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    mapView.showsUserLocation = status == .authorizedAlways
  }
  
  func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
    print("Monitoring failed for region with identifier: \(region!.identifier)")
  }
  
  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    print("Location Manager failed with the following error: \(error)")
  }

}

// MARK: - MapView Delegate
extension GeotificationsViewController: MKMapViewDelegate {
  
  func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
  
    //add new annotations
    let identifier = "myGeotification"
    if annotation is Geotification {
      var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
      if annotationView == nil {
        annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        annotationView?.canShowCallout = true
      } else {
        annotationView?.annotation = annotation
      }
      let image = UIImage(named: "home-icon-2")
//      let pinImage = image?.maskWithColor(color: UIColor.wallyGreen())
      UIGraphicsBeginImageContext(CGSize(width: 25, height: 25))
      image?.draw(in: CGRect(x: 0, y: 0, width: 25, height: 25))
      let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
      UIGraphicsEndImageContext()
        
      annotationView?.image = resizedImage
      return annotationView
    }
    return nil
  }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let overlay = overlay as? MKCircle {
            let circleRenderer = MKCircleRenderer(overlay: overlay)
            circleRenderer.lineWidth = 1.0
            circleRenderer.strokeColor = UIColor.blue
            circleRenderer.fillColor = UIColor.blue.withAlphaComponent(0.4)
            return circleRenderer
        }
        return MKOverlayRenderer(overlay: overlay)
    }
  
}
