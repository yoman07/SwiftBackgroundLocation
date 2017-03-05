import CoreLocation
import Foundation

extension Array where Element:CLLocation {
    
    func interpolateLocationWithHermite(alpha:Double = 1.0/3.0) -> [CLLocation]
    {
        var locations:[CLLocation] = []
        let startPoint = self[0]
        let n = count - 1
        locations.append(startPoint)
        
        for index in 0..<n
        {
            var currentPoint = self[index]
            var nextIndex = (index + 1) % count
            var prevIndex = index == 0 ? count - 1 : index - 1
            var previousPoint = self[prevIndex]
            var nextPoint = self[nextIndex]
            var mx : Double
            var my : Double
            
            if index > 0
            {
                mx = (nextPoint.coordinate.latitude - previousPoint.coordinate.latitude) / 2.0
                my = (nextPoint.coordinate.longitude - previousPoint.coordinate.longitude) / 2.0
            }
            else
            {
                mx = (nextPoint.coordinate.latitude - currentPoint.coordinate.latitude) / 2.0
                my = (nextPoint.coordinate.longitude - currentPoint.coordinate.longitude) / 2.0
            }
            
            let location = CLLocation(latitude: currentPoint.coordinate.latitude + mx * alpha, longitude: currentPoint.coordinate.longitude + my * alpha)
            
            currentPoint = self[nextIndex]
            nextIndex = (nextIndex + 1) % self.count
            prevIndex = index
            previousPoint = self[prevIndex]
            nextPoint = self[nextIndex]
            
            if index < n - 1
            {
                mx = (nextPoint.coordinate.latitude - previousPoint.coordinate.latitude) / 2.0
                my = (nextPoint.coordinate.longitude - previousPoint.coordinate.longitude) / 2.0
            }
            else
            {
                mx = (currentPoint.coordinate.latitude - previousPoint.coordinate.latitude) / 2.0
                my = (currentPoint.coordinate.longitude - previousPoint.coordinate.longitude) / 2.0
            }
            
            let location2 = CLLocation(latitude: currentPoint.coordinate.latitude - mx * alpha, longitude:  currentPoint.coordinate.longitude - my * alpha)
            
            
            locations.append(location)
            locations.append(location2)

        }
        
        return locations
    }
}
