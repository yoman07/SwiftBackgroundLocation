import CoreLocation
import UIKit

public typealias BackgroundTrackingListener = (Result<CLLocation>) -> ()
public typealias RegionListener = (Result<[CLLocation]>) -> ()

final public class BackgroundLocationManager: NSObject {
    public var addedRegionsListener: RegionListener?

    fileprivate var bgTaskIdentifier = "fetchLocation"
    
    fileprivate var currentBGTask: UIBackgroundTaskIdentifier?
    
    fileprivate var regionCache: BackgroundLocationCacheable
    fileprivate var listener: BackgroundTrackingListener?

    fileprivate lazy var trackingLocationManager: TrackingLocationManager = TrackingLocationManager()
    
    fileprivate lazy var locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.distanceFilter = kCLDistanceFilterNone
        manager.desiredAccuracy = kCLLocationAccuracyBest
        return manager
    }()
    
    
    public convenience override init() {
        guard let userDefaults = UserDefaults(suiteName: Constants.suitName) else { fatalError()}
        self.init(regionCache: BackgroundLocationCache(defaults: userDefaults))
    }
    
    public init(regionCache: BackgroundLocationCacheable) {
        self.regionCache = regionCache
    }
    
    public func start(backgroundTrackingListener: @escaping BackgroundTrackingListener) {
        listener = backgroundTrackingListener
        locationManager.delegate = self
        tryToRefreshPosition()
    }
    
    public func startBackground(backgroundTrackingListener: @escaping BackgroundTrackingListener) {
        listener = backgroundTrackingListener

        locationManager.delegate = self
        
        currentBGTask = UIApplication.shared.beginBackgroundTask(withName: bgTaskIdentifier) {[weak self] in
            self?.tryToRefreshPosition()
        }
        
        self.tryToRefreshPosition()
    }
    
    public func stop() {
        listener = nil
        locationManager.delegate = nil
    }

    public struct RegionConfig {
        public static let distanceToAroundRegions = regionRadius*Double(maximumNumberOfRegions)/Double.pi
        public static let regionRadius = 100.0
        public static let maximumNumberOfRegions = 20
    }
}

extension BackgroundLocationManager {
    fileprivate func tryToRefreshPosition(listener: Listener? = nil) {
        var lastLocation: CLLocation? = nil
        trackingLocationManager.requestLocation {[weak self] result in
            if case let .Success(location) = result {
                let theSameLocation = { () -> Bool in
                    guard let l = lastLocation else { return false }
                    return l.coordinate.latitude == location.coordinate.latitude &&  l.coordinate.longitude == location.coordinate.longitude
                }()
                
                if !theSameLocation { //user doesnt change position
                    self?.startMonitoring(for: location.coordinate)
                    self?.provideLocation(location: location)
                    lastLocation = location
                }
            } else {
                listener?(result)
            }
        }
    }
    
    fileprivate func startMonitoring(for coordinate: CLLocationCoordinate2D) {
        clearRegions()
        
        let val = 2*Double.pi/Double(RegionConfig.maximumNumberOfRegions)
        
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        var locations:[CLLocation] = []
        locations.append(location)
        
        var regions:[CLCircularRegion] = []
        for i in 0..<RegionConfig.maximumNumberOfRegions {
            let identifier = "\(Constants.suitName).regionIdentifier.\(i)"
            let bearing = val*Double(i)
            
            let coordinate = coordinate.location(for: bearing, and: RegionConfig.distanceToAroundRegions)
            
            let region = CLCircularRegion(center: CLLocationCoordinate2D(latitude: coordinate.latitude,
                                                                         longitude: coordinate.longitude),
                                          radius: RegionConfig.regionRadius,
                                          identifier: identifier)
            
            
            regions.append(region)
            let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            locations.append(location)
            locationManager.startMonitoring(for: region)
        }
        
        regionCache.saveRegionsCoordinates(regions: regions)
        
        addedRegionsListener?(Result.Success(locations))
    }
    
    fileprivate func clearRegions() {
        locationManager.monitoredRegions.forEach { region in
            locationManager.stopMonitoring(for: region)
        }
    }
    
    fileprivate func provideLocation(location: CLLocation) {
        listener?(Result.Success(location))
        
        if let currentBGTask = currentBGTask, currentBGTask != UIBackgroundTaskInvalid  {
            UIApplication.shared.endBackgroundTask(currentBGTask)
            self.currentBGTask = UIBackgroundTaskInvalid
        }
    }
}


extension BackgroundLocationManager: CLLocationManagerDelegate {
    
    public func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        let coordinates = regionCache.coordinates(for: region)
        let location =  CLLocation(latitude: coordinates.latitude, longitude: coordinates.longitude)

        self.tryToRefreshPosition() {[weak self] result in
            if case .Error(_) = result {
                self?.startMonitoring(for: coordinates)
                self?.provideLocation(location: location)
            }
        }
    }
}
