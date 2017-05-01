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
            guard let isHeadingEnabled = isHeadingEnabled else {
                return
            }
            if isHeadingEnabled {
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
    
    
    public init(desiredAccuracy: CLLocationAccuracy = kCLLocationAccuracyBestForNavigation, distanceFilter: CLLocationDistance = kCLDistanceFilterNone, allowsBackgroundLocationUpdates: Bool = true, activityType:CLActivityType = .fitness) {
        self.desiredAccuracy = desiredAccuracy
        self.allowsBackgroundLocationUpdates = allowsBackgroundLocationUpdates
        self.distanceFilter = distanceFilter
        self.activityType = activityType
    }
    
    
    func startSignificantLocationChanges() {
        significantLocationManager.delegate = self
        significantLocationManager.startMonitoringSignificantLocationChanges()
    }
    
    func requestLocation(listener: @escaping HeadingLocationListener) {
        self.headingListener = listener
        locationManager.delegate = self
        
        if significantLocationManager.delegate == nil {
            startSignificantLocationChanges()
        }
        locationManager.requestLocation()
    }
    
    public func startUpdatingLocation(isHeadingEnabled:Bool = false, headingListener: @escaping HeadingLocationListener) {
        self.headingListener = headingListener
        locationManager.delegate = self
        locationManager.startUpdatingLocation()
        self.isHeadingEnabled = isHeadingEnabled
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        lastHeading = newHeading
        self.headingListener?(Result.Success(LocationHeading(location: lastLocation, heading: lastHeading)))
    }
    
    
    public func manager(for status:LocationAuthorizationStatus, completion: @escaping LocationManagerListener) {
        self.locationManagerListener = completion
        self.requestedStatus = status
        
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
    
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if requestedStatus?.authorizationStatus() == status {
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

    public func stop() {
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
    }
    

    
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
    }
    
    enum LocationAuthorizationError: Error {
        case cantGetAlways, userDenied
    }
}

public struct LocationHeading {
    public var location: CLLocation?
    public var heading: CLHeading?
}

extension TrackingHeadingLocationManager: CLLocationManagerDelegate {
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
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
    }
}
