# SwiftBackgroundLocation

[![CI Status](http://img.shields.io/travis/yoman07/SwiftBackgroundLocation.svg?style=flat)](https://travis-ci.org/yoman07/SwiftBackgroundLocation)
[![Version](https://img.shields.io/cocoapods/v/SwiftBackgroundLocation.svg?style=flat)](http://cocoapods.org/pods/SwiftBackgroundLocation)
[![License](https://img.shields.io/cocoapods/l/SwiftBackgroundLocation.svg?style=flat)](http://cocoapods.org/pods/SwiftBackgroundLocation)
[![Platform](https://img.shields.io/cocoapods/p/SwiftBackgroundLocation.svg?style=flat)](http://cocoapods.org/pods/SwiftBackgroundLocation)

SwiftBackground is the right choice to work easily and efficiently with Location Manager when your app is terminated or killed. It's based on region monitoring. Demo how it works (blue is normal tracking, red line is region based tracking):

![](https://media.giphy.com/media/xUA7biAFYmwE8IKcDe/source.gif)



## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

Just add in your app delegate for background location:

```
    var backgroundLocationManager = BackgroundLocationManager()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        
         backgroundLocationManager.startBackground() { result in
                if case let .Success(location) = result {
                    LocationLogger().writeLocationToFile(location: location)
                }
        }

        return true
    }
```

Getting permission (`.always` or `.whenInUse`) for location tracking:

```
locationManager.manager(for: .always, completion: { result in
            if case let .Success(manager) = result {
                
            }


})
```

Location tracking with listener:

```
locationManager.manager(for: .always, completion: { result in
            if case let .Success(manager) = result {
                manager.startUpdatingLocation(isHeadingEnabled: true) { [weak self] result in
                    if case let .Success(locationHeading) = result, let location = locationHeading.location {
                        self?.updateLocation(location: location)
                    }
                }
            }

})
```

Getting heading needs additional hardware and hence wont work on simulator.


## Requirements

## Installation

SwiftBackgroundLocation is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "SwiftBackgroundLocation"
```

You must add NSLocationAlwaysUsageDescription or NSLocationWhenInUseUsageDescription key to your project’s Info.plist containing the message to be displayed to the user at the prompt. If you need always location, you should add both.

```<key>NSLocationAlwaysUsageDescription</key>
<string>$(PRODUCT_NAME) needs location always usage for recording in background./string>```

```<key>NSLocationWhenInUseUsageDescription</key>
<string>$(PRODUCT_NAME) needs location when in use for recording in foreground.</string>```

The user will not be prompted unless one of these are added to the Info.plist.


## Author

yoman07, roman.barzyczak+web@gmail.com

## License

SwiftBackgroundLocation is available under the MIT license. See the LICENSE file for more info.
