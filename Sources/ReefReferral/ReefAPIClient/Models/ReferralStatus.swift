//
//  ReferralStatus.swift
//
//
//  Created by Alexis Creuzot on 19/10/2023.
//

import Foundation

public enum ReferredStatus: String, Codable {
    case received
    case success
}

public struct ReferralStatus: Codable {
    public let link: ReferralLinkContent
    public let offer: ReferralOffer 
    public let referred_users: [ReferredUser]
}

public struct ReferralOffer: Codable {
    public let id: String
    public let referral_offer_code: String
    public let referring_offer_code: String
    public let referring_offer_eligibility: Int
}

public struct ReferredUser: Codable {
    public let id: String
    public let udid: String
    public let referred_status: ReferredStatus
}
