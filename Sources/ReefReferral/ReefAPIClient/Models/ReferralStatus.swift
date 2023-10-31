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

public struct ReferralStatus: Decodable {
    public let referral_status: ReferralStatusContent
}

public struct ReferralStatusContent: Decodable {
    public let link: ReferralLinkContent
    public let referred_users: [ReferredUser]
}

public struct ReferredUser: Decodable {
    public let id: String
    public let udid: String
    public let referred_status: ReferredStatus
}
