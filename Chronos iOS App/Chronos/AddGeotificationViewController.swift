

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

  @IBOutlet var addButton: UIBarButtonItem!
  @IBOutlet var zoomButton: UIBarButtonItem!
  @IBOutlet weak var mapView: MKMapView!

  @IBOutlet weak var searchBarView: UIView!
    
    
    
  var DynamicView=UIView(frame: CGRect(100, 200, 100, 100))
  DynamicView.backgroundColor=UIColor.green
  DynamicView.layer.cornerRadius=25
  DynamicView.layer.borderWidth=2
  self.view.addSubview(DynamicView)
  


  var delegate: AddGeotificationsViewControllerDelegate?
  var resultSearchController: UISearchController! = nil
  var selectedPin: MKPlacemark?

  override func viewDidLoad() {
    super.viewDidLoad()
    addButton.accessibilityElementsHidden = true
    zoomButton.accessibilityElementsHidden = true
//    navigationItem.rightBarButtonItems = [addButton, zoomButton]
    
    let locationSearchTable = storyboard!.instantiateViewController(withIdentifier: "LocationSearchTable") as! LocationSearchTable
    resultSearchController = UISearchController(searchResultsController: locationSearchTable)
    resultSearchController.searchResultsUpdater = locationSearchTable
    let searchBar = resultSearchController!.searchBar
    searchBar.sizeToFit()
    searchBar.placeholder = "Search for home address"
//    navigationItem.titleView = resultSearchController?.searchBar
    searchBarView.addSubview((resultSearchController?.searchBar)!)
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
