# ReefReferralSDK

[![Swift Version](https://img.shields.io/badge/Swift-5.5-orange.svg)](https://swift.org)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/Platform-iOS-lightgrey.svg)](https://developer.apple.com/swift/)

## Overview

The ReefReferral SDK is a tool for iOS app developers to easily integrate referral functionality into their applications. With a simple setup, developers can enable users to refer friends and earn rewards.


## Requirements

- Swift 5.5+
- iOS 14.0+

## Installation

### Swift Package Manager

You can use the [Swift Package Manager](https://swift.org/package-manager/) to install `ReefReferral` by adding it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/ReefReferral/ReefReferralSDK.git", branch: "main")
]
```

## Configuration

To use the ReefReferral package effectively, you need to make additional configurations in your project.

### Adding URL Type

Add a URL Type to your app. This URL Type is necessary for handling deep links related to referrals. Follow these steps to add a URL Type:

1. In Xcode, open your project settings
2. Navigate to the "Info" > "URL Types" section
3. Click the "+" button to add a new URL Type
4. Set the URL Scheme to "reef-referal"

## Usage

Here is a sample implementation:

### AppDelegate

```swift
import UIKit
import ReefReferral

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    
        // Initialize the ReefReferral SDK
        ReefReferral.shared.start(apiKey: "your_api_key_here", delegate: self)
                
        return true
    }
    
    func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
    
        ReefReferral.shared.handleDeepLink(url: url)
        
        return true
    }
}

extension AppDelegate: ReefReferralDelegate {
    
    // Implement ReefReferralDelegate methods
    
    func didReceiveReferralStatuses(_ statuses: [ReferralStatus]) {
        // Handle referral statuses here
    }
    
    func wasReferredSuccessfully() {
        // Handle successful referral here
        print("You were referred successfully!")
    }
    
    func wasConvertedSuccessfully() {
        // Handle successful conversion here
        print("You were converted successfully!")
    }
}
```

### ViewController

```swift
import UIKit
import ReefReferralSDK  // Replace with the actual module name

class YourViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // Example usage of generating a referral link
    
    func generateReferralLink() {
        Task {
            if let linkContent = await ReefReferral.shared.generateReferralLink() {
                // Handle the generated referral link
                print("Generated Referral Link: \(linkContent.link)")
            } else {
                // Handle the error case
                print("Failed to generate referral link")
            }
        }
    }
    
    // Example usage of checking referral statuses
    
    func checkReferralStatuses() {
        ReefReferral.shared.checkReferralStatuses()
    }
    
     // Example usage of triggering a referral success event
    
    func triggerReferralSuccess() {
        ReefReferral.shared.triggerReferralSuccess()
    }
    
}

```
