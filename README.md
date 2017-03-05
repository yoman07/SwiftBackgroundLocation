# SwiftBackgroundLocation

[![CI Status](http://img.shields.io/travis/yoman07/SwiftBackgroundLocation.svg?style=flat)](https://travis-ci.org/yoman07/SwiftBackgroundLocation)
[![Version](https://img.shields.io/cocoapods/v/SwiftBackgroundLocation.svg?style=flat)](http://cocoapods.org/pods/SwiftBackgroundLocation)
[![License](https://img.shields.io/cocoapods/l/SwiftBackgroundLocation.svg?style=flat)](http://cocoapods.org/pods/SwiftBackgroundLocation)
[![Platform](https://img.shields.io/cocoapods/p/SwiftBackgroundLocation.svg?style=flat)](http://cocoapods.org/pods/SwiftBackgroundLocation)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

Just add in your app delegate:
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

## Requirements

## Installation

SwiftBackgroundLocation is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "SwiftBackgroundLocation"
```

## Author

yoman07, roman.barzyczak+web@gmail.com

## License

SwiftBackgroundLocation is available under the MIT license. See the LICENSE file for more info.
