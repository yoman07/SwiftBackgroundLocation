import UIKit
import SwiftBackgroundLocation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var locationManager = TrackingHeadingLocationManager()
    var backgroundLocationManager = BackgroundLocationManager()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        
        if launchOptions?[UIApplicationLaunchOptionsKey.location] != nil {
            BackgroundDebug().write(string: "UIApplicationLaunchOptionsLocationKey")
            
            backgroundLocationManager.startBackground() { result in
                if case let .Success(location) = result {
                    LocationLogger().writeLocationToFile(location: location)
                }
            }
        }

        return true
    }

}

