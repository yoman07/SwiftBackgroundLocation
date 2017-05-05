import CoreLocation
import UIKit


/// Listener for background tracking
public typealias BackgroundTrackingListener = (Result<CLLocation>) -> ()


/// Listener for region
public typealias RegionListener = (Result<[CLLocation]>) -> ()



/// Struct for region Config
public struct RegionConfig {
	public var distanceToAroundRegions: Double {
		return regionRadius*Double(maximumNumberOfRegions)/Double.pi
	}
	public let regionRadius: Double
	public let maximumNumberOfRegions: Int
	
	public init(regionRadius: Double = 100.0, maximumNumberOfRegions: Int = 20) {
		self.regionRadius = regionRadius
		self.maximumNumberOfRegions = maximumNumberOfRegions
	}
}

final public class BackgroundLocationManager: NSObject {
    public var addedRegionsListener: RegionListener?
	
	public let regionConfig: RegionConfig

    fileprivate var bgTaskIdentifier = "fetchLocation"
    
    fileprivate var currentBGTask: UIBackgroundTaskIdentifier?
    
    fileprivate var regionCache: BackgroundLocationCacheable
    fileprivate var listener: BackgroundTrackingListener?

    fileprivate lazy var trackingLocationManager: TrackingHeadingLocationManager = TrackingHeadingLocationManager()
    
    fileprivate lazy var locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.distanceFilter = kCLDistanceFilterNone
        manager.desiredAccuracy = kCLLocationAccuracyBest
        return manager
    }()
    
    
    public convenience override init() {
        guard let userDefaults = UserDefaults(suiteName: Constants.suitName) else { fatalError()}
		self.init(regionCache: BackgroundLocationCache(defaults: userDefaults), regionConfig: RegionConfig())
    }
	
	public convenience init(regionConfig: RegionConfig) {
		guard let userDefaults = UserDefaults(suiteName: Constants.suitName) else { fatalError()}
		self.init(regionCache: BackgroundLocationCache(defaults: userDefaults), regionConfig: regionConfig)
	}
    
    init(regionCache: BackgroundLocationCacheable, regionConfig: RegionConfig) {
        self.regionCache = regionCache
		self.regionConfig = regionConfig
    }
    
    
    /// Start tracking foregorund
    ///
    /// - Parameter backgroundTrackingListener: listener which contains location
    public func start(backgroundTrackingListener: @escaping BackgroundTrackingListener) {
        listener = backgroundTrackingListener
        locationManager.delegate = self
        tryToRefreshPosition()
    }
    
    
    /// Start tracking background
    ///
    /// - Parameter backgroundTrackingListener: listener which contains location
    public func startBackground(backgroundTrackingListener: @escaping BackgroundTrackingListener) {
        listener = backgroundTrackingListener

        locationManager.delegate = self
        
        currentBGTask = UIApplication.shared.beginBackgroundTask(withName: bgTaskIdentifier) {[weak self] in
            self?.tryToRefreshPosition()
        }
        
        tryToRefreshPosition()
    }
    
    
    /// Stop tracking
    public func stop() {
        listener = nil
        locationManager.delegate = nil
    }
}

extension BackgroundLocationManager {
    fileprivate func tryToRefreshPosition(listener: HeadingLocationListener? = nil) {
        var lastLocation: CLLocation? = nil
        trackingLocationManager.requestLocation {[weak self] result in
            if case let .Success(headingLocation) = result, let location = headingLocation.location {
                
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
        
        let val = 2*Double.pi/Double(regionConfig.maximumNumberOfRegions)
        
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        var locations:[CLLocation] = []
        locations.append(location)
        
        var regions:[CLCircularRegion] = []
        for i in 0..<regionConfig.maximumNumberOfRegions {
            let identifier = "\(Constants.suitName).regionIdentifier.\(i)"
            let bearing = val*Double(i)
            
            let coordinate = coordinate.location(for: bearing, and: regionConfig.distanceToAroundRegions)
            
            let region = CLCircularRegion(center: CLLocationCoordinate2D(latitude: coordinate.latitude,
                                                                         longitude: coordinate.longitude),
                                          radius: regionConfig.regionRadius,
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
    
    
    /// Invoked when the user enters a monitored region.  This callback will be invoked for every allocated
    /// CLLocationManager instance with a non-nil delegate that implements this method.
    ///
    /// - Parameters:
    ///   - manager: location manager
    ///   - region: region
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
