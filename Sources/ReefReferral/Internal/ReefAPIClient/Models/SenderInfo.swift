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

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.reward_status = try container.decode(ReefReferral.SenderRewardStatus.self, forKey: .reward_status)
        self.reward_offer_url = try container.decodeIfPresent(String.self, forKey: .reward_offer_url)

        // check if link valid
        let linkURL = try container.decode(String.self, forKey: .link_url)
        if URL(string: linkURL) == nil {
            throw DecodingError.dataCorruptedError(forKey: .link_url, in: container.self, debugDescription: "Link URL is not valid URL. Check if reef link domain is a valid domain.")
        }
        self.link_url = linkURL
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


