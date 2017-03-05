import CoreLocation

public protocol BackgroundTrackable {
    func start(backgroundTrackingListener: @escaping BackgroundTrackingListener)
    func stop()
}
