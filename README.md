# ReefReferral iOS SDK

## Overview

The ReefReferral SDK allows you to implement a referral system in your app, enabling users to refer others and earn rewards. This guide will help you integrate the SDK quickly and efficiently.

## Prerequisites

Before you begin, make sure you have the following:

- Xcode installed.
- Your API key ready for configuration.

## Standard Mode (With Apple Offer Codes)

In standard mode, the ReefReferral SDK automatically handles referral and referring success events. You don't need to call `triggerReferralSuccess` or `triggerReferringSuccess`.

### 1. Import the SDK

Add the ReefReferral SDK to your project by importing it at the top of your Swift file:

```swift
import ReefReferral
```

### 2. Configure the SDK
Initialize the ReefReferral SDK with your API key and set a delegate to handle referral events:

#### SwiftUI example
```swift
struct ContentView: View {
    @ObservedObject private var reef = ReefReferral.shared
    var body: some View {
        NavigationView {
            MyView {
                ...
            }
            .onAppear {
                reef.start(apiKey: API_KEY, logLevel: .trace)
            }
            .onOpenURL { url in
                reef.handleDeepLink(url: url)
            }
        }
    }
}
```

### 3. Accessing referral information

in Swift UI, you can simply observe `ReefReferral.shared`
```swift
@ObservedObject private var reef = ReefReferral.shared
```

ReefReferral.shared offers referral-related information using the following properties:

- `referringLinkURL`: The URL of the referring user's referral link.
- `receivedCount`: The number of referrals received by the referring user.
- `redeemedCount`: The number of successful referrals made by the referring user.
- `rewardEligibility`: The eligibility status for the referring user's reward.
- `rewardURL`: The URL to claim the referring user's reward.
- `referredStatus`: The status of the referred user.
- `referredOfferURL`: The URL to claim the referred user's offer.

You can also implement the delegate protocol to get updates on those properties :

```swift
public protocol ReefReferralDelegate {
    func referringUpdate(linkURL: URL?, received: Int, redeemed: Int, rewardEligibility: ReferringRewardStatus, rewardURL: URL?)
    func referredUpdate(status: ReferredStatus, offerURL: URL?)
}
``` 

## Manual Mode (Without Apple Offer Codes)
In manual mode, you need to trigger referral success events manually.


### Trigger Referral Success
To manually trigger a referral success event, use the following method:

```swift
ReefReferral.shared.triggerReferralSuccess()
```

### Trigger Referring Success
To manually trigger a referring success event, use the following method:

```swift
ReefReferral.shared.triggerReferringSuccess()
```

## Support

If you have any questions or need further assistance, refer to the SDK documentation or contact our support team.

