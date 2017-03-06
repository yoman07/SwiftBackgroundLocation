import Quick
import Nimble
import SwiftBackgroundLocation
import CoreLocation

class BackgroundLocationCacheTests: QuickSpec {
    override func spec() {
        describe("background regions cache test") {

            var subject: BackgroundLocationCache!
            var expected: [CLCircularRegion]!
            
            beforeEach {
                subject = BackgroundLocationCache(defaults: UserDefaults(suiteName: "com.swiftBackgroundLocation.test")!)
                
                let region1 = CLCircularRegion(center: CLLocationCoordinate2DMake(1.2, 2.10), radius: 10, identifier: "region1")
                let region2 = CLCircularRegion(center: CLLocationCoordinate2DMake(10.1, 20.2), radius: 30, identifier: "region2")
                
                expected = [region1, region2]
                
                subject.saveRegionsCoordinates(regions: [region1, region2])
            }
            
            it("is caching correctly") {
                expect(subject.coordinates(for: expected[0]).latitude) == expected[0].center.latitude
                expect(subject.coordinates(for: expected[0]).longitude) == expected[0].center.longitude
                expect(subject.coordinates(for: expected[1]).latitude) == expected[1].center.latitude
                expect(subject.coordinates(for: expected[1]).longitude) == expected[1].center.longitude
            }
        }
    }
}
