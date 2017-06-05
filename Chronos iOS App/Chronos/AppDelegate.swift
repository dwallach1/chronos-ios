
import UIKit
import CoreLocation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
  
  var window: UIWindow?
  let locationManager = CLLocationManager()
  
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions:[UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
    locationManager.delegate = self
    locationManager.requestAlwaysAuthorization()
    application.registerUserNotificationSettings(UIUserNotificationSettings(types: [.sound, .alert, .badge], categories: nil))
    UIApplication.shared.cancelAllLocalNotifications()
//    UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    return true
  }
  
  func handleEvent(forRegion region: CLRegion!, home: Bool) {
    // Show an alert if application is active
    var status = "none"
    if home {
        status = "you are home"
    } else {
        status = "you are leaving"
    }

    if UIApplication.shared.applicationState == .active {
      window?.rootViewController?.showAlert(withTitle: nil, message: "Chronos says \(status)")
    } else {
      // Otherwise present a local notification
      let notification = UILocalNotification()
      notification.alertBody = "Chronos says \(status)"
      notification.soundName = "Default"
      UIApplication.shared.presentLocalNotificationNow(notification)
    }
    
    let port = userPreferences.sharedInstance.current_port
    var x = -1;
    if home {  x = 1 }
    else { x = 0 }

    var request = URLRequest(url: URL(string: port+"/Run?status=\(x)")!)
    request.httpMethod = "POST"
    let session = URLSession.shared
    
    session.dataTask(with: request) {data, response, err in
        print("Entered the completionHandler")
        }.resume()
    
    }
  
  
}

extension AppDelegate: CLLocationManagerDelegate {
  
  //  user entered home
  func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
    if region is CLCircularRegion {
      handleEvent(forRegion: region, home: true)
    }
  }
  
  // user exited home
  func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
    if region is CLCircularRegion {
      handleEvent(forRegion: region, home: false)
    }
  }
}

