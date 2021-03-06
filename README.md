# SITHSManager

[![Version](https://img.shields.io/cocoapods/v/SITHSManager.svg?style=flat)](http://cocoapods.org/pods/SITHSManager)
[![License](https://img.shields.io/cocoapods/l/SITHSManager.svg?style=flat)](http://cocoapods.org/pods/SITHSManager)
[![Platform](https://img.shields.io/cocoapods/p/SITHSManager.svg?style=flat)](http://cocoapods.org/pods/SITHSManager)

iOS helper classes used for reading and parsing the basic contents of Swedish [SITHS](http://www.inera.se/siths) identification smart cards with a [Precise Biometrics](https://precisebiometrics.com) card reader.

Made by [Appcorn AB](https://www.appcorn.se) for [Svensk e-identitet](http://www.e-identitet.se).

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

The basic usage of the `SITHSManager` helper class is done via the `state` and `stateClosure` properties.

A simple View Controller showing the current state of the card reader, and any inserted SITHS cards, would be as following:

```swift
import UIKit
import SITHSManager

class ViewController: UIViewController {
  
  @IBOutlet weak var stateLabel: UILabel! // Simple label on the view to show status
  
  let sithsManager = SITHSManager() // Store a reference to the manager, so it's not released (causing notifications to stop)
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Add a state change closure, the state can also be read from the `sithsManager.state` property directly
    sithsManager.stateClosure = { [weak self] state in
      guard let stateLabel = self?.stateLabel else {
        return
      }
      
      // Switch for the different states
      switch state {
      case .unknown:
        stateLabel.textColor = .black
        stateLabel.text = "Unknown"
      case .readingFromCard:
        stateLabel.textColor = .black
        stateLabel.text = "Reading From Card..."
      case .error(let error):
        stateLabel.textColor = .red
        stateLabel.text = "Error \(error)"
      case .readerDisconnected:
        stateLabel.textColor = .red
        stateLabel.text = "Reader Disconnected"
      case .unknownCardInserted:
        stateLabel.textColor = .red
        stateLabel.text = "Unknown Card Inserted"
      case .cardWithoutCertificatesInserted:
        stateLabel.textColor = .red
        stateLabel.text = "SITHS Card Without Certificates Inserted"
      case .readerConnected:
        stateLabel.textColor = .blue
        stateLabel.text = "Reader Connected"
      case .cardInserted(let certificates):
        // We have a set of at least one SITHS certificate (see the `SITHSCardCertificate` struct for more information)
        let strings = certificates.map { certificate in
          return "• \(certificate.cardNumber) \(certificate.serialString) \(certificate.subject[.commonName] ?? "[No common name]")"
        }
        
        stateLabel.textColor = .green
        stateLabel.text = "SITHS Card Inserted:\n\(strings.joined(separator: "\n"))"
      }
    }
  }
}
```

## Requirements

Note the special instructions to enable the multiple "Supported external accessory protocols" in the Precise SDK documentation.

## Installation

SITHSManager is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "SITHSManager"
```

## Author

Martin Alléus, Appcorn AB, martin@appcorn.se

## License

Copyright (c) 2019 [Svensk e-identitet AB](http://www.e-identitet.se). SITHSManager is available under the MIT license. See the LICENSE file for more info.
