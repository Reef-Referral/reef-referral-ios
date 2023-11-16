//
//  ReferralStatus.swift
//
//
//  Created by Alexis Creuzot on 19/10/2023.
//

import Foundation

public extension Reef {
    
    struct SenderInfo: Codable {
        public let link: ReferralLinkContent
        public let offer: ReferralOffer
        public let referred_users: [Receiver]
        public var received : Int { return self.referred_users.filter({ $0.referred_status == .received }).count }
        public var redeemed: Int { return self.referred_users.filter({ $0.referred_status == .redeemed }).count }
        
        var status : ReferralStatus {
            return ReferralStatus.init(linkURL: link.linkURL,
                                       received: received,
                                       redeemed: redeemed,
                                       rewardEligibility: link.reward_status,
                                       referringRewardOfferCodeURL: link.rewardURL)
        }
    }
    
    struct ReferralLink: Codable {
        public let link: ReferralLinkContent
    }

    struct ReferralLinkContent: Codable {
        
        public let id: String
        public let reward_status: SenderRewardStatus
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
    
    struct ReferralOffer: Codable {
        public let id: String
        public let referral_offer_id: String
        public let referral_offer_code: String
        public let referring_offer_id: String
        public let referring_offer_code: String
        public let referring_offer_eligibility: Int
    }
    
    struct ReferralStatus {
        public let linkURL: URL?
        public let received: Int
        public let redeemed: Int
        public let rewardEligibility: SenderRewardStatus
        public let referringRewardOfferCodeURL: URL?
    }

}
