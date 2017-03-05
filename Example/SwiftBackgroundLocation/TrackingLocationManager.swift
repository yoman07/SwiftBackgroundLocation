import CoreLocation

typealias Listener = (Result<CLLocation>) -> ()

class TrackingLocationManager: NSObject {
    
    fileprivate lazy var significantLocationManager: CLLocationManager = {
        var locationManager: CLLocationManager = CLLocationManager()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.requestAlwaysAuthorization()
        return locationManager
    }()
    
    fileprivate lazy var locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.distanceFilter = 100
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestAlwaysAuthorization()
        manager.allowsBackgroundLocationUpdates = true

        return manager
    }()
    
    
    fileprivate var listener: Listener?
    
    func startSignificantLocationChanges() {
        significantLocationManager.delegate = self
        significantLocationManager.startMonitoringSignificantLocationChanges()
    }
    
    func requestLocation(listener: @escaping Listener) {
        self.listener = listener
        locationManager.delegate = self
        
        if significantLocationManager.delegate == nil {
            startSignificantLocationChanges()
        }
        locationManager.requestLocation()
    }
    
    func start(listener: @escaping Listener) {
        self.listener = listener
        locationManager.delegate = self
        locationManager.startUpdatingLocation()
    }
    
    func stop() {
        locationManager.stopUpdatingLocation()
    }
}

extension TrackingLocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.max(by: { (location1, location2) -> Bool in
            return location1.timestamp.timeIntervalSince1970 < location2.timestamp.timeIntervalSince1970}) else { return }
        
        if manager == significantLocationManager {
            locationManager.requestLocation()
        } else {
            listener?(Result.Success(location))
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
    }
}
