# SITHSManager

[![Version](https://img.shields.io/cocoapods/v/SITHSManager.svg?style=flat)](http://cocoapods.org/pods/SITHSManager)
[![License](https://img.shields.io/cocoapods/l/SITHSManager.svg?style=flat)](http://cocoapods.org/pods/SITHSManager)
[![Platform](https://img.shields.io/cocoapods/p/SITHSManager.svg?style=flat)](http://cocoapods.org/pods/SITHSManager)

iOS helper classes used for reading and parsing the basic contents of Swedish [SITHS](http://www.inera.se/siths) identification smart cards with a [Precise Biometrics](https://precisebiometrics.com) card reader.

Made by [Appcorn AB](https://www.appcorn.se) for [Svensk e-identitet](http://www.e-identitet.se).

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

The `SITHSManager` class uses the [Precise Biometrics](https://precisebiometrics.com) iOS Smart Card reader SDK. The SDK files are not included in this library, and needs to be copied in separately. There is a directory, `Precise` that has been prepared for this. Place the Precise SDK files in the `Precise` directory. You will need the following files:

* `Precise/lib/libiOSLibrary.a`
* `Precise/include/*.h`

After copying in the files, do a `pod update`.

Please also note the special instructions to enable the different "Supported external accessory protocols" in the Precise SDK documentation.

## Installation

SITHSManager is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "SITHSManager"
```

## Author

Martin Alléus, Appcorn AB, martin@appcorn.se

## License

Copyright (c) 2017 [Svensk e-identitet AB](http://www.e-identitet.se). SITHSManager is available under the MIT license. See the LICENSE file for more info.
