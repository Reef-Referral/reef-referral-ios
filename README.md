# ReefReferral iOS SDK

## Overview

The ReefReferral SDK allows you to implement a referral system in your app, enabling users to refer others and earn rewards. This guide will help you integrate the SDK quickly and efficiently.

## Prerequisites

Before you begin, make sure you have the following:

- Xcode installed.
- Your API key ready for configuration.

## Standard Mode (With Apple Offer Codes)

In standard mode, the ReefReferral SDK automatically handles referral success events. You don't need to call `triggerReferralSuccess` or `triggerReferringSuccess`.

### 1. Import the SDK

Add the ReefReferral SDK to your project by importing it at the top of your Swift file:

```swift
import ReefReferral
```

### 2. Configure the SDK
Initialize the ReefReferral SDK with your API key and set a delegate to handle referral events:

```swift
let apiKey = "YOUR_API_KEY"
ReefReferral.shared.start(apiKey: apiKey, delegate: self)
```

### 3. Generate a Referral Link
To generate a referral link, use the following method:

```swift
if let referralLink = await ReefReferral.shared.generateReferralLink() {
    // Use the generated referralLink
}
```
### 4. Check Referral Status
You can check referral statuses for a specific referral link:

```swift
ReefReferral.shared.checkReferralStatus()
Your delegate methods will be called automatically when referral events occur.
```

## Manual Mode (Without Apple Offer Codes)
In manual mode, you need to trigger referral success events manually.

### 1. Import and Configure the SDK
Follow steps 1 and 2 from the standard mode to import and configure the SDK.

### 2. Generate a Referral Link
Generate a referral link as explained in step 3 from the standard mode.

### 3. Trigger Referral Success
To manually trigger a referral success event, use the following method:

```swift
ReefReferral.shared.triggerReferralSuccess()
```

#### 4. Trigger Referring Success
To manually trigger a referring success event, use the following method:

```swift
ReefReferral.shared.triggerReferringSuccess()
```

## Support

If you have any questions or need further assistance, refer to the SDK documentation or contact our support team.

Happy Referring! 🎉

