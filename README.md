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

Here's a basic example of how to get started:

```swift
import ReefReferral

// Configure ReefReferral with your API key and delegate
let delegate = YourDelegate()
reefReferral.start(apiKey: "<your_api_key>", delegate: delegate)

// Generate a referral link
if let referralLink = await reefReferral.generateReferralLink() {
    // Handle the generated referral link
}

// Check referral statuses
let referralStatuses = await reefReferral.checkReferralStatuses()
// Handle the retrieved referral statuses

// Handle deep links (call this function when your app is opened via a deep link)
func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    reefReferral.handleDeepLink(url: url)
    return true
}

// Trigger a referral success event
reefReferral.triggerReferralSuccess()

// Developer Utilities
reefReferral.clearLink()
reefReferral.clearReferralID()

```

