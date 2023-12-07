//
//  ReferralStatus.swift
//
//
//  Created by Alexis Creuzot on 19/10/2023.
//

import Foundation


struct SenderInfo: Codable, Equatable {
    let link: ReferralLinkContent
    let offer: ReferralOffer
    let referred_users: [Receiver]

    var received : Int { return self.referred_users.filter({ $0.referred_status == .eligible }).count }
    var redeemed: Int { return self.referred_users.filter({ $0.referred_status == .redeemed }).count }

    var status : ReferralStatus {
        return ReferralStatus.init(linkURL: link.linkURL,
                                   received: received,
                                   redeemed: redeemed,
                                   rewardEligibility: link.reward_status,
                                   referringRewardOfferCodeURL: link.rewardURL)
    }
}

struct ReferralLink: Codable {
    let link: ReferralLinkContent
}

struct ReferralLinkContent: Codable, Equatable {

    let id: String
    let reward_status: ReefReferral.SenderRewardStatus
    let link_url: String
    let reward_offer_url : String?

    var rewardURL : URL? {
        guard let reward_offer_url else { return nil }
        return URL(string: reward_offer_url)
    }

    var linkURL: URL {
        return URL(string: link_url)!
    }
}

struct ReferralOffer: Codable, Equatable {
   let id: String
   let referral_offer_id: String
   let referral_offer_code: String
   let referring_offer_id: String
   let referring_offer_code: String
   let referring_offer_eligibility: Int
}

struct ReferralStatus {
   let linkURL: URL?
   let received: Int
   let redeemed: Int
    let rewardEligibility: ReefReferral.SenderRewardStatus
   let referringRewardOfferCodeURL: URL?
}


