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
    .package(url: "https://github.com/ReefReferral/ReefReferralSDK.git", from: "1.0.0")
]
```

## Usage

Integrating the ReefReferral SDK into your app is simple. 
Here's a basic example of how to get started:

```swift
import ReefReferralSDK

// Initialize the SDK with your API key
ReefReferral.shared.start("<your_api_key>")

// Show the referral screen
ReefReferral.shared.showReferralSheet()

// Set up a reward callback
ReefReferral.shared.setRewardCallback { reward in
    // Handle the reward
    // reward is a custom object with details about the reward
}

// To call when your referred user has completed a set action
// Examples : App launch, Review, Purchase...
ReefReferral.shared.triggerReferralSuccess()

```

