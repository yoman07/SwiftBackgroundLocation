import CoreLocation


public typealias LocationManagerListener = (Result<TrackingHeadingLocationManager>) -> ()
public typealias HeadingLocationListener = (Result<LocationHeading>) -> ()



final public class TrackingHeadingLocationManager: NSObject {
    
    var desiredAccuracy: CLLocationAccuracy {
        didSet {
            locationManager.desiredAccuracy = desiredAccuracy
        }
    }

    var allowsBackgroundLocationUpdates: Bool {
        didSet {
            locationManager.allowsBackgroundLocationUpdates = allowsBackgroundLocationUpdates
        }
    }
    
    var distanceFilter: CLLocationDistance {
        didSet {
            locationManager.distanceFilter = distanceFilter
        }
    }
    
    var activityType: CLActivityType {
        didSet {
            locationManager.activityType = activityType
        }
    }
    
    var isHeadingEnabled: Bool? {
        didSet {
            if isHeadingEnabled ?? false {
                locationManager.startUpdatingHeading()
            } else {
                locationManager.stopUpdatingHeading()
            }
        }
    }
    
    fileprivate var headingListener: HeadingLocationListener?
    fileprivate var locationManagerListener: LocationManagerListener?
    fileprivate var requestedStatus: LocationAuthorizationStatus?

    fileprivate lazy var significantLocationManager: CLLocationManager = {
        var locationManager: CLLocationManager = CLLocationManager()
        return locationManager
    }()
    
    fileprivate lazy var locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        return manager
    }()
    
    fileprivate var lastLocation: CLLocation?
    fileprivate var lastHeading: CLHeading?
    
    
    /// Init for trakcing location manager with heading
    ///
    /// - Parameters:
    ///   - desiredAccuracy: desiredAccuracy
    ///   - distanceFilter: distanceFilter
    ///   - allowsBackgroundLocationUpdates: should track location in background
    ///   - activityType: type of recording activity
    public init(desiredAccuracy: CLLocationAccuracy = kCLLocationAccuracyBestForNavigation, distanceFilter: CLLocationDistance = kCLDistanceFilterNone, allowsBackgroundLocationUpdates: Bool = true, activityType:CLActivityType = .fitness) {
        self.desiredAccuracy = desiredAccuracy
        self.allowsBackgroundLocationUpdates = allowsBackgroundLocationUpdates
        self.distanceFilter = distanceFilter
        self.activityType = activityType
    }
    
    /// Method with listner
    ///
    /// - Parameters:
    ///   - isHeadingEnabled: possiblity to get location with heading
    ///   - headingListener: listener which return location with heading if enabled
    public func startUpdatingLocation(isHeadingEnabled:Bool = false, headingListener: @escaping HeadingLocationListener) {
        self.headingListener = headingListener
        locationManager.delegate = self
        locationManager.startUpdatingLocation()
        self.isHeadingEnabled = isHeadingEnabled
    }

    /// Method for asking about location status
    ///
    /// - Parameters:
    ///   - status: which status you need, always or whenInUse
    ///   - completion: completion which return current location manager
    public func manager(for status:LocationAuthorizationStatus, completion: @escaping LocationManagerListener) {
        self.locationManagerListener = completion
        self.requestedStatus = status
        if status.isAuthorized(for: CLLocationManager.authorizationStatus()) {
            locationManagerListener?(Result.Success(self))
            return
        }

        if status == .always && CLLocationManager.authorizationStatus() != .authorizedWhenInUse {
            self.locationManager.requestWhenInUseAuthorization()
        } else {
            if CLLocationManager.authorizationStatus() != status.authorizationStatus() {
                switch status {
                case .always:
                    self.locationManager.requestAlwaysAuthorization()
                case .whenInUse:
                    self.locationManager.requestWhenInUseAuthorization()
                }
            }
        }
    }
    
    
    /// Delegate method for getting authorization status
    ///
    /// - Parameters:
    ///   - manager: manager
    ///   - status: status
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if requestedStatus?.isAuthorized(for: status) ?? false {
            locationManagerListener?(Result.Success(self))
            return
        }
        
        if requestedStatus == .always {
            if status == .authorizedWhenInUse {
                self.locationManager.requestAlwaysAuthorization()
            } else {
                locationManagerListener?(Result.Error(LocationAuthorizationError.cantGetAlways))
            }
        } else {
            locationManagerListener?(Result.Error(LocationAuthorizationError.userDenied))
        }
    }
    
    
    /// Stop tracking
    public func stop() {
        lastHeading = nil
        lastLocation = nil
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
    }
    
    
    func requestLocation(listener: @escaping HeadingLocationListener) {
        self.headingListener = listener
        locationManager.delegate = self
        
        if significantLocationManager.delegate == nil {
            startSignificantLocationChanges()
        }
        locationManager.requestLocation()
    }
    
    private func startSignificantLocationChanges() {
        significantLocationManager.delegate = self
        significantLocationManager.startMonitoringSignificantLocationChanges()
    }

    /// Enum for getting location permission
    ///
    /// - whenInUse: application use location only when in foreground
    /// - always: application can use location always
    public enum LocationAuthorizationStatus {
        case whenInUse, always
        
        func authorizationStatus() -> CLAuthorizationStatus {
            switch self {
            case .always:
                return .authorizedAlways
            case .whenInUse:
                return .authorizedWhenInUse
            }
        }
        
        func isAuthorized(for status: CLAuthorizationStatus) -> Bool {
            if status == authorizationStatus() {
                return true
            }
            
            if status == .authorizedAlways && self == .whenInUse {
                return true
            }
            
            return false
        }
    }
    
    
    /// Errors for authorization
    ///
    /// - cantGetAlways: couldn't get always authorization
    /// - userDenied: user clicked denied
    enum LocationAuthorizationError: Error {
        case cantGetAlways, userDenied
    }
}


/// Struct which contain location and heading, both can be nil
public struct LocationHeading {
    public var location: CLLocation?
    public var heading: CLHeading?
}

extension TrackingHeadingLocationManager: CLLocationManagerDelegate {
    
    /// Delegate for LocationManager Success for getting location
    ///
    /// - Parameters:
    ///   - manager: locationManager
    ///   - locations: location returned from locationManager
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.max(by: { (location1, location2) -> Bool in
            return location1.timestamp.timeIntervalSince1970 < location2.timestamp.timeIntervalSince1970}) else { return }
        lastLocation = location

        if manager == significantLocationManager {
            locationManager.requestLocation()
        } else {
            headingListener?(Result.Success(LocationHeading(location: lastLocation, heading: lastHeading)))
        }
    }
    
    
    /// Delegate for LocationManager errror
    ///
    /// - Parameters:
    ///   - manager: locationManager
    ///   - error: error for getting location
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
    }
    
    /// Delegate method, called when newHeading appear
    ///
    /// - Parameters:
    ///   - manager: manager
    ///   - newHeading: newHeading
    public func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        lastHeading = newHeading
        self.headingListener?(Result.Success(LocationHeading(location: lastLocation, heading: lastHeading)))
    }
}
