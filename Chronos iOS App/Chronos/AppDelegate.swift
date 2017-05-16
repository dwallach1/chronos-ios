
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
      window?.rootViewController?.showAlert(withTitle: nil, message: "Wally says \(status)")
    } else {
      // Otherwise present a local notification
      let notification = UILocalNotification()
      notification.alertBody = "Wally says \(status)"
      notification.soundName = "Default"
      UIApplication.shared.presentLocalNotificationNow(notification)
    }
    
//    let url = "https://maker.ifttt.com/trigger/{event}/with/key/ckgPf3yQsCMF2GNMIHWoatjZmr3YRPnxkn4FkA_iN-d"
//    let req = "PUT"
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

