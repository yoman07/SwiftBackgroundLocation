import UIKit
import MapKit
import SwiftBackgroundLocation

class ViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    var locations: [CLLocation] = []
    var backgroundLocations: [CLLocation] = []

    var logger = LocationLogger()
    var currentPolyline: MKPolyline?
    var currentBackgroundPolyline: MKPolyline?

    var circles: [MKCircle] = []
    
    override func viewDidLoad() {
        mapView.delegate = self
        super.viewDidLoad()
        
        BackgroundDebug().print()

    }
    
    @IBAction func start(_ sender: Any) {
        startTracking()
    }
    
    var appDelagete = {
        return UIApplication.shared.delegate as! AppDelegate
    }
    
    @IBAction func stop(_ sender: Any) {
        appDelagete().locationManager.stop()
        appDelagete().backgroundLocationManager.stop()
    }
    
    @IBAction func clear(_ sender: Any) {
        if let polyline = currentPolyline {
            mapView.remove(polyline)
        }
        if let polyline = currentBackgroundPolyline {
            mapView.remove(polyline)
        }
    }
    
    
    @IBAction func readLog(_ sender: Any) {
        if let locations = logger.readLocation() {
            drawLocation(locations: locations)
            centerCamera(to: locations.last!)
        }
    }
    
    @IBAction func clearLog(_ sender: Any) {
        logger.removeLogFile()
    }
    
    
    func startTracking() {
        drawRegions()
        appDelagete().backgroundLocationManager.start() { [unowned self] result in
            if case let .Success(location) = result {
                self.updateBackgroundLocation(location: location)
            }
        }
        
        
        appDelagete().locationManager.manager(for: .always, completion: { result in
            if case let .Success(manager) = result {
                manager.startUpdatingLocation(isHeadingEnabled: true) { [weak self] result in
                    if case let .Success(locationHeading) = result, let location = locationHeading.location {
                        self?.updateLocation(location: location)
                    }
                }
            }


        })
        
    }

    
    var isCenter = false
    
    private func updateBackgroundLocation(location: CLLocation) {
        backgroundLocations.append(location)
        
        if let polyline = currentBackgroundPolyline {
            mapView.remove(polyline)
        }
        
        currentBackgroundPolyline = ViewController.polyline(locations: backgroundLocations, title: "regions")
        mapView.add(currentBackgroundPolyline!)
        
        logger.writeLocationToFile(location: location)
        
    }
    
    private func updateLocation(location: CLLocation) {
        locations.append(location)
        
        if let polyline = currentPolyline {
            mapView.remove(polyline)
        }

        drawLocation(locations: locations)
        centerCamera(to: location)
        
    }
    
    private func centerCamera(to location: CLLocation) {
        if !isCenter {
            let camera = mapView.camera
            camera.centerCoordinate = location.coordinate
            
            mapView.camera = camera
            let viewRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, 500, 500)
            
            mapView.setRegion(viewRegion, animated: true)
            isCenter = true
        }
    }
    
    func drawLocation(locations: [CLLocation]) {
        currentPolyline = ViewController.polyline(locations: locations, title: "location")
        mapView.add(currentPolyline!)
    }
    
    
    static func polyline(locations: [CLLocation], title:String) -> MKPolyline {
        var coords = [CLLocationCoordinate2D]()
        
        for location in locations {
            coords.append(CLLocationCoordinate2D(latitude: location.coordinate.latitude,
                                                 longitude: location.coordinate.longitude))
        }
        
        let polyline = MKPolyline(coordinates: &coords, count: locations.count)
        polyline.title = title
        
        return polyline
    }
    
    func drawRegions() {
        appDelagete().backgroundLocationManager.addedRegionsListener = { result in
            
            if case let .Success(locations) = result {
                
                self.circles.forEach({ circle in
                    self.mapView.remove(circle)
                })
                
                locations.forEach({ location in
                    let circle = MKCircle(center: location.coordinate, radius: self.appDelagete().backgroundLocationManager.regionConfig.regionRadius)
                    circle.title = "regionPlanned"
                    self.mapView.add(circle)
                    self.circles.append(circle)
                })
                
                
            }
        }

    }

}

extension ViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let circle = overlay as? MKCircle {
            let renderer = MKCircleRenderer(circle: circle)
            let isRegion = circle.title ?? "" == "regionPlanned"
            renderer.fillColor = isRegion ? UIColor.blue.withAlphaComponent(0.2) : UIColor.red.withAlphaComponent(0.2)
            return renderer
        }
        
        
        let isRegion = overlay.title ?? "" == "regions"
        
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = isRegion ? UIColor.red.withAlphaComponent(0.8) : UIColor.blue.withAlphaComponent(0.8)
        renderer.lineWidth = isRegion ? 8.0 : 2.0
        
        return renderer
    }

}
