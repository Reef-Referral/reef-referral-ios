//
//  ReferralStatus.swift
//
//
//  Created by Alexis Creuzot on 19/10/2023.
//

import Foundation


public struct ReferringInfo: Codable {
    public let link: ReferralLinkContent
    public let offer: ReferralOffer 
    public let referred_users: [ReferredUser]
    
    public var received : Int { return self.referred_users.filter({ $0.referred_status == .received }).count }
    public var successes: Int { return self.referred_users.filter({ $0.referred_status == .redeemed }).count }
}

public struct ReferralLink: Codable {
    public let link: ReferralLinkContent
}

public struct ReferralLinkContent: Codable {
    
    public let id: String
    public let reward_status: ReferringRewardStatus
    public let link_url: String
    public let reward_offer_url : String?
    
    public var rewardURL : URL? {
        guard let reward_offer_url else { return nil }
        return URL(string: reward_offer_url)
    }
    
    public var linkURL: URL {
        return URL(string: link_url)!
    }
}

public struct ReferralOffer: Codable {
    public let id: String
    public let referral_offer_code: String
    public let referring_offer_code: String
    public let referring_offer_eligibility: Int
}
