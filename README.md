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

## Configuration

To use the ReefReferral package effectively, you need to make additional configurations in your project.

### Adding URL Type

Add a URL Type to your app. This URL Type is necessary for handling deep links related to referrals. Follow these steps to add a URL Type:

1. In Xcode, open your project settings
2. Navigate to the "Info" > "URL Types" section
3. Click the "+" button to add a new URL Type
4. Set the URL Scheme to "reef-referal"


### Allowing Insecure HTTP Loads

For now we need to allow insecure HTTP Loads.
Right-click on the info.plist file and select "Open As" > "Source Code."

Add the following XML code inside the <dict> element:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

## Usage

Here's a basic example of how to get started:

```swift
import ReefReferral

// Initialize ReefReferral with your API key
ReefReferral.shared.start(apiKey: "your-api-key") // For now use the App ID

// -- Referring user functions

// Generate a referral link
if let referralLink = await ReefReferral.shared.generateReferralLink() {
    print("Referral Link: \(referralLink.link)")
}

// Check referral statuses
let referralStatuses = await ReefReferral.shared.checkReferralStatuses()
print("Referral Statuses: \(referralStatuses)")
print(\(statuses.filter({ $0.status == .received }).count) referrals opened")
print(\(statuses.filter({ $0.status == .success }).count) referrals connverted")

// -- Referred user functions

// Handle deep links, to be called in the App openURL hook
ReefReferral.shared.handleDeepLink(url: deepLinkURL)

// Trigger referral success
ReefReferral.shared.triggerReferralSuccess()
```

