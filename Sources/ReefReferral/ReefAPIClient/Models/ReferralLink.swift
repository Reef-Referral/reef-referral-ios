//
//  Asset.swift
//  APISandbox
//
//  Created by Alexis Creuzot on 17/11/2022.
//

import Foundation

public enum ReferringRewardStatus: String, Codable {
    case not_eligible
    case eligible
    case granted
}

public struct ReferralLink: Codable {
    
    public let link: ReferralLinkContent
}

public struct ReferralLinkContent: Codable {
    
    public let id: String
    public let reward_status: ReferringRewardStatus
    public let link_url: String
    public let ios_scheme: String
    public let reward_offer_code : String?
    
    public var linkURL: URL {
        return URL(string: link_url)!
    }
}
