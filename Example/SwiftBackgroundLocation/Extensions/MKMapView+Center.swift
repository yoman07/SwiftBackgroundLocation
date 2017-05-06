import MapKit

extension MKMapView {
    public func centerCamera(to location: CLLocation? = nil, distance: Double = 500, pitch: CGFloat = 0, heading: Double? = 0, animated: Bool = false) {
        let coordinate: CLLocationCoordinate2D = location?.coordinate ?? camera.centerCoordinate
        
        let c = MKMapCamera(lookingAtCenter: coordinate, fromDistance: distance, pitch: pitch, heading: heading ?? 0)
        setCamera(c, animated: animated)
    }
}
