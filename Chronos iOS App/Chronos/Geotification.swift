
import UIKit
import MapKit
import CoreLocation

struct CoordKey {
  static let latitude = "latitude"
  static let longitude = "longitude"
  static let radius = "radius"
  static let identifier = "identifier"
  static let note = "note"
}


class Geotification: NSObject, NSCoding, MKAnnotation {
  
  var coordinate: CLLocationCoordinate2D
  var radius: CLLocationDistance
  var identifier: String
  var note: String

  let title: String? = "Home"

  
  init(coordinate: CLLocationCoordinate2D, radius: CLLocationDistance, identifier: String, note: String){//, eventType: EventType) {
    self.coordinate = coordinate
    self.radius = radius
    self.identifier = identifier
    self.note = note
  }
  
  // MARK: NSCoding
  required init?(coder decoder: NSCoder) {
    let latitude = decoder.decodeDouble(forKey: CoordKey.latitude)
    let longitude = decoder.decodeDouble(forKey: CoordKey.longitude)
    coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    radius = decoder.decodeDouble(forKey: CoordKey.radius)
    identifier = decoder.decodeObject(forKey: CoordKey.identifier) as! String
    note = decoder.decodeObject(forKey: CoordKey.note) as! String
  }
  
  func encode(with coder: NSCoder) {
    coder.encode(coordinate.latitude, forKey: CoordKey.latitude)
    coder.encode(coordinate.longitude, forKey: CoordKey.longitude)
    coder.encode(radius, forKey: CoordKey.radius)
    coder.encode(identifier, forKey: CoordKey.identifier)
    coder.encode(note, forKey: CoordKey.note)
  }
  
}
